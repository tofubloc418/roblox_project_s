--!strict
-- Placeholder ability templates for UI testing.

local Placeholder = {
	{
		abilityId = "PlaceholderSlash",
		iconId = "rbxassetid://123456789",
		displayName = "Placeholder Slash",
		description = "A swift horizontal sweep that cuts anything directly in front of you. Excellent for catching multiple enemies off guard.",
		isUltimate = false,
		compatibleTags = { "Dagger", "Unarmed" },
		damageScaling = { adScaling = 1.2, mdScaling = 0 },
	},
	{
		abilityId = "PlaceholderStrike",
		iconId = "rbxassetid://123456789",
		displayName = "Placeholder Strike",
		description = "A focused singular thrust that deals solid damage to a single target before quickly recovering.",
		isUltimate = false,
		compatibleTags = { "Dagger", "Unarmed" },
		damageScaling = { adScaling = 1.0, mdScaling = 0 },
	},
	{
		abilityId = "PlaceholderUlt",
		iconId = "rbxassetid://123456789",
		displayName = "Placeholder Ult",
		description = "Concentrate all your power into a massive devastating attack. Enemies caught in the blast are dealt enormous damage.",
		isUltimate = true,
		compatibleTags = { "Dagger", "Unarmed", "Greatsword" },
		damageScaling = { adScaling = 1.5, mdScaling = 0.5 },
	},
}

return Placeholder
