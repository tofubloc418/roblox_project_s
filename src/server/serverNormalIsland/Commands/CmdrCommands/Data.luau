--!strict
return {
	Name = "data",
	Aliases = {},
	Description = "Print raw player data (default: self).",
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
