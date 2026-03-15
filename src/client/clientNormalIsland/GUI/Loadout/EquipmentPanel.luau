--!strict
-- Left panel: Backpack, Armor, 2 Weapon Cards

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))
local EquipmentSlot = require(script.Parent:WaitForChild("EquipmentSlot"))
local WeaponCard = require(script.Parent:WaitForChild("WeaponCard"))
type EquipmentData = InventoryTypes.EquipmentData
type WeaponData = InventoryTypes.WeaponData
type EquipmentSlotId = InventoryTypes.EquipmentSlotId

export type EquipmentPanelProps = {
	equipment: EquipmentData?,
	weapons: { [number]: WeaponData? }?,
	columnWidth: number?,
	backpackSlotSize: number?,
	scale: number?,
	dragEnabled: boolean?,
	onEquipmentDragStart: (slotId: EquipmentSlotId) -> (),
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
	local backpackSlotSize = props.backpackSlotSize or 64
	local scale = props.scale or 1

	local scaledHeaderHeight = math.floor(F.SectionHeaderHeight * scale)
	local scaledHeaderSize = math.floor(F.SectionHeaderSize * scale)
	local scaledHeaderToContent = math.floor(P.HeaderToContent * scale)
	local scaledCardRowGap = math.floor(P.CardRowGap * scale)
	local scaledBackpackArmorGap = math.floor(P.BackpackArmorGap * scale)

	local backpackContainerRef = React.useRef(nil :: GuiObject?)
	local armorContainerRef = React.useRef(nil :: GuiObject?)

	return React.createElement("Frame", {
		Name = "EquipmentPanel",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, scaledHeaderToContent),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = React.createElement("TextLabel", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, scaledHeaderHeight),
			BackgroundTransparency = 1,
			Text = "EQUIPMENT",
			TextColor3 = C.Text.Primary,
			Font = F.Family,
			TextSize = scaledHeaderSize,
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
				Padding = UDim.new(0, scaledCardRowGap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			TopRow = React.createElement("Frame", {
				Name = "TopRow",
				Size = UDim2.new(1, 0, 0, backpackSlotSize),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, scaledBackpackArmorGap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Backpack = React.createElement(GradientBorder, {
				size = UDim2.new(0.5, -scaledBackpackArmorGap / 2, 1, 0),
				fitWithin = true,
				layoutOrder = 1,
				containerRef = backpackContainerRef,
				onMouseEnter = function()
					DragDropManager.notifyHoverEnter({
						container = "equipment",
						slotId = "Backpack",
					})
				end,
				onMouseLeave = function()
					DragDropManager.notifyHoverLeave({
						container = "equipment",
						slotId = "Backpack",
					})
				end,
				onMouseButton1Down = function()
					props.onEquipmentDragStart("Backpack")
				end,
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
					dragEnabled = props.dragEnabled,
					onClick = function()
						props.onEquipmentClick("Backpack")
					end,
				}),
			}),
			Armor = React.createElement(GradientBorder, {
				size = UDim2.new(0.5, -scaledBackpackArmorGap / 2, 1, 0),
				fitWithin = true,
				layoutOrder = 2,
				containerRef = armorContainerRef,
				onMouseEnter = function()
					DragDropManager.notifyHoverEnter({
						container = "equipment",
						slotId = "Armor",
					})
				end,
				onMouseLeave = function()
					DragDropManager.notifyHoverLeave({
						container = "equipment",
						slotId = "Armor",
					})
				end,
				onMouseButton1Down = function()
					props.onEquipmentDragStart("Armor")
				end,
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
					dragEnabled = props.dragEnabled,
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
			scale = scale,
			layoutOrder = 2,
			dragEnabled = props.dragEnabled,
			onWeaponClick = function()
				props.onEquipmentClick("Weapon1")
			end,
			onAbilityClick = function(i)
				props.onAbilityClick(1, i)
			end,
		}),
		Weapon2 = React.createElement(WeaponCard, {
			weaponIndex = 2,
			weapon = weapons[2],
			slotLabel = "Weapon 2",
			panelWidth = columnWidth,
			scale = scale,
			layoutOrder = 3,
			dragEnabled = props.dragEnabled,
			onWeaponClick = function()
				props.onEquipmentClick("Weapon2")
			end,
			onAbilityClick = function(i)
				props.onAbilityClick(2, i)
			end,
		}),
		}),
	})
end

return EquipmentPanel
