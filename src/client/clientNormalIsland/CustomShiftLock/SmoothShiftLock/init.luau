--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Settings = UserSettings()
local GameSettings = Settings.GameSettings

local DependenciesFolder = script:WaitForChild("Dependencies")
local Maid = require(DependenciesFolder:WaitForChild("Maid"))
local Signal = require(DependenciesFolder:WaitForChild("Signal"))
local Spring = require(DependenciesFolder:WaitForChild("Spring"))

local SmoothShiftLock = {} :: any

local Camera = assert(Workspace.CurrentCamera, "[SmoothShiftLock] CurrentCamera required")
local LocalPlayer = Players.LocalPlayer

local Constants = require(script:WaitForChild("Constants"))

local _character: Model?
local HumanoidRootPart: BasePart?
local Humanoid: Humanoid?

local function refreshCharacterVariables()
	local ch = LocalPlayer.Character
	assert(ch, "Character expected")
	_character = ch
	HumanoidRootPart = ch:WaitForChild("HumanoidRootPart") :: BasePart
	Humanoid = ch:WaitForChild("Humanoid") :: Humanoid
end

function SmoothShiftLock:Start()
	if SmoothShiftLock._started then
		warn("[SmoothShiftLock]: Is already started")
		return
	end

	SmoothShiftLock._started = true

	SmoothShiftLock._maid = Maid.new()
	SmoothShiftLock._stateMaid = Maid.new()
	SmoothShiftLock._mouseLockMaid = Maid.new()

	SmoothShiftLock.FirstPersonEvent = SmoothShiftLock._maid:GiveTask(Signal.new())
	SmoothShiftLock.MouseLockEvent = SmoothShiftLock._maid:GiveTask(Signal.new())

	SmoothShiftLock._cameraOffsetSpring = Spring.new(Vector3.new(0, 0, 0))

	SmoothShiftLock.IsEnabled = false
	SmoothShiftLock.ShouldEnable = false
	SmoothShiftLock.IsAvailable = false
	SmoothShiftLock.IsMouseLocked = false
	SmoothShiftLock.IsFirstPerson = false

	SmoothShiftLock._maid:GiveTask(GameSettings.Changed:Connect(function(property)
		if property ~= "ComputerMovementMode" then
			return
		end
		SmoothShiftLock:_updateMouseLockAvailability()
	end))

	SmoothShiftLock._maid:GiveTask(LocalPlayer:GetPropertyChangedSignal("DevComputerMovementMode"):Connect(function()
		SmoothShiftLock:_updateMouseLockAvailability()
	end))

	SmoothShiftLock:_updateMouseLockAvailability()

	SmoothShiftLock:Enable()
	SmoothShiftLock._maid:GiveTask(function()
		SmoothShiftLock:Disable()
	end)
end

function SmoothShiftLock:Destroy()
	SmoothShiftLock._maid:DoCleaning()
	SmoothShiftLock._started = false
end

function SmoothShiftLock:_updateCameraOffset()
	if SmoothShiftLock.IsFirstPerson then
		SmoothShiftLock._cameraOffsetSpring.Damper = 1
	else
		SmoothShiftLock._cameraOffsetSpring.Damper = Constants.TRANSITION_SPRING_DAMPER
	end

	if SmoothShiftLock.IsMouseLocked and not SmoothShiftLock.IsFirstPerson then
		SmoothShiftLock._cameraOffsetSpring.Speed = Constants.CAMERA_TRANSITION_IN_SPEED
		SmoothShiftLock._cameraOffsetSpring.Target = Constants.LOCKED_CAMERA_OFFSET
	else
		SmoothShiftLock._cameraOffsetSpring.Speed = Constants.CAMERA_TRANSITION_OUT_SPEED
		SmoothShiftLock._cameraOffsetSpring.Target = Vector3.new(0, 0, 0)
	end
end

