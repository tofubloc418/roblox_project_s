--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindRegistry = require(keybindsFolder:WaitForChild("KeybindRegistry"))
local KeybindsClient = require(script.Parent.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))

local MOUSE_LOCK_KEYBINDS: { Enum.KeyCode } = {}

local function syncMouseLockKeybinds()
	table.clear(MOUSE_LOCK_KEYBINDS)
	local codes = KeybindsClient.getBinds(KeybindIds.ThirdPersonCameraLock)
	for i, keyCode in ipairs(codes) do
		if i > 2 then
			break
		end
		table.insert(MOUSE_LOCK_KEYBINDS, keyCode)
	end
	if #MOUSE_LOCK_KEYBINDS == 0 then
		for _, keyCode in ipairs(KeybindRegistry.GetDefaultKeyCodes(KeybindIds.ThirdPersonCameraLock)) do
			table.insert(MOUSE_LOCK_KEYBINDS, keyCode)
			if #MOUSE_LOCK_KEYBINDS >= 2 then
				break
			end
		end
	end
	if #MOUSE_LOCK_KEYBINDS == 0 then
		table.insert(MOUSE_LOCK_KEYBINDS, Enum.KeyCode.V)
	end
	while #MOUSE_LOCK_KEYBINDS < 2 do
		table.insert(MOUSE_LOCK_KEYBINDS, MOUSE_LOCK_KEYBINDS[1])
	end
end

syncMouseLockKeybinds()

return {
	CONTEXT_ACTION_NAME = "SmoothMouseLockSwitchAction",
	MOUSELOCK_ACTION_PRIORITY = Enum.ContextActionPriority.High.Value,
	CREATE_MOBILE_BUTTON = false,

	SMOOTH_CHARACTER_ROTATION = false,
	CHARACTER_ROTATION_SPEED = 5,

	TRANSITION_SPRING_DAMPER = 0.75,
	CAMERA_TRANSITION_IN_SPEED = 20,
	CAMERA_TRANSITION_OUT_SPEED = 25,

	LOCKED_CAMERA_OFFSET = Vector3.new(1.75, 0.25, 0),
	LOCKED_MOUSE_ICON = "rbxasset://textures/MouseLockedCursor.png",
	MOUSE_LOCK_KEYBINDS = MOUSE_LOCK_KEYBINDS,
	syncMouseLockKeybinds = syncMouseLockKeybinds,
}
