--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, center: Vector3, radius: number, angularSpeed: number, duration: number, target: Player?)
	local player = target or context.Executor
	local ok, detail = RootMotionCmdrUtil.runMovement(player, RootMotionCmdrUtil.getDefaultTimeout(), function(m)
		return m:orbit({
			center = center,
			radius = radius,
			angularSpeed = angularSpeed,
			duration = duration,
			axis = Vector3.yAxis,
		})
	end)
	if not ok then
		return detail
	end
	return "rm_orbit: ok"
end
