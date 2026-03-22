--!strict
-- Binds the Interact key (default F). Gameplay systems can be wired here later.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindsClient = require(script.Parent:WaitForChild("KeybindsClient"))

KeybindsClient.bindAction(KeybindIds.Interact, function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		-- Placeholder: prompts, pickups, doors, etc.
	end
	return Enum.ContextActionResult.Sink
end, {
	actionName = "Interact",
})
