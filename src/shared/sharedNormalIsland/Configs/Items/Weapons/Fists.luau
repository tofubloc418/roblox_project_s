--!strict
local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums")) :: any

local Fists = {
	["Fists"] = {
		templateId = "Fists",
		displayName = "Fists",
		description = "Your bare hands.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Fists,
		iconId = "rbxassetid://136844142316980",
		stackMax = 1,
		sellValue = 0,
		canDrop = false,
		canTrade = false,
		
		-- Weapon specific
		baseAD = 2,
		baseMD = 0,
		strengthScaling = 0.5,
		dexterityScaling = 0.0,
		intelligenceScaling = 0.0,
		blockPower = 5,
		parryMultiplier = 1.0,
		strengthRequirement = 0,
		dexterityRequirement = 0,
		intelligenceRequirement = 0,
		
		-- Hitbox and Animation Stats
		idleAnimationId    = "rbxassetid://0",
		equipAnimationId   = "rbxassetid://0",
		unequipAnimationId = "rbxassetid://0",
		attackSequence = {
			{ animationId = "rbxassetid://0", hitDuration = 0.5 },
		},
		blockAnimationId = nil,

		swingSoundId = "rbxassetid://0",
		hitSoundId   = "rbxassetid://0",
		castType = "Spherecast",
		castSize = nil,
		castRadius = 2,

		reach = 6,
	},
}

return Fists
