--!strict

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local Easing = req(root.Easing)
local Util = req(root.Util)

local SPEED_SHARPNESS = 2

local function run(mover: any, params: any): any
	local rootPart = mover:getRoot()
	local flat = rootPart.Position - params.origin
	flat = Vector3.new(flat.X, 0, flat.Z)
	if flat.Magnitude < 1e-5 then
		local look = rootPart.CFrame.LookVector
		flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 1e-5 then
			flat = Vector3.new(0, 0, -1)
		end
	end
	local dirH = flat.Unit

	local arcDeg = params.arcAngleDegrees or 35
	local ang = math.rad(arcDeg)
	local horiz = math.cos(ang)
	local vertical = math.sin(ang)
	local knockDir = (dirH * horiz + Vector3.yAxis * vertical).Unit

	local duration = math.max(params.duration, 1e-3)
	local base = params.distance / duration
	local mf = Util.maxForceFor(mover, params.accelerationMultiplier)
	local useDecay = params.decay == true
	local ease = Easing.byId(params.easing)

	local elapsed = 0
	local token: any

	token = ActiveMovement.new(function()
		mover:untrackActive(token)
		mover:unregisterFrameUpdate(token)
		mover:releaseLinearVelocity(token)
	end)

	local function step(_dt: number)
		elapsed += _dt
		local speed: number
		if useDecay then
			local u = math.clamp(elapsed / duration, 0, 1)
			local factor = 1 - ease(u)
			speed = base * SPEED_SHARPNESS * factor
		else
			speed = base
		end
		mover:acquireLinearVelocity(token, knockDir * speed, mf)
		if elapsed >= duration and token:IsActive() then
			ActiveMovement.finish(token)
		end
	end

	mover:trackActive(token)
	if useDecay then
		mover:registerFrameUpdate(token, step)
		step(0)
	else
		mover:acquireLinearVelocity(token, knockDir * base, mf)
		task.delay(duration, function()
			if token:IsActive() then
				ActiveMovement.finish(token)
			end
		end)
	end

	return token
end

return { run = run }
