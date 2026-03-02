--!strict
--[[
	Central place for cursor, mouse lock, and camera when UI needs cursor:
	- When a UI wants the cursor (Loadout, FullMap): mouse unlocked and visible with default
	  pointer; camera taken over (Scriptable, fixed look) so mouse movement does NOT rotate camera.
	- When radial dial is open: HudLoadoutController locks mouse, hides cursor, same camera behavior.
	- When no UI and not radial: unlock mouse; show cursor in third person, hide in first person.
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local cursorFlag = ReplicatedStorage:FindFirstChild("UICursorEnabled")
if not cursorFlag then
	cursorFlag = Instance.new("BoolValue")
	cursorFlag.Name = "UICursorEnabled"
	cursorFlag.Value = false
	cursorFlag.Parent = ReplicatedStorage
end

local FIRST_PERSON_DISTANCE_THRESHOLD = 2.5

-- Default pointer: empty string uses system arrow (see UserInputService.MouseIcon docs).
local DEFAULT_MOUSE_ICON = ""

local CursorManager = {}

local activeSources: { [string]: boolean } = {}

-- Camera takeover for cursor UIs (fixed look so mouse doesn't rotate camera).
local previousCameraType: Enum.CameraType? = nil
local uiCameraLookVector: Vector3? = nil
local uiCameraOffsetFromRoot: Vector3? = nil
-- Restore shift-lock (or other) icon when closing cursor UI.
local previousMouseIcon: string? = nil

local function isFirstPerson(): boolean
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType == Enum.CameraType.Scriptable then
		return false
	end
	local character = localPlayer.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not root then
		return false
	end
	local dist = (cam.CFrame.Position - root.Position).Magnitude
	return dist <= FIRST_PERSON_DISTANCE_THRESHOLD
end

function CursorManager._apply()
	local hasAny = next(activeSources) ~= nil
	local cam = workspace.CurrentCamera

	if hasAny then
		-- Unlock mouse from center, show default pointer, so player can move cursor freely.
		previousMouseIcon = UserInputService.MouseIcon
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseIcon = DEFAULT_MOUSE_ICON
		cursorFlag.Value = true

		-- Take over camera: fixed look so mouse movement does not rotate camera (same idea as radial, but cursor visible).
		if cam then
			previousCameraType = cam.CameraType
			cam.CameraType = Enum.CameraType.Scriptable
			uiCameraLookVector = cam.CFrame.LookVector
			local character = localPlayer.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
				if root then
					uiCameraOffsetFromRoot = cam.CFrame.Position - root.Position
				else
					uiCameraOffsetFromRoot = Vector3.new(0, 0, 0)
				end
			else
				uiCameraOffsetFromRoot = Vector3.new(0, 0, 0)
			end
		end
	else
		cursorFlag.Value = false
		-- Restore camera so mouse controls it again.
		if cam and previousCameraType ~= nil then
			cam.CameraType = previousCameraType
			previousCameraType = nil
		end
		uiCameraLookVector = nil
		uiCameraOffsetFromRoot = nil
		-- Restore previous icon (e.g. shift-lock crosshair) so it isn't stuck on pointer.
		if previousMouseIcon ~= nil then
			UserInputService.MouseIcon = previousMouseIcon
			previousMouseIcon = nil
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

-- When cursor UI is open: update scriptable camera every frame (follow character, fixed look; mouse does not rotate camera).
RunService.RenderStepped:Connect(function()
	local hasAny = next(activeSources) ~= nil
	if hasAny and uiCameraLookVector and uiCameraOffsetFromRoot then
		local cam = workspace.CurrentCamera
		local character = localPlayer.Character
		if cam and character then
			local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
			if root then
				local camPos = root.Position + uiCameraOffsetFromRoot
				cam.CFrame = CFrame.lookAt(camPos, camPos + uiCameraLookVector)
			end
		end
		return
	end

	-- When no UI wants the cursor, hide it only in first person (radial handles its own lock).
	local cam = workspace.CurrentCamera
	if cam and cam.CameraType == Enum.CameraType.Scriptable then
		return
	end
	UserInputService.MouseIconEnabled = not isFirstPerson()
end)

localPlayer.CharacterAdded:Connect(function()
	CursorManager._apply()
end)

CursorManager._apply()

return CursorManager
