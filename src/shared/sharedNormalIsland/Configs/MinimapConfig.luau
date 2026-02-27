--!strict
-- MinimapConfig: Configuration for the static image minimap system

local MinimapConfig = {}

-- Get IslandConfig to calculate world bounds
local IslandConfig = require(script.Parent.IslandConfig)

-- Calculate world bounds from total island size and center (includes ocean)
local halfSize = IslandConfig.totalSize / 2
MinimapConfig.WorldBounds = {
    Min = Vector2.new(
        IslandConfig.spawnAreaCenter.X - halfSize.X,
        IslandConfig.spawnAreaCenter.Z - halfSize.Z
    ),
    Max = Vector2.new(
        IslandConfig.spawnAreaCenter.X + halfSize.X,
        IslandConfig.spawnAreaCenter.Z + halfSize.Z
    )
}

-- Minimap display settings
MinimapConfig.Minimap = {
    Size = UDim2.new(0, 250, 0, 250),
    Position = UDim2.new(0, 20, 0, 20),
    BackgroundColor = Color3.fromRGB(25, 30, 35),
    BorderColor = Color3.fromRGB(0, 0, 0),
    BorderSize = 2,
    UpdateThrottle = 0.05,
    ZoomFactor = 3,
}

-- Full map settings
MinimapConfig.FullMap = {
    Size = UDim2.new(0.85, 0, 0.85, 0),
    Position = UDim2.new(0.075, 0, 0.075, 0),
    BackgroundColor = Color3.fromRGB(15, 20, 25),
    BorderColor = Color3.fromRGB(150, 160, 170),
    BorderSize = 3,
}

-- Player icon settings
MinimapConfig.PlayerIcon = {
    Size = UDim2.new(0, 20, 0, 20),
    Image = "rbxassetid://132741527990568", -- Arrow icon
    Color = Color3.fromRGB(255, 255, 255),
    ZIndex = 5,
    RotationOffset = 0, -- degrees; flip icon if asset points opposite
}

-- Input settings
MinimapConfig.Controls = {
    ToggleMapKey = Enum.KeyCode.M,
}

-- Minimap assets for each island
MinimapConfig.minimapAssets = {
    ["NormalIsland1"] = "rbxassetid://128918368774464",
    ["NormalIsland2"] = "rbxassetid://128918368774464",
    ["NormalIsland3"] = "rbxassetid://128918368774464",
}

-- Function to get the correct minimap asset based on game name
function MinimapConfig.getMinimapAsset()
    local gameName = game.Name
    return MinimapConfig.minimapAssets[gameName] or MinimapConfig.minimapAssets["NormalIsland1"]
end

-- Convert world position to minimap UV coordinates (0-1)
function MinimapConfig.worldToUV(worldPos: Vector3): Vector2
    local bounds = MinimapConfig.WorldBounds
    
    -- Normalize world position to 0-1 range
    local normalizedX = (worldPos.X - bounds.Min.X) / (bounds.Max.X - bounds.Min.X)
    local normalizedZ = (worldPos.Z - bounds.Min.Y) / (bounds.Max.Y - bounds.Min.Y)
    
    -- Clamp to ensure we stay within bounds
    normalizedX = math.clamp(normalizedX, 0, 1)
    normalizedZ = math.clamp(normalizedZ, 0, 1)
    
    return Vector2.new(normalizedX, normalizedZ)
end

-- Convert UV coordinates back to world position (for clicking on map)
function MinimapConfig.uvToWorld(uv: Vector2): Vector3
    local bounds = MinimapConfig.WorldBounds
    
    local worldX = bounds.Min.X + uv.X * (bounds.Max.X - bounds.Min.X)
    local worldZ = bounds.Min.Y + uv.Y * (bounds.Max.Y - bounds.Min.Y)
    
    return Vector3.new(worldX, 0, worldZ)
end

return MinimapConfig 