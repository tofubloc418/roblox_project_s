--!strict
-- LoadoutController: Tab loadout UI, DataService sync, and drag-drop → RequestMove / RequestUnequip.

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local UserInputService     = game:GetService("UserInputService")
local StarterGui           = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local RunService           = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local function getViewportSize(): Vector2
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

local remotes          = ReplicatedStorage:WaitForChild("InventoryRemotes")
local requestMove      = remotes:WaitForChild("RequestMove")      :: RemoteEvent
local requestClearQuick = remotes:WaitForChild("RequestClearQuick") :: RemoteEvent
local requestUnequip   = remotes:WaitForChild("RequestUnequip")   :: RemoteEvent

-- ── Modules ───────────────────────────────────────────────────────────────────
local DataService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("DataService"))
local DataServiceClient = DataService.client
local React         = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ReactRoblox   = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ReactRoblox"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local CursorManager = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("CursorManager"))
local LoadoutApp    = require(script.Parent:WaitForChild("LoadoutApp"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))

type ItemStack         = InventoryTypes.ItemStack
type InventoryData     = InventoryTypes.InventoryData
type EquipmentData    = InventoryTypes.EquipmentData
type WeaponData        = InventoryTypes.WeaponData
type LoadoutData       = InventoryTypes.LoadoutData
type EquipmentSlotId   = InventoryTypes.EquipmentSlotId
type InventorySyncPayload = InventoryTypes.InventorySyncPayload
type SerializedItem    = InventoryTypes.SerializedItem

type DragDescriptor = {
	container: "inventory" | "equipment" | "quickuse" | "stash" | "loot",
	index: number?,
	slotId: string?,
}

local visibleInventorySlotMap: { [number]: number }

-- ── Payload → LoadoutData (for React panels) ───────────────────────────────────

local function toItemStack(item: SerializedItem): ItemStack
	return { itemId = item.tid, count = item.cnt or 1, maxStack = 1 }
end

local function buildGhostVisual(item: SerializedItem): { imageId: string, labelText: string, stackText: string }
	local iconId, displayName = ItemIconResolver.getIconForItem(item.tid)
	local stackCount = item.cnt or 1

	return {
		imageId = iconId or "",
		labelText = if iconId then "" else (displayName or item.tid),
		stackText = if stackCount > 1 then tostring(stackCount) else "",
	}
end

local function buildLoadoutData(payload: InventorySyncPayload): LoadoutData
	-- Inventory: 1:1 grid (position i = backend slot i). Use getSlotItem so string keys from DataStore work.
	local invSlots: { [number]: ItemStack? } = {}
	local slotMap: { [number]: number } = {}
	local maxInvSlots = payload.inventory.maxSlots or 16
	for slot = 1, maxInvSlots do
		local item = (InventoryTypes :: any).getSlotItem(payload.inventory.slots, slot)
		invSlots[slot] = item and toItemStack(item :: SerializedItem) or nil
		slotMap[slot] = slot
	end
	visibleInventorySlotMap = slotMap
	local inventory: InventoryData = { slots = invSlots, equippedSlot = nil }

	local equipment: EquipmentData = {}
	if payload.equipment.Backpack then
		equipment["Backpack" :: EquipmentSlotId] = toItemStack(payload.equipment.Backpack)
	end
	if payload.equipment.Armor then
		equipment["Armor" :: EquipmentSlotId] = toItemStack(payload.equipment.Armor)
	end
	if payload.equipment.Weapon1 then
		equipment["Weapon1" :: EquipmentSlotId] = toItemStack(payload.equipment.Weapon1)
	end
	if payload.equipment.Weapon2 then
		equipment["Weapon2" :: EquipmentSlotId] = toItemStack(payload.equipment.Weapon2)
	end

	local weapons: { [number]: WeaponData? } = {}
	if payload.equipment.Weapon1 then
		weapons[1] = { itemId = payload.equipment.Weapon1.tid, abilities = {} }
	end
	if payload.equipment.Weapon2 then
		weapons[2] = { itemId = payload.equipment.Weapon2.tid, abilities = {} }
	end

	local quickSlots: { [number]: ItemStack? } = {}
	for slot = 1, 8 do
		local raw = (InventoryTypes :: any).getSlotItem(payload.quickUse.slots, slot)
		quickSlots[slot] = (type(raw) == "table" and raw.tid) and toItemStack(raw :: SerializedItem) or nil
	end

	return {
		inventory = inventory,
		equipment = equipment,
		weapons   = weapons,
		quickUse  = { slots = quickSlots },
	}
