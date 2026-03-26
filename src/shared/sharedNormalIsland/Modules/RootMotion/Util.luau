--!strict

local req = require :: any
local s = script.Parent :: any
local MoverModule = req(s.Mover)

local function maxForceFor(mover: any, accelerationMultiplier: number?): number
	local mult = accelerationMultiplier or MoverModule.DEFAULT_ACCEL_MULT
	return mover:getCachedMass() * mult
end

return {
	maxForceFor = maxForceFor,
}
