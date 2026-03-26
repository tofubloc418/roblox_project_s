--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Easing = require(script.Parent.Parent.Easing)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type DashParams = Types.DashParams

local SPEED_SHARPNESS = 2

local function run(mover: Mover, params: DashParams): ActiveMovement.ActiveMovement
	local dir = params.direction
	if dir.Magnitude < 1e-5 then
		error("[RootMotion.dash] direction must be non-zero")
	end
	dir = dir.Unit

	local duration = math.max(params.duration, 1e-3)
	local base = params.distance / duration
	local ease = Easing.byId(params.easing)
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local elapsed = 0
	local token: ActiveMovement.ActiveMovement
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseLinearVelocity(token)
	end)

	local function step(_dt: number)
		elapsed += _dt
		local u = math.clamp(elapsed / duration, 0, 1)
		local factor = 1 - ease(u)
		local speed = base * SPEED_SHARPNESS * factor
		mover:acquireLinearVelocity(token, dir * speed, mf)
		if elapsed >= duration and token:IsActive() then
			ActiveMovement.finish(token)
		end
	end

	mover:trackActive(token)
	mover:registerFrameUpdate(token, step)
	step(0)

	return token
end

return { run = run }
