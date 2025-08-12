--[[
	LootSystemInitializer
	Server script that initializes and wires together all loot system components
]]

local RunService = game:GetService("RunService")
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
local DamageService = require(ServerModules:WaitForChild("DamageService"))
local BreakableCrate = require(ServerModules:WaitForChild("BreakableCrate"))

print("Initializing Loot System...")

-- Initialize RoundState with a seed
local roundState = RoundState.Current()
roundState:Initialize()

-- Initialize services
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
					local damage = tonumber(args[2]) or 10
					
					-- Find nearest crate to player
					local character = player.Character
					if character and character.PrimaryPart then
						local nearestCrate = nil
						local nearestDistance = math.huge
						
						for crateModel, _ in pairs(BreakableCrate.ActiveCrates) do
							if crateModel and crateModel.Parent then
								local distance = (crateModel:GetPivot().Position - character.PrimaryPart.Position).Magnitude
								if distance < nearestDistance then
									nearestDistance = distance
									nearestCrate = crateModel
								end
							end
						end
						
						if nearestCrate and nearestDistance < 20 then
							DamageService:ApplyDamage(nearestCrate, damage, player, "Melee")
							print(string.format("Applied %d damage to nearest crate", damage))
						else
							warn("No crate nearby to damage")
						end
					end
				elseif args[1] == "/spawncrates" then
					-- Spawn procedural crates
					local count = LootSpawnService:SpawnCratesForRound()
					print(string.format("Spawned %d crates", count))
				elseif args[1] == "/clearcrates" then
					-- Clear all crates
					BreakableCrate.ClearAll()
					DropFactory:ClearAllDrops()
					print("Cleared all crates and drops")
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
	/damage [amount] - Damage nearest crate
	/spawncrates - Spawn procedural crates for round
	/spawncrate [type] - Spawn specific crate type
	/clearcrates - Clear all crates and drops
	]])
end

-- Handle round start (integrate with your round system)
local function onRoundStart()
	-- Generate new seed for the round
	roundState:Initialize()
	
	-- Clear previous round's items
	BreakableCrate.ClearAll()
	DropFactory:ClearAllDrops()
	
	-- Spawn new crates
	local crateCount = LootSpawnService:SpawnCratesForRound()
	
	print(string.format("Round started: Spawned %d crates", crateCount))
end

-- Example: Start a round after 5 seconds (remove in production)
if LootConfig.DEBUG_MODE then
	task.wait(5)
	onRoundStart()
end

print("Loot System initialized successfully!")

-- Export for other systems to use
_G.LootSystem = {
	LootBoxService = LootBoxService,
	DropFactory = DropFactory,
	LootSpawnService = LootSpawnService,
	DamageService = DamageService,
	BreakableCrate = BreakableCrate,
	OnRoundStart = onRoundStart,
}
