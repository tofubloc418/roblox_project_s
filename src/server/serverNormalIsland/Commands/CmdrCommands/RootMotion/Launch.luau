--!strict
return {
	Name = "rm_launch",
	Aliases = {},
	Description = "RootMotion: vertical launch impulse.",
	Group = "Dev",
	Args = {
		{
			Type = "number",
			Name = "Height",
			Description = "Target height offset (studs)",
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: executor)",
			Optional = true,
		},
	},
}
