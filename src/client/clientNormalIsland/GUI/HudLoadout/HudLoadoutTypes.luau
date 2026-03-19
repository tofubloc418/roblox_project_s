--!strict
-- Type definitions for the HUD Loadout equipment section.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
type ItemStack = InventoryTypes.ItemStack

-- Which "slot" the player currently has active (for gameplay + HUD highlighting)
export type HudActiveSlot = "Weapon1" | "Weapon2" | "QuickUse" | "Fists"

-- Lightweight weapon info needed by the HUD (resolved from WeaponData)
export type HudWeaponInfo = {
	itemId: string,
	displayName: string,
}

--[[
	Full HUD loadout state.

	expandedWeapon:
	  Tracks which weapon card shows its visual icon slot.
	  This is intentionally SEPARATE from activeSlot: switching to Q or Fists
	  does NOT collapse the last active weapon's visual (spec §5). Only switching
	  between Weapon1 and Weapon2 updates expandedWeapon.
]]
export type HudLoadoutState = {
	activeSlot: HudActiveSlot,
	expandedWeapon: ("Weapon1" | "Weapon2")?,
	weapon1: HudWeaponInfo?,
	weapon2: HudWeaponInfo?,
	quickUseItems: { [number]: ItemStack? },
	currentQuickSlotIndex: number?,
	flashlightOn: boolean,
}

return {}
