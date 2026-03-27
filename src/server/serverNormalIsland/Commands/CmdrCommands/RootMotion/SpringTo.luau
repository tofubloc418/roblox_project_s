--!strict
return {
	Name = "rm_springto",
	Aliases = {},
	Description = "RootMotion: spring position toward a world point (AlignPosition).",
	Group = "Dev",
	Args = {
		{
			Type = "vector3",
			Name = "Destination",
			Description = "World position",
		},
		{
			Type = "number",
			Name = "MaxDuration",
			Description = "Seconds before auto-complete",
			Optional = true,
			Default = 4,
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: executor)",
			Optional = true,
		},
	},
}
