--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

type LockedFlags = {
	Sprint: boolean,
	Jump: boolean,
	Swim: boolean,
}

type MovementLockModule = {
	Changed: any,
	GetLockedFlags: () -> LockedFlags,
	IsLocked: (flag: "Sprint" | "Jump" | "Swim") -> boolean,
}

type MovementSpeedMultipliersModule = {
	Changed: any,
	GetMultiplier: () -> number,
}

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Configs = ReplicatedStorage:WaitForChild("Configs")
local MovementControl = Modules:WaitForChild("MovementControl")

local MovementLock = require(MovementControl:WaitForChild("MovementLock")) :: MovementLockModule
local MovementSpeedMultipliers = require(MovementControl:WaitForChild("MovementSpeedMultipliers")) :: MovementSpeedMultipliersModule
local PlayerConfig = require(Configs:WaitForChild("PlayerConfig")) :: any

local localPlayer = Players.LocalPlayer
local activeHumanoid: Humanoid? = nil
local activeConnections: { RBXScriptConnection } = {}

local RENDER_STEP_BIND_NAME = "NormalIsland_MovementLockEnforcer"

local function disconnectActiveConnections()
	pcall(function()
		RunService:UnbindFromRenderStep(RENDER_STEP_BIND_NAME)
	end)
	for _, connection in ipairs(activeConnections) do
		connection:Disconnect()
	end
	table.clear(activeConnections)
end

local function getJumpPower(): number
	return PlayerConfig.jumpPower or 50
end

local function hasJumpStamina(): boolean
	local stamina = (localPlayer:GetAttribute("Stamina") or 0) :: number
	local cost = PlayerConfig.jumpStaminaCost or 20
	return stamina >= cost
end

local function getWalkSpeed(): number
	return (localPlayer:GetAttribute("WalkSpeed") or PlayerConfig.walkSpeed or 14) :: number
end

local function getRunSpeed(): number
	return (localPlayer:GetAttribute("RunSpeed") or PlayerConfig.runSpeed or 20) :: number
end

local function hasAnyLocks(flags: LockedFlags): boolean
	return flags.Sprint or flags.Jump or flags.Swim
end

local function getEffectiveSpeed(flags: LockedFlags, speedMultiplier: number): number
	if speedMultiplier <= 0 then
		return 0
	end

	local humanoid = activeHumanoid
	if humanoid and flags.Swim and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		return 0
	end

	local wantsSprint = localPlayer:GetAttribute("WantsSprint") == true
	local stamina = (localPlayer:GetAttribute("Stamina") or 0) :: number
	local baseSpeed = getWalkSpeed()
	if not flags.Sprint and wantsSprint and stamina > 0 then
		baseSpeed = getRunSpeed()
	end

	return baseSpeed * speedMultiplier
end

local function applyLockState()
	local humanoid = activeHumanoid
	if not humanoid then
		localPlayer:SetAttribute("SprintLocked", false)
		return
	end

	local lockedFlags = MovementLock.GetLockedFlags()
	local speedMultiplier = MovementSpeedMultipliers.GetMultiplier()
	local sprintLocked = lockedFlags.Sprint
	local jumpAllowed = not lockedFlags.Jump and hasJumpStamina()

	localPlayer:SetAttribute("SprintLocked", sprintLocked)
	humanoid.WalkSpeed = getEffectiveSpeed(lockedFlags, speedMultiplier)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpAllowed)
	humanoid.JumpPower = if jumpAllowed then getJumpPower() else 0
	if not jumpAllowed and humanoid.Jump then
		humanoid.Jump = false
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, not lockedFlags.Swim)
	if lockedFlags.Swim and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function bindCharacter(character: Model)
	disconnectActiveConnections()

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 15) :: Humanoid?
	end
	activeHumanoid = humanoid
	applyLockState()

	if not humanoid then
		return
	end

	table.insert(activeConnections, humanoid.StateChanged:Connect(function()
		applyLockState()
	end))

	RunService:BindToRenderStep(RENDER_STEP_BIND_NAME, Enum.RenderPriority.Last.Value, function()
		local h = activeHumanoid
		if not h then
			return
		end
		local lockedFlags = MovementLock.GetLockedFlags()
		if hasAnyLocks(lockedFlags) or MovementSpeedMultipliers.GetMultiplier() ~= 1 then
			applyLockState()
		end
	end)
end

MovementLock.Changed:Connect(function()
	applyLockState()
end)

MovementSpeedMultipliers.Changed:Connect(function()
	applyLockState()
end)

for _, attributeName in ipairs({ "Stamina", "WantsSprint", "WalkSpeed", "RunSpeed" }) do
	localPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
		applyLockState()
	end)
end

if localPlayer.Character then
	task.spawn(bindCharacter, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(bindCharacter)
