--!strict
-- InventoryService
-- Server-side, data-only inventory management.
--
-- RESPONSIBILITIES:
--   - Own ALL InventoryRemotes (creates them; AbilityDataService reuses the folder).
--   - Handle client requests: RequestMove, RequestEquip, RequestUnequip,
--     RequestDrop, RequestAssignQuick, RequestStashTransfer.
--   - Provide server-callable APIs for container CRUD, equip/unequip, stash
--     transfers, quick-use assignment, and full-state sync to client.
--
-- WHAT THIS MODULE DOES NOT DO:
--   - No stat calculation or modifier application.
--   - No ability activation or cooldown management.
--   - No world-drop spawning (RequestDrop removes the item from data only).
--   - No DataStore access; all persistence goes through DataManager.
--
-- CONTAINER MODEL:
--   The four containers are: "inventory", "stash", "equipment", "quickuse".
--   inventory / stash: numbered slots (1 … maxSlots), value = SerializedItem?.
--   equipment: named slots (Backpack, Armor, Weapon1, Weapon2), value = SerializedItem?.
--   quickuse: numbered slots (1 … QUICK_USE_MAX_SLOTS), value = instanceId string?
--             (quick-use slots are references, not item copies).

local _Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Server-side dependencies (relative path through ServerScriptService tree).
local DataManager  = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataManager"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

type PlayerData         = InventoryTypes.PlayerData
type SerializedItem     = InventoryTypes.SerializedItem
type SerializedMod      = InventoryTypes.SerializedMod
type StoredInventoryData = InventoryTypes.StoredInventoryData
type StoredEquipmentData = InventoryTypes.StoredEquipmentData
type StoredQuickUseData  = InventoryTypes.StoredQuickUseData
type StashData          = InventoryTypes.StashData
type CurrencyData       = InventoryTypes.CurrencyData
type InventorySyncPayload = InventoryTypes.InventorySyncPayload
type EquipmentSlotId    = InventoryTypes.EquipmentSlotId
type ContainerId        = InventoryTypes.ContainerId

-- ── Constants ─────────────────────────────────────────────────────────────────

local QUICK_USE_MAX_SLOTS = 8

-- Maps equipment slot → the item category allowed in that slot.
-- If ItemRegistry has no template for an item (dev mode), validation is skipped.
local SLOT_ALLOWED_CATEGORY: { [EquipmentSlotId]: string } = {
	Backpack = "Backpack",
	Armor    = "Armor",
	Weapon1  = "Weapon",
	Weapon2  = "Weapon",
}

local VALID_EQUIPMENT_SLOTS: { [EquipmentSlotId]: boolean } = {
	Backpack = true, Armor = true, Weapon1 = true, Weapon2 = true,
}

-- ── Remote references (populated in Initialize) ───────────────────────────────

local _syncFullState:       RemoteEvent
local _syncCurrency:        RemoteEvent
local _requestMove:         RemoteEvent
local _requestEquip:        RemoteEvent
local _requestUnequip:      RemoteEvent
local _requestDrop:         RemoteEvent
local _requestAssignQuick:  RemoteEvent
local _requestStashTransfer: RemoteEvent

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function generateInstanceId(templateId: string): string
	return templateId
		.. "_" .. tostring(os.time())
		.. "_" .. string.format("%04d", math.random(0, 9999))
end

-- Find a SerializedItem in any container by its instanceId.
-- Returns (containerId, slot) where slot is a number or EquipmentSlotId string.
local function findItemById(
	data: PlayerData,
	instanceId: string
): (ContainerId?, number | string?)

	for slot, item in pairs(data.inventory.slots) do
		if item and item.iid == instanceId then
			return "inventory", slot
		end
	end

	local eq = data.equipment
	if eq.Backpack and eq.Backpack.iid == instanceId then return "equipment", "Backpack" end
	if eq.Armor    and eq.Armor.iid    == instanceId then return "equipment", "Armor"    end
	if eq.Weapon1  and eq.Weapon1.iid  == instanceId then return "equipment", "Weapon1"  end
	if eq.Weapon2  and eq.Weapon2.iid  == instanceId then return "equipment", "Weapon2"  end

	for slot, item in pairs(data.stash.slots) do
		if item and item.iid == instanceId then
			return "stash", slot
		end
	end

	return nil, nil
end

