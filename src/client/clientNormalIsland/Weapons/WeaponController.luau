--!strict
--[[
	WeaponController (Client)
	Reusable helper used by weapon Logic modules to provide standard melee:
	animations, combo sequencing, ShapecastHitbox hit detection, and sounds.

	USAGE (from a weapon's Logic.luau):
	  local WeaponController = require(...)
	  local controller = WeaponController.new(weaponModel, player, templateId)
	  controller:Equip()
	  -- ...
	  controller:Destroy()  -- on unequip
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local SHAPECAST_HITBOX_MODULE_NAME = "shapecasthitbox"
local ShapecastHitbox = require(Packages:WaitForChild(SHAPECAST_HITBOX_MODULE_NAME)) :: any

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry")) :: any
local WeaponBasicAttackProfiles =
	require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("AnimationProfiles"):WaitForChild("WeaponBasicAttackProfiles") :: ModuleScript) :: any
local WeaponStanceAnimationProfiles =
	require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("AnimationProfiles"):WaitForChild("WeaponStanceAnimationProfiles") :: ModuleScript) :: any
local RootMotion = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RootMotion") :: ModuleScript) :: any
local MovementControlLocks = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MovementControl"):WaitForChild("MovementControlLocks") :: ModuleScript
) :: any
local WeaponAttackRootMotion = require((script.Parent :: Instance):WaitForChild("WeaponAttackRootMotion") :: ModuleScript) :: any

-- Remotes are created by the server in WeaponService.Initialize().
local weaponRemotes = ReplicatedStorage:WaitForChild("WeaponRemotes")
local weaponAttackRemote = weaponRemotes:WaitForChild("WeaponAttackRequest") :: RemoteEvent

-- ── Module ──────────────────────────────────────────────────────────────────

local WeaponController = {}
WeaponController.__index = WeaponController

local debugEnabled = false

local WEAPON_ATTACK_WALK_SPEED_MULTIPLIER = 0.2

local function debugLog(templateId: string, message: string)
	if not debugEnabled then
		return
	end
	print(string.format("[WeaponDebug][%s] %s", templateId, message))
end

export type WeaponControllerInstance = typeof(setmetatable({} :: {
	weaponModel: Model,
	player: Player,
	character: Model,
	humanoid: Humanoid,
	animator: Animator,
	templateId: string,
	stats: any,
	hitbox: any,
	-- Animation tracks
	idleTrack: AnimationTrack?,
	equipTrack: AnimationTrack?,
	unequipTrack: AnimationTrack?,
	blockTrack: AnimationTrack?,
	_attackAnimByAssetId: { [string]: AnimationTrack },
	_rootMotionMover: any,
	_rootMotionToken: any,
	-- Sounds (created at runtime)
	swingSound: Sound?,
	hitSound: Sound?,
	-- State
	sequenceIndex: number,
	nextAttackTime: number,
	comboExpireTime: number,
	attacking: boolean,
	equipped: boolean,
	_attackLockTags: { [string]: boolean },
	-- Connections to clean up
	_connections: { RBXScriptConnection },
}, WeaponController))

--[[
	WeaponController.new(weaponModel, player, templateId)
	Creates a new controller but does NOT activate it yet. Call :Equip() after.
]]
function WeaponController.new(weaponModel: Model, player: Player, templateId: string): WeaponControllerInstance
	local stats = ItemRegistry.GetTemplate(templateId)
	assert(stats, "[WeaponController] No ItemRegistry template for templateId: " .. templateId)

	local character = player.Character
	assert(character, "[WeaponController] Player has no character")

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "[WeaponController] Character has no Humanoid")

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = humanoid
		animator = newAnimator
	end

	local self = setmetatable({}, WeaponController)
	self.weaponModel = weaponModel
	self.player = player
	self.character = character
	self.humanoid = humanoid
	self.animator = animator
	self.templateId = templateId
	self.stats = stats
	self.hitbox = nil

	-- Animation tracks (loaded lazily in Equip)
	self.idleTrack = nil
	self.equipTrack = nil
	self.unequipTrack = nil
	self.blockTrack = nil
	self._attackAnimByAssetId = {}
	self._rootMotionMover = nil
	self._rootMotionToken = nil

	-- Sounds
	self.swingSound = nil
	self.hitSound = nil

	-- State
	self.sequenceIndex = 1
	self.nextAttackTime = 0
	self.comboExpireTime = 0
	self.attacking = false
	self.equipped = false

	self._attackLockTags = {}
	self._connections = {}

	return self :: any
end

function WeaponController.SetDebugEnabled(enabled: boolean)
	debugEnabled = enabled
	print(string.format("[Dev] Weapon debug logs: %s", enabled and "ON" or "OFF"))
end

-- ── Private helpers ─────────────────────────────────────────────────────────

local function loadAnimationFromId(animator: Animator, assetId: string): AnimationTrack?
	if assetId == "rbxassetid://0" or assetId == "" then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = assetId
	return animator:LoadAnimation(anim)
