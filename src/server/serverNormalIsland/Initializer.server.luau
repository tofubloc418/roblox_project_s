--[[
	Initializer
	Server entry point.  Starts all services in dependency order.

	Boot order:
	  1. DataServiceBootstrap – dataService server init (ProfileStore + template)
	  2. InventoryService – creates ALL InventoryRemotes, wires request handlers
	  3. AbilityDataService – wires preset request handler (uses remotes from step 2)
	  4. StatsService    – per-player stat containers
	  5. MeleeService    – melee attack handling
	  6. MedService      – consumable healing (legacy; will be replaced by asset scripts)
	  7. PlayerAdded handler – wait for player data (dataService), apply attributes (replication is automatic)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- ── Shared modules ─────────────────────────────────────────────────────────────
local RoundState   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))
local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

-- ── Data layer ────────────────────────────────────────────────────────────────
local DATA_FOLDER = "Data"
local DATA_SERVICE_BOOTSTRAP_NAME = "DataServiceBootstrap"
local DataServiceBootstrap = require(script.Parent:WaitForChild(DATA_FOLDER):WaitForChild(DATA_SERVICE_BOOTSTRAP_NAME))
local InventoryService  = require(script.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
local AbilityDataService = require(script.Parent:WaitForChild("Abilities"):WaitForChild("AbilityDataService"))

-- ── Combat / weapons / meds ───────────────────────────────────────────────────
local DamageService = require(script.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local MeleeService  = require(script.Parent:WaitForChild("Weapons"):WaitForChild("MeleeService"))
local MedService    = require(script.Parent:WaitForChild("Med"):WaitForChild("MedService"))

-- ── Stats ─────────────────────────────────────────────────────────────────────
local StatsService = require(script.Parent:WaitForChild("Stats"):WaitForChild("StatsService"))

print("[Initializer] Starting...")

-- ── Global settings ───────────────────────────────────────────────────────────
local StarterPlayer = game:GetService("StarterPlayer")
StarterPlayer:SetAttribute("ForceR15", true)
StarterPlayer:SetAttribute("IgnoreCharacterAppearance", true)

-- Initialise round state seed.
local roundState = RoundState.Current()
roundState:Initialize()

-- Expose universal match start time.
local function ensureMatchInfo()
	local folder = ReplicatedStorage:FindFirstChild("MatchInfo") or (function()
		local f = Instance.new("Folder")
		f.Name   = "MatchInfo"
		f.Parent = ReplicatedStorage
		return f
	end)()

	if not folder:FindFirstChild("StartTime") then
		local v = Instance.new("NumberValue")
		v.Name   = "StartTime"
		v.Value  = os.time()
		v.Parent = folder
	end
end
ensureMatchInfo()

-- ── Service boot ──────────────────────────────────────────────────────────────

-- 1. DataServiceBootstrap: dataService server init (ProfileStore + template).
DataServiceBootstrap.Initialize()

-- 2. InventoryService: creates InventoryRemotes folder + all RemoteEvents,
--    wires server-side handlers for RequestMove, RequestEquip, etc.
InventoryService.Initialize()

-- 3. AbilityDataService: wires RequestSetAbilityPreset handler.
--    (Folder + remotes must exist from InventoryService.Initialize above.)
AbilityDataService.Initialize()

-- 4–6. Legacy / existing services.
StatsService:Initialize()
MeleeService:Initialize()
MedService:Initialize()

-- ── Character config ──────────────────────────────────────────────────────────
-- Enforces R15 blocky rig and applies PlayerConfig scale on each character spawn.
local function applyCharacterConfig(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player    = Players:GetPlayerFromCharacter(character)
	local maxHealth = player and player:GetAttribute("MaxHP") or PlayerConfig.maxHealth
	local walkSpeed = player and player:GetAttribute("WalkSpeed") or PlayerConfig.walkSpeed

	if PlayerConfig.humanoidRigType == "R15" then
		humanoid.RigType = Enum.HumanoidRigType.R15

		task.defer(function()
			local ok, dc = pcall(function() return humanoid:GetAppliedDescription() end)
			if ok and dc then
				dc.Head      = 0; dc.Torso      = 0
				dc.LeftArm   = 0; dc.RightArm   = 0
				dc.LeftLeg   = 0; dc.RightLeg   = 0
				dc.HeadScale = 1; dc.HeightScale = 1; dc.WidthScale  = 1
				dc.BodyTypeScale = 1; dc.DepthScale = 1; dc.ProportionScale = 1
				pcall(function() humanoid:ApplyDescription(dc) end)

				local scale = PlayerConfig.scale
				if scale then
					local function setScale(name: string, value: number)
						local s = humanoid:FindFirstChild(name)
						if not s then
							s = Instance.new("NumberValue")
							s.Name   = name
							s.Parent = humanoid
						end
						s.Value = value
					end
					setScale("BodyHeightScale", scale.height)
					setScale("BodyWidthScale",  scale.width)
					setScale("BodyDepthScale",  scale.depth)
					setScale("HeadScale",       scale.head)
				end
			end
		end)
	else
		humanoid.RigType = Enum.HumanoidRigType.R6
	end

	humanoid.WalkSpeed  = walkSpeed
	humanoid.JumpPower  = PlayerConfig.jumpPower
	humanoid.MaxHealth  = maxHealth
	humanoid.Health     = maxHealth
end

-- ── Player lifecycle ──────────────────────────────────────────────────────────

local function onPlayerAdded(player: Player)
	-- Wait for dataService to load this player's profile (blocks until ready).
	local data = DataServiceBootstrap.WaitForPlayerData(player)
	-- Replication to client is automatic; no SyncToClient or SyncAbilityPresets.

	if data then
		-- Apply saved character attributes to the stats container.
		local container = StatsService:GetContainer(player)
		if container and data.character and data.character.attributes then
			for attrName, value in pairs(data.character.attributes) do
				container:SetAttribute(attrName :: any, value)
			end
		end
	end

	-- Stamina attributes for the existing sprint system.
	if player:GetAttribute("MaxStamina") == nil then
		player:SetAttribute("MaxStamina", PlayerConfig.baseMaxStamina or 100)
	end
	if player:GetAttribute("Stamina") == nil then
		player:SetAttribute("Stamina", player:GetAttribute("MaxStamina") or PlayerConfig.baseMaxStamina or 100)
	end
	player:SetAttribute("WantsSprint", false)

	-- Apply character config each time the character spawns.
	player.CharacterAdded:Connect(function(character)
		applyCharacterConfig(character)
	end)
end

-- Handle players who join after the server is already running.
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already present (Studio "Run" with a local player).
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("[Initializer] Initialization complete")

-- Export service refs for other server scripts (optional convenience).
_G.Services = {
	DataServiceBootstrap = DataServiceBootstrap,
	InventoryService  = InventoryService,
	AbilityDataService = AbilityDataService,
	StatsService      = StatsService,
	DamageService     = DamageService,
}
