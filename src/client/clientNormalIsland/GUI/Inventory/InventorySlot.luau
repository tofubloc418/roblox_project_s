--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))

type ItemStack = InventoryTypes.ItemStack

export type InventorySlotProps = {
	index: number,
	stack: ItemStack?,
	active: boolean,
	onDragStart: () -> (),
	onEquip: () -> (),
	onMouseEnter: (() -> ())?,
	onMouseLeave: (() -> ())?,
}

local function InventorySlot(props: InventorySlotProps)
	local stack = props.stack
	local active = props.active

	local imageId: string = ""
	local displayText: string = ""
	local stackText: string = ""

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

	local strokeThickness = active and 2 or 1
	local strokeColor = active and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(120, 120, 120)

	return React.createElement("ImageButton", {
		Name = "Slot_" .. tostring(props.index),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		AutoButtonColor = false,
		Image = imageId,
		ImageTransparency = imageId == "" and 1 or 0,
		LayoutOrder = props.index,
		[React.Event.MouseButton1Down] = props.onDragStart,
		[React.Event.MouseButton2Click] = props.onEquip,
		[React.Event.MouseEnter] = props.onMouseEnter,
		[React.Event.MouseLeave] = props.onMouseLeave,
	}, {
		Label = React.createElement("TextLabel", {
			Name = "Label",
			Size = UDim2.fromScale(1, 0.25),
			Position = UDim2.fromScale(0, 0.75),
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			Text = displayText,
		}),
		Stack = React.createElement("TextLabel", {
			Name = "Stack",
			Size = UDim2.fromScale(0.4, 0.25),
			Position = UDim2.fromScale(0.6, 0),
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = stackText,
		}),
		Stroke = React.createElement("UIStroke", {
			Thickness = strokeThickness,
			Color = strokeColor,
		}),
	})
end

return InventorySlot
