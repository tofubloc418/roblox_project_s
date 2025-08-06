-- ServerScriptService/PrefabSpawner
-- Advanced prefab spawning system with priority-based placement, quadtree optimization, 
-- water occupancy mapping, and improved terrain integration.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain           = workspace.Terrain

-- BindableEvents
local terrainReadyEvt = ReplicatedStorage:WaitForChild("TerrainReady")
local prefabsReadyEvt = ReplicatedStorage:WaitForChild("PrefabsReady")

-- Modules
local Config       = require(ReplicatedStorage.Modules.TerrainConfig)
local Occupancy    = require(ReplicatedStorage.Modules.OccupancyMap)
local TerrainUtils = require(ReplicatedStorage.Modules.TerrainUtils)
local QuadTree     = require(ReplicatedStorage.Modules.QuadTree)
local RiverGenerator = require(ReplicatedStorage.Modules.RiverGenerator)

-- Design configuration modules
local DesignFolder = ReplicatedStorage:WaitForChild("Design", 5) -- Wait up to 5 seconds
if not DesignFolder then
	error("PrefabSpawner: Design folder not found in ReplicatedStorage after 5 seconds")
end
print("[PrefabSpawner] Found Design folder:", DesignFolder:GetFullName())

-- Asset storage (folders mirroring Design)
local AssetsRoot = ReplicatedStorage:WaitForChild("Assets", 5)
if not AssetsRoot then
	error("PrefabSpawner: Assets folder not found in ReplicatedStorage after 5 seconds")
end
print("[PrefabSpawner] Found Assets folder:", AssetsRoot:GetFullName())

-- Print contents of Design folder to help diagnose issues
for _, child in ipairs(DesignFolder:GetChildren()) do
	print("[PrefabSpawner] Found in Design folder:", child.Name, child.ClassName)
end

-- Constants
local CELL = Config.CELL_SIZE
local CORE_W = Config.CORE_WIDTH
local TOTAL_W = Config.TOTAL_WIDTH
local HALF_W = TOTAL_W / 2

-- Terrain modification settings
local TRANSITION_RADIUS = 5  -- studs for feathered blend
local H0_MODE = "avg"        -- "min" | "avg" | "max"
local FLATTEN_BUF = 5        -- studs extra around footprint for flattening

-- Building category priorities and settings
local BUILDING_CATEGORIES = {
	{
		name = "SpecialPrefabs",
		priority = 1,
		maxAttempts = 100,
		occupancyBuffer = 3, -- Reduced from 10
		requiresCentralPlacement = true
	},
	{
		name = "NormalPrefabs", 
		priority = 2,
		maxAttempts = 50,
		occupancyBuffer = 2, -- Reduced from 5
		requiresCentralPlacement = true
	},
	{
		name = "NaturePrefabs",
		priority = 3,
		maxAttempts = 25,
		occupancyBuffer = 1, -- Reduced from 2
		requiresCentralPlacement = false
	}
}

-- Global state
local quadTree = nil
local placementStats = {
	attempted = 0,
	successful = 0,
	failed = 0,
	byCategory = {}
}

-- Wait for terrain completion
print("[PrefabSpawner] Waiting for terrain to be ready...")
terrainReadyEvt.Event:Wait()
print("[PrefabSpawner] TerrainReady received; initializing systems...")

-- Initialize occupancy mapping system
local gridSize = Occupancy.initialize(TOTAL_W, CELL)
print(string.format("[PrefabSpawner] Initialized %dx%d occupancy grid", gridSize, gridSize))

-- Mark water areas in occupancy map
Occupancy.markWaterAreas(Config, RiverGenerator)

-- Mark river paths from generated rivers
local riverPaths = RiverGenerator.getRiverPaths()
for _, riverData in ipairs(riverPaths) do
	Occupancy.markPath(riverData.path, riverData.width, Occupancy.OCCUPANCY_TYPES.WATER)
	print(string.format("[PrefabSpawner] Marked %s river (width: %d)", riverData.type, riverData.width))
end

-- Initialize QuadTree for efficient spatial lookups
quadTree = QuadTree.new(0, 0, CORE_W, CORE_W, 4, Occupancy)
local quadStats = quadTree:getStats()
print(string.format("[PrefabSpawner] Initialized QuadTree: %d nodes, %.1f available area", 
	quadStats.nodeCount, quadStats.totalAvailableArea))

-- Raycast helper to find ground Y at (x,z)
local function getGroundY(x, z)
	local origin = Vector3.new(x, HALF_W + 500, z)
	local dir = Vector3.new(0, -(HALF_W + 500), 0)
	
	-- Create raycast params to ensure we hit terrain
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {} -- Don't filter anything
	
	local res = workspace:Raycast(origin, dir, raycastParams)
	if res then
		return res.Position.Y
	else
		-- Try a shorter raycast
		local shortOrigin = Vector3.new(x, 200, z)
		local shortDir = Vector3.new(0, -300, 0)
		local shortRes = workspace:Raycast(shortOrigin, shortDir, raycastParams)
		
		if shortRes then
			return shortRes.Position.Y
		else
			warn(string.format("❌ Raycast failed at (%.1f, %.1f) - using default height", x, z))
			return Config.MIN_LAND_HEIGHT
		end
	end
