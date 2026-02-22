--!strict

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cursorFlag = ReplicatedStorage:FindFirstChild("UICursorEnabled")
if not cursorFlag then
    cursorFlag = Instance.new("BoolValue")
    cursorFlag.Name = "UICursorEnabled"
    cursorFlag.Value = false
    cursorFlag.Parent = ReplicatedStorage
end

local CursorManager = {}

local activeSources: {[string]: boolean} = {}

function CursorManager._apply()
	local hasAny = next(activeSources) ~= nil
	if hasAny then
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
            localPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        end
        cursorFlag.Value = false
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

-- Initialize to gameplay state (hidden/locked)
CursorManager._apply()

return CursorManager


