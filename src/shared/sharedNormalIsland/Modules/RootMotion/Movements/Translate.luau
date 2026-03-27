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

	local token: any
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:releaseLinearVelocity(token)
	end)

	mover:trackActive(token)
	mover:acquireLinearVelocity(token, dir * speed, mf, true)

	task.delay(duration, function()
		if not token:IsActive() then
			return
		end
		ActiveMovement.finish(token)
	end)

	return token
end

return { run = run }
