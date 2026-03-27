--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, direction: Vector3, distance: number, duration: number, target: Player?)
	local player = target or context.Executor
	local ok, detail = RootMotionCmdrUtil.runMovement(player, RootMotionCmdrUtil.getDefaultTimeout(), function(m)
		return m:translate({
			direction = direction,
			distance = distance,
			duration = duration,
		})
	end)
	if not ok then
		return detail
	end
	return "rm_translate: ok"
end
