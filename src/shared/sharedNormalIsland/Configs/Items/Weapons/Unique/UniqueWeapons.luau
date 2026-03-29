--!strict
local ItemEnums = require((((script.Parent :: any).Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

local UNIQUE_WUKONG_TAG = "Unique_WukongsJingubang"

local UniqueWeapons = {
	["WukongsJingubang"] = {
		templateId = "WukongsJingubang",
		displayName = "Wukong's Jingubang",
		description = "A legendary quarterstaff that answers only to its wielder.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.UniqueWeapon,
		rarity = ItemEnums.Rarity.Legendary,
		weaponTag = UNIQUE_WUKONG_TAG,
		abilityPresetKey = UNIQUE_WUKONG_TAG,
		modelAssetId = "rbxassetid://0",
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 0,
		canDrop = false,
		canTrade = false,
		baseAD = 150,
		baseMD = 0,
		strengthScaling = 1.0,
		dexterityScaling = 1.0,
		intelligenceScaling = 0.0,
		blockPower = 38,
		parryMultiplier = 1.6,
		strengthRequirement = 12,
		dexterityRequirement = 12,
		intelligenceRequirement = 0,

		idleMotionId    = UNIQUE_WUKONG_TAG .. "_Idle",
		equipMotionId   = UNIQUE_WUKONG_TAG .. "_Equip",
		unequipMotionId = UNIQUE_WUKONG_TAG .. "_Unequip",
		attackSequence = {
			{
				attackMotionId = "Quarterstaff_Attack_01",
				hitDuration = 22 / 60,
				comboTimeLimit = 48 / 60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Quarterstaff_Attack_02",
				hitDuration = 24 / 60,
				comboTimeLimit = 52 / 60,
				movementLocks = { "All" },
			},
		},
		blockMotionId = UNIQUE_WUKONG_TAG .. "_Block",

		swingSoundId = "rbxassetid://0",
		hitSoundId = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 13,

		gripC0 = CFrame.new(0, 0, 0),
		gripC1 = CFrame.new(0, -1.8, 0) * CFrame.fromOrientation(math.rad(90), 0, 0),
	},
}

return UniqueWeapons
