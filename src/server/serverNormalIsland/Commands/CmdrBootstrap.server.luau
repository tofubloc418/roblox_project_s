--!strict
-- Cmdr bootstrap: Studio-only dev commands, types, and DevRemotes (e.g. hitbox).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then return existing :: Folder end
	if existing then existing:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function ensureRemote(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing :: RemoteEvent end
	if existing then existing:Destroy() end
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = parent
	return r
end

local devRemotes = ensureFolder(ReplicatedStorage, "DevRemotes")
ensureRemote(devRemotes, "SetHitboxDebug")

local Cmdr = require(ReplicatedStorage:WaitForChild("Cmdr"))

Cmdr.Registry:RegisterHook("BeforeRun", function(_context): string?
	if not RunService:IsStudio() then
		return "Dev commands are disabled in live games."
	end
	return nil
end)

local commandsFolder = script.Parent:WaitForChild("CmdrCommands")
local typesFolder = script.Parent:FindFirstChild("CmdrTypes")
if typesFolder then
	Cmdr.Registry:RegisterTypesIn(typesFolder)
end
Cmdr.Registry:RegisterCommandsIn(commandsFolder)
