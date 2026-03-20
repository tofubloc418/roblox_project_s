--!strict
-- AbilityDetailsColumn: Column 3 of the Abilities page.
-- Shows enlarged icon, description, and compatible weapon tags for the selected ability.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))
local ItemEnums = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemEnums"))

export type AbilityDetailsColumnProps = {
	viewportSize: Vector2,
	selectedAbilityId: string?,
}

local A = ThemeConfig.AbilitiesPage
local C = ThemeConfig.Colors
local F = ThemeConfig.Font
local R = ThemeConfig.CornerRadius

local function AbilityDetailsColumn(props: AbilityDetailsColumnProps)
	local abilityId = props.selectedAbilityId
	local config = if abilityId then AbilityRegistry.GetAbility(abilityId) else nil

	if not config then
		-- Empty / default state
		return React.createElement("Frame", {
			Name = "AbilityDetailsColumn",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Header = React.createElement("Frame", {
				Name = "DetailsHeader",
				Size = UDim2.new(1, 0, 0, A.TagHeaderHeight),
				BackgroundTransparency = 1,
				ZIndex = LayoutConfig.ZIndex.Content + 1,
			}, {
				Title = React.createElement("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "DETAILS",
					TextColor3 = C.Text.Primary,
					Font = F.Family,
					TextSize = F.TitleSize * 0.55,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = LayoutConfig.ZIndex.Content + 1,
				}),
			}),
			Placeholder = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, -A.TagHeaderHeight),
				Position = UDim2.fromOffset(0, A.TagHeaderHeight),
				BackgroundTransparency = 1,
				Text = "Select an ability to view details",
				TextColor3 = C.Text.Secondary,
				Font = F.FamilySecondary,
				TextSize = 16,
				TextWrapped = true,
				ZIndex = LayoutConfig.ZIndex.Content,
			}),
		})
	end

	local displayName = config.displayName or config.abilityId
	local description = config.description
	local iconId = config.iconId
	local hasIcon = iconId ~= nil and iconId ~= ""

	-- Build tag pills
	local tagPills: { [string]: any } = {}
	tagPills["_Layout"] = React.createElement("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Wraps = true,
	})
	for i, tag in ipairs(config.compatibleTags) do
		local tagDisplay = ItemEnums.WeaponTagDisplayName[tag] or tag
		tagPills["Tag_" .. tag] = React.createElement("Frame", {
			Name = "TagPill",
			Size = UDim2.new(0, 0, 0, A.DetailsTagPillHeight),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = C.Slot,
			BackgroundTransparency = 0,
			LayoutOrder = i,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.SlotSmall) }),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
			Label = React.createElement("TextLabel", {
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = tagDisplay,
				TextColor3 = C.Text.Primary,
				Font = F.FamilySecondary,
				TextSize = 14,
			}),
		})
	end

	return React.createElement("Frame", {
		Name = "AbilityDetailsColumn",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Header = React.createElement("Frame", {
			Name = "DetailsHeader",
			Size = UDim2.new(1, 0, 0, A.TagHeaderHeight),
			BackgroundTransparency = 1,
			ZIndex = LayoutConfig.ZIndex.Content + 1,
		}, {
			Title = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "DETAILS",
				TextColor3 = C.Text.Primary,
				Font = F.Family,
				TextSize = F.TitleSize * 0.55,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = LayoutConfig.ZIndex.Content + 1,
			}),
		}),
		Content = React.createElement("Frame", {
			Name = "DetailsContent",
			Size = UDim2.new(1, 0, 1, -A.TagHeaderHeight),
			Position = UDim2.fromOffset(0, A.TagHeaderHeight),
			BackgroundTransparency = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			-- Large icon
			IconFrame = React.createElement("Frame", {
				Name = "IconFrame",
				Size = UDim2.fromOffset(A.DetailsIconSize, A.DetailsIconSize),
				BackgroundColor3 = C.Slot,
				BackgroundTransparency = C.SlotTransparency,
				LayoutOrder = 1,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
				Stroke = React.createElement("UIStroke", {
					Color = C.Stroke.Default,
					Thickness = C.Stroke.Thickness,
					Transparency = C.Stroke.Transparency,
				}),
				Icon = if hasIcon then React.createElement("ImageLabel", {
					Size = UDim2.fromScale(0.85, 0.85),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = iconId,
					ScaleType = Enum.ScaleType.Fit,
				}) else nil,
				Label = if not hasIcon then React.createElement("TextLabel", {
					Size = UDim2.fromScale(0.85, 0.85),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Text = displayName,
					TextColor3 = C.Text.Primary,
					Font = F.FamilySecondary,
					TextScaled = true,
					TextWrapped = true,
				}) else nil,
			}),
			-- Name
			NameLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Text = displayName,
				TextColor3 = C.Text.Primary,
				Font = F.Family,
				TextSize = F.SectionHeaderSize * 0.85,
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 2,
			}),
			-- Ultimate badge
			UltBadge = if config.isUltimate then React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = "★ ULTIMATE",
				TextColor3 = C.Stroke.Active,
				Font = F.Family,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 3,
			}) else nil,
			-- Description
			Description = if description then React.createElement("TextLabel", {
				Size = UDim2.new(1, -24, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = description,
				TextColor3 = C.Text.Secondary,
				Font = F.FamilySecondary,
				TextSize = 15,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 4,
			}) else nil,
			-- Compatible tags section
			TagsSection = React.createElement("Frame", {
				Name = "TagsSection",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 5,
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
				TagsLabel = React.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = "COMPATIBLE WEAPONS",
					TextColor3 = C.Text.Secondary,
					Font = F.Family,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Center,
					LayoutOrder = 1,
				}),
				TagPillsRow = React.createElement("Frame", {
					Name = "TagPills",
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, tagPills),
			}),
		}),
	})
end

return AbilityDetailsColumn
