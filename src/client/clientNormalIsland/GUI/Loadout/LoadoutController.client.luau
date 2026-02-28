--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local function getViewportSize(): Vector2
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local updateInventory = remotes:WaitForChild("UpdateInventory")
local requestSwap = remotes:WaitForChild("RequestSwap")

-- Modules
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ReactRoblox"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local CursorManager = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("CursorManager"))
local LoadoutApp = require(script.Parent:WaitForChild("LoadoutApp"))

type InventoryData = InventoryTypes.InventoryData
type LoadoutData = InventoryTypes.LoadoutData

-- Config
local ROWS = 4
local COLS = 4

-- State
local loadoutData: LoadoutData = {
	inventory = { slots = {}, equippedSlot = nil },
	equipment = nil,
	weapons = nil,
	quickUse = nil,
}
local loadoutOpen = false
local dragStartSlot: number? = nil
local inventoryGridRef = { current = nil :: Frame? }

-- Create ScreenGuis
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local playerGui = localPlayer:WaitForChild("PlayerGui")

local loadoutScreen = Instance.new("ScreenGui")
loadoutScreen.Name = "LoadoutScreen"
loadoutScreen.ResetOnSpawn = false
loadoutScreen.Enabled = false
loadoutScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
loadoutScreen.Parent = playerGui

-- Mount React root
local loadoutRoot = ReactRoblox.createRoot(loadoutScreen)

local function renderLoadout()
	loadoutRoot:render(React.createElement(LoadoutApp, {
		loadoutData = loadoutData,
		rows = ROWS,
		cols = COLS,
		viewportSize = getViewportSize(),
		inventoryGridRef = inventoryGridRef,
		onDragStart = function(i: number)
			if loadoutOpen then
				dragStartSlot = i
			end
		end,
		onEquipmentClick = function(_slotId: InventoryTypes.EquipmentSlotId) end,
		onAbilityClick = function(_weaponIndex: number, _abilityIndex: number) end,
		onQuickUseClick = function(_index: number) end,
		onMouseEnter = function(_i: number) end,
		onMouseLeave = function(_i: number) end,
	}))
end

local function render()
	renderLoadout()
end

-- Handle inventory updates from server
updateInventory.OnClientEvent:Connect(function(newData: InventoryData)
	loadoutData = {
		inventory = newData,
		equipment = loadoutData.equipment,
		weapons = loadoutData.weapons,
		quickUse = loadoutData.quickUse,
	}
	render()
end)

-- Loadout toggle (Tab keybind)
local function onToggleLoadout(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject?)
	if inputState == Enum.UserInputState.Begin then
		loadoutOpen = not loadoutOpen
		loadoutScreen.Enabled = loadoutOpen
		CursorManager.setEnabledFor("Loadout", loadoutOpen)
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("ToggleLoadout", onToggleLoadout, false, Enum.KeyCode.Tab)

-- Global mouse release for completing drags (inventory grid only)
UserInputService.InputEnded:Connect(function(input: InputObject, _gpe: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragStartSlot then
		local grid = inventoryGridRef.current
		if grid then
			local mouse = localPlayer:GetMouse()
			local mousePos = Vector2.new(mouse.X, mouse.Y)

			local buttons: { ImageButton } = {}
			for _, child in ipairs(grid:GetChildren()) do
				if child:IsA("ImageButton") then
					table.insert(buttons, child)
				end
			end
			table.sort(buttons, function(a, b)
				return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
			end)

			for i, btn in ipairs(buttons) do
				local absPos = btn.AbsolutePosition
				local absSize = btn.AbsoluteSize
				if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
					and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y
				then
					if i ~= dragStartSlot then
						requestSwap:FireServer(dragStartSlot, i)
					end
					break
				end
			end
		end
		dragStartSlot = nil
	end
end)

-- Re-render when viewport changes (resize, etc.)
local lastViewportSize = getViewportSize()
RunService.Heartbeat:Connect(function()
	local current = getViewportSize()
	if current ~= lastViewportSize then
		lastViewportSize = current
		render()
	end
end)

-- Initial render
render()
