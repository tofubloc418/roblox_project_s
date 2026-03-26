--!strict

--[[
	Standalone physics-root motion helpers. Require from ReplicatedStorage.Modules.RootMotion.

	local RootMotion = require(ReplicatedStorage.Modules.RootMotion)
	local mover = RootMotion.createMover(character)
	local token = mover:dash({ direction = look, distance = 12, duration = 0.25 })
	token.Completed:Connect(function(ok) end)
]]

local MoverLib = require(script.Mover)

local Translate = require(script.Movements.Translate)
local Dash = require(script.Movements.Dash)
local Knockback = require(script.Movements.Knockback)
local Pull = require(script.Movements.Pull)
local Launch = require(script.Movements.Launch)
local Slam = require(script.Movements.Slam)
local Float = require(script.Movements.Float)
local Slide = require(script.Movements.Slide)
local Lunge = require(script.Movements.Lunge)
local Teleport = require(script.Movements.Teleport)
local Orbit = require(script.Movements.Orbit)
local SpringTo = require(script.Movements.SpringTo)

local function createMover(character: Model)
	return MoverLib.create(character, {
		translate = function(m, p)
			return Translate.run(m :: any, p)
		end,
		dash = function(m, p)
			return Dash.run(m :: any, p)
		end,
		knockback = function(m, p)
			return Knockback.run(m :: any, p)
		end,
		pull = function(m, p)
			return Pull.run(m :: any, p)
		end,
		launch = function(m, p)
			return Launch.run(m :: any, p)
		end,
		slam = function(m, p)
			return Slam.run(m :: any, p)
		end,
		float = function(m, p)
			return Float.run(m :: any, p)
		end,
		slide = function(m, p)
			return Slide.run(m :: any, p)
		end,
		lunge = function(m, p)
			return Lunge.run(m :: any, p)
		end,
		teleport = function(m, p)
			return Teleport.run(m :: any, p)
		end,
		orbit = function(m, p)
			return Orbit.run(m :: any, p)
		end,
		springTo = function(m, p)
			return SpringTo.run(m :: any, p)
		end,
	})
end

return {
	createMover = createMover,
	DEFAULT_ACCEL_MULT = MoverLib.DEFAULT_ACCEL_MULT,
	Types = require(script.Types),
	Validation = require(script.Validation),
	PhysicsHelpers = require(script.PhysicsHelpers),
	Easing = require(script.Easing),
	ActiveMovement = require(script.ActiveMovement),
	Util = require(script.Util),
}
