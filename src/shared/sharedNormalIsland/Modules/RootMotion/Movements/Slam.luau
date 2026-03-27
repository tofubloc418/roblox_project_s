--!strict

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local PhysicsHelpers = req(root.PhysicsHelpers)
local Util = req(root.Util)

local function run(mover: any, params: any): any
	local rootPart = mover:getRoot()
	local speed = params.speed
	local maxDur = params.maxDuration or 4
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
		local grounded = PhysicsHelpers.isGrounded(rootPart, 3.5, nil)
		if grounded and rootPart.AssemblyLinearVelocity.Y <= 1.5 then
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
		mover:acquireLinearVelocity(token, Vector3.new(0, -speed, 0), mf)
	end

	mover:trackActive(token)
	mover:registerFrameUpdate(token, step)
	step(0)

	return token
end

return { run = run }
