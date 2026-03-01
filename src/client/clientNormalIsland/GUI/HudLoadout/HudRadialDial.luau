--!strict
--[[
	HudRadialDial
	=============
	Radial (circular) item selector shown when the player holds Q.

	Behaviour:
	  • Items from the quick-use slots are arranged in a circle around a center point.
	  • The mouse angle from center determines which item is "highlighted".
	  • On release (controlled by the parent controller), `onSelect` fires with
	    the index of the highlighted item. If no item is under the mouse the
	    current index stays unchanged (onSelect is not called).
	  • The component is always in the React tree; `visible` controls rendering.

	Layout:
	  • The component fills the full ScreenGui (center of screen = origin of the dial).
	  • Items are placed at RADIUS pixels from the screen center.
	  • Each item has an icon and a small name label below it.
	  • The center of the dial shows a small "current item" indicator.

	Integration note:
	  The CONTROLLER is responsible for:
	    1. Detecting Q hold vs tap.
	    2. Tracking mouse position each frame (via RunService.Heartbeat).
	    3. Passing `mouseAngle` (degrees, 0 = right, 90 = down) to this component.
	    4. Calling onSelect on Q key release if radial is visible.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local ItemIconResolver = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("ItemIconResolver"))

type ItemStack = InventoryTypes.ItemStack

local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius

-- Dial geometry (1.5x scale)
local RADIUS = 225          -- px from screen center to item center
local ITEM_SIZE = 105        -- square icon size
local CENTER_SIZE = 75       -- center indicator dot size
local LABEL_HEIGHT = 30
local LABEL_FONT_SIZE = 21
local HIGHLIGHT_SCALE = 1.15

export type HudRadialDialProps = {
	items: { [number]: ItemStack? },
	currentIndex: number?,
	-- Highlighted item index (derived from mouse angle by the controller)
	highlightedIndex: number?,
	visible: boolean,
	-- Called when the user selects a slot (by releasing Q)
	onSelect: (index: number) -> (),
	-- Viewport size passed from controller for positioning
	viewportSize: Vector2,
}

-- Compute the screen-space position for item index i out of count total.
-- Starts at top (angle offset -90°) and goes clockwise.
local function itemPosition(i: number, count: number, cx: number, cy: number): (number, number)
	local angle = ((i - 1) / count) * 2 * math.pi - math.pi / 2
	local x = cx + RADIUS * math.cos(angle)
	local y = cy + RADIUS * math.sin(angle)
	return x, y
end

local function HudRadialDial(props: HudRadialDialProps)
	if not props.visible then
		return nil
	end

	local items = props.items
	local cx = props.viewportSize.X / 2
	local cy = props.viewportSize.Y / 2

	-- Collect occupied slots (slot indices that have an item)
	local slotIndices: { number } = {}
	for i = 1, 6 do
		if items[i] ~= nil then
			table.insert(slotIndices, i)
		end
	end

	local count = #slotIndices
	if count == 0 then
		return nil
	end

	-- Build item frames
	local itemElements: { [string]: any } = {}

	for pos, slotIdx in ipairs(slotIndices) do
		local stack = items[slotIdx] :: ItemStack
		local ix, iy = itemPosition(pos, count, cx, cy)

		local isHighlighted = props.highlightedIndex == slotIdx
		local isCurrent = props.currentIndex == slotIdx

		local imageId, displayName = ItemIconResolver.getIconForItem(stack.itemId)
		imageId = imageId or ""
		displayName = displayName or stack.itemId

		local visualSize = if isHighlighted then math.floor(ITEM_SIZE * HIGHLIGHT_SCALE) else ITEM_SIZE
		local halfSize = visualSize / 2

		itemElements["Item_" .. tostring(slotIdx)] = React.createElement("Frame", {
			Name = "RadialItem_" .. tostring(slotIdx),
			Size = UDim2.new(0, visualSize, 0, visualSize + LABEL_HEIGHT + 4),
			Position = UDim2.new(0, ix - halfSize, 0, iy - halfSize),
			BackgroundTransparency = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),

			Icon = React.createElement("ImageButton", {
				Name = "Icon",
				Size = UDim2.new(0, visualSize, 0, visualSize),
				BackgroundColor3 = if isHighlighted then C.Stroke.Active else C.Slot,
				BackgroundTransparency = if isHighlighted then 0 else C.SlotTransparency,
				AutoButtonColor = false,
				Image = imageId,
				ImageTransparency = imageId == "" and 1 or 0,
				LayoutOrder = 1,
				ZIndex = LayoutConfig.ZIndex.Content,
				[React.Event.Activated] = function()
					props.onSelect(slotIdx)
				end,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, R.Slot),
				}),
				Stroke = React.createElement("UIStroke", {
					Thickness = if isCurrent then C.Stroke.ActiveThickness else C.Stroke.Thickness,
					Color = if isCurrent then C.Stroke.Active else C.Stroke.Default,
					Transparency = C.Stroke.Transparency,
				}),
			}),

			NameLabel = React.createElement("TextLabel", {
				Name = "NameLabel",
				Size = UDim2.new(0, visualSize + 20, 0, LABEL_HEIGHT),
				Position = UDim2.new(0.5, 0, 1, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Text = displayName,
				TextColor3 = if isHighlighted then C.Text.Primary else C.Text.Secondary,
				Font = ThemeConfig.Font.FamilySecondary,
				TextSize = LABEL_FONT_SIZE,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 2,
				ZIndex = LayoutConfig.ZIndex.Content,
			}),
		})
	end

	-- Center indicator: shows the current quick-slot item
	local currentStack = props.currentIndex and items[props.currentIndex] or nil
	local centerImageId = ""
	if currentStack then
		local cIcon = ItemIconResolver.getIconForItem(currentStack.itemId)
		centerImageId = cIcon or ""
	end

	local half = CENTER_SIZE / 2

	return React.createElement("Frame", {
		Name = "HudRadialDial",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.6,
		ZIndex = LayoutConfig.ZIndex.MainFrame,
	}, {
		-- Center dot
		Center = React.createElement("Frame", {
			Name = "Center",
			Size = UDim2.new(0, CENTER_SIZE, 0, CENTER_SIZE),
			Position = UDim2.new(0, cx - half, 0, cy - half),
			BackgroundColor3 = C.Slot,
			BackgroundTransparency = C.SlotTransparency,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.5, 0),
			}),
			Stroke = React.createElement("UIStroke", {
				Thickness = C.Stroke.Thickness,
				Color = C.Stroke.Default,
				Transparency = C.Stroke.Transparency,
			}),
			CenterIcon = React.createElement("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = centerImageId,
				ImageTransparency = centerImageId == "" and 1 or 0,
				ZIndex = LayoutConfig.ZIndex.Content,
			}),
		}),

			-- Item nodes (spread around the circle; merged into the children table)
		Items = React.createElement("Frame", {
			Name = "ItemsContainer",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, itemElements),
	})
end

return HudRadialDial
