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
		stackMax = 3,
	},
}

-- Helper function to get item by ID
function ItemDefinitions.GetItem(itemId: string)
	return ItemDefinitions.Items[itemId]
end

-- Helper function to get ammo type for a gun
function ItemDefinitions.GetAmmoForGun(gunId: string)
	-- Deprecated. Retrieve from GunConfigs if needed.
	return nil
end

return ItemDefinitions
