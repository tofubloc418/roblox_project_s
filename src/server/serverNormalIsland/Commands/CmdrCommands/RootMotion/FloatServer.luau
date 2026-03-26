--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, duration: number, targetY: number?, target: Player?)
	local player = target or context.Executor
	local ok, detail = RootMotionCmdrUtil.runMovement(player, RootMotionCmdrUtil.getDefaultTimeout(), function(m)
		local params: { duration: number, targetY: number?, hoverHeightGain: number? } = {
			duration = duration,
		}
		if targetY ~= nil then
			params.targetY = targetY
			params.hoverHeightGain = 12
		end
		return m:float(params)
	end)
	if not ok then
		return detail
	end
	return "rm_float: ok"
end
