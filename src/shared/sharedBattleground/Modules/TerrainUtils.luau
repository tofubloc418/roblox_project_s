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

-- Sample heights across entire footprint area with proper density
local function sampleFootprintHeights(footprint, matGrid, occGrid, minX, minZ, VOX_RES, h0mode)
	local hs = {}
	
	-- Calculate footprint bounds
	local fpMinX, fpMaxX = math.huge, -math.huge
	local fpMinZ, fpMaxZ = math.huge, -math.huge
	for _, v in ipairs(footprint) do
		fpMinX, fpMaxX = math.min(fpMinX, v.X), math.max(fpMaxX, v.X)
		fpMinZ, fpMaxZ = math.min(fpMinZ, v.Y), math.max(fpMaxZ, v.Y)
	end
	
	-- Sample points across the footprint area
	local sampleStep = VOX_RES * 2 -- Sample every 2 voxels for better coverage
	for x = fpMinX, fpMaxX, sampleStep do
		for z = fpMinZ, fpMaxZ, sampleStep do
			if pointInPolygon(x, z, footprint) then
				local ii = math.floor((x - minX) / VOX_RES) + 1
				local kk = math.floor((z - minZ) / VOX_RES) + 1
				
				-- Find the height by looking for any occupied voxel (not just >0.5)
				if ii >= 1 and ii <= occGrid.Size.X and kk >= 1 and kk <= occGrid.Size.Z then
					for j = occGrid.Size.Y, 1, -1 do
						if occGrid[ii][j][kk] > 0.1 then -- Lowered threshold from 0.5 to 0.1
							local height = (j - 1) * VOX_RES
							table.insert(hs, height)
							break
						end
					end
				end
			end
		end
	end
	
	-- Try raycast sampling if voxel sampling fails
	if #hs == 0 then
		for _, v in ipairs(footprint) do
			local x, z = v.X, v.Y
			local origin = Vector3.new(x, 500, z)
			local dir = Vector3.new(0, -600, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = {}
			
			local hit = workspace:Raycast(origin, dir, raycastParams)
			if hit then
				table.insert(hs, hit.Position.Y)
			end
		end
	end
	
	if #hs == 0 then
		warn("TerrainUtils: No heights sampled; using MIN_LAND_HEIGHT")
		return Config.MIN_LAND_HEIGHT
	end
	
	print(string.format("🔍 Sampled %d heights: [%s]", #hs, table.concat(hs, ", ")))
	
	local targetHeight
	if h0mode == "min" then
		targetHeight = math.min(table.unpack(hs))
	elseif h0mode == "max" then
		targetHeight = math.max(table.unpack(hs))
	else -- "avg"
		local sum = 0
		for _, h in ipairs(hs) do sum = sum + h end
		targetHeight = sum / #hs
	end
	
	print(string.format("🎯 Target height (%s): %.1f", h0mode, targetHeight))
	return targetHeight
end

-- Flattens terrain around a 2D footprint polygon with a feathered transition
-- footprint: Vector2[]; transitionRadius: number; h0mode: "min"|"avg"|"max"; terrain: Terrain
function TerrainUtils.FlattenPadWithTransition(footprint, transitionRadius, h0mode, terrain)
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, p in ipairs(footprint) do
		if p.X < minX then minX = p.X end
		if p.X > maxX then maxX = p.X end
		if p.Y < minZ then minZ = p.Y end -- 2D footprint uses (X,Y) but we treat Y as Z
		if p.Y > maxZ then maxZ = p.Y end
	end

	-- 2) Expand by transition radius
	minX = minX - transitionRadius
	maxX = maxX + transitionRadius
	minZ = minZ - transitionRadius
	maxZ = maxZ + transitionRadius

	-- 3) Use proper Region3 with ExpandToGrid for correct alignment
	local VOX_RES = 4
	local region = Region3.new(
		Vector3.new(minX, 0, minZ),
		Vector3.new(maxX, 250, maxZ)
	):ExpandToGrid(VOX_RES)

	-- 4) Read existing terrain
	local origMat, origOcc = terrain:ReadVoxels(region, VOX_RES)
	local xs, ys, zs = origMat.Size.X, origMat.Size.Y, origMat.Size.Z
	
	-- Update aligned bounds based on actual region
	local alignedMinX = region.CFrame.Position.X - region.Size.X/2
	local alignedMinZ = region.CFrame.Position.Z - region.Size.Z/2

	-- 5) Sample heights within and around the footprint
	local h0 = sampleFootprintHeights(footprint, origMat, origOcc, alignedMinX, alignedMinZ, VOX_RES, h0mode)

	-- 6) Create height map for each (x,z) position based on distance to footprint
	local smoothH = {}
	for i = 1, xs do
		smoothH[i] = {}
		for k = 1, zs do
			local worldX = alignedMinX + (i - 1) * VOX_RES
			local worldZ = alignedMinZ + (k - 1) * VOX_RES
			local distToFootprint = pointToPolygonDistance(worldX, worldZ, footprint)

			if distToFootprint <= 0 then
				-- Inside footprint: use target height h0
				smoothH[i][k] = h0
			elseif distToFootprint <= transitionRadius then
				-- Transition zone: blend between h0 and original terrain height
				local t = distToFootprint / transitionRadius
				local originalHeight = 0
				local sampleCount = 0
				
				-- Sample original height from voxels at this (x,z)
				for j = 1, ys do
					if origOcc[i][j][k] > 0.1 then -- Lowered threshold
						originalHeight = originalHeight + ((j - 1) * VOX_RES)
						sampleCount = sampleCount + 1
					end
				end
				
				if sampleCount > 0 then
					originalHeight = originalHeight / sampleCount
				else
					originalHeight = h0  -- fallback
				end
				
				smoothH[i][k] = lerp(h0, originalHeight, t * t)
			else
				-- Outside transition: keep original terrain
				local originalHeight = 0
				local sampleCount = 0
				for j = 1, ys do
					if origOcc[i][j][k] > 0.1 then -- Lowered threshold
						originalHeight = originalHeight + ((j - 1) * VOX_RES)
						sampleCount = sampleCount + 1
					end
				end
				if sampleCount > 0 then
					smoothH[i][k] = originalHeight / sampleCount
				else
					smoothH[i][k] = h0
				end
			end
		end
	end

	-- 8) Build new voxel grids with improved height interpolation
	local newMat = {}
	local newOcc = {}
	
	for i = 1, xs do
		newMat[i] = {}
		newOcc[i] = {}
		for j = 1, ys do
			newMat[i][j] = {}
			newOcc[i][j] = {}
			for k = 1, zs do
				local voxelY = (j - 1) * VOX_RES
				local targetH = smoothH[i][k]
				
				-- Improved voxel assignment with smooth interpolation
				if voxelY < targetH - VOX_RES/2 then
					-- Solid terrain below target height - use sand for visibility
					newOcc[i][j][k] = 1
					newMat[i][j][k] = Enum.Material.Sand
				elseif voxelY <= targetH + VOX_RES/2 then
					-- Transition zone - use fractional occupancy for smoother terrain
					local occupancy = clamp((targetH - voxelY) / VOX_RES + 0.5, 0, 1)
					newOcc[i][j][k] = occupancy
					newMat[i][j][k] = occupancy > 0.1 and Enum.Material.Sand or Enum.Material.Air
				else
					-- Air above target height
					newOcc[i][j][k] = 0
					newMat[i][j][k] = Enum.Material.Air
				end
			end
		end
	end
	
	terrain:WriteVoxels(region, VOX_RES, newMat, newOcc)
	print(string.format("🔨 [TerrainStamp] WriteVoxels completed for region: (%.1f,%.1f) to (%.1f,%.1f)", 
		region.CFrame.Position.X - region.Size.X/2, region.CFrame.Position.Z - region.Size.Z/2,
		region.CFrame.Position.X + region.Size.X/2, region.CFrame.Position.Z + region.Size.Z/2))

