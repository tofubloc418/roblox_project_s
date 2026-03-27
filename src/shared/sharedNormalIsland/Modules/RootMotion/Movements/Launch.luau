--!strict

local Workspace = game:GetService("Workspace")

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local Util = req(root.Util)

local function run(mover: any, params: any): any
	local g = Workspace.Gravity
	if g < 1e-5 then
		g = 196.2
	end

	local h = math.max(params.height, 0)
	local vy = math.sqrt(2 * g * h)
	local riseTime = vy / g
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local token: any
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
