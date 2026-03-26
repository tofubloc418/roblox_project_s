--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type PullParams = Types.PullParams

local function run(mover: Mover, params: PullParams): ActiveMovement.ActiveMovement
	local root = mover:getRoot()
	local target = params.target
	local speed = params.speed
	local maxDur = math.max(params.maxDuration, 1e-3)
	local arrival = params.arrivalRadius or 1
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local elapsed = 0
	local token: ActiveMovement.ActiveMovement

	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseLinearVelocity(token)
	end)

	local function step(dt: number)
		elapsed += dt
		local toT = target - root.Position
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