end

local function createSoundOnPart(parent: Instance, assetId: string): Sound?
	if assetId == "rbxassetid://0" or assetId == "" then return nil end
	local sound = Instance.new("Sound")
	sound.SoundId = assetId
	sound.Parent = parent
	return sound
end

local function connect(self: WeaponControllerInstance, conn: RBXScriptConnection)
	table.insert(self._connections, conn)
end

local function cancelAttackRootMotion(self: WeaponControllerInstance)
	local tok = self._rootMotionToken
	self._rootMotionToken = nil
	if tok and type(tok) == "table" and type(tok.IsActive) == "function" and tok:IsActive() then
		tok:Cancel()
	end
end

local function ensureRootMotionMover(self: WeaponControllerInstance)
	if self._rootMotionMover then
		return self._rootMotionMover
	end
	local m = RootMotion.createMover(self.character)
	self._rootMotionMover = m
	return m
end

local function lockAttackMovement(self: WeaponControllerInstance, attackIndex: number, profile: any)
	local movementLocks = profile.movementLocks
	if type(movementLocks) ~= "table" or next(movementLocks) == nil then
		return
	end

	local lockTag = string.format("Weapon_%s_%d", self.templateId, attackIndex)
	self._attackLockTags[lockTag] = true
	MovementControlLocks.Lock(lockTag, movementLocks, profile.hitDuration, WEAPON_ATTACK_WALK_SPEED_MULTIPLIER)
end

-- ── Public API ──────────────────────────────────────────────────────────────

function WeaponController.Equip(self: WeaponControllerInstance)
	if self.equipped then return end
	self.equipped = true

	local stats = self.stats
	local animator = self.animator

	-- Load animations --------------------------------------------------------
	self.idleTrack = loadAnimationFromId(animator, WeaponStanceAnimationProfiles.GetAnimationId(stats.idleMotionId))
	self.equipTrack = loadAnimationFromId(animator, WeaponStanceAnimationProfiles.GetAnimationId(stats.equipMotionId))
	self.unequipTrack = loadAnimationFromId(animator, WeaponStanceAnimationProfiles.GetAnimationId(stats.unequipMotionId))

	if stats.blockMotionId then
		self.blockTrack = loadAnimationFromId(animator, WeaponStanceAnimationProfiles.GetAnimationId(stats.blockMotionId))
	end

	table.clear(self._attackAnimByAssetId)
	for _, entry in ipairs(stats.attackSequence or {}) do
		local attackMotionId = entry.attackMotionId
		assert(type(attackMotionId) == "string" and #attackMotionId > 0, "[WeaponController] attackSequence entry missing attackMotionId")
		local profile = WeaponBasicAttackProfiles.GetProfile(attackMotionId)
		assert(profile, "[WeaponController] unknown attackMotionId: " .. attackMotionId)
		local assetId = profile.animationId
		if not self._attackAnimByAssetId[assetId] then
			local track = loadAnimationFromId(animator, assetId)
			if track then
				self._attackAnimByAssetId[assetId] = track
			end
		end
	end

	-- Load sounds ------------------------------------------------------------
	local handle = self.weaponModel:FindFirstChild("Handle") or self.weaponModel.PrimaryPart
	if handle then
		self.swingSound = createSoundOnPart(handle, stats.swingSoundId)
		self.hitSound = createSoundOnPart(handle, stats.hitSoundId)
	end

	-- Weapon visuals (and the `RightGrip` Motor6D) are server-owned/replicated.
	-- The client should not create/destroy grip motors.
	if handle and handle:IsA("BasePart") and self.weaponModel ~= self.character then
		if self.weaponModel.Parent ~= self.character then
			self.weaponModel.Parent = self.character
		end
	end

	-- ShapecastHitbox setup --------------------------------------------------
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.character }

	self.hitbox = ShapecastHitbox.new(self.weaponModel, params)

	-- Apply global cast data from item config
	if stats.castType == "Spherecast" and stats.castRadius then
		self.hitbox:SetCastData({
			CastType = "Spherecast",
			Radius = stats.castRadius,
		})
	elseif stats.castType == "Blockcast" and stats.castSize then
		self.hitbox:SetCastData({
			CastType = "Blockcast",
			Size = stats.castSize,
		})
	end
	-- "Raycast" is the default, no SetCastData needed.

	-- Play equip animation ---------------------------------------------------
	if self.equipTrack then
		debugLog(self.templateId, "equip anim")
		self.equipTrack:Play()
	end

	-- Play idle animation (looped) -------------------------------------------
	if self.idleTrack then
		self.idleTrack.Looped = true
		debugLog(self.templateId, "idle start")
		self.idleTrack:Play()
	end

	-- Input binding: primary attack on mouse click ---------------------------
	connect(self, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if not self.equipped then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:Attack()
		end
	end))
end

