-- ServerScriptService/PlayerSpawner

-- Controls when players actually spawn, waiting for terrain & prefabs to finish,
-- and ensures no overlap with existing prefabs or other players via the improved occupancy system.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Turn off automatic character loading
Players.CharacterAutoLoads = false

-- BindableEvents
local terrainReadyEvt = ReplicatedStorage:WaitForChild("TerrainReady")
local prefabsReadyEvt = ReplicatedStorage:WaitForChild("PrefabsReady")

-- Modules
local Config     = require(ReplicatedStorage.Modules.TerrainConfig)
local Occupancy  = require(ReplicatedStorage.Modules.OccupancyMap)

-- CONFIG: must match your terrain settings
local CORE_WIDTH      = Config.CORE_WIDTH          -- voxels
local MIN_PLAYER_DIST = Config.PLAYER_MIN_DIST  -- studs
local PLAYER_RAD      = Config.PLAYER_RADIUS     -- studs

-- Derived for sampling
local HALF_CORE = CORE_WIDTH / 2

-- Spawn state
local terrainDone         = false
local prefabsDone         = false
local spawnPointsComputed = false
local spawnPoints         = {}  -- Array of {position = Vector3, taken = boolean}
local currentSpawnIndex   = 1   -- Cycles through spawn points in order
local waitingPlayers      = {}

-- Sample a random (x,z) within the plateau core that's free for players
local function sampleXZ()
	local maxAttempts = 100 -- Reduced from 1000
	local attempts = 0

	while attempts < maxAttempts do
		attempts = attempts + 1
		local angle = math.random() * 2 * math.pi
		local radius = math.sqrt(math.random()) * HALF_CORE
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius

		-- Quick check: only use smaller area for initial validation
		if Occupancy.isAreaFree(x, z, PLAYER_RAD, PLAYER_RAD, 0) then
			-- More thorough check only if initial passes
			if Occupancy.isAreaFree(x, z, PLAYER_RAD * 2, PLAYER_RAD * 2, MIN_PLAYER_DIST) then
				return x, z
			end
		end
	end

	-- If we can't find a free spot, return nil
	return nil
end

-- Mark occupancy for a player radius
local function markPlayerOccupancy(x, z)
	Occupancy.markCircularArea(x, z, PLAYER_RAD + MIN_PLAYER_DIST, Occupancy.OCCUPANCY_TYPES.RESERVED)
end

-- Find and record spawn points (called only once per server)
local function computeSpawnPoints()
	local pts = {}
	local attempts = 0
	local maxTotalAttempts = Config.NUM_SPAWN * 10 -- Reduced from 20 to 10
	
	print(string.format("[PlayerSpawner] Computing spawn points, target: %d", Config.NUM_SPAWN))

	while #pts < Config.NUM_SPAWN and attempts < maxTotalAttempts do
		attempts = attempts + 1

		-- Progress update every 100 attempts
		if attempts % 100 == 0 then
			print(string.format("[PlayerSpawner] Progress: %d/%d spawn points, %d attempts", 
				#pts, Config.NUM_SPAWN, attempts))
		end

		local x, z = sampleXZ()
		if x then -- sampleXZ returns nil if it fails
			-- raycast down for Y
			local origin = Vector3.new(x, HALF_CORE + 500, z)
			local hit = workspace:Raycast(origin, Vector3.new(0, -(HALF_CORE + 500), 0))
			local y = (hit and hit.Position.Y or Config.SEA_LEVEL) + 2

			-- Store spawn point with taken status
			table.insert(pts, {
				position = Vector3.new(x, y, z),
				taken = false
			})
			markPlayerOccupancy(x, z)
		end
		
		-- Early exit if we're struggling to find spots
		if attempts > Config.NUM_SPAWN * 5 and #pts < Config.NUM_SPAWN * 0.5 then
			print(string.format("[PlayerSpawner] Early exit - only found %d/%d spawn points after %d attempts", 
				#pts, Config.NUM_SPAWN, attempts))
			break
		end
	end

	if #pts == 0 then
		warn("PlayerSpawner: no valid spawn points found!")
	else
		print("[PlayerSpawner] Computed", #pts, "spawn points out of", Config.NUM_SPAWN, "requested")
	end

	return pts
end

-- Get next available spawn point
local function getNextSpawnPoint()
	if #spawnPoints == 0 then
		warn("PlayerSpawner: no spawn points available!")
		return Vector3.new(0, HALF_CORE + 50, 0)
	end

	-- Try to find an unused spawn point starting from current index
	local startIndex = currentSpawnIndex
	local foundUnused = false

	repeat
		local spawnData = spawnPoints[currentSpawnIndex]
		if not spawnData.taken then
			-- Mark as taken and return position
			spawnData.taken = true
			local position = spawnData.position
			currentSpawnIndex = (currentSpawnIndex % #spawnPoints) + 1 -- Move to next for next player
			return position
		end

		currentSpawnIndex = (currentSpawnIndex % #spawnPoints) + 1
	until currentSpawnIndex == startIndex

	-- All spawn points are taken, reuse in order
	local spawnData = spawnPoints[currentSpawnIndex]
	local position = spawnData.position
	currentSpawnIndex = (currentSpawnIndex % #spawnPoints) + 1
	return position
end

-- Try to spawn all queued players once setup is complete
local function trySpawnQueued()
	if not (terrainDone and prefabsDone) then return end

	-- Compute spawn points only once per server
	if not spawnPointsComputed then
		spawnPoints = computeSpawnPoints()
		spawnPointsComputed = true
	end

	for i = #waitingPlayers, 1, -1 do -- Iterate backwards to safely remove
		local player = waitingPlayers[i]
		if player and player.Parent and not player.Character then
			player:LoadCharacter()
			table.remove(waitingPlayers, i)
		elseif not player or not player.Parent then
			-- Clean up disconnected players
			table.remove(waitingPlayers, i)
		end
	end
end

-- Event handlers
terrainReadyEvt.Event:Connect(function()
	terrainDone = true
	print("[PlayerSpawner] TerrainReady")
	trySpawnQueued()
end)

prefabsReadyEvt.Event:Connect(function()
	prefabsDone = true
	print("[PlayerSpawner] PrefabsReady")
	trySpawnQueued()
end)

-- Player join
Players.PlayerAdded:Connect(function(player)
	table.insert(waitingPlayers, player)
	print("[PlayerSpawner] Queued player:", player.Name)
	trySpawnQueued()

	player.CharacterAdded:Connect(function(char)
		local pos = getNextSpawnPoint()
		print("Spawning", player.Name, "at", pos)
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if hrp then 
			hrp.CFrame = CFrame.new(pos) 
		end
	end)
end)

print("[PlayerSpawner] Initialized, awaiting TerrainReady & PrefabsReady")