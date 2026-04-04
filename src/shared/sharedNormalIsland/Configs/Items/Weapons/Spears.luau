--!strict
local ItemEnums = require(((script.Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

local Spears = {
	["IronSpear"] = {
		templateId = "IronSpear",
		displayName = "Iron Spear",
		description = "A simple iron spear — long reach and reliable thrusts.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Spear,
		modelAssetId = "rbxassetid://0",
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 95,
		canDrop = true,
		canTrade = true,
		baseAD = 72,
		baseMD = 0,
		strengthScaling = 0.85,
		dexterityScaling = 0.55,
		intelligenceScaling = 0.0,
		blockPower = 20,
		parryMultiplier = 1.4,
		strengthRequirement = 10,
		dexterityRequirement = 9,
		intelligenceRequirement = 0,

		idleMotionId    = ItemEnums.WeaponTag.Spear .. "_Idle",
		equipMotionId   = ItemEnums.WeaponTag.Spear .. "_Equip",
		unequipMotionId = ItemEnums.WeaponTag.Spear .. "_Unequip",
		attackSequence = {
			{ attackMotionId = "Spear_Attack_01" },
			{ attackMotionId = "Spear_Attack_02" },
		},
		blockMotionId = ItemEnums.WeaponTag.Spear .. "_Block",

		swingSoundId = "rbxassetid://0",
		hitSoundId = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 16,

		gripC0 = CFrame.new(0, 0, 0),
		gripC1 = CFrame.new(0, -2.2, 0) * CFrame.fromOrientation(math.rad(90), 0, 0),
	},
}

return Spears
