--!strict
-- Settings: tabbed UI, inventory/loadout, keybinds, drag-drop, DataService sync.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local function getViewportSize(): Vector2
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local requestMove = remotes:WaitForChild("RequestMove") :: RemoteEvent
local requestUnequip = remotes:WaitForChild("RequestUnequip") :: RemoteEvent

local DataService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("DataService"))
local DataServiceClient = DataService.client
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ReactRoblox"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
local GetPresetKey = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("GetPresetKey"))
local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local AbilityPresetsBridge = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("AbilityPresetsBridge"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local KeybindConflictTooltipLayer = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("KeybindConflictTooltipLayer"))
local CursorManager = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("CursorManager"))
local SettingsShellApp = require(script.Parent:WaitForChild("SettingsShellApp"))
local ItemIconResolver = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("ItemIconResolver"))
local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindsClient = require(script.Parent.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))

local setKeybindsRemote = ReplicatedStorage:WaitForChild("KeybindRemotes"):WaitForChild("SetKeybinds") :: RemoteEvent

type ItemStack = InventoryTypes.ItemStack
type InventoryData = InventoryTypes.InventoryData
type EquipmentData = InventoryTypes.EquipmentData
type WeaponData = InventoryTypes.WeaponData
type LoadoutData = InventoryTypes.LoadoutData
type EquipmentSlotId = InventoryTypes.EquipmentSlotId
type InventorySyncPayload = InventoryTypes.InventorySyncPayload
type SerializedItem = InventoryTypes.SerializedItem
type AbilityPresetsData = InventoryTypes.AbilityPresetsData
type AbilitySlotData = InventoryTypes.AbilitySlotData
type SerializedPreset = InventoryTypes.SerializedPreset

type DragDescriptor = {
	container: "backpack" | "equipment" | "quickuse" | "stash" | "loot" | "ability_pool",
	index: number?,
	slotId: string?,
}

local function toServerContainer(c: "backpack" | "equipment" | "quickuse" | "stash" | "loot"): string
	if c == "backpack" then
		return "inventory"
	end
	return c
end

local visibleInventorySlotMap: { [number]: number }

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

local function presetToAbilities(preset: SerializedPreset?): { [number]: AbilitySlotData? }
	local out: { [number]: AbilitySlotData? } = {}
	if not preset then
		return out
	end
	for i = 1, 5 do
		local aid, isUlt = AbilityPresetSlotUtils.readSlot(preset, i)
		if aid then
			out[i] = { abilityId = aid, isUltimate = isUlt }
		end
	end
	return out
end

local function buildLoadoutData(payload: InventorySyncPayload, abilityPresets: AbilityPresetsData?): LoadoutData
	local invSlots: { [number]: ItemStack? } = {}
	local slotMap: { [number]: number } = {}
	local maxInvSlots = payload.inventory.maxSlots or 16
	for slot = 1, maxInvSlots do
		local item = (InventoryTypes :: any).getSlotItem(payload.inventory.slots, slot)
		invSlots[slot] = item and toItemStack(item :: SerializedItem) or nil
		slotMap[slot] = slot
	end
	visibleInventorySlotMap = slotMap
	local backpack: InventoryData = { slots = invSlots, equippedSlot = nil }

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

	local presets = abilityPresets or {}
	local weapons: { [number]: WeaponData? } = {}
	if payload.equipment.Weapon1 then
		local presetKey = GetPresetKey.GetPresetKeyForEquipmentSlot(payload.equipment, "Weapon1")
		local preset = presets[presetKey]
		weapons[1] = {
			itemId = payload.equipment.Weapon1.tid,
			abilities = presetToAbilities(preset),
			abilityPreset = if type(preset) == "table" then preset :: SerializedPreset else nil,
		}
	end
	if payload.equipment.Weapon2 then
		local presetKey = GetPresetKey.GetPresetKeyForEquipmentSlot(payload.equipment, "Weapon2")
		local preset = presets[presetKey]
		weapons[2] = {
			itemId = payload.equipment.Weapon2.tid,
			abilities = presetToAbilities(preset),
			abilityPreset = if type(preset) == "table" then preset :: SerializedPreset else nil,
		}
	end

	local quickSlots: { [number]: ItemStack? } = {}
	for slot = 1, 8 do
		local raw = (InventoryTypes :: any).getSlotItem(payload.quickUse.slots, slot)
		quickSlots[slot] = (type(raw) == "table" and raw.tid) and toItemStack(raw :: SerializedItem) or nil
	end

	return {
		backpack = backpack,
		equipment = equipment,
		weapons = weapons,
		quickUse = { slots = quickSlots },
	}
