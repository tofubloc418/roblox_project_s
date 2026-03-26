--!strict

local Workspace = game:GetService("Workspace")

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type LaunchParams = Types.LaunchParams

local function run(mover: Mover, params: LaunchParams): ActiveMovement.ActiveMovement
	local g = Workspace.Gravity
	if g < 1e-5 then
		g = 196.2
	end

	local h = math.max(params.height, 0)
	local vy = math.sqrt(2 * g * h)
	local riseTime = vy / g
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local token: ActiveMovement.ActiveMovement
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:releaseLinearVelocity(token)
	end)

	mover:trackActive(token)
	mover:acquireLinearVelocity(token, Vector3.new(0, vy, 0), mf)

	task.delay(math.max(riseTime * 0.985, 1e-3), function()
		if not token:IsActive() then
			return
		end
		ActiveMovement.finish(token)
	end)

	return token
end

return { run = run }
