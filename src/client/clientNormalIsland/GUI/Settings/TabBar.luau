--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local SettingsTabConfig = require(script.Parent:WaitForChild("SettingsTabConfig"))
local TabButton = require(script.Parent:WaitForChild("TabButton"))

export type TabBarProps = {
	activeTabId: string,
	onTabActivated: (tabId: string) -> (),
	tabBarHeight: number,
	tabFontSize: number,
	scale: number,
}

local function TabBar(props: TabBarProps)
	local tabH = math.floor(props.tabBarHeight * props.scale)
	local fontSize = math.floor(props.tabFontSize * props.scale)
	local minW = math.floor(ThemeConfig.Settings.TabMinWidth * props.scale)

	local children: { [string]: any } = {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, ThemeConfig.Settings.TabGap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Pad = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, math.floor(ThemeConfig.Settings.TabPadding * props.scale)),
		}),
	}

	for _, tab in SettingsTabConfig do
		children["Tab_" .. tab.id] = React.createElement(TabButton, {
			tabId = tab.id,
			label = tab.label,
			layoutOrder = tab.layoutOrder,
			isActive = props.activeTabId == tab.id,
			minWidth = minW,
			tabHeight = tabH,
			fontSize = fontSize,
			onActivated = function()
				props.onTabActivated(tab.id)
			end,
		})
	end

	return React.createElement("Frame", {
		Name = "TabBar",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(1, 0, 0, tabH),
		BackgroundTransparency = 1,
		ZIndex = LayoutConfig.Settings.TabBarZIndex,
	}, children)
end

return TabBar
