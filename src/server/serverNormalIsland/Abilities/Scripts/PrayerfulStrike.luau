--!strict
--[[
	Server PrayerfulStrike: session gating, cooldowns, and visual relay.
	All VFX/SFX are played on clients via AbilityVisualRelayService + shared playback.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry")) :: any
local AbilityStateRuntime = require(script.Parent.Parent:WaitForChild("AbilityStateRuntime")) :: any
local AbilityVisualRelayService =
	require(script.Parent.Parent.Parent:WaitForChild("Effects"):WaitForChild("AbilityVisualRelayService")) :: any

type ExecutionContext = { player: Player, abilityId: string }

local ABILITY_ID = "PrayerfulStrike"
local MAIN_TRACK = "main"

local function cfgMarkers(): (string, string)
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	if not c then
		error(`[PrayerfulStrike] AbilityRegistry missing entry for {ABILITY_ID}`, 2)
	end
	local p = c.params
	if type(p) ~= "table" then
		error("[PrayerfulStrike] params table is required", 2)
	end
	local t = p :: any
	local mpu, mpi = t.markerPowerup, t.markerImpact
	if type(mpu) ~= "string" or mpu == "" then
		error("[PrayerfulStrike] params.markerPowerup must be a non-empty string", 2)
	end
	if type(mpi) ~= "string" or mpi == "" then
		error("[PrayerfulStrike] params.markerImpact must be a non-empty string", 2)
	end
	return mpu, mpi
end

type Session = {
	exp: number,
	didP: boolean,
	didI: boolean,
}

local sessions: { [Player]: Session } = {}

local function sessionWindow(): number
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" and type((p :: any).totalDurationSeconds) == "number" then
		return math.max((p :: any).totalDurationSeconds, 0.5) + 3
	end
	return 220 / 60 + 3
end

local function cooldownSec(): number
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" and type((p :: any).cooldownSeconds) == "number" and (p :: any).cooldownSeconds > 0 then
		return (p :: any).cooldownSeconds
	end
	return 8
end

Players.PlayerRemoving:Connect(function(plr: Player)
	sessions[plr] = nil
end)

local PrayerfulStrike = {}

function PrayerfulStrike.CanUse(player: Player, context: ExecutionContext): boolean
	return AbilityStateRuntime.IsAbilityReady(player, context.abilityId)
end

function PrayerfulStrike.Execute(player: Player, context: ExecutionContext): boolean
	local sess: Session = {
		exp = os.clock() + sessionWindow(),
		didP = false,
		didI = false,
	}
	sessions[player] = sess
	AbilityStateRuntime.StartCooldown(player, context.abilityId, MAIN_TRACK, cooldownSec())
	return true
end

function PrayerfulStrike.OnAnimationMarker(player: Player, markerName: string)
	local markPowerup, markImpact = cfgMarkers()
	if markerName ~= markPowerup and markerName ~= markImpact then
		return
	end
	local s = sessions[player]
	if not s or os.clock() > s.exp then
		return
	end
	if markerName == markPowerup then
		if s.didP then
			return
		end
		s.didP = true
		AbilityVisualRelayService.FireAll(player, ABILITY_ID, markerName)
		return
	end
	if s.didI then
		return
	end
	s.didI = true
	AbilityVisualRelayService.FireAll(player, ABILITY_ID, markerName)
end

return PrayerfulStrike