-- Read a SerializedItem from any container at a given slot.
local function getItemAt(
	data: PlayerData,
	containerId: ContainerId,
	slot: number | string
): SerializedItem?

	if containerId == "inventory" then
		return data.inventory.slots[slot :: number]
	elseif containerId == "equipment" then
		return (data.equipment :: any)[slot :: string]
	elseif containerId == "stash" then
		return data.stash.slots[slot :: number]
	end
	return nil
end

-- Write (or clear) a SerializedItem in any container at a given slot.
local function setItemAt(
	data: PlayerData,
	containerId: ContainerId,
	slot: number | string,
	item: SerializedItem?
)
	if containerId == "inventory" then
		data.inventory.slots[slot :: number] = item
	elseif containerId == "equipment" then
		(data.equipment :: any)[slot :: string] = item
	elseif containerId == "stash" then
		data.stash.slots[slot :: number] = item
	end
end

-- Scan for the first empty numbered slot in the inventory.
local function findFreeInventorySlot(data: PlayerData): number?
	for i = 1, data.inventory.maxSlots do
		if not data.inventory.slots[i] then
			return i
		end
	end
	return nil
end

-- Scan for the first empty numbered slot in the stash.
local function findFreeStashSlot(data: PlayerData): number?
	for i = 1, data.stash.maxSlots do
		if not data.stash.slots[i] then
			return i
		end
	end
	return nil
end

-- Check whether an item may go into an equipment slot.
-- Permissive if the template is not yet registered (development mode).
local function canEquipInSlot(item: SerializedItem, slotId: EquipmentSlotId): boolean
	local template = ItemRegistry.GetTemplate(item.tid)
	if not template then
		return true -- template not yet defined; allow during development
	end
	return template.category == SLOT_ALLOWED_CATEGORY[slotId]
end

-- Remove all quickuse references that point to an instanceId that no longer exists.
local function _pruneOrphanedQuickUseRefs(data: PlayerData)
	for slot, instanceId in pairs(data.quickUse.slots) do
		if instanceId then
			local container = findItemById(data, instanceId)
			if not container then
				data.quickUse.slots[slot] = nil
			end
		end
	end
end

-- ── Public API ────────────────────────────────────────────────────────────────

local InventoryService = {}

-- ─── Read accessors ───────────────────────────────────────────────────────────

function InventoryService.GetInventory(player: Player): StoredInventoryData?
	local data = DataManager.GetPlayerData(player)
	return data and data.inventory or nil
end

function InventoryService.GetEquipment(player: Player): StoredEquipmentData?
	local data = DataManager.GetPlayerData(player)
	return data and data.equipment or nil
end

function InventoryService.GetStash(player: Player): StashData?
	local data = DataManager.GetPlayerData(player)
	return data and data.stash or nil
end

function InventoryService.GetQuickUse(player: Player): StoredQuickUseData?
	local data = DataManager.GetPlayerData(player)
	return data and data.quickUse or nil
end

function InventoryService.GetCurrency(player: Player): CurrencyData?
	local data = DataManager.GetPlayerData(player)
	return data and data.currency or nil
end

-- ─── Item creation ────────────────────────────────────────────────────────────

