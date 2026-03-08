--!strict
local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums"))

local Daggers = {
	["IronDagger"] = {
		templateId = "IronDagger",
		displayName = "Iron Dagger",
		description = "A simple swift blade for close-quarters combat.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.Dagger,
		rarity = ItemEnums.Rarity.Common,
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 50,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 40,
		baseMD = 0,
		strengthScaling = 0.2,
		dexterityScaling = 1.3,
		intelligenceScaling = 0.0,
		blockPower = 10,
		parryMultiplier = 2.0,
		strengthRequirement = 4,
		dexterityRequirement = 10,
		intelligenceRequirement = 0,
		weaponTag = ItemEnums.WeaponTag.Dagger,
	},
}

return Daggers
