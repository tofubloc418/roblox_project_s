--!strict
return {
	Name = "rm_pull",
	Aliases = {},
	Description = "RootMotion: pull toward a world position.",
	Group = "Dev",
	Args = {
		{
			Type = "vector3",
			Name = "PullTo",
			Description = "World position",
		},
		{
			Type = "number",
			Name = "Speed",
			Description = "Studs per second",
		},
		{
			Type = "number",
			Name = "MaxDuration",
			Description = "Seconds",
		},
		{
			Type = "number",
			Name = "ArrivalRadius",
			Description = "Studs; stop when within this radius",
			Optional = true,
			Default = 1,
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: executor)",
			Optional = true,
		},
	},
}
