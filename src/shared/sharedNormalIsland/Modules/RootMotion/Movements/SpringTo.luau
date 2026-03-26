--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type SpringToParams = Types.SpringToParams

local function run(mover: Mover, params: SpringToParams): ActiveMovement.ActiveMovement
	local target = params.target
	local responsiveness = params.frequency or 10
	local maxVel = params.maxVelocity or params.damping or 40
	local maxForce = params.maxForce or Util.maxForceFor(mover, params.accelerationMultiplier)
	local applyCom = if params.applyAtCenterOfMass == nil then true else params.applyAtCenterOfMass
	local maxDur = params.maxDuration or 4

	local token: ActiveMovement.ActiveMovement
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:releaseAlignPosition(token)
	end)

	mover:trackActive(token)
	mover:acquireAlignPosition(token, target, maxForce, maxVel, responsiveness, applyCom)

	task.delay(maxDur, function()
		if not token:IsActive() then
			return
		end
		ActiveMovement.finish(token)
	end)

	return token
end

return { run = run }
