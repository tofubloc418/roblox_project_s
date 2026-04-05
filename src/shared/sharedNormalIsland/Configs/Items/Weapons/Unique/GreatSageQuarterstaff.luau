--!strict
local ItemEnums = require((((script.Parent :: any).Parent :: any).Parent :: any):WaitForChild("ItemEnums")) :: any

local UNIQUE_GREAT_SAGE_QUARTERSTAFF_TAG = "Unique_GreatSageQuarterstaff"

local GreatSageQuarterstaff = {
	["GreatSageQuarterstaff"] = {
		templateId = "GreatSageQuarterstaff",
		displayName = "Great Sage Quarterstaff",
		description = "A legendary quarterstaff worthy of the Great Sage.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.UniqueWeapon,
		rarity = ItemEnums.Rarity.Legendary,
		weaponTag = UNIQUE_GREAT_SAGE_QUARTERSTAFF_TAG,
		abilityPresetKey = UNIQUE_GREAT_SAGE_QUARTERSTAFF_TAG,
		modelAssetId = "rbxassetid://118680361917241",
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

		idleMotionId    = UNIQUE_GREAT_SAGE_QUARTERSTAFF_TAG .. "_Idle",
		equipMotionId   = UNIQUE_GREAT_SAGE_QUARTERSTAFF_TAG .. "_Equip",
		unequipMotionId = UNIQUE_GREAT_SAGE_QUARTERSTAFF_TAG .. "_Unequip",
		attackSequence = {
			{
				attackMotionId = "GreatSageQuarterstaff_Attack_01",
				movementLocks = { "All" },
			},
			{
				attackMotionId = "GreatSageQuarterstaff_Attack_02",
				movementLocks = { "All" },
			},
			{
				attackMotionId = "GreatSageQuarterstaff_Attack_03",
				movementLocks = { "All" },
			},
		},
		blockMotionId = UNIQUE_GREAT_SAGE_QUARTERSTAFF_TAG .. "_Block",

		swingSoundId = "rbxassetid://0",
		hitSoundId = "rbxassetid://0",
		castType = "Raycast",
		castSize = nil,
		castRadius = nil,

		reach = 13,

		gripC0 = CFrame.new(0, 0, 0),
		gripC1 = CFrame.new(-0.154, 0, 0) * CFrame.fromOrientation(math.rad(45), math.rad(-90), math.rad(-90)),
	},
}

return GreatSageQuarterstaff
