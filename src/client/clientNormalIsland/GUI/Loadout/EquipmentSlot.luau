--!strict
-- Backpack/Armor slot (accepts optional item data; visual only for now)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))
type ItemStack = InventoryTypes.ItemStack
type EquipmentSlotId = InventoryTypes.EquipmentSlotId

export type EquipmentSlotProps = {
	slotId: EquipmentSlotId,
	label: string,
	item: ItemStack?,
	layoutOrder: number?,
	size: UDim2?,
	dragEnabled: boolean?,
	onClick: () -> (),
}

local s = LayoutConfig.DefaultSlotSize.Equipment
local DEFAULT_SLOT_SIZE = UDim2.fromOffset(s, s)
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius
local F = ThemeConfig.Font

local function EquipmentSlot(props: EquipmentSlotProps)
	local item = props.item
	local imageId = ""
	local stackText = ""
	-- Show label only when slot is empty; hide when item is equipped
	local displayText = if item then "" else props.label

	if item then
		local icon = ItemIconResolver.getIconForItem(item.itemId)
		if icon then
			imageId = icon
		end
		stackText = tostring(item.count)
	end

	local size = props.size or DEFAULT_SLOT_SIZE
	local slotRef = React.useRef(nil :: ImageButton?)

	local function handleMouseButton1Down()
		if not props.dragEnabled or not item then
			return
		end

		DragDropManager.prepareDrag({
			container = "equipment",
			slotId = props.slotId,
		}, {
			imageId = imageId,
			labelText = displayText,
			stackText = stackText,
		})
	end

	local function handleActivated()
		if DragDropManager.consumeActivatedSuppression() then
			return
		end

		props.onClick()
	end

	return React.createElement("ImageButton", {
		Name = "EquipmentSlot_" .. props.slotId,
		Size = size,
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = C.Slot,
		BackgroundTransparency = C.SlotTransparency,
		AutoButtonColor = false,
		Image = imageId,
		ImageTransparency = imageId == "" and 1 or 0,
		ZIndex = LayoutConfig.ZIndex.Content,
		ref = slotRef,
		[React.Event.MouseButton1Down] = handleMouseButton1Down,
		[React.Event.Activated] = handleActivated,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
		Stroke = React.createElement("UIStroke", {
			Thickness = C.Stroke.Thickness,
			Color = C.Stroke.Default,
			Transparency = C.Stroke.Transparency,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, F.SlotLabelHeightScale),
			Position = LayoutConfig.SlotLabel.Equipment.Position,
			AnchorPoint = LayoutConfig.SlotLabel.Equipment.AnchorPoint,
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = C.Text.Secondary,
			Font = F.FamilySecondary,
			Text = displayText,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
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

return EquipmentSlot
