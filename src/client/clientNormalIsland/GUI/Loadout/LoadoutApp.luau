--!strict
-- Root loadout component: dark overlay + 3-panel horizontal layout

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local EquipmentPanel = require(script.Parent:WaitForChild("EquipmentPanel"))
local BackpackPanel = require(script.Parent:WaitForChild("BackpackPanel"))
local QuickUsePanel = require(script.Parent:WaitForChild("QuickUsePanel"))
type LoadoutData = InventoryTypes.LoadoutData
type EquipmentSlotId = InventoryTypes.EquipmentSlotId

export type LoadoutAppProps = {
	loadoutData: LoadoutData,
	rows: number,
	cols: number,
	viewportSize: Vector2?,
	inventoryGridRef: { current: Frame? }?,
	dragEnabled: boolean?,
	onDragStart: (index: number) -> (),
	onEquipmentDragStart: (slotId: EquipmentSlotId) -> (),
	onQuickUseDragStart: (index: number) -> (),
	onEquipmentClick: (slotId: EquipmentSlotId) -> (),
	onAbilityClick: (weaponIndex: number, abilityIndex: number) -> (),
	onQuickUseClick: (index: number) -> (),
	onMouseEnter: (index: number) -> (),
	onMouseLeave: (index: number) -> (),
}

local P = ThemeConfig.Padding
local C = ThemeConfig.Colors
local F = ThemeConfig.Font
local R = ThemeConfig.CornerRadius
local L = ThemeConfig.Loadout
local COLUMN_RATIO_TOTAL = L.ColumnRatioEquip + L.ColumnRatioBackpack + L.ColumnRatioQuick

