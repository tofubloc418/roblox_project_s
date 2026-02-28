--!strict
-- Single inventory slot (restyled for Arc Raiders aesthetic)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))
type ItemStack = InventoryTypes.ItemStack

export type InventorySlotProps = {
	index: number,
	stack: ItemStack?,
	active: boolean,
	size: number?,
	onDragStart: () -> (),
	onMouseEnter: (() -> ())?,
	onMouseLeave: (() -> ())?,
}

local DEFAULT_SLOT_SIZE = LayoutConfig.DefaultSlotSize.Inventory
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
			displayText = displayName
		end
		if stack.maxStack > 1 then
			stackText = string.format("%d/%d", stack.count, stack.maxStack)
		end
	end

	local strokeThickness = active and C.Stroke.ActiveThickness or C.Stroke.Thickness
	local strokeColor = active and C.Stroke.Active or C.Stroke.Default
	local slotSize = props.size or DEFAULT_SLOT_SIZE

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
		[React.Event.MouseButton1Down] = props.onDragStart,
		[React.Event.MouseEnter] = props.onMouseEnter,
		[React.Event.MouseLeave] = props.onMouseLeave,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
		Stroke = React.createElement("UIStroke", {
			Thickness = strokeThickness,
			Color = strokeColor,
			Transparency = C.Stroke.Transparency,
		}),
		Label = React.createElement("TextLabel", {
			Name = "Label",
			Size = UDim2.fromScale(1, LayoutConfig.SlotLabel.Inventory.LabelHeightScale),
			Position = UDim2.fromScale(LayoutConfig.SlotLabel.Inventory.LabelXPos, LayoutConfig.SlotLabel.Inventory.LabelYPos),
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = C.Text.Primary,
			Font = F.FamilySecondary,
			Text = displayText,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),
		Stack = React.createElement("TextLabel", {
			Name = "Stack",
			Size = UDim2.fromScale(LayoutConfig.SlotLabel.Inventory.StackWidthScale, LayoutConfig.SlotLabel.Inventory.LabelHeightScale),
			Position = UDim2.fromScale(LayoutConfig.SlotLabel.Inventory.StackXPos, LayoutConfig.SlotLabel.Inventory.StackYPos),
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = C.Text.Secondary,
			Font = F.FamilySecondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = stackText,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),
	})
end

return InventorySlot
