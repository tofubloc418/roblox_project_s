-- ModuleScript: OccupancyMap
-- Shared 2D boolean grid of "taken" cells with support for different occupancy types

local M = {
	grid = nil,   -- will be a 2D array of occupancy values
	cellSize = nil,
	totalWidth = nil,
	_debugCount = 0, -- Debug counter for logging
}

-- Occupancy types
M.OCCUPANCY_TYPES = {
	FREE = 0,        -- Available for building placement
	BUILDING = 1,    -- Occupied by a building
	WATER = 2,       -- Water area (rivers, ocean)
	RESERVED = 3,    -- Reserved for special purposes
}

-- Initialize the occupancy grid
function M.initialize(totalWidth, cellSize)
	local N = math.ceil(totalWidth / cellSize)
	M.cellSize = cellSize
	M.totalWidth = totalWidth
	M.grid = {}
	
	for ix = 1, N do
		M.grid[ix] = {}
		for iz = 1, N do
			M.grid[ix][iz] = M.OCCUPANCY_TYPES.FREE
		end
	end
	
	return N -- Return grid size for convenience
end

-- Convert world coordinates to grid indices
function M.worldToGridIndex(worldX, worldZ)
	local halfWidth = M.totalWidth / 2
	local ix = math.floor((worldX + halfWidth) / M.cellSize) + 1
	local iz = math.floor((worldZ + halfWidth) / M.cellSize) + 1
	return ix, iz
end

-- Convert grid indices to world coordinates (center of cell)
function M.gridToWorldPos(ix, iz)
	local halfWidth = M.totalWidth / 2
	local worldX = (ix - 0.5) * M.cellSize - halfWidth
	local worldZ = (iz - 0.5) * M.cellSize - halfWidth
	return worldX, worldZ
end

-- Check if grid indices are valid
function M.isValidIndex(ix, iz)
	local N = math.ceil(M.totalWidth / M.cellSize)
	return ix >= 1 and ix <= N and iz >= 1 and iz <= N
end

-- Mark a rectangular area with specified occupancy type
function M.markRectangularArea(centerX, centerZ, width, height, occupancyType)
	local halfWidth, halfHeight = width / 2, height / 2
	local minX, maxX = centerX - halfWidth, centerX + halfWidth
	local minZ, maxZ = centerZ - halfHeight, centerZ + halfHeight
	
	local minIX, minIZ = M.worldToGridIndex(minX, minZ)
	local maxIX, maxIZ = M.worldToGridIndex(maxX, maxZ)
	
	for ix = minIX, maxIX do
		for iz = minIZ, maxIZ do
			if M.isValidIndex(ix, iz) then
				M.grid[ix][iz] = occupancyType
			end
		end
	end
end

-- Mark a circular area with specified occupancy type
function M.markCircularArea(centerX, centerZ, radius, occupancyType)
	local minIX, minIZ = M.worldToGridIndex(centerX - radius, centerZ - radius)
	local maxIX, maxIZ = M.worldToGridIndex(centerX + radius, centerZ + radius)
	
	for ix = minIX, maxIX do
		for iz = minIZ, maxIZ do
			if M.isValidIndex(ix, iz) then
				local worldX, worldZ = M.gridToWorldPos(ix, iz)
				local distance = math.sqrt((worldX - centerX)^2 + (worldZ - centerZ)^2)
				if distance <= radius then
					M.grid[ix][iz] = occupancyType
				end
			end
		end
	end
end

-- Mark a path (like rivers) with specified width and occupancy type
function M.markPath(pathPoints, width, occupancyType)
	local halfWidth = width / 2
	
	for i = 1, #pathPoints - 1 do
		local p1, p2 = pathPoints[i], pathPoints[i + 1]
		local dir = p2 - p1
		local length = dir.Magnitude
		local steps = math.max(1, math.ceil(length / M.cellSize))
		
		for step = 0, steps do
			local t = step / steps
			local pos = p1:Lerp(p2, t)
			M.markCircularArea(pos.X, pos.Z, halfWidth, occupancyType)
		end
	end
end

-- Check if an area is free for building placement
function M.isAreaFree(centerX, centerZ, width, height, buffer)
	buffer = buffer or 0
	local totalWidth, totalHeight = width + buffer * 2, height + buffer * 2
	local halfWidth, halfHeight = totalWidth / 2, totalHeight / 2
	
	local minX, maxX = centerX - halfWidth, centerX + halfWidth
	local minZ, maxZ = centerZ - halfHeight, centerZ + halfHeight
	
	local minIX, minIZ = M.worldToGridIndex(minX, minZ)
	local maxIX, maxIZ = M.worldToGridIndex(maxX, maxZ)
	
	for ix = minIX, maxIX do
		for iz = minIZ, maxIZ do
			if not M.isValidIndex(ix, iz) then
				return false -- Outside map bounds
			end
			
			local cellType = M.grid[ix][iz]
			if cellType ~= M.OCCUPANCY_TYPES.FREE then
				return false -- Already occupied
			end
		end
	end
	
	return true
end

-- Mark water areas based on terrain configuration
function M.markWaterAreas(Config, RiverGenerator)
	-- Mark ocean areas (outside the core + rim area)
	local coreWidth = Config.CORE_WIDTH
	local rimWidth = Config.SAND_RIM_WIDTH
	local playableHalfWidth = (coreWidth + rimWidth) / 2
	
	-- First mark everything as free
	local N = math.ceil(M.totalWidth / M.cellSize)
	for ix = 1, N do
		for iz = 1, N do
			M.grid[ix][iz] = M.OCCUPANCY_TYPES.FREE
		end
	end
	
	-- Then mark ocean areas (outside playable zone) as water using square bounds
	for ix = 1, N do
		for iz = 1, N do
			local worldX, worldZ = M.gridToWorldPos(ix, iz)
			
			-- Mark as water if outside playable square area
			if math.abs(worldX) > playableHalfWidth or math.abs(worldZ) > playableHalfWidth then
				M.grid[ix][iz] = M.OCCUPANCY_TYPES.WATER
			end
		end
	end
	
	print(string.format("[OccupancyMap] Marked water areas outside %.1f x %.1f square bounds", 
		playableHalfWidth * 2, playableHalfWidth * 2))
	
end

return M
