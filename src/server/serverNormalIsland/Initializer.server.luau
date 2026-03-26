-- Server bootstrap: services in dependency order.

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
local AbilityStateRuntime = require(script.Parent:WaitForChild("Abilities"):WaitForChild("AbilityStateRuntime"))
local AbilityExecutionService = require(script.Parent:WaitForChild("Abilities"):WaitForChild("AbilityExecutionService"))
local KeybindsService = require(script.Parent:WaitForChild("Input"):WaitForChild("KeybindsService"))

local EffectTemplatePreloader = require(script.Parent:WaitForChild("Effects"):WaitForChild("EffectTemplatePreloader"))
local AbilityVisualRelayService = require(script.Parent:WaitForChild("Effects"):WaitForChild("AbilityVisualRelayService"))
local DamageService = require(script.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local WeaponService = require(script.Parent:WaitForChild("Weapons"):WaitForChild("WeaponService"))
local StatsService = require(script.Parent:WaitForChild("Stats"):WaitForChild("StatsService"))
local BlockyCharacterSetup = require(script.Parent:WaitForChild("Player"):WaitForChild("BlockyCharacterSetup"))
local CharacterAttachmentSetup = require(script.Parent:WaitForChild("Player"):WaitForChild("CharacterAttachmentSetup"))

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

DataServiceBootstrap.Initialize()
KeybindsService.Initialize()
InventoryService.Initialize()
AbilityDataService.Initialize()
AbilityStateRuntime.Initialize()
EffectTemplatePreloader.Initialize()
AbilityVisualRelayService.Initialize()
AbilityExecutionService.Initialize()
StatsService:Initialize()
WeaponService:Initialize()


-- Character config
local function applyCharacterConfig(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	local maxHealth = player and player:GetAttribute("MaxHP") or PlayerConfig.maxHealth
	local walkSpeed = player and player:GetAttribute("WalkSpeed") or PlayerConfig.walkSpeed

	BlockyCharacterSetup.Apply(character)

	humanoid.WalkSpeed = walkSpeed
	humanoid.JumpPower = PlayerConfig.jumpPower
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth

	if PlayerConfig.humanoidRigType ~= "R15" then
		CharacterAttachmentSetup.Apply(character)
	end
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
	-- CharacterAdded only fires for spawns *after* this connection. If the character
	-- already exists (common when onPlayerAdded runs late), apply once now.
	local existing = player.Character
	if existing then
		task.defer(function()
			if player.Character == existing and existing.Parent then
				applyCharacterConfig(existing)
			end
		end)
	end
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
	KeybindsService = KeybindsService,
	InventoryService  = InventoryService,
	AbilityDataService = AbilityDataService,
	AbilityStateRuntime = AbilityStateRuntime,
	AbilityExecutionService = AbilityExecutionService,
	StatsService      = StatsService,
	DamageService     = DamageService,
}
