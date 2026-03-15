--!strict
return {
	Name = "save",
	Aliases = {},
	Description = "Force-save player data.",
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
