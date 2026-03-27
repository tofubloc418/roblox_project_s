--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, speed: number, maxDuration: number?, target: Player?)
	local player = target or context.Executor
	local ok, detail = RootMotionCmdrUtil.runMovement(player, RootMotionCmdrUtil.getDefaultTimeout(), function(m)
		return m:slam({ speed = speed, maxDuration = maxDuration })
	end)
	if not ok then
		return detail
	end
	return "rm_slam: ok"
end