--[[
	Attack()
	Performs the next attack in the combo sequence. Enforces local cooldown,
	plays animation + sound, activates ShapecastHitbox, and fires hit claims
	to the server.
]]
function WeaponController.Attack(self: WeaponControllerInstance)
	if not self.equipped then return end

	local now = tick()
	if now < self.nextAttackTime then return end

	local sequence = self.stats.attackSequence or {}
	local sequenceLength = #sequence
	if sequenceLength == 0 then return end

	local attackIndex
	if self.sequenceIndex >= 1 and self.sequenceIndex <= sequenceLength and now <= self.comboExpireTime then
		local nextIndex = self.sequenceIndex + 1
		if nextIndex > sequenceLength then
			nextIndex = 1
		end
		attackIndex = nextIndex
	else
		attackIndex = 1
	end

	local attackEntry = sequence[attackIndex]
	if not attackEntry then return end

	local attackMotionId = attackEntry.attackMotionId
	if type(attackMotionId) ~= "string" or attackMotionId == "" then
		return
	end
	local profile = WeaponBasicAttackProfiles.GetProfile(attackMotionId)
	if not profile then
		warn("[WeaponController] unknown attackMotionId: " .. attackMotionId)
		return
	end

	self.sequenceIndex = attackIndex

	local hitDuration = profile.hitDuration
	self.nextAttackTime = now + hitDuration
	self.comboExpireTime = now + (profile.comboTimeLimit or hitDuration)
	lockAttackMovement(self, attackIndex, profile)

	cancelAttackRootMotion(self)

	-- Play animation (+ optional RootMotion from profile)
	local track = self._attackAnimByAssetId[profile.animationId]
	if track then
		debugLog(self.templateId, string.format("attack anim %d", attackIndex))
		track:Play()
	end

	if WeaponAttackRootMotion.profileUsesRootMotion(profile) then
		local mover = ensureRootMotionMover(self)
		self._rootMotionToken = WeaponAttackRootMotion.run(mover, self.character, profile.motion, {
			humanoid = self.humanoid,
			hitDuration = hitDuration,
			syncMotionDurationFromHit = profile.syncMotionDurationFromHit == true,
		})
	end

	-- Play swing sound
	if self.swingSound then
		self.swingSound:Play()
	end

	-- Activate hitbox for the duration specified in this attack entry
	if self.hitbox then
		local targetsHit: { [Model]: boolean } = {}

		self.hitbox:BeforeStart(function()
			table.clear(targetsHit)
		end):OnHit(function(raycastResult, _segmentHit)
			local hitInstance = raycastResult.Instance
			if not hitInstance then return end

			local hitModel = hitInstance:FindFirstAncestorOfClass("Model") :: Model?
			if not hitModel or hitModel == self.character then return end
			if targetsHit[hitModel] then return end

			local enemyHumanoid = hitModel:FindFirstChildOfClass("Humanoid")
			if not enemyHumanoid or enemyHumanoid.Health <= 0 then return end

			targetsHit[hitModel] = true

			-- Play hit sound locally
			if self.hitSound then
				self.hitSound:Play()
			end

			-- Fire hit claim to server for validation
			local targetPlayer = Players:GetPlayerFromCharacter(hitModel)
			if targetPlayer then
				weaponAttackRemote:FireServer(self.templateId, targetPlayer, hitModel.PrimaryPart and hitModel.PrimaryPart.Position or hitInstance.Position)
			end
		end):OnStopped(function(cleanCallbacks)
			cleanCallbacks()
		end)

		self.hitbox:HitStart(hitDuration)
	end
end

--[[
	Destroy()
	Full cleanup. Call this when the weapon is unequipped or the character dies.
]]
function WeaponController.Destroy(self: WeaponControllerInstance)
	self.equipped = false

	cancelAttackRootMotion(self)
	if self._rootMotionMover then
		(self._rootMotionMover :: any):destroy()
		self._rootMotionMover = nil
	end
	for _, tr in pairs(self._attackAnimByAssetId) do
		tr:Stop()
	end
	table.clear(self._attackAnimByAssetId)

	-- Play unequip animation (fire-and-forget)
	if self.unequipTrack then
		debugLog(self.templateId, "unequip anim")
		self.unequipTrack:Play()
	end

	-- Stop idle animation
	if self.idleTrack then
		debugLog(self.templateId, "idle end")
		self.idleTrack:Stop()
	end

	-- Destroy hitbox
	if self.hitbox then
		self.hitbox:Destroy()
		self.hitbox = nil
	end

	-- Disconnect all input connections
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	for lockTag in pairs(self._attackLockTags) do
		MovementControlLocks.Unlock(lockTag)
	end
	table.clear(self._attackLockTags)

	-- Destroy runtime sounds
	if self.swingSound then self.swingSound:Destroy(); self.swingSound = nil end
	if self.hitSound then self.hitSound:Destroy(); self.hitSound = nil end
end

return WeaponController
