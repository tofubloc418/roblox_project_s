local IslandConfig = {}

-- Water and terrain settings
IslandConfig.spawnRadius = 50
IslandConfig.boundarySize = Vector3.new(2048, 100, 2048)
IslandConfig.boundaryCenter = Vector3.new(0, 50, 0)

-- Environment settings
IslandConfig.fogDistance = 150
IslandConfig.timeOfDay = "14:00:00"
IslandConfig.ambientColor = Color3.fromRGB(138, 138, 138)
IslandConfig.skyboxId = "rbxasset://sky/sky512_hr"

-- Spawn points for players
IslandConfig.spawnPoints = {}

-- Generic Normal Island properties
IslandConfig.islandName = "Normal Island"
IslandConfig.maxPlayers = 100

return IslandConfig 