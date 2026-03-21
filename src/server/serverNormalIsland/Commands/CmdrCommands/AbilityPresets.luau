--!strict
return {
	Name = "abilitypresets",
	Aliases = { "abilpresets", "apresets" },
	Description = "Print all ability presets for a player (slots 1–5 per preset key).",
	Group = "Dev",
	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: self)",
			Optional = true,
		},
	},
}
