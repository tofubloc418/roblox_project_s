--[[
	LootSpawnService
	Procedurally spawns crates at round start based on configuration
]]

local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Shared modules
local LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))
local SpawnConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("SpawnConfig"))
local IslandConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("IslandConfig"))
local RoundState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))

local LootSpawnService = {}
LootSpawnService.__index = LootSpawnService

function LootSpawnService.new()
	local self = setmetatable({}, LootSpawnService)
	
	self.SpawnedCrates = {}
	self.BreakableCrateComponent = nil -- Will be set during init
	
	return self
end

-- Initialize the service
function LootSpawnService:Initialize(breakableCrateComponent)
	self.BreakableCrateComponent = breakableCrateComponent

end

-- Spawn crates for a new round
function LootSpawnService:SpawnCratesForRound()
	local roundState = RoundState.Current()
	local rng = roundState:GetSpawnRng()
	local spawnSettings = SpawnConfig
	local spawnCounts = {}
	local totalSpawned = 0
	for crateType, distribution in pairs(spawnSettings.CrateDistribution) do
		local count = typeof(distribution) == "number" and distribution or rng:NextInteger(distribution.min or 0, distribution.max or 0)
		local typeSpawned = 0
		for i = 1, count do
			local success = self:SpawnSingleCrate(crateType, rng)
			if success then
				typeSpawned = typeSpawned + 1
				totalSpawned = totalSpawned + 1
			end
		end
		if typeSpawned > 0 then
			spawnCounts[crateType] = typeSpawned
		end
	end
	
	for crateType, count in pairs(spawnCounts) do
		print(string.format("[LootSpawn] Spawned %d %s crates", count, crateType))
	end
	return totalSpawned
end

-- Sky-drop a single crate within core land area
function LootSpawnService:SpawnSingleCrate(crateType: string, rng: Random): boolean
	local dropPos = self:GetRandomCoreSkyPosition(rng)
	if not dropPos then
		return false
	end
	local crate = self:CreateCrate(crateType, dropPos)
	if crate then
		table.insert(self.SpawnedCrates, crate)
		return true
	end
	return false
end

-- Random sky position over core area (no sand/ocean)
function LootSpawnService:GetRandomCoreSkyPosition(rng: Random): Vector3?
	local coreSize = IslandConfig.coreSize
	if not coreSize then
		return nil
	end
	local halfX = coreSize.X * 0.5
	local halfZ = coreSize.Z * 0.5
	local x = rng:NextNumber(-halfX, halfX)
	local z = rng:NextNumber(-halfZ, halfZ)
	local dropHeight = SpawnConfig.SpawnHeight or ((IslandConfig.spawnAreaCenter and (IslandConfig.spawnAreaCenter.Y + 400)) or 600)

	return Vector3.new(x, dropHeight, z)
end

-- Create a crate instance (prefab clone if available)
function LootSpawnService:CreateCrate(crateType: string, position: Vector3): Model
	local crateModel: Model? = nil
	local lootCratesFolder = ReplicatedStorage:FindFirstChild("LootCrates")
	if lootCratesFolder then
		local template: Instance?
		for _, child in ipairs(lootCratesFolder:GetChildren()) do
			if child:IsA("Model") then
				local attrType = child:GetAttribute("CrateType")
				if (attrType and tostring(attrType) == crateType) or (child.Name == crateType) then
					template = child
					break
				end
			end
		end
		if template and template:IsA("Model") then
			crateModel = template:Clone()
		end
	else
		warn("[LootSpawn] ReplicatedStorage/LootCrates not found; cannot spawn crate")
	end
	if not crateModel then
		warn(string.format("[LootSpawn] No crate prefab found for type '%s'", tostring(crateType)))
		return nil :: any
	end
	local model = crateModel :: Model
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Anchored = false
			inst.CanCollide = true
		end
	end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	end
	model:PivotTo(CFrame.new(position))
	local crateConfig = LootConfig.GetCrateConfig(crateType)
	local crateId = string.format("%s_%d_%d", crateType, os.time(), math.random(1, 10000))
	model:SetAttribute("CrateType", crateType)
	model:SetAttribute("CrateId", crateId)
	model:SetAttribute("MaxHealth", crateConfig.MaxHealth or 100)
	model:SetAttribute("Health", crateConfig.MaxHealth or 100)
	model:SetAttribute("BundleCount", crateConfig.BundleCount or 1)
	if crateConfig.Whitelist then
		model:SetAttribute("Whitelist", game:GetService("HttpService"):JSONEncode(crateConfig.Whitelist))
	end
	if crateConfig.GuaranteeAtLeast then
		model:SetAttribute("GuaranteeAtLeast", game:GetService("HttpService"):JSONEncode(crateConfig.GuaranteeAtLeast))
	end
	model:SetAttribute("CrackStage", 0)
	model.Parent = Workspace
	if self.BreakableCrateComponent and self.BreakableCrateComponent.RegisterCrate then
		self.BreakableCrateComponent.RegisterCrate(model)
	end

	return model
end


-- Create singleton instance
local instance = LootSpawnService.new()

return instance
