--!strict
-- Single ability slot: shows ability icon from preset; optional ultimate border.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local AbilityIconResolver = require(script.Parent:WaitForChild("AbilityIconResolver"))
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
	local ability = props.ability
	local iconId: string = ""
	if ability then
		local id, _ = AbilityIconResolver.getIconForAbility(ability.abilityId)
		iconId = (id and #id > 0) and id or ""
	end
	local strokeColor = C.Stroke.Default
	local strokeThickness = C.Stroke.Thickness
	if ability and ability.isUltimate then
		strokeColor = C.Stroke.Active
		strokeThickness = C.Stroke.ActiveThickness
	end
	return React.createElement("ImageButton", {
		Name = "AbilitySlot_" .. tostring(props.index),
		Size = UDim2.fromOffset(slotSize, slotSize),
		BackgroundColor3 = C.Slot,
		BackgroundTransparency = C.SlotTransparency,
		AutoButtonColor = false,
		Image = iconId,
		ImageTransparency = (iconId == "" or iconId == "rbxassetid://0") and 1 or 0,
		LayoutOrder = props.index,
		ZIndex = LayoutConfig.ZIndex.Content,
		[React.Event.Activated] = props.onClick,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.SlotSmall) }),
		Stroke = React.createElement("UIStroke", {
			Thickness = strokeThickness,
			Color = strokeColor,
			Transparency = C.Stroke.Transparency,
		}),
	})
end

return AbilitySlot
