--!strict
-- TestItems config module for testing the item and data systems
-- These are "dummy" items that require no visual assets or ability scripts to load correctly

local ItemEnums = require(script.Parent:WaitForChild("ItemEnums")) :: any

local TestItems = {
	["TestSword"] = {
		templateId = "TestSword",
		displayName = "Test Sword",
		description = "Used for testing data persistence and equipment logic.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.MeleeWeapon,
		weaponTag = ItemEnums.WeaponTag.Greatsword,
		modelAssetId = "rbxassetid://0",
		rarity = ItemEnums.Rarity.Common,
		iconId = "rbxassetid://0", -- Empty or generic UI icon
		stackMax = 1,
		sellValue = 0,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 10,
		baseMD = 0,
		strengthScaling = 1.0,
		dexterityScaling = 0.5,
		intelligenceScaling = 0.0,
		blockPower = 20,
		parryMultiplier = 1.5,
		strengthRequirement = 10,
		dexterityRequirement = 5,
		intelligenceRequirement = 0,
	},
	
	["TestBandage"] = {
		templateId = "TestBandage",
		displayName = "Test Bandage",
		description = "A stackable consumable for testing inventory stacks.",
		category = ItemEnums.Category.Consumable,
		subcategory = ItemEnums.Subcategory.Healing,
		rarity = ItemEnums.Rarity.Common,
		iconId = "rbxassetid://114493673811902",
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
