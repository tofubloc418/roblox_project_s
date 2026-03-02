--!strict
--[[
	HudActionRow
	============
	Displays the flashlight action key above the slot columns.
	Right-aligned to match the weapon column.

	Each entry renders as:   LABEL  |  [KEY]

	Currently only "FLASHLIGHT / F" is shown. Additional action keys
	can be added by extending the entries table in the future.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

local H = ThemeConfig.HudLoadout
local C = ThemeConfig.Colors

-- Fixed dimensions for the action row entries (1.5x scale; gaps unchanged)
local ENTRY_HEIGHT = 38
local KEY_CAP_WIDTH = 45
local LABEL_FONT_SIZE = 24
local SEPARATOR_WIDTH = 8

export type HudActionRowProps = {
	flashlightOn: boolean,
	layoutOrder: number?,
}

-- Renders a single "LABEL | [KEY]" row
local function ActionEntry(label: string, key: string, isOn: boolean)
	local textColor = if isOn then C.Text.Primary else C.Text.Secondary

	return React.createElement("Frame", {
		Name = "ActionEntry_" .. label,
		Size = UDim2.new(1, 0, 0, ENTRY_HEIGHT),
		BackgroundTransparency = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, SEPARATOR_WIDTH),
		}),

		Label = React.createElement("TextLabel", {
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = textColor,
			Font = ThemeConfig.Font.Family,
			TextSize = LABEL_FONT_SIZE,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),

		Separator = React.createElement("Frame", {
			Name = "Separator",
			Size = UDim2.new(0, 1, 0.6, 0),
			BackgroundColor3 = C.Stroke.Default,
			BackgroundTransparency = C.Stroke.Transparency,
			LayoutOrder = 2,
		}),

		KeyCap = React.createElement("Frame", {
			Name = "KeyCap",
			Size = UDim2.new(0, KEY_CAP_WIDTH, 1, 0),
			BackgroundColor3 = C.Slot,
			BackgroundTransparency = C.SlotTransparency,
			LayoutOrder = 3,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, ThemeConfig.CornerRadius.SlotSmall),
			}),
			Stroke = React.createElement("UIStroke", {
				Thickness = C.Stroke.Thickness,
				Color = C.Stroke.Default,
				Transparency = C.Stroke.Transparency,
			}),
			KeyText = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = key,
				TextColor3 = textColor,
				Font = ThemeConfig.Font.Family,
				TextSize = LABEL_FONT_SIZE,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = LayoutConfig.ZIndex.Content,
			}),
		}),
	})
end

local function HudActionRow(props: HudActionRowProps)
	return React.createElement("Frame", {
		Name = "HudActionRow",
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),

		FlashlightEntry = ActionEntry("FLASHLIGHT", "F", props.flashlightOn),
	})
end

return HudActionRow
