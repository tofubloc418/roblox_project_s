--!strict
-- Modular tab registry for the settings shell. Add entries here for new pages.

export type TabDef = {
	id: string,
	label: string,
	layoutOrder: number,
}

local SettingsTabConfig: { TabDef } = {
	{ id = "loadout", label = "LOADOUT", layoutOrder = 1 },
	{ id = "keybinds", label = "KEYBINDS", layoutOrder = 2 },
}

return table.freeze(SettingsTabConfig)
