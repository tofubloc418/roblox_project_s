--[[
	LootBoxService
	Server-side service for rolling and dropping loot from crates
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared modules
local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("ItemDefinitions"))
local LootPools = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootPools"))
local DropRules = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("DropRules"))
local LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))
local RoundState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))

local LootBoxService = {}
LootBoxService.__index = LootBoxService

function LootBoxService.new()
	local self = setmetatable({}, LootBoxService)
	
	self.DropFactory = nil -- Will be set by init
	self.ActiveCrates = {} -- Track active crates
	
	return self
end

-- Initialize the service
function LootBoxService:Initialize(dropFactory)
	self.DropFactory = dropFactory
	
	if LootConfig.DEBUG_MODE then
		print("LootBoxService initialized")
	end
end

-- Main API: Roll loot and drop it from a crate
function LootBoxService:RollAndDrop(crateModel: Model)
	if not crateModel then
		warn("RollAndDrop called with nil crate model")
		return
	end
	
	-- Get crate attributes
	local crateType = crateModel:GetAttribute("CrateType") or "Normal"
	local crateId = crateModel:GetAttribute("CrateId")
	if not crateId then
		-- Generate a stable, non-plugin ID for manual crates
		local fullName = crateModel:GetFullName()
		crateId = "manual_" .. fullName
		crateModel:SetAttribute("CrateId", crateId)
	end
	
	-- Get crate configuration
	local crateConfig = LootConfig.GetCrateConfig(crateType)
	
	-- Get deterministic RNG for this crate
	local roundState = RoundState.Current()
	local rng = roundState:GetCrateRollRng(crateId)
	
	-- Get drop position (at crate's position)
	local dropPosition = crateModel:GetPivot().Position
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Rolling loot for crate [%s] type: %s at position: %s", 
			crateId, crateType, tostring(dropPosition)))
	end
	
	-- Roll for items
	local rolledItems = {}
	
	-- Handle whitelist-only crates
	if crateConfig.Whitelist then
		for _, itemId in ipairs(crateConfig.Whitelist) do
			if LootPools.ItemExists(itemId) then
				table.insert(rolledItems, itemId)
				break -- Take first valid item
			end
		end
	else
		-- Standard rolling process
		-- Step 1: Choose category
		local category = self:RollCategory(crateConfig, rng)
		if not category then
			warn("Failed to roll category for crate:", crateType)
			return
		end
		
		-- Step 2: Choose rarity
		local rarity = self:RollRarity(crateConfig, rng)
		if not rarity then
			warn("Failed to roll rarity for crate:", crateType)
			return
		end
		
		-- Step 3: Choose item from pool
		local item = self:RollItem(category, rarity, crateConfig, rng)
		if not item then
			warn("Failed to roll item for category:", category, "rarity:", rarity)
			return
		end
		
		table.insert(rolledItems, item)
	end
	
	-- Apply drop rules to get final drop list
	local bundleRuleId = crateConfig.BundleRuleId or "Small"
	local drops = {}
	
	for _, itemId in ipairs(rolledItems) do
		local bundleDrops = DropRules.ApplyRule(bundleRuleId, itemId, rng)
		for _, drop in ipairs(bundleDrops) do
			table.insert(drops, drop)
		end
	end
	
	-- Spawn the drops
	if self.DropFactory then
		for i, drop in ipairs(drops) do
			local rule = DropRules.GetRule(bundleRuleId)
			local scatterPos = DropRules.GetScatterPosition(dropPosition, rule, i, rng)
			local impulse = DropRules.GetImpulse(rule, rng)
			
			self.DropFactory:SpawnDrop(drop.itemId, drop.stackCount, scatterPos, impulse)
		end
	else
		warn("DropFactory not initialized")
	end
	
	if LootConfig.DEBUG_MODE then
		print("Dropped items:", drops)
	end
	
	-- Fire break effects (stub)
	self:PlayBreakEffects(crateModel)
	
	-- Remove the crate
	crateModel:Destroy()