end

-- Flattens terrain around a 2D footprint polygon to a specific target height
-- footprint: Vector2[]; transitionRadius: number; targetHeight: number; terrain: Terrain
function TerrainUtils.FlattenPadToHeight(footprint, transitionRadius, targetHeight, terrain)
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, p in ipairs(footprint) do
		if p.X < minX then minX = p.X end
		if p.X > maxX then maxX = p.X end
		if p.Y < minZ then minZ = p.Y end -- 2D footprint uses (X,Y) but we treat Y as Z
		if p.Y > maxZ then maxZ = p.Y end
	end

	-- 2) Expand by transition radius
	minX = minX - transitionRadius
	maxX = maxX + transitionRadius
	minZ = minZ - transitionRadius
	maxZ = maxZ + transitionRadius

	-- 3) Use proper Region3 with ExpandToGrid for correct alignment
	local VOX_RES = 4
	local region = Region3.new(
		Vector3.new(minX, 0, minZ),
		Vector3.new(maxX, 250, maxZ)
	):ExpandToGrid(VOX_RES)

	-- 4) Read existing terrain
	local origMat, origOcc = terrain:ReadVoxels(region, VOX_RES)
	local xs, ys, zs = origMat.Size.X, origMat.Size.Y, origMat.Size.Z
	
	-- Update aligned bounds based on actual region
	local alignedMinX = region.CFrame.Position.X - region.Size.X/2
	local alignedMinZ = region.CFrame.Position.Z - region.Size.Z/2

	-- 5) Use the specified target height directly
	local h0 = targetHeight
	print(string.format("🎯 Target height (direct): %.1f", h0))

	-- 6) Create height map for each (x,z) position based on distance to footprint
	local smoothH = {}
	for i = 1, xs do
		smoothH[i] = {}
		for k = 1, zs do
			local worldX = alignedMinX + (i - 1) * VOX_RES
			local worldZ = alignedMinZ + (k - 1) * VOX_RES
			local distToFootprint = pointToPolygonDistance(worldX, worldZ, footprint)

			if distToFootprint <= 0 then
				-- Inside footprint: use target height h0
				smoothH[i][k] = h0
			elseif distToFootprint <= transitionRadius then
				-- Transition zone: blend between h0 and original terrain height
				local t = distToFootprint / transitionRadius
				local originalHeight = 0
				local sampleCount = 0
				
				-- Sample original height from voxels at this (x,z)
				for j = 1, ys do
					if origOcc[i][j][k] > 0.1 then -- Lowered threshold
						originalHeight = originalHeight + ((j - 1) * VOX_RES)
						sampleCount = sampleCount + 1
					end
				end
				
				if sampleCount > 0 then
					originalHeight = originalHeight / sampleCount
				else
					originalHeight = h0  -- fallback
				end
				
				smoothH[i][k] = lerp(h0, originalHeight, t * t)
			else
				-- Outside transition: keep original terrain
				local originalHeight = 0
				local sampleCount = 0
				for j = 1, ys do
					if origOcc[i][j][k] > 0.1 then -- Lowered threshold
						originalHeight = originalHeight + ((j - 1) * VOX_RES)
						sampleCount = sampleCount + 1
					end
				end
				if sampleCount > 0 then
					smoothH[i][k] = originalHeight / sampleCount
				else
					smoothH[i][k] = h0
				end
			end
		end
	end

	-- 8) Build new voxel grids with improved height interpolation
	local newMat = {}
	local newOcc = {}
	
	for i = 1, xs do
		newMat[i] = {}
		newOcc[i] = {}
		for j = 1, ys do
			newMat[i][j] = {}
			newOcc[i][j] = {}
			for k = 1, zs do
				local voxelY = (j - 1) * VOX_RES
				local targetH = smoothH[i][k]
				
				-- Improved voxel assignment with smooth interpolation
				if voxelY < targetH - VOX_RES/2 then
					-- Solid terrain below target height - use sand for visibility
					newOcc[i][j][k] = 1
					newMat[i][j][k] = Enum.Material.Sand
				elseif voxelY <= targetH + VOX_RES/2 then
					-- Transition zone - use fractional occupancy for smoother terrain
					local occupancy = clamp((targetH - voxelY) / VOX_RES + 0.5, 0, 1)
					newOcc[i][j][k] = occupancy
					newMat[i][j][k] = occupancy > 0.1 and Enum.Material.Sand or Enum.Material.Air
				else
					-- Air above target height
					newOcc[i][j][k] = 0
					newMat[i][j][k] = Enum.Material.Air
				end
			end
		end
	end
	
	terrain:WriteVoxels(region, VOX_RES, newMat, newOcc)
	print(string.format("🔨 [TerrainStamp] WriteVoxels completed for region: (%.1f,%.1f) to (%.1f,%.1f)", 
		region.CFrame.Position.X - region.Size.X/2, region.CFrame.Position.Z - region.Size.Z/2,
		region.CFrame.Position.X + region.Size.X/2, region.CFrame.Position.Z + region.Size.Z/2))

end

return TerrainUtils
