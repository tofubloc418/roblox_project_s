--!strict
-- AbilityPage: Root container for the Abilities tab.
-- Three-column layout: WeaponTagsColumn | UnlockedAbilitiesColumn | AbilityDetailsColumn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local WeaponTagsColumn = require(script.Parent:WaitForChild("WeaponTagsColumn"))
local UnlockedAbilitiesColumn = require(script.Parent:WaitForChild("UnlockedAbilitiesColumn"))
local AbilityDetailsColumn = require(script.Parent:WaitForChild("AbilityDetailsColumn"))

type AbilityPresetsData = { [string]: { [number]: { aid: string, ult: boolean? }? } }

export type AbilityPageProps = {
	viewportSize: Vector2,
	abilityPresets: AbilityPresetsData,
	unlockedAbilities: { [string]: boolean },
	dragEnabled: boolean?,
}

local A = ThemeConfig.AbilitiesPage
local P = ThemeConfig.Padding

local function AbilityPage(props: AbilityPageProps)
	local expandedTags, setExpandedTags = React.useState({} :: { [string]: boolean })
	local selectedAbilityId, setSelectedAbilityId = React.useState(nil :: string?)

	local totalRatio = A.ColumnRatioTags + A.ColumnRatioPool + A.ColumnRatioDetails
	local tagsFrac = A.ColumnRatioTags / totalRatio
	local poolFrac = A.ColumnRatioPool / totalRatio
	local detailsFrac = A.ColumnRatioDetails / totalRatio

	local columnGap = P.ColumnGap

	return React.createElement("Frame", {
		Name = "AbilityPageRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		TagsColumn = React.createElement("Frame", {
			Name = "TagsColumnFrame",
			Size = UDim2.new(tagsFrac, -columnGap, 1, 0),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
		}, {
			Inner = React.createElement(WeaponTagsColumn, {
				viewportSize = props.viewportSize,
				abilityPresets = props.abilityPresets,
				expandedTags = expandedTags,
				onTagSelected = function(tag: string)
					local next = table.clone(expandedTags)
					next[tag] = if next[tag] then nil else true
					setExpandedTags(next)
				end,
				onAbilityClicked = function(abilityId: string)
					setSelectedAbilityId(abilityId)
				end,
				onPresetSlotClicked = function(_tag: string, _slotIndex: number)
					-- no-op: slots are filled via drag-drop
				end,
				dragEnabled = props.dragEnabled,
			}),
		}),
		PoolColumn = React.createElement("Frame", {
			Name = "PoolColumnFrame",
			Size = UDim2.new(poolFrac, -columnGap, 1, 0),
			Position = UDim2.new(tagsFrac, 0, 0, 0),
			BackgroundTransparency = 1,
		}, {
			Inner = React.createElement(UnlockedAbilitiesColumn, {
				viewportSize = props.viewportSize,
				unlockedAbilities = props.unlockedAbilities,
				onAbilityClicked = function(abilityId: string)
					setSelectedAbilityId(abilityId)
				end,
				dragEnabled = props.dragEnabled,
			}),
		}),
		DetailsColumn = React.createElement("Frame", {
			Name = "DetailsColumnFrame",
			Size = UDim2.new(detailsFrac, 0, 1, 0),
			Position = UDim2.new(tagsFrac + poolFrac, 0, 0, 0),
			BackgroundTransparency = 1,
		}, {
			Inner = React.createElement(AbilityDetailsColumn, {
				viewportSize = props.viewportSize,
				selectedAbilityId = selectedAbilityId,
			}),
		}),
	})
end

return AbilityPage
