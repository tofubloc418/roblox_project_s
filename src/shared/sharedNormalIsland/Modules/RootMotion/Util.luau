--!strict

local MoverModule = require(script.Parent.Mover)

type MoverLike = { getCachedMass: (MoverLike) -> number }

local function maxForceFor(mover: MoverLike, accelerationMultiplier: number?): number
	local mult = accelerationMultiplier or MoverModule.DEFAULT_ACCEL_MULT
	return mover:getCachedMass() * mult
end

return {
	maxForceFor = maxForceFor,
}
