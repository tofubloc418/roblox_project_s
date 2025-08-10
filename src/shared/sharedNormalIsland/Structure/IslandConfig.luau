local IslandConfig = {}

-- Island dimensions (all centered at 0, 50, 0)
IslandConfig.coreSize = Vector3.new(1600, 100, 1600) -- Core land area (i.e. grass area in Normal Island)
IslandConfig.sandRimWidth = 100 -- Width of sand rim around core (i.e. on each edge, width is 100 so adds 200 to the total size)
IslandConfig.oceanWidth = 300 -- Width of ocean around sand rim (i.e. on each edge, width is 300 so adds 600 to the total size)
IslandConfig.totalSize = Vector3.new(2400, 100, 2400) -- Total island size including ocean (i.e. 1600 + 200 + 600)

-- Spawn settings (only in core area)
IslandConfig.spawnRadius = 50
-- Players spawn only in core area + sand rim
IslandConfig.spawnAreaSize = Vector3.new(
    IslandConfig.coreSize.X + (IslandConfig.sandRimWidth * 2),
    IslandConfig.coreSize.Y,
    IslandConfig.coreSize.Z + (IslandConfig.sandRimWidth * 2)
)
IslandConfig.spawnAreaCenter = Vector3.new(0, 300, 0) -- Spawn area is centered at 0, 300, 0

-- Spawn points for players
IslandConfig.spawnPoints = {}

-- Generic Normal Island properties
IslandConfig.islandName = "Normal Island"
IslandConfig.maxPlayers = 100

return IslandConfig 