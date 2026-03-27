--!strict
local ItemEnums = require(((script.Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

local Greatswords = {
	["IronGreatsword"] = {
		templateId = "IronGreatsword",
		displayName = "Iron Greatsword",
		description = "A sturdy greatsword forged from iron.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Greatsword,
		modelAssetId = "rbxassetid://0",
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 150,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 120,
		baseMD = 0,
		strengthScaling = 1.2,
		dexterityScaling = 0.3,
		intelligenceScaling = 0.0,
		blockPower = 40,
		parryMultiplier = 1.5,
		strengthRequirement = 12,
		dexterityRequirement = 8,
		intelligenceRequirement = 0,
		
		-- Hitbox and Animation Stats
		idleAnimationId    = "rbxassetid://0",
		equipAnimationId   = "rbxassetid://0",
		unequipAnimationId = "rbxassetid://0",
		attackSequence = {
			{ attackMotionId = "Greatsword_Attack_01", hitDuration = 0.2 },
			{ attackMotionId = "Greatsword_Attack_02", hitDuration = 0.2 },
		},
		blockAnimationId = "rbxassetid://0",

		swingSoundId = "rbxassetid://0",
		hitSoundId   = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 0,
	},
}

return Greatswords