--[[
	AddItem(player, templateId, count?, modifiers?)
	Creates a new item instance in the player's inventory.
	Respects template stackMax when defined (stacks existing items first).
	Returns the SerializedItem on success, nil if inventory is full.
	modifiers should be a list of SerializedMod if provided.
]]
function InventoryService.AddItem(
	player: Player,
	templateId: string,
	count: number?,
	modifiers: { SerializedMod }?
): SerializedItem?

	local data = DataManager.GetPlayerData(player)
	if not data or not templateId or templateId == "" then return nil end

	local template  = ItemRegistry.GetTemplate(templateId)
	local stackMax  = (template and template.stackMax) or 1
	local remaining = count or 1

	-- Try to fill existing stacks first.
	if stackMax > 1 and remaining > 0 then
		for _, existing in pairs(data.inventory.slots) do
			if existing and existing.tid == templateId and not existing.mods then
				local currentCount = existing.cnt or 1
				local canAdd       = stackMax - currentCount
				if canAdd > 0 then
					local addAmount = math.min(canAdd, remaining)
					existing.cnt   = currentCount + addAmount
					remaining      -= addAmount
					if remaining <= 0 then
						DataManager.MarkDirty(player)
						InventoryService.SyncToClient(player)
						return existing
					end
				end
			end
		end
	end

	-- Place remaining into a new slot.
	local freeSlot = findFreeInventorySlot(data)
	if not freeSlot then
		warn("[InventoryService] Inventory full for " .. player.Name)
		return nil
	end

	local newItem: SerializedItem = {
		iid  = generateInstanceId(templateId),
		tid  = templateId,
		cnt  = (remaining > 1 or stackMax > 1) and remaining or nil,
		mods = (modifiers and #modifiers > 0) and modifiers or nil,
	}

	data.inventory.slots[freeSlot] = newItem
	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return newItem
end

-- ─── Item removal ─────────────────────────────────────────────────────────────

--[[
	RemoveItem(player, instanceId)
	Removes an item from any container (inventory, equipment, or stash).
	Also removes any quickuse reference pointing to this instance.
	Returns true on success.
]]
function InventoryService.RemoveItem(player: Player, instanceId: string): boolean
	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	local containerId, slot = findItemById(data, instanceId)
	if not containerId or slot == nil then return false end

	setItemAt(data, containerId :: ContainerId, slot, nil)

	-- Clear dangling quickuse references.
	for i, qiid in pairs(data.quickUse.slots) do
		if qiid == instanceId then
			data.quickUse.slots[i] = nil
		end
	end

	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

-- ─── Container movement ───────────────────────────────────────────────────────

--[[
	MoveItem(player, fromContainer, fromSlot, toContainer, toSlot)
	Moves an item from one container/slot to another, swapping if the
	destination is occupied.  Validates equipment slot categories.
	Returns true on success.
]]
function InventoryService.MoveItem(
	player: Player,
	fromContainer: ContainerId,
	fromSlot: number | string,
	toContainer: ContainerId,
	toSlot: number | string
): boolean

	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	local item     = getItemAt(data, fromContainer, fromSlot)
	if not item then return false end

	local destItem = getItemAt(data, toContainer, toSlot)

	-- Validate equipment slot compatibility for both directions.
	if toContainer == "equipment" then
		if type(toSlot) ~= "string" then
			return false
		end
		local slotId: EquipmentSlotId = toSlot :: any
		if not VALID_EQUIPMENT_SLOTS[slotId] then return false end
		if not canEquipInSlot(item, slotId) then return false end
	end
	if fromContainer == "equipment" and destItem then
		if type(fromSlot) ~= "string" then
			return false
		end
		local slotId: EquipmentSlotId = fromSlot :: any
		if not canEquipInSlot(destItem, slotId) then return false end
	end

	-- Perform atomic swap.
	setItemAt(data, fromContainer, fromSlot, destItem)
	setItemAt(data, toContainer,   toSlot,   item)

	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

-- ─── Equip / Unequip ──────────────────────────────────────────────────────────

--[[
	EquipItem(player, instanceId, slotId)
	Moves an item from inventory/stash into an equipment slot.
	If the slot is already occupied, the old item swaps to the source location
	(or a free inventory slot if the source was stash/equip).
	Returns true on success.
]]
function InventoryService.EquipItem(
	player: Player,
	instanceId: string,
	slotId: EquipmentSlotId
): boolean

	local data = DataManager.GetPlayerData(player)
	if not data then return false end
	if not VALID_EQUIPMENT_SLOTS[slotId] then return false end

	local fromContainer, fromSlot = findItemById(data, instanceId)
	if not fromContainer or fromSlot == nil then return false end

	-- Already in the correct slot.
	if fromContainer == "equipment" and fromSlot == slotId then return true end

	local item = getItemAt(data, fromContainer :: ContainerId, fromSlot)
	if not item then return false end

	if not canEquipInSlot(item, slotId) then return false end

	local existing: SerializedItem? = (data.equipment :: any)[slotId]

	if existing then
		-- Try to return the existing item to the source slot.
		if fromContainer == "inventory" then
			data.inventory.slots[fromSlot :: number] = existing
		else
			local freeSlot = findFreeInventorySlot(data)
			if not freeSlot then return false end
			data.inventory.slots[freeSlot] = existing
			setItemAt(data, fromContainer :: ContainerId, fromSlot, nil)
		end
	else
		setItemAt(data, fromContainer :: ContainerId, fromSlot, nil)
	end

	(data.equipment :: any)[slotId] = item

	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

--[[
	UnequipItem(player, slotId)
	Moves the item in an equipment slot back to a free inventory slot.
	Returns true on success.
]]
function InventoryService.UnequipItem(player: Player, slotId: EquipmentSlotId): boolean
	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	local item: SerializedItem? = (data.equipment :: any)[slotId]
	if not item then return false end

	local freeSlot = findFreeInventorySlot(data)
	if not freeSlot then return false end

	data.inventory.slots[freeSlot] = item;
	(data.equipment :: any)[slotId] = nil

	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

-- ─── Quick-use management ─────────────────────────────────────────────────────

--[[
	AssignQuickUse(player, instanceId, quickSlot)
	Assigns an existing item (by instanceId) to a quick-use slot (1–8).
	The item must still be somewhere in inventory or stash.
]]
function InventoryService.AssignQuickUse(
	player: Player,
	instanceId: string,
	quickSlot: number
): boolean

	local data = DataManager.GetPlayerData(player)
	if not data then return false end
	if quickSlot < 1 or quickSlot > QUICK_USE_MAX_SLOTS then return false end

	local containerId = findItemById(data, instanceId)
	if not containerId then return false end

	data.quickUse.slots[quickSlot] = instanceId
	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

--[[
	ClearQuickUse(player, quickSlot)
	Empties a quick-use reference slot.
]]
function InventoryService.ClearQuickUse(player: Player, quickSlot: number): boolean
	local data = DataManager.GetPlayerData(player)
	if not data then return false end
	if quickSlot < 1 or quickSlot > QUICK_USE_MAX_SLOTS then return false end

	data.quickUse.slots[quickSlot] = nil
	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

-- ─── Stash transfers ──────────────────────────────────────────────────────────

--[[
	TransferToStash(player, inventorySlot, stashSlot)
	Moves an item from an inventory slot to a stash slot.
	If stashSlot is occupied or invalid (0), finds the first free stash slot.
]]
function InventoryService.TransferToStash(
	player: Player,
	inventorySlot: number,
	stashSlot: number
): boolean

	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	local item = data.inventory.slots[inventorySlot]
	if not item then return false end

	local targetSlot = stashSlot
	if targetSlot < 1 or targetSlot > data.stash.maxSlots or data.stash.slots[targetSlot] then
		targetSlot = findFreeStashSlot(data) or 0
		if targetSlot == 0 then return false end
	end

	data.stash.slots[targetSlot]       = item
	data.inventory.slots[inventorySlot] = nil

	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

--[[
	TransferFromStash(player, stashSlot, inventorySlot)
	Moves an item from a stash slot to an inventory slot.
	If inventorySlot is occupied or invalid (0), finds the first free inventory slot.
]]
function InventoryService.TransferFromStash(
	player: Player,
	stashSlot: number,
	inventorySlot: number
): boolean

	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	local item = data.stash.slots[stashSlot]
	if not item then return false end

	local targetSlot = inventorySlot
	if targetSlot < 1 or targetSlot > data.inventory.maxSlots or data.inventory.slots[targetSlot] then
		targetSlot = findFreeInventorySlot(data) or 0
		if targetSlot == 0 then return false end
	end

	data.inventory.slots[targetSlot] = item
	data.stash.slots[stashSlot]       = nil

	DataManager.MarkDirty(player)
	InventoryService.SyncToClient(player)
	return true
end

-- ─── Sync ─────────────────────────────────────────────────────────────────────

--[[
	SyncToClient(player)
	Fires SyncFullState to the client with the current inventory, equipment,
	quickUse, and currency.  Strips server-only fields (sessionId, etc.).
]]
function InventoryService.SyncToClient(player: Player)
	local data = DataManager.GetPlayerData(player)
	if not data then return end

	local payload: InventorySyncPayload = {
		inventory = data.inventory,
		equipment = data.equipment,
		quickUse  = data.quickUse,
		currency  = data.currency,
	}

	_syncFullState:FireClient(player, payload)
end

-- ─── Initialization ───────────────────────────────────────────────────────────

--[[
	Initialize()
	Creates all InventoryRemotes (used by this service AND AbilityDataService),
	wires up client request handlers, and registers a PlayerAdded hook so data
	is synced to the client after loading.

	Must be called after DataManager.Initialize().
]]
function InventoryService.Initialize()

	-- ── Remote creation ──────────────────────────────────────────────────────
	local remoteFolder = ReplicatedStorage:FindFirstChild("InventoryRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "InventoryRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	local function ensureRemote(name: string): RemoteEvent
		local existing = remoteFolder:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			return existing :: RemoteEvent
		end
		-- Remove stale non-RemoteEvent with the same name (e.g. placeholder from old code).
		if existing then existing:Destroy() end
		local remote = Instance.new("RemoteEvent")
		remote.Name   = name
		remote.Parent = remoteFolder
		return remote
	end

	-- Inventory remotes
	_syncFullState        = ensureRemote("SyncFullState")
	_syncCurrency         = ensureRemote("SyncCurrency")
	_requestMove          = ensureRemote("RequestMove")
	_requestEquip         = ensureRemote("RequestEquip")
	_requestUnequip       = ensureRemote("RequestUnequip")
	_requestDrop          = ensureRemote("RequestDrop")
	_requestAssignQuick   = ensureRemote("RequestAssignQuick")
	_requestStashTransfer = ensureRemote("RequestStashTransfer")

	-- Shared slot-update (granular, for future optimisation; created but not fired yet).
	ensureRemote("SyncSlotUpdate")

	-- Ability preset remotes (folder is shared; AbilityDataService sets up handlers).
	ensureRemote("RequestSetAbilityPreset")
	ensureRemote("SyncAbilityPresets")

	-- Stubbed runtime-behavior remotes (wired in a future milestone).
	ensureRemote("RequestAbility")
	ensureRemote("AbilityActivated")
	ensureRemote("AbilityCooldownSync")
	ensureRemote("RequestUseConsumable")
	ensureRemote("ConsumableActivated")

	-- ── Request handlers ─────────────────────────────────────────────────────

	-- RequestMove: { fromContainer, fromSlot, toContainer, toSlot }
	_requestMove.OnServerEvent:Connect(function(
		player: Player,
		fromContainer: any,
		fromSlot: any,
		toContainer: any,
		toSlot: any
	)
		if type(fromContainer) ~= "string" or type(toContainer) ~= "string" then return end
		if type(fromSlot) ~= "number" and type(fromSlot) ~= "string" then return end
		if type(toSlot)   ~= "number" and type(toSlot)   ~= "string" then return end
		local fromId: ContainerId = fromContainer :: any
		local toId: ContainerId = toContainer :: any
		InventoryService.MoveItem(player, fromId, fromSlot, toId, toSlot)
	end)

	-- RequestEquip: instanceId, slotId
	_requestEquip.OnServerEvent:Connect(function(player: Player, instanceId: any, slotId: any)
		if type(instanceId) ~= "string" or type(slotId) ~= "string" then return end
		InventoryService.EquipItem(player, instanceId, slotId :: EquipmentSlotId)
	end)

	-- RequestUnequip: slotId
	_requestUnequip.OnServerEvent:Connect(function(player: Player, slotId: any)
		if type(slotId) ~= "string" then return end
		InventoryService.UnequipItem(player, slotId :: EquipmentSlotId)
	end)

	-- RequestDrop: instanceId
	-- Data layer only: removes from data. World-drop behavior is a future task.
	_requestDrop.OnServerEvent:Connect(function(player: Player, instanceId: any)
		if type(instanceId) ~= "string" then return end
		InventoryService.RemoveItem(player, instanceId)
	end)

	-- RequestAssignQuick: instanceId, quickSlot
	_requestAssignQuick.OnServerEvent:Connect(function(player: Player, instanceId: any, quickSlot: any)
		if type(instanceId) ~= "string" or type(quickSlot) ~= "number" then return end
		InventoryService.AssignQuickUse(player, instanceId, quickSlot)
	end)

	-- RequestStashTransfer: { direction, fromSlot, toSlot }
	-- direction = "toStash" | "fromStash"
	_requestStashTransfer.OnServerEvent:Connect(function(player: Player, direction: any, fromSlot: any, toSlot: any)
		if type(direction) ~= "string" or type(fromSlot) ~= "number" or type(toSlot) ~= "number" then return end
		if direction == "toStash" then
			InventoryService.TransferToStash(player, fromSlot, toSlot)
		elseif direction == "fromStash" then
			InventoryService.TransferFromStash(player, fromSlot, toSlot)
		end
	end)
end

return InventoryService
