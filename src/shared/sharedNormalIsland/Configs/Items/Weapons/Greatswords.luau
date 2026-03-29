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
		modelAssetId = "rbxassetid://81113787250917",
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
		idleMotionId    = ItemEnums.WeaponTag.Greatsword .. "_Idle",
		equipMotionId   = ItemEnums.WeaponTag.Greatsword .. "_Equip",
		unequipMotionId = ItemEnums.WeaponTag.Greatsword .. "_Unequip",
		attackSequence = {
			{
				attackMotionId = "Greatsword_Attack_01",
				hitDuration = 30/60,
				comboTimeLimit = 60/60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Greatsword_Attack_02",
				hitDuration = 30/60,
				comboTimeLimit = 60/60,
				movementLocks = { "All" },
			},
			{
				attackMotionId = "Greatsword_Attack_03",
				hitDuration = 30/60,
				comboTimeLimit = 60/60,
				movementLocks = { "All" },
			},
		},
		blockMotionId = ItemEnums.WeaponTag.Greatsword .. "_Block",

		swingSoundId = "rbxassetid://0",
		hitSoundId   = "rbxassetid://0",
		-- Blockcast from each DmgPoint; box is centered on the attachment. Replace castSize when blade dims are final.
		castType = "Blockcast",
		castSize = Vector3.new(1, 4.576, 0.356),
		castRadius = nil,

		reach = 14,

		-- RightGrip C1 from Studio (Handle space): Position + Orientation (deg).
		gripC0 = CFrame.new(0, 0, 0),
		gripC1 = CFrame.new(-0.058, -2.378, 0) * CFrame.fromOrientation(math.rad(90), math.rad(-90), 0),
	},
}

return Greatswords
