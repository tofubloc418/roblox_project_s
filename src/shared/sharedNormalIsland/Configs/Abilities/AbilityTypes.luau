--!strict
-- Ability template types used by AbilityRegistry and UI.
-- damageScaling is passed to DamageService options.ability.

local AbilityTypes = {}

export type AbilityDamageScaling = {
	adScaling: number,
	mdScaling: number,
}

export type AbilityConfig = {
	abilityId: string,
	iconId: string,
	displayName: string?,
	isUltimate: boolean,
	compatibleTags: { string },
	-- Optional: defaults to { adScaling = 1.0, mdScaling = 1.0 }.
	damageScaling: AbilityDamageScaling?,
}

return AbilityTypes
