--!strict
-- Basic-attack timing: hitDuration / comboTimeLimit (seconds) come from WeaponBasicAttackProfiles.
-- If hitDuration is missing or invalid, uses 60/60 and 75/60. If hit is valid but comboTimeLimit is missing, combo = hit.

export type BasicAttackTimingProfile = {
	hitDuration: number?,
	comboTimeLimit: number?,
}

export type ResolvedBasicAttackTimings = {
	hitDuration: number,
	comboTimeLimit: number,
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
	local h = profile.hitDuration
	local c = profile.comboTimeLimit
	if type(h) == "number" and isFinitePositive(h) then
		if type(c) == "number" and isFinitePositive(c) then
			return { hitDuration = h, comboTimeLimit = c }
		end
		return { hitDuration = h, comboTimeLimit = h }
	end
	return {
		hitDuration = DEFAULT_HIT_DURATION,
		comboTimeLimit = DEFAULT_COMBO_TIME_LIMIT,
	}
end

return AnimationAttackTiming
