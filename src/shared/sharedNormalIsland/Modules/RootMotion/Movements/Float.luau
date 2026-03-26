--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local PhysicsHelpers = require(script.Parent.Parent.PhysicsHelpers)
local Types = require(script.Parent.Parent.Types)
type Mover = Types.MoverInternal
type FloatParams = Types.FloatParams

local function run(mover: Mover, params: FloatParams): ActiveMovement.ActiveMovement
	local root = mover:getRoot()
	local mass = mover:getCachedMass()
	local counter = PhysicsHelpers.getCounterGravityForceVector(root)
	local duration = math.max(params.duration, 1e-3)
	local targetY = params.targetY
	local gain = params.hoverHeightGain or 0

	local token: ActiveMovement.ActiveMovement

	local function cleanup()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseVectorForce(token)
	end

	token = ActiveMovement.new(cleanup)

	if targetY ~= nil and gain > 0 then
		local function step(_dt: number)
			local err = targetY - root.Position.Y
			local boost = Vector3.new(0, err * gain * mass, 0)
			mover:acquireVectorForce(token, counter + boost)
		end
		mover:trackActive(token)
		mover:registerFrameUpdate(token, step)
		step(0)
	else
		mover:trackActive(token)
		mover:acquireVectorForce(token, counter)
	end

	task.delay(duration, function()
		if not token:IsActive() then
			return
		end
		ActiveMovement.finish(token)
	end)

	return token
end

return { run = run }
