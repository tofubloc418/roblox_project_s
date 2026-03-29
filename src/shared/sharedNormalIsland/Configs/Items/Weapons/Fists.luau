--!strict
local ItemEnums = require(((script.Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

local Fists = {
	["Fists"] = {
		templateId = "Fists",
		displayName = "Fists",
		description = "Your bare hands.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Fists,
		modelAssetId = "rbxassetid://0",
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
		idleMotionId    = ItemEnums.WeaponTag.Fists .. "_Idle",
		equipMotionId   = ItemEnums.WeaponTag.Fists .. "_Equip",
		unequipMotionId = ItemEnums.WeaponTag.Fists .. "_Unequip",
		attackSequence = {
			{
				attackMotionId = "Fists_Attack_01",
				hitDuration = 12 / 60,
				comboTimeLimit = 30 / 60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Fists_Attack_02",
				hitDuration = 12 / 60,
				comboTimeLimit = 30 / 60,
				movementLocks = { "All" },
			},
		},
		swingSoundId = "rbxassetid://0",
		hitSoundId   = "rbxassetid://0",
		castType = "Spherecast",
		castSize = nil,
		castRadius = 2,

		reach = 6,
	},
}

return Fists
