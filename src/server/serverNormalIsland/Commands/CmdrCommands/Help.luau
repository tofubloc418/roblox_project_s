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
			"  learnability <id> [target]                   Unlock ability for loadout pool",
			"── Player ──",
			"  stats [target]   Attributes & leaderstats",
			"  players          List players",
			"  loaded            Data-load status",
			"── RootMotion ──",
			"  rmhelp                       Parameter reference (all rm_* commands)",
			"  rmsmoke [target]             Smoke-test every movement",
			"  rm_translate <v3> dist dur [target]   rm_dash <v3> dist dur [easing] [target]",
			"  rm_knockback <origin v3> dist dur [target]   rm_pull <v3> speed maxDur [radius] [target]",
			"  rm_launch <height> [target]   rm_slam <speed> [maxDur] [target]",
			"  rm_float <dur> [targetY] [target]   rm_slide <v3> speed dur [target]",
			"  rm_lunge <v3> [dist] [dur] [target]   rm_teleport <v3> [validate?] [target]",
			"  rm_orbit <center v3> radius rad/s dur [target]   rm_springto <v3> [maxDur] [target]",
			"── Debug ──",
			"  hitbox [target] [on|off]   ShapecastHitbox visuals",
			"  weapondebug [target] [on|off]   Weapon animation debug logs",
			"  help               Show this list",
			"━━━━━━━━━━━━━━━━━━━━━━━━━━━",
		}
		for _, line in ipairs(lines) do
			context:Reply(line)
		end
		return "Dev commands listed."
	end,
}
