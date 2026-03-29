--!strict
local ItemEnums = require(((script.Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

local Katanas = {
	["IronKatana"] = {
		templateId = "IronKatana",
		displayName = "Iron Katana",
		description = "A curved blade balanced for quick cuts and clean footwork.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Katana,
		modelAssetId = "rbxassetid://0",
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 125,
		canDrop = true,
		canTrade = true,
		baseAD = 88,
		baseMD = 0,
		strengthScaling = 0.45,
		dexterityScaling = 1.15,
		intelligenceScaling = 0.0,
		blockPower = 26,
		parryMultiplier = 1.75,
		strengthRequirement = 7,
		dexterityRequirement = 13,
		intelligenceRequirement = 0,

		idleMotionId    = ItemEnums.WeaponTag.Katana .. "_Idle",
		equipMotionId   = ItemEnums.WeaponTag.Katana .. "_Equip",
		unequipMotionId = ItemEnums.WeaponTag.Katana .. "_Unequip",
		attackSequence = {
			{
				attackMotionId = "Katana_Attack_01",
				hitDuration = 24 / 60,
				comboTimeLimit = 52 / 60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Katana_Attack_02",
				hitDuration = 24 / 60,
				comboTimeLimit = 52 / 60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Katana_Attack_03",
				hitDuration = 32 / 60,
				comboTimeLimit = 60 / 60,
				movementLocks = { "All" },
			},
		},
		blockMotionId = ItemEnums.WeaponTag.Katana .. "_Block",

		swingSoundId = "rbxassetid://0",
		hitSoundId = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 11,

		gripC0 = CFrame.new(0, 0, 0),
		gripC1 = CFrame.new(0.1, -1.1, 0) * CFrame.fromOrientation(math.rad(90), math.rad(90), 0),
	},
}

return Katanas
