--!strict
local ItemEnums = require(script.Parent.Parent:WaitForChild("ItemEnums"))

local Greatswords = {
	["IronGreatsword"] = {
		templateId = "IronGreatsword",
		displayName = "Iron Greatsword",
		description = "A sturdy greatsword forged from iron.",
		category = ItemEnums.Category.Weapon,
		subcategory = ItemEnums.Subcategory.Greatsword,
		rarity = ItemEnums.Rarity.Common,
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
		weaponTag = ItemEnums.WeaponTag.Greatsword,
	},
}

return Greatswords
