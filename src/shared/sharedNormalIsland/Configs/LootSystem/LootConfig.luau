--[[
	LootConfig
	Central configuration file for all loot crate types, rarity weights, and rules
	This is the main file you'll tweak to adjust loot balance
]]

local ItemDefinitions = require(script.Parent.ItemDefinitions)

local LootConfig = {}

-- Debug mode flag
LootConfig.DEBUG_MODE = true

-- Rarity tier definitions with display properties
LootConfig.Tiers = {
	{
		name = "Common",
		displayColor = "#808080", -- Gray
		order = 1,
	},
	{
		name = "Uncommon",
		displayColor = "#00FF00", -- Green
		order = 2,
	},
	{
		name = "Rare",
		displayColor = "#0080FF", -- Blue
		order = 3,
	},
	{
		name = "Epic",
		displayColor = "#B000FF", -- Purple
		order = 4,
	},
	{
		name = "Legendary",
		displayColor = "#FFB000", -- Orange
		order = 5,
	},
}

-- Crate type definitions
LootConfig.CrateTypes = {
	["TestCrate"] = {
		AllowedPools = {
			ItemDefinitions.Categories.GUN,
		},
		RarityWeights = {
			[ItemDefinitions.Rarities.COMMON] = 100,
		},
		CategoryWeights = {
			[ItemDefinitions.Categories.GUN] = 100,
		},
		BundleCount = 1,
		MaxHealth = 100,
	},
	-- Standard loot crate
	["Normal"] = {
		AllowedPools = {
			ItemDefinitions.Categories.GUN,
			ItemDefinitions.Categories.GRENADE,
			ItemDefinitions.Categories.AMMO,
			ItemDefinitions.Categories.MED,
			ItemDefinitions.Categories.ARMOR,
		},
		RarityWeights = {
			[ItemDefinitions.Rarities.COMMON] = 55,
			[ItemDefinitions.Rarities.UNCOMMON] = 30,
			[ItemDefinitions.Rarities.RARE] = 12,
			[ItemDefinitions.Rarities.EPIC] = 3,
			[ItemDefinitions.Rarities.LEGENDARY] = 0,
		},
		CategoryWeights = {
			[ItemDefinitions.Categories.GUN] = 20,
			[ItemDefinitions.Categories.GRENADE] = 15,
			[ItemDefinitions.Categories.AMMO] = 25,
			[ItemDefinitions.Categories.MED] = 20,
			[ItemDefinitions.Categories.ARMOR] = 15,
			[ItemDefinitions.Categories.ATTACHMENT] = 5,
		},
		BundleCount = 1,
		MaxHealth = 100,
	},
	
	-- Better loot crate
	["NormalPlus"] = {
		AllowedPools = {
			ItemDefinitions.Categories.GUN,
			ItemDefinitions.Categories.GRENADE,
			ItemDefinitions.Categories.AMMO,
			ItemDefinitions.Categories.MED,
			ItemDefinitions.Categories.ARMOR,
			ItemDefinitions.Categories.ATTACHMENT,
		},
		RarityWeights = {
			[ItemDefinitions.Rarities.COMMON] = 30,
			[ItemDefinitions.Rarities.UNCOMMON] = 35,
			[ItemDefinitions.Rarities.RARE] = 25,
			[ItemDefinitions.Rarities.EPIC] = 8,
			[ItemDefinitions.Rarities.LEGENDARY] = 2,
		},
		CategoryWeights = {
			[ItemDefinitions.Categories.GUN] = 25,
			[ItemDefinitions.Categories.GRENADE] = 10,
			[ItemDefinitions.Categories.AMMO] = 20,
			[ItemDefinitions.Categories.MED] = 20,
			[ItemDefinitions.Categories.ARMOR] = 15,
			[ItemDefinitions.Categories.ATTACHMENT] = 10,
		},
		BundleCount = 2,
		MaxHealth = 150,
	},
	
	-- Weapon crate
	["WeaponCrate"] = {
		AllowedPools = {
			ItemDefinitions.Categories.GUN,
			ItemDefinitions.Categories.AMMO,
			ItemDefinitions.Categories.ATTACHMENT,
		},
		RarityWeights = {
			[ItemDefinitions.Rarities.COMMON] = 40,
			[ItemDefinitions.Rarities.UNCOMMON] = 35,
			[ItemDefinitions.Rarities.RARE] = 20,
			[ItemDefinitions.Rarities.EPIC] = 5,
			[ItemDefinitions.Rarities.LEGENDARY] = 0,
		},
		CategoryWeights = {
			[ItemDefinitions.Categories.GUN] = 40,
			[ItemDefinitions.Categories.AMMO] = 40,
			[ItemDefinitions.Categories.ATTACHMENT] = 20,
		},
		BundleCount = 1,
		GuaranteeAtLeast = {
			category = ItemDefinitions.Categories.GUN,
			count = 1,
		},
		MaxHealth = 120,
	},
	
	-- Grenade box
	["GrenadeBox"] = {
		AllowedPools = {ItemDefinitions.Categories.GRENADE},
		RarityWeights = {
			[ItemDefinitions.Rarities.COMMON] = 80,
			[ItemDefinitions.Rarities.UNCOMMON] = 15,
			[ItemDefinitions.Rarities.RARE] = 5,
			[ItemDefinitions.Rarities.EPIC] = 0,
			[ItemDefinitions.Rarities.LEGENDARY] = 0,
		},
		BundleCount = 1,
		MaxHealth = 80,
	},
	
	-- Medical supply crate
	["Medical"] = {
		AllowedPools = {ItemDefinitions.Categories.MED},
		RarityWeights = {
			[ItemDefinitions.Rarities.COMMON] = 100,
			-- [ItemDefinitions.Rarities.UNCOMMON] = 30,
			-- [ItemDefinitions.Rarities.RARE] = 15,
			-- [ItemDefinitions.Rarities.EPIC] = 5,
			-- [ItemDefinitions.Rarities.LEGENDARY] = 0,
		},
		BundleCount = 1,
		MaxHealth = 80,
	},
	
	-- Specific weapon crate (example: Mosin only)
	["MosinOnly"] = {
		Whitelist = {"mosin"},
		BundleCount = 1,
		MaxHealth = 100,
	},
	
	-- High tier loot crate
	["Elite"] = {
		AllowedPools = {
			ItemDefinitions.Categories.GUN,
			ItemDefinitions.Categories.ARMOR,
			ItemDefinitions.Categories.ATTACHMENT,
			ItemDefinitions.Categories.MED,
		},
		RarityWeights = {
			[ItemDefinitions.Rarities.COMMON] = 0,
			[ItemDefinitions.Rarities.UNCOMMON] = 20,
			[ItemDefinitions.Rarities.RARE] = 40,
			[ItemDefinitions.Rarities.EPIC] = 30,
			[ItemDefinitions.Rarities.LEGENDARY] = 10,
		},
		BundleCount = 2,
		GuaranteeAtLeast = {
			rarity = ItemDefinitions.Rarities.RARE,
			count = 1,
		},
		MaxHealth = 200,
	},
}

-- Helper function to get crate configuration
function LootConfig.GetCrateConfig(crateType: string)
	return LootConfig.CrateTypes[crateType] or LootConfig.CrateTypes["Normal"]
end

-- Helper function to get visual state configuration
function LootConfig.GetVisualState(crateType: string)
	return nil
end

-- Validate configuration on load
local function validateConfig()
	for crateType, config in pairs(LootConfig.CrateTypes) do
		-- Validate rarity weights sum to > 0
		if config.RarityWeights then
			local sum = 0
			for _, weight in pairs(config.RarityWeights) do
				sum = sum + weight
			end
			if sum <= 0 then
				warn("Invalid rarity weights for crate type:", crateType)
			end
		end
		
		-- Validate category weights if present
		if config.CategoryWeights then
			local sum = 0
			for _, weight in pairs(config.CategoryWeights) do
				sum = sum + weight
			end
			if sum <= 0 then
				warn("Invalid category weights for crate type:", crateType)
			end
		end
	end
end

validateConfig()

return LootConfig
