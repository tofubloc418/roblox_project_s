-- StatsTypes
-- Type definitions for the modular stats system

export type CoreAttributeId = "Vitality" | "Intelligence" | "Endurance" | "Strength" | "Dexterity" | "Luck"

export type CoreAttributes = {
	Vitality: number,
	Intelligence: number,
	Endurance: number,
	Strength: number,
	Dexterity: number,
	Luck: number,
}

export type ModifierOperation = "Flat" | "PercentAdd" | "PercentMult"

export type ModifierSource = "Base" | "Equipment" | "Buff" | "Item" | "Ability" | "Passive"

export type DerivedStatId =
	| "MaxHP"
	| "MaxMana"
	| "MaxEnergy"
	| "CritChance"
	| "MoveSpeed"
	| "WalkSpeed"
	| "RunSpeed"
	| "FallDamageReduction"
	| "PhysicalResist"
	| "MagicResist"
	| "Armor"
	| "AbilityHaste"
	| "LootBonus"
	| "EnergyRegen"
	| "ManaRegen"

export type StatModifier = {
	id: string,
	source: ModifierSource,
	stat: DerivedStatId,
	operation: ModifierOperation,
	value: number,
	duration: number?,
	metadata: { [string]: any }?,
}

export type DerivedStats = {
	MaxHP: number,
	MaxMana: number,
	MaxEnergy: number,
	CritChance: number,
	MoveSpeed: number,
	WalkSpeed: number,
	RunSpeed: number,
	FallDamageReduction: number,
	PhysicalResist: number,
	MagicResist: number,
	Armor: number,
	AbilityHaste: number,
	LootBonus: number,
	EnergyRegen: number,
	ManaRegen: number,
}

return {}
