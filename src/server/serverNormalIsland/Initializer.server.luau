-- Initializer
-- Server entry point. Starts all services in dependency order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local RoundState   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))
local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

local DATA_FOLDER = "Data"
local DATA_SERVICE_BOOTSTRAP_NAME = "DataServiceBootstrap"
local DataServiceBootstrap = require(script.Parent:WaitForChild(DATA_FOLDER):WaitForChild(DATA_SERVICE_BOOTSTRAP_NAME))
local InventoryService  = require(script.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
local AbilityDataService = require(script.Parent:WaitForChild("Abilities"):WaitForChild("AbilityDataService"))

local DamageService = require(script.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local WeaponService = require(script.Parent:WaitForChild("Weapons"):WaitForChild("WeaponService"))
local StatsService = require(script.Parent:WaitForChild("Stats"):WaitForChild("StatsService"))

local isStudio = RunService:IsStudio()
print(string.format("[Initializer] Starting... (Studio=%s)", tostring(isStudio)))
local StarterPlayer = game:GetService("StarterPlayer")
StarterPlayer:SetAttribute("ForceR15", true)
StarterPlayer:SetAttribute("IgnoreCharacterAppearance", true)


local roundState = RoundState.Current()
roundState:Initialize()


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

-- Service boot

DataServiceBootstrap.Initialize()
InventoryService.Initialize()
AbilityDataService.Initialize()
StatsService:Initialize()
WeaponService:Initialize()


-- Character config
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
				-- Force default blocky R15 proportions
				dc.HeadScale      = 1
				dc.HeightScale    = 1
				dc.WidthScale     = 1
				dc.DepthScale     = 1
				dc.BodyTypeScale  = 0
				dc.ProportionScale = 0
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

-- Player lifecycle
local DataServiceServer = DataServiceBootstrap.GetDataService()
function DataServiceServer:onPlayerInit(player: Player, data: any)
	player:SetAttribute("_DataLoaded", true)
	print(string.format("[Initializer] Data loaded for: %s (UserId=%d)", player.Name, player.UserId))

	local container = StatsService:GetContainer(player)
	if container and data.character and data.character.attributes then
		for attrName, value in pairs(data.character.attributes) do
			container:SetAttribute(attrName :: any, value)
		end
	end
end

local function onPlayerAdded(player: Player)
	print(string.format("[Initializer] Player joined: %s (UserId=%d)", player.Name, player.UserId))

	-- Stamina defaults
	if player:GetAttribute("MaxStamina") == nil then
		player:SetAttribute("MaxStamina", PlayerConfig.baseMaxStamina or 100)
	end
	if player:GetAttribute("Stamina") == nil then
		player:SetAttribute("Stamina", player:GetAttribute("MaxStamina") or PlayerConfig.baseMaxStamina or 100)
	end
	player:SetAttribute("WantsSprint", false)

	player.CharacterAdded:Connect(function(character)
		applyCharacterConfig(character)
	end)
end

-- Handle players who join after the server is already running.
Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("[Initializer] Initialization complete")

-- Export service refs for other server scripts.
_G.Services = {
	DataServiceBootstrap = DataServiceBootstrap,
	InventoryService  = InventoryService,
	AbilityDataService = AbilityDataService,
	StatsService      = StatsService,
	DamageService     = DamageService,
}
