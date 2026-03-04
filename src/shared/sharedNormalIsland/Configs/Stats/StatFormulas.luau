-- StatFormulas
-- Pure functions that compute derived stats from core attributes.
-- Shared so both server and client can use them.

local StatsTypes = require(script.Parent:WaitForChild("StatsTypes"))
local StatsConfig = require(script.Parent:WaitForChild("StatsConfig"))

type CoreAttributes = StatsTypes.CoreAttributes
type DerivedStats = StatsTypes.DerivedStats

local Scaling = StatsConfig.AttributeScaling
local Defaults = StatsConfig.DerivedStatDefaults

local function calculateMaxHP(vitality: number, strength: number): number
	return Defaults.MaxHP + (vitality * Scaling.VitalityHpPerPoint) + (strength * Scaling.StrengthHpPerPoint)
end

local function calculateMaxMana(intelligence: number): number
	return Defaults.MaxMana + (intelligence * Scaling.IntelligenceManaPerPoint)
end

local function calculateMaxEnergy(endurance: number): number
	return Defaults.MaxEnergy + (endurance * Scaling.EnduranceEnergyPerPoint)
end

local function calculateCritChance(luck: number): number
	return Defaults.CritChance + (luck * Scaling.LuckCritChancePerPoint)
end

local function calculateMoveSpeed(dexterity: number): number
	return Defaults.MoveSpeed + (dexterity * Scaling.DexterityMoveSpeedPerPoint)
end

local function calculateWalkSpeed(dexterity: number): number
	return Defaults.WalkSpeed + (dexterity * Scaling.DexterityMoveSpeedPerPoint)
end

local function calculateRunSpeed(dexterity: number): number
	return Defaults.RunSpeed + (dexterity * Scaling.DexterityMoveSpeedPerPoint)
end

local function calculateFallDamageReduction(dexterity: number): number
	return Defaults.FallDamageReduction + (dexterity * Scaling.DexterityFallReductionPerPoint)
end

local function calculateAllDerived(attributes: CoreAttributes): DerivedStats
	return {
		MaxHP = calculateMaxHP(attributes.Vitality, attributes.Strength),
		MaxMana = calculateMaxMana(attributes.Intelligence),
		MaxEnergy = calculateMaxEnergy(attributes.Endurance),
		CritChance = calculateCritChance(attributes.Luck),
		MoveSpeed = calculateMoveSpeed(attributes.Dexterity),
		WalkSpeed = calculateWalkSpeed(attributes.Dexterity),
		RunSpeed = calculateRunSpeed(attributes.Dexterity),
		FallDamageReduction = calculateFallDamageReduction(attributes.Dexterity),
		PhysicalResist = Defaults.PhysicalResist,
		MagicResist = Defaults.MagicResist,
		Armor = Defaults.Armor,
		AbilityHaste = Defaults.AbilityHaste,
		LootBonus = Defaults.LootBonus,
		EnergyRegen = Defaults.EnergyRegen,
		ManaRegen = Defaults.ManaRegen,
	}
end

return {
	calculateMaxHP = calculateMaxHP,
	calculateMaxMana = calculateMaxMana,
	calculateMaxEnergy = calculateMaxEnergy,
	calculateCritChance = calculateCritChance,
	calculateMoveSpeed = calculateMoveSpeed,
	calculateWalkSpeed = calculateWalkSpeed,
	calculateRunSpeed = calculateRunSpeed,
	calculateFallDamageReduction = calculateFallDamageReduction,
	calculateAllDerived = calculateAllDerived,
}
