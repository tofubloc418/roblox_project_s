--!strict

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

-- ── Remotes (request-only; state comes from DataService) ───────────────────────
local remotes          = ReplicatedStorage:WaitForChild("InventoryRemotes")
local requestMove      = remotes:WaitForChild("RequestMove")      :: RemoteEvent
local _requestEquip    = remotes:WaitForChild("RequestEquip")     :: RemoteEvent
local requestUnequip   = remotes:WaitForChild("RequestUnequip")   :: RemoteEvent

-- ── Modules ───────────────────────────────────────────────────────────────────
local DataService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("DataService"))
local DataServiceClient = DataService.client
local React         = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ReactRoblox   = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ReactRoblox"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local CursorManager = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("CursorManager"))
local LoadoutApp    = require(script.Parent:WaitForChild("LoadoutApp"))

-- UI-layer types (unchanged from original components).
type ItemStack      = InventoryTypes.ItemStack
type InventoryData  = InventoryTypes.InventoryData
type EquipmentData  = InventoryTypes.EquipmentData
type WeaponData     = InventoryTypes.WeaponData
type LoadoutData    = InventoryTypes.LoadoutData
type EquipmentSlotId = InventoryTypes.EquipmentSlotId

-- Persistence-layer types (server payload).
type InventorySyncPayload = InventoryTypes.InventorySyncPayload
type SerializedItem       = InventoryTypes.SerializedItem

-- ── Conversion: DataService payload → UI-layer LoadoutData ─────────────────────
-- The React components (LoadoutApp, InventoryPanel, EquipmentPanel) expect
-- the old ItemStack format.  This function converts when we read from DataService.

local function toItemStack(item: SerializedItem): ItemStack
	return { itemId = item.tid, count = item.cnt or 1, maxStack = 1 }
end

local function buildLoadoutData(payload: InventorySyncPayload): LoadoutData
	-- Inventory slots
	local invSlots: { [number]: ItemStack? } = {}
	for slot, item in pairs(payload.inventory.slots) do
		if item then invSlots[slot] = toItemStack(item) end
	end
	local inventory: InventoryData = { slots = invSlots, equippedSlot = nil }

	-- Equipment slots (PascalCase keys match EquipmentSlotId)
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

	-- Weapon cards for EquipmentPanel (itemId + empty abilities for now)
	local weapons: { [number]: WeaponData? } = {}
	if payload.equipment.Weapon1 then
		weapons[1] = { itemId = payload.equipment.Weapon1.tid, abilities = {} }
	end
	if payload.equipment.Weapon2 then
		weapons[2] = { itemId = payload.equipment.Weapon2.tid, abilities = {} }
	end

	-- Quick-use: resolve instanceId references back to ItemStack.
	-- An instanceId in quickUse.slots may point to an item in inventory or stash.
	-- We only have inventory data on the client; stash items show a fallback label.
	local quickSlots: { [number]: ItemStack? } = {}
	for slot, instanceId in pairs(payload.quickUse.slots) do
		if instanceId then
			local found = false
			for _, item in pairs(payload.inventory.slots) do
				if item and item.iid == instanceId then
					quickSlots[slot] = toItemStack(item)
					found = true
					break
				end
			end
			if not found then
				-- Item may be in stash (not sent to client); use instanceId as label.
				quickSlots[slot] = { itemId = instanceId, count = 1, maxStack = 1 }
			end
		end
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
local loadoutOpen   = false
local dragStartSlot: number? = nil
local inventoryGridRef = { current = nil :: Frame? }

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

local loadoutRoot = ReactRoblox.createRoot(loadoutScreen)

-- ── Render ────────────────────────────────────────────────────────────────────
local function render()
	loadoutRoot:render(React.createElement(LoadoutApp, {
		loadoutData      = loadoutData,
		rows             = ROWS,
		cols             = COLS,
		viewportSize     = getViewportSize(),
		inventoryGridRef = inventoryGridRef,

		onDragStart = function(i: number)
			if loadoutOpen then dragStartSlot = i end
		end,

		onEquipmentClick = function(slotId: EquipmentSlotId)
			-- Server-side unequip: send RequestUnequip if slot is filled.
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
		loadoutScreen.Enabled  = loadoutOpen
		CursorManager.setEnabledFor("Loadout", loadoutOpen)
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("ToggleLoadout", onToggleLoadout, false, Enum.KeyCode.Tab)

-- ── Drag-to-move items ────────────────────────────────────────────────────────
UserInputService.InputEnded:Connect(function(input: InputObject, _gpe: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragStartSlot then
		local grid = inventoryGridRef.current
		if grid then
			local mouse    = localPlayer:GetMouse()
			local mousePos = Vector2.new(mouse.X, mouse.Y)

			local buttons: { ImageButton } = {}
			for _, child in ipairs(grid:GetChildren()) do
				if child:IsA("ImageButton") then table.insert(buttons, child) end
			end
			table.sort(buttons, function(a, b)
				return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
			end)

			for i, btn in ipairs(buttons) do
				local absPos  = btn.AbsolutePosition
				local absSize = btn.AbsoluteSize
				if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
					and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y
				then
					if i ~= dragStartSlot then
						-- Tell server to move slot dragStartSlot → slot i in inventory.
						requestMove:FireServer("inventory", dragStartSlot, "inventory", i)
					end
					break
				end
			end
		end
		dragStartSlot = nil
	end
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
