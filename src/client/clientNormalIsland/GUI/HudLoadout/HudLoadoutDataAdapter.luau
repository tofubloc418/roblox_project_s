--!strict
--[[
	HudLoadoutDataAdapter
	=====================
	Single source-of-truth interface for the HUD Loadout UI.

	The controller reads state via getState(), mutates it via the write methods,
	and subscribes to changes via subscribe(). React components are pure renderers
	that only receive state as props — they never call this module directly.

	TO CONNECT A REAL BACKEND LATER:
	  Replace the stub state and write method bodies with calls to your actual
	  loadout/equipment data system. The interface (function signatures and
	  HudLoadoutState shape) must remain the same so the UI requires no changes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudLoadoutTypes = require(script.Parent:WaitForChild("HudLoadoutTypes"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

type HudLoadoutState = HudLoadoutTypes.HudLoadoutState
type HudActiveSlot = HudLoadoutTypes.HudActiveSlot
type ItemStack = InventoryTypes.ItemStack

-- ── Stub / mock data ────────────────────────────────────────────────────────
-- Replace this initial state with real data when wiring to the backend.
local _state: HudLoadoutState = {
	activeSlot = "Weapon1",
	expandedWeapon = "Weapon1",
	weapon1 = {
		itemId = "placeholder_weapon_1",
		displayName = "",
	},
	weapon2 = {
		itemId = "placeholder_weapon_2",
		displayName = "",
	},
	quickUseItems = {
		[1] = { itemId = "Bandage",  count = 3, maxStack = 5 },
		[2] = { itemId = "Medkit",   count = 1, maxStack = 1 },
		[3] = nil,
		[4] = nil,
		[5] = nil,
		[6] = nil,
	},
	currentQuickSlotIndex = 1,
	flashlightOn = false,
}

-- ── Subscriber list ──────────────────────────────────────────────────────────
local _subscribers: { (HudLoadoutState) -> () } = {}

local function _notify()
	for _, cb in ipairs(_subscribers) do
		cb(_state)
	end
end

-- ── Public API ────────────────────────────────────────────────────────────────

local HudLoadoutDataAdapter = {}

-- Returns a shallow copy of current state so callers can't mutate internals.
function HudLoadoutDataAdapter.getState(): HudLoadoutState
	return {
		activeSlot              = _state.activeSlot,
		expandedWeapon          = _state.expandedWeapon,
		weapon1                 = _state.weapon1,
		weapon2                 = _state.weapon2,
		quickUseItems           = _state.quickUseItems,
		currentQuickSlotIndex   = _state.currentQuickSlotIndex,
		flashlightOn            = _state.flashlightOn,
	}
end

--[[
	Subscribe to state changes.
	The callback fires every time state is mutated.
	Returns an unsubscribe function — call it in cleanup (e.g. on module unload).
]]
function HudLoadoutDataAdapter.subscribe(callback: (HudLoadoutState) -> ()): () -> ()
	table.insert(_subscribers, callback)
	return function()
		local idx = table.find(_subscribers, callback)
		if idx then
			table.remove(_subscribers, idx)
		end
	end
end

--[[
	Set the currently active slot.
	Does NOT update expandedWeapon — that is managed by the controller so that
	switching to Q/Fists never collapses the weapon visual.
	BACKEND HOOK: also fire the equip remote/signal here.
]]
function HudLoadoutDataAdapter.setActiveSlot(slot: HudActiveSlot)
	_state = {
		activeSlot              = slot,
		expandedWeapon          = _state.expandedWeapon,
		weapon1                 = _state.weapon1,
		weapon2                 = _state.weapon2,
		quickUseItems           = _state.quickUseItems,
		currentQuickSlotIndex   = _state.currentQuickSlotIndex,
		flashlightOn            = _state.flashlightOn,
	}
	_notify()
end

--[[
	Update which weapon card shows its full visual slot (bar + icon).
	Called only when switching between Weapon1 and Weapon2.
	BACKEND HOOK: no additional backend call needed; this is pure UI state.
]]
function HudLoadoutDataAdapter.setExpandedWeapon(weapon: ("Weapon1" | "Weapon2")?)
	_state = {
		activeSlot              = _state.activeSlot,
		expandedWeapon          = weapon,
		weapon1                 = _state.weapon1,
		weapon2                 = _state.weapon2,
		quickUseItems           = _state.quickUseItems,
		currentQuickSlotIndex   = _state.currentQuickSlotIndex,
		flashlightOn            = _state.flashlightOn,
	}
	_notify()
end

--[[
	Set which quick-slot item is "current" (shown in the Q slot card and
	equipped on Q tap).
	BACKEND HOOK: persist this choice in the player's loadout record.
]]
function HudLoadoutDataAdapter.setCurrentQuickSlotIndex(index: number)
	_state = {
		activeSlot              = _state.activeSlot,
		expandedWeapon          = _state.expandedWeapon,
		weapon1                 = _state.weapon1,
		weapon2                 = _state.weapon2,
		quickUseItems           = _state.quickUseItems,
		currentQuickSlotIndex   = index,
		flashlightOn            = _state.flashlightOn,
	}
	_notify()
end

--[[
	Toggle flashlight on/off.
	BACKEND HOOK: fire the flashlight toggle remote/signal here.
]]
function HudLoadoutDataAdapter.toggleFlashlight()
	_state = {
		activeSlot              = _state.activeSlot,
		expandedWeapon          = _state.expandedWeapon,
		weapon1                 = _state.weapon1,
		weapon2                 = _state.weapon2,
		quickUseItems           = _state.quickUseItems,
		currentQuickSlotIndex   = _state.currentQuickSlotIndex,
		flashlightOn            = not _state.flashlightOn,
	}
	_notify()
end

--[[
	Replace the full weapon loadout (called when the loadout screen changes
	what weapons are equipped).
	BACKEND HOOK: this is the entry point for the loadout screen to push
	changes into the HUD.
]]
function HudLoadoutDataAdapter.setWeapons(
	weapon1: HudLoadoutTypes.HudWeaponInfo?,
	weapon2: HudLoadoutTypes.HudWeaponInfo?
)
	_state = {
		activeSlot              = _state.activeSlot,
		expandedWeapon          = _state.expandedWeapon,
		weapon1                 = weapon1,
		weapon2                 = weapon2,
		quickUseItems           = _state.quickUseItems,
		currentQuickSlotIndex   = _state.currentQuickSlotIndex,
		flashlightOn            = _state.flashlightOn,
	}
	_notify()
end

--[[
	Replace the full quick-use items table (called when the loadout screen
	changes what items are in the quick-use slots).
	BACKEND HOOK: entry point for the loadout screen to push changes into HUD.
]]
function HudLoadoutDataAdapter.setQuickUseItems(items: { [number]: ItemStack? })
	_state = {
		activeSlot              = _state.activeSlot,
		expandedWeapon          = _state.expandedWeapon,
		weapon1                 = _state.weapon1,
		weapon2                 = _state.weapon2,
		quickUseItems           = items,
		currentQuickSlotIndex   = _state.currentQuickSlotIndex,
		flashlightOn            = _state.flashlightOn,
	}
	_notify()
end

return HudLoadoutDataAdapter
