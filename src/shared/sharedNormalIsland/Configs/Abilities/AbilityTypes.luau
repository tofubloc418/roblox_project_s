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
	-- Optional string map: animation ids, rbxassetid VFX/SFX, etc. Reference keys from a local `Asset` table in ability scripts.
	assets: { [string]: string }?,
}

return AbilityTypes
