--!strict

export type BasicAttackTimingProfile = {
	hitboxStartTime: number?,
	hitboxEndTime: number?,
	comboTimeLimitMin: number?,
	comboTimeLimitMax: number?,
}

export type ResolvedBasicAttackTimings = {
	hitboxStartTime: number,
	hitboxEndTime: number,
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
	local endRaw = profile.hitboxEndTime
	if type(endRaw) ~= "number" or not isFinitePositive(endRaw) then
		return {
			hitboxStartTime = 0,
			hitboxEndTime = DEFAULT_HIT_DURATION,
			comboTimeLimitMin = DEFAULT_HIT_DURATION,
			comboTimeLimitMax = DEFAULT_COMBO_TIME_LIMIT,
		}
	end
	local endT = endRaw
	local sRaw = profile.hitboxStartTime
	local startT = if type(sRaw) == "number" and sRaw == sRaw and sRaw >= 0 and sRaw < math.huge then sRaw else 0
	if startT >= endT then
		startT = 0
	end
	local h = endT
	local minV = profile.comboTimeLimitMin
	local maxV = profile.comboTimeLimitMax
	local minOut = if type(minV) == "number" and isFinitePositive(minV) then minV else h
	local maxOut = if type(maxV) == "number" and isFinitePositive(maxV) then maxV else h
	return {
		hitboxStartTime = startT,
		hitboxEndTime = endT,
		comboTimeLimitMin = minOut,
		comboTimeLimitMax = maxOut,
	}
end

return AnimationAttackTiming