end

-- ── Config ────────────────────────────────────────────────────────────────────
local ROWS = 4
local COLS = 4

-- ── State ─────────────────────────────────────────────────────────────────────
local loadoutData: LoadoutData = {
	inventory = { slots = {}, equippedSlot = nil },
	equipment = nil,
	weapons   = nil,
	quickUse  = nil,
}
local latestPayload: InventorySyncPayload? = nil
visibleInventorySlotMap = {}
local loadoutOpen   = false
local dataReady = false
local inventoryGridRef = { current = nil :: Frame? }
local getEquipmentItem: (slotId: string) -> SerializedItem?
local getBackendInventorySlot: (visibleSlot: number?) -> number?

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,    false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,  false)

local playerGui = localPlayer:WaitForChild("PlayerGui")

local loadoutScreen = Instance.new("ScreenGui")
loadoutScreen.Name             = "LoadoutScreen"
loadoutScreen.ResetOnSpawn     = false
loadoutScreen.Enabled          = false
loadoutScreen.ZIndexBehavior   = Enum.ZIndexBehavior.Global
loadoutScreen.IgnoreGuiInset   = true
loadoutScreen.Parent           = playerGui

DragDropManager.attachGhostLayer(loadoutScreen)

local loadoutRoot = ReactRoblox.createRoot(loadoutScreen)

-- ── Render ────────────────────────────────────────────────────────────────────
local function render()
	loadoutRoot:render(React.createElement(LoadoutApp, {
		loadoutData      = loadoutData,
		rows             = ROWS,
		cols             = COLS,
		viewportSize     = getViewportSize(),
		inventoryGridRef = inventoryGridRef,
		dragEnabled      = loadoutOpen and dataReady,

		onDragStart = function(index: number)
			if not loadoutOpen then
				return
			end

			local payload = latestPayload
			local backendSlot = getBackendInventorySlot(index)
			local item = payload and backendSlot and (InventoryTypes :: any).getSlotItem(payload.inventory.slots, backendSlot)
			if not item then
				return
			end

			DragDropManager.prepareDrag({
				container = "inventory",
				index = index,
			}, buildGhostVisual(item))
		end,

		onEquipmentDragStart = function(slotId: EquipmentSlotId)
			if not loadoutOpen then
				return
			end

			local item = getEquipmentItem(slotId)
			if not item then
				return
			end

			DragDropManager.prepareDrag({
				container = "equipment",
				slotId = slotId,
			}, buildGhostVisual(item))
		end,

		onQuickUseDragStart = function(index: number)
			if not loadoutOpen then
				return
			end

			local payload = latestPayload
			if not payload then
				return
			end

			local raw = (InventoryTypes :: any).getSlotItem(payload.quickUse.slots, index)
			if type(raw) ~= "table" or not raw.tid then
				return
			end

			local item = raw :: SerializedItem
			DragDropManager.prepareDrag({
				container = "quickuse",
				index = index,
			}, buildGhostVisual(item))
		end,

		onEquipmentClick = function(slotId: EquipmentSlotId)
			local eq = loadoutData.equipment
			if eq and eq[slotId] then
				requestUnequip:FireServer(slotId)
			end
		end,

		onAbilityClick  = function(_weaponIndex: number, _abilityIndex: number) end,
		onQuickUseClick = function(_index: number) end,
		onMouseEnter    = function(_i: number) end,
		onMouseLeave    = function(_i: number) end,
	}))
end

-- ── DataService: initial state + updates (replication is automatic) ────────────
local function dsGet(path: { string }): any?
	local client = DataServiceClient
	return client:get(path)
end

local function refreshLoadoutFromData()
	local inv = dsGet({ "inventory" })
	local eq  = dsGet({ "equipment" })
	local qu  = dsGet({ "quickUse" })
	local cur = dsGet({ "currency" })
	if type(inv) == "table" and type(eq) == "table" and type(qu) == "table" then
		local payload: InventorySyncPayload = {
			inventory = inv,
			equipment = eq,
			quickUse  = qu,
			currency  = type(cur) == "table" and cur or { gold = 0 },
		}
		latestPayload = payload
		loadoutData = buildLoadoutData(payload)
		render()
	end
end

