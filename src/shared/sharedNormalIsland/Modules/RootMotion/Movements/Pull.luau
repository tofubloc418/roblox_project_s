--!strict

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local Util = req(root.Util)

local function run(mover: any, params: any): any
	local rootPart = mover:getRoot()
	local target = params.target
	local speed = params.speed
	local maxDur = math.max(params.maxDuration, 1e-3)
	local arrival = params.arrivalRadius or 1
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local elapsed = 0
	local token: any

	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseLinearVelocity(token)
	end)

	local function step(dt: number)
		elapsed += dt
		local toT = target - rootPart.Position
		if toT.Magnitude <= arrival then
			if token:IsActive() then
				ActiveMovement.finish(token)
			end
			return
		end
		if elapsed >= maxDur then
			if token:IsActive() then
				ActiveMovement.finish(token)
			end
			return
		end
		mover:acquireLinearVelocity(token, toT.Unit * speed, mf)
	end

	mover:trackActive(token)
	mover:registerFrameUpdate(token, step)
	step(0)

	return token
end

return { run = run }
