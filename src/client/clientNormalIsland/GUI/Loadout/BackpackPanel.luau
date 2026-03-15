--!strict
-- Center panel: backpack grid connected to server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local InventorySlot = require(script.Parent:WaitForChild("InventorySlot"))
type InventoryData = InventoryTypes.InventoryData
type ItemStack = InventoryTypes.ItemStack

export type BackpackPanelProps = {
	backpackData: InventoryData,
	rows: number,
	cols: number,
	columnWidth: number?,
	scale: number?,
	gridRef: { current: Frame? }?,
	dragEnabled: boolean?,
	onDragStart: (index: number) -> (),
	onMouseEnter: (index: number) -> (),
	onMouseLeave: (index: number) -> (),
}

local P = ThemeConfig.Padding
local F = ThemeConfig.Font
local C = ThemeConfig.Colors

local function BackpackPanel(props: BackpackPanelProps)
	local rows = props.rows
	local cols = props.cols
	local columnWidth = props.columnWidth or 400
	local scale = props.scale or 1
	local backpackData = props.backpackData
	local slotCount = rows * cols

	local scaledBackpackSlot = math.floor(P.BackpackSlot * scale)
	local scaledHeaderHeight = math.floor(F.SectionHeaderHeight * scale)
	local scaledHeaderSize = math.floor(F.SectionHeaderSize * scale)
	local scaledHeaderToContent = math.floor(P.HeaderToContent * scale)

	-- Compute slot size from column width: cols * slotSize + (cols-1) * padding = columnWidth
	local slotSize = math.floor((columnWidth - (cols - 1) * scaledBackpackSlot) / cols)
	local gridWidth = cols * slotSize + (cols - 1) * scaledBackpackSlot
	local gridHeight = rows * slotSize + (rows - 1) * scaledBackpackSlot
	local panelHeight = scaledHeaderHeight + scaledHeaderToContent + gridHeight

	local borderWidth = ThemeConfig.GradientBorder and ThemeConfig.GradientBorder.BorderWidth or 2
	local innerSlotSize = slotSize - 2 * borderWidth

	-- One ref per slot: same GuiObject as gradient border container (also used for drag-hover tracking).
	local slotContainerRefs: { [number]: any } = {}
	for i = 1, slotCount do
		slotContainerRefs[i] = React.useRef(nil :: GuiObject?)
	end

	local slots: { [string]: any } = {}
	for i = 1, slotCount do
		local raw = backpackData.slots[i]
		local stack: ItemStack? = if raw and typeof(raw) == "table" then raw :: ItemStack else nil
		local isActive = backpackData.equippedSlot == i
		slots["Slot" .. i] = React.createElement(GradientBorder, {
			size = innerSlotSize,
			layoutOrder = i,
			containerRef = slotContainerRefs[i],
			onMouseEnter = function()
				props.onMouseEnter(i)
				DragDropManager.notifyHoverEnter({
					container = "backpack",
					index = i,
				})
			end,
			onMouseLeave = function()
				props.onMouseLeave(i)
				DragDropManager.notifyHoverLeave({
					container = "backpack",
					index = i,
				})
			end,
			onMouseButton1Down = function()
				props.onDragStart(i)
			end,
		}, {
			Slot = React.createElement(InventorySlot, {
				index = i,
				stack = stack,
				active = isActive,
				size = innerSlotSize,
				dragEnabled = props.dragEnabled,
				onDragStart = function()
					props.onDragStart(i)
				end,
				onMouseEnter = function()
					props.onMouseEnter(i)
				end,
				onMouseLeave = function()
					props.onMouseLeave(i)
				end,
			}),
		})
	end

	return React.createElement("Frame", {
		Name = "BackpackPanel",
		Size = UDim2.fromOffset(gridWidth, panelHeight),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, scaledHeaderToContent),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = React.createElement("TextLabel", {
			Name = "Header",
			Size = UDim2.fromOffset(gridWidth, scaledHeaderHeight),
			BackgroundTransparency = 1,
			Text = "BACKPACK",
			TextColor3 = C.Text.Primary,
			Font = F.Family,
			TextSize = scaledHeaderSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,
		}),
		Grid = React.createElement("Frame", {
			Name = "Grid",
			-- Explicit width so UIGridLayout wraps at the correct column count
			Size = UDim2.fromOffset(gridWidth, gridHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ref = props.gridRef,
		}, {
			GridLayout = React.createElement("UIGridLayout", {
				CellSize = UDim2.fromOffset(slotSize, slotSize),
				CellPadding = UDim2.fromOffset(scaledBackpackSlot, scaledBackpackSlot),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirectionMaxCells = cols,
			}),
			Slot1 = slots["Slot1"],
			Slot2 = slots["Slot2"],
			Slot3 = slots["Slot3"],
			Slot4 = slots["Slot4"],
			Slot5 = slots["Slot5"],
			Slot6 = slots["Slot6"],
			Slot7 = slots["Slot7"],
			Slot8 = slots["Slot8"],
			Slot9 = slots["Slot9"],
			Slot10 = slots["Slot10"],
			Slot11 = slots["Slot11"],
			Slot12 = slots["Slot12"],
			Slot13 = slots["Slot13"],
			Slot14 = slots["Slot14"],
			Slot15 = slots["Slot15"],
			Slot16 = slots["Slot16"],
		}),
	})
end

return BackpackPanel
