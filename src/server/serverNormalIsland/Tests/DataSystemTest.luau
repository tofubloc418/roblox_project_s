--!strict
-- DataSystemTest
-- Studio Command Bar test utilities. Routes stateful calls through _TestBridge.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataSystemTest = {}

-- Helper: resolve player by name, or default to first player.
local function getPlayerName(playerName: string?): string?
	if playerName and playerName ~= "" then
		local p = Players:FindFirstChild(playerName)
		if not p then
			warn(string.format("[DataSystemTest] Player '%s' not found.", playerName))
			return nil
		end
		return (p :: Player).Name
	end
	local players = Players:GetPlayers()
	if #players > 0 then
		return players[1].Name
	end
	warn("[DataSystemTest] No players in server.")
	return nil
end

-- Helper: invoke the server-side test bridge.
local function bridge(action: string, ...: any): (any, any)
	local bf = ServerScriptService:FindFirstChild("_TestBridge") :: BindableFunction
	if not bf then
		warn("[DataSystemTest] _TestBridge not found. Is the server running?")
		return nil, "Bridge missing"
	end
	return bf:Invoke(action, ...)
end

--[[
	GiveTestItem(playerName, templateId, count)
	Adds an item to the player's inventory via the server-side InventoryService.
]]
function DataSystemTest.GiveTestItem(playerName: string?, templateId: string?, count: number?)
	local name = getPlayerName(playerName)
	if not name then return end
	local ok, result = bridge("GiveItem", name, templateId or "TestSword", count or 1)
	if ok then
		print(string.format("[DataSystemTest] Gave %d x %s to %s. iid=%s",
			count or 1, templateId or "TestSword", name, tostring(result)))
	else
		warn(string.format("[DataSystemTest] GiveItem failed for %s: %s", name, tostring(result)))
	end
end

--[[
	CheckData(playerName)
	Prints the raw DataService profile for the player.
]]
function DataSystemTest.CheckData(playerName: string?)
	local name = getPlayerName(playerName)
	if not name then return end
	local data = bridge("CheckData", name)
	if type(data) == "table" then
		print(string.format("[DataSystemTest] Raw PlayerData for %s:", name))
		for k, v in pairs(data) do
			if type(v) == "table" then
				print("  ["..tostring(k).."] = (table)")
				if k == "inventory" and type(v.slots) == "table" then
					local c = 0
					for _ in pairs(v.slots) do c += 1 end
					print("    slots: " .. tostring(c) .. " item(s)")
				end
			else
				print("  ["..tostring(k).."] = " .. tostring(v))
			end
		end
	else
		warn(string.format("[DataSystemTest] No data returned for %s.", name))
	end
end

--[[
	ListPlayers()
	Lists every player in the server with their Name, DisplayName, and UserId.
]]
function DataSystemTest.ListPlayers()
	local players = Players:GetPlayers()
	if #players == 0 then
		warn("[DataSystemTest] No players in server.")
		return
	end
	print(string.format("[DataSystemTest] %d player(s) in server:", #players))
	for i, p in ipairs(players) do
		print(string.format("  %d) Name='%s'  DisplayName='%s'  UserId=%d", i, p.Name, p.DisplayName, p.UserId))
	end
end

--[[
	ListLoadedData()
	Shows which players have had their data successfully loaded.
	Reads the _DataLoaded attribute set by the server on data load.
]]
function DataSystemTest.ListLoadedData()
	local players = Players:GetPlayers()
	local loaded = {}
	local missing = {}

	for _, p in ipairs(players) do
		if p:GetAttribute("_DataLoaded") then
			table.insert(loaded, p)
		else
			table.insert(missing, p)
		end
	end

	if #players == 0 then
		warn("[DataSystemTest] No players in server.")
		return
	end

	print(string.format("[DataSystemTest] %d/%d player(s) with data loaded:", #loaded, #players))
	for _, p in ipairs(loaded) do
		print(string.format("  [loaded] %s (UserId=%d)", p.Name, p.UserId))
	end
	for _, p in ipairs(missing) do
		warn(string.format("  [NO DATA] %s (UserId=%d)", p.Name, p.UserId))
	end
end

--[[
	ForceSave(playerName)
	Triggers a server-side save for the player.
]]
function DataSystemTest.ForceSave(playerName: string?)
	local name = getPlayerName(playerName)
	if not name then return end
	local ok, result = bridge("ForceSave", name)
	if ok then
		print(string.format("[DataSystemTest] ForceSave succeeded for %s.", name))
	else
		warn(string.format("[DataSystemTest] ForceSave failed for %s: %s", name, tostring(result)))
	end
end

return DataSystemTest
