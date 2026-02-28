--!strict
-- Resolves item icons from Loot prefabs for display in inventory slots

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("ItemDefinitions"))

local ItemIconResolver = {}

function ItemIconResolver.getIconForItem(itemId: string): (string?, string?)
	-- Returns (imageId, displayName)
	local itemData = ItemDefinitions.GetItem(itemId)
	local displayName = (itemData and itemData.displayName) or itemId

	if not itemData then
		return nil, displayName
	end

	local lootFolder = ReplicatedStorage:FindFirstChild("Loot")
	if not lootFolder then return nil, displayName end

	local categoryFolder = lootFolder:FindFirstChild(itemData.category)
	if not categoryFolder then return nil, displayName end

	for _, descendant in ipairs(categoryFolder:GetDescendants()) do
		if descendant.Name == itemId then
			local iconImage = descendant:FindFirstChild("IconImage")
			if iconImage then
				local imageId: string? = nil
				if iconImage:IsA("StringValue") then
					imageId = iconImage.Value
				elseif iconImage:IsA("IntValue") or iconImage:IsA("NumberValue") then
					imageId = "rbxassetid://" .. tostring(iconImage.Value)
				elseif iconImage:IsA("ImageLabel") then
					imageId = iconImage.Image
				elseif iconImage:IsA("Decal") then
					imageId = iconImage.Texture
				end

				if imageId and imageId ~= "" then
					if string.match(imageId, "^%d+$") then
						imageId = "rbxassetid://" .. imageId
					end
					return imageId, displayName
				end
			end
			break
		end
	end

	return nil, displayName
end

return ItemIconResolver
