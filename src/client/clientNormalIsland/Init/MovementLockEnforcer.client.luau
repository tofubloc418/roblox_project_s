--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

type LockedFlags = {
	Walk: boolean,
	Sprint: boolean,
	Jump: boolean,
	Swim: boolean,
}

type MovementLockModule = {
	Changed: any,
	GetLockedFlags: () -> LockedFlags,
	IsLocked: (flag: "Walk" | "Sprint" | "Jump" | "Swim") -> boolean,
}

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Configs = ReplicatedStorage:WaitForChild("Configs")

local MovementLock = require(Modules:WaitForChild("MovementLock")) :: MovementLockModule
local PlayerConfig = require(Configs:WaitForChild("PlayerConfig")) :: any

type MovementAnimCfg = {
	LocomotionIdSet: { [number]: boolean },
	ParseAssetIdNumber: (string?) -> number?,
}
local MovementAnimationConfig = require(Configs:WaitForChild("MovementAnimationConfig")) :: MovementAnimCfg

local localPlayer = Players.LocalPlayer
local activeHumanoid: Humanoid? = nil
local activeConnections: { RBXScriptConnection } = {}
local cachedControls: any = nil
local controlsDisabledByLock = false

local RENDER_STEP_BIND_NAME = "NormalIsland_MovementLockEnforcer"
local ROOT_MOTION_LOCOMOTION_ATTR = "RootMotion_LocomotionLock"

local function isRootMotionLocomotionLocked(humanoid: Humanoid): boolean
	if localPlayer:GetAttribute(ROOT_MOTION_LOCOMOTION_ATTR) == true then
		return true
	end
	local ch = humanoid.Parent
	return ch ~= nil and ch:IsA("Model") and ch:GetAttribute(ROOT_MOTION_LOCOMOTION_ATTR) == true
end

local function suppressRootMotionLocomotionTracks(humanoid: Humanoid)
	if not isRootMotionLocomotionLocked(humanoid) then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local bumpSet = MovementAnimationConfig.LocomotionIdSet
	local parse = MovementAnimationConfig.ParseAssetIdNumber
	for _, track in animator:GetPlayingAnimationTracks() do
		local anim = track.Animation
		if anim then
			local num = parse(anim.AnimationId)
			if num and bumpSet[num] then
				track:AdjustWeight(0, 0)
			end
		end
	end
end

local function disconnectActiveConnections()
	pcall(function()
		RunService:UnbindFromRenderStep(RENDER_STEP_BIND_NAME)
	end)
	for _, connection in ipairs(activeConnections) do
		connection:Disconnect()
	end
	table.clear(activeConnections)
end

local function getControls()
	if cachedControls ~= nil then
		return cachedControls
	end

	local playerScripts = localPlayer:FindFirstChildOfClass("PlayerScripts")
		or (localPlayer:WaitForChild("PlayerScripts", 15) :: PlayerScripts?)
	if not playerScripts then
		return nil
	end

	local playerModule = playerScripts:FindFirstChild("PlayerModule")
		or (playerScripts:WaitForChild("PlayerModule", 15) :: ModuleScript?)
	if not playerModule then
		return nil
	end

	local ok, module = pcall(require, playerModule)
	if not ok or type(module) ~= "table" or type((module :: any).GetControls) ~= "function" then
		return nil
	end

	cachedControls = (module :: any):GetControls()
	return cachedControls
end

local function getJumpPower(): number
	return PlayerConfig.jumpPower or 50
end

local function hasJumpStamina(): boolean
	local stamina = (localPlayer:GetAttribute("Stamina") or 0) :: number
	local cost = PlayerConfig.jumpStaminaCost or 20
	return stamina >= cost
end

local function hasAnyLocks(flags: LockedFlags): boolean
	return flags.Walk or flags.Sprint or flags.Jump or flags.Swim
end

local function setLocomotionInputSuppressed(suppressed: boolean)
	local controls = getControls()
	if not controls then
		return
	end

	if suppressed then
		if not controlsDisabledByLock then
			controlsDisabledByLock = true
			controls:Disable()
		end
	elseif controlsDisabledByLock then
		controlsDisabledByLock = false
		controls:Enable()
	end
end

local function applyLockState()
	local humanoid = activeHumanoid
	if not humanoid then
		setLocomotionInputSuppressed(false)
		localPlayer:SetAttribute("SprintLocked", false)
		return
	end

	local lockedFlags = MovementLock.GetLockedFlags()
	local rootMotionLock = isRootMotionLocomotionLocked(humanoid)
	local locomotionInputSuppressed = rootMotionLock
		or lockedFlags.Walk
		or (lockedFlags.Swim and humanoid:GetState() == Enum.HumanoidStateType.Swimming)
	local sprintLocked = lockedFlags.Sprint or lockedFlags.Walk or rootMotionLock
	local jumpAllowed = not lockedFlags.Jump and hasJumpStamina() and not rootMotionLock

	setLocomotionInputSuppressed(locomotionInputSuppressed)
	localPlayer:SetAttribute("SprintLocked", sprintLocked)

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
		if hasAnyLocks(lockedFlags) or isRootMotionLocomotionLocked(h) then
			applyLockState()
		end
		if isRootMotionLocomotionLocked(h) then
			suppressRootMotionLocomotionTracks(h)
		end
	end)

	table.insert(activeConnections, localPlayer:GetAttributeChangedSignal(ROOT_MOTION_LOCOMOTION_ATTR):Connect(applyLockState))
end

MovementLock.Changed:Connect(function()
	applyLockState()
end)

localPlayer:GetAttributeChangedSignal("Stamina"):Connect(function()
	applyLockState()
end)

if localPlayer.Character then
	task.spawn(bindCharacter, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(bindCharacter)
