--!strict
-- Modular tab registry for the settings shell. Add entries here for new pages.

export type TabDef = {
	id: string,
	label: string,
	layoutOrder: number,
}

local SettingsTabConfig: { TabDef } = {
	{ id = "loadout", label = "LOADOUT", layoutOrder = 1 },
	{ id = "abilities", label = "ABILITIES", layoutOrder = 2 },
	{ id = "keybinds", label = "KEYBINDS", layoutOrder = 3 },
}

return table.freeze(SettingsTabConfig)
