--!strict
return {
	Name = "rmsmoke",
	Aliases = { "rootmotion_smoke" },
	Description = "Run all RootMotion movements once with safe defaults (dev smoke test).",
	Group = "Dev",
	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player to test (default: executor)",
			Optional = true,
		},
	},
}
