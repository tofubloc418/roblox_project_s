--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Translate = require(script.Parent.Translate)
local Types = require(script.Parent.Parent.Types)
type Mover = Types.MoverInternal
type LungeParams = Types.LungeParams

local DEFAULT_DISTANCE = 6
local DEFAULT_DURATION = 0.18

local function run(mover: Mover, params: LungeParams): ActiveMovement.ActiveMovement
	return Translate.run(mover, {
		direction = params.direction,
		distance = params.distance or DEFAULT_DISTANCE,
		duration = params.duration or DEFAULT_DURATION,
		accelerationMultiplier = params.accelerationMultiplier,
	})
end

return { run = run }
