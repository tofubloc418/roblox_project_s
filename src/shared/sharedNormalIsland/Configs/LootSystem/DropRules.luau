--[[
	DropRules
	Bundle templates and physical drop behavior
]]

local DropRules = {}

-- Bundle templates (functional). Each returns an array of {itemId, stackCount}
DropRules.Bundles = {
	SingleMed = {
		{ itemId = "Bandage", stackCount = 5 },
		{ itemId = "Medkit", stackCount = 1 },
		{ itemId = "Pill", stackCount = 1 },
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

	return { { itemId = picked.itemId, stackCount = picked.stackCount or 1 } }
end

-- Calculate scatter position for a drop
function DropRules.GetScatterPosition(basePosition: Vector3, rule: any, index: number, rng: Random)
	local scatterRadius = (rule and rule.scatterRadius) or 0
	if scatterRadius <= 0 then
		return basePosition
	end

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
