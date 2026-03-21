--!strict
-- Client mirror of AbilityStateRuntime for HUD cooldowns / blocked.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

export type CooldownTrackSync = {
	startedAt: number,
	endsAt: number,
}

export type AbilityStateSync = {
	blocked: boolean,
	tracks: { [string]: CooldownTrackSync },
}

local _abilities: { [string]: AbilityStateSync } = {}
local _subscribers: { (() -> ()) } = {}

local function notify()
	for _, cb in ipairs(_subscribers) do
		cb()
	end
end

local AbilityStateClient = {}

function AbilityStateClient.subscribe(callback: () -> ()): () -> ()
	table.insert(_subscribers, callback)
	return function()
		local i = table.find(_subscribers, callback)
		if i then
			table.remove(_subscribers, i)
		end
	end
end

function AbilityStateClient.getAbility(abilityId: string): AbilityStateSync?
	return _abilities[abilityId]
end

function AbilityStateClient.getDominantCooldown(abilityId: string): (number, number)
	local st = _abilities[abilityId]
	if not st then
		return 0, 0
	end
	local now = Workspace:GetServerTimeNow()
	local bestRem = 0
	local bestDur = 0
	for _, tr in pairs(st.tracks) do
		local rem = math.max(0, tr.endsAt - now)
		if rem > bestRem then
			bestRem = rem
			bestDur = math.max(0.001, tr.endsAt - tr.startedAt)
		end
	end
	return bestRem, bestDur
end

function AbilityStateClient.isAbilityBlocked(abilityId: string): boolean
	local st = _abilities[abilityId]
	return st ~= nil and st.blocked == true
end

function AbilityStateClient.anyCooldownActive(): boolean
	local now = Workspace:GetServerTimeNow()
	for _, st in pairs(_abilities) do
		if st.blocked then
			return true
		end
		for _, tr in pairs(st.tracks) do
			if tr.endsAt > now then
				return true
			end
		end
	end
	return false
end

local function applyPayload(abilityId: string, payload: any)
	if payload == nil then
		_abilities[abilityId] = nil
		return
	end
	if type(payload) ~= "table" then
		return
	end
	local blocked = payload.blocked == true
	local tracksRaw = payload.tracks
	local tracks: { [string]: CooldownTrackSync } = {}
	if type(tracksRaw) == "table" then
		for trackId, tr in pairs(tracksRaw) do
			if type(trackId) == "string" and type(tr) == "table" then
				local sa = tr.startedAt
				local ea = tr.endsAt
				if type(sa) == "number" and type(ea) == "number" then
					tracks[trackId] = { startedAt = sa, endsAt = ea }
				end
			end
		end
	end
	if not blocked and next(tracks) == nil then
		_abilities[abilityId] = nil
	else
		_abilities[abilityId] = { blocked = blocked, tracks = tracks }
	end
end

local function connectRemotes()
	local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")

	local snap = remotes:WaitForChild("AbilityStateSnapshot", 30)
	if snap and snap:IsA("RemoteEvent") then
		(snap :: RemoteEvent).OnClientEvent:Connect(function(payload: any)
			table.clear(_abilities)
			if type(payload) ~= "table" then
				notify()
				return
			end
			for abilityId, st in pairs(payload) do
				if type(abilityId) == "string" then
					applyPayload(abilityId, st)
				end
			end
			notify()
		end)
	end

	local ev = remotes:WaitForChild("AbilityStateChanged", 30)
	if not ev or not ev:IsA("RemoteEvent") then
		return
	end
	(ev :: RemoteEvent).OnClientEvent:Connect(function(abilityId: any, payload: any)
		if type(abilityId) ~= "string" or #abilityId == 0 then
			return
		end
		applyPayload(abilityId, payload)
		notify()
	end)
end

task.defer(connectRemotes)

return AbilityStateClient
