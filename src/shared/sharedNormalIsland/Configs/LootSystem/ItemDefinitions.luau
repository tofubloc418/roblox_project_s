--[[
	ItemDefinitions
	Canonical list of all items in the game with their properties
]]

local ItemDefinitions = {}

-- Item categories
ItemDefinitions.Categories = {
	GUN = "Gun",
	GRENADE = "Grenade",
	AMMO = "Ammo",
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
	-- Guns
	["M9"] = {
		id = "M9",
		displayName = "M9",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.COMMON,
		weight = 1,
		stackMax = 1,
	},
	["AK47"] = {
		id = "AK47",
		displayName = "AK47",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
		stackMax = 1,
	},

    -- Ammo
	["9mm"] = {
		id = "9mm",
		displayName = "9mm",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.COMMON,
		weight = 1,
		stackMax = 60,
	},
	["5.56mm"] = {
		id = "5.56mm",
		displayName = "5.56mm",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
		stackMax = 60,
	},
	["7.62mm"] = {
		id = "7.62mm",
		displayName = "7.62mm",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
		stackMax = 60,
	},
	["12 Gauge"] = {
		id = "12 Gauge",
		displayName = "12 Gauge",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
		stackMax = 30,
	},
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
