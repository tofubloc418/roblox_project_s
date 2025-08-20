--[[
	DropRules
	Bundle templates and physical drop behavior
]]

local ItemDefinitions = require(script.Parent.ItemDefinitions)
local GunConfigs = require(script.Parent.Parent:WaitForChild("Weapons"):WaitForChild("GunConfigs"))

local DropRules = {}

-- Bundle templates (functional). Each returns an array of {itemId, stackCount}
DropRules.Bundles = {
	-- List of guns and their ammo stack behavior. Each row:
	-- { itemId = <gun>, stackCount = <gun stacks, usually 1>, stackAmmo = <number of full ammo stacks to drop> }
	GunWithAmmo = {
		{ itemId = "M9", stackCount = 1, stackAmmo = 1 },
		{ itemId = "AK47", stackCount = 1, stackAmmo = 1 },
		{ itemId = "MP220", stackCount = 1, stackAmmo = 1 },
	},

	-- Single-item bundles expressed as lists for consistency
	SingleMed = {
		{ itemId = "Bandage", stackCount = 5 },
	},

	SingleAttachment = {
		{ itemId = "scope_2x", stackCount = 1 },
	},

	SingleArmor = {
		{ itemId = "vest_level1", stackCount = 1 },
	},

	SingleGrenade = {
		{ itemId = "frag_grenade", stackCount = 1 },
	},
}

function DropRules.GetBundle(name: string)
	return DropRules.Bundles[name]
end

-- Generate drops for a bundle name
function DropRules.ApplyBundle(name: string, primaryItem: string?, rng: Random)
	local bundle = DropRules.GetBundle(name)
	if not bundle then return {} end

	-- Bundle must be a list (array of rows)
	local picked = nil
	if primaryItem then
		for _, row in ipairs(bundle) do
			if row.itemId == primaryItem then
				picked = row
				break
			end
		end
	end
	if not picked then
		local count = #bundle
		if count == 0 then return {} end
		local index = rng:NextInteger(1, count)
		picked = bundle[index]
	end

	local drops = {}
	-- Always drop the primary item row
	table.insert(drops, { itemId = picked.itemId, stackCount = picked.stackCount or 1 })

	-- For gun bundles, drop ammo stacks per row.stackAmmo using GunConfigs.ammoType
	local stacksOfAmmo = picked.stackAmmo or 0
	if stacksOfAmmo > 0 then
		local gunCfg = GunConfigs[picked.itemId]
		local ammoId = gunCfg and gunCfg.ammoType
		if ammoId then
			local ammoDef = ItemDefinitions.GetItem(ammoId)
			if ammoDef then
				local fullStack = ammoDef.stackMax or 1
				for i = 1, stacksOfAmmo do
					table.insert(drops, { itemId = ammoId, stackCount = fullStack })
				end
			end
		end
	end

	return drops
end

-- Calculate scatter position for a drop
function DropRules.GetScatterPosition(basePosition: Vector3, rule: any, index: number, rng: Random)
	local scatterRadius = (rule and rule.scatterRadius) or 0
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
	local impulseMin = (rule and rule.impulse and rule.impulse.min) or 5
	local impulseMax = (rule and rule.impulse and rule.impulse.max) or 15
	
	local force = rng:NextNumber() * (impulseMax - impulseMin) + impulseMin
	local angle = rng:NextNumber() * math.pi * 2
	
	return Vector3.new(
		math.cos(angle) * force * 0.5,
		force,
		math.sin(angle) * force * 0.5
	)
end

return DropRules
