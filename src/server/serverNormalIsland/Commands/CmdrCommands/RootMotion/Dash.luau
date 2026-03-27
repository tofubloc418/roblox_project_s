--!strict
return {
	Name = "rm_dash",
	Aliases = {},
	Description = "RootMotion: dash with easing.",
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
			Type = "string",
			Name = "Easing",
			Description = "linear | quadOut | quadIn | cubicOut | cubicIn",
			Optional = true,
			Default = "quadOut",
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: executor)",
			Optional = true,
		},
	},
}
