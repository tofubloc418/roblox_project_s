--!strict
--[[
	HudLoadoutDataAdapter
	=====================
	Single source-of-truth for the HUD Loadout UI state.

	BACKEND CONNECTION:
	  When required, this module immediately connects to the InventoryRemotes:
	    • SyncFullState     → updates weapon1/weapon2 and quickUseItems from
	                          server inventory/equipment data.
	    • SyncAbilityPresets → stores presets; exposed via getAbilityPresets().

	  Other write methods (setActiveSlot, setExpandedWeapon, etc.) remain as
	  pure client-side UI state mutations and do not touch the server.

	CONTROLLER INTERFACE (unchanged):
	  Controllers read state via getState(), mutate it via the write methods,
	  and re-render via subscribe(). React components are purely presentational.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudLoadoutTypes  = require(script.Parent:WaitForChild("HudLoadoutTypes"))
local InventoryTypes   = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

type HudLoadoutState    = HudLoadoutTypes.HudLoadoutState
type HudActiveSlot      = HudLoadoutTypes.HudActiveSlot
type ItemStack          = InventoryTypes.ItemStack
type InventorySyncPayload = InventoryTypes.InventorySyncPayload
type SerializedItem     = InventoryTypes.SerializedItem
type AbilityPresetsData = InventoryTypes.AbilityPresetsData

-- ── Internal state ────────────────────────────────────────────────────────────

local _state: HudLoadoutState = {
	activeSlot            = "Weapon1",
	expandedWeapon        = "Weapon1",
	weapon1               = nil,
	weapon2               = nil,
	quickUseItems         = {},
	currentQuickSlotIndex = nil,
	flashlightOn          = false,
}

-- Latest ability presets (keyed by weaponTag / presetKey).
local _abilityPresets: AbilityPresetsData = {}

local _subscribers: { (HudLoadoutState) -> () } = {}

local function _notify()
	for _, cb in ipairs(_subscribers) do
		cb(_state)
	end
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function toItemStack(item: SerializedItem): ItemStack
	return { itemId = item.tid, count = item.cnt or 1, maxStack = 1 }
end

-- Build quickUseItems from a SyncFullState payload.
-- Quick-use slots store instanceId references; we search inventory.slots for the item.
local function buildQuickUseItems(payload: InventorySyncPayload): { [number]: ItemStack? }
	local result: { [number]: ItemStack? } = {}
	for slot, instanceId in pairs(payload.quickUse.slots) do
		if instanceId then
			local found = false
			for _, item in pairs(payload.inventory.slots) do
				if item and item.iid == instanceId then
					result[slot] = toItemStack(item)
					found        = true
					break
				end
			end
			if not found then
				-- Item may be in stash (not included in payload); use instanceId as fallback label.
				result[slot] = { itemId = instanceId, count = 1, maxStack = 1 }
			end
		end
	end
	return result
end

-- ── Public API ────────────────────────────────────────────────────────────────

local HudLoadoutDataAdapter = {}

-- Returns a shallow copy of current state.
function HudLoadoutDataAdapter.getState(): HudLoadoutState
	return {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = _state.weapon1,
		weapon2               = _state.weapon2,
		quickUseItems         = _state.quickUseItems,
		currentQuickSlotIndex = _state.currentQuickSlotIndex,
		flashlightOn          = _state.flashlightOn,
	}
end

-- Subscribe to state changes.  Returns an unsubscribe function.
function HudLoadoutDataAdapter.subscribe(callback: (HudLoadoutState) -> ()): () -> ()
	table.insert(_subscribers, callback)
	return function()
		local idx = table.find(_subscribers, callback)
		if idx then table.remove(_subscribers, idx) end
	end
end

-- Returns the latest ability presets (keyed by weaponTag / presetKey).
function HudLoadoutDataAdapter.getAbilityPresets(): AbilityPresetsData
	return _abilityPresets
end

--[[
	receiveServerPayload(payload)
	Called (or fired automatically via SyncFullState remote) whenever the server
	sends updated inventory/equipment/quickUse data.  Converts to HUD state and
	notifies subscribers.
]]
function HudLoadoutDataAdapter.receiveServerPayload(payload: InventorySyncPayload)
	local eq = payload.equipment

	local w1: HudLoadoutTypes.HudWeaponInfo? = nil
	local w2: HudLoadoutTypes.HudWeaponInfo? = nil

	if eq.Weapon1 then
		w1 = { itemId = eq.Weapon1.tid, displayName = eq.Weapon1.tid }
	end
	if eq.Weapon2 then
		w2 = { itemId = eq.Weapon2.tid, displayName = eq.Weapon2.tid }
	end

	local quickItems = buildQuickUseItems(payload)

	-- Preserve UI-only fields (activeSlot, expandedWeapon, flashlight, currentQuickSlotIndex).
	_state = {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = w1,
		weapon2               = w2,
		quickUseItems         = quickItems,
		currentQuickSlotIndex = payload.quickUse.currentSlotIndex or _state.currentQuickSlotIndex,
		flashlightOn          = _state.flashlightOn,
	}
	_notify()
end

-- ── Write methods (UI-only state) ─────────────────────────────────────────────

--[[
	setActiveSlot(slot)
	Does NOT update expandedWeapon — managed by the controller so that switching
	to Q or Fists never collapses the last active weapon visual.
]]
function HudLoadoutDataAdapter.setActiveSlot(slot: HudActiveSlot)
	_state = {
		activeSlot            = slot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = _state.weapon1,
		weapon2               = _state.weapon2,
		quickUseItems         = _state.quickUseItems,
		currentQuickSlotIndex = _state.currentQuickSlotIndex,
		flashlightOn          = _state.flashlightOn,
	}
	_notify()
end

-- Update which weapon card shows its full visual icon slot.
function HudLoadoutDataAdapter.setExpandedWeapon(weapon: ("Weapon1" | "Weapon2")?)
	_state = {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = weapon,
		weapon1               = _state.weapon1,
		weapon2               = _state.weapon2,
		quickUseItems         = _state.quickUseItems,
		currentQuickSlotIndex = _state.currentQuickSlotIndex,
		flashlightOn          = _state.flashlightOn,
	}
	_notify()
end

-- Set which quick-slot item is currently selected (used on Q tap).
function HudLoadoutDataAdapter.setCurrentQuickSlotIndex(index: number)
	_state = {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = _state.weapon1,
		weapon2               = _state.weapon2,
		quickUseItems         = _state.quickUseItems,
		currentQuickSlotIndex = index,
		flashlightOn          = _state.flashlightOn,
	}
	_notify()
end

-- Toggle flashlight on/off.
function HudLoadoutDataAdapter.toggleFlashlight()
	_state = {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = _state.weapon1,
		weapon2               = _state.weapon2,
		quickUseItems         = _state.quickUseItems,
		currentQuickSlotIndex = _state.currentQuickSlotIndex,
		flashlightOn          = not _state.flashlightOn,
	}
	_notify()
end

-- Replace weapon loadout (called when the loadout screen changes what is equipped).
-- After the InventoryService is live, this is driven by SyncFullState; this
-- method remains for any direct overrides the controller might need.
function HudLoadoutDataAdapter.setWeapons(
	weapon1: HudLoadoutTypes.HudWeaponInfo?,
	weapon2: HudLoadoutTypes.HudWeaponInfo?
)
	_state = {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = weapon1,
		weapon2               = weapon2,
		quickUseItems         = _state.quickUseItems,
		currentQuickSlotIndex = _state.currentQuickSlotIndex,
		flashlightOn          = _state.flashlightOn,
	}
	_notify()
end

-- Replace the quick-use items table.
function HudLoadoutDataAdapter.setQuickUseItems(items: { [number]: ItemStack? })
	_state = {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = _state.weapon1,
		weapon2               = _state.weapon2,
		quickUseItems         = items,
		currentQuickSlotIndex = _state.currentQuickSlotIndex,
		flashlightOn          = _state.flashlightOn,
	}
	_notify()
end

-- ── Remote connections ────────────────────────────────────────────────────────
-- Connect as soon as this module is required (i.e. when HudLoadoutController loads).
-- WaitForChild is used so this is safe even if Initializer is still booting.

local function connectRemotes()
	local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")

	-- SyncFullState: update weapon/quickuse HUD data.
	local syncFullState = remotes:WaitForChild("SyncFullState") :: RemoteEvent
	syncFullState.OnClientEvent:Connect(function(payload: InventorySyncPayload)
		HudLoadoutDataAdapter.receiveServerPayload(payload)
	end)

	-- SyncAbilityPresets: store for ability selection UI.
	local syncAbilityPresets = remotes:WaitForChild("SyncAbilityPresets") :: RemoteEvent
	syncAbilityPresets.OnClientEvent:Connect(function(presets: AbilityPresetsData)
		if type(presets) == "table" then
			_abilityPresets = presets
			-- No re-render needed; the ability UI pulls presets on demand.
		end
	end)
end

-- Connect in a separate task so the module returns before WaitForChild yields.
task.spawn(connectRemotes)

return HudLoadoutDataAdapter
