--!strict
-- TestItems config module for testing the item and data systems
-- These are "dummy" items that require no visual assets or ability scripts to load correctly

local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums"))

local TestItems = {
	["TestSword"] = {
		templateId = "TestSword",
		displayName = "Debug Sword",
		description = "Used for testing data persistence and equipment logic.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.Greatsword,
		rarity = ItemEnums.Rarity.Common,
		iconId = "rbxassetid://0", -- Empty or generic UI icon
		weight = 10,
		stackMax = 1,
		sellValue = 0,
		levelReq = 1,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 10,
		baseMD = 0,
		basicAttackType = "Physical",
		strengthScaling = 1.0,
		dexterityScaling = 0.5,
		intelligenceScaling = 0.0,
		blockPower = 20,
		parryMultiplier = 1.2,
		hands = 2,
		attackSpeed = 1.0,
		range = 6,
		staminaCost = 15,
		hitShape = "Box",
		hitSize = Vector3.new(4, 4, 8),
		hitOffset = Vector3.new(0, 0, -4),
		animationSet = "Greatsword",
		attackSequence = {"Attack1"},
		weaponTag = "Greatsword",
		abilityPresetKey = "Greatsword",
		maxAbilitySlots = 3,
		maxUltimateSlots = 1,
		innateAbility = nil,
		maxLevel = 5,
		levelScaling = 0.1,
		modifierPoolId = "MeleeWeaponPool",
		maxModifiers = 2,
	},
	
	["TestBandage"] = {
		templateId = "TestBandage",
		displayName = "Debug Bandage",
		description = "A stackable consumable for testing inventory stacks.",
		category = ItemEnums.Category.Consumable,
		subcategory = ItemEnums.Subcategory.Healing,
		rarity = ItemEnums.Rarity.Common,
		iconId = "rbxassetid://0",
		weight = 1,
		stackMax = 10,
		sellValue = 5,
		canDrop = true,
		canTrade = true,
		-- Consumable specific
		useTime = 2,
		cooldown = 5,
		usableInCombat = true,
	}
}

return TestItems
