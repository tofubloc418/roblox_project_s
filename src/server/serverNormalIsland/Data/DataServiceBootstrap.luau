--!strict
-- DataServiceBootstrap
-- Initializes the leifstout/dataservice package on the server.
-- Handles player data lifecycle and exports WaitForPlayerData.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local DATA_MANAGER_MODULE_NAME = "DataManager"
local DataManager = require((script.Parent :: Instance):WaitForChild(DATA_MANAGER_MODULE_NAME)) :: any

local function getDefaultTemplate(): any
	return DataManager.createDefaultData(0)
end

local Packages = ReplicatedStorage:WaitForChild("Packages")
local DATA_SERVICE_MODULE_NAME = "DataService"
local DataServicePackage = require(Packages:WaitForChild(DATA_SERVICE_MODULE_NAME)) :: any
local DataServiceServer = DataServicePackage.server :: any

export type Path = { string }

local DataServiceBootstrap = {}

-- Call once from Initializer before any service that needs player data.
function DataServiceBootstrap.Initialize()
	local template = getDefaultTemplate()
	local isStudio = RunService:IsStudio()
	local ok, err = pcall(function()
		if type(DataServiceServer.init) == "function" then
			DataServiceServer:init({
				template = template,
				profileStoreIndex = "PlayerData_v1",
				profileStoreDataPrefix = "PLAYER_",
			})
		elseif type(DataServiceServer.InitServer) == "function" then
			DataServiceServer:InitServer({
				template = template,
				storeName = "PlayerData_v1",
				keyFormat = "PLAYER_%s",
			})
		else
		error("[DataServiceBootstrap] No init or InitServer on DataService")
		end
	end)
	if not ok then
		warn("[DataServiceBootstrap] Init failed: ", tostring(err))
		return
	end

	-- Guard against double _playerAdded calls (Studio race condition)
	local originalPlayerAdded = DataServiceServer._playerAdded
	local loadingPlayers: { [Player]: boolean } = {}
	function DataServiceServer._playerAdded(self: any, player: Player)
		if loadingPlayers[player] then return end
		loadingPlayers[player] = true
		originalPlayerAdded(self, player)
		loadingPlayers[player] = nil
	end

	print(string.format("[DataServiceBootstrap] DataService server initialized (Studio=%s)", tostring(isStudio)))
end

-- Yields until the player's data is loaded. Returns nil on failure.
function DataServiceBootstrap.WaitForPlayerData(player: Player): any?
	if type(DataServiceServer.waitForData) == "function" then
		return DataServiceServer:waitForData(player)
	end
	if type(DataServiceServer.WaitForData) == "function" then
		return DataServiceServer:WaitForData(player)
	end
	local ds = DataServiceServer
	if type(ds.get) == "function" then
		return ds:get(player, {})
	end
	if type(ds.Get) == "function" then
		return ds:Get(player, {})
	end
	warn("[DataServiceBootstrap] No waitForData or get on DataService")
	return nil
end

-- Returns the raw DataServiceServer module.
function DataServiceBootstrap.GetDataService(): any
	return DataServiceServer
end

return DataServiceBootstrap
