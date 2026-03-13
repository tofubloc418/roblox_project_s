--!strict
-- Single quick-use slot: icon, stack label, and drag-drop target registration.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))
type ItemStack = InventoryTypes.ItemStack

export type QuickUseSlotProps = {
	index: number,
	stack: ItemStack?,
	size: number?,
	onClick: () -> (),
}

local DEFAULT_SLOT_SIZE = LayoutConfig.DefaultSlotSize.QuickUse
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius
local F = ThemeConfig.Font

local function QuickUseSlot(props: QuickUseSlotProps)
	local stack = props.stack
	local imageId = ""
	local displayText = ""
	local stackText = ""
	local slotRef = React.useRef(nil :: ImageButton?)

	if stack then
		local icon, displayName = ItemIconResolver.getIconForItem(stack.itemId)
		if icon then
			imageId = icon
		else
			displayText = displayName or ""
		end
		stackText = tostring(stack.count)
	end

	local slotSize = props.size or DEFAULT_SLOT_SIZE

	return React.createElement("ImageButton", {
		Name = "QuickUseSlot_" .. tostring(props.index),
		Size = UDim2.fromOffset(slotSize, slotSize),
		BackgroundColor3 = C.Slot,
		BackgroundTransparency = C.SlotTransparency,
		AutoButtonColor = false,
		Image = imageId,
		ImageTransparency = imageId == "" and 1 or 0,
		LayoutOrder = props.index,
		ZIndex = LayoutConfig.ZIndex.Content,
		ref = slotRef,
		[React.Event.Activated] = props.onClick,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
		Stroke = React.createElement("UIStroke", {
			Thickness = C.Stroke.Thickness,
			Color = C.Stroke.Default,
			Transparency = C.Stroke.Transparency,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, LayoutConfig.SlotLabel.QuickUse.LabelHeightScale),
			Position = UDim2.fromScale(LayoutConfig.SlotLabel.QuickUse.LabelXPos, LayoutConfig.SlotLabel.QuickUse.LabelYPos),
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = C.Text.Secondary,
			Font = F.FamilySecondary,
			Text = displayText,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),
		Stack = React.createElement("TextLabel", {
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

return QuickUseSlot