function SmoothShiftLock:_updateMouseLockEnabledState()
	local isEnabled = SmoothShiftLock.ShouldEnable and SmoothShiftLock.IsAvailable

	if isEnabled == SmoothShiftLock.IsEnabled then
		return
	end
	SmoothShiftLock.IsEnabled = isEnabled

	if isEnabled then
		if LocalPlayer.Character then
			refreshCharacterVariables()
		end

		SmoothShiftLock._stateMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
			refreshCharacterVariables()
		end))

		local lockKey1 = assert(Constants.MOUSE_LOCK_KEYBINDS[1], "MOUSE_LOCK_KEYBINDS[1]")
		local lockKey2 = assert(Constants.MOUSE_LOCK_KEYBINDS[2], "MOUSE_LOCK_KEYBINDS[2]")

		ContextActionService:BindActionAtPriority(
			Constants.CONTEXT_ACTION_NAME,
			function(_actionName, inputState, _inputObject)
				if inputState == Enum.UserInputState.Begin then
					SmoothShiftLock:MouseLock()
					return Enum.ContextActionResult.Sink
				end

				return Enum.ContextActionResult.Pass
			end,
			Constants.CREATE_MOBILE_BUTTON,
			Constants.MOUSELOCK_ACTION_PRIORITY,
			lockKey1,
			lockKey2
		)

		SmoothShiftLock._stateMaid:GiveTask(function()
			ContextActionService:UnbindAction(Constants.CONTEXT_ACTION_NAME)
		end)

		SmoothShiftLock._stateMaid:GiveTask(function()
			SmoothShiftLock:MouseLock(false)
		end)

		SmoothShiftLock._stateMaid:GiveTask(RunService.RenderStepped:Connect(function()
			if Camera.CameraType ~= Enum.CameraType.Custom then
				return
			end
			if Humanoid == nil or Camera.CameraSubject ~= Humanoid then
				return
			end

			local cameraDelta = Camera.Focus.Position - Camera.CFrame.Position
			local isFirstPerson = cameraDelta.Magnitude < 1

			if SmoothShiftLock.IsFirstPerson ~= isFirstPerson then
				SmoothShiftLock.IsFirstPerson = isFirstPerson
				SmoothShiftLock:_updateCameraOffset()
				SmoothShiftLock.FirstPersonEvent:Fire(isFirstPerson)
			end

			Camera.CFrame = Camera.CFrame * CFrame.new(SmoothShiftLock._cameraOffsetSpring.Position)
		end))
	else
		SmoothShiftLock._stateMaid:DoCleaning()
	end
end

function SmoothShiftLock:_updateMouseLockAvailability()
	local DevMovementModeIsScriptable = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable
	local UserHasClickToMoveEnabled = GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove
	local MouseLockAvailable = not UserHasClickToMoveEnabled
		and not DevMovementModeIsScriptable

	SmoothShiftLock.IsAvailable = MouseLockAvailable
	SmoothShiftLock:_updateMouseLockEnabledState()
end

function SmoothShiftLock:Enable()
	SmoothShiftLock.ShouldEnable = true
	SmoothShiftLock:_updateMouseLockEnabledState()
end

function SmoothShiftLock:Disable()
	SmoothShiftLock.ShouldEnable = false
	SmoothShiftLock:_updateMouseLockEnabledState()
end

function SmoothShiftLock:MouseLock(enable: boolean?)
	local isMouseLocked: boolean
	if type(enable) == "boolean" then
		isMouseLocked = enable
	else
		isMouseLocked = not SmoothShiftLock.IsMouseLocked
	end

	if isMouseLocked == SmoothShiftLock.IsMouseLocked then
		return
	end
	SmoothShiftLock.IsMouseLocked = isMouseLocked

	if isMouseLocked then
		UserInputService.MouseIcon = Constants.LOCKED_MOUSE_ICON
		SmoothShiftLock:_updateCameraOffset()

		SmoothShiftLock._mouseLockMaid:GiveTask(RunService.RenderStepped:Connect(function(deltaTime: number)
			if not HumanoidRootPart or not Humanoid then
				return
			end

			Humanoid.AutoRotate = false

			if not (Humanoid :: any).Sit then
				local _x, y, _z = Camera.CFrame:ToOrientation()
				local finalCFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, y, 0)

				if Constants.SMOOTH_CHARACTER_ROTATION then
					HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(finalCFrame, deltaTime * 5 * Constants.CHARACTER_ROTATION_SPEED)
				else
					HumanoidRootPart.CFrame = finalCFrame
				end
			end

			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end))

		SmoothShiftLock._mouseLockMaid:GiveTask(function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIcon = ""
			SmoothShiftLock:_updateCameraOffset()
		end)

		SmoothShiftLock._mouseLockMaid:GiveTask(function()
			if not Humanoid then
				return
			end
			Humanoid.AutoRotate = true
		end)
	else
		SmoothShiftLock._mouseLockMaid:DoCleaning()
	end

	SmoothShiftLock.MouseLockEvent:Fire(isMouseLocked)
end

return SmoothShiftLock
