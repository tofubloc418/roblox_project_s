--!strict
-- MinimapRenderer: Handles dynamic rendering of the minimap
-- Unlike ChatGPT's static texture approach, this samples actual terrain

local MinimapConfig = require(script.Parent.MinimapConfig)
local OccupancyMap = require(script.Parent.Parent.Structure.OccupancyMap)

local MinimapRenderer = {}
MinimapRenderer.__index = MinimapRenderer

type TerrainCache = {
    data: {[string]: Color3},
    lastUpdate: number,
}

type MinimapRendererType = {
    cache: TerrainCache,
    mapFrame: Frame,
    pixelSize: number,
    renderDistance: number,
}

-- Create a new renderer instance
function MinimapRenderer.new(mapFrame: Frame): MinimapRendererType
    local self = setmetatable({}, MinimapRenderer) :: any
    
    self.mapFrame = mapFrame
    self.pixelSize = 4 -- Size of each terrain pixel
    self.renderDistance = MinimapConfig.Performance.MaxRenderDistance
    self.cache = {
        data = {},
        lastUpdate = 0,
    }
    
    return self
end

-- Get terrain material at world position
local function getTerrainAt(x: number, z: number): Enum.Material
    local terrain = workspace.Terrain
    local region = Region3.new(
        Vector3.new(x - 2, -100, z - 2),
        Vector3.new(x + 2, 200, z + 2)
    )
    region = region:ExpandToGrid(4)
    
    local materials, sizes = terrain:ReadVoxels(region, 4)
    local size = materials.Size
    
    -- Find the highest non-air voxel
    for y = size.Y, 1, -1 do
        local material = materials[1][y][1]
        if material ~= Enum.Material.Air then
            return material
        end
    end
    
    return Enum.Material.Air
end

-- Convert terrain material to color
local function materialToColor(material: Enum.Material): Color3
    return MinimapConfig.TerrainColors[material] or MinimapConfig.TerrainColors.Default
end

-- Render the minimap centered on a position
function MinimapRenderer:Render(centerPos: Vector3, viewRadius: number)
    local now = tick()
    local useCache = MinimapConfig.Performance.UseCache and 
                    (now - self.cache.lastUpdate) < MinimapConfig.Performance.CacheLifetime
    
    -- Clear existing pixels if not using cache
    if not useCache then
        for _, child in ipairs(self.mapFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name == "TerrainPixel" then
                child:Destroy()
            end
        end
        self.cache.data = {}
    end
    
    local sampleRate = MinimapConfig.Performance.TerrainSampleRate
    local mapSize: Vector2 = self.mapFrame.AbsoluteSize
    local pixelsPerSide = math.floor(mapSize.X / self.pixelSize)
    
    -- Calculate bounds
    local minX = centerPos.X - viewRadius
    local maxX = centerPos.X + viewRadius
    local minZ = centerPos.Z - viewRadius
    local maxZ = centerPos.Z + viewRadius
    
    -- Render terrain pixels
    for i = 0, pixelsPerSide - 1 do
        for j = 0, pixelsPerSide - 1 do
            local worldX = minX + (i / pixelsPerSide) * (maxX - minX)
            local worldZ = minZ + (j / pixelsPerSide) * (maxZ - minZ)
            
            -- Check bounds
            if worldX < MinimapConfig.WorldBounds.Min.X or worldX > MinimapConfig.WorldBounds.Max.X or
               worldZ < MinimapConfig.WorldBounds.Min.Y or worldZ > MinimapConfig.WorldBounds.Max.Y then
                continue
            end
            
            local cacheKey = string.format("%d,%d", 
                math.floor(worldX / sampleRate), 
                math.floor(worldZ / sampleRate))
            
            local color: Color3
            if useCache and self.cache.data[cacheKey] then
                color = self.cache.data[cacheKey]
            else
                -- Check occupancy map first for performance
                local ix, iz = OccupancyMap.worldToGridIndex(worldX, worldZ)
                if OccupancyMap.isValidIndex(ix, iz) then
                    local occupancy = OccupancyMap.grid[ix][iz]
                    if occupancy == OccupancyMap.OCCUPANCY_TYPES.WATER then
                        color = materialToColor(Enum.Material.Water)
                    else
                        local material = getTerrainAt(worldX, worldZ)
                        color = materialToColor(material)
                    end
                else
                    color = materialToColor(Enum.Material.Water)
                end
                
                self.cache.data[cacheKey] = color
            end
            
            -- Create or update pixel
            local pixelName = string.format("TerrainPixel_%d_%d", i, j)
            local existingPixel = self.mapFrame:FindFirstChild(pixelName)
            
            if existingPixel and existingPixel:IsA("Frame") then
                -- Update existing pixel
                existingPixel.BackgroundColor3 = color
            else
                -- Create new pixel
                local pixel = Instance.new("Frame")
                pixel.Name = pixelName
                pixel.BorderSizePixel = 0
                pixel.Size = UDim2.new(0, self.pixelSize, 0, self.pixelSize)
                pixel.Position = UDim2.new(0, i * self.pixelSize, 0, j * self.pixelSize)
                pixel.BackgroundColor3 = color
                pixel.Parent = self.mapFrame
            end
        end
    end
    
    self.cache.lastUpdate = now
end

-- Create a static full map (called less frequently)
function MinimapRenderer:RenderFullMap()
    -- This would render the entire world map
    -- For performance, this should be called sparingly and cached
    self:Render(Vector3.new(0, 0, 0), math.max(
        MinimapConfig.WorldBounds.Max.X,
        MinimapConfig.WorldBounds.Max.Y
    ))
end

-- Add a fog of war effect for unexplored areas
function MinimapRenderer:ApplyFogOfWar(exploredAreas: {[string]: boolean})
    for _, child in ipairs(self.mapFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("TerrainPixel") then
            local coords = child.Name:match("TerrainPixel_(%d+)_(%d+)")
            if coords and not exploredAreas[coords] then
                child.BackgroundTransparency = 0.7
            end
        end
    end
end

return MinimapRenderer 