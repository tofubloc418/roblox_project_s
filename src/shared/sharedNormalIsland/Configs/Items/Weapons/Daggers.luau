--!strict
local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums"))

local Daggers = {
	["Knife"] = {
		templateId = "Knife",
		displayName = "Knife",
		description = "A simple swift blade for close-quarters combat.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.Dagger,
		rarity = ItemEnums.Rarity.Common,
		weaponTag = ItemEnums.WeaponTag.Dagger,
		iconId = "rbxassetid://0",
		stackMax = 1,
		sellValue = 50,
		canDrop = true,
		canTrade = true,
		-- Weapon specific
		baseAD = 5,
		baseMD = 0,
		strengthScaling = 0.2,
		dexterityScaling = 1.3,
		intelligenceScaling = 0.0,
		blockPower = 10,
		parryMultiplier = 2.0,
		strengthRequirement = 4,
		dexterityRequirement = 10,
		intelligenceRequirement = 0,
	},
}

return Daggers
