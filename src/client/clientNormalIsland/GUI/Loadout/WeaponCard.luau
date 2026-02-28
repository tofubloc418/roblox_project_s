--!strict
-- Weapon slot with 5 ability sub-slots inside a contained card (Arc Raiders style)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local AbilitySlot = require(script.Parent:WaitForChild("AbilitySlot"))
type WeaponData = InventoryTypes.WeaponData

export type WeaponCardProps = {
	weaponIndex: number,
	weapon: WeaponData?,
	slotLabel: string,
	panelWidth: number?,
	layoutOrder: number?,
	onAbilityClick: (index: number) -> (),
}

local ABILITY_COUNT = 5

local P = ThemeConfig.Padding
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius
local F = ThemeConfig.Font
local L = ThemeConfig.Loadout

local function WeaponCard(props: WeaponCardProps)
	local weapon = props.weapon
	local imageId = ""
	-- Show label only when slot is empty; hide when weapon is equipped
	local displayText = if weapon then "" else props.slotLabel
	local panelWidth = props.panelWidth or 250

	-- Outer card: height:width = 6:9
	local outerCardHeight = math.floor(panelWidth * L.OuterCardHeightRatio)
	-- Inner card (weapon visual) fills remaining space after abilities row and padding
	local contentHeight = outerCardHeight - P.Card * 2
	local weaponSlotHeight = math.max(0, contentHeight - P.Card - L.AbilitySlotSize)

	if weapon then
		local icon = ItemIconResolver.getIconForItem(weapon.itemId)
		if icon then
			imageId = icon
		end
	end

	local borderWidth = ThemeConfig.GradientBorder and ThemeConfig.GradientBorder.BorderWidth or 2
	local innerAbilitySize = L.AbilitySlotSize - 2 * borderWidth

	local abilitySlots: { [string | number]: any } = {}
	for i = 1, ABILITY_COUNT do
		abilitySlots["Ability" .. i] = React.createElement(GradientBorder, {
			size = innerAbilitySize,
			layoutOrder = i,
			cornerRadius = R.SlotSmall,
			onActivated = function()
				props.onAbilityClick(i)
			end,
		}, {
			Slot = React.createElement(AbilitySlot, {
				index = i,
				ability = weapon and weapon.abilities[i] or nil,
				size = innerAbilitySize,
				onClick = function()
					props.onAbilityClick(i)
				end,
			}),
		})
	end

	return React.createElement("Frame", {
		Name = "WeaponCard_" .. tostring(props.weaponIndex),
		Size = UDim2.new(1, 0, 0, outerCardHeight),
		BackgroundColor3 = C.Card,
		BackgroundTransparency = C.CardTransparency,
		LayoutOrder = props.layoutOrder or props.weaponIndex,
		ClipsDescendants = true,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Card) }),
		Stroke = React.createElement("UIStroke", {
			Thickness = C.Stroke.Thickness,
			Color = C.Stroke.Default,
			Transparency = C.Stroke.Transparency,
		}),
		Content = React.createElement("Frame", {
			Name = "Content",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, P.Card),
				PaddingBottom = UDim.new(0, P.Card),
				PaddingLeft = UDim.new(0, P.Card),
				PaddingRight = UDim.new(0, P.Card),
			}),
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, P.Card),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			WeaponSlot = React.createElement(GradientBorder, {
				size = UDim2.new(1, 0, 0, weaponSlotHeight),
				fitWithin = true,
				layoutOrder = 1,
				cornerRadius = R.SlotSmall,
			}, {
			Slot = React.createElement("ImageButton", {
					Name = "WeaponSlot",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = C.Slot,
				BackgroundTransparency = C.SlotTransparency,
				AutoButtonColor = false,
				Image = imageId,
				ImageTransparency = imageId == "" and 1 or 0,
				ZIndex = LayoutConfig.ZIndex.Content,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.SlotSmall) }),
				Stroke = React.createElement("UIStroke", {
					Thickness = C.Stroke.Thickness,
					Color = C.Stroke.Default,
					Transparency = C.Stroke.Transparency,
				}),
				Label = React.createElement("TextLabel", {
					Size = UDim2.fromScale(1, F.SlotLabelHeightScale),
					Position = LayoutConfig.SlotLabel.Equipment.Position,
					AnchorPoint = LayoutConfig.SlotLabel.Equipment.AnchorPoint,
					BackgroundTransparency = 1,
					TextScaled = true,
					TextColor3 = C.Text.Secondary,
					Font = F.FamilySecondary,
					Text = displayText,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = LayoutConfig.ZIndex.Content,
				}),
			}),
			}),
			AbilitiesRow = React.createElement("Frame", {
				Name = "AbilitiesRow",
				Size = UDim2.new(1, 0, 0, L.AbilitySlotSize),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, P.AbilitySlot),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				Ability1 = abilitySlots["Ability1"],
				Ability2 = abilitySlots["Ability2"],
				Ability3 = abilitySlots["Ability3"],
				Ability4 = abilitySlots["Ability4"],
				Ability5 = abilitySlots["Ability5"],
			}),
		}),
	})
end

return WeaponCard
