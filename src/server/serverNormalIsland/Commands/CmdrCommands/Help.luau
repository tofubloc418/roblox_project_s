--!strict
return {
	Name = "help",
	Aliases = {},
	Description = "Show dev command list.",
	Group = "Dev",
	Args = {},

	ClientRun = function(context)
		local lines = {
			"━━━━━━  Dev Commands  ━━━━━━",
			"── Inventory ──",
			"  give <templateId> [target] [count]   Give item",
			"  remove <container> <slot> [target]   Remove item at slot (backpack, equipment, quickuse, stash)",
			"  items [filter]                       List registered items",
			"── Data ──",
			"  data [target]       Raw player data",
			"  invreport [target]  Inventory report",
			"  save [target]       Force-save",
			"── Abilities ──",
			"  abilitypresets [target]              Print all ability presets",
			"  setabilitypreset <id> <tag> <1-5> [target]   Set preset slot (validates tag + ult cap)",
			"  removeabilityslot <tag> <1-5> [target]       Clear a preset slot",
			"── Player ──",
			"  stats [target]   Attributes & leaderstats",
			"  players          List players",
			"  loaded            Data-load status",
			"── Debug ──",
			"  hitbox [target] [on|off]   ShapecastHitbox visuals",
			"  help               Show this list",
			"━━━━━━━━━━━━━━━━━━━━━━━━━━━",
		}
		for _, line in ipairs(lines) do
			context:Reply(line)
		end
		return "Dev commands listed."
	end,
}
