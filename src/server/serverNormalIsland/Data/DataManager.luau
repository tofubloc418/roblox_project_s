--!strict
-- DataManager
-- Sole gateway to DataStore for player persistence.
--
-- RESPONSIBILITIES:
--   - Load, cache, and save PlayerData via a single DataStore key per player.
--   - Run schema migrations when the stored version is behind CURRENT_VERSION.
--   - Maintain a session lock so multiple servers can't corrupt the same data.
--   - Provide simple CRUD-like accessors for other services (InventoryService,
--     AbilityDataService, StatsService) without them needing DataStore knowledge.
--   - Run an autosave loop and a BindToClose save for server shutdown safety.
--
-- WHAT THIS MODULE DOES NOT DO:
--   - No knowledge of items, abilities, weapons, or any gameplay logic.
--   - No remote events (owned by InventoryService / AbilityDataService).
--   - No stat calculation or modifier application.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local StatsConfig    = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Stats"):WaitForChild("StatsConfig"))

type PlayerData      = InventoryTypes.PlayerData
type CharacterData   = InventoryTypes.CharacterData
type SerializedItem  = InventoryTypes.SerializedItem

-- ── Constants ─────────────────────────────────────────────────────────────────

local DATASTORE_NAME       = "PlayerData_v1"
local KEY_PREFIX           = "player_"
local CURRENT_VERSION      = 1
local AUTOSAVE_INTERVAL    = 60  -- seconds between autosave cycles
local SAVE_RETRY_COUNT     = 3
local SAVE_RETRY_BASE_WAIT = 2   -- seconds; doubled each retry (2, 4, 6…)
local SESSION_LOCK_TIMEOUT = 45  -- seconds to wait before force-claiming a lock

-- ── State ─────────────────────────────────────────────────────────────────────

local _store: DataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local _cache:  { [number]: PlayerData } = {}
local _dirty:  { [number]: boolean }    = {}

-- ── Default data factory ──────────────────────────────────────────────────────

local function createDefaultData(userId: number): PlayerData
	return {
		version   = CURRENT_VERSION,
		lastSaved = os.time(),
		sessionId = "",

		character = {
			level           = 1,
			experience      = 0,
			attributePoints = 0,
			attributes      = {
				Vitality     = StatsConfig.DefaultAttributes.Vitality,
				Intelligence = StatsConfig.DefaultAttributes.Intelligence,
				Endurance    = StatsConfig.DefaultAttributes.Endurance,
				Strength     = StatsConfig.DefaultAttributes.Strength,
				Dexterity    = StatsConfig.DefaultAttributes.Dexterity,
				Luck         = StatsConfig.DefaultAttributes.Luck,
			},
		} :: InventoryTypes.CharacterData,

		inventory = { maxSlots = 16, slots = {} },

		equipment = {
			Backpack = nil,
			Armor    = nil,
			Weapon1  = nil,
			Weapon2  = nil,
		},

		quickUse = {
			slots            = {},
			currentSlotIndex = nil,
		},

		stash = { maxSlots = 100, slots = {} },

		abilityPresets = {},

		currency = { gold = 0 },

		settings = {},
	}
end

-- Add new migration steps here as the schema evolves.
-- Each step upgrades version N → N+1.

local Migrations = {
	-- v0 → v1: initial schema; fill in any missing top-level keys from defaults.
	function(data: any)
		local defaults = createDefaultData(0)
		for key, value in pairs(defaults) do
			if data[key] == nil then
				data[key] = value
			end
		end
		data.version = 1
	end,
}

local function migrateData(raw: any): PlayerData
	local version = raw.version or 0
	for i = version + 1, CURRENT_VERSION do
		local step = Migrations[i]
		if step then
			local ok = pcall(step, raw)
			if not ok then
				warn("[DataManager] Migration step " .. i .. " failed")
			end
		end
	end
	return raw :: PlayerData
end

-- ── DataStore helpers ─────────────────────────────────────────────────────────

local function readWithRetry(key: string): (boolean, any)
	for attempt = 1, SAVE_RETRY_COUNT do
		local ok, result = pcall(function()
			return _store:GetAsync(key)
		end)
		if ok then
			return true, result
		end
		warn(string.format("[DataManager] GetAsync attempt %d failed (%s): %s", attempt, key, tostring(result)))
		if attempt < SAVE_RETRY_COUNT then
			task.wait(SAVE_RETRY_BASE_WAIT * attempt)
		end
	end
	return false, nil
end

local function writeWithRetry(key: string, data: PlayerData): boolean
	for attempt = 1, SAVE_RETRY_COUNT do
		-- Yield briefly if the DataStore budget is exhausted.
		local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
		if budget < 1 then
			warn("[DataManager] UpdateAsync budget low; waiting before retry for " .. key)
			task.wait(4)
		end

		local ok, err = pcall(function()
			_store:UpdateAsync(key, function(_oldData: any)
				return data
			end)
		end)
		if ok then
			return true
		end
		warn(string.format("[DataManager] UpdateAsync attempt %d failed (%s): %s", attempt, key, tostring(err)))
		if attempt < SAVE_RETRY_COUNT then
			task.wait(SAVE_RETRY_BASE_WAIT * attempt)
		end
	end
	return false
