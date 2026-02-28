--!strict
-- Single ability slot (visual placeholder; no actual abilities yet)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
type AbilitySlotData = InventoryTypes.AbilitySlotData

export type AbilitySlotProps = {
	index: number,
	ability: AbilitySlotData?,
	size: number?,
	onClick: () -> (),
}

local DEFAULT_SLOT_SIZE = LayoutConfig.DefaultSlotSize.Ability
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius

local function AbilitySlot(props: AbilitySlotProps)
	local slotSize = props.size or DEFAULT_SLOT_SIZE
	return React.createElement("ImageButton", {
		Name = "AbilitySlot_" .. tostring(props.index),
		Size = UDim2.fromOffset(slotSize, slotSize),
		BackgroundColor3 = C.Slot,
		BackgroundTransparency = C.SlotTransparency,
		AutoButtonColor = false,
		Image = "",
		ImageTransparency = 1,
		LayoutOrder = props.index,
		ZIndex = LayoutConfig.ZIndex.Content,
		[React.Event.Activated] = props.onClick,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.SlotSmall) }),
		Stroke = React.createElement("UIStroke", {
			Thickness = C.Stroke.Thickness,
			Color = C.Stroke.Default,
			Transparency = C.Stroke.Transparency,
		}),
	})
end

return AbilitySlot
