--!strict
return {
	Name = "give",
	Aliases = {},
	Description = "Give an item to yourself or a target player.",
	Group = "Dev",
	Args = {
		{
			Type = "itemTemplateId",
			Name = "TemplateId",
			Description = "Item template ID",
		},
		{
			Type = "player",
			Name = "Target",
			Description = "Player to give to (default: self)",
			Optional = true,
		},
		{
			Type = "integer",
			Name = "Count",
			Description = "Amount",
			Optional = true,
			Default = 1,
		},
	},
}
