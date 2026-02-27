--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local InventorySlot = require(script.Parent:WaitForChild("InventorySlot"))

type ItemStack = InventoryTypes.ItemStack
type InventoryData = InventoryTypes.InventoryData

export type InventoryGridProps = {
	rows: number,
	cols: number,
	inventoryData: InventoryData,
	gridRef: { current: Frame? }?,
	onDragStart: (index: number) -> (),
	onEquip: (index: number) -> (),
	onMouseEnter: (index: number) -> (),
	onMouseLeave: (index: number) -> (),
}

local function InventoryGrid(props: InventoryGridProps)
	local rows = props.rows
	local cols = props.cols
	local inventoryData = props.inventoryData
	local slotCount = rows * cols

	local width = cols * 80 + (cols - 1) * 8 + 16
	local height = rows * 80 + (rows - 1) * 8 + 16

	local children: { [string | number]: React.Element } = {
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		GridLayout = React.createElement("UIGridLayout", {
			CellSize = UDim2.fromOffset(80, 80),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i = 1, slotCount do
		local stack = inventoryData.slots[i]
		if stack == false then
			stack = nil
		end
		local isActive = inventoryData.equippedSlot == i
		children["Slot" .. i] = React.createElement(InventorySlot, {
			index = i,
			stack = stack,
			active = isActive,
			onDragStart = function()
				props.onDragStart(i)
			end,
			onEquip = function()
				props.onEquip(i)
			end,
			onMouseEnter = function()
				props.onMouseEnter(i)
			end,
			onMouseLeave = function()
				props.onMouseLeave(i)
			end,
		})
	end

	return React.createElement("Frame", {
		Name = "Grid",
		ref = props.gridRef,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	}, children)
end

return InventoryGrid
