--!strict
-- AbilityRegistry
-- Single in-memory registry for ability templates (UI + compatibility lookup).

local _AbilityTypes = require(script.Parent:WaitForChild("AbilityTypes")) :: any

export type AbilityConfig = _AbilityTypes.AbilityConfig

local AbilityRegistry = {}

-- ── Internal storage ──────────────────────────────────────────────────────────

local _abilities: { [string]: AbilityConfig } = {}

-- ── Registration ──────────────────────────────────────────────────────────────

function AbilityRegistry.Register(config: AbilityConfig)
	assert(type(config) == "table", "AbilityRegistry.Register: config must be a table")
	assert(type(config.abilityId) == "string" and #config.abilityId > 0,
		"AbilityRegistry.Register: abilityId must be a non-empty string")
	assert(type(config.compatibleTags) == "table",
		"AbilityRegistry.Register: compatibleTags must be a table (abilityId = " .. config.abilityId .. ")")

	if _abilities[config.abilityId] then
		warn("[AbilityRegistry] Duplicate abilityId registered: " .. config.abilityId)
	end

	_abilities[config.abilityId] = config
end

-- ── Lookup API ────────────────────────────────────────────────────────────────

function AbilityRegistry.GetAbility(abilityId: string): AbilityConfig?
	if not abilityId or #abilityId == 0 then return nil end
	return _abilities[abilityId] or nil
end

function AbilityRegistry.GetAbilitiesByCompatibleTag(weaponTag: string): { AbilityConfig }
	local result: { AbilityConfig } = {}
	if type(weaponTag) ~= "string" or #weaponTag == 0 then return result end
	for _, config in pairs(_abilities) do
		if table.find(config.compatibleTags, weaponTag) then
			table.insert(result, config)
		end
	end
	return result
end

--[[
	GetDamageScaling(abilityId) -> { adScaling: number, mdScaling: number }
	Returns the ability's damage scaling for use with DamageService options.ability.
	Defaults to 1.0 / 1.0 (basic attack) if ability is unknown or has no damageScaling.
]]
function AbilityRegistry.GetDamageScaling(abilityId: string): { adScaling: number, mdScaling: number }
	local config = AbilityRegistry.GetAbility(abilityId)
	if not config or not config.damageScaling then
		return { adScaling = 1.0, mdScaling = 1.0 }
	end
	return {
		adScaling = config.damageScaling.adScaling,
		mdScaling = config.damageScaling.mdScaling,
	}
end

-- Sorted ability IDs (Cmdr autocomplete, dev tools).
function AbilityRegistry.GetAllAbilityIds(): { string }
	local ids: { string } = {}
	for id in pairs(_abilities) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

-- Unique compatible weapon tags across all abilities (Cmdr autocomplete).
function AbilityRegistry.GetAllCompatibleTags(): { string }
	local seen: { [string]: boolean } = {}
	for _, config in pairs(_abilities) do
		for _, tag in ipairs(config.compatibleTags) do
			if tag ~= "" then
				seen[tag] = true
			end
		end
	end
	local tags: { string } = {}
	for tag in pairs(seen) do
		table.insert(tags, tag)
	end
	table.sort(tags)
	return tags
end

-- ── Sub-module auto-discovery ─────────────────────────────────────────────

local function registerFile(moduleScript: Instance)
	local abilitiesTable = require(moduleScript :: ModuleScript) :: { AbilityConfig }
	for _, config in pairs(abilitiesTable) do
		AbilityRegistry.Register(config)
	end
end

registerFile(script.Parent:WaitForChild("Placeholder"))
registerFile(script.Parent:WaitForChild("PrayerfulStrike"))

return AbilityRegistry
