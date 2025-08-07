local IslandConfig = {}

-- Island dimensions (all centered at 0, 50, 0)
IslandConfig.coreSize = Vector3.new(1900, 100, 1900) -- Land area where players spawn and spend time
IslandConfig.sandRimWidth = 100 -- Width of sand rim around core
IslandConfig.oceanWidth = 300 -- Width of ocean around sand rim
IslandConfig.totalSize = Vector3.new(2200, 100, 2200) -- Total island size including ocean

-- Spawn settings (only in core area)
IslandConfig.spawnRadius = 50
IslandConfig.spawnAreaSize = IslandConfig.coreSize -- Players spawn only in core area
IslandConfig.spawnAreaCenter = Vector3.new(0, 300, 0) -- Spawn area is centered at 0, 300, 0

-- Spawn points for players
IslandConfig.spawnPoints = {}

-- Generic Normal Island properties
IslandConfig.islandName = "Normal Island"
IslandConfig.maxPlayers = 100

return IslandConfig 