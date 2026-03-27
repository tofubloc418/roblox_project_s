local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local requireAny = require :: any

local inputRemotes = ReplicatedStorage:WaitForChild("InputRemotes")
local setSprintRemote: RemoteEvent = inputRemotes:WaitForChild("SetSprint")
local jumpPressedRemote: RemoteEvent = inputRemotes:WaitForChild("JumpPressed")

local player = Players.LocalPlayer
local ROOT_MOTION_LOCOMOTION_ATTR = "RootMotion_LocomotionLock"

local function isRootMotionLocomotionLocked(): boolean
	if player:GetAttribute(ROOT_MOTION_LOCOMOTION_ATTR) == true then
		return true
	end
	local ch = player.Character
	return ch ~= nil and ch:GetAttribute(ROOT_MOTION_LOCOMOTION_ATTR) == true
end

local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = requireAny(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindsClient = requireAny(script.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))
local MovementLock = requireAny(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MovementLock"))
local PlayerConfig = requireAny(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

local function isSprintLocked(): boolean
	return player:GetAttribute("SprintLocked") == true
		or MovementLock.IsLocked("Sprint")
		or MovementLock.IsLocked("Walk")
		or isRootMotionLocomotionLocked()
end

local function isJumpLocked(): boolean
	return MovementLock.IsLocked("Jump") or isRootMotionLocomotionLocked()
end

local function setSprint(desired: boolean)
	if desired and isSprintLocked() then
		desired = false
	end

	player:SetAttribute("WantsSprint", desired)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and PlayerConfig then
		if isRootMotionLocomotionLocked() then
			humanoid.WalkSpeed = 0
		else
			local stamina = player:GetAttribute("Stamina") or (PlayerConfig.baseMaxStamina or 100)
			local canRun = stamina > 0
			local want = desired and canRun
			humanoid.WalkSpeed = want and (PlayerConfig.runSpeed or 20) or (PlayerConfig.walkSpeed or 14)
		end
	end
	setSprintRemote:FireServer(desired)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
	if KeybindsClient.isInputForAction(KeybindIds.Sprint, input) then
		setSprint(true)
	elseif KeybindsClient.isInputForAction(KeybindIds.Jump, input) then
		if not isJumpLocked() then
			jumpPressedRemote:FireServer()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
	if KeybindsClient.isInputForAction(KeybindIds.Sprint, input) then
		setSprint(false)
	end
end)

MovementLock.Changed:Connect(function(lockedFlags)
	if lockedFlags.Walk or lockedFlags.Sprint then
		setSprint(false)
	end
end)

player:GetAttributeChangedSignal("Stamina"):Connect(function()
	local stamina = player:GetAttribute("Stamina") or 0
	if stamina <= 0 then
		setSprint(false)
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if isRootMotionLocomotionLocked() then
			humanoid.JumpPower = 0
		else
			local cost = PlayerConfig.jumpStaminaCost or 20
			local allow = stamina >= cost
			humanoid.JumpPower = allow and (PlayerConfig.jumpPower or 50) or 0
		end
	end
end)

local function blockJump(_, state, input)
	if state == Enum.UserInputState.Begin then
		if isJumpLocked() then
			return Enum.ContextActionResult.Sink
		end

		local stamina = player:GetAttribute("Stamina") or 0
		local cost = PlayerConfig.jumpStaminaCost or 20
		if stamina < cost then
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end
KeybindsClient.bindAction(KeybindIds.Jump, blockJump, {
	actionName = "BlockJumpOnLowStamina",
})
