local KeybindsClient = require(script.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))

local Constants = require(script:WaitForChild("SmoothShiftLock"):WaitForChild("Constants"))
local SmoothShiftLock = require(script:WaitForChild("SmoothShiftLock"))

local function refreshCameraLockKeybinds()
	Constants.syncMouseLockKeybinds()
	if SmoothShiftLock.IsEnabled then
		SmoothShiftLock:Disable()
		SmoothShiftLock:Enable()
	end
end

SmoothShiftLock:Start()

KeybindsClient.subscribe(refreshCameraLockKeybinds)
task.defer(refreshCameraLockKeybinds)
