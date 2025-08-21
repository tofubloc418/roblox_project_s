--[[
	Initializer
	Server script that initializes and wires together game systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local _StarterPlayer = game:GetService("StarterPlayer")

-- Shared modules
local _LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))
local RoundState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))
local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

-- Server modules
local LootSystemModules = script.Parent:WaitForChild("LootSystem")
local LootBoxService = require(LootSystemModules:WaitForChild("LootBoxService"))
local DropFactory = require(LootSystemModules:WaitForChild("DropFactory"))
local LootSpawnService = require(LootSystemModules:WaitForChild("LootSpawnService"))
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

-- Note: Some environments may not expose typed members on StarterPlayer in Luau; use attributes instead
game:GetService("StarterPlayer"):SetAttribute("ForceR15", true)
game:GetService("StarterPlayer"):SetAttribute("IgnoreCharacterAppearance", true)

-- Initialize RoundState with a seed
local roundState = RoundState.Current()
roundState:Initialize()

-- Initialize services
InventoryService:Initialize()
DropFactory:Initialize(InventoryService)
LootBoxService:Initialize(DropFactory)
LootSpawnService:Initialize(BreakableCrate)
GunService:Initialize()
MeleeService:Initialize()
MedService:Initialize()

-- Wire up BreakableCrate registration
local function registerCrate(crateModel: Model)
	return BreakableCrate:RegisterCrate(crateModel, LootBoxService, DamageService)
end

-- Override LootSpawnService registration to use our function
LootSpawnService.BreakableCrateComponent = {
	RegisterCrate = registerCrate
}

-- Register existing crates in workspace
BreakableCrate.RegisterExistingCrates(LootBoxService, DamageService)

-- Trigger procedural crate spawning on init
local spawnedOnInit = LootSpawnService:SpawnCratesForRound()
print(string.format("[LootSpawn] Spawned %d crates on init", spawnedOnInit))

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

	-- Rig type
	if PlayerConfig.humanoidRigType == "R15" then
		humanoid.RigType = Enum.HumanoidRigType.R15
	else
		humanoid.RigType = Enum.HumanoidRigType.R6
	end

	-- Scaling (R15 only)
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

	-- Basic movement/health (optional)
	humanoid.WalkSpeed = PlayerConfig.walkSpeed
	humanoid.JumpPower = PlayerConfig.jumpPower
	humanoid.MaxHealth = PlayerConfig.maxHealth
	humanoid.Health = PlayerConfig.maxHealth
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		applyCharacterConfig(character)
	end)
end)

print("[Initializer] Initialization complete")

-- Export refs for convenience (optional)
_G.Services = {
	LootBoxService = LootBoxService,
	DropFactory = DropFactory,
	LootSpawnService = LootSpawnService,
	DamageService = DamageService,
	BreakableCrate = BreakableCrate,
}


