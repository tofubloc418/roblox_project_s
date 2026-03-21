--!strict
return {
	Name = "removeabilityslot",
	Aliases = { "clearabilityslot", "raslot" },
	Description = "Clear an ability from a preset slot (weapon tag + slot only).",
	Group = "Dev",
	Args = {
		{
			Type = "weaponTag",
			Name = "WeaponTag",
			Description = "Preset key / weapon tag",
		},
		{
			Type = "presetSlot",
			Name = "Slot",
			Description = "Slot 1–5",
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player (default: self)",
			Optional = true,
		},
	},
}
