--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceBootstrap = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataServiceBootstrap"))

local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindRegistry = require(keybindsFolder:WaitForChild("KeybindRegistry"))
local KeybindsCodec = require(keybindsFolder:WaitForChild("KeybindsCodec"))

local DataService = DataServiceBootstrap.GetDataService()

local function setAtPath(player: Player, path: { string | number }, value: any)
	local ds = DataService
	if type(ds.set) == "function" then
		ds:set(player, path, value)
		return
	end
	if type(ds.Set) == "function" then
		ds:Set(player, path, value)
		return
	end
	if type((ds :: any).set) == "function" then
		(ds :: any):set(player, path, value)
	end
end

local function waitForProfile(player: Player): boolean
	local ds = DataService
	if type(ds.hasProfile) == "function" and not ds:hasProfile(player) then
		if type(ds.waitForData) == "function" then
			ds:waitForData(player)
		elseif type(ds.WaitForData) == "function" then
			ds:WaitForData(player)
		else
			return false
		end
	end
	return true
end

local function normalizeKeybindNames(rawValue: any): { string }?
	local names = KeybindsCodec.NormalizeStoredValue(rawValue)
	if not names then
		return nil
	end

	local validNames: { string } = {}
	for _, name in ipairs(names) do
		if KeybindsCodec.NameToKeyCode(name) then
			table.insert(validNames, name)
		end
	end
	return validNames
end

local function encodeStoredValue(names: { string }): string | { string }
	if #names == 1 then
		return names[1]
	end
	return names
end

local KeybindsService = {}

function KeybindsService.SetKeybinds(player: Player, actionId: string, rawValue: any): boolean
	if not KeybindRegistry.Has(actionId) then
		return false
	end

	local names = normalizeKeybindNames(rawValue)
	if not names then
		return false
	end

	if not waitForProfile(player) then
		return false
	end

	setAtPath(player, { "settings", "keybinds", actionId }, encodeStoredValue(names))
	return true
end

function KeybindsService.Initialize()
	local remotesFolder = ReplicatedStorage:FindFirstChild("KeybindRemotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "KeybindRemotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	local setKeybindsRemote = remotesFolder:FindFirstChild("SetKeybinds")
	if not setKeybindsRemote then
		setKeybindsRemote = Instance.new("RemoteEvent")
		setKeybindsRemote.Name = "SetKeybinds"
		setKeybindsRemote.Parent = remotesFolder
	end

	(setKeybindsRemote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, actionId: string, rawValue: any)
		KeybindsService.SetKeybinds(player, actionId, rawValue)
	end)
end

return KeybindsService
