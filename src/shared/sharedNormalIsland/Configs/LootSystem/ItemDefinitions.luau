--[[
	ItemDefinitions
	Canonical list of all items in the game with their properties
]]

local ItemDefinitions = {}

-- Item categories
ItemDefinitions.Categories = {
	GRENADE = "Grenade",
	MED = "Med",
	ARMOR = "Armor",
	ATTACHMENT = "Attachment",
	MELEE = "Melee",
}

-- Rarity tiers
ItemDefinitions.Rarities = {
	COMMON = "Common",
	UNCOMMON = "Uncommon",
	RARE = "Rare",
	EPIC = "Epic",
	LEGENDARY = "Legendary",
}

-- Item database
ItemDefinitions.Items = {
	["Bandage"] = {
		id = "Bandage",
		displayName = "Bandage",
		category = ItemDefinitions.Categories.MED,
		rarity = ItemDefinitions.Rarities.COMMON,
		weight = 1,
		stackMax = 15,
	},
	["Medkit"] = {
		id = "Medkit",
		displayName = "Medkit",
		category = ItemDefinitions.Categories.MED,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
		stackMax = 2,
	},
	["Pill"] = {
		id = "Pill",
		displayName = "Pill",
		category = ItemDefinitions.Categories.MED,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
		stackMax = 3,
	},
}

-- Helper function to get item by ID
function ItemDefinitions.GetItem(itemId: string)
	return ItemDefinitions.Items[itemId]
end

return ItemDefinitions
