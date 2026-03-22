--!strict
-- Square slot + keybind bar (quick-use / fists columns).

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
	iconImage: string?,
	isActive: boolean,
	size: number?,
	hudScale: number?,
	layoutOrder: number?,
	onActivated: (() -> ())?,
}

local function HudSlotCard(props: HudSlotCardProps)
	local size = props.size or H.SlotSize
	local hudScale = props.hudScale or 1
	local imageId = props.iconImage or ""
	local scaledBarHeight = math.round(H.BarHeight * hudScale)
	local scaledCorner = math.round(R.Slot * hudScale)

	local totalHeight = scaledBarHeight + size

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
			hudScale = hudScale,
			layoutOrder = 1,
			onActivated = props.onActivated,
		}),

		Slot = React.createElement("ImageButton", {
			Name = "SlotVisual",
			key = if imageId == "" then "empty" else imageId,
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
				CornerRadius = UDim.new(0, scaledCorner),
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
