--!strict
-- DataServiceBootstrap
-- Initializes the leifstout/dataservice package on the server: ProfileStore-backed
-- persistence, path-based get/set/update, and automatic replication to clients.
-- Player lifecycle (load on PlayerAdded, release on PlayerRemoving/BindToClose)
-- is handled by the package; this module wires the template and exports WaitForPlayerData.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dynamic require so the type checker does not resolve DataManager (relative path, may be unindexed).
local DATA_MANAGER_MODULE_NAME = "DataManager"
local DataManager = require(script.Parent:WaitForChild(DATA_MANAGER_MODULE_NAME)) :: any

-- Default template for new players (Reconcile-only; no migrations in this refactor).
local function getDefaultTemplate(): any
	return DataManager.createDefaultData(0)
end

-- Require the dataservice package (ReplicatedStorage.Packages.DataService).
-- Dynamic require so the type checker does not resolve Packages (wally-installed, may be unindexed).
local Packages = ReplicatedStorage:WaitForChild("Packages")
local DATA_SERVICE_MODULE_NAME = "DataService"
local DataServiceModule = require(Packages:WaitForChild(DATA_SERVICE_MODULE_NAME)) :: any

export type Path = { string }

local DataServiceBootstrap = {}

--[[
	Initialize()
	Configures the dataService server with the PlayerData template and store options.
	Call once from Initializer before any service that needs player data.
	Does not wire PlayerAdded/PlayerRemoving; the package typically does that internally,
	or the caller uses WaitForPlayerData in onPlayerAdded.
]]
function DataServiceBootstrap.Initialize()
	local template = getDefaultTemplate()
	-- leifstout/dataservice server init. Adjust options to match package API if needed.
	local ok, err = pcall(function()
		if type(DataServiceModule.init) == "function" then
			DataServiceModule.init({
				template = template,
				storeName = "PlayerData_v1",
				keyFormat = "player_%s",
			})
		elseif type(DataServiceModule.InitServer) == "function" then
			DataServiceModule.InitServer({
				template = template,
				storeName = "PlayerData_v1",
				keyFormat = "player_%s",
			})
		else
			-- Fallback: some packages use CreateStore or similar
			error("[DataServiceBootstrap] DataService package has no init or InitServer")
		end
	end)
	if not ok then
		warn("[DataServiceBootstrap] Init failed: ", tostring(err))
		return
	end
	print("[DataServiceBootstrap] DataService server initialized")
end

--[[
	WaitForPlayerData(player)
	Yields until the player's profile/data is loaded and returns the full PlayerData.
	Returns nil if the player was kicked or data could not be loaded.
]]
function DataServiceBootstrap.WaitForPlayerData(player: Player): any?
	if type(DataServiceModule.waitForData) == "function" then
		return DataServiceModule.waitForData(player)
	end
	if type(DataServiceModule.WaitForData) == "function" then
		return DataServiceModule.WaitForData(player)
	end
	-- Fallback: get root data (might yield until ready)
	local ds = DataServiceModule
	if type(ds.get) == "function" then
		return ds.get(player, {})
	end
	if type(ds.Get) == "function" then
		return ds.Get(player, {})
	end
	warn("[DataServiceBootstrap] No waitForData or get on DataService")
	return nil
end

--[[
	GetDataService()
	Returns the raw DataService module for path-based get/set/update (used by
	InventoryService and AbilityDataService). Prefer using this so we have one
	place that holds the required package.
]]
function DataServiceBootstrap.GetDataService(): any
	return DataServiceModule
end

return DataServiceBootstrap
