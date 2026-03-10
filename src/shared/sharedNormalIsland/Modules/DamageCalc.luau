--!strict
-- DamageCalc
-- Pure-function module implementing the 6-step damage pipeline from combat-system.md.
-- Stateless — no service requires, no RNG calls, no side-effects.
-- The caller supplies all data via typed parameter tables.
--
-- Usage (full pipeline):
--   local result = DamageCalc.calculate(context)
--   print(result.finalDamage, result.isCrit)
--
-- Usage (individual steps):
--   local bonusAD, bonusMD = DamageCalc.calculateAttributeBonuses(attacker, weapon)

local DamageCalcTypes = require(script.Parent.Parent:WaitForChild("Configs"):WaitForChild("Combat"):WaitForChild("DamageCalcTypes"))

type WeaponParams   = DamageCalcTypes.WeaponParams
type AttackerParams = DamageCalcTypes.AttackerParams
type DefenderParams = DamageCalcTypes.DefenderParams
type AbilityParams  = DamageCalcTypes.AbilityParams
type DamageContext  = DamageCalcTypes.DamageContext
type StepResults    = DamageCalcTypes.StepResults
type DamageResult   = DamageCalcTypes.DamageResult

-- ── Constants ────────────────────────────────────────────────────────────────

local CRIT_MULTIPLIER = 1.5    -- damage multiplier on critical hit
local MIN_FINAL_DAMAGE = 0     -- floor for the final damage value

-- ── Step 1: Attribute Bonuses to Attack Damage ──────────────────────────────
-- BonusAD = (Strength × WeaponStrScaling) + (Dexterity × WeaponDexScaling)
-- BonusMD = Intelligence × WeaponIntScaling

local function calculateAttributeBonuses(
	attacker: AttackerParams,
	weapon: WeaponParams
): (number, number)
	local bonusAD = (attacker.strength * weapon.strengthScaling)
		+ (attacker.dexterity * weapon.dexterityScaling)
	local bonusMD = attacker.intelligence * weapon.intelligenceScaling
	return bonusAD, bonusMD
end

-- ── Step 2: Total Base Damage ───────────────────────────────────────────────
-- TotalAD = WeaponAD + BonusAD
-- TotalMD = WeaponMD + BonusMD

local function calculateTotalBaseDamage(
	weapon: WeaponParams,
	bonusAD: number,
	bonusMD: number
): (number, number)
	return weapon.baseAD + bonusAD, weapon.baseMD + bonusMD
end

-- ── Step 3: Apply Ability Scaling ───────────────────────────────────────────
-- AbilityScaledAD = TotalAD × Ability.adScaling
-- AbilityScaledMD = TotalMD × Ability.mdScaling

local function applyAbilityScaling(
	totalAD: number,
	totalMD: number,
	ability: AbilityParams
): (number, number)
	return totalAD * ability.adScaling, totalMD * ability.mdScaling
end

-- ── Step 4: Apply Defender Resistances ──────────────────────────────────────
-- UnresistedAD = AbilityScaledAD × (1 - Defender.physicalResist)
-- UnresistedMD = AbilityScaledMD × (1 - Defender.magicResist)
-- PreMitigationDamage = UnresistedAD + UnresistedMD

local function applyDefenderResistances(
	scaledAD: number,
	scaledMD: number,
	defender: DefenderParams
): (number, number, number)
	local unresistedAD = scaledAD * (1 - defender.physicalResist)
	local unresistedMD = scaledMD * (1 - defender.magicResist)
	local preMitDamage = unresistedAD + unresistedMD
	return unresistedAD, unresistedMD, preMitDamage
end

-- ── Step 5: Apply Critical Strike ───────────────────────────────────────────
-- If critRoll <= critChance → TrueDamage = PreMitigation × 1.5
-- Else                      → TrueDamage = PreMitigation

local function applyCriticalStrike(
	preMitDamage: number,
	critChance: number,
	critRoll: number
): (number, boolean)
	local isCrit = critRoll <= critChance
	local trueDamage = if isCrit then preMitDamage * CRIT_MULTIPLIER else preMitDamage
	return trueDamage, isCrit
end

-- ── Step 6: Apply Mitigation & Defense ──────────────────────────────────────
-- No Defense:  FinalDamage = TrueDamage − Armor
-- Blocking:    FinalDamage = TrueDamage − Armor − Attacker's Weapon BlockPower
-- Parrying:    FinalDamage = TrueDamage − Armor − (Attacker's Weapon BlockPower × Defender's Weapon ParryMultiplier)

local function applyMitigation(
	trueDamage: number,
	defender: DefenderParams,
	attackerWeapon: WeaponParams
): number
	local armor = defender.armor
	local reduction = armor

	if defender.defenseState == "Blocking" then
		reduction = reduction + attackerWeapon.blockPower
	elseif defender.defenseState == "Parrying" then
		reduction = reduction + (attackerWeapon.blockPower * defender.weaponParryMultiplier)
	end

	return math.max(MIN_FINAL_DAMAGE, trueDamage - reduction)
end

-- ── Full Pipeline ───────────────────────────────────────────────────────────
-- Runs all 6 steps and returns a DamageResult with the final number plus a
-- complete breakdown of every intermediate value.

local function calculate(context: DamageContext): DamageResult
	local attacker = context.attacker
	local defender = context.defender
	local weapon   = context.weapon
	local ability  = context.ability
	local critRoll = context.critRoll

	-- Step 1
	local bonusAD, bonusMD = calculateAttributeBonuses(attacker, weapon)

	-- Step 2
	local totalAD, totalMD = calculateTotalBaseDamage(weapon, bonusAD, bonusMD)

	-- Step 3
	local abilityScaledAD, abilityScaledMD = applyAbilityScaling(totalAD, totalMD, ability)

	-- Step 4
	local unresistedAD, unresistedMD, preMitigationDamage = applyDefenderResistances(
		abilityScaledAD, abilityScaledMD, defender
	)

	-- Step 5
	local trueDamage, isCrit = applyCriticalStrike(preMitigationDamage, attacker.critChance, critRoll)

	-- Step 6
	local finalDamage = applyMitigation(trueDamage, defender, weapon)

	local breakdown: StepResults = {
		-- Step 1
		bonusAD = bonusAD,
		bonusMD = bonusMD,
		-- Step 2
		totalAD = totalAD,
		totalMD = totalMD,
		-- Step 3
		abilityScaledAD = abilityScaledAD,
		abilityScaledMD = abilityScaledMD,
		-- Step 4
		unresistedAD = unresistedAD,
		unresistedMD = unresistedMD,
		preMitigationDamage = preMitigationDamage,
		-- Step 5
		isCrit = isCrit,
		trueDamage = trueDamage,
		-- Step 6
		finalDamage = finalDamage,
	}

	return {
		finalDamage = finalDamage,
		isCrit = isCrit,
		breakdown = breakdown,
	}
end

return {
	-- Individual step functions (for partial calculations, tooltips, etc.)
	calculateAttributeBonuses  = calculateAttributeBonuses,
	calculateTotalBaseDamage   = calculateTotalBaseDamage,
	applyAbilityScaling        = applyAbilityScaling,
	applyDefenderResistances   = applyDefenderResistances,
	applyCriticalStrike        = applyCriticalStrike,
	applyMitigation            = applyMitigation,

	-- Full pipeline
	calculate = calculate,

	-- Exposed constants for external use
	CRIT_MULTIPLIER  = CRIT_MULTIPLIER,
	MIN_FINAL_DAMAGE = MIN_FINAL_DAMAGE,
}