end

local ROWS = 4
local COLS = 4

local loadoutData: LoadoutData = {
	backpack = { slots = {}, equippedSlot = nil },
	equipment = nil,
	weapons = nil,
	quickUse = nil,
}
local latestPayload: InventorySyncPayload? = nil
visibleInventorySlotMap = {}
local settingsOpen = false
local dataReady = false
local inventoryGridRef = { current = nil :: Frame? }
local getEquipmentItem: (slotId: string) -> SerializedItem?
local getBackendInventorySlot: (visibleSlot: number?) -> number?

local activeTabId = "loadout"
local keybindsRevision = 0
local keybindListening = false
local cachedAbilityPresets: AbilityPresetsData = {}
local cachedUnlockedAbilities: { [string]: boolean } = {}

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local playerGui = localPlayer:WaitForChild("PlayerGui")

local settingsScreen = Instance.new("ScreenGui")
settingsScreen.Name = "SettingsScreen"
settingsScreen.ResetOnSpawn = false
settingsScreen.Enabled = false
settingsScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
settingsScreen.IgnoreGuiInset = true
settingsScreen.Parent = playerGui

DragDropManager.attachGhostLayer(settingsScreen)
KeybindConflictTooltipLayer.attach(settingsScreen)

local settingsRoot = ReactRoblox.createRoot(settingsScreen)

local function render()
	settingsRoot:render(React.createElement(SettingsShellApp, {
		activeTabId = activeTabId,
		onTabActivated = function(tabId: string)
			activeTabId = tabId
			render()
		end,
		viewportSize = getViewportSize(),
		loadoutData = loadoutData,
		loadoutRows = ROWS,
		loadoutCols = COLS,
		inventoryGridRef = inventoryGridRef,
		loadoutDragEnabled = settingsOpen and dataReady,
		onLoadoutDragStart = function(index: number)
			if not settingsOpen then
				return
			end

			local payload = latestPayload
			local backendSlot = getBackendInventorySlot(index)
			local item = payload and backendSlot and (InventoryTypes :: any).getSlotItem(payload.inventory.slots, backendSlot)
			if not item then
				return
			end

			DragDropManager.prepareDrag({
				container = "backpack",
				index = index,
			}, buildGhostVisual(item))
		end,
		onLoadoutEquipmentDragStart = function(slotId: EquipmentSlotId)
			if not settingsOpen then
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
		onLoadoutQuickUseDragStart = function(index: number)
			if not settingsOpen then
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
		onLoadoutEquipmentClick = function(slotId: EquipmentSlotId)
			local eq = loadoutData.equipment
			if eq and eq[slotId] then
				requestUnequip:FireServer(slotId)
			end
		end,
		onLoadoutAbilityClick = function(_weaponIndex: number, _abilityIndex: number) end,
		onLoadoutQuickUseClick = function(_index: number) end,
		onLoadoutMouseEnter = function(_i: number) end,
		onLoadoutMouseLeave = function(_i: number) end,
		keybindsRevision = keybindsRevision,
		setKeybindsRemote = setKeybindsRemote,
		onKeybindListeningChange = function(listening: boolean)
			keybindListening = listening
		end,
		settingsScreenGui = settingsScreen,
		abilityPresets = cachedAbilityPresets,
		unlockedAbilities = cachedUnlockedAbilities,
		abilityDragEnabled = settingsOpen and dataReady,
		onAbilityDragToPreset = function(abilityId: string, weaponTag: string, slotIndex: number)
			local requestSetPreset = remotes:FindFirstChild("RequestSetAbilityPreset") :: RemoteEvent?
			if requestSetPreset then
				requestSetPreset:FireServer(weaponTag, slotIndex, abilityId, false)
			end
		end,
	}))
end

local function dsGet(path: { string }): any?
	return DataServiceClient:get(path)
end

