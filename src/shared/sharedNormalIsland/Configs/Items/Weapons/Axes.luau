--!strict
local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums")) :: any

local Axes = {
	["IronAxe"] = {
		templateId = "IronAxe",
		displayName = "Iron Axe",
		description = "A one-handed iron axe with a heavy cleaving swing.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Axe,
		modelAssetId = "rbxassetid://115321453925433",
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 80,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 14,
		baseMD = 0,
		strengthScaling = 1.1,
		dexterityScaling = 0.4,
		intelligenceScaling = 0.0,
		blockPower = 18,
		parryMultiplier = 1.6,
		strengthRequirement = 8,
		dexterityRequirement = 6,
		intelligenceRequirement = 0,

		-- Hitbox and Animation Stats
		idleAnimationId = "rbxassetid://112151615655157",
		equipAnimationId = "rbxassetid://79058443592728",
		unequipAnimationId = "rbxassetid://83081513554352",
		attackSequence = {
			{ animationId = "rbxassetid://107791038673413", hitDuration = 28 / 60, comboTimeLimit = 43 / 60 },
			{ animationId = "rbxassetid://75612209059589", hitDuration = 28 / 60, comboTimeLimit = 43 / 60 },
			{ animationId = "rbxassetid://82850857726878", hitDuration = 45 / 60, comboTimeLimit = 60 / 60 },
		},
		blockAnimationId = "rbxassetid://0",

		swingSoundId = "rbxassetid://0",
		hitSoundId = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 9,

		gripC0 = CFrame.new(0, 0, 0),
		gripC1 = CFrame.new(0.5, -1, 0) * CFrame.fromOrientation(math.rad(90), math.rad(90), 0),
	},
}

return Axes
