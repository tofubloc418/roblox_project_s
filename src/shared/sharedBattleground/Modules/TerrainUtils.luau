-- ModuleScript: TerrainUtils
-- Flattens a footprint pad with a feathered transition and smoothing using ReadVoxels/WriteVoxels.

local PathfindingService = game:GetService("PathfindingService")
local Config            = require(game:GetService("ReplicatedStorage").Modules.TerrainConfig)

local TerrainUtils = {}

-- Helpers
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

-- Point-in-polygon test
local function pointInPolygon(px, pz, poly)
	local inside = false
	local j = #poly
	for i = 1, #poly do
		local xi, zi = poly[i].X, poly[i].Y
		local xj, zj = poly[j].X, poly[j].Y
		if ((zi > pz) ~= (zj > pz)) and
			(px < (xj - xi) * (pz - zi) / (zj - zi) + xi) then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- Distance from point to polygon
local function pointToPolygonDistance(px, pz, poly)
	local minDist = math.huge
	for i = 1, #poly do
		local ax, az = poly[i].X, poly[i].Y
		local bx, bz = poly[i % #poly + 1].X, poly[i % #poly + 1].Y
		local vx, vz = bx - ax, bz - az
		local wx, wz = px - ax, pz - az
		local c = (wx * vx + wz * vz) / (vx * vx + vz * vz)
		local dx, dz
		if c < 0 then
			dx, dz = px - ax, pz - az
		elseif c > 1 then
			dx, dz = px - bx, pz - bz
		else
			local projx, projz = ax + c * vx, az + c * vz
			dx, dz = px - projx, pz - projz
		end
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist < minDist then minDist = dist end
	end
	return minDist
end

-- footprint: Vector2[]; transitionRadius: number; h0mode: "min"|"avg"|"max"; terrain: Terrain
function TerrainUtils.FlattenPadWithTransition(footprint, transitionRadius, h0mode, terrain)
	local cellSize = Config.CELL_SIZE
	local VOX_RES = Config.VOXEL_RES

	-- 1) Compute world‐space bounds with padding
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	for _, v in ipairs(footprint) do
		minX, maxX = math.min(minX, v.X), math.max(maxX, v.X)
		minZ, maxZ = math.min(minZ, v.Y), math.max(maxZ, v.Y)
	end
	minX, minZ = minX - transitionRadius, minZ - transitionRadius
	maxX, maxZ = maxX + transitionRadius, maxZ + transitionRadius

	-- 2) Build and align Region3 to voxel grid
	local region = Region3.new(
		Vector3.new(minX, 0, minZ),
		Vector3.new(maxX, Config.MIN_LAND_HEIGHT * 2 + transitionRadius, maxZ)
	):ExpandToGrid(VOX_RES)

	-- 3) Read existing voxel materials & occupancy
	local resolution = VOX_RES
	local matGrid, occGrid = terrain:ReadVoxels(region, resolution)  -- :contentReference[oaicite:0]{index=0}

	-- Dimensions
	local xs = #matGrid
	local ys = #matGrid[1]
	local zs = #matGrid[1][1]

	-- 4) Build original heightmap by finding highest occupied voxel per column
	local orig = {}
	for i = 1, xs do
		orig[i] = {}
		for k = 1, zs do
			local h = 0
			for j = ys, 1, -1 do
				if occGrid[i][j][k] then
					h = (j - 1) * VOX_RES
					break
				end
			end
			orig[i][k] = h
		end
	end

	-- 5) Sample h₀ from footprint corners
	local hs = {}
	for _, v in ipairs(footprint) do
		local ii = math.floor((v.X - minX) / VOX_RES) + 1
		local jj = math.floor((v.Y - minZ) / VOX_RES) + 1
		table.insert(hs, orig[ii][jj])
	end
	local h0
	if h0mode == "min" then
		h0 = math.min(unpack(hs))
	elseif h0mode == "max" then
		h0 = math.max(unpack(hs))
	else
		local sum = 0
		for _, h in ipairs(hs) do sum += h end
		h0 = sum / #hs
	end

	-- 6) Compute flattened + feathered heights
	local newH = {}
	for i = 1, xs do
		newH[i] = {}
		for k = 1, zs do
			local wx = minX + (i - 1) * VOX_RES + VOX_RES/2
			local wz = minZ + (k - 1) * VOX_RES + VOX_RES/2
			local oH = orig[i][k]
			if pointInPolygon(wx, wz, footprint) then
				newH[i][k] = h0
			else
				local d = pointToPolygonDistance(wx, wz, footprint)
				if d <= transitionRadius then
					local t = clamp(d / transitionRadius, 0, 1)
					newH[i][k] = lerp(h0, oH, t)
				else
					newH[i][k] = oH
				end
			end
		end
	end

	-- 7) Smooth heights with 3×3 kernel
	local smoothH = {}
	for i = 1, xs do
		smoothH[i] = {}
		for k = 1, zs do
			local sum, cnt = 0, 0
			for di = -1, 1 do
				for dk = -1, 1 do
					local ni, nk = i + di, k + dk
					if ni >= 1 and ni <= xs and nk >= 1 and nk <= zs then
						sum += newH[ni][nk]
						cnt += 1
					end
				end
			end
			smoothH[i][k] = sum / cnt
		end
	end

	-- 8) Build new voxel grids and write back
	local newMat = {}
	local newOcc = {}
	for i = 1, xs do
		newMat[i] = {}
		newOcc[i] = {}
		for j = 1, ys do
			newMat[i][j] = {}
			newOcc[i][j] = {}
			for k = 1, zs do
				local h = smoothH[i][k]
				if (j - 1) * VOX_RES <= h then
					newOcc[i][j][k] = 1
					newMat[i][j][k] = Config.LAND_MAT
				else
					newOcc[i][j][k] = 0
					newMat[i][j][k] = Enum.Material.Air
				end
			end
		end
	end
	terrain:WriteVoxels(region, resolution, newMat, newOcc)  -- :contentReference[oaicite:1]{index=1}


end

return TerrainUtils
