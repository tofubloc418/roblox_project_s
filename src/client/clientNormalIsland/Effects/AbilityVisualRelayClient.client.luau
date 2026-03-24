--!strict
--[[
	Listens for AbilityVisualRelay events from the server and dispatches to
	per-ability script modules under Abilities/Scripts/<abilityId>.

	Each ability script exports OnRelay(casterCharacter: Model, eventName: string, payload: any?).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local relay = remotes:WaitForChild("AbilityVisualRelay") :: RemoteEvent

local scriptsFolder = script.Parent.Parent:WaitForChild("Abilities"):WaitForChild("Scripts", 5)

local moduleCache: { [string]: any } = {}

local function getAbilityModule(abilityId: string): any?
	if moduleCache[abilityId] ~= nil then
		return moduleCache[abilityId]
	end
	if not scriptsFolder then
		return nil
	end
	local mod = scriptsFolder:FindFirstChild(abilityId)
	if not mod or not mod:IsA("ModuleScript") then
		moduleCache[abilityId] = false :: any
		return nil
	end
	local ok, result = pcall(require, mod :: ModuleScript)
	if not ok or type(result) ~= "table" then
		moduleCache[abilityId] = false :: any
		return nil
	end
	moduleCache[abilityId] = result
	return result
end

relay.OnClientEvent:Connect(function(casterUserId: unknown, abilityId: unknown, eventName: unknown, payload: unknown)
	if type(casterUserId) ~= "number" or type(abilityId) ~= "string" or type(eventName) ~= "string" then
		return
	end

	local caster = Players:GetPlayerByUserId(casterUserId :: number)
	if not caster then
		return
	end
	local character = caster.Character
	if not character then
		return
	end

	local abilityModule = getAbilityModule(abilityId :: string)
	if not abilityModule then
		return
	end

	local fn = abilityModule.OnRelay
	if type(fn) == "function" then
		task.spawn(fn, character, eventName :: string, payload)
	end
end)
