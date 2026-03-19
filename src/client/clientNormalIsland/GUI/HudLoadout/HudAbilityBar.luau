--!strict
-- Bottom-center HUD bar: 5 square ability slots for current/last active weapon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local AbilityIconResolver = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("AbilityIconResolver"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

type AbilitySlotData = InventoryTypes.AbilitySlotData

local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius
local AB = ThemeConfig.AbilityBar
local L_AB = LayoutConfig.AbilityBar

local SLOT_COUNT = 5

export type HudAbilityBarProps = {
	slots: { [number]: AbilitySlotData? },
}

local function HudAbilityBar(props: HudAbilityBarProps)
	local slots = props.slots or {}
	local slotSize = AB.SlotSize
	local gap = AB.SlotGap

	-- Total width: 5 slots + 4 gaps
	local totalWidth = SLOT_COUNT * slotSize + (SLOT_COUNT - 1) * gap
	local totalHeight = slotSize

	local slotElements: { [string]: any } = {}
	for i = 1, SLOT_COUNT do
		local ability = slots[i]
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
		slotElements["Slot" .. i] = React.createElement("Frame", {
			Name = "AbilitySlot_" .. tostring(i),
			Size = UDim2.fromOffset(slotSize, slotSize),
			BackgroundColor3 = C.Slot,
			BackgroundTransparency = C.SlotTransparency,
			LayoutOrder = i,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.SlotSmall) }),
			Stroke = React.createElement("UIStroke", {
				Thickness = strokeThickness,
				Color = strokeColor,
				Transparency = C.Stroke.Transparency,
			}),
			Icon = React.createElement("ImageLabel", {
				Name = "Icon",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = iconId,
				ImageTransparency = (iconId == "" or iconId == "rbxassetid://0") and 1 or 0,
			}),
		})
	end

	return React.createElement("Frame", {
		Name = "HudAbilityBar",
		AnchorPoint = L_AB.AnchorPoint,
		Position = UDim2.new(0.5, 0, 1, L_AB.OffsetY),
		Size = UDim2.fromOffset(totalWidth, totalHeight),
		BackgroundTransparency = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
		}),
		Slot1 = slotElements["Slot1"],
		Slot2 = slotElements["Slot2"],
		Slot3 = slotElements["Slot3"],
		Slot4 = slotElements["Slot4"],
		Slot5 = slotElements["Slot5"],
	})
end

return HudAbilityBar
