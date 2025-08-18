--[[
	LootSystemInitializer
	Server script that initializes and wires together all loot system components
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for modules to replicate
local ServerModules = script.Parent

-- Shared modules
local LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))
local RoundState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))

-- Server modules
local LootBoxService = require(ServerModules:WaitForChild("LootBoxService"))
local DropFactory = require(ServerModules:WaitForChild("DropFactory"))
local LootSpawnService = require(ServerModules:WaitForChild("LootSpawnService"))
local BreakableCrate = require(ServerModules:WaitForChild("BreakableCrate"))

-- Inventory module
local InventoryModules = script.Parent.Parent:WaitForChild("Inventory")
local InventoryService = require(InventoryModules:WaitForChild("InventoryService"))

-- Combat modules (DamageService is now in Combat folder)
local CombatModules = script.Parent.Parent:WaitForChild("Combat")
local DamageService = require(CombatModules:WaitForChild("DamageService"))

print("[LootSystem] Initializing...")

-- Initialize RoundState with a seed
local roundState = RoundState.Current()
roundState:Initialize()

-- Initialize services
InventoryService:Initialize()
DropFactory:Initialize(InventoryService)
LootBoxService:Initialize(DropFactory)
LootSpawnService:Initialize(BreakableCrate)

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

-- Example damage testing (remove in production)
if LootConfig.DEBUG_MODE then
	-- Create test commands for damage
	local function createTestCommands()
		-- Test damage command
		Players.PlayerAdded:Connect(function(player)
			player.Chatted:Connect(function(message)
				local args = string.split(message, " ")
				
				if args[1] == "/damage" and args[2] then
					-- Minimal testing: apply damage to nearest registered crate
					local damage = tonumber(args[2]) or 10
					local playerChar = player.Character
					if playerChar and playerChar.PrimaryPart then
						local nearest, nearestDist
						for object, _ in pairs(DamageService.DamageableRegistry) do
							if object and object.Parent and object:GetAttribute("CrateType") then
								local d = (object:GetPivot().Position - playerChar.PrimaryPart.Position).Magnitude
								if not nearestDist or d < nearestDist then
									nearest = object
									nearestDist = d
								end
							end
						end
						if nearest and nearestDist < 25 then
							DamageService:ApplyDamage(nearest, damage, player)

						else
							warn("No nearby crate to damage")
						end
					end
				elseif args[1] == "/spawncrates" then
					-- Spawn procedural crates
					local count = LootSpawnService:SpawnCratesForRound()
					print(string.format("Spawned %d crates", count))
				elseif args[1] == "/spawncrate" and args[2] then
					-- Spawn specific crate type at player position
					local crateType = args[2]
					local character = player.Character
					if character and character.PrimaryPart then
						local position = character.PrimaryPart.Position + Vector3.new(0, 0, 5)
						local crate = LootSpawnService:CreateCrate(crateType, position)
						if crate then
							registerCrate(crate)
							print(string.format("Spawned %s crate", crateType))
						end
					end
				end
			end)
		end)
	end
	
	createTestCommands()
	
	print([[ 
	Debug commands available:
	/damage [amount] - Damage nearest crate (simple test)
	/spawncrates - Spawn procedural crates for round
	/spawncrate [type] - Spawn specific crate type at player
	]])
end

-- Handle round start (integrate with your round system)
local function onRoundStart()
	-- Generate new seed for the round
	roundState:Initialize()
	
	-- Spawn new crates
	local crateCount = LootSpawnService:SpawnCratesForRound()
	
	print(string.format("Round started: Spawned %d crates", crateCount))
end

print("[LootSystem] Initialization complete")

-- Export for other systems to use
_G.LootSystem = {
	LootBoxService = LootBoxService,
	DropFactory = DropFactory,
	LootSpawnService = LootSpawnService,
	DamageService = DamageService,
	BreakableCrate = BreakableCrate,
	OnRoundStart = onRoundStart,
}
