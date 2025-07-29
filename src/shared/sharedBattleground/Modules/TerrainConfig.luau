-- ModuleScript: TerrainConfig
-- Central configuration for terrain, rivers, and spawning

local Config = {}

-- Voxel resolution
Config.CELL_SIZE          = 1       -- studs per voxel
Config.VOXEL_RES			= 4       -- number of sub-cells per voxel

-- Terrain dimensions (voxels)
Config.CORE_WIDTH         = 1000    -- side length of noisy plateau
Config.SAND_RIM_WIDTH     = 300     -- width of linear sand rim around plateau
Config.TOTAL_WIDTH        = Config.CORE_WIDTH + 2 * Config.SAND_RIM_WIDTH
Config.SEA_LEVEL		  = 1
Config.MIN_LAND_HEIGHT    = 15      -- minimum height (voxels) of grass plateau

-- Noise for plateau
Config.HEIGHT_NOISE_S     = 150     -- noise scale (higher = smoother hills)
Config.NOISE_AMPLITUDE    = 50      -- amplitude of noise on plateau

-- River parameters
Config.RIVER_BOTTOM_HEIGHT = 7      -- river bottom height (voxels)
Config.RIVER_WIDTH         = 80     -- width of main river (voxels)
Config.TRIB_WIDTH          = 40     -- width of tributary rivers (voxels)
Config.TRIB_MIN            = 0      -- min number of tributaries
Config.TRIB_MAX            = 2      -- max number of tributaries

-- Seeds
Config.SEED_MAIN          = os.time()
Config.SEED_RIVER         = Config.SEED_MAIN + 1

-- Materials
Config.LAND_MAT           = Enum.Material.Grass
Config.BEACH_MAT          = Enum.Material.Sand
Config.WATER_MAT          = Enum.Material.Water

-- Player spawn settings
Config.NUM_SPAWN          = 100    -- number of spawn points to precompute
Config.PLAYER_MIN_DIST    = 30     -- minimum separation between spawn points (studs)
Config.PLAYER_RADIUS      = 2      -- approximate player collision radius (studs)

return Config
