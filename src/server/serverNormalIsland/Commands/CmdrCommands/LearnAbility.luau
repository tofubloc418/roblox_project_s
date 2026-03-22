--!strict
return {
	Name = "learnability",
	Aliases = { "learnabil", "unlockability" },
	Description = "Unlock an ability for the ability pool (sets unlockedAbilities in player data).",
	Group = "Dev",
	Args = {
		{
			Type = "abilityId",
			Name = "AbilityId",
			Description = "Registered ability ID",
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: self)",
			Optional = true,
		},
	},
}
