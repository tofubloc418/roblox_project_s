--!strict
-- In-memory rbxassetid → clip length (seconds). Filled by probe, client tracks, etc.

local AnimationClipLengthCache = {}

local cache: { [string]: number } = {}

function AnimationClipLengthCache.get(animationAssetId: string): number?
	if type(animationAssetId) ~= "string" or animationAssetId == "" or animationAssetId == "rbxassetid://0" then
		return nil
	end
	return cache[animationAssetId]
end

function AnimationClipLengthCache.set(animationAssetId: string, lengthSeconds: number): ()
	if type(animationAssetId) ~= "string" or animationAssetId == "" or animationAssetId == "rbxassetid://0" then
		return
	end
	if type(lengthSeconds) ~= "number" or lengthSeconds ~= lengthSeconds or lengthSeconds <= 0 or lengthSeconds >= math.huge then
		return
	end
	cache[animationAssetId] = lengthSeconds
end

function AnimationClipLengthCache.probeAndCache(animator: Animator, animationAssetId: string): number?
	if type(animationAssetId) ~= "string" or animationAssetId == "" or animationAssetId == "rbxassetid://0" then
		return nil
	end
	local existing = cache[animationAssetId]
	if existing then
		return existing
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animationAssetId

	local track: AnimationTrack?
	local ok, result = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and typeof(result) == "Instance" and (result :: Instance):IsA("AnimationTrack") then
		track = result :: AnimationTrack
	end
	anim:Destroy()

	if not track then
		warn("[AnimationClipLengthCache] LoadAnimation failed for " .. animationAssetId)
		return nil
	end

	local len = track.Length
	track:Stop()
	track:Destroy()

	if type(len) ~= "number" or len ~= len or len <= 0 or len >= math.huge then
		warn(
			("[AnimationClipLengthCache] %s: invalid AnimationTrack.Length (%s); try PreloadAsync."):format(animationAssetId, tostring(len))
		)
		return nil
	end

	cache[animationAssetId] = len
	return len
end

return AnimationClipLengthCache
