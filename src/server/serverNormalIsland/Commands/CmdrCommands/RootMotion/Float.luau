--!strict
return {
	Name = "rm_float",
	Aliases = {},
	Description = "RootMotion: counter-gravity float for a duration.",
	Group = "Dev",
	Args = {
		{
			Type = "number",
			Name = "Duration",
			Description = "Seconds",
		},
		{
			Type = "number",
			Name = "TargetY",
			Description = "Optional world Y to hover toward (uses hover gain)",
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
