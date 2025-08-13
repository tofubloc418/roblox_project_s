--[[
	LootSpawnService
	Procedurally spawns crates at round start based on configuration
]]

local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Shared modules
local LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))
local RoundState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))

local LootSpawnService = {}
LootSpawnService.__index = LootSpawnService

function LootSpawnService.new()
	local self = setmetatable({}, LootSpawnService)
	
	self.SpawnedCrates = {}
	self.BreakableCrateComponent = nil -- Will be set during init
	
	-- Find spawn areas and exclusion zones
	self.OutdoorSpawnAreas = {}
	self.NoLootZones = {}
	
	return self
end

-- Initialize the service
function LootSpawnService:Initialize(breakableCrateComponent)
	self.BreakableCrateComponent = breakableCrateComponent
	
	-- Find spawn areas
	local spawnAreasFolder = Workspace:FindFirstChild("OutdoorSpawnAreas")
	if spawnAreasFolder then
		for _, area in ipairs(spawnAreasFolder:GetChildren()) do
			if area:IsA("BasePart") then
				table.insert(self.OutdoorSpawnAreas, area)
			end
		end
	end
	
	-- Find no-loot zones
	local noLootFolder = Workspace:FindFirstChild("NoLootZones")
	if noLootFolder then
		for _, zone in ipairs(noLootFolder:GetChildren()) do
			if zone:IsA("BasePart") then
				table.insert(self.NoLootZones, zone)
			end
		end
	end
	
	if LootConfig.DEBUG_MODE then
		print(string.format("LootSpawnService initialized with %d spawn areas and %d no-loot zones",
			#self.OutdoorSpawnAreas, #self.NoLootZones))
	end
end

-- Spawn crates for a new round
function LootSpawnService:SpawnCratesForRound()
	-- Get spawn RNG
	local roundState = RoundState.Current()
	local rng = roundState:GetSpawnRng()
	
	local spawnSettings = LootConfig.SpawnSettings
	local totalSpawned = 0
	
	-- Spawn each crate type
	for crateType, distribution in pairs(spawnSettings.CrateDistribution) do
		local count = rng:NextInteger(distribution.min, distribution.max)
		
		for i = 1, count do
			local success = self:SpawnSingleCrate(crateType, rng)
			if success then
				totalSpawned = totalSpawned + 1
			end
		end
	end
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Spawned %d crates for round", totalSpawned))
	end
	
	return totalSpawned
end

-- Spawn a single crate
function LootSpawnService:SpawnSingleCrate(crateType: string, rng: Random): boolean
	local spawnSettings = LootConfig.SpawnSettings
	local maxAttempts = spawnSettings.MaxSpawnAttempts or 50
	
	for attempt = 1, maxAttempts do
		local position = self:GetRandomSpawnPosition(rng)
		
		if position then
			-- Check minimum separation from other crates
			if self:CheckMinimumSeparation(position, spawnSettings.MinSeparation) then
				-- Check if in no-loot zone
				if not self:IsInNoLootZone(position) then
					-- Raycast to find ground
					local groundPosition = self:FindGroundPosition(position)
					
					if groundPosition then
						-- Create the crate
						local crate = self:CreateCrate(crateType, groundPosition)
						
						if crate then
							table.insert(self.SpawnedCrates, crate)
							return true
						end
					end
				end
			end
		end
	end
	
	if LootConfig.DEBUG_MODE then
		warn(string.format("Failed to spawn crate type '%s' after %d attempts", crateType, maxAttempts))
	end
	
	return false
end

-- Get a random spawn position
function LootSpawnService:GetRandomSpawnPosition(rng: Random): Vector3?
	if #self.OutdoorSpawnAreas == 0 then
		-- No defined spawn areas, use random world position
		local x = rng:NextNumber(-500, 500)
		local z = rng:NextNumber(-500, 500)
		return Vector3.new(x, 100, z) -- Start high for raycast down
	end
	
	-- Pick a random spawn area
	local area = self.OutdoorSpawnAreas[rng:NextInteger(1, #self.OutdoorSpawnAreas)]
	
	-- Get random position within the area bounds
	local size = area.Size
	local position = area.Position
	
	local offsetX = rng:NextNumber(-size.X/2, size.X/2)
	local offsetZ = rng:NextNumber(-size.Z/2, size.Z/2)
	
	return position + Vector3.new(offsetX, size.Y/2 + 10, offsetZ)
end

-- Check minimum separation from other crates
function LootSpawnService:CheckMinimumSeparation(position: Vector3, minDistance: number): boolean
	for _, crate in ipairs(self.SpawnedCrates) do
		if crate and crate.Parent then
			local cratePos = crate:GetPivot().Position
			local distance = (position - cratePos).Magnitude
			
			if distance < minDistance then
				return false
			end
		end
	end
	
	return true
end

-- Check if position is in a no-loot zone
function LootSpawnService:IsInNoLootZone(position: Vector3): boolean
	for _, zone in ipairs(self.NoLootZones) do
		if zone and zone.Parent then
			-- Simple AABB check
			local zonePos = zone.Position
			local zoneSize = zone.Size
			
			local minX = zonePos.X - zoneSize.X/2
			local maxX = zonePos.X + zoneSize.X/2
			local minZ = zonePos.Z - zoneSize.Z/2
			local maxZ = zonePos.Z + zoneSize.Z/2
			
			if position.X >= minX and position.X <= maxX and
			   position.Z >= minZ and position.Z <= maxZ then
				return true
			end
		end
	end
	
	return false
end

-- Find ground position via raycast
function LootSpawnService:FindGroundPosition(startPosition: Vector3): Vector3?
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {self.SpawnedCrates}
	
	local rayDirection = Vector3.new(0, -200, 0)
	local raycastResult = Workspace:Raycast(startPosition, rayDirection, raycastParams)
	
	if raycastResult then
		local spawnHeight = LootConfig.SpawnSettings.SpawnHeight or 2
		return raycastResult.Position + Vector3.new(0, spawnHeight, 0)
	end
	
	return nil
end

-- Create a crate instance
function LootSpawnService:CreateCrate(crateType: string, position: Vector3): Model?
	-- Create placeholder crate model (will be replaced with actual prefabs)
	local crateModel = Instance.new("Model")
	crateModel.Name = "Crate_" .. crateType
	
	-- Create placeholder part
	local cratePart = Instance.new("Part")
	cratePart.Name = "CrateBody"
	cratePart.Size = Vector3.new(4, 4, 4)
	cratePart.TopSurface = Enum.SurfaceType.Smooth
	cratePart.BottomSurface = Enum.SurfaceType.Smooth
	cratePart.CanCollide = true
	cratePart.Anchored = false -- Procedural crates are not anchored
	
	-- Color based on crate type
	local crateColors = {
		["Normal"] = Color3.fromRGB(139, 69, 19), -- Brown
		["NormalPlus"] = Color3.fromRGB(160, 82, 45), -- Sienna
		["WeaponCrate"] = Color3.fromRGB(70, 130, 180), -- Steel blue
		["GrenadeBox"] = Color3.fromRGB(128, 128, 0), -- Olive
		["MedicalCrate"] = Color3.fromRGB(255, 255, 255), -- White
		["Elite"] = Color3.fromRGB(255, 215, 0), -- Gold
	}
	
	cratePart.Color = crateColors[crateType] or Color3.fromRGB(128, 128, 128)
	cratePart.Parent = crateModel
	
	-- Set as primary part
	crateModel.PrimaryPart = cratePart
	
	-- Set position
	crateModel:PivotTo(CFrame.new(position))
	
	-- Set crate attributes
	local crateConfig = LootConfig.GetCrateConfig(crateType)
	local crateId = string.format("%s_%d_%d", crateType, os.time(), math.random(1, 10000))
	
	crateModel:SetAttribute("CrateType", crateType)
	crateModel:SetAttribute("CrateId", crateId)
	crateModel:SetAttribute("MaxHealth", crateConfig.MaxHealth or 100)
	crateModel:SetAttribute("Health", crateConfig.MaxHealth or 100)
	crateModel:SetAttribute("CrackStage", 0)
	
	-- Add visual indicator for crate type (text label)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(6, 0, 2, 0)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = false
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = crateType
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = billboardGui
	
	billboardGui.Parent = cratePart
	
	-- Parent to workspace
	crateModel.Parent = Workspace
	
	-- Register with BreakableCrate component
	if self.BreakableCrateComponent then
		self.BreakableCrateComponent:RegisterCrate(crateModel)
	end
	
	return crateModel
end


-- Create singleton instance
local instance = LootSpawnService.new()

return instance
