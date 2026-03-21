--!strict
-- Abilities page: weapon tags + five preset slots per expanded tag.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local ItemEnums = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemEnums"))
local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local AbilityPresetSlot = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("AbilityPresetSlot"))

type AbilityPresetsData = { [string]: { [number]: { aid: string, ult: boolean? }? } }

export type WeaponTagsColumnProps = {
	viewportSize: Vector2,
	abilityPresets: AbilityPresetsData,
	expandedTags: { [string]: boolean },
	onTagSelected: (tag: string) -> (),
	onAbilityClicked: (abilityId: string) -> (),
	onPresetSlotClicked: (tag: string, slotIndex: number) -> (),
	dragEnabled: boolean?,
}

local A = ThemeConfig.AbilitiesPage
local C = ThemeConfig.Colors
local F = ThemeConfig.Font
local R = ThemeConfig.CornerRadius
local GB = ThemeConfig.GradientBorder
local L = ThemeConfig.Loadout    -- for WidthScale
local P = ThemeConfig.Padding    -- for OuterFrameHorizontal
local AZ = LayoutConfig.Settings.AbilitiesPage

-- Sorted list of weapon tags (alphabetical by display name)
local function getSortedTags(): { { tag: string, display: string } }
	local list: { { tag: string, display: string } } = {}
	for key, value in pairs(ItemEnums.WeaponTag) do
		local display = ItemEnums.WeaponTagDisplayName[value] or key
		table.insert(list, { tag = value, display = display })
	end
	table.sort(list, function(a, b) return a.display < b.display end)
	return list
end

type TagRowProps = {
	tag: string,
	display: string,
	expandedTags: { [string]: boolean },
	viewportSize: Vector2,
	layoutOrder: number,
	abilityPresets: AbilityPresetsData,
	onTagSelected: (tag: string) -> (),
	onAbilityClicked: (abilityId: string) -> (),
	onPresetSlotClicked: (tag: string, slotIndex: number) -> (),
	dragEnabled: boolean?,
}