task.spawn(function()
	local client = DataServiceClient
	if not (client :: any).networker then
		client:init()
	end
	client:waitForData()
	dataReady = true
	refreshLoadoutFromData()
	
	for _, path in ipairs({ { "inventory" }, { "equipment" }, { "quickUse" }, { "currency" } }) do
		local sig = client:getChangedSignal(path)
		if sig and type(sig.Connect) == "function" then
			sig:Connect(refreshLoadoutFromData)
		end
	end
end)

-- ── Loadout toggle (Tab) ──────────────────────────────────────────────────────
local function onToggleLoadout(_actionName: string, inputState: Enum.UserInputState, _input: InputObject?)
	if inputState == Enum.UserInputState.Begin then
		loadoutOpen            = not loadoutOpen
		if not loadoutOpen then
			DragDropManager.cancelDrag()
		end
		loadoutScreen.Enabled  = loadoutOpen
		CursorManager.setEnabledFor("Loadout", loadoutOpen)
		render()
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("ToggleLoadout", onToggleLoadout, false, Enum.KeyCode.Tab)

function getEquipmentItem(slotId: string): SerializedItem?
	local payload = latestPayload
	if not payload then
		return nil
	end
	return (payload.equipment :: any)[slotId]
end

function getBackendInventorySlot(visibleSlot: number?): number?
	if visibleSlot == nil then
		return nil
	end

	return visibleInventorySlotMap[visibleSlot]
end

local function getDraggedInstanceId(source: DragDescriptor): string?
	local payload = latestPayload
	if not payload then
		return nil
	end

	if source.container == "inventory" and source.index then
		local backendSlot = getBackendInventorySlot(source.index)
		if backendSlot == nil then
			return nil
		end

		local item = (InventoryTypes :: any).getSlotItem(payload.inventory.slots, backendSlot)
		return item and item.iid or nil
	end

	if source.container == "equipment" and source.slotId then
		local item = getEquipmentItem(source.slotId)
		return item and item.iid or nil
	end

	if source.container == "quickuse" and source.index then
		local item = (InventoryTypes :: any).getSlotItem(payload.quickUse.slots, source.index)
		return (type(item) == "table" and item.iid) or nil
	end

	return nil
end

local function descriptorsMatch(source: DragDescriptor, target: DragDescriptor): boolean
	if source.container ~= target.container then
		return false
	end

	if source.index ~= nil and target.index ~= nil then
		return source.index == target.index
	end

	if source.slotId ~= nil and target.slotId ~= nil then
		return source.slotId == target.slotId
	end

	return false
end

DragDropManager.subscribeToDrop(function(source: DragDescriptor, target: DragDescriptor?, _pointerPosition: Vector2)
	if not loadoutOpen or not dataReady then
		return
	end

	if not target then
		if source.container == "equipment" and source.slotId then
			requestUnequip:FireServer(source.slotId)
		end
		-- Quick-use dropped outside any slot: no-op (item stays in place).
		return
	end

	if descriptorsMatch(source, target) then
		return
	end

	local fromSlot: number | string? = nil
	local toSlot: number | string? = nil
	if source.container == "inventory" then
		fromSlot = getBackendInventorySlot(source.index)
	elseif source.container == "equipment" then
		fromSlot = source.slotId
	elseif source.container == "quickuse" then
		fromSlot = source.index
	end
	if target.container == "inventory" then
		toSlot = getBackendInventorySlot(target.index)
	elseif target.container == "equipment" then
		toSlot = target.slotId
	elseif target.container == "quickuse" then
		toSlot = target.index
	end

	local canMove = (source.container == "inventory" or source.container == "equipment" or source.container == "quickuse")
		and (target.container == "inventory" or target.container == "equipment" or target.container == "quickuse")
		and fromSlot ~= nil and toSlot ~= nil

	if canMove then
		requestMove:FireServer(source.container, fromSlot, target.container, toSlot)
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape then
		DragDropManager.cancelDrag()
	end
end)

localPlayer.CharacterAdded:Connect(function()
	DragDropManager.cancelDrag()
end)

-- ── Viewport resize ───────────────────────────────────────────────────────────
local lastViewportSize = getViewportSize()
RunService.Heartbeat:Connect(function()
	local current = getViewportSize()
	if current ~= lastViewportSize then
		lastViewportSize = current
		render()
	end
end)

-- ── Initial render ────────────────────────────────────────────────────────────
render()
