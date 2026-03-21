--!strict
-- Per-player state keyed by abilityId: named cooldown tracks + optional blocked flag.
-- Ability server scripts use these helpers from CanUse/Execute; state syncs to the client HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

type TrackState = {
	startedAt: number,
	endsAt: number,
}

type AbilityState = {
	blocked: boolean,
	tracks: { [string]: TrackState },
}

-- Minimal shape for ability dispatch context (matches AbilityExecutionService.AbilityExecutionContext fields used here).
export type AbilityExecutionContextLike = {
	player: Player,
	abilityId: string,
}

export type BoundAbilityStateApi = {
	startCooldown: (trackId: string, durationSeconds: number) -> (),
	clearCooldownTrack: (trackId: string) -> (),
	clearAllCooldownTracks: () -> (),
	setBlocked: (blocked: boolean) -> (),
	isReady: () -> boolean,
	getCooldownRemaining: (trackId: string) -> number,
}

local AbilityStateRuntime = {}

local _changedRemote: RemoteEvent
local _snapshotRemote: RemoteEvent
local _byPlayer: { [Player]: { [string]: AbilityState } } = {}

local function nowServer(): number
	return Workspace:GetServerTimeNow()
end

local function ensurePlayer(player: Player): { [string]: AbilityState }
	local t = _byPlayer[player]
	if not t then
		t = {}
		_byPlayer[player] = t
	end
	return t
end

