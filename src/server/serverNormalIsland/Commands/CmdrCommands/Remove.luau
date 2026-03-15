--!strict
return {
	Name = "remove",
	Aliases = {},
	Description = "Remove the item at a container slot (backpack, equipment, quickuse, stash).",
	Group = "Dev",
	Args = {
		{
			Type = "removeContainer",
			Name = "Container",
			Description = "backpack, equipment, quickuse, or stash",
		},
		{
			Type = "removeSlot",
			Name = "Slot",
			Description = "Slot number (e.g. 1, 5) or equipment slot: Backpack, Armor, Weapon1, Weapon2",
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: self)",
			Optional = true,
		},
	},
}
