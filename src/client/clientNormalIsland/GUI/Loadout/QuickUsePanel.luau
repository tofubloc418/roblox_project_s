--!strict
-- Quick-use panel: grid of consumable slots with drag-drop (full-cell drop target).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local QuickUseSlot = require(script.Parent:WaitForChild("QuickUseSlot"))
type QuickUseData = InventoryTypes.QuickUseData

export type QuickUsePanelProps = {
	quickUseData: QuickUseData?,
	-- When set with columnWidth, quick slots match backpack: same slot size and padding; column count is derived from width.
	slotSize: number?,
	columnWidth: number?,
	scale: number?,
	dragEnabled: boolean?,
	onDragStart: (index: number) -> (),
	onSlotClick: (index: number) -> (),
}

local QUICK_USE_SLOT_COUNT = LayoutConfig.QuickUse.SlotCount

local P = ThemeConfig.Padding
local F = ThemeConfig.Font
local C = ThemeConfig.Colors

local function QuickUsePanel(props: QuickUsePanelProps)
	local quickUseData = props.quickUseData or { slots = {} }
	local slots = quickUseData.slots or {}
	local scale = props.scale or 1

	local scaledHeaderHeight = math.floor(F.SectionHeaderHeight * scale)
	local scaledHeaderSize = math.floor(F.SectionHeaderSize * scale)
	local scaledHeaderToContent = math.floor(P.HeaderToContent * scale)

	-- Use same slot size and padding as backpack when slotSize + columnWidth are provided; else fallback to fixed layout
	local useBackpackSizing = props.slotSize ~= nil and props.columnWidth ~= nil
	local slotSize: number
	local cellPadding: number
	local quickCols: number
	local quickRows: number
	if useBackpackSizing and props.slotSize and props.columnWidth then
		slotSize = props.slotSize
		cellPadding = math.floor(P.BackpackSlot * scale)
		-- Derive column count from width (same formula as backpack): width = cols*slotSize + (cols-1)*padding
		quickCols = math.max(1, math.floor((props.columnWidth + cellPadding) / (slotSize + cellPadding)))
		quickRows = math.ceil(QUICK_USE_SLOT_COUNT / quickCols)
	else
		cellPadding = math.floor(P.QuickUseSlot * scale)
		quickCols = LayoutConfig.QuickUse.Cols
		quickRows = LayoutConfig.QuickUse.Rows
		local columnWidth = props.columnWidth or 250
		slotSize = math.floor((columnWidth - (quickCols - 1) * cellPadding) / quickCols)
	end
	local borderWidth = ThemeConfig.GradientBorder and ThemeConfig.GradientBorder.BorderWidth or 2
	local innerSlotSize = slotSize - 2 * borderWidth
	local gridWidth = quickCols * slotSize + (quickCols - 1) * cellPadding
	local gridHeight = quickRows * slotSize + (quickRows - 1) * cellPadding
	local panelHeight = scaledHeaderHeight + scaledHeaderToContent + gridHeight

	-- One ref per slot: GradientBorder container (same area as gradient hover).
	local slotContainerRefs: { [number]: any } = {}
	for i = 1, QUICK_USE_SLOT_COUNT do
		slotContainerRefs[i] = React.useRef(nil :: GuiObject?)
	end

	local slotElements: { [string]: any } = {}
	for i = 1, QUICK_USE_SLOT_COUNT do
		local stack = slots[i]
		if stack == false then
			stack = nil
		end
		-- GradientBorder as grid child so drop target = same Frame that gets gradient hover.
		slotElements["Slot" .. i] = React.createElement(GradientBorder, {
			size = innerSlotSize,
			layoutOrder = i,
			containerRef = slotContainerRefs[i],
			onMouseEnter = function()
				DragDropManager.notifyHoverEnter({
					container = "quickuse",
					index = i,
				})
			end,
			onMouseLeave = function()
				DragDropManager.notifyHoverLeave({
					container = "quickuse",
					index = i,
				})
			end,
			onMouseButton1Down = function()
				props.onDragStart(i)
			end,
			onActivated = function()
				props.onSlotClick(i)
			end,
		}, {
			Slot = React.createElement(QuickUseSlot, {
				index = i,
				stack = stack,
				size = innerSlotSize,
				onClick = function()
					props.onSlotClick(i)
				end,
			}),
		})
	end

	return React.createElement("Frame", {
		Name = "QuickUsePanel",
		Size = UDim2.fromOffset(gridWidth, panelHeight),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
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
			Text = "QUICK USE",
			TextColor3 = C.Text.Primary,
			Font = F.Family,
			TextSize = scaledHeaderSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,
		}),
		SlotsGrid = React.createElement("Frame", {
			Name = "SlotsGrid",
			Size = UDim2.fromOffset(gridWidth, gridHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
		SlotsLayout = React.createElement("UIGridLayout", {
			CellSize = UDim2.fromOffset(slotSize, slotSize),
			CellPadding = UDim2.fromOffset(cellPadding, cellPadding),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = quickCols,
		}),
			Slot1 = slotElements["Slot1"],
			Slot2 = slotElements["Slot2"],
			Slot3 = slotElements["Slot3"],
			Slot4 = slotElements["Slot4"],
			Slot5 = slotElements["Slot5"],
			Slot6 = slotElements["Slot6"],
			Slot7 = slotElements["Slot7"],
			Slot8 = slotElements["Slot8"],
		}),
	})
end

return QuickUsePanel
