--!strict
-- Bottom HUD: five ability preset slots for the active weapon bar preset key.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local AbilityPresetSlot = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("AbilityPresetSlot"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

type SerializedPreset = InventoryTypes.SerializedPreset

local AB = ThemeConfig.AbilityBar
local L_AB = LayoutConfig.AbilityBar

local SLOT_COUNT = 5

export type HudAbilityBarProps = {
	preset: SerializedPreset?,
}

local function HudAbilityBar(props: HudAbilityBarProps)
	local preset = props.preset
	local slotSize = AB.SlotSize
	local gap = AB.SlotGap

	local totalWidth = SLOT_COUNT * slotSize + (SLOT_COUNT - 1) * gap
	local totalHeight = slotSize

	local slotElements: { [string]: any } = {}
	for i = 1, SLOT_COUNT do
		local aid, isUlt = AbilityPresetSlotUtils.readSlot(preset, i)
		slotElements["Slot" .. i] = React.createElement(AbilityPresetSlot, {
			aid = aid,
			isUlt = isUlt,
			variant = "hud",
			pixelSize = slotSize,
			layoutOrder = i,
			zIndex = LayoutConfig.ZIndex.Content,
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