end

-- ── Public API ────────────────────────────────────────────────────────────────

local DataManager = {}

--[[
	LoadPlayerData(player)
	Loads, migrates, and caches PlayerData for the given player.
	If the DataStore is unreachable after retries, the player is kicked.
	Session-locks the record to this server (game.JobId).
	Returns the PlayerData (may be default for a brand-new player).
]]
function DataManager.LoadPlayerData(player: Player): PlayerData
	local userId = player.UserId
	local key    = KEY_PREFIX .. tostring(userId)

	local ok, raw = readWithRetry(key)
	if not ok then
		warn("[DataManager] Could not load data for " .. player.Name .. " — kicking.")
		player:Kick("Your data could not be loaded. Please try again.")
		return createDefaultData(userId)
	end

	local data: PlayerData
	if raw == nil then
		print("[DataManager] New player: " .. player.Name)
		data = createDefaultData(userId)
	else
		data = migrateData(raw)
	end

	-- Session lock: wait for another server to release, then force-claim.
	if data.sessionId ~= "" and data.sessionId ~= game.JobId then
		warn(string.format("[DataManager] Session conflict for %s (lock owner: %s). Waiting up to %ds.",
			player.Name, data.sessionId, SESSION_LOCK_TIMEOUT))
		local deadline = os.time() + SESSION_LOCK_TIMEOUT
		while os.time() < deadline do
			task.wait(5)
			local ok2, fresh = readWithRetry(key)
			if ok2 and fresh and (fresh.sessionId == "" or fresh.sessionId == game.JobId) then
				data = migrateData(fresh)
				break
			end
		end
		if data.sessionId ~= "" and data.sessionId ~= game.JobId then
			warn("[DataManager] Force-claiming session for " .. player.Name)
		end
	end

	-- Claim the session lock.
	data.sessionId = game.JobId
	data.lastSaved = os.time()

	_cache[userId] = data
	_dirty[userId] = false

	-- Write the session lock claim immediately.
	task.spawn(function()
		writeWithRetry(key, data)
	end)

	return data
end

--[[
	SavePlayerData(player)
	Persists the cached PlayerData to DataStore.
	Returns true on success, false on failure.
	Clears the dirty flag on success.
]]
function DataManager.SavePlayerData(player: Player): boolean
	local userId = player.UserId
	local data   = _cache[userId]
	if not data then
		return false
	end

	data.lastSaved = os.time()
	local key     = KEY_PREFIX .. tostring(userId)
	local success = writeWithRetry(key, data)
	if success then
		_dirty[userId] = false
	end
	return success
end

--[[
	GetPlayerData(player)
	Returns the in-memory cached PlayerData. No DataStore call.
	Returns nil if the player hasn't been loaded yet.
]]
function DataManager.GetPlayerData(player: Player): PlayerData?
	return _cache[player.UserId]
end

--[[
	MarkDirty(player)
	Signals that data has changed and should be persisted on the next autosave
	cycle (or immediately via SavePlayerData).
]]
function DataManager.MarkDirty(player: Player)
	if _cache[player.UserId] then
		_dirty[player.UserId] = true
	end
end

--[[
	ReleasePlayerData(player)
	Clears the session lock, saves data, and removes from cache.
	Called automatically by the PlayerRemoving handler in Initialize().
]]
function DataManager.ReleasePlayerData(player: Player)
	local userId = player.UserId
	local data   = _cache[userId]
	if not data then return end

	data.sessionId = ""
	data.lastSaved = os.time()

	local key = KEY_PREFIX .. tostring(userId)
	writeWithRetry(key, data)

	_cache[userId] = nil
	_dirty[userId] = nil
end

--[[
	SaveAll()
	Saves all dirty player records. Called by game:BindToClose() and manually
	by Initializer when shutting down. Runs synchronously so all writes finish
	before the server closes.
]]
function DataManager.SaveAll()
	for userId, dirty in pairs(_dirty) do
		if dirty then
			local data = _cache[userId]
			if data then
				data.sessionId = ""
				data.lastSaved = os.time()
				local key = KEY_PREFIX .. tostring(userId)
				writeWithRetry(key, data)
				_dirty[userId] = false
			end
		end
	end
end

--[[
	Initialize()
	Sets up autosave loop, BindToClose handler, and PlayerRemoving cleanup.
	Call once from Initializer.server.luau before any other service is started.
]]
function DataManager.Initialize()
	-- Autosave: save all dirty records periodically.
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for userId, dirty in pairs(_dirty) do
				if dirty then
					local player = Players:GetPlayerByUserId(userId)
					if player then
						DataManager.SavePlayerData(player)
					end
				end
			end
		end
	end)

	-- Release all data cleanly when the server shuts down.
	game:BindToClose(function()
		DataManager.SaveAll()
	end)

	-- Cleanup when a player leaves.
	Players.PlayerRemoving:Connect(function(player: Player)
		DataManager.ReleasePlayerData(player)
	end)
end

return DataManager
