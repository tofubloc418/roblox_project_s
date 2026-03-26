--!strict
-- Dev helpers for RootMotion Cmdr commands (ServerScriptService only).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RootMotion = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RootMotion") :: ModuleScript)

export type EasingId = "linear" | "quadOut" | "quadIn" | "cubicOut" | "cubicIn"

local DEFAULT_CMD_TIMEOUT = 8

local function getHumanoidRootPart(character: Model): BasePart?
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	return nil
end

local function resetRig(hrp: BasePart, cf: CFrame)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = cf
end

local function flatLookFromHrp(hrp: BasePart): Vector3
	local look = hrp.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		return Vector3.zAxis
	end
	return flat.Unit
end

local RootMotionCmdrUtil = {}

function RootMotionCmdrUtil.getDefaultTimeout(): number
	return DEFAULT_CMD_TIMEOUT
end

function RootMotionCmdrUtil.flatLookFromHrp(hrp: BasePart): Vector3
	return flatLookFromHrp(hrp)
end

function RootMotionCmdrUtil.ensureMover(player: Player): (any?, string?)
	local character = player.Character
	if not character then
		return nil, "No Character."
	end
	local hrp = getHumanoidRootPart(character)
	if not hrp then
		return nil, "HumanoidRootPart missing."
	end
	local ok, moverOrErr = pcall(function()
		return RootMotion.createMover(character)
	end)
	if not ok then
		return nil, tostring(moverOrErr)
	end
	return moverOrErr, nil
end

function RootMotionCmdrUtil.waitForMovement(mover: any, token: any, timeout: number): (boolean, string)
	local outcome: string? = nil
	token.Completed:Connect(function(didComplete: boolean)
		outcome = if didComplete then "ok" else "cancelled"
	end)
	local deadline = os.clock() + timeout
	while outcome == nil and os.clock() < deadline do
		task.wait()
	end
	if outcome == nil then
		mover:cancelAll()
		task.wait()
		return false, "timeout"
	end
	if outcome == "ok" then
		return true, "ok"
	end
	return false, "cancelled"
end

function RootMotionCmdrUtil.runMovement(player: Player, timeout: number, startFn: (any) -> any): (boolean, string)
	local mover, err = RootMotionCmdrUtil.ensureMover(player)
	if not mover then
		return false, err :: string
	end
	local ok, tokenOrErr = pcall(function()
		return startFn(mover)
	end)
	if not ok then
		mover:destroy()
		return false, tostring(tokenOrErr)
	end
	local success, detail = RootMotionCmdrUtil.waitForMovement(mover, tokenOrErr, timeout)
	mover:destroy()
	if not success then
		return false, detail
	end
	return true, "ok"
end

function RootMotionCmdrUtil.coerceEasing(id: string?): EasingId
	local s = id or "linear"
	if
		s == "linear"
		or s == "quadOut"
		or s == "quadIn"
		or s == "cubicOut"
		or s == "cubicIn"
	then
		return s
	end
	return "linear"
end

function RootMotionCmdrUtil.runSmokeAll(player: Player): { string }
	local lines: { string } = {}
	local character = player.Character
	if not character then
		table.insert(lines, "[rmsmoke] No Character.")
		return lines
	end
	local hrp = getHumanoidRootPart(character)
	if not hrp then
		table.insert(lines, "[rmsmoke] No HumanoidRootPart.")
		return lines
	end

	local baseline = hrp.CFrame
	local look = hrp.CFrame.LookVector
	local pos = hrp.Position
	local flatLook = flatLookFromHrp(hrp)
	local originBehind = pos - look * 5
	local rx, ry, rz = baseline:ToOrientation()

	local function record(name: string, timeout: number, fn: (any) -> any)
		resetRig(hrp, baseline)
		local mover, merr = RootMotionCmdrUtil.ensureMover(player)
		if not mover then
			table.insert(lines, ("[%s] %s"):format(name, merr :: string))
			return
		end
		local token
		local ok, res = pcall(fn, mover)
		if not ok then
			mover:destroy()
			table.insert(lines, ("[%s] ERROR: %s"):format(name, tostring(res)))
			return
		end
		token = res
		local success, detail = RootMotionCmdrUtil.waitForMovement(mover, token, timeout)
		mover:destroy()
		if success then
			table.insert(lines, ("[%s] ok"):format(name))
		else
			table.insert(lines, ("[%s] %s"):format(name, detail))
		end
	end

	record("translate", 4, function(m)
		return m:translate({ direction = look, distance = 2, duration = 0.35 })
	end)
	record("dash", 4, function(m)
		return m:dash({ direction = look, distance = 4, duration = 0.28, easing = "quadOut" })
	end)
	record("knockback", 4, function(m)
		return m:knockback({ origin = originBehind, distance = 3, duration = 0.35 })
	end)
	record("pull", 6, function(m)
		return m:pull({ target = pos + flatLook * 4, speed = 40, maxDuration = 2, arrivalRadius = 1 })
	end)
	record("launch", 5, function(m)
		return m:launch({ height = 8 })
	end)
	record("slam", 5, function(m)
		return m:slam({ speed = 80, maxDuration = 2 })
	end)
	record("float", 3, function(m)
		return m:float({ duration = 0.6 })
	end)
	record("slide", 5, function(m)
		return m:slide({ direction = flatLook, speed = 45, duration = 0.6 })
	end)
	record("lunge", 4, function(m)
		return m:lunge({ direction = look })
	end)
	record("teleport", 2, function(m)
		local tPos = pos + flatLook * 2
		local tFrame = CFrame.new(tPos) * CFrame.fromOrientation(rx, ry, rz)
		return m:teleport({ target = tFrame, validatePath = false })
	end)
	record("orbit", 5, function(m)
		return m:orbit({
			center = pos + Vector3.yAxis * 2,
			radius = 4,
			angularSpeed = 2,
			duration = 1.2,
			axis = Vector3.yAxis,
		})
	end)
	record("springTo", 6, function(m)
		return m:springTo({ target = pos + flatLook * 3, maxDuration = 3 })
	end)

	resetRig(hrp, baseline)
	return lines
end

return RootMotionCmdrUtil
