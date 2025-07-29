-- ServerScriptService/PrefabSpawner

-- Waits for terrain to be ready, then places prefabs from Design configs,
-- uses TerrainUtils to flatten footprint pads with smooth transitions,
-- maintains a shared occupancy grid, and signals PrefabsReady.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain           = workspace.Terrain

-- BindableEvents
local terrainReadyEvt = ReplicatedStorage:WaitForChild("TerrainReady")
local prefabsReadyEvt = ReplicatedStorage:WaitForChild("PrefabsReady")

-- Modules
local Config       = require(ReplicatedStorage.Modules.TerrainConfig)
local Occupancy    = require(ReplicatedStorage.Modules.OccupancyMap)
local TerrainUtils = require(ReplicatedStorage.Modules.TerrainUtils)

-- Design configuration modules
local DesignFolder = ReplicatedStorage:WaitForChild("Design")
local Categories   = { "SpecialPrefabs", "NormalPrefabs", "NaturePrefabs" }

-- Asset storage (folders mirroring Design)
local AssetsRoot = ReplicatedStorage:WaitForChild("Assets")

-- Constants
local CELL             = Config.CELL_SIZE
local CORE_W           = Config.CORE_WIDTH
local TOTAL_W          = Config.TOTAL_WIDTH
local HALF_W           = TOTAL_W / 2
local TRANSITION_RADIUS= 5       -- studs for feathered blend
local H0_MODE          = "avg"   -- "min" | "avg" | "max"
local FLATTEN_BUF      = 5       -- studs extra around footprint for flattening
local OCCUPY_BUF       = 5       -- studs extra for occupancy buffer

-- Initialize occupancy grid
local N = math.ceil(TOTAL_W / CELL)
Occupancy.cellSize   = CELL
Occupancy.totalWidth = TOTAL_W
Occupancy.grid = {}
for ix = 1, N do
	Occupancy.grid[ix] = {}
	for iz = 1, N do
		Occupancy.grid[ix][iz] = false
	end
end

-- Helpers: world-coordinate to grid index
local function worldToI(x)
	return math.floor((x + HALF_W) / CELL) + 1
end
local function worldToJ(z)
	return math.floor((z + HALF_W) / CELL) + 1
end

-- Build list of core-area cell coords for sampling
local coreMinI = worldToI(-CORE_W/2)
local coreMaxI = worldToI( CORE_W/2)
local coreCells = {}
for ix = coreMinI, coreMaxI do
	for iz = coreMinI, coreMaxI do
		if ix >= 1 and ix <= N and iz >= 1 and iz <= N then -- bounds check
			table.insert(coreCells, { ix = ix, iz = iz })
		end
	end
end

