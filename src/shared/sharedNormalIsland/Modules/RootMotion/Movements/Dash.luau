--!strict

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local Easing = req(root.Easing)
local Util = req(root.Util)

local SPEED_SHARPNESS = 2

local function run(mover: any, params: any): any
	local dir = params.direction
	if dir.Magnitude < 1e-5 then
		error("[RootMotion.dash] direction must be non-zero")
	end
	dir = dir.Unit

	local duration = math.max(params.duration, 1e-3)
	local base = params.distance / duration
	local ease = Easing.byId(params.easing)
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)
	local extraVelocityFn = if type(params.additionalVelocity) == "function" then params.additionalVelocity else nil

	local elapsed = 0
	local token: any
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
		local extraVelocity = Vector3.zero
		if extraVelocityFn then
			local extra = extraVelocityFn()
			if typeof(extra) == "Vector3" then
				extraVelocity = Vector3.new(extra.X, 0, extra.Z)
			end
		end
		mover:acquireLinearVelocity(token, dir * speed + extraVelocity, mf, true)
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
