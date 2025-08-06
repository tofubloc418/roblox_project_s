--!strict
-- MinimapConfig: Configuration for the minimap system
-- Improves upon ChatGPT's basic config with more features

local MinimapConfig = {}

-- World bounds from IslandConfig
MinimapConfig.WorldBounds = {
    Min = Vector2.new(-1024, -1024), -- Half of 2048x2048
    Max = Vector2.new(1024, 1024)
}

-- Minimap display settings
MinimapConfig.Minimap = {
    Size = UDim2.new(0, 250, 0, 250), -- Slightly larger than ChatGPT's 200x200
    Position = UDim2.new(1, -260, 0, 10), -- Top-right with padding
    ViewRadius = 150, -- Studs visible in minimap (dynamic viewport)
    MinZoom = 50,
    MaxZoom = 500,
    DefaultZoom = 150,
    UpdateThrottle = 0.1, -- Update every 100ms instead of every frame
    BackgroundColor = Color3.fromRGB(20, 25, 30),
    BorderColor = Color3.fromRGB(100, 110, 120),
    BorderSize = 2,
}

-- Full map settings
MinimapConfig.FullMap = {
    Size = UDim2.new(0.85, 0, 0.85, 0), -- Slightly larger than ChatGPT's 0.8
    Position = UDim2.new(0.075, 0, 0.075, 0),
    BackgroundColor = Color3.fromRGB(15, 20, 25),
    BorderColor = Color3.fromRGB(150, 160, 170),
    BorderSize = 3,
}

-- Player icon settings
MinimapConfig.PlayerIcon = {
    Size = UDim2.new(0, 20, 0, 20),
    Image = "rbxassetid://6034684949", -- Arrow icon (you can change this)
    Color = Color3.fromRGB(255, 255, 255),
    ZIndex = 5,
}

-- Ping settings (more comprehensive than ChatGPT)
MinimapConfig.Ping = {
    Types = {
        LOCATION = {
            Icon = "rbxassetid://6031075938", -- Location marker
            Color = Color3.fromRGB(255, 200, 0),
            BeamColor = ColorSequence.new(Color3.fromRGB(255, 200, 0)),
            Lifetime = 30,
        },
        DANGER = {
            Icon = "rbxassetid://6031075931", -- Warning icon
            Color = Color3.fromRGB(255, 50, 50),
            BeamColor = ColorSequence.new(Color3.fromRGB(255, 50, 50)),
            Lifetime = 20,
        },
        HELP = {
            Icon = "rbxassetid://6031075933", -- Help icon
            Color = Color3.fromRGB(50, 255, 50),
            BeamColor = ColorSequence.new(Color3.fromRGB(50, 255, 50)),
            Lifetime = 45,
        },
    },
    IconSize = UDim2.new(0, 24, 0, 24),
    BeamWidth = 2,
    BeamHeight = 500,
    MaxPingsPerPlayer = 3, -- Limit spam
    Cooldown = 1, -- Seconds between pings
}

-- Terrain colors for dynamic rendering
MinimapConfig.TerrainColors = {
    [Enum.Material.Grass] = Color3.fromRGB(65, 152, 10),
    [Enum.Material.Sand] = Color3.fromRGB(220, 188, 129),
    [Enum.Material.Rock] = Color3.fromRGB(102, 108, 111),
    [Enum.Material.Water] = Color3.fromRGB(12, 84, 160),
    [Enum.Material.Snow] = Color3.fromRGB(195, 199, 218),
    [Enum.Material.Mud] = Color3.fromRGB(58, 46, 27),
    Default = Color3.fromRGB(80, 80, 80),
}

-- Input settings
MinimapConfig.Controls = {
    ToggleMapKey = Enum.KeyCode.M,
    PingModifierKey = Enum.KeyCode.C,
    ZoomInKey = Enum.KeyCode.Equals,
    ZoomOutKey = Enum.KeyCode.Minus,
    ZoomSpeed = 1.2, -- Multiplier per zoom step
}

-- Performance settings
MinimapConfig.Performance = {
    MaxRenderDistance = 500, -- Don't render terrain beyond this
    TerrainSampleRate = 4, -- Sample every N studs for performance
    UseCache = true, -- Cache terrain data
    CacheLifetime = 60, -- Seconds before cache refresh
}

export type PingType = "LOCATION" | "DANGER" | "HELP"

export type PingData = {
    Type: PingType,
    Position: Vector3,
    PlayerId: number,
    Timestamp: number,
}

return MinimapConfig 