local function TagRow(props: TagRowProps)
	local hovered, setHovered = React.useState(false)

	local vp = props.viewportSize
	local shellScale = math.clamp(math.min(vp.X, vp.Y) / (L.ReferenceShortEdge or 1080), 0.5, 2)
	local outerPad = math.floor(P.OuterFrameHorizontal * shellScale) * 2
	local shellContentWidth = vp.X * L.WidthScale - outerPad

	local totalRatio = A.ColumnRatioTags + A.ColumnRatioPool + A.ColumnRatioDetails
	local tagColWidth = shellContentWidth * (A.ColumnRatioTags / totalRatio) - P.ColumnGap
	local safeContentWidth = tagColWidth - C.ScrollBar.Thickness - 2

	local available = safeContentWidth - A.PresetRowPadding * 2 - A.PresetSlotGap * 4
	local slotSize = math.clamp(math.floor(available / 5), 24, 52)
	local slotGap  = A.PresetSlotGap
	local rowPad   = A.PresetRowPadding

	local tag = props.tag
	local isSelected = props.expandedTags[props.tag] == true
	local isHover = hovered and not isSelected

	local textColor = if isSelected then C.Text.Primary
		elseif isHover then A.TagHoverText
		else C.Text.Secondary

	local presetChildren: { [string]: any }? = nil
	if isSelected then
		local preset = props.abilityPresets[tag] or {}
		local pc: { [string]: any } = {}
		pc["_Layout"] = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, slotGap),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		})
		local borderW = GB.BorderWidth or 2
		local innerPx = math.max(1, slotSize - 2 * borderW)
		for i = 1, 5 do
			local abilityId, isUlt = AbilityPresetSlotUtils.readSlot(preset, i)
			pc["Slot" .. i] = React.createElement(GradientBorder, {
				size = slotSize,
				fitWithin = true,
				cornerRadius = R.SlotSmall,
				layoutOrder = i,
				onActivated = function()
					if abilityId then
						props.onAbilityClicked(abilityId)
					else
						props.onPresetSlotClicked(tag, i)
					end
				end,
				onMouseEnter = function()
					if props.dragEnabled then
						DragDropManager.notifyHoverEnter({
							container = "equipment" :: any,
							slotId = tag .. "_" .. tostring(i),
						})
					end
				end,
				onMouseLeave = function()
					if props.dragEnabled then
						DragDropManager.notifyHoverLeave({
							container = "equipment" :: any,
							slotId = tag .. "_" .. tostring(i),
						})
					end
				end,
				children = {
					Slot = React.createElement(AbilityPresetSlot, {
						aid = abilityId,
						isUlt = isUlt,
						variant = "settings",
						pixelSize = innerPx,
						layoutOrder = 0,
						zIndex = LayoutConfig.ZIndex.Content,
					}),
				},
			})
		end
		presetChildren = pc
	end

	local totalPresetHeight = if isSelected then slotSize + rowPad * 2 else 0
	local rowHeight = A.TagRowHeight + totalPresetHeight

	return React.createElement("TextButton", {
		Name = "TagRow_" .. tag,
		Size = UDim2.new(1, 0, 0, rowHeight),
		BackgroundColor3 = if isSelected then A.TagSelectedColor else C.Slot,
		BackgroundTransparency = if isSelected then A.TagSelectedTransparency else C.SlotTransparency,
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,
		Text = "",
		ZIndex = LayoutConfig.ZIndex.AbilitiesTagRowBackground,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
		[React.Event.Activated] = function()
			props.onTagSelected(tag)
		end,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
		Stroke = React.createElement("UIStroke", {
			Color = if isSelected then C.Stroke.Active else C.Stroke.Default,
			Thickness = if isSelected then C.Stroke.ActiveThickness else C.Stroke.Thickness,
			Transparency = C.Stroke.Transparency,
		}),
		NameLabel = React.createElement("TextLabel", {
			Size = UDim2.new(1, -16, 0, A.TagRowHeight),
			Position = UDim2.fromOffset(12, 0),
			BackgroundTransparency = 1,
			Text = props.display,
			TextColor3 = textColor,
			Font = F.FamilySecondary,
			TextSize = F.SectionHeaderSize * 0.9,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),
		PresetRow = if presetChildren then React.createElement("Frame", {
			Name = "PresetRow",
			Size = UDim2.new(1, -rowPad * 2, 0, slotSize),
			Position = UDim2.new(0, rowPad, 0, A.TagRowHeight + rowPad),
			BackgroundTransparency = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, presetChildren) else nil,
	})
end

local function WeaponTagsColumn(props: WeaponTagsColumnProps)
	local sortedTags = React.useMemo(getSortedTags, {})
	local query, setQuery = React.useState("")

	local queryLower = string.lower(query)

	local children: { [string]: any } = {}
	children["_Layout"] = React.createElement("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, A.TagRowGap),
	})

	for order, entry in ipairs(sortedTags) do
		if queryLower == "" or string.find(string.lower(entry.display), queryLower, 1, true) then
			local tag = entry.tag
			children["Tag_" .. tag] = React.createElement(TagRow, {
				tag = tag,
				display = entry.display,
				expandedTags = props.expandedTags,
				viewportSize = props.viewportSize,
				layoutOrder = order,
				abilityPresets = props.abilityPresets,
				onTagSelected = props.onTagSelected,
				onAbilityClicked = props.onAbilityClicked,
				onPresetSlotClicked = props.onPresetSlotClicked,
				dragEnabled = props.dragEnabled,
			})
		end
	end


	return React.createElement("Frame", {
		Name = "WeaponTagsColumn",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Header = React.createElement("Frame", {
			Name = "TagsHeader",
			Size = UDim2.new(1, 0, 0, A.TagHeaderHeight),
			BackgroundTransparency = 1,
			ZIndex = AZ.ChromeZIndex,
		}, {
			Title = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "WEAPONS",
				TextColor3 = C.Text.Primary,
				Font = F.Family,
				TextSize = F.TitleSize * 0.55,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = AZ.ChromeZIndex,
			}),
		}),
		SearchBar = React.createElement("Frame", {
			Name = "TagsSearch",
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
			Name = "TagsScroll",
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
		}, children),
	})
end

return WeaponTagsColumn
