--!strict
return {
	Name = "rm_knockback",
	Aliases = {},
	Description = "RootMotion: knockback away from an origin point.",
	Group = "Dev",
	Args = {
		{
			Type = "vector3",
			Name = "Origin",
			Description = "World position to push away from",
		},
		{
			Type = "number",
			Name = "Distance",
			Description = "Studs",
		},
		{
			Type = "number",
			Name = "Duration",
			Description = "Seconds",
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: executor)",
			Optional = true,
		},
	},
}
