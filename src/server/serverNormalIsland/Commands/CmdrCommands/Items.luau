--!strict
return {
	Name = "items",
	Aliases = {},
	Description = "List all registered item IDs, optionally filtered.",
	Group = "Dev",
	Args = {
		{
			Type = "string",
			Name = "Filter",
			Description = "Filter by id, name, or category",
			Optional = true,
		},
	},
}
