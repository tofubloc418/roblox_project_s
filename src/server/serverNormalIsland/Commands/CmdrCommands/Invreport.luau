--!strict
return {
	Name = "invreport",
	Aliases = {},
	Description = "Detailed inventory report: loadout, backpack, quick slots, stash.",
	Group = "Dev",
	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: self)",
			Optional = true,
		},
	},
}
