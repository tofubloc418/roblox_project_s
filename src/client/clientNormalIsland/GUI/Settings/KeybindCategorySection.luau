--!strict
-- Settings → Keybinds: category header + list of KeybindRow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local KeybindRow = require(script.Parent:WaitForChild("KeybindRow"))

export type KeybindCategorySectionProps = {
	categoryTitle: string,
	layoutOrder: number,
	categoryTitleTextSize: number,
	rowProps: { { [string]: any } },
}

local function KeybindCategorySection(props: KeybindCategorySectionProps)
	local C = ThemeConfig.Colors
	local F = ThemeConfig.Font
	local K = ThemeConfig.KeybindsPage
	local stroke = C.Stroke
	local headerH = math.floor(props.categoryTitleTextSize * 1.5)

	local children: { [string]: any } = {
		VLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, K.RowGap),
		}),
		HeaderRow = React.createElement("Frame", {
			Name = "CategoryHeaderRow",
			Size = UDim2.new(1, 0, 0, headerH),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, {
			Title = React.createElement("TextLabel", {
				Name = "CategoryTitle",
				Size = UDim2.new(1, 0, 1, -2),
				BackgroundTransparency = 1,
				Text = props.categoryTitle,
				TextColor3 = C.Text.Secondary,
				Font = F.Family,
				TextSize = props.categoryTitleTextSize,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Underline = React.createElement("Frame", {
				Name = "Underline",
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = stroke.Default,
				BackgroundTransparency = stroke.Transparency,
				BorderSizePixel = 0,
			}),
		}),
	}

	for i, rowProp in props.rowProps do
		local merged = table.clone(rowProp)
		merged.layoutOrder = i + 1
		children["Row_" .. tostring(i)] = React.createElement(KeybindRow, merged)
	end

	return React.createElement("Frame", {
		Name = "CategorySection_" .. props.categoryTitle,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		ZIndex = LayoutConfig.ZIndex.Content,
	}, children)
end

return KeybindCategorySection
