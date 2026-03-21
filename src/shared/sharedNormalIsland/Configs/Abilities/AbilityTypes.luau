--!strict
-- AbilityRegistry / UI template types.

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
	description: string?,
	compatibleTags: { string },
	damageScaling: AbilityDamageScaling?,
	params: { [string]: any }?,
}

return AbilityTypes
