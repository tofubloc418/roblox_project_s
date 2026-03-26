--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local PhysicsHelpers = require(script.Parent.Parent.PhysicsHelpers)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type SlideParams = Types.SlideParams

local function run(mover: Mover, params: SlideParams): ActiveMovement.ActiveMovement
	local root = mover:getRoot()
	local horiz = params.direction
	horiz = Vector3.new(horiz.X, 0, horiz.Z)
	if horiz.Magnitude < 1e-5 then
		error("[RootMotion.slide] horizontal direction must be non-zero")
	end
	horiz = horiz.Unit

	local duration = math.max(params.duration, 1e-3)
	local friction = params.friction or 0.92
	local rayLen = params.groundRayLength or 4
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local speed = params.speed
	local elapsed = 0

	local token: ActiveMovement.ActiveMovement

	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseLinearVelocity(token)
	end)

	local function step(dt: number)
		elapsed += dt
		local n = PhysicsHelpers.getGroundNormal(root, rayLen, nil) or Vector3.yAxis
		local along = (horiz - n * horiz:Dot(n))
		local slideDir: Vector3
		if along.Magnitude < 1e-4 then
			slideDir = horiz
		else
			slideDir = along.Unit
		end

		local decay = math.pow(friction, dt * 60)
		speed *= decay

		mover:acquireLinearVelocity(token, slideDir * speed, mf)

		if (elapsed >= duration or speed < 0.35) and token:IsActive() then
			ActiveMovement.finish(token)
		end
	end

	mover:trackActive(token)
	mover:registerFrameUpdate(token, step)
	step(0)

	return token
end

return { run = run }
