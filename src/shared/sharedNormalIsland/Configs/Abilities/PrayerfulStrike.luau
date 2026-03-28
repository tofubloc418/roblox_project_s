--!strict
-- Registry row: metadata, params, asset nameIDs (keys must match ability scripts).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemEnums = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemEnums")) :: any

local FRAMES_AT_60 = 220
local TOTAL_DURATION_SECONDS = FRAMES_AT_60 / 60
-- Used for surge client VFX condense and for RootMotion lunge delay after the Powerup marker.
local SURGE_CONDENSE_DURATION_SECONDS = 39 / 60

local PrayerfulStrike = {
	{
		abilityId = "PrayerfulStrike",
		iconId = "rbxassetid://0",
		displayName = "Prayerful Strike",
		description = "Channel power through your axe, then release it in a single heavy chop.",
		isUltimate = false,
		compatibleTags = { ItemEnums.WeaponTag.Axe },
		damageScaling = { adScaling = 1.5, mdScaling = 0.5 },
		params = {
			totalDurationSeconds = TOTAL_DURATION_SECONDS,
			cooldownSeconds = 5,
			surgeMaxScale = 10,
			surgeMinScale = 1,
			surgeCondenseDurationSeconds = SURGE_CONDENSE_DURATION_SECONDS,
			-- Must match Animation Editor marker names on the ability animation.
			markerPowerup = "Powerup",
			markerImpact = "Impact",
			-- RootMotion: phase1 anim start→Powerup; delay then phase2 (lunge start→Impact). Flat HRP look.
			rootMotionPhase1ForwardStuds = 0.55,
			rootMotionPhase1DurationSeconds = 1.0,
			rootMotionLungeDelayAfterPowerupSeconds = SURGE_CONDENSE_DURATION_SECONDS,
			rootMotionPhase2ForwardStuds = 5,
			rootMotionPhase2DurationSeconds = 0.5,
			-- Magic circle VFX at Powerup (MiddleFeetAttachment): local Y offset, studs; total lifetime.
			magicCircleOffsetY = -0.2,
			magicCircleLifetimeSeconds = 60 / 60,
			-- Model:ScaleTo range over lifetime (linear). Ignored if the clone is not a Model.
			magicCircleScaleMin = 0.5,
			magicCircleScaleMax = 0.75,
			-- Opacity timeline within lifetime: fast fade in, brief fully opaque, slower fade out (remainder).
			magicCircleFadeInSeconds = 0.1,
			magicCircleOpaqueHoldSeconds = 0.5,
			-- Magic circle look (client applies to parts, faces, particles/beams/trails, point light).
			magicCircleGlowColor = Color3.fromRGB(255, 244, 200),
			magicCirclePartMaterial = Enum.Material.Neon,
			magicCirclePointLightBrightness = 10,
			magicCirclePointLightRange = 6,
		},
		assets = {
			Animation = "rbxassetid://81398758260246",
			VfxPrayerSurge = "PrayerSurge",
			VfxMagicCircle = "MagicCircle",
			VfxMediumImpact = "MediumImpact",
			SfxPowerup = "PowerupWhoosh",
			SfxMagicCircle = "",
			SfxImpact = "Impact1",
		},
	},
}

return PrayerfulStrike
