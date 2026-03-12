--!strict
local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums"))

local Greatswords = {
	["IronGreatsword"] = {
		templateId = "IronGreatsword",
		displayName = "Iron Greatsword",
		description = "A sturdy greatsword forged from iron.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.Greatsword,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Greatsword,
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
			{ animationId = "rbxassetid://0", hitDuration = 0.2 },
			{ animationId = "rbxassetid://0", hitDuration = 0.2 },
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
