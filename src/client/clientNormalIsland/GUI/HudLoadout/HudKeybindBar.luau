--!strict
--[[
	HudKeybindBar
	=============
	Reusable keybind label bar that sits on top of a slot card.

	Layout modes:
	  • leftAlignKeybind = false/nil and no label → keybind CENTERED (Q and 3 slots)
	  • leftAlignKeybind = true, or label provided → keybind LEFT, label RIGHT (weapon slots)
	  • Weapon slots should pass leftAlignKeybind = true so the number is left-aligned
	    even when there is no weapon name.

	Active state: white background, dark text.
	Inactive state: dark/semi-transparent background, white text.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

local H = ThemeConfig.HudLoadout

export type HudKeybindBarProps = {
	keybind: string,
	-- Optional item/weapon name shown right-aligned.
	label: string?,
	-- When true, keybind is always left-aligned (weapon slots, even with no name).
	leftAlignKeybind: boolean?,
	isActive: boolean,
	-- Must match the width of the parent slot card
	width: number,
	layoutOrder: number?,
}

local function HudKeybindBar(props: HudKeybindBarProps)
	local isActive = props.isActive
	-- Use two-column layout (key left, name right) when leftAlignKeybind or when label is non-empty
	local useWeaponLayout = (props.leftAlignKeybind == true) or (props.label ~= nil and props.label ~= "")

	local bgColor = if isActive then H.BarActiveBackground else H.BarInactiveBackground
	local bgTransparency = if isActive then 0 else H.BarInactiveBackgroundTransparency
	local textColor = if isActive then H.BarActiveText else H.BarInactiveText

	return React.createElement("Frame", {
		Name = "KeybindBar",
		Size = UDim2.new(0, props.width, 0, H.BarHeight),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = bgTransparency,
		LayoutOrder = props.layoutOrder or 1,
		ZIndex = LayoutConfig.ZIndex.Content,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, ThemeConfig.CornerRadius.SlotSmall),
		}),

		-- Keybind: fixed-width left block when weapon layout, else full width centered
		KeyLabel = React.createElement("TextLabel", {
			Name = "KeyLabel",
			Size = if useWeaponLayout
				then UDim2.new(0, H.BarHeight, 1, 0)    -- fixed-width left block
				else UDim2.new(1, 0, 1, 0),             -- full width, centered
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = props.keybind,
			TextColor3 = textColor,
			Font = ThemeConfig.Font.Family,
			TextSize = H.BarFontSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),

		-- Name (right-aligned); shown when using weapon layout (can be empty string)
		NameLabel = if useWeaponLayout then React.createElement("TextLabel", {
			Name = "NameLabel",
			Size = UDim2.new(1, -(H.BarHeight + 4), 1, 0),
			Position = UDim2.new(0, H.BarHeight + 4, 0, 0),
			BackgroundTransparency = 1,
			Text = props.label or "",
			TextColor3 = textColor,
			Font = ThemeConfig.Font.Family,
			TextSize = H.BarFontSize,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = LayoutConfig.ZIndex.Content,
		}) else nil,
	})
end

return HudKeybindBar
