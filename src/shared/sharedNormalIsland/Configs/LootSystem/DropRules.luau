--[[
	DropRules
	Named rules for bundle sizes, category constraints, and physical drop behavior
]]

local ItemDefinitions = require(script.Parent.ItemDefinitions)

local DropRules = {}

-- Bundle rule definitions
DropRules.BundleRules = {
	["Single"] = {
		countRange = {1, 1},
		stackScale = 1.0,
		scatterRadius = 0,
		impulse = {min = 5, max = 10},
	},
	
	["Small"] = {
		countRange = {1, 3},
		stackScale = 0.8,
		scatterRadius = 2,
		impulse = {min = 8, max = 15},
	},
	
	["Medium"] = {
		countRange = {2, 5},
		stackScale = 1.0,
		scatterRadius = 3,
		impulse = {min = 10, max = 20},
	},
	
	["Large"] = {
		countRange = {3, 7},
		stackScale = 1.2,
		scatterRadius = 4,
		impulse = {min = 12, max = 25},
	},
	
	["SingleWithAmmo"] = {
		countRange = {2, 2}, -- Gun + ammo
		categoryConstraints = {
			-- If first item is a gun, second must be matching ammo
			{
				ifCategory = ItemDefinitions.Categories.GUN,
				thenCategory = ItemDefinitions.Categories.AMMO,
				matchAmmoType = true,
				ammoStackRange = {20, 40},
			}
		},
		stackScale = 1.0,
		scatterRadius = 1.5,
		impulse = {min = 8, max = 12},
	},
	
	["GunLoadout"] = {
		countRange = {3, 4}, -- Gun + ammo + possible attachment
		categoryConstraints = {
			{
				ifCategory = ItemDefinitions.Categories.GUN,
				thenCategory = ItemDefinitions.Categories.AMMO,
				matchAmmoType = true,
				ammoStackRange = {30, 60},
			}
		},
		optionalCategories = {ItemDefinitions.Categories.ATTACHMENT},
		stackScale = 1.0,
		scatterRadius = 2.5,
		impulse = {min = 10, max = 18},
	},
	
	["MedicalSupply"] = {
		countRange = {2, 4},
		forceCategory = ItemDefinitions.Categories.MED,
		stackScale = 0.8,
		scatterRadius = 2,
		impulse = {min = 6, max = 12},
	},
	
	["GrenadeBundle"] = {
		countRange = {2, 3},
		forceCategory = ItemDefinitions.Categories.GRENADE,
		stackScale = 1.0,
		scatterRadius = 1.5,
		impulse = {min = 8, max = 14},
	},
}

-- Get a bundle rule by ID
function DropRules.GetRule(ruleId: string)
	return DropRules.BundleRules[ruleId] or DropRules.BundleRules["Small"]
end

-- Apply bundle rules to generate drop items
function DropRules.ApplyRule(ruleId: string, primaryItem: string, rng: Random)
	local rule = DropRules.GetRule(ruleId)
	local drops = {}
	
	-- Get primary item info
	local primaryItemData = ItemDefinitions.GetItem(primaryItem)
	if not primaryItemData then
		warn("Invalid primary item:", primaryItem)
		return drops
	end
	
	-- Determine bundle count
	local minCount, maxCount = rule.countRange[1], rule.countRange[2]
	local bundleCount = rng:NextInteger(minCount, maxCount)
	
	-- Add primary item with appropriate stack size
	local primaryStack = 1
	if primaryItemData.stackMax then
		local stackMin = math.ceil(primaryItemData.stackMax * 0.3 * rule.stackScale)
		local stackMax = math.ceil(primaryItemData.stackMax * rule.stackScale)
		primaryStack = rng:NextInteger(stackMin, stackMax)
	end
	
	table.insert(drops, {
		itemId = primaryItem,
		stackCount = primaryStack,
	})
	
	-- Handle category constraints (e.g., gun needs ammo)
	if rule.categoryConstraints then
		for _, constraint in ipairs(rule.categoryConstraints) do
			if primaryItemData.category == constraint.ifCategory then
				-- Need to add constrained category item
				if constraint.matchAmmoType and primaryItemData.ammoType then
					-- Find matching ammo
					local ammoId = ItemDefinitions.GetAmmoForGun(primaryItem)
					if ammoId and bundleCount > #drops then
						local ammoStack = rng:NextInteger(
							constraint.ammoStackRange[1],
							constraint.ammoStackRange[2]
						)
						table.insert(drops, {
							itemId = ammoId,
							stackCount = ammoStack,
						})
					end
				elseif constraint.thenCategory and bundleCount > #drops then
					-- Add random item from required category
					-- This would need LootPools integration for proper random selection
					-- For now, just log what would happen
					warn("Would add item from category:", constraint.thenCategory)
				end
			end
		end
	end
	
	-- Fill remaining slots with optional categories if specified
	if rule.optionalCategories and bundleCount > #drops then
		-- Would need proper random selection from optional categories
		warn("Would add optional items from categories:", rule.optionalCategories)
	end
	
	-- If forced category, ensure all items are from that category
	if rule.forceCategory then
		-- Override drops to be only from forced category
		-- This would need proper implementation with LootPools
		warn("Would force all items to be from category:", rule.forceCategory)
	end
	
	return drops
end

-- Calculate scatter position for a drop
function DropRules.GetScatterPosition(basePosition: Vector3, rule: any, index: number, rng: Random)
	local scatterRadius = rule.scatterRadius or 0
	if scatterRadius <= 0 then
		return basePosition
	end
	
	-- Random angle and distance
	local angle = rng:NextNumber() * math.pi * 2
	local distance = rng:NextNumber() * scatterRadius
	
	local offset = Vector3.new(
		math.cos(angle) * distance,
		0,
		math.sin(angle) * distance
	)
	
	return basePosition + offset
end

-- Calculate impulse for a drop
function DropRules.GetImpulse(rule: any, rng: Random)
	local impulseMin = rule.impulse and rule.impulse.min or 5
	local impulseMax = rule.impulse and rule.impulse.max or 15
	
	local force = rng:NextNumber() * (impulseMax - impulseMin) + impulseMin
	local angle = rng:NextNumber() * math.pi * 2
	
	return Vector3.new(
		math.cos(angle) * force * 0.5,
		force,
		math.sin(angle) * force * 0.5
	)
end

return DropRules