local function LoadoutApp(props: LoadoutAppProps)
	local loadoutData = props.loadoutData
	local viewportSize = props.viewportSize or LayoutConfig.DefaultViewportSize
	local _rows = props.rows
	local cols = props.cols

	-- Scale factor from viewport (reference from config); clamp to avoid extreme sizes
	local refShort = L.ReferenceShortEdge or 1080
	local scale = math.clamp(math.min(viewportSize.X, viewportSize.Y) / refShort, 0.5, 2)

	-- Scaled padding and font for this screen
	local scaledP = {
		OuterFrameHorizontal = math.floor(P.OuterFrameHorizontal * scale),
		OuterFrameVertical = math.floor(P.OuterFrameVertical * scale),
		TitleToContent = math.floor(P.TitleToContent * scale),
		ColumnGap = math.floor(P.ColumnGap * scale),
		BackpackSlot = math.floor(P.BackpackSlot * scale),
	}
	local scaledF = {
		TitleHeight = math.floor(F.TitleHeight * scale),
		TitleSize = math.floor(F.TitleSize * scale),
	}

	-- Outer frame content width (after UIPadding)
	local contentWidth = viewportSize.X * L.WidthScale - scaledP.OuterFrameHorizontal * 2
	-- Only padding between the 3 columns (2 gaps); left/right come from outer frame's UIPadding
	local totalColumnPadding = scaledP.ColumnGap * 2
	local availableForColumns = contentWidth - totalColumnPadding

	local equipmentWidth = math.floor(availableForColumns * L.ColumnRatioEquip / COLUMN_RATIO_TOTAL)
	local backpackWidth = math.floor(availableForColumns * L.ColumnRatioBackpack / COLUMN_RATIO_TOTAL)
	local quickUseWidth = math.floor(availableForColumns * L.ColumnRatioQuick / COLUMN_RATIO_TOTAL)

	-- Backpack slot size (square); same size used for backpack and quick slots so they match
	local backpackSlotSize = math.floor((backpackWidth - (cols - 1) * scaledP.BackpackSlot) / cols)

	return React.createElement("Frame", {
		Name = "LoadoutApp",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		UnifiedContainer = React.createElement("Frame", {
			Name = "UnifiedContainer",
			AnchorPoint = LayoutConfig.Container.AnchorPoint,
			Position = LayoutConfig.Container.Position,
			Size = UDim2.fromScale(L.WidthScale, 1 - 2 * LayoutConfig.Container.VerticalMarginScale),
			BackgroundColor3 = C.MainFrame,
			BackgroundTransparency = C.MainFrameTransparency,
			ZIndex = LayoutConfig.ZIndex.MainFrame,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.MainFrame) }),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, scaledP.TitleToContent),
				PaddingBottom = UDim.new(0, scaledP.OuterFrameVertical),
				PaddingLeft = UDim.new(0, scaledP.OuterFrameHorizontal),
				PaddingRight = UDim.new(0, scaledP.OuterFrameHorizontal),
			}),
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, scaledP.TitleToContent),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Header = React.createElement("TextLabel", {
				Name = "Header",
				Size = UDim2.new(1, 0, 0, scaledF.TitleHeight),
				BackgroundTransparency = 1,
				Text = "LOADOUT",
				TextColor3 = C.Text.Primary,
				Font = F.Family,
				TextSize = scaledF.TitleSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			PanelsRow = React.createElement("Frame", {
				Name = "PanelsRow",
				Size = UDim2.new(1, 0, 1, -(scaledF.TitleHeight + scaledP.TitleToContent)),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, scaledP.ColumnGap),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				}),
			EquipmentCol = React.createElement("ScrollingFrame", {
				Name = "EquipmentCol",
				Size = UDim2.new(0, equipmentWidth, 1, 0),
				BackgroundColor3 = ThemeConfig.DebugColumnColors.Equipment,
				BackgroundTransparency = ThemeConfig.DebugColumnColors.Transparency,
				LayoutOrder = 1,
				CanvasSize = UDim2.fromOffset(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = C.ScrollBar.Thickness,
				ScrollBarImageColor3 = C.ScrollBar.Color,
				ScrollBarImageTransparency = C.ScrollBar.Transparency,
				ClipsDescendants = true,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Panel = React.createElement(EquipmentPanel, {
					equipment = loadoutData.equipment,
					weapons = loadoutData.weapons,
					columnWidth = equipmentWidth,
					backpackSlotSize = backpackSlotSize,
					scale = scale,
					dragEnabled = props.dragEnabled,
					onEquipmentDragStart = props.onEquipmentDragStart,
					onEquipmentClick = props.onEquipmentClick,
					onAbilityClick = props.onAbilityClick,
				}),
			}),
			BackpackCol = React.createElement("ScrollingFrame", {
				Name = "BackpackCol",
				Size = UDim2.new(0, backpackWidth, 1, 0),
				BackgroundColor3 = ThemeConfig.DebugColumnColors.Backpack,
				BackgroundTransparency = ThemeConfig.DebugColumnColors.Transparency,
				LayoutOrder = 2,
				CanvasSize = UDim2.fromOffset(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = C.ScrollBar.Thickness,
				ScrollBarImageColor3 = C.ScrollBar.Color,
				ScrollBarImageTransparency = C.ScrollBar.Transparency,
				ClipsDescendants = true,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Panel = React.createElement(BackpackPanel, {
					backpackData = loadoutData.backpack,
					rows = props.rows,
					cols = props.cols,
					columnWidth = backpackWidth,
					scale = scale,
					gridRef = props.inventoryGridRef,
					dragEnabled = props.dragEnabled,
					onDragStart = props.onDragStart,
					onMouseEnter = props.onMouseEnter,
					onMouseLeave = props.onMouseLeave,
				}),
			}),
			QuickUseCol = React.createElement("ScrollingFrame", {
				Name = "QuickUseCol",
				Size = UDim2.new(0, quickUseWidth, 1, 0),
				BackgroundColor3 = ThemeConfig.DebugColumnColors.QuickUse,
				BackgroundTransparency = ThemeConfig.DebugColumnColors.Transparency,
				LayoutOrder = 3,
				CanvasSize = UDim2.fromOffset(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = C.ScrollBar.Thickness,
				ScrollBarImageColor3 = C.ScrollBar.Color,
				ScrollBarImageTransparency = C.ScrollBar.Transparency,
				ClipsDescendants = true,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Panel = React.createElement(QuickUsePanel, {
					quickUseData = loadoutData.quickUse,
					slotSize = backpackSlotSize,
					columnWidth = quickUseWidth,
					scale = scale,
					dragEnabled = props.dragEnabled,
					onDragStart = props.onQuickUseDragStart,
					onSlotClick = props.onQuickUseClick,
				}),
			}),
			})
		})
	})
end

return LoadoutApp
