--!strict
return {
	Name = "rm_slide",
	Aliases = {},
	Description = "RootMotion: ground slide (needs floor under character).",
	Group = "Dev",
	Args = {
		{
			Type = "vector3",
			Name = "Direction",
			Description = "Horizontal-ish world direction",
		},
		{
			Type = "number",
			Name = "Speed",
			Description = "Studs per second",
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
