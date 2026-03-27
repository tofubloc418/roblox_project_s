--!strict
return {
	Name = "rm_teleport",
	Aliases = {},
	Description = "RootMotion: teleport HumanoidRootPart (optionally validate path).",
	Group = "Dev",
	Args = {
		{
			Type = "vector3",
			Name = "Position",
			Description = "World position; keeps current facing",
		},
		{
			Type = "boolean",
			Name = "ValidatePath",
			Description = "Run Shapecast path validation",
			Optional = true,
			Default = false,
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: executor)",
			Optional = true,
		},
	},
}
