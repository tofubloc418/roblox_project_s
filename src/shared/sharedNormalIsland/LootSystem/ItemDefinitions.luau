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
	["pistol"] = {
		id = "pistol",
		displayName = "Pistol",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.COMMON,
		ammoType = ItemDefinitions.AmmoTypes.LIGHT,
		weight = 1,
	},
	["smg"] = {
		id = "smg",
		displayName = "SMG",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		ammoType = ItemDefinitions.AmmoTypes.LIGHT,
		weight = 1,
	},
	["assault_rifle"] = {
		id = "assault_rifle",
		displayName = "Assault Rifle",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.RARE,
		ammoType = ItemDefinitions.AmmoTypes.MEDIUM,
		weight = 1,
	},
	["shotgun"] = {
		id = "shotgun",
		displayName = "Shotgun",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		ammoType = ItemDefinitions.AmmoTypes.SHOTGUN,
		weight = 1,
	},
	["mosin"] = {
		id = "mosin",
		displayName = "Mosin Nagant",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.EPIC,
		ammoType = ItemDefinitions.AmmoTypes.SNIPER,
		weight = 1,
	},
	["awp"] = {
		id = "awp",
		displayName = "AWP",
		category = ItemDefinitions.Categories.GUN,
		rarity = ItemDefinitions.Rarities.LEGENDARY,
		ammoType = ItemDefinitions.AmmoTypes.SNIPER,
		weight = 1,
	},
	
	-- Grenades
	["frag_grenade"] = {
		id = "frag_grenade",
		displayName = "Frag Grenade",
		category = ItemDefinitions.Categories.GRENADE,
		rarity = ItemDefinitions.Rarities.COMMON,
		stackMax = 3,
		weight = 1,
	},
	["smoke_grenade"] = {
		id = "smoke_grenade",
		displayName = "Smoke Grenade",
		category = ItemDefinitions.Categories.GRENADE,
		rarity = ItemDefinitions.Rarities.COMMON,
		stackMax = 3,
		weight = 1,
	},
	["flash_grenade"] = {
		id = "flash_grenade",
		displayName = "Flash Grenade",
		category = ItemDefinitions.Categories.GRENADE,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		stackMax = 2,
		weight = 1,
	},
	["molotov"] = {
		id = "molotov",
		displayName = "Molotov",
		category = ItemDefinitions.Categories.GRENADE,
		rarity = ItemDefinitions.Rarities.RARE,
		stackMax = 2,
		weight = 1,
	},
	
	-- Ammo
	["ammo_light"] = {
		id = "ammo_light",
		displayName = "Light Ammo",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.COMMON,
		ammoType = ItemDefinitions.AmmoTypes.LIGHT,
		stackMax = 60,
		weight = 1,
	},
	["ammo_medium"] = {
		id = "ammo_medium",
		displayName = "Medium Ammo",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.COMMON,
		ammoType = ItemDefinitions.AmmoTypes.MEDIUM,
		stackMax = 40,
		weight = 1,
	},
	["ammo_heavy"] = {
		id = "ammo_heavy",
		displayName = "Heavy Ammo",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		ammoType = ItemDefinitions.AmmoTypes.HEAVY,
		stackMax = 30,
		weight = 1,
	},
	["ammo_shotgun"] = {
		id = "ammo_shotgun",
		displayName = "Shotgun Shells",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.COMMON,
		ammoType = ItemDefinitions.AmmoTypes.SHOTGUN,
		stackMax = 20,
		weight = 1,
	},
	["ammo_sniper"] = {
		id = "ammo_sniper",
		displayName = "Sniper Ammo",
		category = ItemDefinitions.Categories.AMMO,
		rarity = ItemDefinitions.Rarities.RARE,
		ammoType = ItemDefinitions.AmmoTypes.SNIPER,
		stackMax = 15,
		weight = 1,
	},
	
	-- Meds
	["bandage"] = {
		id = "bandage",
		displayName = "Bandage",
		category = ItemDefinitions.Categories.MED,
		rarity = ItemDefinitions.Rarities.COMMON,
		stackMax = 10,
		weight = 1,
	},
	["medkit"] = {
		id = "medkit",
		displayName = "Medkit",
		category = ItemDefinitions.Categories.MED,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		stackMax = 2,
		weight = 1,
	},
	["first_aid"] = {
		id = "first_aid",
		displayName = "First Aid Kit",
		category = ItemDefinitions.Categories.MED,
		rarity = ItemDefinitions.Rarities.RARE,
		stackMax = 1,
		weight = 1,
	},
	["shield_potion"] = {
		id = "shield_potion",
		displayName = "Shield Potion",
		category = ItemDefinitions.Categories.MED,
		rarity = ItemDefinitions.Rarities.EPIC,
		stackMax = 2,
		weight = 1,
	},
	
	-- Armor
	["vest_level1"] = {
		id = "vest_level1",
		displayName = "Level 1 Vest",
		category = ItemDefinitions.Categories.ARMOR,
		rarity = ItemDefinitions.Rarities.COMMON,
		weight = 1,
	},
	["vest_level2"] = {
		id = "vest_level2",
		displayName = "Level 2 Vest",
		category = ItemDefinitions.Categories.ARMOR,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
	},
	["vest_level3"] = {
		id = "vest_level3",
		displayName = "Level 3 Vest",
		category = ItemDefinitions.Categories.ARMOR,
		rarity = ItemDefinitions.Rarities.RARE,
		weight = 1,
	},
	["helmet_level1"] = {
		id = "helmet_level1",
		displayName = "Level 1 Helmet",
		category = ItemDefinitions.Categories.ARMOR,
		rarity = ItemDefinitions.Rarities.COMMON,
		weight = 1,
	},
	["helmet_level2"] = {
		id = "helmet_level2",
		displayName = "Level 2 Helmet",
		category = ItemDefinitions.Categories.ARMOR,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		weight = 1,
	},
	["helmet_level3"] = {
		id = "helmet_level3",
		displayName = "Level 3 Helmet",
		category = ItemDefinitions.Categories.ARMOR,
		rarity = ItemDefinitions.Rarities.RARE,
		weight = 1,
	},
	
	-- Attachments
	["scope_2x"] = {
		id = "scope_2x",
		displayName = "2x Scope",
		category = ItemDefinitions.Categories.ATTACHMENT,
		rarity = ItemDefinitions.Rarities.COMMON,
		stackMax = 1,
		weight = 1,
	},
	["scope_4x"] = {
		id = "scope_4x",
		displayName = "4x Scope",
		category = ItemDefinitions.Categories.ATTACHMENT,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		stackMax = 1,
		weight = 1,
	},
	["scope_8x"] = {
		id = "scope_8x",
		displayName = "8x Scope",
		category = ItemDefinitions.Categories.ATTACHMENT,
		rarity = ItemDefinitions.Rarities.RARE,
		stackMax = 1,
		weight = 1,
	},
	["suppressor"] = {
		id = "suppressor",
		displayName = "Suppressor",
		category = ItemDefinitions.Categories.ATTACHMENT,
		rarity = ItemDefinitions.Rarities.EPIC,
		stackMax = 1,
		weight = 1,
	},
	["extended_mag"] = {
		id = "extended_mag",
		displayName = "Extended Magazine",
		category = ItemDefinitions.Categories.ATTACHMENT,
		rarity = ItemDefinitions.Rarities.UNCOMMON,
		stackMax = 1,
		weight = 1,
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
