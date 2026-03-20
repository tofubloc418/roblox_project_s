--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

export type TabButtonProps = {
	tabId: string,
	label: string,
	layoutOrder: number,
	isActive: boolean,
	onActivated: () -> (),
	minWidth: number,
	tabHeight: number,
	fontSize: number,
}

local function TabButton(props: TabButtonProps)
	local hovered, setHovered = React.useState(false)

	local S = ThemeConfig.Settings
	local C = ThemeConfig.Colors

	local isActive = props.isActive
	local isHover = hovered and not isActive

	local bg = if isActive then S.TabActiveBackground else S.TabInactiveBackground
	local bgTrans = if isActive
		then S.TabActiveBackgroundTransparency
		elseif isHover then S.TabHoverBackgroundTransparency
		else S.TabInactiveBackgroundTransparency

	local textColor = if isActive then S.TabActiveText elseif isHover then S.TabHoverText else S.TabInactiveText

	return React.createElement("TextButton", {
		Name = "Tab_" .. props.tabId,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.new(0, math.max(props.minWidth, 0), 0, props.tabHeight),
		BackgroundColor3 = bg,
		BackgroundTransparency = bgTrans,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = props.label,
		TextColor3 = textColor,
		Font = ThemeConfig.Font.Family,
		TextSize = props.fontSize,
		ZIndex = LayoutConfig.Settings.TabButtonZIndex,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
		[React.Event.Activated] = function()
			props.onActivated()
		end,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, S.TabCornerRadius),
		}),
		Pad = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, S.TabPadding),
			PaddingRight = UDim.new(0, S.TabPadding),
		}),
	})
end

return TabButton
