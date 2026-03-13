--!strict
-- ItemIconResolver
-- Resolves an itemId to a UI-ready icon imageId and display name using ItemRegistry.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))

local ItemIconResolver = {}

-- Returns (imageId, displayName) for a given itemId.
-- imageId may be nil if the template has no usable icon, in which case callers
-- should fall back to showing the displayName as text.
function ItemIconResolver.getIconForItem(itemId: string): (string?, string?)
	-- Look up the item template from the shared ItemRegistry.
	local template = ItemRegistry.GetTemplate(itemId)
	if not template then
		-- Unknown itemId; show the raw id as a last-resort label.
		return nil, itemId
	end

	local displayName = template.displayName or template.templateId or itemId
	local iconId = template.iconId

	-- Treat missing / placeholder ids as "no icon".
	if iconId == nil or iconId == "" or iconId == "rbxassetid://0" then
		return nil, displayName
	end

	return iconId, displayName
end

return ItemIconResolver

