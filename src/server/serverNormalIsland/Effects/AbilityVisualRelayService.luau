--!strict
--[[
	Server→client relay for ability visual events (marker-timed SFX, impact VFX, etc.).
	Ability server scripts call FireAll to broadcast to every client; client-side
	AbilityVisualRelayClient dispatches to per-ability visual modules.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityVisualRelayService = {}

local _remote: RemoteEvent

function AbilityVisualRelayService.Initialize()
	local remoteFolder = ReplicatedStorage:WaitForChild("InventoryRemotes")

	local existing = remoteFolder:FindFirstChild("AbilityVisualRelay")
	if existing and existing:IsA("RemoteEvent") then
		_remote = existing :: RemoteEvent
	else
		local r = Instance.new("RemoteEvent")
		r.Name = "AbilityVisualRelay"
		r.Parent = remoteFolder
		_remote = r
	end
end

function AbilityVisualRelayService.FireAll(caster: Player, abilityId: string, eventName: string, payload: any?)
	_remote:FireAllClients(caster.UserId, abilityId, eventName, payload)
end

return AbilityVisualRelayService
