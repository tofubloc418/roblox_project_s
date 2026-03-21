--!strict
-- Abilities page column: unlocked abilities grid (pool drag sources).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))

export type UnlockedAbilitiesColumnProps = {
	viewportSize: Vector2,
	unlockedAbilities: { [string]: boolean },
	onAbilityClicked: (abilityId: string) -> (),
	dragEnabled: boolean?,
}

local A = ThemeConfig.AbilitiesPage
local C = ThemeConfig.Colors
local F = ThemeConfig.Font
local R = ThemeConfig.CornerRadius
local AZ = LayoutConfig.Settings.AbilitiesPage

local function UnlockedAbilitiesColumn(props: UnlockedAbilitiesColumnProps)
	local query, setQuery = React.useState("")

	-- Build sorted list of unlocked ability IDs
	local sortedIds = React.useMemo(function()
		local ids: { string } = {}
		for abilityId, unlocked in pairs(props.unlockedAbilities) do
			if unlocked then
				table.insert(ids, abilityId)
			end
		end
		table.sort(ids)
		return ids
	end, { props.unlockedAbilities } :: { any })

	local queryLower = string.lower(query)

	local gridChildren: { [string]: any } = {}
	gridChildren["_Layout"] = React.createElement("UIGridLayout", {
		CellSize = UDim2.fromOffset(A.PoolSlotSize, A.PoolSlotSize),
		CellPadding = UDim2.fromOffset(A.PoolSlotGap, A.PoolSlotGap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = A.PoolCols,
	})

	for order, abilityId in ipairs(sortedIds) do
		local config = AbilityRegistry.GetAbility(abilityId)
		local displayName = if config and config.displayName then config.displayName else abilityId

		-- Filter by query
		if queryLower ~= "" and not string.find(string.lower(displayName), queryLower, 1, true) then
			continue
		end

		local iconId = if config then config.iconId else ""
		local hasIcon = iconId ~= nil and iconId ~= ""

		local capturedId = abilityId
		gridChildren["Ability_" .. abilityId] = React.createElement(GradientBorder, {
			size = A.PoolSlotSize,
			fitWithin = true,
			cornerRadius = R.Slot,
			layoutOrder = order,
			onActivated = function()
				props.onAbilityClicked(capturedId)
			end,
			onMouseButton1Down = function()
				if not props.dragEnabled then return end
				DragDropManager.prepareDrag({
					container = "ability_pool",
					slotId = capturedId,
				}, {
					imageId = iconId or "",
					labelText = if hasIcon then "" else displayName,
					stackText = "",
				})
			end,
			children = {
				Slot = React.createElement("Frame", {
					Name = "AbilitySlot",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = C.Slot,
					BackgroundTransparency = if hasIcon then 1 else C.SlotTransparency,
					ClipsDescendants = true,
					ZIndex = LayoutConfig.ZIndex.Content,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
					Icon = if hasIcon then React.createElement("ImageLabel", {
						Size = UDim2.new(1, 0, 1, 0),
						Position = UDim2.fromScale(0, 0),
						AnchorPoint = Vector2.new(0, 0),
						BackgroundTransparency = 1,
						ClipsDescendants = true,
						Image = iconId,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = LayoutConfig.ZIndex.Content,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
					}) else nil,
					Label = if not hasIcon then React.createElement("TextLabel", {
						Size = UDim2.fromScale(0.9, 0.9),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Text = displayName,
						TextColor3 = C.Text.Primary,
						Font = F.FamilySecondary,
						TextScaled = true,
						TextWrapped = true,
						ZIndex = LayoutConfig.ZIndex.Content,
					}) else nil,
				}),
			},
		})
	end

	return React.createElement("Frame", {
		Name = "UnlockedAbilitiesColumn",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Header = React.createElement("Frame", {
			Name = "PoolHeader",
			Size = UDim2.new(1, 0, 0, A.TagHeaderHeight),
			BackgroundTransparency = 1,
			ZIndex = AZ.ChromeZIndex,
		}, {
			Title = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "LEARNED ABILITIES",
				TextColor3 = C.Text.Primary,
				Font = F.Family,
				TextSize = F.TitleSize * 0.55,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = AZ.ChromeZIndex,
			}),
		}),
		SearchBar = React.createElement("Frame", {
			Name = "PoolSearch",
			Size = UDim2.new(1, 0, 0, A.SearchBarHeight),
			Position = UDim2.fromOffset(0, A.TagHeaderHeight + A.SearchBarGap),
			BackgroundColor3 = C.MainFrame,
			BackgroundTransparency = 0.1,
			ZIndex = AZ.ChromeZIndex,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
			Stroke = React.createElement("UIStroke", {
				Color = C.Stroke.Default,
				Thickness = C.Stroke.Thickness,
				Transparency = C.Stroke.Transparency,
			}),
			Pad = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
			Input = React.createElement("TextBox", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = query,
				PlaceholderText = "Search...",
				PlaceholderColor3 = C.Text.Secondary,
				TextColor3 = C.Text.Primary,
				Font = F.FamilySecondary,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				ZIndex = AZ.ChromeZIndex,
				[React.Event.Changed] = function(rbx: TextBox)
					setQuery(rbx.Text)
				end,
			}),
		}),
		ScrollArea = React.createElement("ScrollingFrame", {
			Name = "PoolScroll",
			Size = UDim2.new(1, 0, 1, -(A.TagHeaderHeight + A.SearchBarGap + A.SearchBarHeight + A.SearchBarGap)),
			Position = UDim2.fromOffset(0, A.TagHeaderHeight + A.SearchBarGap + A.SearchBarHeight + A.SearchBarGap),
			BackgroundTransparency = 1,
			ScrollBarThickness = ThemeConfig.Colors.ScrollBar.Thickness,
			ScrollBarImageColor3 = ThemeConfig.Colors.ScrollBar.Color,
			ScrollBarImageTransparency = ThemeConfig.Colors.ScrollBar.Transparency,
			CanvasSize = UDim2.fromScale(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, gridChildren),
	})
end

return UnlockedAbilitiesColumn
