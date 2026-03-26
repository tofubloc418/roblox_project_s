--!strict
return {
	Name = "rm_slam",
	Aliases = {},
	Description = "RootMotion: slam downward.",
	Group = "Dev",
	Args = {
		{
			Type = "number",
			Name = "Speed",
			Description = "Downward speed scale",
		},
		{
			Type = "number",
			Name = "MaxDuration",
			Description = "Seconds (optional cap)",
			Optional = true,
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: executor)",
			Optional = true,
		},
	},
}
