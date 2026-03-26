--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type OrbitParams = Types.OrbitParams

local function run(mover: Mover, params: OrbitParams): ActiveMovement.ActiveMovement
	local center = params.center
	local radius = math.max(params.radius, 1e-3)
	local w = params.angularSpeed
	local duration = math.max(params.duration, 1e-3)
	local axisU = (params.axis or Vector3.yAxis).Unit
	local aux = if math.abs(axisU:Dot(Vector3.xAxis)) < 0.9 then Vector3.xAxis else Vector3.zAxis
	local u = axisU:Cross(aux).Unit
	local v = axisU:Cross(u).Unit

	local angle = params.startAngle or 0
	local elapsed = 0
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local token: ActiveMovement.ActiveMovement
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseLinearVelocity(token)
	end)

	local function step(dt: number)
		elapsed += dt
		angle += w * dt
		local vel = w * radius * (-math.sin(angle) * u + math.cos(angle) * v)
		mover:acquireLinearVelocity(token, vel, mf)
		if elapsed >= duration and token:IsActive() then
			ActiveMovement.finish(token)
		end
	end

	mover:trackActive(token)
	mover:registerFrameUpdate(token, step)
	step(0)

	return token
end

return { run = run }
