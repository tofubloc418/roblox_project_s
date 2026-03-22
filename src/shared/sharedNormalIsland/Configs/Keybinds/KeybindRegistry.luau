--!strict

local KeybindIds = require(script.Parent:WaitForChild("KeybindIds"))

export type KeybindEntry = {
	default: { Enum.KeyCode },
	category: string,
	description: string,
}

local entries: { [string]: KeybindEntry } = {
	[KeybindIds.Sprint] = {
		default = { Enum.KeyCode.LeftControl },
		category = "Gameplay",
		description = "Hold to sprint",
	},
	[KeybindIds.Jump] = {
		default = { Enum.KeyCode.Space },
		category = "Gameplay",
		description = "Jump",
	},
	[KeybindIds.Interact] = {
		default = { Enum.KeyCode.F },
		category = "Gameplay",
		description = "Interact",
	},
	[KeybindIds.ThirdPersonCameraLock] = {
		default = { Enum.KeyCode.V },
		category = "Gameplay",
		description = "Toggle third-person camera lock",
	},

	[KeybindIds.AbilitySlot1] = {
		default = { Enum.KeyCode.One },
		category = "Abilities",
		description = "Use ability slot 1",
	},
	[KeybindIds.AbilitySlot2] = {
		default = { Enum.KeyCode.Two },
		category = "Abilities",
		description = "Use ability slot 2",
	},
	[KeybindIds.AbilitySlot3] = {
		default = { Enum.KeyCode.Three },
		category = "Abilities",
		description = "Use ability slot 3",
	},
	[KeybindIds.AbilitySlot4] = {
		default = { Enum.KeyCode.Four },
		category = "Abilities",
		description = "Use ability slot 4",
	},
	[KeybindIds.AbilitySlot5] = {
		default = { Enum.KeyCode.Five },
		category = "Abilities",
		description = "Use ability slot 5",
	},

	[KeybindIds.HudWeapon1] = {
		default = { Enum.KeyCode.Z },
		category = "HudLoadout",
		description = "Equip weapon slot 1",
	},
	[KeybindIds.HudWeapon2] = {
		default = { Enum.KeyCode.C },
		category = "HudLoadout",
		description = "Equip weapon slot 2",
	},
	[KeybindIds.HudSwapWeapons] = {
		default = { Enum.KeyCode.E },
		category = "HudLoadout",
		description = "Swap between weapon slots / equip primary weapon",
	},
	[KeybindIds.HudFists] = {
		default = { Enum.KeyCode.X },
		category = "HudLoadout",
		description = "Equip fists",
	},
	[KeybindIds.HudQuickUse] = {
		default = { Enum.KeyCode.Q },
		category = "HudLoadout",
		description = "Use quick slot / radial",
	},
	[KeybindIds.HudFlashlight] = {
		default = { Enum.KeyCode.Zero },
		category = "HudLoadout",
		description = "Toggle flashlight",
	},

	[KeybindIds.ToggleLoadout] = {
		default = { Enum.KeyCode.Tab },
		category = "Interface",
		description = "Toggle loadout screen",
	},
	[KeybindIds.ToggleMap] = {
		default = { Enum.KeyCode.M },
		category = "Interface",
		description = "Toggle full map",
	},
}

local function cloneKeyCodes(keyCodes: { Enum.KeyCode }): { Enum.KeyCode }
	local copy: { Enum.KeyCode } = {}
	for _, keyCode in ipairs(keyCodes) do
		table.insert(copy, keyCode)
	end
	return copy
end

local KeybindRegistry = {}

function KeybindRegistry.Has(actionId: string): boolean
	return entries[actionId] ~= nil
end

function KeybindRegistry.Get(actionId: string): KeybindEntry?
	local entry = entries[actionId]
	if not entry then
		return nil
	end
	return {
		default = cloneKeyCodes(entry.default),
		category = entry.category,
		description = entry.description,
	}
end

function KeybindRegistry.GetDefaultKeyCodes(actionId: string): { Enum.KeyCode }
	local entry = entries[actionId]
	if not entry then
		return {}
	end
	return cloneKeyCodes(entry.default)
end

function KeybindRegistry.GetAll(): { [string]: KeybindEntry }
	local copy: { [string]: KeybindEntry } = {}
	for actionId, entry in pairs(entries) do
		copy[actionId] = {
			default = cloneKeyCodes(entry.default),
			category = entry.category,
			description = entry.description,
		}
	end
	return copy
end

return table.freeze(KeybindRegistry)
