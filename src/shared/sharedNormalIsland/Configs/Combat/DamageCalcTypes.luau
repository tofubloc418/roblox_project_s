--!strict
-- DamageCalcTypes
-- Type definitions for the modular damage calculation pipeline.
-- Shared so that server, client, and test code can all reference the same shapes.

-- ── Defence State ─────────────────────────────────────────────────────────────
-- Describes what the defender is currently doing at the moment of impact.

export type DefenseState = "None" | "Blocking" | "Parrying"

-- ── Input Parameter Tables ───────────────────────────────────────────────────

-- Fields pulled from the weapon template (ItemRegistry).
export type WeaponParams = {
	baseAD: number,              -- weapon's physical attack damage
	baseMD: number,              -- weapon's magic damage
	strengthScaling: number,     -- multiplier applied to attacker's Strength
	dexterityScaling: number,    -- multiplier applied to attacker's Dexterity
	intelligenceScaling: number, -- multiplier applied to attacker's Intelligence
	blockPower: number,          -- flat damage absorbed when the *defender* blocks
	parryMultiplier: number,     -- multiplier on blockPower when the *defender* parries
}

-- Fields pulled from the attacker's StatContainer (core attributes + derived).
export type AttackerParams = {
	strength: number,    -- core attribute
	dexterity: number,   -- core attribute
	intelligence: number,-- core attribute
	critChance: number,  -- derived stat (0–1), used to determine crit
}

-- Fields pulled from the defender's StatContainer (derived stats).
export type DefenderParams = {
	physicalResist: number, -- 0–1  fraction of physical damage resisted
	magicResist: number,    -- 0–1  fraction of magic damage resisted
	armor: number,          -- flat damage reduction applied after crit
	defenseState: DefenseState, -- what the defender is doing at impact
	-- Defender's weapon parry multiplier (blockPower comes from the ATTACKER's weapon)
	weaponParryMultiplier: number, -- defender's equipped weapon parryMultiplier
}

-- Ability scaling factors. Basic attacks default to 1.0 / 1.0.
export type AbilityParams = {
	adScaling: number, -- multiplier applied to Total AD (default 1.0)
	mdScaling: number, -- multiplier applied to Total MD (default 1.0)
}

-- Complete context bundle passed into the full pipeline.
export type DamageContext = {
	attacker: AttackerParams,
	defender: DefenderParams,
	weapon: WeaponParams,
	ability: AbilityParams,
	critRoll: number, -- random number 0–1 supplied by the caller
}

-- ── Output ───────────────────────────────────────────────────────────────────

-- Intermediate values for every pipeline step (useful for UI, debug, logging).
export type StepResults = {
	-- Step 1: Attribute bonuses
	bonusAD: number,
	bonusMD: number,
	-- Step 2: Total base damage
	totalAD: number,
	totalMD: number,
	-- Step 3: Ability-scaled damage
	abilityScaledAD: number,
	abilityScaledMD: number,
	-- Step 4: After resistances
	unresistedAD: number,
	unresistedMD: number,
	preMitigationDamage: number,
	-- Step 5: Critical strike
	isCrit: boolean,
	trueDamage: number,
	-- Step 6: After mitigation
	finalDamage: number,
}

-- The public result returned by DamageCalc.calculate().
export type DamageResult = {
	finalDamage: number,
	isCrit: boolean,
	breakdown: StepResults,
}

return {}
