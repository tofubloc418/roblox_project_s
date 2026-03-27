--!strict
return {
	Name = "rm_orbit",
	Aliases = {},
	Description = "RootMotion: orbit around a world center (axis defaults to world up).",
	Group = "Dev",
	Args = {
		{
			Type = "vector3",
			Name = "Center",
			Description = "World center",
		},
		{
			Type = "number",
			Name = "Radius",
			Description = "Studs",
		},
		{
			Type = "number",
			Name = "AngularSpeed",
			Description = "Radians per second",
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
