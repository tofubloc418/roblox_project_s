--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")

local localPlayer = Players.LocalPlayer

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local updateInventory = remotes:WaitForChild("UpdateInventory")
local requestEquip = remotes:WaitForChild("RequestEquip")
local requestSwap = remotes:WaitForChild("RequestSwap")

-- Modules
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ReactRoblox"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local CursorManager = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("CursorManager"))
local InventoryApp = require(script.Parent:WaitForChild("InventoryApp"))
local Hotbar = require(script.Parent:WaitForChild("Hotbar"))

type InventoryData = InventoryTypes.InventoryData

-- Config
local ROWS = 3
local COLS = 5
local SLOT_COUNT = ROWS * COLS

-- State
local inventoryData: InventoryData = {
	slots = {},
	equippedSlot = nil,
}
local inventoryOpen = false
local dragStartSlot: number? = nil
local gridRef = { current = nil :: Frame? }

-- Create ScreenGuis
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local playerGui = localPlayer:WaitForChild("PlayerGui")

local inventoryScreen = Instance.new("ScreenGui")
inventoryScreen.Name = "InventoryScreen"
inventoryScreen.ResetOnSpawn = false
inventoryScreen.Enabled = false
inventoryScreen.Parent = playerGui

local hotbarScreen = Instance.new("ScreenGui")
hotbarScreen.Name = "Hotbar"
hotbarScreen.ResetOnSpawn = false
hotbarScreen.Enabled = true
hotbarScreen.Parent = playerGui

-- Mount React roots
local inventoryRoot = ReactRoblox.createRoot(inventoryScreen)
local hotbarRoot = ReactRoblox.createRoot(hotbarScreen)

local function renderInventory()
	inventoryRoot:render(React.createElement(InventoryApp, {
		inventoryData = inventoryData,
		rows = ROWS,
		cols = COLS,
		gridRef = gridRef,
		onDragStart = function(i: number)
			if inventoryOpen then
				dragStartSlot = i
			end
		end,
		onEquip = function(i: number)
			if inventoryOpen then
				requestEquip:FireServer(i)
			end
		end,
		onMouseEnter = function(_i: number) end,
		onMouseLeave = function(_i: number) end,
	}))
end

local function renderHotbar()
	hotbarRoot:render(React.createElement(Hotbar, {
		cols = COLS,
		inventoryData = inventoryData,
		onEquip = function(i: number)
			requestEquip:FireServer(i)
		end,
	}))
end

local function render()
	renderInventory()
	renderHotbar()
end

-- Handle inventory updates from server
updateInventory.OnClientEvent:Connect(function(newData: InventoryData)
	inventoryData = newData
	render()
end)

-- Inventory toggle
local function onToggleInventory(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject?)
	if inputState == Enum.UserInputState.Begin then
		inventoryOpen = not inventoryOpen
		inventoryScreen.Enabled = inventoryOpen
		CursorManager.setEnabledFor("Inventory", inventoryOpen)
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("ToggleInventory", onToggleInventory, false, Enum.KeyCode.Tab)

-- Hotbar keys
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end

	if input.KeyCode.Value >= Enum.KeyCode.One.Value and input.KeyCode.Value <= Enum.KeyCode.Five.Value then
		local slotIndex = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
		requestEquip:FireServer(slotIndex)
	end
end)

-- Global mouse release for completing drags
UserInputService.InputEnded:Connect(function(input: InputObject, _gpe: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragStartSlot then
		local grid = gridRef.current
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

-- Initial render
render()
