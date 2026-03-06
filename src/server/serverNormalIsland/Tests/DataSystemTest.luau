--!strict
-- DataSystemTest
-- Utility commands you can run in the Roblox Studio Command Bar to test the game data system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataServiceBootstrap = require(ServerScriptService.serverNormalIsland.Data.DataServiceBootstrap)
local InventoryService = require(ServerScriptService.serverNormalIsland.Inventory.InventoryService)
local DataServiceModule = DataServiceBootstrap.GetDataService()

local DataSystemTest = {}

-- Helper to find a player by name (or return the first player if no name provided)
local function getPlayer(playerName: string?): Player?
	if playerName and playerName ~= "" then
		return Players:FindFirstChild(playerName) :: Player
	end
	
	local players = Players:GetPlayers()
	if #players > 0 then
		return players[1]
	end
	
	warn("[DataSystemTest] No player found.")
	return nil
end

--[[
	GiveTestItem(playerName, templateId, count)
	Forces an item into the player's inventory using the InventoryService
]]
function DataSystemTest.GiveTestItem(playerName: string?, templateId: string?, count: number?)
	local player = getPlayer(playerName)
	if not player then return end
	
	templateId = templateId or "TestSword"
	count = count or 1
	
	local instanceId = InventoryService:AddItem(player, templateId, count)
	if instanceId then
		print(string.format("[DataSystemTest] Gave %d %s to %s. InstanceId: %s", count, templateId, player.Name, instanceId))
	else
		warn(string.format("[DataSystemTest] Failed to give %s to %s. Inventory might be full or template invalid.", templateId, player.Name))
	end
end

--[[
	CheckData(playerName)
	Prints the raw state of the player's DataService profile. Useful to see exactly what is being tracked for their character.
]]
function DataSystemTest.CheckData(playerName: string?)
	local player = getPlayer(playerName)
	if not player then return end
	
	local data = DataServiceModule.get(player, {})
	if data then
		print(string.format("[DataSystemTest] Raw PlayerData for %s:", player.Name))
		-- Simple pretty-print for top-level fields
		for k, v in pairs(data) do
			if type(v) == "table" then
				print("  ["..tostring(k).."] = (table)")
				if k == "inventory" and type(v.slots) == "table" then
					local c = 0
					for _, _ in pairs(v.slots) do c += 1 end
					print("    - Has " .. tostring(c) .. " items in inventory.")
				end
			else
				print("  ["..tostring(k).."] = " .. tostring(v))
			end
		end
	else
		warn("[DataSystemTest] Could not read data for " .. player.Name)
	end
end

--[[
	ForceSave(playerName)
	Uses the dataservice API to force a save if supported, otherwise just kicks them to ensure the autosave logic runs.
]]
function DataSystemTest.ForceSave(playerName: string?)
	local player = getPlayer(playerName)
	if not player then return end
	
	if type(DataServiceModule.forceSave) == "function" then
		DataServiceModule.forceSave(player)
		print(string.format("[DataSystemTest] Forced save for %s", player.Name))
	else
		print(string.format("[DataSystemTest] No DataServiceModule.forceSave exported. Kicking %s to trigger standard BindToClose/Removing saves...", player.Name))
		player:Kick("Data System Test - Forced Save")
	end
end

return DataSystemTest
