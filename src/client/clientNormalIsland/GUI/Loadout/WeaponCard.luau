--!strict
-- Weapon slot with 5 ability sub-slots inside a contained card (Arc Raiders style)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local ItemIconResolver = require(script.Parent:WaitForChild("ItemIconResolver"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local AbilitySlot = require(script.Parent:WaitForChild("AbilitySlot"))
type WeaponData = InventoryTypes.WeaponData
type EquipmentSlotId = InventoryTypes.EquipmentSlotId

export type WeaponCardProps = {
	weaponIndex: number,
	weapon: WeaponData?,
	slotLabel: string,
	panelWidth: number?,
	scale: number?,
	layoutOrder: number?,
	dragEnabled: boolean?,
	onWeaponClick: () -> (),
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
	local scale = props.scale or 1
	local slotId: EquipmentSlotId = if props.weaponIndex == 1 then "Weapon1" else "Weapon2"
	-- Use GradientBorder container so hover and drop targeting share the same region.
	local weaponSlotContainerRef = React.useRef(nil :: GuiObject?)

	local scaledCard = math.floor(P.Card * scale)
	local scaledAbilityGap = math.floor(P.AbilitySlot * scale)

	-- Ability slots: cap by width so they fit when column is narrow; use min scale so they don't shrink too fast vertically
	local availableWidth = panelWidth - 2 * scaledCard - 4 * scaledAbilityGap
	local maxAbilitySizeFromWidth = math.floor(availableWidth / 5)
	local abilityScale = math.max(scale, L.AbilitySlotMinScale or 0.65)
	local abilitySlotSize = math.min(
		math.floor(L.AbilitySlotSize * abilityScale),
		math.max(1, maxAbilitySizeFromWidth)
	)

	-- Outer card: height:width = 6:9
	local outerCardHeight = math.floor(panelWidth * L.OuterCardHeightRatio)
	-- Inner card (weapon visual) fills remaining space after abilities row and padding
	local contentHeight = outerCardHeight - scaledCard * 2
	local weaponSlotHeight = math.max(0, contentHeight - scaledCard - abilitySlotSize)

	if weapon then
		local icon = ItemIconResolver.getIconForItem(weapon.itemId)
		if icon then
			imageId = icon
		end
	end

	local function handleMouseButton1Down()
		if not props.dragEnabled or not weapon then
			return
		end

		DragDropManager.prepareDrag({
			container = "equipment",
			slotId = slotId,
		}, {
			imageId = imageId,
			labelText = displayText,
			stackText = "",
		})
	end

	local function handleActivated()
		if DragDropManager.consumeActivatedSuppression() then
			return
		end

		props.onWeaponClick()
	end

	local borderWidth = ThemeConfig.GradientBorder and ThemeConfig.GradientBorder.BorderWidth or 2
	local innerAbilitySize = math.max(1, abilitySlotSize - 2 * borderWidth)

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
				PaddingTop = UDim.new(0, scaledCard),
				PaddingBottom = UDim.new(0, scaledCard),
				PaddingLeft = UDim.new(0, scaledCard),
				PaddingRight = UDim.new(0, scaledCard),
			}),
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, scaledCard),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			WeaponSlot = React.createElement(GradientBorder, {
				size = UDim2.new(1, 0, 0, weaponSlotHeight),
				fitWithin = true,
				layoutOrder = 1,
				cornerRadius = R.SlotSmall,
				containerRef = weaponSlotContainerRef,
				onMouseEnter = function()
					DragDropManager.notifyHoverEnter({
						container = "equipment",
						slotId = slotId,
					})
				end,
				onMouseLeave = function()
					DragDropManager.notifyHoverLeave({
						container = "equipment",
						slotId = slotId,
					})
				end,
				onMouseButton1Down = handleMouseButton1Down,
				onActivated = handleActivated,
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
				[React.Event.MouseButton1Down] = handleMouseButton1Down,
				[React.Event.Activated] = handleActivated,
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
				Size = UDim2.new(1, 0, 0, abilitySlotSize),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, scaledAbilityGap),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
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
