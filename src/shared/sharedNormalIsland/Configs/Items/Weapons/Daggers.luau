--!strict
local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums")) :: any

local Daggers = {
	["Knife"] = {
		templateId = "Knife",
		displayName = "Knife",
		description = "A simple swift blade for close-quarters combat.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.Dagger,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Dagger,
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 50,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 5,
		baseMD = 0,
		strengthScaling = 0.2,
		dexterityScaling = 1.3,
		intelligenceScaling = 0.0,
		blockPower = 10,
		parryMultiplier = 2.0,
		strengthRequirement = 4,
		dexterityRequirement = 10,
		intelligenceRequirement = 0,

		-- Hitbox and Animation Stats
		idleAnimationId    = "rbxassetid://0",
		equipAnimationId   = "rbxassetid://0",
		unequipAnimationId = "rbxassetid://0",
		attackSequence = {
			{ animationId = "rbxassetid://120794561550510", hitDuration = 0.5, comboTimeLimit = 1 },
			{ animationId = "rbxassetid://96019133363181", hitDuration = 1, comboTimeLimit = 3 },
		},
		blockAnimationId = "rbxassetid://0",

		swingSoundId = "rbxassetid://0",
		hitSoundId   = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 8,

		-- C0/C1 Offset Method (WeaponRigging): Position (studs) + Orientation copied from Studio.
		-- Use fromOrientation here because Studio's orientation fields do not match CFrame.Angles rotation order.
		gripC0 = CFrame.new(0, 0, 0), -- offset from RightHand (palm)
		gripC1 = CFrame.new(0, -1.18, 0.065) * CFrame.fromOrientation(math.rad(84.646), math.rad(-92.516), math.rad(-92.505)),
	},
}

return Daggers
