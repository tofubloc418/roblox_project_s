--!strict
-- Bottom HUD: five ability preset slots for the active weapon bar preset key.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local AbilityPresetSlot = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("AbilityPresetSlot"))
local KeybindsClient = require(script.Parent.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

type SerializedPreset = InventoryTypes.SerializedPreset

local AB = ThemeConfig.AbilityBar
local L_AB = LayoutConfig.AbilityBar

local SLOT_COUNT = 5

local ABILITY_SLOT_IDS = {
	KeybindIds.AbilitySlot1,
	KeybindIds.AbilitySlot2,
	KeybindIds.AbilitySlot3,
	KeybindIds.AbilitySlot4,
	KeybindIds.AbilitySlot5,
}

export type HudAbilityBarProps = {
	preset: SerializedPreset?,
}

local function HudAbilityBar(props: HudAbilityBarProps)
	local preset = props.preset
	local slotSize = AB.SlotSize
	local gap = AB.SlotGap
	local keyGap = AB.KeyLabelToSlotGap
	local keyH = AB.KeyLabelHeight
	local keyFont = AB.KeyLabelFontSize

	local totalWidth = SLOT_COUNT * slotSize + (SLOT_COUNT - 1) * gap
	local totalHeight = keyH + keyGap + slotSize

	local slotElements: { [string]: any } = {}
	for i = 1, SLOT_COUNT do
		local aid, isUlt = AbilityPresetSlotUtils.readSlot(preset, i)
		local actionId = ABILITY_SLOT_IDS[i]
		local keyText = KeybindsClient.getDisplayString(actionId)
		slotElements["Col" .. i] = React.createElement("Frame", {
			Name = "HudAbilityColumn_" .. i,
			Size = UDim2.fromOffset(slotSize, totalHeight),
			BackgroundTransparency = 1,
			LayoutOrder = i,
		}, {
			ColLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, keyGap),
			}),
			KeyLabel = React.createElement("TextLabel", {
				Name = "KeyLabel",
				Size = UDim2.new(1, 0, 0, keyH),
				BackgroundTransparency = 1,
				Text = keyText,
				TextColor3 = ThemeConfig.Colors.Text.Primary,
				Font = ThemeConfig.Font.Family,
				TextSize = keyFont,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 1,
				ZIndex = LayoutConfig.ZIndex.Content,
			}),
			Slot = React.createElement(AbilityPresetSlot, {
				aid = aid,
				isUlt = isUlt,
				variant = "hud",
				pixelSize = slotSize,
				layoutOrder = 2,
				zIndex = LayoutConfig.ZIndex.Content,
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
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
		}),
		Col1 = slotElements["Col1"],
		Col2 = slotElements["Col2"],
		Col3 = slotElements["Col3"],
		Col4 = slotElements["Col4"],
		Col5 = slotElements["Col5"],
	})
end

return HudAbilityBar
