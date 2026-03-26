--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local PhysicsHelpers = require(script.Parent.Parent.PhysicsHelpers)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type SlamParams = Types.SlamParams

local function run(mover: Mover, params: SlamParams): ActiveMovement.ActiveMovement
	local root = mover:getRoot()
	local speed = params.speed
	local maxDur = params.maxDuration or 4
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
		local grounded = PhysicsHelpers.isGrounded(root, 3.5, nil)
		if grounded and root.AssemblyLinearVelocity.Y <= 1.5 then
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