print(string.format("[PrefabSpawner] Core area: cells %d to %d (total %d cells available)", coreMinI, coreMaxI, #coreCells))
print(string.format("[PrefabSpawner] Core width: %d studs, Cell size: %d studs, Grid size: %dx%d", CORE_W, CELL, N, N))

-- Sample a random free cell in the plateau core
local function sampleFreeCell()
	while #coreCells > 0 do
		local idx = math.random(#coreCells)
		local cell = table.remove(coreCells, idx)
		if not Occupancy.grid[cell.ix][cell.iz] then
			local x = (cell.ix - 0.5) * CELL - HALF_W
			local z = (cell.iz - 0.5) * CELL - HALF_W
			return x, z, cell.ix, cell.iz
		end
	end
	error("PrefabSpawner: no free cells left to sample!")
end

-- Mark occupancy grid cells under buffered footprint
local function markOccupancy(ix, iz, halfCellsX, halfCellsZ)
	local minI = math.max(1, math.floor(ix - halfCellsX))
	local maxI = math.min(N, math.ceil(ix + halfCellsX))
	local minJ = math.max(1, math.floor(iz - halfCellsZ))
	local maxJ = math.min(N, math.ceil(iz + halfCellsZ))
	for x = minI, maxI do
		for z = minJ, maxJ do
			Occupancy.grid[x][z] = true
		end
	end
end

-- Wait for terrain completion
print("[PrefabSpawner] Waiting for terrain to be ready...")
terrainReadyEvt.Event:Wait()
print("[PrefabSpawner] TerrainReady received; spawning prefabs...")

-- Raycast helper to find ground Y at (x,z)
local function getGroundY(x, z)
	local origin = Vector3.new(x, HALF_W + 500, z)
	local dir    = Vector3.new(0, -(HALF_W + 500), 0)
	local res    = workspace:Raycast(origin, dir)
	if res then
		return res.Position.Y
	else
		warn("PrefabSpawner: raycast failed at", x, z, "- using Y=0")
		return 0
	end
end

-- Main spawning logic: by category priority, using MainFloor part
for _, category in ipairs(Categories) do
	local configModule = DesignFolder:FindFirstChild(category)
	local assetFolder  = AssetsRoot:FindFirstChild(category)
	if not configModule or not assetFolder then
		warn("PrefabSpawner: missing config or assets for category", category)
		continue
	end
	local specs = require(configModule)
	for _, spec in ipairs(specs) do
		local template = assetFolder:FindFirstChild(spec.Name)
		if not template then
			warn("PrefabSpawner: missing asset model", spec.Name)
			continue
		end
		for i = 1, spec.Count do
			-- 1) pick a free cell
			local x, z, ix, iz = sampleFreeCell()
			print(string.format("[%s #%d] Sampled cell (%d,%d) -> world pos (%.1f, %.1f)", spec.Name, i, ix, iz, x, z))

			-- 2) clone model 
			local clone = template:Clone()
			clone.Parent = workspace

			-- 3) Position model at sampled location FIRST (before rotation)
			local modelPivot = clone:GetPivot()
			clone:PivotTo(CFrame.new(x, modelPivot.Y, z) * (modelPivot - modelPivot.Position))

			-- 4) Apply random rotation around Y axis
			local randomRotationY = math.random() * math.pi * 2
			local rotationCFrame = CFrame.Angles(0, randomRotationY, 0)
			local currentPivot = clone:GetPivot()
			clone:PivotTo(currentPivot * rotationCFrame)

			-- 5) Get MainFloor footprint (should now be centered at x,z)
			local floorPart = clone:FindFirstChild("MainFloor")
			local fc, fs
			if floorPart and floorPart:IsA("BasePart") then
				fc, fs = floorPart.CFrame, floorPart.Size
				print(string.format("[%s #%d] MainFloor found: size %.1fx%.1f at (%.1f, %.1f)", spec.Name, i, fs.X, fs.Z, fc.X, fc.Z))
			else
				fc, fs = clone:GetBoundingBox()
				print(string.format("[%s #%d] No MainFloor, using bounding box: size %.1fx%.1f at (%.1f, %.1f)", spec.Name, i, fs.X, fs.Z, fc.X, fc.Z))
			end

			-- 6) Create footprint polygon for terrain flattening
			local halfX, halfZ = fs.X/2, fs.Z/2
			local corners = {
				Vector3.new(-halfX, 0, -halfZ),
				Vector3.new( halfX, 0, -halfZ),
				Vector3.new( halfX, 0,  halfZ),
				Vector3.new(-halfX, 0,  halfZ),
			}

			local footprint = {}
			for _, corner in ipairs(corners) do
				local worldCorner = fc:PointToWorldSpace(corner)
				table.insert(footprint, Vector2.new(worldCorner.X, worldCorner.Z))
			end

			-- 7) flatten pad with transition and smoothing
			TerrainUtils.FlattenPadWithTransition(
				footprint,
				TRANSITION_RADIUS + FLATTEN_BUF,
				H0_MODE,
				Terrain
			)

			-- 8) reposition clone so floor bottom aligns to pad
			local groundY = getGroundY(fc.X, fc.Z)
			local bottomY = fc.Y - (fs.Y/2)
			local deltaY  = groundY - bottomY

			-- Move the model up/down while preserving rotation
			local currentPivot = clone:GetPivot()
			local newPivot = currentPivot + Vector3.new(0, deltaY, 0)
			clone:PivotTo(newPivot)

			-- 9) mark occupancy with buffer (use MainFloor dimensions as square)
			local floorHalfX = fs.X/2
			local floorHalfZ = fs.Z/2
			local halfCellsX = (floorHalfX + OCCUPY_BUF) / CELL
			local halfCellsZ = (floorHalfZ + OCCUPY_BUF) / CELL
			print(string.format("[%s #%d] Marking occupancy: %.1fx%.1f + %d buffer = %.1fx%.1f cells", spec.Name, i, fs.X, fs.Z, OCCUPY_BUF, halfCellsX*2, halfCellsZ*2))
			markOccupancy(ix, iz, halfCellsX, halfCellsZ)

			-- Final position for debugging
			local finalPivot = clone:GetPivot()
			print(string.format("[%s #%d] Final world position: (%.1f, %.1f, %.1f)", spec.Name, i, finalPivot.X, finalPivot.Y, finalPivot.Z))
		end
		print("[PrefabSpawner] Placed", spec.Name, "×", spec.Count)
	end
end

print("[PrefabSpawner] All prefabs spawned; firing PrefabsReady.")
prefabsReadyEvt:Fire()