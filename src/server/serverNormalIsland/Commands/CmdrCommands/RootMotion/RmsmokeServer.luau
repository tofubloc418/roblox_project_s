--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, target: Player?)
	local player = target or context.Executor
	local lines = RootMotionCmdrUtil.runSmokeAll(player)
	for _, line in ipairs(lines) do
		context:Reply(line)
	end
	return ""
end
