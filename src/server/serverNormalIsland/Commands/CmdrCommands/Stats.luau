--!strict
return {
	Name = "stats",
	Aliases = {},
	Description = "Print attributes and leaderstats for a player.",
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