local function refreshLoadoutFromData()
	AbilityPresetsBridge.ensureInitialized()
	local inv = dsGet({ "inventory" })
	local eq = dsGet({ "equipment" })
	local qu = dsGet({ "quickUse" })
	local cur = dsGet({ "currency" })
	local ua = dsGet({ "unlockedAbilities" })
	cachedAbilityPresets = AbilityPresetsBridge.get() :: AbilityPresetsData
	if type(ua) == "table" then cachedUnlockedAbilities = ua end
	if type(inv) == "table" and type(eq) == "table" and type(qu) == "table" then
		local payload: InventorySyncPayload = {
			inventory = inv,
			equipment = eq,
			quickUse = qu,
			currency = if type(cur) == "table" then cur else { gold = 0 },
		}
		latestPayload = payload
		loadoutData = buildLoadoutData(payload, cachedAbilityPresets)
		render()
	end
end

task.spawn(function()
	local client = DataServiceClient
	if not (client :: any).networker then
		client:init()
	end
	client:waitForData()

	AbilityPresetsBridge.subscribe(function()
		cachedAbilityPresets = AbilityPresetsBridge.get() :: AbilityPresetsData
		if latestPayload then
			loadoutData = buildLoadoutData(latestPayload, cachedAbilityPresets)
		end
		render()
	end)
	AbilityPresetsBridge.ensureInitialized()

	dataReady = true
	refreshLoadoutFromData()

	for _, path in { { "inventory" }, { "equipment" }, { "quickUse" }, { "currency" }, { "unlockedAbilities" } } do
		local sig = client:getChangedSignal(path)
		if sig and type(sig.Connect) == "function" then
			sig:Connect(refreshLoadoutFromData)
		end
	end
end)

KeybindsClient.subscribe(function()
	keybindsRevision += 1
	render()
end)

local function onToggleLoadout(_actionName: string, inputState: Enum.UserInputState, _input: InputObject?)
	if inputState == Enum.UserInputState.Begin then
		if keybindListening then
			return Enum.ContextActionResult.Sink
		end

		local wasOpen = settingsOpen
		settingsOpen = not settingsOpen

		if settingsOpen and not wasOpen then
			activeTabId = "loadout"
		end

		if not settingsOpen then
			DragDropManager.cancelDrag()
			KeybindConflictTooltipLayer.hide()
		end
		settingsScreen.Enabled = settingsOpen
		CursorManager.setEnabledFor("Loadout", settingsOpen)
		render()
	end
	return Enum.ContextActionResult.Sink
end
KeybindsClient.bindAction(KeybindIds.ToggleLoadout, onToggleLoadout, {
	actionName = "ToggleLoadout",
})

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
	if not settingsOpen or not dataReady then
		return
	end

	if not target then
		if source.container == "equipment" and source.slotId then
			requestUnequip:FireServer(source.slotId)
		end
		return
	end

	if descriptorsMatch(source, target) then
		return
	end

	local fromSlot: number | string? = nil
	local toSlot: number | string? = nil
	if source.container == "backpack" then
		fromSlot = getBackendInventorySlot(source.index)
	elseif source.container == "equipment" then
		fromSlot = source.slotId
	elseif source.container == "quickuse" then
		fromSlot = source.index
	end

	-- Ability pool → preset slot drop
	if source.container == "ability_pool" and target.container == "equipment" and target.slotId then
		local slotIdStr = target.slotId :: string
		local weaponTag, indexStr = string.match(slotIdStr, "^(.*)_([^_]+)$")
		local slotIndex = if indexStr then tonumber(indexStr) else nil

		if weaponTag and slotIndex and source.slotId then
			local requestSetPreset = remotes:FindFirstChild("RequestSetAbilityPreset") :: RemoteEvent?
			if requestSetPreset then
				requestSetPreset:FireServer(weaponTag, slotIndex, source.slotId)
			end
		end
		return
	end
	if target.container == "backpack" then
		toSlot = getBackendInventorySlot(target.index)
	elseif target.container == "equipment" then
		toSlot = target.slotId
	elseif target.container == "quickuse" then
		toSlot = target.index
	end

	local canMove = (source.container == "backpack" or source.container == "equipment" or source.container == "quickuse")
		and (target.container == "backpack" or target.container == "equipment" or target.container == "quickuse")
		and fromSlot ~= nil and toSlot ~= nil

	if canMove then
		requestMove:FireServer(toServerContainer(source.container :: any), fromSlot, toServerContainer(target.container :: any), toSlot)
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed:boolean)
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

local lastViewportSize = getViewportSize()
RunService.Heartbeat:Connect(function()
	local current = getViewportSize()
	if current ~= lastViewportSize then
		lastViewportSize = current
		render()
	end
end)

render()
