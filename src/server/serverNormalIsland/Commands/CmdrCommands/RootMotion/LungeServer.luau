--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, direction: Vector3, distance: number?, duration: number?, target: Player?)
	local player = target or context.Executor
	local ok, detail = RootMotionCmdrUtil.runMovement(player, RootMotionCmdrUtil.getDefaultTimeout(), function(m)
		local params: { direction: Vector3, distance: number?, duration: number? } = {
			direction = direction,
		}
		if distance ~= nil then
			params.distance = distance
		end
		if duration ~= nil then
			params.duration = duration
		end
		return m:lunge(params)
	end)
	if not ok then
		return detail
	end
	return "rm_lunge: ok"
end
