--!strict
-- Timings from WeaponBasicAttackProfiles (seconds):
--   hitDuration → hitbox + movement lock duration on swing
--   comboTimeLimitMin → min time before next attack input (nextAttackTime)
--   comboTimeLimitMax → combo chain window (comboExpireTime)
-- Missing / invalid hitDuration → DEFAULT_HIT_DURATION (60/60) for hit; min = that hit; max = DEFAULT_COMBO_TIME_LIMIT (75/60).
-- Valid hitDuration, omit min → comboTimeLimitMin = hitDuration. Omit max → comboTimeLimitMax = hitDuration.

export type BasicAttackTimingProfile = {
	hitDuration: number?,
	comboTimeLimitMin: number?,
	comboTimeLimitMax: number?,
}

export type ResolvedBasicAttackTimings = {
	hitDuration: number,
	comboTimeLimitMin: number,
	comboTimeLimitMax: number,
}

local DEFAULT_HIT_DURATION = 60 / 60
local DEFAULT_COMBO_TIME_LIMIT = 75 / 60

local AnimationAttackTiming = {}

AnimationAttackTiming.DEFAULT_HIT_DURATION = DEFAULT_HIT_DURATION
AnimationAttackTiming.DEFAULT_COMBO_TIME_LIMIT = DEFAULT_COMBO_TIME_LIMIT

local function isFinitePositive(n: number): boolean
	return n == n and n > 0 and n < math.huge
end

function AnimationAttackTiming.resolveBasicAttackTimings(profile: BasicAttackTimingProfile, _debugLabel: string?): ResolvedBasicAttackTimings
	local hRaw = profile.hitDuration
	if type(hRaw) ~= "number" or not isFinitePositive(hRaw) then
		return {
			hitDuration = DEFAULT_HIT_DURATION,
			comboTimeLimitMin = DEFAULT_HIT_DURATION,
			comboTimeLimitMax = DEFAULT_COMBO_TIME_LIMIT,
		}
	end
	local h = hRaw
	local minV = profile.comboTimeLimitMin
	local maxV = profile.comboTimeLimitMax
	local minOut = if type(minV) == "number" and isFinitePositive(minV) then minV else h
	local maxOut = if type(maxV) == "number" and isFinitePositive(maxV) then maxV else h
	return {
		hitDuration = h,
		comboTimeLimitMin = minOut,
		comboTimeLimitMax = maxOut,
	}
end

return AnimationAttackTiming
