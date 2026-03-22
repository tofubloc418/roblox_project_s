return {
	CONTEXT_ACTION_NAME = "SmoothMouseLockSwitchAction",
	MOUSELOCK_ACTION_PRIORITY = Enum.ContextActionPriority.High.Value,
	CREATE_MOBILE_BUTTON = false,

	SMOOTH_CHARACTER_ROTATION = true,
	CHARACTER_ROTATION_SPEED = 5,

	TRANSITION_SPRING_DAMPER = 0.75,
	CAMERA_TRANSITION_IN_SPEED = 20,
	CAMERA_TRANSITION_OUT_SPEED = 25,

	LOCKED_CAMERA_OFFSET = Vector3.new(1.75, 0.25, 0),
	LOCKED_MOUSE_ICON = "rbxasset://textures/MouseLockedCursor.png",
	MOUSE_LOCK_KEYBINDS = { Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift },
}
