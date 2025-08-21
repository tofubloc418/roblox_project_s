-- Shift-lock init without modifying PlayerModule
-- Docs: UserInputService.MouseBehavior (LockCenter) and camera zoom properties

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local player = Players.LocalPlayer
local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

local function enforceZoom()
	local zoom = PlayerConfig.shiftLockZoom
	player.CameraMinZoomDistance = zoom
	player.CameraMaxZoomDistance = zoom
end

local function lockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function apply()
	if not workspace.CurrentCamera then return end

	-- Disable Roblox's native shift‑lock so avatar doesn't face the camera
	task.spawn(function()
		repeat task.wait() until pcall(function()
			StarterGui:SetCore("ShiftLockEnabled", false)
		end)
	end)

	-- Rotate character based on movement, not camera yaw
	UserGameSettings.RotationType = Enum.RotationType.MovementRelative

	lockMouse()
	enforceZoom()

	-- Offset camera around the shoulder so player can see some of the front
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and PlayerConfig.shiftLockOffset then
		humanoid.CameraOffset = PlayerConfig.shiftLockOffset
		humanoid.AutoRotate = true
	end

	-- Continuously align character's facing to camera yaw plus offset for right-back view
	local runService = game:GetService("RunService")
	local _connection
	_connection = runService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam or not character or not character.PrimaryPart then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local camCFrame = cam.CFrame
		local _, y, _ = camCFrame:ToOrientation()
		local offset = math.rad(PlayerConfig.cameraFaceYawOffsetDeg or -25)
		local targetYaw = y + offset
		local pos = root.CFrame.Position
		root.CFrame = CFrame.new(pos) * CFrame.Angles(0, targetYaw, 0)
	end)
end

-- Initial apply and on respawn
apply()
player.CharacterAdded:Connect(apply)

-- Re-enforce if user tries to change zoom or window focus changes
player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(enforceZoom)
player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(enforceZoom)
UserInputService.WindowFocused:Connect(lockMouse)
UserInputService.WindowFocusReleased:Connect(lockMouse)


