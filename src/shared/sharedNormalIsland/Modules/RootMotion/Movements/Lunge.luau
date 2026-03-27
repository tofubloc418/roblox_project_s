--!strict

local req = require :: any
local movements = script.Parent :: any
local Translate = req(movements.Translate)

local DEFAULT_DISTANCE = 6
local DEFAULT_DURATION = 0.18

local function run(mover: any, params: any): any
	return Translate.run(mover, {
		direction = params.direction,
		distance = params.distance or DEFAULT_DISTANCE,
		duration = params.duration or DEFAULT_DURATION,
		accelerationMultiplier = params.accelerationMultiplier,
	})
end

return { run = run }