local function ensureAbility(player: Player, abilityId: string): AbilityState
	assert(type(abilityId) == "string" and #abilityId > 0, "AbilityStateRuntime: abilityId required")
	local map = ensurePlayer(player)
	local s = map[abilityId]
	if not s then
		s = { blocked = false, tracks = {} }
		map[abilityId] = s
	end
	return s
end

local function pruneExpiredTracks(state: AbilityState)
	local tNow = nowServer()
	for trackId, tr in pairs(state.tracks) do
		if tr.endsAt <= tNow then
			state.tracks[trackId] = nil
		end
	end
end

local function packTracks(state: AbilityState): { [string]: { startedAt: number, endsAt: number } }
	local tracksOut: { [string]: { startedAt: number, endsAt: number } } = {}
	for trackId, tr in pairs(state.tracks) do
		tracksOut[trackId] = { startedAt = tr.startedAt, endsAt = tr.endsAt }
	end
	return tracksOut
end

local function fireAbilitySync(player: Player, abilityId: string, map: { [string]: AbilityState })
	local state = map[abilityId]
	if state then
		pruneExpiredTracks(state)
		if not state.blocked and next(state.tracks) == nil then
			map[abilityId] = nil
			_changedRemote:FireClient(player, abilityId, nil)
			return
		end
	end
	if not state then
		return
	end
	_changedRemote:FireClient(player, abilityId, {
		blocked = state.blocked,
		tracks = packTracks(state),
	})
end

local function fireFullSnapshot(player: Player)
	local map = _byPlayer[player]
	if not map then
		_snapshotRemote:FireClient(player, {})
		return
	end
	local out: { [string]: { blocked: boolean, tracks: { [string]: { startedAt: number, endsAt: number } } } } = {}
	for abilityId, state in pairs(map) do
		pruneExpiredTracks(state)
		if state.blocked or next(state.tracks) ~= nil then
			out[abilityId] = {
				blocked = state.blocked,
				tracks = packTracks(state),
			}
		else
			map[abilityId] = nil
		end
	end
	_snapshotRemote:FireClient(player, out)
end

function AbilityStateRuntime.Initialize()
	local remoteFolder = ReplicatedStorage:WaitForChild("InventoryRemotes")

	local function ensureRemote(name: string): RemoteEvent
		local existing = remoteFolder:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			return existing :: RemoteEvent
		end
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = remoteFolder
		return ev
	end

	_changedRemote = ensureRemote("AbilityStateChanged")
	_snapshotRemote = ensureRemote("AbilityStateSnapshot")

	Players.PlayerAdded:Connect(function(player: Player)
		ensurePlayer(player)
		task.defer(function()
			if player.Parent then
				fireFullSnapshot(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		_byPlayer[player] = nil
	end)

	for _, p in Players:GetPlayers() do
		ensurePlayer(p)
		task.defer(function()
			if p.Parent then
				fireFullSnapshot(p)
			end
		end)
	end
end

function AbilityStateRuntime.SetAbilityBlocked(player: Player, abilityId: string, blocked: boolean)
	local map = ensurePlayer(player)
	local state = ensureAbility(player, abilityId)
	state.blocked = blocked
	fireAbilitySync(player, abilityId, map)
end

function AbilityStateRuntime.IsAbilityBlocked(player: Player, abilityId: string): boolean
	local map = _byPlayer[player]
	if not map then
		return false
	end
	local state = map[abilityId]
	return state ~= nil and state.blocked == true
end

function AbilityStateRuntime.IsAbilityReady(player: Player, abilityId: string): boolean
	if AbilityStateRuntime.IsAbilityBlocked(player, abilityId) then
		return false
	end
	return AbilityStateRuntime.GetMaxCooldownRemaining(player, abilityId) <= 0
end

function AbilityStateRuntime.StartCooldown(player: Player, abilityId: string, trackId: string, durationSeconds: number)
	assert(type(trackId) == "string" and #trackId > 0, "AbilityStateRuntime.StartCooldown: trackId required")
	assert(type(durationSeconds) == "number" and durationSeconds > 0, "AbilityStateRuntime.StartCooldown: duration must be > 0")

	local map = ensurePlayer(player)
	local state = ensureAbility(player, abilityId)
	local tNow = nowServer()
	state.tracks[trackId] = {
		startedAt = tNow,
		endsAt = tNow + durationSeconds,
	}
	fireAbilitySync(player, abilityId, map)
end

function AbilityStateRuntime.ClearCooldownTrack(player: Player, abilityId: string, trackId: string)
	local map = _byPlayer[player]
	if not map then
		return
	end
	local state = map[abilityId]
	if not state then
		return
	end
	state.tracks[trackId] = nil
	fireAbilitySync(player, abilityId, map)
end

function AbilityStateRuntime.ClearAllCooldownTracks(player: Player, abilityId: string)
	local map = _byPlayer[player]
	if not map then
		return
	end
	local state = map[abilityId]
	if not state then
		return
	end
	table.clear(state.tracks)
	fireAbilitySync(player, abilityId, map)
end

function AbilityStateRuntime.GetCooldownTrackRemaining(player: Player, abilityId: string, trackId: string): number
	local map = _byPlayer[player]
	if not map then
		return 0
	end
	local state = map[abilityId]
	if not state then
		return 0
	end
	local tr = state.tracks[trackId]
	if not tr then
		return 0
	end
	return math.max(0, tr.endsAt - nowServer())
end

function AbilityStateRuntime.IsCooldownTrackReady(player: Player, abilityId: string, trackId: string): boolean
	return AbilityStateRuntime.GetCooldownTrackRemaining(player, abilityId, trackId) <= 0
end

function AbilityStateRuntime.GetMaxCooldownRemaining(player: Player, abilityId: string): number
	local map = _byPlayer[player]
	if not map then
		return 0
	end
	local state = map[abilityId]
	if not state then
		return 0
	end
	local tNow = nowServer()
	local maxRem = 0
	for _, tr in pairs(state.tracks) do
		local rem = tr.endsAt - tNow
		if rem > maxRem then
			maxRem = rem
		end
	end
	return math.max(0, maxRem)
end

function AbilityStateRuntime.bindContext(player: Player, abilityId: string): BoundAbilityStateApi
	return {
		startCooldown = function(trackId: string, durationSeconds: number)
			AbilityStateRuntime.StartCooldown(player, abilityId, trackId, durationSeconds)
		end,
		clearCooldownTrack = function(trackId: string)
			AbilityStateRuntime.ClearCooldownTrack(player, abilityId, trackId)
		end,
		clearAllCooldownTracks = function()
			AbilityStateRuntime.ClearAllCooldownTracks(player, abilityId)
		end,
		setBlocked = function(blocked: boolean)
			AbilityStateRuntime.SetAbilityBlocked(player, abilityId, blocked)
		end,
		isReady = function()
			return AbilityStateRuntime.IsAbilityReady(player, abilityId)
		end,
		getCooldownRemaining = function(trackId: string)
			return AbilityStateRuntime.GetCooldownTrackRemaining(player, abilityId, trackId)
		end,
	}
end

function AbilityStateRuntime.bindExecutionContext(context: AbilityExecutionContextLike): BoundAbilityStateApi
	return AbilityStateRuntime.bindContext(context.player, context.abilityId)
end

return AbilityStateRuntime
