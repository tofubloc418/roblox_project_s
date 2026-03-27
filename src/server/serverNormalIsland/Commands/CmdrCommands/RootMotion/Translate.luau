--!strict
return {
	Name = "rm_translate",
	Aliases = {},
	Description = "RootMotion: translate along a direction for a distance over time.",
	Group = "Dev",
	Args = {
		{
			Type = "vector3",
			Name = "Direction",
			Description = "World-space direction (need not be unit)",
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
