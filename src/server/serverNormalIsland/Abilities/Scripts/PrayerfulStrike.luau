--!strict
--[[
	Server PrayerfulStrike: session gating, cooldowns, server-authoritative root motion
	at animation markers, and visual relay. VFX/SFX play on clients via relay + shared playback.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local scriptsFolder = script.Parent
assert(scriptsFolder, "[PrayerfulStrike] script.Parent missing")
local abilitiesFolder = scriptsFolder.Parent
assert(abilitiesFolder, "[PrayerfulStrike] Abilities folder missing")
local serverNormalIslandFolder = abilitiesFolder.Parent
assert(serverNormalIslandFolder, "[PrayerfulStrike] serverNormalIsland folder missing")

local AbilityRegistry =
	require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry") :: ModuleScript) :: any
local AbilityStateRuntime = require(abilitiesFolder:WaitForChild("AbilityStateRuntime") :: ModuleScript) :: any
local AbilityVisualRelayService = require(
	serverNormalIslandFolder:WaitForChild("Effects"):WaitForChild("AbilityVisualRelayService") :: ModuleScript
) :: any
local RootMotion = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RootMotion") :: ModuleScript) :: any

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

local function flatLook(root: BasePart): Vector3
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-4 then
		return Vector3.zAxis
	end
	return flat.Unit
end

local function rootMotionTune(): (number, number, number, number)
	local powerupStuds, powerupDur = 0.55, 0.12
	local lungeStuds, lungeDur = 5, 0.2
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" then
		local t = p :: any
		if type(t.rootMotionPowerupForwardStuds) == "number" and t.rootMotionPowerupForwardStuds > 0 then
			powerupStuds = t.rootMotionPowerupForwardStuds
		end
		if type(t.rootMotionPowerupDurationSeconds) == "number" and t.rootMotionPowerupDurationSeconds > 0 then
			powerupDur = t.rootMotionPowerupDurationSeconds
		end
		if type(t.rootMotionLungeForwardStuds) == "number" and t.rootMotionLungeForwardStuds > 0 then
			lungeStuds = t.rootMotionLungeForwardStuds
		end
		if type(t.rootMotionLungeDurationSeconds) == "number" and t.rootMotionLungeDurationSeconds > 0 then
			lungeDur = t.rootMotionLungeDurationSeconds
		end
	end
	return powerupStuds, powerupDur, lungeStuds, lungeDur
end

type Session = {
	exp: number,
	didP: boolean,
	didI: boolean,
	mover: any?,
}

local function tryApplyForwardRootMotion(session: Session, character: Model, forwardStuds: number, durationSec: number, destroyMoverWhenDone: boolean)
	if forwardStuds <= 0 or durationSec <= 0 then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	if not session.mover then
		local okMover, mover = pcall(function()
			return RootMotion.createMover(character)
		end)
		if not okMover or mover == nil then
			return
		end
		session.mover = mover
	end
	local mover = assert(session.mover, "[PrayerfulStrike] root motion mover expected")
	local dir = flatLook(hrp :: BasePart)
	local okTok, token = pcall(function()
		return mover:translate({
			direction = dir,
			distance = forwardStuds,
			duration = durationSec,
		})
	end)
	if not okTok or token == nil then
		pcall(function()
			mover:destroy()
		end)
		session.mover = nil
		return
	end
	token.Completed:Connect(function()
		if destroyMoverWhenDone and session.mover then
			local m = session.mover
			pcall(function()
				m:destroy()
			end)
			session.mover = nil
		end
	end)
end

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
	local s = sessions[plr]
	if s and s.mover then
		pcall(function()
			s.mover:destroy()
		end)
	end
	sessions[plr] = nil
end)

local PrayerfulStrike = {}

function PrayerfulStrike.CanUse(player: Player, context: ExecutionContext): boolean
	return AbilityStateRuntime.IsAbilityReady(player, context.abilityId)
end

function PrayerfulStrike.Execute(player: Player, context: ExecutionContext): boolean
	local prev = sessions[player]
	if prev and prev.mover then
		pcall(function()
			prev.mover:destroy()
		end)
	end
	local sess: Session = {
		exp = os.clock() + sessionWindow(),
		didP = false,
		didI = false,
		mover = nil,
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
	local character = player.Character
	if markerName == markPowerup then
		if s.didP then
			return
		end
		s.didP = true
		if character then
			local ps, pd, _, _ = rootMotionTune()
			tryApplyForwardRootMotion(s, character, ps, pd, false)
		end
		AbilityVisualRelayService.FireAll(player, ABILITY_ID, markerName)
		return
	end
	if s.didI then
		return
	end
	s.didI = true
	if character then
		local _, _, ls, ld = rootMotionTune()
		tryApplyForwardRootMotion(s, character, ls, ld, true)
	end
	AbilityVisualRelayService.FireAll(player, ABILITY_ID, markerName)
end

return PrayerfulStrike
