--!strict
local ItemEnums = require(((script.Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

local ThrustingSwords = {
	["Rapier"] = {
		templateId = "Rapier",
		displayName = "Rapier",
		description = "A swift thrusting sword that excels at parrying and quick strikes.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.ThrustingSword,
		modelAssetId = "rbxassetid://0",
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 120,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 80,
		baseMD = 0,
		strengthScaling = 0.4,
		dexterityScaling = 1.1,
		intelligenceScaling = 0.0,
		blockPower = 25,
		parryMultiplier = 2.0,
		strengthRequirement = 6,
		dexterityRequirement = 12,
		intelligenceRequirement = 0,

		-- Hitbox and Animation Stats
		idleMotionId    = ItemEnums.WeaponTag.ThrustingSword .. "_Idle",
		equipMotionId   = ItemEnums.WeaponTag.ThrustingSword .. "_Equip",
		unequipMotionId = ItemEnums.WeaponTag.ThrustingSword .. "_Unequip",
		attackSequence = {
			{ attackMotionId = "ThrustingSword_Attack_01", hitDuration = 0.2 },
			{ attackMotionId = "ThrustingSword_Attack_02", hitDuration = 0.2 },
		},
		blockMotionId = ItemEnums.WeaponTag.ThrustingSword .. "_Block",

		swingSoundId = "rbxassetid://0",
		hitSoundId   = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 0,
	},
	["Lance"] = {
		templateId = "Lance",
		displayName = "Lance",
		description = "A long thrusting blade built for reach and running strikes.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.ThrustingSword,
		modelAssetId = "rbxassetid://0",
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 140,
		canDrop = true,
		canTrade = true,
		baseAD = 92,
		baseMD = 0,
		strengthScaling = 0.55,
		dexterityScaling = 0.95,
		intelligenceScaling = 0.0,
		blockPower = 22,
		parryMultiplier = 1.85,
		strengthRequirement = 9,
		dexterityRequirement = 11,
		intelligenceRequirement = 0,

		idleMotionId    = ItemEnums.WeaponTag.ThrustingSword .. "_Idle",
		equipMotionId   = ItemEnums.WeaponTag.ThrustingSword .. "_Equip",
		unequipMotionId = ItemEnums.WeaponTag.ThrustingSword .. "_Unequip",
		attackSequence = {
			{ attackMotionId = "ThrustingSword_Attack_01", hitDuration = 0.22 },
			{ attackMotionId = "ThrustingSword_Attack_02", hitDuration = 0.22 },
		},
		blockMotionId = ItemEnums.WeaponTag.ThrustingSword .. "_Block",

		swingSoundId = "rbxassetid://0",
		hitSoundId   = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 0,
	},
}

return ThrustingSwords
