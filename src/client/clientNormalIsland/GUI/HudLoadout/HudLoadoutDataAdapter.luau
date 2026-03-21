--!strict
-- HUD loadout state: inventory/equipment/quickUse via DataService; ability presets via AbilityPresetsBridge.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudLoadoutTypes = require(script.Parent:WaitForChild("HudLoadoutTypes"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
local GetPresetKey = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("GetPresetKey"))
local AbilityPresetsBridge = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("AbilityPresetsBridge"))

local Packages = ReplicatedStorage:WaitForChild("Packages")
local DataService = require(Packages:WaitForChild("DataService")) :: any
local DataServiceClient = DataService.client

type HudLoadoutState = HudLoadoutTypes.HudLoadoutState
type HudActiveSlot = HudLoadoutTypes.HudActiveSlot
type ItemStack = InventoryTypes.ItemStack
type InventorySyncPayload = InventoryTypes.InventorySyncPayload
type SerializedItem = InventoryTypes.SerializedItem
type AbilityPresetsData = InventoryTypes.AbilityPresetsData
type SerializedPreset = InventoryTypes.SerializedPreset
type StoredEquipmentData = InventoryTypes.StoredEquipmentData

local _state: HudLoadoutState = {
	activeSlot            = "Weapon1",
	expandedWeapon        = "Weapon1",
	weapon1               = nil,
	weapon2               = nil,
	quickUseItems         = {},
	currentQuickSlotIndex = 1,
	flashlightOn          = false,
}

local _lastEquipment: StoredEquipmentData = {
	Backpack = nil,
	Armor = nil,
	Weapon1 = nil,
	Weapon2 = nil,
}

local _subscribers: { (HudLoadoutState) -> () } = {}

local function _notify()
	for _, cb in ipairs(_subscribers) do
		cb(_state)
	end
end

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

local HudLoadoutDataAdapter = {}

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

function HudLoadoutDataAdapter.subscribe(callback: (HudLoadoutState) -> ()): () -> ()
	table.insert(_subscribers, callback)
	return function()
		local idx = table.find(_subscribers, callback)
		if idx then table.remove(_subscribers, idx) end
	end
end

function HudLoadoutDataAdapter.getAbilityPresets(): AbilityPresetsData
	AbilityPresetsBridge.ensureInitialized()
	return AbilityPresetsBridge.get() :: AbilityPresetsData
end

function HudLoadoutDataAdapter.getAbilityBarPreset(): SerializedPreset?
	AbilityPresetsBridge.ensureInitialized()
	local presetKey = GetPresetKey.GetAbilityBarPresetKey(
		_state.activeSlot,
		_state.expandedWeapon,
		_lastEquipment
	)
	local raw = AbilityPresetsBridge.get()[presetKey]
	return if type(raw) == "table" then raw :: SerializedPreset else nil
end

function HudLoadoutDataAdapter.receiveServerPayload(payload: InventorySyncPayload)
	local eq = payload.equipment

	_lastEquipment = {
		Backpack = eq.Backpack,
		Armor = eq.Armor,
		Weapon1 = eq.Weapon1,
		Weapon2 = eq.Weapon2,
	}

	local w1: HudLoadoutTypes.HudWeaponInfo? = nil
	local w2: HudLoadoutTypes.HudWeaponInfo? = nil

	if eq.Weapon1 then
		w1 = { itemId = eq.Weapon1.tid, displayName = eq.Weapon1.tid }
	end
	if eq.Weapon2 then
		w2 = { itemId = eq.Weapon2.tid, displayName = eq.Weapon2.tid }
	end

	local quickItems = buildQuickUseItems(payload)

	_state = {
		activeSlot            = _state.activeSlot,
		expandedWeapon        = _state.expandedWeapon,
		weapon1               = w1,
		weapon2               = w2,
		quickUseItems         = quickItems,
		currentQuickSlotIndex = payload.quickUse.currentSlotIndex or _state.currentQuickSlotIndex or 1,
		flashlightOn          = _state.flashlightOn,
	}
	_notify()
end

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

local function dsGet(path: { string }): any?
	local client = DataServiceClient
	return client:get(path)
end

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
end

-- Deferred refresh: multi-path moves replicate in steps; reading next frame avoids stale quick-use icons.
local refreshDeferred = false
local function scheduleRefreshFromDataService()
	if refreshDeferred then
		return
	end
	refreshDeferred = true
	task.defer(function()
		refreshDeferred = false
		refreshFromDataService()
	end)
end

local function connectSignal(sig: any?, handler: () -> ())
	if sig and type(sig.Connect) == "function" then
		sig:Connect(handler)
	end
end

local function connectDataService()
	local client = DataServiceClient
	local clientAny = client :: any
	if not clientAny.networker then
		client:init()
	end
	client:waitForData()

	AbilityPresetsBridge.subscribe(function()
		_notify()
	end)
	AbilityPresetsBridge.ensureInitialized()

	refreshFromDataService()

	for _, path in ipairs({ { "inventory" }, { "equipment" }, { "quickUse" } }) do
		connectSignal(client:getChangedSignal(path), scheduleRefreshFromDataService)
	end

	if type(clientAny.getIndexChangedSignal) == "function" then
		connectSignal(clientAny:getIndexChangedSignal({ "quickUse", "slots" }), scheduleRefreshFromDataService)
	end
end

task.spawn(connectDataService)

return HudLoadoutDataAdapter
