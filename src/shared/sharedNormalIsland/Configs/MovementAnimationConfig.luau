--!strict
--[[
	Client: locomotion clips (not stance idle) bumped to Movement priority.

	Server: optional HumanoidDescription animation overrides (rbxassetid strings).
	See: https://create.roblox.com/docs/animation/using — keys match HumanoidDescription (WalkAnimation, RunAnimation, …).
]]

-- Fill in only what you want to replace; omit keys or use nil to keep Roblox defaults.
local HumanoidDescriptionOverrides: { [string]: string? } = {
	-- WalkAnimation = "rbxassetid://...",
	-- RunAnimation = "rbxassetid://...",
	-- JumpAnimation = "rbxassetid://...",
	-- FallAnimation = "rbxassetid://...",
	-- ClimbAnimation = "rbxassetid://...",
	-- SwimAnimation = "rbxassetid://...",
	-- IdleAnimation = "rbxassetid://...",
	-- MoodAnimation = "rbxassetid://...",
}

local HD_ANIM_KEYS = {
	"WalkAnimation",
	"RunAnimation",
	"JumpAnimation",
	"FallAnimation",
	"ClimbAnimation",
	"SwimAnimation",
	"IdleAnimation",
	"MoodAnimation",
}

-- Locomotion overrides also get Movement priority on the client (idle/mood excluded).
local LOCOMOTION_PRIORITY_KEYS = {
	"WalkAnimation",
	"RunAnimation",
	"JumpAnimation",
	"FallAnimation",
	"ClimbAnimation",
	"SwimAnimation",
}

-- Stock R15 Animate locomotion defaults
local defaultRobloxCoreAnimateLocomotionIds: { string } = {
	"rbxassetid://507777826", -- walk
	"rbxassetid://507767714", -- run
	"rbxassetid://507784897", -- swim
	"rbxassetid://507785072", -- swimidle
	"rbxassetid://507765000", -- jump
	"rbxassetid://507767968", -- fall
	"rbxassetid://507765644", -- climb
	"rbxassetid://2506281703", -- sit
}

local function parseAssetIdNumber(assetId: string?): number?
	if not assetId or assetId == "" then
		return nil
	end
	local m = string.match(assetId, "rbxassetid://(%d+)")
	if m then
		return tonumber(m)
	end
	m = string.match(assetId, "id=(%d+)")
	if m then
		return tonumber(m)
	end
	m = string.match(assetId, "^(%d+)$")
	return m and tonumber(m) or tonumber(assetId)
end

local locomotionIdSet: { [number]: boolean } = {}
for _, s in ipairs(defaultRobloxCoreAnimateLocomotionIds) do
	local num = parseAssetIdNumber(s)
	if num then
		locomotionIdSet[num] = true
	end
end
for _, key in ipairs(LOCOMOTION_PRIORITY_KEYS) do
	local raw = HumanoidDescriptionOverrides[key]
	local num = parseAssetIdNumber(raw)
	if num then
		locomotionIdSet[num] = true
	end
end

local MovementAnimationConfig = {
	HumanoidDescriptionOverrides = HumanoidDescriptionOverrides,
	LocomotionIdSet = locomotionIdSet,
}

function MovementAnimationConfig.ParseAssetIdNumber(assetId: string?): number?
	return parseAssetIdNumber(assetId)
end

function MovementAnimationConfig.ApplyHumanoidDescriptionOverrides(description: HumanoidDescription)
	local anyDc = description :: any
	for _, key in ipairs(HD_ANIM_KEYS) do
		local raw = HumanoidDescriptionOverrides[key]
		local num = parseAssetIdNumber(raw)
		if num then
			anyDc[key] = num
		end
	end
end

return MovementAnimationConfig
