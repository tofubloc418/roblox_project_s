--!strict
--[[
	HudRadialDial
	=============
	Thin adapter between the HUD loadout system and the generic RadialDial
	component. Maps quick-slot ItemStack data into RadialSlotData, then
	delegates all rendering to RadialDial.

	Responsibilities:
	  • Iterate over all 8 quick-use slots (always all 8, even if empty).
	  • Resolve item icon and display name via ItemIconResolver.
	  • For empty slots, use displayName = "Empty Slot" and isEmpty = true.
	  • Pass resolved slots + highlighted index to RadialDial.

	The onSelect callback has been removed — selection is handled exclusively
	by the Q-release logic in HudLoadoutController.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes    = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local ItemIconResolver  = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("ItemIconResolver"))
local RadialDial        = require(script.Parent.Parent:WaitForChild("RadialDial"):WaitForChild("RadialDial"))
local RadialDialTypes   = require(script.Parent.Parent:WaitForChild("RadialDial"):WaitForChild("RadialDialTypes"))

type ItemStack      = InventoryTypes.ItemStack
type RadialSlotData = RadialDialTypes.RadialSlotData

export type HudRadialDialProps = {
	items: { [number]: ItemStack? },
	highlightedIndex: number?,
	visible: boolean,
	viewportSize: Vector2,
}

local function HudRadialDial(props: HudRadialDialProps)
	local slots: { [number]: RadialSlotData } = {}

	for i = 1, 8 do
		local stack = props.items[i]
		if stack then
			local iconId, displayName = ItemIconResolver.getIconForItem(stack.itemId)
			slots[i] = {
				iconId      = iconId,
				displayName = displayName or stack.itemId,
				isEmpty     = false,
			}
		else
			slots[i] = {
				iconId      = nil,
				displayName = "Empty Slot",
				isEmpty     = true,
			}
		end
	end

	return React.createElement(RadialDial, {
		slots            = slots,
		highlightedIndex = props.highlightedIndex,
		visible          = props.visible,
		viewportSize     = props.viewportSize,
	})
end

return HudRadialDial
