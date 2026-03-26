--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
type Mover = Types.MoverInternal
type TranslateParams = Types.TranslateParams

local function run(mover: Mover, params: TranslateParams): ActiveMovement.ActiveMovement
	local dir = params.direction
	if dir.Magnitude < 1e-5 then
		error("[RootMotion.translate] direction must be non-zero")
	end
	dir = dir.Unit

	local duration = math.max(params.duration, 1e-3)
	local speed = params.distance / duration
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)

	local token: ActiveMovement.ActiveMovement
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:releaseLinearVelocity(token)
	end)

	mover:trackActive(token)
	mover:acquireLinearVelocity(token, dir * speed, mf)

	task.delay(duration, function()
		if not token:IsActive() then
			return
		end
		ActiveMovement.finish(token)
	end)

	return token
end

return { run = run }
