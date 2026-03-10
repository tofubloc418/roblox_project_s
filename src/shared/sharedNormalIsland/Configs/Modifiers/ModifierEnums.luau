--!strict
-- ModifierEnums
-- Constants for the augment / bonus modifier system.
--
-- Three tiers only: Minor, Standard, Major. Items (e.g. armor, accessories)
-- roll one tier and attach a modifier as an augment. No tier weights — the
-- item or roll context decides which tier is used.
--
-- Each stat that can be modified has a min/max value range per tier. Values
-- are in the same units as the stat (e.g. CritChance 0.01 = 1%, flat HP is a number).
-- Rolling logic: pick tier, then math.random(min, max) for that stat's tier range.
--
-- HOW TO ADD A NEW STAT RANGE:
--   Add an entry to StatTierRanges with Minor, Standard, Major { min, max }.
--   If the stat is shown as a percentage in UI, add it to PercentageStats.

local ModifierEnums = {}

-- ── Tier names (3 only) ─────────────────────────────────────────────────────────
ModifierEnums.Tier = {
	Minor    = "Minor",
	Standard = "Standard",
	Major    = "Major",
}

-- ── Tier display colors (for tooltip / augment UI) ──────────────────────────────
ModifierEnums.TierDisplayColors = {
	Minor    = Color3.fromRGB(180, 180, 180), -- grey
	Standard = Color3.fromRGB(255, 255, 255), -- white
	Major    = Color3.fromRGB(100, 149, 237), -- blue
}

-- ── Per-stat, per-tier value ranges ────────────────────────────────────────────
-- Roll picks a tier (e.g. from item/context), then a value in [min, max] for that stat.
-- Percent stats: use decimal (0.01 = 1%, 0.05 = 5%). Flat stats: use raw units (HP, speed, etc.).
ModifierEnums.StatTierRanges = {
	CritChance = {
		Minor    = { min = 0.01, max = 0.05 },   -- +1% to +5%
		Standard = { min = 0.05, max = 0.10 },   -- +5% to +10%
		Major    = { min = 0.10, max = 0.15 },   -- +10% to +15%
	},
	PhysicalResist = {
		Minor    = { min = 0.01, max = 0.03 },
		Standard = { min = 0.03, max = 0.06 },
		Major    = { min = 0.06, max = 0.10 },
	},
	MagicResist = {
		Minor    = { min = 0.01, max = 0.03 },
		Standard = { min = 0.03, max = 0.06 },
		Major    = { min = 0.06, max = 0.10 },
	},
	Armor = {
		Minor    = { min = 2, max = 8 },
		Standard = { min = 8, max = 16 },
		Major    = { min = 16, max = 28 },
	},
	MaxHP = {
		Minor    = { min = 10, max = 30 },
		Standard = { min = 30, max = 60 },
		Major    = { min = 60, max = 100 },
	},
	-- Add more stats (AbilityHaste, WalkSpeed, etc.) as needed; same pattern.
}

-- ── Stats that display as "+X%" in tooltips ─────────────────────────────────────
ModifierEnums.PercentageStats = {
	CritChance           = true,
	PhysicalResist       = true,
	MagicResist          = true,
	AbilityHaste         = true,
	LootBonus            = true,
	FallDamageReduction  = true,
}

-- ── Rarity → how many augment slots / modifiers an item can have ────────────────
-- Used when generating or validating items (e.g. armor, accessories). Capped by template.
ModifierEnums.RarityModifierCount = {
	Common    = { max = 1 },
	Uncommon  = { max = 2 },
	Rare      = { max = 3 },
	Epic      = { max = 4 },
	Legendary = { max = 6 },
}

return ModifierEnums
