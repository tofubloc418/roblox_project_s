--!strict
-- Basic-attack timing: default is absolute hitDuration / comboTimeLimit (seconds, often X/60 for animation frames).
-- Optional: timingDerivedFromAnimationClip + known clip length → hit = clip×0.75, combo = clip×1.25 (absolute seconds).
-- Clip length needs AnimationTrack.Length or AnimationClipLengthCache (not available from rbxassetid alone in config).

export type BasicAttackTimingProfile = {
	hitDuration: number,
	comboTimeLimit: number?,
	timingDerivedFromAnimationClip: boolean?,
}

export type ResolvedBasicAttackTimings = {
	hitDuration: number,
	comboTimeLimit: number,
}

export type ClipLengthSources = {
	trackLength: number?,
	cachedLength: number?,
}

local AnimationAttackTiming = {}

AnimationAttackTiming.AUTO_HIT_FRACTION_OF_CLIP = 0.75
AnimationAttackTiming.AUTO_COMBO_FRACTION_OF_CLIP = 1.25

local warnedAutoWithoutClip: { [string]: boolean } = {}

local function isFinitePositive(n: number): boolean
	return n == n and n > 0 and n < math.huge
end

function AnimationAttackTiming.tryGetClipLengthSecondsFromTrack(track: AnimationTrack?): number?
	if not track then
		return nil
	end
	local len = track.Length
	if type(len) ~= "number" or not isFinitePositive(len) then
		return nil
	end
	return len
end

function AnimationAttackTiming.resolveClipLengthSeconds(sources: ClipLengthSources): number?
	for _, v in ipairs({ sources.trackLength, sources.cachedLength }) do
		if type(v) == "number" and isFinitePositive(v) then
			return v
		end
	end
	return nil
end

function AnimationAttackTiming.resolveBasicAttackTimings(
	profile: BasicAttackTimingProfile,
	clipLengthSeconds: number?,
	debugLabel: string?
): ResolvedBasicAttackTimings
	local useClip = profile.timingDerivedFromAnimationClip == true
	local clip = clipLengthSeconds
	local validClip = clip ~= nil and isFinitePositive(clip :: number)
	local label = if debugLabel and debugLabel ~= "" then debugLabel else "(attack profile)"

	if useClip and validClip then
		local c = clip :: number
		return {
			hitDuration = c * AnimationAttackTiming.AUTO_HIT_FRACTION_OF_CLIP,
			comboTimeLimit = c * AnimationAttackTiming.AUTO_COMBO_FRACTION_OF_CLIP,
		}
	end

	if useClip and not validClip then
		if not warnedAutoWithoutClip[label] then
			warnedAutoWithoutClip[label] = true
			warn(("[AnimationAttackTiming] %s: timingDerivedFromAnimationClip but no clip length; using hitDuration/comboTimeLimit."):format(label))
		end
	end

	local h = profile.hitDuration
	local c = profile.comboTimeLimit
	if type(c) == "number" and isFinitePositive(c) then
		return { hitDuration = h, comboTimeLimit = c }
	end
	return { hitDuration = h, comboTimeLimit = h }
end

return AnimationAttackTiming
