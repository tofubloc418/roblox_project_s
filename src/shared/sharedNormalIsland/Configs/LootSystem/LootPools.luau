--[[
	LootPools
	Groups items by category and rarity with per-item weights
]]

local ItemDefinitions = require(script.Parent.ItemDefinitions)

local LootPools = {}

-- Initialize empty pool structure
local function initializePools()
	local pools = {}
	
	-- Create pools for each category
	for _, category in pairs(ItemDefinitions.Categories) do
		pools[category] = {}
		-- Create rarity tiers within each category
		for _, rarity in pairs(ItemDefinitions.Rarities) do
			pools[category][rarity] = {}
		end
	end
	
	-- Populate pools with items and their weights
	for itemId, item in pairs(ItemDefinitions.Items) do
		local category = item.category
		local rarity = item.rarity
		local weight = item.weight or 1
		
		if pools[category] and pools[category][rarity] then
			table.insert(pools[category][rarity], {
				itemId = itemId,
				weight = weight
			})
		end
	end
	
	return pools
end

-- Initialize the pools
LootPools.Pools = initializePools()

-- Helper function to get all items in a specific pool
function LootPools.GetPool(category: string, rarity: string)
	if LootPools.Pools[category] and LootPools.Pools[category][rarity] then
		return LootPools.Pools[category][rarity]
	end
	return {}
end

-- Helper function to get a weighted random item from a pool
function LootPools.GetWeightedRandomItem(category: string, rarity: string, rng: Random)
	local pool = LootPools.GetPool(category, rarity)
	if #pool == 0 then
		return nil
	end
	
	-- Calculate total weight
	local totalWeight = 0
	for _, entry in ipairs(pool) do
		totalWeight = totalWeight + entry.weight
	end
	
	-- Pick a random weight value
	local randomWeight = rng:NextNumber() * totalWeight
	
	-- Find the item that corresponds to this weight
	local currentWeight = 0
	for _, entry in ipairs(pool) do
		currentWeight = currentWeight + entry.weight
		if randomWeight <= currentWeight then
			return entry.itemId
		end
	end
	
	-- Fallback (shouldn't happen)
	return pool[1].itemId
end

-- Get all categories that have items in a specific rarity
function LootPools.GetCategoriesWithRarity(rarity: string)
	local categories = {}
	for category, rarityPools in pairs(LootPools.Pools) do
		if rarityPools[rarity] and #rarityPools[rarity] > 0 then
			table.insert(categories, category)
		end
	end
	return categories
end

-- Check if an item exists in pools
function LootPools.ItemExists(itemId: string)
	local item = ItemDefinitions.GetItem(itemId)
	if not item then
		return false
	end
	
	local pool = LootPools.GetPool(item.category, item.rarity)
	for _, entry in ipairs(pool) do
		if entry.itemId == itemId then
			return true
		end
	end
	return false
end

return LootPools
