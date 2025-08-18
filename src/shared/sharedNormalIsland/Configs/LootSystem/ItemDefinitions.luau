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

-- Ammo types
ItemDefinitions.AmmoTypes = {
	LIGHT = "Light",
	MEDIUM = "Medium",
	HEAVY = "Heavy",
	SHOTGUN = "Shotgun",
	SNIPER = "Sniper",
	ENERGY = "Energy",
}

-- Item database
ItemDefinitions.Items = {
	-- Guns
	["M9"] = {
		id = "M9",
		displayName = "M9",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.COMMON,
		ammoType = ItemDefinitions.AmmoTypes.LIGHT,
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
	local gun = ItemDefinitions.Items[gunId]
	if gun and gun.ammoType then
		-- Find matching ammo item
		for id, item in pairs(ItemDefinitions.Items) do
			if item.category == ItemDefinitions.Categories.AMMO and item.ammoType == gun.ammoType then
				return id
			end
		end
	end
	return nil
end

return ItemDefinitions
