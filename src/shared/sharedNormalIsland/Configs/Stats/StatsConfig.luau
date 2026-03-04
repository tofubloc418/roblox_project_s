-- StatsConfig
-- Tuning knobs for the stats system: default attributes, scaling coefficients, derived stat caps

local StatsTypes = require(script.Parent:WaitForChild("StatsTypes"))
type CoreAttributes = StatsTypes.CoreAttributes
type DerivedStatId = StatsTypes.DerivedStatId

export type AttributeScaling = {
	-- Vitality: HP pool
	VitalityHpPerPoint: number,
	StrengthHpPerPoint: number,

	-- Intelligence: Mana pool
	IntelligenceManaPerPoint: number,

	-- Endurance: Energy (stamina) pool
	EnduranceEnergyPerPoint: number,

	-- Dexterity: movement, fall damage reduction
	DexterityMoveSpeedPerPoint: number,
	DexterityFallReductionPerPoint: number,

	-- Luck: crit chance
	LuckCritChancePerPoint: number,
}

export type DerivedStatDefaults = {
	[DerivedStatId]: number,
}

export type DerivedStatCaps = {
	[DerivedStatId]: { min: number, max: number }?,
}

local StatsConfig = {
	-- Starting values for all 6 core attributes (e.g. level 1 character)
	DefaultAttributes = {
		Vitality = 10,
		Intelligence = 10,
		Endurance = 10,
		Strength = 10,
		Dexterity = 10,
		Luck = 10,
	} :: CoreAttributes,

	-- How each attribute point contributes to derived stats
	AttributeScaling = {
		VitalityHpPerPoint = 10,
		StrengthHpPerPoint = 1,

		IntelligenceManaPerPoint = 10,

		EnduranceEnergyPerPoint = 10,

		DexterityMoveSpeedPerPoint = 0.5,
		DexterityFallReductionPerPoint = 0.005, -- 0.5% per point

		LuckCritChancePerPoint = 0.005, -- 0.5% per point
	} :: AttributeScaling,

	-- Base values for derived stats before attribute contribution (at 10 Dex: WalkSpeed=14, RunSpeed=50)
	DerivedStatDefaults = {
		MaxHP = 0,
		MaxMana = 0,
		MaxEnergy = 0,
		CritChance = 0,
		MoveSpeed = 9,
		WalkSpeed = 9,
		RunSpeed = 45,
		FallDamageReduction = 0,
		PhysicalResist = 0,
		MagicResist = 0,
		Armor = 0,
		AbilityHaste = 0,
		LootBonus = 1,
		EnergyRegen = 12,
		ManaRegen = 5,
	} :: DerivedStatDefaults,

	-- Min/max clamps for derived stats (nil = no clamp)
	DerivedStatCaps = {
		MaxHP = { min = 1, max = math.huge },
		MaxMana = { min = 0, max = math.huge },
		MaxEnergy = { min = 1, max = math.huge },
		CritChance = { min = 0, max = 1 },
		WalkSpeed = { min = 1, max = 200 },
		RunSpeed = { min = 1, max = 200 },
		FallDamageReduction = { min = 0, max = 1 },
		PhysicalResist = { min = 0, max = 1 },
		MagicResist = { min = 0, max = 1 },
		Armor = { min = 0, max = math.huge },
		AbilityHaste = { min = 0, max = 1 },
		LootBonus = { min = 0.1, max = 10 },
		EnergyRegen = { min = 0, max = math.huge },
		ManaRegen = { min = 0, max = math.huge },
	} :: DerivedStatCaps,

	-- Stats to replicate to Player:SetAttribute() for client/existing systems
	ReplicatedStats = {
		"MaxHP",
		"MaxMana",
		"MaxEnergy",
		"WalkSpeed",
		"RunSpeed",
		"CritChance",
		"FallDamageReduction",
	},
}

return StatsConfig
