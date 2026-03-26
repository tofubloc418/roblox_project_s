--!strict

--[[
	Standalone physics-root motion helpers. Require from ReplicatedStorage.Modules.RootMotion.

	local RootMotion = require(ReplicatedStorage.Modules.RootMotion)
	local mover = RootMotion.createMover(character)
	local token = mover:dash({ direction = look, distance = 12, duration = 0.25 })
	token.Completed:Connect(function(ok) end)
]]

-- `script` is typed as `LuaSourceContainer` (no children). `require(script....)` is not always a
-- supported static path in the analyzer. `:: any` keeps Studio/LSP behavior aligned with runtime.
local req = require :: any
local s = script :: any

local MoverLib = req(s.Mover)

local Translate = req(s.Movements.Translate)
local Dash = req(s.Movements.Dash)
local Knockback = req(s.Movements.Knockback)
local Pull = req(s.Movements.Pull)
local Launch = req(s.Movements.Launch)
local Slam = req(s.Movements.Slam)
local Float = req(s.Movements.Float)
local Slide = req(s.Movements.Slide)
local Lunge = req(s.Movements.Lunge)
local Teleport = req(s.Movements.Teleport)
local Orbit = req(s.Movements.Orbit)
local SpringTo = req(s.Movements.SpringTo)

local function createMover(character: Model)
	return MoverLib.create(character, {
		translate = function(m, p)
			return Translate.run(m, p)
		end,
		dash = function(m, p)
			return Dash.run(m, p)
		end,
		knockback = function(m, p)
			return Knockback.run(m, p)
		end,
		pull = function(m, p)
			return Pull.run(m, p)
		end,
		launch = function(m, p)
			return Launch.run(m, p)
		end,
		slam = function(m, p)
			return Slam.run(m, p)
		end,
		float = function(m, p)
			return Float.run(m, p)
		end,
		slide = function(m, p)
			return Slide.run(m, p)
		end,
		lunge = function(m, p)
			return Lunge.run(m, p)
		end,
		teleport = function(m, p)
			return Teleport.run(m, p)
		end,
		orbit = function(m, p)
			return Orbit.run(m, p)
		end,
		springTo = function(m, p)
			return SpringTo.run(m, p)
		end,
	})
end

return {
	createMover = createMover,
	DEFAULT_ACCEL_MULT = MoverLib.DEFAULT_ACCEL_MULT,
	Types = req(s.Types),
	Validation = req(s.Validation),
	PhysicsHelpers = req(s.PhysicsHelpers),
	Easing = req(s.Easing),
	ActiveMovement = req(s.ActiveMovement),
	Util = req(s.Util),
}
