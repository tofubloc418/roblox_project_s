--!strict
--[[
	HudLoadoutDataAdapter
	=====================
	Single source-of-truth for the HUD Loadout UI state.

	BACKEND CONNECTION:
	  Data is read from the dataService client API (path-based get + optional
	  getChangedSignal). Initial state and updates come from DataService:get()
	  for inventory, equipment, quickUse, and abilityPresets; we build
	  InventorySyncPayload and call receiveServerPayload().

	CONTROLLER INTERFACE (unchanged):
	  Controllers read state via getState(), mutate it via the write methods,
	  and re-render via subscribe(). React components are purely presentational.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudLoadoutTypes  = require(script.Parent:WaitForChild("HudLoadoutTypes"))
local InventoryTypes   = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

local Packages = ReplicatedStorage:WaitForChild("Packages")
local DataService = require(Packages:WaitForChild("DataService")) :: any
local DataServiceClient = DataService.client

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

local function buildQuickUseItems(payload: InventorySyncPayload): { [number]: ItemStack? }
	local result: { [number]: ItemStack? } = {}
	for slot = 1, 8 do
		local raw = (InventoryTypes :: any).getSlotItem(payload.quickUse.slots, slot)
		if type(raw) == "table" and raw.tid then
			result[slot] = toItemStack(raw :: SerializedItem)
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

-- Call DataService client get (supports .get or :get).
local function dsGet(path: { string }): any?
	local client = DataServiceClient
	return client:get(path)
end

-- Build InventorySyncPayload from dataService path reads.
local function buildPayloadFromData(): InventorySyncPayload?
	local inv = dsGet({ "inventory" })
	local eq  = dsGet({ "equipment" })
	local qu  = dsGet({ "quickUse" })
	local cur = dsGet({ "currency" })
	if type(inv) ~= "table" or type(eq) ~= "table" or type(qu) ~= "table" then return nil end
	return {
		inventory = inv,
		equipment = eq,
		quickUse  = qu,
		currency  = type(cur) == "table" and cur or { gold = 0 },
	}
end

local function refreshFromDataService()
	local payload = buildPayloadFromData()
	if payload then
		HudLoadoutDataAdapter.receiveServerPayload(payload)
	end
	local presets = dsGet({ "abilityPresets" })
	if type(presets) == "table" then
		_abilityPresets = presets
	end
end

-- Initialize dataService client and subscribe to data; no remotes for state.
local function connectDataService()
	local client = DataServiceClient
	if not (client :: any).networker then
		client:init()
	end
	client:waitForData()
	refreshFromDataService()

	for _, path in ipairs({ { "inventory" }, { "equipment" }, { "quickUse" }, { "abilityPresets" } }) do
		local sig = client:getChangedSignal(path)
		if sig and type(sig.Connect) == "function" then
			sig:Connect(refreshFromDataService)
		end
	end
end

task.spawn(connectDataService)

return HudLoadoutDataAdapter
