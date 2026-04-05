--!strict
-- rbxassetid → clip length (seconds). Length is often 0 until the asset streams; use PreloadAsync + short wait.

local ContentProvider = game:GetService("ContentProvider")

local AnimationClipLengthCache = {}

local cache: { [string]: number } = {}

local LENGTH_POLL_STEP = 0.05
local LENGTH_POLL_MAX_SEC = 5

local function isValidLength(len: number): boolean
	return type(len) == "number" and len == len and len > 0 and len < math.huge
end

local function waitForTrackLength(track: AnimationTrack): number?
	local deadline = os.clock() + LENGTH_POLL_MAX_SEC
	while os.clock() < deadline do
		local len = track.Length
		if isValidLength(len) then
			return len
		end
		task.wait(LENGTH_POLL_STEP)
	end
	return nil
end

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

	pcall(function()
		ContentProvider:PreloadAsync({ anim })
	end)

	local ok, result = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()

	if not ok or typeof(result) ~= "Instance" or not (result :: Instance):IsA("AnimationTrack") then
		warn("[AnimationClipLengthCache] LoadAnimation failed for " .. animationAssetId)
		return nil
	end

	local track = result :: AnimationTrack

	local len = track.Length
	if not isValidLength(len) then
		local polled = waitForTrackLength(track)
		if polled ~= nil then
			len = polled
		end
	end

	track:Stop()
	track:Destroy()

	if not isValidLength(len) then
		warn(
			("[AnimationClipLengthCache] %s: AnimationTrack.Length stayed invalid after PreloadAsync and %.1fs wait."):format(
				animationAssetId,
				LENGTH_POLL_MAX_SEC
			)
		)
		return nil
	end

	cache[animationAssetId] = len
	return len
end

return AnimationClipLengthCache
