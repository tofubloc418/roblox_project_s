-- ModuleScript: RiverGenerator
-- Stamps simple straight rivers (no slope) into height & material maps

local Config = require(script.Parent.TerrainConfig)

local CELL           = Config.CELL_SIZE
local TOTAL_W			= Config.TOTAL_WIDTH
local SEA_Y          = Config.MIN_LAND_HEIGHT

local RIVER_BOTTOM   = Config.RIVER_BOTTOM_HEIGHT
local RIVER_WIDTH    = Config.RIVER_WIDTH
local TRIB_MIN       = Config.TRIB_MIN
local TRIB_MAX       = Config.TRIB_MAX
local SEED_RIVER     = Config.SEED_RIVER

local RiverGenerator = {}

-- Store generated river paths for occupancy mapping
RiverGenerator.generatedPaths = {}

-- Convert world X or Z to map index
local function ix_from_x(x)
	return math.floor((x + TOTAL_W / 2) / CELL) + 1
end
local function iz_from_z(z)
	return math.floor((z + TOTAL_W / 2) / CELL) + 1
end

-- Generate a meandering path via midpoint displacement
function RiverGenerator.generateRiverPath(p0, p1, iterations, maxDisp)
	math.randomseed(SEED_RIVER)
	local path = {p0, p1}
	for i = 1, iterations do
		local newPath = {}
		for j = 1, #path - 1 do
			local a, b = path[j], path[j+1]
			table.insert(newPath, a)
			local mid = (a + b) * 0.5
			local dir = (b - a)
			local perp = Vector3.new(-dir.Z, 0, dir.X).Unit
			local offsetAmt = (math.random() * 2 - 1) * maxDisp
			mid = Vector3.new(mid.X, SEA_Y, mid.Z) + perp * offsetAmt
			table.insert(newPath, mid)
		end
		table.insert(newPath, path[#path])
		path = newPath
		maxDisp = maxDisp * 0.5
	end
	return path
end

-- Stamp a path into the height & material maps
function RiverGenerator.stamp(height_map, mat_map)
	-- Clear previous paths
	RiverGenerator.generatedPaths = {}
	
	-- Main stem
	local theta = math.random() * math.pi
	local dx, dz = math.cos(theta), math.sin(theta)
	local pA = Vector3.new(-dx * (TOTAL_W/2), SEA_Y, -dz * (TOTAL_W/2))
	local pB = Vector3.new( dx * (TOTAL_W/2), SEA_Y,  dz * (TOTAL_W/2))

	local paths = {}
	local mainPath = RiverGenerator.generateRiverPath(pA, pB, 3, TOTAL_W * 0.2)
	table.insert(paths, {path = mainPath, width = RIVER_WIDTH, type = "main"})
	
	-- Tributaries
	local nTrib = math.random(TRIB_MIN, TRIB_MAX)
	for i = 1, nTrib do
		local ang    = math.random() * 2 * math.pi
		local rstart = TOTAL_W/2 * (0.8 + math.random() * 0.2)
		local startP = Vector3.new(math.cos(ang) * rstart, SEA_Y, math.sin(ang) * rstart)
		local endP   = pA:Lerp(pB, math.random())
		local tribPath = RiverGenerator.generateRiverPath(startP, endP, 2, TOTAL_W * 0.1)
		table.insert(paths, {path = tribPath, width = Config.TRIB_WIDTH, type = "tributary"})
	end

	-- Store paths for occupancy mapping
	RiverGenerator.generatedPaths = paths

	for idx, pathData in ipairs(paths) do
		local path = pathData.path
		local riverW = pathData.width
		local halfW  = riverW / 2

		for i = 1, #path - 1 do
			local a, b = path[i], path[i+1]
			local dir   = b - a
			local length= dir.Magnitude
			local steps = math.max(1, math.ceil(length / CELL))
			for s = 0, steps do
				local t      = s / steps
				local center = a:Lerp(b, t)

				for ox = -halfW, halfW, CELL do
					for oz = -halfW, halfW, CELL do
						if math.abs(ox) + math.abs(oz) <= halfW then
							local wx = center.X + ox
							local wz = center.Z + oz
							local ix = ix_from_x(wx)
							local iz = iz_from_z(wz)
							if height_map[ix] and height_map[ix][iz] then
								height_map[ix][iz] = RIVER_BOTTOM
								mat_map[ix][iz]    = Config.BEACH_MAT
							end
						end
					end
				end
			end
		end
	end
end

-- Get generated river paths for occupancy mapping
function RiverGenerator.getRiverPaths()
	return RiverGenerator.generatedPaths
end

return RiverGenerator
