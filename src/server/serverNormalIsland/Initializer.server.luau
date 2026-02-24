--[[
	Initializer
	Server script that initializes and wires together game systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Shared modules
local _LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))
local RoundState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))
local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

-- Server modules
local LootSystemModules = script.Parent:WaitForChild("LootSystem")
local LootBoxService = require(LootSystemModules:WaitForChild("LootBoxService"))
local DropFactory = require(LootSystemModules:WaitForChild("DropFactory"))
local BreakableCrate = require(LootSystemModules:WaitForChild("BreakableCrate"))

-- Inventory module
local InventoryModules = script.Parent:WaitForChild("Inventory")
local InventoryService = require(InventoryModules:WaitForChild("InventoryService"))

-- Combat modules
local CombatModules = script.Parent:WaitForChild("Combat")
local DamageService = require(CombatModules:WaitForChild("DamageService"))

-- Weapon modules
local WeaponModules = script.Parent:WaitForChild("Weapons")
local GunService = require(WeaponModules:WaitForChild("GunService"))
local MeleeService = require(WeaponModules:WaitForChild("MeleeService"))

-- Med modules
local MedModules = script.Parent:WaitForChild("Med")
local MedService = require(MedModules:WaitForChild("MedService"))

print("[Initializer] Starting...")

local StarterPlayer = game:GetService("StarterPlayer")

StarterPlayer:SetAttribute("ForceR15", true)
StarterPlayer:SetAttribute("IgnoreCharacterAppearance", true)

-- Initialize RoundState with a seed
local roundState = RoundState.Current()
roundState:Initialize()

-- Expose universal match start time
local matchInfoFolder = ReplicatedStorage:FindFirstChild("MatchInfo")
if not matchInfoFolder then
    matchInfoFolder = Instance.new("Folder")
    matchInfoFolder.Name = "MatchInfo"
    matchInfoFolder.Parent = ReplicatedStorage
end
local startTime = matchInfoFolder:FindFirstChild("StartTime")
if not startTime then
    startTime = Instance.new("NumberValue")
    startTime.Name = "StartTime"
    startTime.Value = os.time()
    startTime.Parent = matchInfoFolder
end

-- Initialize services
InventoryService:Initialize()
DropFactory:Initialize(InventoryService)
LootBoxService:Initialize(DropFactory)
GunService:Initialize()
MeleeService:Initialize()
MedService:Initialize()

-- Wire up BreakableCrate registration for static crates in the map (CrateType attribute)
local function registerCrate(crateModel: Model)
	return BreakableCrate:RegisterCrate(crateModel, LootBoxService, DamageService)
end

-- Register existing crates in workspace (static loot crates placed in map design)
BreakableCrate.RegisterExistingCrates(LootBoxService, DamageService)

-- Listen for new crates added to workspace
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and descendant:GetAttribute("CrateType") then
		-- Small delay to ensure attributes are set
		task.wait(0.1)
		registerCrate(descendant)
	end
end)

-- Enforce humanoid rig type and scale on character spawn
local function applyCharacterConfig(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if PlayerConfig.humanoidRigType == "R15" then
		humanoid.RigType = Enum.HumanoidRigType.R15

		-- Force blocky R15 (no Rthro): reset body part IDs and proportions to default
		task.defer(function()
			local ok, dc = pcall(function()
				return humanoid:GetAppliedDescription()
			end)
			if ok and dc then
				dc.Head = 0
				dc.Torso = 0
				dc.LeftArm = 0
				dc.RightArm = 0
				dc.LeftLeg = 0
				dc.RightLeg = 0
				dc.HeadScale = 1
				dc.HeightScale = 1
				dc.WidthScale = 1
				dc.BodyTypeScale = 1
				dc.DepthScale = 1
				dc.ProportionScale = 1
				pcall(function()
					humanoid:ApplyDescription(dc)
				end)
				-- Re-apply PlayerConfig scale after blocky reset
				local scale = PlayerConfig.scale
				if scale then
					local function setScale(name: string, value: number)
						local s = humanoid:FindFirstChild(name)
						if not s then
							s = Instance.new("NumberValue")
							s.Name = name
							s.Parent = humanoid
						end
						s.Value = value
					end
					setScale("BodyHeightScale", scale.height)
					setScale("BodyWidthScale", scale.width)
					setScale("BodyDepthScale", scale.depth)
					setScale("HeadScale", scale.head)
				end
			end
		end)
	else
		humanoid.RigType = Enum.HumanoidRigType.R6
	end

	-- Basic movement/health
	humanoid.WalkSpeed = PlayerConfig.walkSpeed
	humanoid.JumpPower = PlayerConfig.jumpPower
	humanoid.MaxHealth = PlayerConfig.maxHealth
	humanoid.Health = PlayerConfig.maxHealth
end

Players.PlayerAdded:Connect(function(player)
	if player:GetAttribute("MaxStamina") == nil then
		player:SetAttribute("MaxStamina", PlayerConfig.baseMaxStamina or 100)
	end
	if player:GetAttribute("Stamina") == nil then
		player:SetAttribute("Stamina", PlayerConfig.baseMaxStamina or 100)
	end
	player:SetAttribute("WantsSprint", false)
	player.CharacterAdded:Connect(function(character)
		applyCharacterConfig(character)
	end)
end)

print("[Initializer] Initialization complete")

-- Export refs for convenience (optional)
_G.Services = {
	LootBoxService = LootBoxService,
	DropFactory = DropFactory,
	DamageService = DamageService,
	BreakableCrate = BreakableCrate,
}


