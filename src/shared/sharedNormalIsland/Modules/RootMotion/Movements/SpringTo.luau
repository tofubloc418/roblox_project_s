--!strict

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local Util = req(root.Util)

local function run(mover: any, params: any): any
	local target = params.target
	local responsiveness = params.frequency or 10
	local maxVel = params.maxVelocity or params.damping or 40
	local maxForce = params.maxForce or Util.maxForceFor(mover, params.accelerationMultiplier)
	local applyCom = if params.applyAtCenterOfMass == nil then true else params.applyAtCenterOfMass
	local maxDur = params.maxDuration or 4

	local token: any
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
