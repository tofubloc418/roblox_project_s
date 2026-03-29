--!strict
local ItemEnums = require(((script.Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

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
		idleMotionId = ItemEnums.WeaponTag.Axe .. "_Idle",
		equipMotionId = ItemEnums.WeaponTag.Axe .. "_Equip",
		unequipMotionId = ItemEnums.WeaponTag.Axe .. "_Unequip",
		attackSequence = {
			{
				attackMotionId = "Axe_Attack_01",
				hitDuration = 28 / 60,
				comboTimeLimit = 43 / 60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Axe_Attack_02",
				hitDuration = 28 / 60,
				comboTimeLimit = 43 / 60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Axe_Attack_03",
				hitDuration = 45 / 60,
				comboTimeLimit = 60 / 60,
				movementLocks = { "All" },
			},
		},
		blockMotionId = ItemEnums.WeaponTag.Axe .. "_Block",

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
