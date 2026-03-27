--!strict
local RootMotionCmdrUtil = require(script.Parent.Parent.Parent.RootMotionCmdrUtil :: ModuleScript)

return function(context, position: Vector3, validatePath: boolean?, target: Player?)
	local player = target or context.Executor
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return "HumanoidRootPart missing."
	end
	local rx, ry, rz = hrp.CFrame:ToOrientation()
	local tFrame = CFrame.new(position) * CFrame.fromOrientation(rx, ry, rz)
	local doValidate = if validatePath == nil then false else validatePath
	local ok, detail = RootMotionCmdrUtil.runMovement(player, 4, function(m)
		return m:teleport({ target = tFrame, validatePath = doValidate })
	end)
	if not ok then
		return detail
	end
	return "rm_teleport: ok"
end
