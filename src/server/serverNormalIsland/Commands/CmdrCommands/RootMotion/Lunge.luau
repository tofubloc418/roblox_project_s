--!strict
return {
	Name = "rm_lunge",
	Aliases = {},
	Description = "RootMotion: short lunge (translate with defaults).",
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
			Description = "Studs (default: module default)",
			Optional = true,
		},
		{
			Type = "number",
			Name = "Duration",
			Description = "Seconds (default: module default)",
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
