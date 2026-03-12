--!strict
--[[
	HudLoadoutApp
	=============
	Root React component for the in-game HUD equipment section.

	Props flow: controller reads from DataAdapter → passes HudLoadoutState
	down to this component → distributes to sub-components. No sub-component
	calls the adapter directly.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local HudLoadoutTypes = require(script.Parent:WaitForChild("HudLoadoutTypes"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local ItemIconResolver = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("ItemIconResolver"))

local HudActionRow = require(script.Parent:WaitForChild("HudActionRow"))
local HudSlotCard = require(script.Parent:WaitForChild("HudSlotCard"))
local HudWeaponCard = require(script.Parent:WaitForChild("HudWeaponCard"))

type HudLoadoutState = HudLoadoutTypes.HudLoadoutState

local H = ThemeConfig.HudLoadout
local L = LayoutConfig.HudLoadout

-- Fists placeholder icon — nil means the slot renders empty (no icon).
-- Swap with a real asset id once available.
local FISTS_ICON: string? = nil

export type HudLoadoutAppProps = {
	state: HudLoadoutState,
	viewportSize: Vector2,
	-- Callbacks wired by the controller
	onSlot1: () -> (),
	onSlot2: () -> (),
	onSlot3: () -> (),
	onQuickUse: () -> (),
}

local function HudLoadoutApp(props: HudLoadoutAppProps)
	local state = props.state

	-- Resolve quick-slot current item icon
	local quickImageId: string = ""
	if state.currentQuickSlotIndex then
		local currentItem = state.quickUseItems[state.currentQuickSlotIndex]
		if currentItem then
			local icon = ItemIconResolver.getIconForItem(currentItem.itemId)
			quickImageId = icon or ""
		end
	end

	-- Resolve weapon icons
	local weapon1ImageId = ""
	local weapon2ImageId = ""
	if state.weapon1 then
		local icon = ItemIconResolver.getIconForItem(state.weapon1.itemId)
		weapon1ImageId = icon or ""
	end
	if state.weapon2 then
		local icon = ItemIconResolver.getIconForItem(state.weapon2.itemId)
		weapon2ImageId = icon or ""
	end

	-- showVisual: per spec §5, visual is shown for the expandedWeapon slot.
	-- expandedWeapon is only updated when switching between weapon1 and weapon2.
	local show1 = state.expandedWeapon == "Weapon1"
	local show2 = state.expandedWeapon == "Weapon2"

	-- Weapon slots are square, same size as Q and 3
	local slotSize = H.SlotSize

	return React.createElement("Frame", {
		Name = "HudLoadoutApp",
		AnchorPoint = L.AnchorPoint,
		Position = L.Position,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, {
		-- Outer layout: action row on top, slot columns below
		OuterLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),

		-- ── Action row (flashlight key) ────────────────────────────────────
		ActionRow = React.createElement(HudActionRow, {
			flashlightOn = state.flashlightOn,
			layoutOrder = 1,
		}),

		-- ── Three-column slot area ─────────────────────────────────────────
		ColumnsFrame = React.createElement("Frame", {
			Name = "ColumnsFrame",
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			ColumnsLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, H.ColumnGap),
			}),

			-- ── Column 1: Q (quick-use) ──────────────────────────────────
			ColQuick = React.createElement(HudSlotCard, {
				keybind = "Q",
				iconImage = quickImageId ~= "" and quickImageId or nil,
				isActive = state.activeSlot == "QuickUse",
				size = H.SlotSize,
				layoutOrder = 1,
				onActivated = props.onQuickUse,
			}),

			-- ── Column 2: 3 (fists / unequip) ───────────────────────────
			ColFists = React.createElement(HudSlotCard, {
				keybind = "3",
				iconImage = FISTS_ICON,
				isActive = state.activeSlot == "Fists",
				size = H.SlotSize,
				layoutOrder = 2,
				onActivated = props.onSlot3,
			}),

			-- ── Column 3: weapon slots (stacked vertically, square like Q and 3) ──────────────
			ColWeapons = React.createElement("Frame", {
				Name = "ColWeapons",
				Size = UDim2.new(0, slotSize, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				WeaponsLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, H.ColumnGap),
				}),

				Weapon1Card = React.createElement(HudWeaponCard, {
					keybind = "1",
					weaponName = state.weapon1 and state.weapon1.displayName or nil,
					iconImage = weapon1ImageId ~= "" and weapon1ImageId or nil,
					isActive = state.activeSlot == "Weapon1",
					showVisual = show1,
					width = slotSize,
					layoutOrder = 1,
					onActivated = props.onSlot1,
				}),

				Weapon2Card = React.createElement(HudWeaponCard, {
					keybind = "2",
					weaponName = state.weapon2 and state.weapon2.displayName or nil,
					iconImage = weapon2ImageId ~= "" and weapon2ImageId or nil,
					isActive = state.activeSlot == "Weapon2",
					showVisual = show2,
					width = slotSize,
					layoutOrder = 2,
					onActivated = props.onSlot2,
				}),
			}),
		}),
	})
end

return HudLoadoutApp
