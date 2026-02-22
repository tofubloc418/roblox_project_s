-- ModuleScript: OccupancyMap
-- Simple 2D grid data structure for spawn point management

local M = {
	grid = {},   -- 2D array of occupancy values
	cellSize = 10,
	totalWidth = 1900, -- Spawn area width (core land area only)
}

-- Occupancy types
M.OCCUPANCY_TYPES = {
	FREE = 0,        -- Available for spawn placement
	WATER = 2,       -- Water area (ocean)
	RESERVED = 3,    -- Reserved for spawn points
}

-- Initialize the occupancy grid
function M.initialize()
	local N = math.ceil(M.totalWidth / M.cellSize)
	
	-- Initialize all cells as FREE
	for ix = 1, N do
		M.grid[ix] = {}
		for iz = 1, N do
			M.grid[ix][iz] = M.OCCUPANCY_TYPES.FREE
		end
	end
	
	-- Automatically mark water areas outside the boundary
	M.markWaterAreas()
	
	return N
end

-- Convert world coordinates to grid indices
function M.worldToGridIndex(worldX, worldZ)
	local halfWidth = M.totalWidth / 2
	local ix = math.floor((worldX + halfWidth) / M.cellSize) + 1
	local iz = math.floor((worldZ + halfWidth) / M.cellSize) + 1
	return ix, iz
end

-- Check if grid indices are valid
function M.isValidIndex(ix, iz)
	local N = math.ceil(M.totalWidth / M.cellSize)
	return ix >= 1 and ix <= N and iz >= 1 and iz <= N
end

-- Mark a circular area with specified occupancy type
function M.markCircularArea(centerX, centerZ, radius, occupancyType)
	local minIX, minIZ = M.worldToGridIndex(centerX - radius, centerZ - radius)
	local maxIX, maxIZ = M.worldToGridIndex(centerX + radius, centerZ + radius)
	
	for ix = minIX, maxIX do
		for iz = minIZ, maxIZ do
			if M.isValidIndex(ix, iz) then
				local worldX = (ix - 0.5) * M.cellSize - M.totalWidth / 2
				local worldZ = (iz - 0.5) * M.cellSize - M.totalWidth / 2
				local distance = math.sqrt((worldX - centerX)^2 + (worldZ - centerZ)^2)
				if distance <= radius then
					M.grid[ix][iz] = occupancyType
				end
			end
		end
	end
end

-- Check if an area is free for spawn placement
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

-- Automatically mark water areas outside the boundary
function M.markWaterAreas()
	local halfWidth = M.totalWidth / 2
	local N = math.ceil(M.totalWidth / M.cellSize)
	
	-- Mark ocean areas (outside playable zone) as water
	for ix = 1, N do
		for iz = 1, N do
			local worldX = (ix - 0.5) * M.cellSize - halfWidth
			local worldZ = (iz - 0.5) * M.cellSize - halfWidth
			
			-- Mark as water if outside playable square area
			if math.abs(worldX) > halfWidth or math.abs(worldZ) > halfWidth then
				M.grid[ix][iz] = M.OCCUPANCY_TYPES.WATER
			end
		end
	end
	
	print(string.format("[OccupancyMap] Marked water areas outside %.1f x %.1f square bounds", 
		halfWidth * 2, halfWidth * 2))
end

return M 