--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, direction: Vector3, distance: number, duration: number, easing: string?, target: Player?)
	local player = target or context.Executor
	local ease = RootMotionCmdrUtil.coerceEasing(easing)
	local ok, detail = RootMotionCmdrUtil.runMovement(player, RootMotionCmdrUtil.getDefaultTimeout(), function(m)
		return m:dash({
			direction = direction,
			distance = distance,
			duration = duration,
			easing = ease,
		})
	end)
	if not ok then
		return detail
	end
	return "rm_dash: ok"
end
