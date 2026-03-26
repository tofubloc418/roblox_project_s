--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, pullTo: Vector3, speed: number, maxDuration: number, arrivalRadius: number?, target: Player?)
	local player = target or context.Executor
	local ok, detail = RootMotionCmdrUtil.runMovement(player, RootMotionCmdrUtil.getDefaultTimeout(), function(m)
		return m:pull({
			target = pullTo,
			speed = speed,
			maxDuration = maxDuration,
			arrivalRadius = arrivalRadius,
		})
	end)
	if not ok then
		return detail
	end
	return "rm_pull: ok"
end
