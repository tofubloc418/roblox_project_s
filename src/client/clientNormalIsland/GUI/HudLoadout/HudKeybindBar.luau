--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

local H = ThemeConfig.HudLoadout

export type HudKeybindBarProps = {
	keybind: string,
	label: string?,
	leftAlignKeybind: boolean?,
	isActive: boolean,
	width: number,
	hudScale: number?,
	layoutOrder: number?,
}

local function HudKeybindBar(props: HudKeybindBarProps)
	local isActive = props.isActive
	local hudScale = props.hudScale or 1
	local useWeaponLayout = (props.leftAlignKeybind == true) or (props.label ~= nil and props.label ~= "")
	local scaledBarHeight = math.round(H.BarHeight * hudScale)
	local scaledFontSize = math.round(H.BarFontSize * hudScale)
	local scaledCorner = math.round(ThemeConfig.CornerRadius.SlotSmall * hudScale)
	local nameOffset = scaledBarHeight + math.round(4 * hudScale)

	local bgColor = if isActive then H.BarActiveBackground else H.BarInactiveBackground
	local bgTransparency = if isActive then 0 else H.BarInactiveBackgroundTransparency
	local textColor = if isActive then H.BarActiveText else H.BarInactiveText

	return React.createElement("Frame", {
		Name = "KeybindBar",
		Size = UDim2.new(0, props.width, 0, scaledBarHeight),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = bgTransparency,
		LayoutOrder = props.layoutOrder or 1,
		ZIndex = LayoutConfig.ZIndex.Content,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, scaledCorner),
		}),

		KeyLabel = React.createElement("TextLabel", {
			Name = "KeyLabel",
			Size = if useWeaponLayout
				then UDim2.new(0, scaledBarHeight, 1, 0)
				else UDim2.new(1, 0, 1, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = props.keybind,
			TextColor3 = textColor,
			Font = ThemeConfig.Font.Family,
			TextSize = scaledFontSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),

		NameLabel = if useWeaponLayout then React.createElement("TextLabel", {
			Name = "NameLabel",
			Size = UDim2.new(1, -nameOffset, 1, 0),
			Position = UDim2.new(0, nameOffset, 0, 0),
			BackgroundTransparency = 1,
			Text = props.label or "",
			TextColor3 = textColor,
			Font = ThemeConfig.Font.Family,
			TextSize = scaledFontSize,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = LayoutConfig.ZIndex.Content,
		}) else nil,
	})
end

return HudKeybindBar
