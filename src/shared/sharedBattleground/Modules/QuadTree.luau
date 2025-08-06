-- ModuleScript: QuadTree
-- Spatial partitioning for efficient building placement

local QuadTree = {}
QuadTree.__index = QuadTree

-- QuadTree node structure
local function createNode(x, z, width, height, depth)
	return {
		x = x,
		z = z,
		width = width,
		height = height,
		depth = depth,
		children = nil,  -- Will be array of 4 children when subdivided
		availableArea = width * height,  -- Track available space
		isLeaf = true,
		occupancyGrid = nil,  -- Reference to occupancy grid section
	}
end

-- Create a new QuadTree
function QuadTree.new(centerX, centerZ, totalWidth, totalHeight, maxDepth, occupancyMap)
	local self = setmetatable({}, QuadTree)
	
	self.maxDepth = maxDepth or 6
	self.minNodeSize = totalWidth / (2^maxDepth)
	self.occupancyMap = occupancyMap
	self.root = createNode(centerX, centerZ, totalWidth, totalHeight, 0)
	
	-- Build the tree
	self:subdivide(self.root)
	self:updateAvailableAreas(self.root)
	
	return self
end

-- Subdivide a node into 4 children
function QuadTree:subdivide(node)
	if node.depth >= self.maxDepth or node.width <= self.minNodeSize then
		return
	end
	
	local halfW, halfH = node.width / 2, node.height / 2
	local quarterW, quarterH = halfW / 2, halfH / 2
	
	node.children = {
		createNode(node.x - quarterW, node.z - quarterH, halfW, halfH, node.depth + 1), -- NW
		createNode(node.x + quarterW, node.z - quarterH, halfW, halfH, node.depth + 1), -- NE
		createNode(node.x - quarterW, node.z + quarterH, halfW, halfH, node.depth + 1), -- SW
		createNode(node.x + quarterW, node.z + quarterH, halfW, halfH, node.depth + 1), -- SE
	}
	node.isLeaf = false
	
	-- Recursively subdivide children
	for _, child in ipairs(node.children) do
		self:subdivide(child)
	end
end

-- Update available areas based on occupancy map
function QuadTree:updateAvailableAreas(node)
	if node.isLeaf then
		-- Calculate available area by checking occupancy map
		local cellSize = self.occupancyMap.cellSize
		local samples = math.max(4, math.floor(node.width / cellSize / 2)) -- More samples for better accuracy
		
		local totalSamples = 0
		local freeSamples = 0
		
		for i = 0, samples do
			for j = 0, samples do
				local x = node.x - node.width/2 + (i/samples) * node.width
				local z = node.z - node.height/2 + (j/samples) * node.height
				totalSamples = totalSamples + 1
				
				-- Only check if within core area (where buildings should spawn)
				local distFromCenter = math.sqrt(x*x + z*z)
				local coreRadius = 500 -- CORE_W / 2, only check grass area
				
				if distFromCenter <= coreRadius then
					local ix, iz = self.occupancyMap.worldToGridIndex(x, z)
					
					if self.occupancyMap.isValidIndex(ix, iz) and 
					   self.occupancyMap.grid[ix][iz] == self.occupancyMap.OCCUPANCY_TYPES.FREE then
						freeSamples = freeSamples + 1
					end
				end
			end
		end
		
		-- Calculate free area as proportion of total node area
		local freeRatio = totalSamples > 0 and (freeSamples / totalSamples) or 0
		node.availableArea = freeRatio * node.width * node.height
	else
		-- Sum available area from children
		node.availableArea = 0
		for _, child in ipairs(node.children) do
			self:updateAvailableAreas(child)
			node.availableArea = node.availableArea + child.availableArea
		end
	end
end

-- Find best placement candidates for a building footprint
function QuadTree:findPlacementCandidates(footprintWidth, footprintHeight, buffer, maxCandidates)
	buffer = buffer or 0
	maxCandidates = maxCandidates or 10
	
	local requiredWidth = footprintWidth + buffer * 2
	local requiredHeight = footprintHeight + buffer * 2
	local requiredArea = requiredWidth * requiredHeight
	
	local candidates = {}
	
	local function searchNode(node)
		if #candidates >= maxCandidates then
			return
		end
		
		-- Skip nodes that are too small or have no available area
		if node.availableArea < requiredArea then
			return
		end
		
		if node.width < requiredWidth or node.height < requiredHeight then
			return
		end
		
		if node.isLeaf then
			-- Check if this area can actually fit the building
			local areaIsFree = self.occupancyMap.isAreaFree(node.x, node.z, footprintWidth, footprintHeight, buffer)
			
			if areaIsFree then
				table.insert(candidates, {
					x = node.x,
					z = node.z,
					availableArea = node.availableArea,
					priority = node.availableArea / requiredArea -- Preference for larger available areas
				})
			end
		else
			-- Sort children by available area (descending)
			local sortedChildren = {}
			for _, child in ipairs(node.children) do
				table.insert(sortedChildren, child)
			end
			table.sort(sortedChildren, function(a, b) 
				return a.availableArea > b.availableArea 
			end)
			
			-- Search children in order of available area
			for _, child in ipairs(sortedChildren) do
				searchNode(child)
			end
		end
	end
	
	searchNode(self.root)
	
	-- Sort candidates by priority (higher is better)
	table.sort(candidates, function(a, b) return a.priority > b.priority end)
	
	return candidates
end

-- Update the tree after placing a building
function QuadTree:markAreaOccupied(centerX, centerZ, width, height, buffer)
	buffer = buffer or 0
	self.occupancyMap.markRectangularArea(
		centerX, centerZ, 
		width + buffer * 2, height + buffer * 2, 
		self.occupancyMap.OCCUPANCY_TYPES.BUILDING
	)
	
	-- Update available areas
	self:updateAvailableAreas(self.root)
end

-- Get statistics about the quadtree
function QuadTree:getStats()
	local function countNodes(node)
		if node.isLeaf then
			return 1, node.availableArea
		else
			local totalNodes, totalArea = 1, 0
			for _, child in ipairs(node.children) do
				local childNodes, childArea = countNodes(child)
				totalNodes = totalNodes + childNodes
				totalArea = totalArea + childArea
			end
			return totalNodes, totalArea
		end
	end
	
	local nodeCount, totalAvailableArea = countNodes(self.root)
	return {
		nodeCount = nodeCount,
		totalAvailableArea = totalAvailableArea,
		maxDepth = self.maxDepth,
		minNodeSize = self.minNodeSize
	}
end

return QuadTree 