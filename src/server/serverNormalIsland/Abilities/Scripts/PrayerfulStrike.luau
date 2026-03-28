--!strict
-- Session, cooldowns, server RootMotion, visual relay. Tunables: PrayerfulStrike params (rootMotion*).

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
local PHASE1_START_MARKER = "__PrayerfulStrikePhase1Start"

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
	local p1Studs, p1Dur = 0.55, 1.0
	local p2Studs, p2Dur = 5, 0.5
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" then
		local t = p :: any
		if type(t.rootMotionPhase1ForwardStuds) == "number" and t.rootMotionPhase1ForwardStuds > 0 then
			p1Studs = t.rootMotionPhase1ForwardStuds
		end
		if type(t.rootMotionPhase1DurationSeconds) == "number" and t.rootMotionPhase1DurationSeconds > 0 then
			p1Dur = t.rootMotionPhase1DurationSeconds
		end
		if type(t.rootMotionPhase2ForwardStuds) == "number" and t.rootMotionPhase2ForwardStuds > 0 then
			p2Studs = t.rootMotionPhase2ForwardStuds
		end
		if type(t.rootMotionPhase2DurationSeconds) == "number" and t.rootMotionPhase2DurationSeconds > 0 then
			p2Dur = t.rootMotionPhase2DurationSeconds
		end
	end
	return p1Studs, p1Dur, p2Studs, p2Dur
end

local function lungeDelayAfterPowerupSeconds(): number
	local delaySec = 39 / 60
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" then
		local t = p :: any
		if type(t.rootMotionLungeDelayAfterPowerupSeconds) == "number" and t.rootMotionLungeDelayAfterPowerupSeconds >= 0 then
			delaySec = t.rootMotionLungeDelayAfterPowerupSeconds
		end
	end
	return delaySec
end

type Session = {
	exp: number,
	didPhase1Start: boolean,
	didP: boolean,
	didI: boolean,
	mover: any?,
}

local function tryApplyForwardRootMotion(session: Session, character: Model, forwardStuds: number, durationSec: number)
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
end

local function stopRootMotion(session: Session)
	if session.mover then
		pcall(function()
			session.mover:cancelAll()
			session.mover:destroy()
		end)
		session.mover = nil
	end
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
	if s then
		stopRootMotion(s)
	end
	sessions[plr] = nil
end)

local PrayerfulStrike = {}

function PrayerfulStrike.CanUse(player: Player, context: ExecutionContext): boolean
	return AbilityStateRuntime.IsAbilityReady(player, context.abilityId)
end

function PrayerfulStrike.Execute(player: Player, context: ExecutionContext): boolean
	local prev = sessions[player]
	if prev then
		stopRootMotion(prev)
	end
	local sess: Session = {
		exp = os.clock() + sessionWindow(),
		didPhase1Start = false,
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
	local s = sessions[player]
	if not s or os.clock() > s.exp then
		return
	end
	local character = player.Character

	if markerName == PHASE1_START_MARKER then
		if s.didPhase1Start or s.didP then
			return
		end
		s.didPhase1Start = true
		if character then
			local p1s, p1d, _, _ = rootMotionTune()
			tryApplyForwardRootMotion(s, character, p1s, p1d)
		end
		return
	end

	if markerName ~= markPowerup and markerName ~= markImpact then
		return
	end

	if markerName == markPowerup then
		if s.didP then
			return
		end
		s.didP = true
		if character then
			local sessionRef = s
			local delaySec = lungeDelayAfterPowerupSeconds()
			local function beginLunge()
				if sessions[player] ~= sessionRef or os.clock() > sessionRef.exp or sessionRef.didI then
					return
				end
				local ch = player.Character
				if not ch then
					return
				end
				local _, _, p2s, p2d = rootMotionTune()
				tryApplyForwardRootMotion(sessionRef, ch, p2s, p2d)
			end
			if delaySec <= 0 then
				beginLunge()
			else
				task.delay(delaySec, beginLunge)
			end
		end
		AbilityVisualRelayService.FireAll(player, ABILITY_ID, markerName)
		return
	end

	if s.didI then
		return
	end
	s.didI = true
	if character then
		stopRootMotion(s)
	end
	AbilityVisualRelayService.FireAll(player, ABILITY_ID, markerName)
end

return PrayerfulStrike
