--!strict
-- Left panel: Backpack, Armor, 2 Weapon Cards

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local EquipmentSlot = require(script.Parent:WaitForChild("EquipmentSlot"))
local WeaponCard = require(script.Parent:WaitForChild("WeaponCard"))
type EquipmentData = InventoryTypes.EquipmentData
type WeaponData = InventoryTypes.WeaponData
type EquipmentSlotId = InventoryTypes.EquipmentSlotId

export type EquipmentPanelProps = {
	equipment: EquipmentData?,
	weapons: { [number]: WeaponData? }?,
	columnWidth: number?,
	inventorySlotSize: number?,
	onEquipmentClick: (slotId: EquipmentSlotId) -> (),
	onAbilityClick: (weaponIndex: number, abilityIndex: number) -> (),
}

local P = ThemeConfig.Padding
local F = ThemeConfig.Font
local C = ThemeConfig.Colors

local function EquipmentPanel(props: EquipmentPanelProps)
	local equipment = (props.equipment or {}) :: EquipmentData
	local weapons = props.weapons or {}
	local columnWidth = props.columnWidth or 250
	local inventorySlotSize = props.inventorySlotSize or 64

	return React.createElement("Frame", {
		Name = "EquipmentPanel",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, P.HeaderToContent),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = React.createElement("TextLabel", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, F.SectionHeaderHeight),
			BackgroundTransparency = 1,
			Text = "EQUIPMENT",
			TextColor3 = C.Text.Primary,
			Font = F.Family,
			TextSize = F.SectionHeaderSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
		}),
		CardRows = React.createElement("Frame", {
			Name = "CardRows",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, P.CardRowGap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			TopRow = React.createElement("Frame", {
				Name = "TopRow",
				Size = UDim2.new(1, 0, 0, inventorySlotSize),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, P.BackpackArmorGap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Backpack = React.createElement(GradientBorder, {
				size = UDim2.new(0.5, -P.BackpackArmorGap / 2, 1, 0),
				fitWithin = true,
				layoutOrder = 1,
				onActivated = function()
					props.onEquipmentClick("Backpack")
				end,
			}, {
				Slot = React.createElement(EquipmentSlot, {
					slotId = "Backpack",
					label = "Backpack",
					item = equipment["Backpack" :: EquipmentSlotId],
					layoutOrder = 1,
					size = UDim2.new(1, 0, 1, 0),
					onClick = function()
						props.onEquipmentClick("Backpack")
					end,
				}),
			}),
			Armor = React.createElement(GradientBorder, {
				size = UDim2.new(0.5, -P.BackpackArmorGap / 2, 1, 0),
				fitWithin = true,
				layoutOrder = 2,
				onActivated = function()
					props.onEquipmentClick("Armor")
				end,
			}, {
				Slot = React.createElement(EquipmentSlot, {
					slotId = "Armor",
					label = "Armor",
					item = equipment["Armor" :: EquipmentSlotId],
					layoutOrder = 2,
					size = UDim2.new(1, 0, 1, 0),
					onClick = function()
						props.onEquipmentClick("Armor")
					end,
				}),
			}),
		}),
		Weapon1 = React.createElement(WeaponCard, {
			weaponIndex = 1,
			weapon = weapons[1],
			slotLabel = "Weapon 1",
			panelWidth = columnWidth,
			layoutOrder = 2,
			onAbilityClick = function(i)
				props.onAbilityClick(1, i)
			end,
		}),
		Weapon2 = React.createElement(WeaponCard, {
			weaponIndex = 2,
			weapon = weapons[2],
			slotLabel = "Weapon 2",
			panelWidth = columnWidth,
			layoutOrder = 3,
			onAbilityClick = function(i)
				props.onAbilityClick(2, i)
			end,
		}),
		}),
	})
end

return EquipmentPanel
