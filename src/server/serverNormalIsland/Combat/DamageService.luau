--!strict
--[[
	DamageService
	Server-side entry-point for all damage calculations and application.

	Reads live player stats from StatsService and weapon data from ItemRegistry,
	builds typed parameter tables, and delegates the math to the pure-function
	DamageCalc module.

	PUBLIC API:
	  CalculateDamage(attacker, weaponTemplateId, defender, options?)
	      → DamageResult   (number-crunching only, no side-effects)

	  CalculateAndApply(attacker, weaponTemplateId, defender, options?)
	      → DamageResult   (calculates then deals damage to defender)

	OPTIONS TABLE (all fields optional):
	  ability: { adScaling: number, mdScaling: number }
	      Override the ability scaling factors (defaults to 1.0 / 1.0 for basic attacks).
	  defenseState: "None" | "Blocking" | "Parrying"
	      Override the defender's defense posture (defaults to "None").
	  defenderWeaponTemplateId: string
	      templateId of the defender's equipped weapon (needed for block/parry power).
	      If omitted, blockPower and parryMultiplier default to 0 / 1.
	  critRollOverride: number
	      Force a specific crit roll (0–1) instead of math.random(). Useful for tests.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Dependencies ─────────────────────────────────────────────────────────────

local CombatFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Combat")
local DamageCalc      = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DamageCalc"))
local DamageCalcTypes = require(CombatFolder:WaitForChild("DamageCalcTypes"))

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))
local StatsService = require(script.Parent.Parent:WaitForChild("Stats"):WaitForChild("StatsService"))

type WeaponParams   = DamageCalcTypes.WeaponParams
type AttackerParams = DamageCalcTypes.AttackerParams
type DefenderParams = DamageCalcTypes.DefenderParams
type AbilityParams  = DamageCalcTypes.AbilityParams
type DamageContext  = DamageCalcTypes.DamageContext
type DamageResult   = DamageCalcTypes.DamageResult
type DefenseState   = DamageCalcTypes.DefenseState

-- ── Options type ─────────────────────────────────────────────────────────────

export type DamageOptions = {
	ability: AbilityParams?,
	defenseState: DefenseState?,
	defenderWeaponTemplateId: string?,
	critRollOverride: number?,
}

-- ── Internal helpers ─────────────────────────────────────────────────────────

-- Build a WeaponParams table from an ItemRegistry template.
local function weaponParamsFromTemplate(template: any): WeaponParams
	return {
		baseAD              = template.baseAD or 0,
		baseMD              = template.baseMD or 0,
		strengthScaling     = template.strengthScaling or 0,
		dexterityScaling    = template.dexterityScaling or 0,
		intelligenceScaling = template.intelligenceScaling or 0,
		blockPower          = template.blockPower or 0,
		parryMultiplier     = template.parryMultiplier or 1,
	}
end

-- Build an AttackerParams table from a player's live stats.
local function buildAttackerParams(player: Player): AttackerParams
	local container = StatsService:GetContainer(player)
	assert(container, "[DamageService] Attacker has no StatContainer: " .. player.Name)

	local attrs = container:GetAttributes()
	return {
		strength     = attrs.Strength,
		dexterity    = attrs.Dexterity,
		intelligence = attrs.Intelligence,
		critChance   = container:GetDerivedStat("CritChance"),
	}
end

-- Build a DefenderParams table from a player's live stats + optional weapon.
local function buildDefenderParams(player: Player, options: DamageOptions?): DefenderParams
	local container = StatsService:GetContainer(player)
	assert(container, "[DamageService] Defender has no StatContainer: " .. player.Name)

	local defenseState: DefenseState = "None"
	local weaponParryMultiplier = 1

	if options then
		if options.defenseState then
			defenseState = options.defenseState
		end
		if options.defenderWeaponTemplateId then
			local template = ItemRegistry.GetTemplate(options.defenderWeaponTemplateId)
			if template then
				weaponParryMultiplier = template.parryMultiplier or 1
			end
		end
	end

	return {
		physicalResist        = container:GetDerivedStat("PhysicalResist"),
		magicResist           = container:GetDerivedStat("MagicResist"),
		armor                 = container:GetDerivedStat("Armor"),
		defenseState          = defenseState,
		weaponParryMultiplier = weaponParryMultiplier,
	}
end

-- ── Public API ───────────────────────────────────────────────────────────────

local DamageService = {}

--[[
	CalculateDamage(attacker, weaponTemplateId, defender, options?)
	Runs the full 6-step damage pipeline using live player stats.
	Returns a DamageResult with finalDamage, isCrit, and a full breakdown.
	Does NOT apply damage — use CalculateAndApply for that.
]]
function DamageService.CalculateDamage(
	attacker: Player,
	weaponTemplateId: string,
	defender: Player,
	options: DamageOptions?
): DamageResult
	-- Resolve weapon template
	local template = ItemRegistry.GetTemplate(weaponTemplateId)
	assert(template, "[DamageService] Unknown weapon templateId: " .. weaponTemplateId)

	local weaponParams   = weaponParamsFromTemplate(template)
	local attackerParams = buildAttackerParams(attacker)
	local defenderParams = buildDefenderParams(defender, options)

	-- Ability scaling: use provided values or default to basic attack (1.0 / 1.0)
	local abilityParams: AbilityParams = if options and options.ability
		then options.ability
		else { adScaling = 1.0, mdScaling = 1.0 }

	-- Crit roll: use override or generate from math.random()
	local critRoll: number = if options and options.critRollOverride
		then options.critRollOverride
		else math.random()

	local context: DamageContext = {
		attacker = attackerParams,
		defender = defenderParams,
		weapon   = weaponParams,
		ability  = abilityParams,
		critRoll = critRoll,
	}

	return DamageCalc.calculate(context)
end

--[[
	CalculateAndApply(attacker, weaponTemplateId, defender, options?)
	Runs CalculateDamage, then applies the resulting damage to the defender's
	Humanoid. Returns the DamageResult so callers can inspect the breakdown.
]]
function DamageService.CalculateAndApply(
	attacker: Player,
	weaponTemplateId: string,
	defender: Player,
	options: DamageOptions?
): DamageResult
	local result = DamageService.CalculateDamage(attacker, weaponTemplateId, defender, options)

	-- Apply to defender's character
	if result.finalDamage > 0 then
		local character = defender.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(result.finalDamage)
			end
		end
	end

	return result
end

return DamageService
