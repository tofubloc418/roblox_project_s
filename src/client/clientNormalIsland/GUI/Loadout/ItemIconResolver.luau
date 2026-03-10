--!strict
--[[
	TEMPORARY PLACEHOLDER: ItemIconResolver
	======================================
	The old item system was deprecated. This stub returns nil for all icons
	so the Loadout and HUD Loadout UI can run without errors. When the new
	item system is implemented, replace this with a resolver that reads
	iconId from ItemRegistry.GetTemplate(templateId).
]]
local ItemIconResolver = {}

function ItemIconResolver.getIconForItem(itemId: string): (string?, string?)
	-- Returns (imageId, displayName). Placeholder: no icons, use itemId as display name.
	return nil, itemId
end

return ItemIconResolver
