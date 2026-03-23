--!strict
return {
	Name = "weapondebug",
	Aliases = {},
	Description = "Toggle weapon animation debug logs on a player's client.",
	Group = "Dev",
	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player whose client toggles (default: self)",
			Optional = true,
		},
		{
			Type = "string",
			Name = "State",
			Description = "on, off, or omit to toggle",
			Optional = true,
		},
	},
}
