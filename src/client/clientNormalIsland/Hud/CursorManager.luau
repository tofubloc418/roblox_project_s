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
		cursorFlag.Value = true
	else
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

localPlayer.CharacterAdded:Connect(function()
	CursorManager._apply()
end)

CursorManager._apply()

return CursorManager