end

-- Roll a category based on weights
function LootBoxService:RollCategory(crateConfig, rng: Random): string?
	local allowedPools = crateConfig.AllowedPools
	if not allowedPools or #allowedPools == 0 then
		return nil
	end
	
	-- Use category weights if available
	if crateConfig.CategoryWeights then
		local totalWeight = 0
		local weightedCategories = {}
		
		for _, category in ipairs(allowedPools) do
			local weight = crateConfig.CategoryWeights[category] or 1
			totalWeight = totalWeight + weight
			table.insert(weightedCategories, {category = category, weight = weight})
		end
		
		local roll = rng:NextNumber() * totalWeight
		local currentWeight = 0
		
		for _, entry in ipairs(weightedCategories) do
			currentWeight = currentWeight + entry.weight
			if roll <= currentWeight then
				return entry.category
			end
		end
	end
	
	-- Fallback to uniform distribution
	local index = rng:NextInteger(1, #allowedPools)
	return allowedPools[index]
end

-- Roll a rarity based on weights
function LootBoxService:RollRarity(crateConfig, rng: Random): string?
	local rarityWeights = crateConfig.RarityWeights
	if not rarityWeights then
		return ItemDefinitions.Rarities.COMMON
	end
	
	local totalWeight = 0
	for _, weight in pairs(rarityWeights) do
		totalWeight = totalWeight + weight
	end
	if totalWeight <= 0 then
		return ItemDefinitions.Rarities.COMMON
	end
	
	local roll = rng:NextNumber() * totalWeight
	local currentWeight = 0
	for rarity, weight in pairs(rarityWeights) do
		currentWeight = currentWeight + weight
		if roll <= currentWeight then
			return rarity
		end
	end
	return ItemDefinitions.Rarities.COMMON
end

-- Roll an item from a specific pool
function LootBoxService:RollItem(category: string, rarity: string, crateConfig, rng: Random): string?
	-- Check whitelist first
	if crateConfig.Whitelist then
		local validItems = {}
		for _, itemId in ipairs(crateConfig.Whitelist) do
			local item = ItemDefinitions.GetItem(itemId)
			if item and item.category == category and item.rarity == rarity then
				table.insert(validItems, itemId)
			end
		end
		
		if #validItems > 0 then
			local index = rng:NextInteger(1, #validItems)
			return validItems[index]
		end
	end
	
	-- Use pool weights
	local itemId = LootPools.GetWeightedRandomItem(category, rarity, rng)
	if not itemId then
		-- Fallback: pick any random item from the database
		itemId = self:GetAnyRandomItem(rng)
		if LootConfig.DEBUG_MODE and itemId then
			print(string.format("[LootSpawn] Fallback selected item '%s'", tostring(itemId)))
		end
	end
	return itemId
end

-- Fallback: random item from entire database (weighted by item.weight if present)
function LootBoxService:GetAnyRandomItem(rng: Random): string?
	local entries = {}
	local totalWeight = 0
	for id, def in pairs(ItemDefinitions.Items) do
		local w = (def and def.weight) or 1
		totalWeight = totalWeight + w
		table.insert(entries, { id = id, weight = w })
	end
	if totalWeight <= 0 or #entries == 0 then
		return nil
	end
	local roll = rng:NextNumber() * totalWeight
	local acc = 0
	for _, e in ipairs(entries) do
		acc = acc + e.weight
		if roll <= acc then
			return e.id
		end
	end
	return entries[1].id
end

-- Play break effects (stub)
function LootBoxService:PlayBreakEffects(crateModel: Model)
	-- TODO: Play break sound effect
	if LootConfig.DEBUG_MODE then
		print("Would play break SFX for crate at:", crateModel:GetPivot().Position)
	end
	
	-- TODO: Play break particle effect
	if LootConfig.DEBUG_MODE then
		print("Would play break VFX for crate")
	end
end

-- Create singleton instance
local instance = LootBoxService.new()

return instance
