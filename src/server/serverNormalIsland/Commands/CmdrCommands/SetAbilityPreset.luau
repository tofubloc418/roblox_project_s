--!strict
return {
	Name = "setabilitypreset",
	Aliases = { "setabilpreset", "sapreset" },
	Description = "Assign an ability to a preset slot (validates tag compatibility and ultimate limit).",
	Group = "Dev",
	Args = {
		{
			Type = "abilityId",
			Name = "AbilityId",
			Description = "Registered ability ID",
		},
		{
			Type = "weaponTag",
			Name = "WeaponTag",
			Description = "Weapon tag (from ability compatibleTags)",
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
