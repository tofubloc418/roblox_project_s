--!strict
-- Placeholder ability templates for UI testing.

local Placeholder = {
	{
		abilityId = "PlaceholderSlash",
		iconId = "",
		displayName = "Placeholder Slash",
		isUltimate = false,
		compatibleTags = { "Dagger", "Unarmed" },
		damageScaling = { adScaling = 1.2, mdScaling = 0 },
	},
	{
		abilityId = "PlaceholderStrike",
		iconId = "",
		displayName = "Placeholder Strike",
		isUltimate = false,
		compatibleTags = { "Dagger", "Unarmed" },
		damageScaling = { adScaling = 1.0, mdScaling = 0 },
	},
	{
		abilityId = "PlaceholderUlt",
		iconId = "",
		displayName = "Placeholder Ult",
		isUltimate = true,
		compatibleTags = { "Dagger", "Unarmed", "Greatsword" },
		damageScaling = { adScaling = 1.5, mdScaling = 0.5 },
	},
}

return Placeholder
