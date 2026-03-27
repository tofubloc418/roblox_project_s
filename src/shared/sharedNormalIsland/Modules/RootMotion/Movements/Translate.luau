--!strict

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local Util = req(root.Util)

local function run(mover: any, params: any): any
	local dir = params.direction
	if dir.Magnitude < 1e-5 then
		error("[RootMotion.translate] direction must be non-zero")
	end
	dir = dir.Unit

	local duration = math.max(params.duration, 1e-3)
	local speed = params.distance / duration
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)
	local extraVelocityFn = if type(params.additionalVelocity) == "function" then params.additionalVelocity else nil

	local token: any
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseLinearVelocity(token)
	end)

	local function step(_dt: number)
		local extraVelocity = Vector3.zero
		if extraVelocityFn then
			local extra = extraVelocityFn()
			if typeof(extra) == "Vector3" then
				extraVelocity = Vector3.new(extra.X, 0, extra.Z)
			end
		end
		mover:acquireLinearVelocity(token, dir * speed + extraVelocity, mf, true)
	end

	mover:trackActive(token)
	mover:registerFrameUpdate(token, step)
	step(0)

	task.delay(duration, function()
		if not token:IsActive() then
			return
		end
		ActiveMovement.finish(token)
	end)

	return token
end

return { run = run }