end

-- Calculate rotated footprint polygon at a specific world position
local function calculateRotatedFootprint(floorPart, rotation, centerX, centerZ)
	local size = floorPart.Size
	local halfX, halfZ = size.X/2, size.Z/2
	
	-- Define corner offsets relative to center
	local corners = {
		Vector3.new(-halfX, 0, -halfZ),
		Vector3.new( halfX, 0, -halfZ), 
		Vector3.new( halfX, 0,  halfZ),
		Vector3.new(-halfX, 0,  halfZ),
	}
	
	-- Apply rotation and convert to world space at the target position
	local rotationCFrame = CFrame.Angles(0, rotation, 0)
	local footprint = {}
	for _, corner in ipairs(corners) do
		local rotatedCorner = rotationCFrame:VectorToWorldSpace(corner)
		local worldCorner = Vector3.new(centerX + rotatedCorner.X, 0, centerZ + rotatedCorner.Z)
		table.insert(footprint, Vector2.new(worldCorner.X, worldCorner.Z))
	end
	
	return footprint, size
end

-- Advanced building placement with quadtree optimization
local function placeBuildingAdvanced(spec, buildingInstance, category)
	local buildingStats = {
		name = spec.Name,
		attempts = 0,
		candidates = 0,
		success = false,
		finalPos = Vector3.new(),
	}

	local floorPart = buildingInstance:FindFirstChild("MainFloor")
	if not floorPart then
		warn(string.format("[%s] ❌ MainFloor not found, cannot place.", spec.Name))
		return false, buildingStats
	end

	local rotation = math.random() * 2 * math.pi
	local size = floorPart.Size
	
	-- Use QuadTree to find potential placement candidates
	local candidates = quadTree:findPlacementCandidates(size.X, size.Z, category.occupancyBuffer, 50)
	buildingStats.candidates = #candidates
	
	if #candidates == 0 then
		-- This is expected for some buildings, so not a warning
		print(string.format("[%s] ℹ️ No placement candidates found.", spec.Name))
		return false, buildingStats
	end

	for i, candidate in ipairs(candidates) do
		buildingStats.attempts = i
		
		-- Use a single, reliable raycast to get ground height
		local groundY = getGroundY(candidate.x, candidate.z)
		print(string.format("🔍 [%s] Raycast detected height: %.1f at (%.1f, %.1f)", 
			spec.Name, groundY, candidate.x, candidate.z))
		
		if Occupancy.isAreaFree(candidate.x, candidate.z, size.X, size.Z, category.occupancyBuffer) then
			-- Calculate the footprint for THIS specific instance and rotation at the candidate position
			local footprint, _ = calculateRotatedFootprint(floorPart, rotation, candidate.x, candidate.z)
			
			print(string.format("📏 [%s] Building size: %.1fx%.1f, Stamp size with buffers: %.1fx%.1f", 
				spec.Name, size.X, size.Z, size.X + 2*(TRANSITION_RADIUS + FLATTEN_BUF), size.Z + 2*(TRANSITION_RADIUS + FLATTEN_BUF)))
			print(string.format("🎯 [%s] Footprint at: (%.1f, %.1f) with %d corners", 
				spec.Name, candidate.x, candidate.z, #footprint))
			
			-- Use the initial raycast height as the target height for flattening
			print(string.format("🎯 [%s] Using raycast height %.1f as target for flattening", spec.Name, groundY))
			TerrainUtils.FlattenPadToHeight(footprint, TRANSITION_RADIUS + FLATTEN_BUF, groundY, Terrain)
			
			-- Get the actual flattened terrain height after stamping
			local actualGroundY = getGroundY(candidate.x, candidate.z)
			print(string.format("🏗️ [%s] Terrain modified, new height: %.1f", spec.Name, actualGroundY))
			
			-- Position building precisely on the flattened terrain
			local pivotOffset = floorPart.Position - buildingInstance:GetPivot().Position
			local finalPivot = Vector3.new(candidate.x, actualGroundY + size.Y/2, candidate.z) - Vector3.new(0, pivotOffset.Y, 0)
			
			print(string.format("🧮 [%s] Height calc: terrain=%.1f + halfHeight=%.1f - pivotOffset=%.1f = %.1f", 
				spec.Name, actualGroundY, size.Y/2, pivotOffset.Y, finalPivot.Y))
			print(string.format("⚠️ [%s] Initial ground: %.1f, Final ground: %.1f, Building Y: %.1f", 
				spec.Name, groundY, actualGroundY, finalPivot.Y))
			
			-- Ensure we have a PrimaryPart set before using SetPrimaryPartCFrame
			buildingInstance.PrimaryPart = floorPart
			buildingInstance:SetPrimaryPartCFrame(CFrame.new(finalPivot) * CFrame.Angles(0, rotation, 0))
			
			-- Get the actual final position of the MainFloor part
			local actualMainFloorPos = floorPart.Position
			print(string.format("📍 [%s] MainFloor placed at Y=%.1f (planned: %.1f)", 
				spec.Name, actualMainFloorPos.Y, finalPivot.Y))
			
			-- Mark occupancy in both systems
			quadTree:markAreaOccupied(candidate.x, candidate.z, size.X, size.Z, category.occupancyBuffer)
			
			print(string.format("[%s] ✅ Placed at (%.1f, %.1f, %.1f) - Attempt %d, Rotation %.0f°", 
				spec.Name, finalPivot.X, finalPivot.Y, finalPivot.Z, i, math.deg(rotation)))

			buildingStats.success = true
			buildingStats.finalPos = finalPivot
			return true, buildingStats
		end
	end

	warn(string.format("[%s] ❌ Failed to place after %d attempts", spec.Name, #candidates))
	return false, buildingStats
end

-- Main spawning logic with priority-based system
local function spawnByPriority()
	for _, category in ipairs(BUILDING_CATEGORIES) do
		print(string.format("[PrefabSpawner] Processing category: %s", category.name))
		
		local configModule = DesignFolder:FindFirstChild(category.name)
		if not configModule then
			warn(string.format("[PrefabSpawner] ❌ Config module '%s' not found in Design folder", category.name))
			continue
		end
		print(string.format("[PrefabSpawner] Found config module: %s (%s)", configModule.Name, configModule.ClassName))
		
		local assetFolder = AssetsRoot:FindFirstChild(category.name)
		if not assetFolder then
			warn(string.format("[PrefabSpawner] ❌ Asset folder '%s' not found in Assets folder", category.name))
			continue
		end
		print(string.format("[PrefabSpawner] Found asset folder: %s (%s)", assetFolder.Name, assetFolder.ClassName))
		
		-- Initialize category stats
		placementStats.byCategory[category.name] = {
			attempted = 0,
			successful = 0,
			failed = 0
		}
		
		local success, specs = pcall(function() return require(configModule) end)
		if not success then
			warn(string.format("[PrefabSpawner] ❌ Failed to require module '%s': %s", category.name, tostring(specs)))
			continue
		end
		
		if type(specs) ~= "table" then
			warn(string.format("[PrefabSpawner] ❌ Module '%s' did not return a table", category.name))
			continue
		end
		
		print(string.format("[PrefabSpawner] Starting %s spawning (Priority %d) - Found %d specs", 
			category.name, category.priority, #specs))
		
		for _, spec in ipairs(specs) do
			local template = assetFolder:FindFirstChild(spec.Name)
			if not template then
				warn("PrefabSpawner: missing asset model", spec.Name)
				continue
			end
			
			local successCount = 0
			for i = 1, spec.Count do
				placementStats.byCategory[category.name].attempted = 
					placementStats.byCategory[category.name].attempted + 1
				placementStats.attempted = placementStats.attempted + 1
				
				-- Clone the template for this instance
				local buildingInstance = template:Clone()
				buildingInstance.Parent = workspace
				
				local placementSuccess, _ = placeBuildingAdvanced(spec, buildingInstance, category)
				if placementSuccess then
					successCount = successCount + 1
					placementStats.byCategory[category.name].successful = 
						placementStats.byCategory[category.name].successful + 1
					placementStats.successful = placementStats.successful + 1
				else
					-- Clean up the failed instance
					buildingInstance:Destroy()
					placementStats.byCategory[category.name].failed = 
						placementStats.byCategory[category.name].failed + 1
					placementStats.failed = placementStats.failed + 1
				end
			end
			
			print(string.format("[%s] Placed %d/%d instances", 
				spec.Name, successCount, spec.Count))
		end
		
		print(string.format("[PrefabSpawner] Completed %s: %d/%d successful", 
			category.name, 
			placementStats.byCategory[category.name].successful,
			placementStats.byCategory[category.name].attempted))
	end
end

-- Execute spawning system
spawnByPriority()

-- Print final statistics
print("\n[PrefabSpawner] === FINAL STATISTICS ===")
print(string.format("Total: %d/%d successful (%.1f%%)", 
	placementStats.successful, placementStats.attempted,
	(placementStats.successful / math.max(1, placementStats.attempted)) * 100))

for category, stats in pairs(placementStats.byCategory) do
	local successRate = (stats.successful / math.max(1, stats.attempted)) * 100
	print(string.format("%s: %d/%d successful (%.1f%%)", 
		category, stats.successful, stats.attempted, successRate))
end

local finalQuadStats = quadTree:getStats()
print(string.format("Remaining available area: %.1f", finalQuadStats.totalAvailableArea))

print("[PrefabSpawner] All prefabs spawned; firing PrefabsReady.")
prefabsReadyEvt:Fire()