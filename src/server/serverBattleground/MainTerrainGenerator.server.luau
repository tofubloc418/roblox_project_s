-- ServerScriptService/MainTerrainGenerator

-- Builds the plateau, rim, stamps rivers, fills land & water, then signals TerrainReady.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Terrain           = workspace.Terrain

local Config         = require(ReplicatedStorage.Modules.TerrainConfig)
local RiverGenerator = require(ReplicatedStorage.Modules.RiverGenerator)

-- Phase-completion event
local terrainReadyEvt = ReplicatedStorage:WaitForChild("TerrainReady")

-- Constants from config
local CELL             = Config.CELL_SIZE
local CORE_WIDTH       = Config.CORE_WIDTH            -- e.g. 1000
local RIM_WIDTH        = Config.SAND_RIM_WIDTH         -- e.g. 300
local TOTAL_WIDTH      = CORE_WIDTH + 2 * RIM_WIDTH    -- e.g. 1600
local MIN_LAND_HEIGHT  = Config.MIN_LAND_HEIGHT        -- e.g. 15
local RIVER_BOTTOM     = Config.RIVER_BOTTOM_HEIGHT    -- e.g. 10
local RIVER_WIDTH      = Config.RIVER_WIDTH

local WATER_MAT        = Config.WATER_MAT

-- Derived values
local HALF_TOTAL       = TOTAL_WIDTH / 2
local CELLS_PER_SIDE   = math.floor(TOTAL_WIDTH / CELL)

-- Convenience: Perlin noise for plateau
local function noise2(x, z)
	return math.noise(x, z, Config.SEED_MAIN)
end

-- Build height & material maps
local function buildMaps()
	local height_map = {}
	local mat_map    = {}
	for ix = 1, CELLS_PER_SIDE do
		height_map[ix] = {}
		mat_map[ix]    = {}
		for iz = 1, CELLS_PER_SIDE do
			local x = (ix - 1) * CELL - HALF_TOTAL
			local z = (iz - 1) * CELL - HALF_TOTAL
			local ax = math.max(math.abs(x), math.abs(z))
			local h, m

			if ax <= CORE_WIDTH / 2 then
				-- plateau: Perlin noise + minimum height
				local raw = noise2(x / Config.HEIGHT_NOISE_S, z / Config.HEIGHT_NOISE_S) * Config.NOISE_AMPLITUDE
				h = math.max(raw + MIN_LAND_HEIGHT, MIN_LAND_HEIGHT)
				m = Config.LAND_MAT

			elseif ax <= HALF_TOTAL then
				-- sloping sand rim from MIN_LAND_HEIGHT --> 1
				local dist = ax - (CORE_WIDTH / 2)              -- 0 → RIM_WIDTH
				local t    = dist / RIM_WIDTH                   -- 0 → 1
				h = MIN_LAND_HEIGHT - (MIN_LAND_HEIGHT - 1) * t
				m = Config.BEACH_MAT

			else
				-- outside bounds; leave nil
				h = nil
				m = nil
			end

			height_map[ix][iz] = h
			mat_map[ix][iz]    = m
		end
	end

	return height_map, mat_map
end

-- Stamp rivers: carve to air then fill sand bottom
local function stampRivers(height_map, mat_map)
	-- RiverGenerator should override height_map[ix][iz] and mat_map[ix][iz]
	RiverGenerator.stamp(height_map, mat_map)
end

-- Batch-fill terrain and water
local function fillAll(height_map, mat_map)
	Terrain:Clear()

	-- Flatten all cells once
	local cells = {}
	for ix = 1, CELLS_PER_SIDE do
		for iz = 1, CELLS_PER_SIDE do
			local h = height_map[ix][iz]
			if h then
				table.insert(cells, { ix = ix, iz = iz, h = h, m = mat_map[ix][iz] })
			end
		end
	end

	local total     = #cells
	local batchSize = 20000
	local index     = 1
	local conn

	conn = RunService.Heartbeat:Connect(function()
		local count = 0
		while index <= total and count < batchSize do
			local e  = cells[index]
			local wx = (e.ix - 1) * CELL - HALF_TOTAL
			local wz = (e.iz - 1) * CELL - HALF_TOTAL

			-- fill land/sand
			Terrain:FillBlock(
				CFrame.new(wx, e.h / 2, wz),
				Vector3.new(CELL, e.h, CELL),
				e.m
			)

			-- fill water up to MIN_LAND_HEIGHT
			if e.h < MIN_LAND_HEIGHT then
				local waterH = MIN_LAND_HEIGHT - e.h
				Terrain:FillBlock(
					CFrame.new(wx, e.h + waterH / 2, wz),
					Vector3.new(CELL, waterH, CELL),
					WATER_MAT
				)
			end

			index += 1
			count += 1
		end

		if index > total then
			conn:Disconnect()
			terrainReadyEvt:Fire()
		end
	end)
end

-- ────────────────────────────────────────────────────────────────────
-- MAIN
-- ────────────────────────────────────────────────────────────────────
local height_map, mat_map = buildMaps()
stampRivers(height_map, mat_map)
fillAll(height_map, mat_map)
