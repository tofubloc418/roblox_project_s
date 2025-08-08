-- ServerScriptService/SpawnManager
-- Controls player spawning with occupancy-based spawn point management

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = true

local IslandConfig = require(ReplicatedStorage.Structure.IslandConfig)
local Occupancy  = require(ReplicatedStorage.Structure.OccupancyMap)

local BOUNDARY_WIDTH   = IslandConfig.spawnAreaSize.X   -- studs (core area only)
local MIN_PLAYER_DIST  = 30                           -- studs
local PLAYER_RAD       = 2                            -- studs

local HALF_BOUNDARY = BOUNDARY_WIDTH / 2

-- Spawn state
local spawnPoints         = {}  -- Array of {position = Vector3, taken = boolean}
local currentSpawnIndex   = 1   -- Cycles through spawn points in order
local waitingPlayers      = {}

-- Sample a random (x,z) within the boundary that's free for players
local function sampleXZ()
	local maxAttempts = 100
	local attempts = 0

	while attempts < maxAttempts do
		attempts = attempts + 1
		local angle = math.random() * 2 * math.pi
		local radius = math.sqrt(math.random()) * HALF_BOUNDARY
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
	local targetSpawns = 100
	local maxTotalAttempts = targetSpawns * 10
	
	print(string.format("[SpawnManager] Computing spawn points, target: %d", targetSpawns))

	while #pts < targetSpawns and attempts < maxTotalAttempts do
		attempts = attempts + 1

		-- Progress update every 100 attempts
		if attempts % 100 == 0 then
			print(string.format("[SpawnManager] Progress: %d/%d spawn points, %d attempts", 
				#pts, targetSpawns, attempts))
		end

		local x, z = sampleXZ()
		if x then -- sampleXZ returns nil if it fails
			-- raycast down for Y
			local origin = Vector3.new(x, 500, z)
			local hit = workspace:Raycast(origin, Vector3.new(0, -1000, 0))
			local y = (hit and hit.Position.Y or 0) + 2

			-- Store spawn point with taken status
			local spawnPos = Vector3.new(x, y, z)
			table.insert(pts, {
				position = spawnPos,
				taken = false
			})
			markPlayerOccupancy(x, z)
			
			-- print(string.format("[SpawnManager] Generated spawn point %d: X=%.2f, Y=%.2f, Z=%.2f", #pts, spawnPos.X, spawnPos.Y, spawnPos.Z))
		end
		
		-- Early exit if we're struggling to find spots
		if attempts > targetSpawns * 5 and #pts < targetSpawns * 0.5 then
			print(string.format("[SpawnManager] Early exit - only found %d/%d spawn points after %d attempts", 
				#pts, targetSpawns, attempts))
			break
		end
	end

	if #pts == 0 then
		warn("SpawnManager: no valid spawn points found!")
	else
		print("[SpawnManager] Computed", #pts, "spawn points out of", targetSpawns, "requested")
	end

	return pts
end

-- Get next available spawn point
local function getNextSpawnPoint()
	if #spawnPoints == 0 then
		warn("[SpawnManager] No spawn points available!")
		return Vector3.new(0, 1000, 0)
	end

	-- Try to find an unused spawn point starting from current index
	local startIndex = currentSpawnIndex

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

-- Initialize occupancy map
local function initializeOccupancyMap()
	Occupancy.initialize()
end

-- Handle player spawning and queue management
local function handlePlayerSpawn(player)
	local pos = getNextSpawnPoint()
	local hrp = player.Character:WaitForChild("HumanoidRootPart", 10)
	if hrp then 
        print("[SpawnManager] Spawning", player.Name, "at", pos)
		hrp.CFrame = CFrame.new(pos) 
	end
	
	-- Remove player from waiting queue after successful spawn
	for i = #waitingPlayers, 1, -1 do
		if waitingPlayers[i] == player then
			table.remove(waitingPlayers, i)
			print("[SpawnManager] Removed", player.Name, "from waiting queue")
			break
		end
	end
end

-- Clean up disconnected players from queue
local function cleanupDisconnectedPlayers()
	for i = #waitingPlayers, 1, -1 do
		local player = waitingPlayers[i]

        -- If player is not in the game, player.Parent will be nil. Else, player.Parent will be game.Players
		if not player or not player.Parent then
			table.remove(waitingPlayers, i)
			print("[SpawnManager] Removed disconnected player from queue:", player and player.Name or "unknown")
		end
	end
end

-- On player join
Players.PlayerAdded:Connect(function(player)
	table.insert(waitingPlayers, player)
	print("[SpawnManager] Queued player:", player.Name)

	player.CharacterAdded:Connect(function(char)
		handlePlayerSpawn(player)
		-- Boost movement speed on spawn
		local humanoid = char:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.WalkSpeed = 100 -- very fast
		end
	end)
	
	-- Clean up disconnected players when new player joins
	cleanupDisconnectedPlayers()
end)


initializeOccupancyMap()

spawnPoints = computeSpawnPoints()

-- Periodic cleanup of disconnected players (every 30 seconds)
spawn(function()
	while true do
		wait(30)
		cleanupDisconnectedPlayers()
		if #waitingPlayers > 0 then
			print("[SpawnManager] Queue status:", #waitingPlayers, "players waiting")
		end
	end
end)

print("[SpawnManager] Initialized with", #spawnPoints, "spawn points")