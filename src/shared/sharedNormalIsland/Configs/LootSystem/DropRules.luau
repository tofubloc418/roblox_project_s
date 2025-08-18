--[[
	DropRules
	Bundle templates and physical drop behavior
]]

local ItemDefinitions = require(script.Parent.ItemDefinitions)

local DropRules = {}

-- Bundle templates (functional). Each returns an array of {itemId, stackCount}
DropRules.Bundles = {
	GunWithAmmo = function(primaryGunId: string?, rng: Random)
		local drops = {}
		if primaryGunId then
			table.insert(drops, {itemId = primaryGunId, stackCount = 1})
			local ammoId = ItemDefinitions.GetAmmoForGun(primaryGunId)
			if ammoId then
				local ammoDef = ItemDefinitions.GetItem(ammoId)
				local count = 30
				if ammoDef and ammoDef.stackMax then
					count = math.max(10, math.min(ammoDef.stackMax, math.floor(ammoDef.stackMax * 0.5)))
				end
				table.insert(drops, {itemId = ammoId, stackCount = count})
			end
		end
		return drops
	end,

	SingleMed = function(_: string?, rng: Random)
		return {{itemId = "bandage", stackCount = 1}}
	end,

	SingleAttachment = function(_: string?, rng: Random)
		return {{itemId = "scope_2x", stackCount = 1}}
	end,

	SingleArmor = function(_: string?, rng: Random)
		return {{itemId = "vest_level1", stackCount = 1}}
	end,

	SingleGrenade = function(_: string?, rng: Random)
		return {{itemId = "frag_grenade", stackCount = 1}}
	end,
}

function DropRules.GetBundle(name: string)
	return DropRules.Bundles[name]
end

-- Generate drops for a bundle name
function DropRules.ApplyBundle(name: string, primaryItem: string?, rng: Random)
	local handler = DropRules.GetBundle(name)
	if not handler then return {} end
	return handler(primaryItem, rng)
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
