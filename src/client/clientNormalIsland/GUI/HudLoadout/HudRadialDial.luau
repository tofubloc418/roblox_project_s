--!strict
-- Maps quick-use items into RadialDial props; selection is driven by HudLoadoutController.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes    = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
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
