local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")

local localPlayer = Players.LocalPlayer

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local updateInventory = remotes:WaitForChild("UpdateInventory")
local requestEquip = remotes:WaitForChild("RequestEquip")
local requestSwap = remotes:WaitForChild("RequestSwap")

-- Types
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
type ItemStack = InventoryTypes.ItemStack
type InventoryData = InventoryTypes.InventoryData

-- UI Module
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI"))

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

-- Build UI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local screen, hotbarGui = InventoryUI.createScreens()
local grid = InventoryUI.buildInventoryGrid(screen, ROWS, COLS)
local hotbar = InventoryUI.buildHotbar(hotbarGui, COLS)

local slotButtons: { ImageButton } = {}
for i = 1, SLOT_COUNT do
	slotButtons[i] = InventoryUI.createSlot(grid, i)
end

local hotbarButtons: { ImageButton } = {}
for i = 1, COLS do
	hotbarButtons[i] = InventoryUI.createSlot(hotbar, i)
end

-- Render function
local function render()
	for i = 1, SLOT_COUNT do
		local stack = inventoryData.slots[i]
		-- Convert false to nil for empty slots
		if stack == false then
			stack = nil
		end
		local isActive = inventoryData.equippedSlot == i
		InventoryUI.renderSlot(slotButtons[i], stack, isActive)
	end
	
	-- Render hotbar (first 5 slots)
	for i = 1, COLS do
		local stack = inventoryData.slots[i]
		-- Convert false to nil for empty slots
		if stack == false then
			stack = nil
		end
		local isActive = inventoryData.equippedSlot == i
		InventoryUI.renderSlot(hotbarButtons[i], stack, isActive)
	end
end

-- Handle inventory updates from server
updateInventory.OnClientEvent:Connect(function(newData: InventoryData)
	inventoryData = newData
	render()
end)

-- Inventory toggle
local function onToggleInventory(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		inventoryOpen = not inventoryOpen
		screen.Enabled = inventoryOpen
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("ToggleInventory", onToggleInventory, false, Enum.KeyCode.Tab)

-- Hotbar keys
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	
	if input.KeyCode.Value >= Enum.KeyCode.One.Value and input.KeyCode.Value <= Enum.KeyCode.Five.Value then
		local slotIndex = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
		requestEquip:FireServer(slotIndex)
	end
end)

-- Slot interactions
for i = 1, SLOT_COUNT do
	local btn = slotButtons[i]
	
	btn.MouseButton1Down:Connect(function()
		if not inventoryOpen then return end
		dragStartSlot = i
	end)
	
	btn.MouseEnter:Connect(function()
		if not inventoryOpen then return end
		if dragStartSlot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			-- User is dragging over this slot
			btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end
	end)
	
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end)
	
	btn.MouseButton2Click:Connect(function()
		if not inventoryOpen then return end
		requestEquip:FireServer(i)
	end)
end

-- Global mouse release for completing drags
UserInputService.InputEnded:Connect(function(input: InputObject, gpe: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragStartSlot then
		-- Find which slot the mouse is over
		local mouse = localPlayer:GetMouse()
		for i = 1, SLOT_COUNT do
			local btn = slotButtons[i]
			local absPos = btn.AbsolutePosition
			local absSize = btn.AbsoluteSize
			local mousePos = Vector2.new(mouse.X, mouse.Y)
			
			if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
			   mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
				-- Mouse is over this slot
				if i ~= dragStartSlot then
	
					requestSwap:FireServer(dragStartSlot, i)
				end
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				break
			end
		end
		dragStartSlot = nil
	end
end)

-- Initial render
render()
