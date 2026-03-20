--!strict
-- Single inventory slot (restyled for Arc Raiders aesthetic)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))
type ItemStack = InventoryTypes.ItemStack

export type InventorySlotProps = {
	index: number,
	stack: ItemStack?,
	active: boolean,
	size: number?,
	dragEnabled: boolean?,
	onDragStart: () -> (),
	onMouseEnter: (() -> ())?,
	onMouseLeave: (() -> ())?,
}

local DEFAULT_SLOT_SIZE = LayoutConfig.DefaultSlotSize.Backpack
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius
local F = ThemeConfig.Font

local function InventorySlot(props: InventorySlotProps)
	local stack = props.stack
	local active = props.active

	local imageId = ""
	local displayText = ""
	local stackText = ""

	if stack then
		local icon, displayName = ItemIconResolver.getIconForItem(stack.itemId)
		if icon then
			imageId = icon
		else
			displayText = displayName or ""
		end
		stackText = tostring(stack.count)
	end

	local strokeThickness = active and C.Stroke.ActiveThickness or C.Stroke.Thickness
	local strokeColor = active and C.Stroke.Active or C.Stroke.Default
	local slotSize = props.size or DEFAULT_SLOT_SIZE
	local slotRef = React.useRef(nil :: ImageButton?)

	local function handleMouseButton1Down()
		props.onDragStart()
		if not props.dragEnabled or not stack then
			return
		end

		DragDropManager.prepareDrag({
			container = "backpack",
			index = props.index,
		}, {
			imageId = imageId,
			labelText = displayText,
			stackText = stackText,
		})
	end

	return React.createElement("ImageButton", {
		Name = "Slot_" .. tostring(props.index),
		Size = UDim2.fromOffset(slotSize, slotSize),
		BackgroundColor3 = C.Slot,
		BackgroundTransparency = C.SlotTransparency,
		AutoButtonColor = false,
		Image = imageId,
		ImageTransparency = imageId == "" and 1 or 0,
		LayoutOrder = props.index,
		ZIndex = LayoutConfig.ZIndex.Content,
		ref = slotRef,
		[React.Event.MouseButton1Down] = handleMouseButton1Down,
		[React.Event.MouseEnter] = props.onMouseEnter or function() end,
		[React.Event.MouseLeave] = props.onMouseLeave or function() end,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
		Stroke = React.createElement("UIStroke", {
			Thickness = strokeThickness,
			Color = strokeColor,
			Transparency = C.Stroke.Transparency,
		}),
		Label = React.createElement("TextLabel", {
			Name = "Label",
			Size = UDim2.fromScale(1, LayoutConfig.SlotLabel.Backpack.LabelHeightScale),
			Position = UDim2.fromScale(LayoutConfig.SlotLabel.Backpack.LabelXPos, LayoutConfig.SlotLabel.Backpack.LabelYPos),
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = C.Text.Primary,
			Font = F.FamilySecondary,
			Text = displayText,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),
		Stack = React.createElement("TextLabel", {
			Name = "Stack",
			Size = UDim2.fromScale(LayoutConfig.SlotLabel.StackCorner.WidthScale, LayoutConfig.SlotLabel.StackCorner.HeightScale),
			Position = LayoutConfig.SlotLabel.StackCorner.Position,
			AnchorPoint = LayoutConfig.SlotLabel.StackCorner.AnchorPoint,
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = C.Text.Secondary,
			Font = F.FamilySecondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = stackText,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),
	})
end

return InventorySlot
