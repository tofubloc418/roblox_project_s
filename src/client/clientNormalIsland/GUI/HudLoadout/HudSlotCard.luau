--!strict
--[[
	HudSlotCard
	===========
	Generic slot card used for the Q (quick-use) and 3 (fists/unequip) slots.

	Style matches the weapon slots (1–2): translucent gray slot only, no gradient rim.
	No gap between the keybind bar and the square visual.

	Structure (bottom of column anchor point):
	  ┌──────────┐
	  │ KeyBar   │   ← HudKeybindBar (centered keybind, width = size)
	  │  Icon    │   ← square ImageButton (translucent gray + stroke, no gap)
	  └──────────┘
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local HudKeybindBar = require(script.Parent:WaitForChild("HudKeybindBar"))

local H = ThemeConfig.HudLoadout
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius

export type HudSlotCardProps = {
	keybind: string,
	-- Item icon asset id (nil = empty slot)
	iconImage: string?,
	isActive: boolean,
	-- Square side length in pixels (defaults to ThemeConfig.HudLoadout.SlotSize)
	size: number?,
	layoutOrder: number?,
	onActivated: (() -> ())?,
}

local function HudSlotCard(props: HudSlotCardProps)
	local size = props.size or H.SlotSize
	local imageId = props.iconImage or ""

	-- Total card height = bar + slot (no gap)
	local totalHeight = H.BarHeight + size

	return React.createElement("Frame", {
		Name = "HudSlotCard_" .. props.keybind,
		Size = UDim2.new(0, size, 0, totalHeight),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),

		Bar = React.createElement(HudKeybindBar, {
			keybind = props.keybind,
			label = nil,
			isActive = props.isActive,
			width = size,
			layoutOrder = 1,
		}),

		-- Translucent gray slot only (same style as weapon slots 1–2), no gradient rim
		Slot = React.createElement("ImageButton", {
			Name = "SlotVisual",
			Size = UDim2.new(0, size, 0, size),
			BackgroundColor3 = C.Slot,
			BackgroundTransparency = C.SlotTransparency,
			AutoButtonColor = false,
			Image = imageId,
			ImageTransparency = imageId == "" and 1 or 0,
			LayoutOrder = 2,
			ZIndex = LayoutConfig.ZIndex.Content,
			[React.Event.Activated] = props.onActivated,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, R.Slot),
			}),
			Stroke = React.createElement("UIStroke", {
				Thickness = C.Stroke.Thickness,
				Color = C.Stroke.Default,
				Transparency = C.Stroke.Transparency,
			}),
		}),
	})
end

return HudSlotCard
