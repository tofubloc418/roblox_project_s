--!strict
-- ItemEnums
-- Centralised string constants for item categories, subcategories, rarities, weapon tags,
-- and equipment slots. Import this wherever you need to refer to these values by name
-- instead of raw strings, so typos are caught at require-time rather than at runtime.
--
-- HOW TO ADD A NEW WEAPON TAG:
--   Add a key to ItemEnums.WeaponTag. Unique weapon tags ("Unique_Moonveil", etc.) are
--   dynamic and need not be listed here; they are derived automatically from templateId.
--
-- HOW TO ADD A NEW SUBCATEGORY:
--   Add a key to ItemEnums.Subcategory (weapon buckets or consumable types, etc.).

local ItemEnums = {}

-- ── Categories ───────────────────────────────────────────────────────────────
-- Top-level item type; determines which equipment slot (if any) an item occupies.
ItemEnums.Category = {
	Weapon     = "Weapon",
	Armor      = "Armor",
	Backpack   = "Backpack",
	Accessory  = "Accessory",
	Consumable = "Consumable",
	Material   = "Material",
	Currency   = "Currency",
	KeyItem    = "KeyItem",
}

-- ── Subcategories ─────────────────────────────────────────────────────────────
-- Second-level classification within a category.
ItemEnums.Subcategory = {
	-- Weapons (broad buckets; weaponTag names the specific weapon type for abilities / assets)
	MeleeWeapon  = "MeleeWeapon",
	MagicWeapon  = "MagicWeapon",
	UniqueWeapon = "UniqueWeapon",
	-- Consumables
	Healing       = "Healing",
	Buff          = "Buff",
	Throwable     = "Throwable",
	Food          = "Food",
}

-- ── Rarities ─────────────────────────────────────────────────────────────────
ItemEnums.Rarity = {
	Common    = "Common",
	Uncommon  = "Uncommon",
	Rare      = "Rare",
	Epic      = "Epic",
	Legendary = "Legendary",
}

-- ── Equipment Slots ───────────────────────────────────────────────────────────
-- The four fixed loadout slots a player can occupy at any time.
ItemEnums.EquipmentSlot = {
	Backpack = "Backpack",
	Armor    = "Armor",
	Weapon1  = "Weapon1",
	Weapon2  = "Weapon2",
}

-- ── Weapon Tags ───────────────────────────────────────────────────────────────
-- Each weapon template has exactly ONE weaponTag that abilities use for compatibility
-- and for ReplicatedStorage.Items.Weapons/<weaponTag>/<templateId> asset layout.
-- Unique weapon tags are derived as "Unique_<templateId>" and need not be listed here.
ItemEnums.WeaponTag = {
	Dagger        = "Dagger",
	StraightSword = "StraightSword",
	Greatsword    = "Greatsword",
	CurvedSword   = "CurvedSword",
	Axe           = "Axe",
	Greataxe      = "Greataxe",
	Hammer        = "Hammer",
	GreatHammer   = "GreatHammer",
	Spear         = "Spear",
	Halberd       = "Halberd",
	Fists         = "Fists",
	Whip          = "Whip",
	Staff         = "Staff",
	Seal          = "Seal",
	Bow           = "Bow",
	Crossbow      = "Crossbow",
	ThrustingSword = "ThrustingSword",
	Quarterstaff  = "Quarterstaff",
}

-- ── Weapon Tag Display Names ──────────────────────────────────────────────────
ItemEnums.WeaponTagDisplayName = {
	[ItemEnums.WeaponTag.Dagger]        = "Dagger",
	[ItemEnums.WeaponTag.StraightSword] = "Straight Sword",
	[ItemEnums.WeaponTag.Greatsword]    = "Greatsword",
	[ItemEnums.WeaponTag.CurvedSword]   = "Curved Sword",
	[ItemEnums.WeaponTag.Axe]           = "Axe",
	[ItemEnums.WeaponTag.Greataxe]      = "Greataxe",
	[ItemEnums.WeaponTag.Hammer]        = "Hammer",
	[ItemEnums.WeaponTag.GreatHammer]   = "Great Hammer",
	[ItemEnums.WeaponTag.Spear]         = "Spear",
	[ItemEnums.WeaponTag.Halberd]       = "Halberd",
	[ItemEnums.WeaponTag.Fists]         = "Fists",
	[ItemEnums.WeaponTag.Whip]          = "Whip",
	[ItemEnums.WeaponTag.Staff]         = "Staff",
	[ItemEnums.WeaponTag.Seal]          = "Seal",
	[ItemEnums.WeaponTag.Bow]           = "Bow",
	[ItemEnums.WeaponTag.Crossbow]      = "Crossbow",
	[ItemEnums.WeaponTag.ThrustingSword] = "Thrusting Sword",
	[ItemEnums.WeaponTag.Quarterstaff]  = "Quarterstaff",
}

return ItemEnums
