--!strict

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

local cursorFlag = ReplicatedStorage:FindFirstChild("UICursorEnabled")
if not cursorFlag then
	cursorFlag = Instance.new("BoolValue")
	cursorFlag.Name = "UICursorEnabled"
	cursorFlag.Value = false
	cursorFlag.Parent = ReplicatedStorage
end

local CursorManager = {}

local activeSources: {[string]: boolean} = {}

local RENDER_STEP_NAME = "ThirdPersonLock"

local function restoreCharacterToDefault()
	local character = localPlayer.Character
	if not character then return end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.AutoRotate = true
	hum.CameraOffset = Vector3.zero
end

function CursorManager._apply()
	local hasAny = next(activeSources) ~= nil

	if hasAny then
		RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
		restoreCharacterToDefault()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if localPlayer then
			localPlayer.CameraMode = Enum.CameraMode.Classic
		end
		cursorFlag.Value = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		if localPlayer then
			localPlayer.CameraMode = Enum.CameraMode.Classic
		end
		cursorFlag.Value = false

		if PlayerConfig.forceShiftLock then
			-- Run immediately after Camera (201) to avoid fighting with Character-priority updates
			local CAMERA_PLUS_ONE = Enum.RenderPriority.Camera.Value + 1
			RunService:BindToRenderStep(RENDER_STEP_NAME, CAMERA_PLUS_ONE, function()
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				UserInputService.MouseIconEnabled = false

				local character = localPlayer.Character
				if not character then return end
				local hum = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart")
				if not hum or not root then return end

				hum.AutoRotate = false
				hum.CameraOffset = PlayerConfig.shiftLockOffset or Vector3.new(5, 0.2, 0)

				local _, y = workspace.CurrentCamera.CFrame.Rotation:ToEulerAnglesYXZ()
				root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, y, 0)
			end)
		end
	end
end

function CursorManager.setEnabledFor(source: string, enabled: boolean)
	if enabled then
		activeSources[source] = true
	else
		activeSources[source] = nil
	end
	CursorManager._apply()
end

-- Re-apply on respawn so shift-lock binds to new character
localPlayer.CharacterAdded:Connect(function()
	CursorManager._apply()
end)

-- Initialize to gameplay state (hidden/locked)
CursorManager._apply()

return CursorManager
