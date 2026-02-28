--!strict
-- Right panel: quick-use slots (visual placeholders; not connected to radial selector yet)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local QuickUseSlot = require(script.Parent:WaitForChild("QuickUseSlot"))
type QuickUseData = InventoryTypes.QuickUseData

export type QuickUsePanelProps = {
	quickUseData: QuickUseData?,
	columnWidth: number?,
	onSlotClick: (index: number) -> (),
}

local QUICK_USE_SLOT_COUNT = LayoutConfig.QuickUse.SlotCount
local QUICK_COLS = LayoutConfig.QuickUse.Cols
local QUICK_ROWS = LayoutConfig.QuickUse.Rows

local P = ThemeConfig.Padding
local F = ThemeConfig.Font
local C = ThemeConfig.Colors

local function QuickUsePanel(props: QuickUsePanelProps)
	local quickUseData = props.quickUseData or { slots = {} }
	local slots = quickUseData.slots or {}
	local columnWidth = props.columnWidth or 250

	-- Compute slot size from column width: cols * slotSize + (cols-1) * padding = columnWidth
	local slotSize = math.floor((columnWidth - (QUICK_COLS - 1) * P.QuickUseSlot) / QUICK_COLS)
	local borderWidth = ThemeConfig.GradientBorder and ThemeConfig.GradientBorder.BorderWidth or 2
	local innerSlotSize = slotSize - 2 * borderWidth
	local gridWidth = QUICK_COLS * slotSize + (QUICK_COLS - 1) * P.QuickUseSlot
	local gridHeight = QUICK_ROWS * slotSize + (QUICK_ROWS - 1) * P.QuickUseSlot
	local panelHeight = F.SectionHeaderHeight + P.HeaderToContent + gridHeight

	local slotElements: { [string]: any } = {}
	for i = 1, QUICK_USE_SLOT_COUNT do
		local stack = slots[i]
		if stack == false then
			stack = nil
		end
		slotElements["Slot" .. i] = React.createElement(GradientBorder, {
			size = innerSlotSize,
			layoutOrder = i,
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
			Padding = UDim.new(0, P.HeaderToContent),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = React.createElement("TextLabel", {
			Name = "Header",
			Size = UDim2.fromOffset(gridWidth, F.SectionHeaderHeight),
			BackgroundTransparency = 1,
			Text = "QUICK USE",
			TextColor3 = C.Text.Primary,
			Font = F.Family,
			TextSize = F.SectionHeaderSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,
		}),
		SlotsGrid = React.createElement("Frame", {
			Name = "SlotsGrid",
			-- Explicit width so UIGridLayout wraps at 3 columns
			Size = UDim2.fromOffset(gridWidth, gridHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
		SlotsLayout = React.createElement("UIGridLayout", {
			CellSize = UDim2.fromOffset(slotSize, slotSize),
			CellPadding = UDim2.fromOffset(P.QuickUseSlot, P.QuickUseSlot),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = QUICK_COLS,
		}),
			Slot1 = slotElements["Slot1"],
			Slot2 = slotElements["Slot2"],
			Slot3 = slotElements["Slot3"],
			Slot4 = slotElements["Slot4"],
			Slot5 = slotElements["Slot5"],
			Slot6 = slotElements["Slot6"],
		}),
	})
end

return QuickUsePanel
