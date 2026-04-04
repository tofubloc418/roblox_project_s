--!strict
-- Bridges Configs/AnimationProfiles/WeaponBasicAttackProfiles motion specs → RootMotion Mover API (no edits under Modules/RootMotion).

export type MotionRunContext = {
	humanoid: Humanoid,
	hitDuration: number?,
	syncMotionDurationFromHit: boolean?,
}

local WeaponAttackRootMotion = {}

local function flatLook(root: BasePart): Vector3
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-4 then
		return Vector3.zAxis
	end
	return flat.Unit
end

local function resolveDirection(ref: string, root: BasePart, humanoid: Humanoid): Vector3
	if ref == "HumanoidRootPartLookFlat" then
		return flatLook(root)
	elseif ref == "HumanoidRootPartLook" then
		return root.CFrame.LookVector.Unit
	elseif ref == "HumanoidMoveDirection" then
		local md = humanoid.MoveDirection
		if md.Magnitude < 1e-4 then
			return flatLook(root)
		end
		return md.Unit
	end
	error(("[WeaponAttackRootMotion] unknown DirectionRef %q"):format(tostring(ref)))
end

local function resolveOrigin(origin: any, root: BasePart): Vector3
	if origin.ref == "BehindRootFlat" then
		return root.Position - flatLook(root) * origin.behindStuds
	end
	error("[WeaponAttackRootMotion] unknown knockback OriginRef")
end

local function resolveWorldTarget(t: any, root: BasePart): Vector3
	if t.ref == "InFrontOfRootFlat" then
		return root.Position + flatLook(root) * t.forwardStuds
	end
	error("[WeaponAttackRootMotion] unknown WorldTargetRef")
end

local function resolveCenter(c: any, root: BasePart): Vector3
	if c.ref == "HumanoidRootPartWorldPosition" then
		local off: Vector3 = if c.offset ~= nil then c.offset else Vector3.zero
		return root.Position + off
	end
	error("[WeaponAttackRootMotion] unknown WorldCenterRef")
end

local function resolveTeleportTarget(t: any, root: BasePart): CFrame
	if t.ref == "RootForwardFlat" then
		local pos = root.Position + flatLook(root) * t.forwardStuds
		local preserve = if t.preserveCharacterYaw == nil then true else t.preserveCharacterYaw
		if preserve then
			return CFrame.new(pos) * root.CFrame.Rotation
		end
		local flat = flatLook(root)
		return CFrame.lookAt(pos, pos + flat)
	end
	error("[WeaponAttackRootMotion] unknown TeleportTargetRef")
end

local function pickDuration(sync: boolean, hitDur: number?, configured: number): number
	if sync and hitDur ~= nil and hitDur > 0 then
		return hitDur
	end
	return configured
end

local function pickOptionalDuration(sync: boolean, hitDur: number?, configured: number?): number?
	if sync and hitDur ~= nil and hitDur > 0 then
		return hitDur
	end
	return configured
end

local function getLocomotionVelocity(humanoid: Humanoid): Vector3
	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude < 1e-4 then
		return Vector3.zero
	end
	local speed = humanoid.WalkSpeed
	if speed <= 0 then
		return Vector3.zero
	end
	local flatDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z)
	if flatDirection.Magnitude < 1e-4 then
		return Vector3.zero
	end
	return flatDirection.Unit * speed
end

--[[
	Returns ActiveMovement token or nil when motion is none / invalid.
]]
function WeaponAttackRootMotion.run(mover: any, character: Model, motion: any, context: MotionRunContext): any?
	local humanoid = context.humanoid
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end

	local kind = motion.kind
	if type(kind) ~= "string" then
		return nil
	end

	local sync = context.syncMotionDurationFromHit == true
	local hitDur = context.hitDuration

	if kind == "none" then
		return nil
	end

	if kind == "translate" then
		local dir = resolveDirection(motion.direction, hrp, humanoid)
		return mover:translate({
			direction = dir,
			distance = motion.distance,
			duration = pickDuration(sync, hitDur, motion.duration),
			accelerationMultiplier = motion.accelerationMultiplier,
			additionalVelocity = function()
				return getLocomotionVelocity(humanoid)
			end,
		})
	elseif kind == "dash" then
		local dir = resolveDirection(motion.direction, hrp, humanoid)
		return mover:dash({
			direction = dir,
			distance = motion.distance,
			duration = pickDuration(sync, hitDur, motion.duration),
			easing = motion.easing,
			accelerationMultiplier = motion.accelerationMultiplier,
			additionalVelocity = function()
				return getLocomotionVelocity(humanoid)
			end,
		})
	elseif kind == "lunge" then
		local dir = resolveDirection(motion.direction, hrp, humanoid)
		return mover:lunge({
			direction = dir,
			distance = motion.distance,
			duration = pickOptionalDuration(sync, hitDur, motion.duration),
			accelerationMultiplier = motion.accelerationMultiplier,
		})
	elseif kind == "knockback" then
		return mover:knockback({
			origin = resolveOrigin(motion.origin, hrp),
			distance = motion.distance,
			duration = pickDuration(sync, hitDur, motion.duration),
			arcAngleDegrees = motion.arcAngleDegrees,
			accelerationMultiplier = motion.accelerationMultiplier,
			decay = motion.decay,
			easing = motion.easing,
		})
	elseif kind == "pull" then
		return mover:pull({
			target = resolveWorldTarget(motion.target, hrp),
			speed = motion.speed,
			maxDuration = pickDuration(sync, hitDur, motion.maxDuration),
			arrivalRadius = motion.arrivalRadius,
			accelerationMultiplier = motion.accelerationMultiplier,
		})
	elseif kind == "launch" then
		return mover:launch({
			height = motion.height,
			accelerationMultiplier = motion.accelerationMultiplier,
		})
	elseif kind == "slam" then
		return mover:slam({
			speed = motion.speed,
			maxDuration = pickOptionalDuration(sync, hitDur, motion.maxDuration),
			accelerationMultiplier = motion.accelerationMultiplier,
		})
	elseif kind == "float" then
		return mover:float({
			duration = pickDuration(sync, hitDur, motion.duration),
			accelerationMultiplier = motion.accelerationMultiplier,
			hoverHeightGain = motion.hoverHeightGain,
			targetY = motion.targetY,
		})
	elseif kind == "slide" then
		local dir = resolveDirection(motion.direction, hrp, humanoid)
		return mover:slide({
			direction = dir,
			speed = motion.speed,
			duration = pickDuration(sync, hitDur, motion.duration),
			friction = motion.friction,
			groundRayLength = motion.groundRayLength,
			accelerationMultiplier = motion.accelerationMultiplier,
		})
	elseif kind == "teleport" then
		return mover:teleport({
			target = resolveTeleportTarget(motion.target, hrp),
			validatePath = motion.validatePath,
			collisionGroup = motion.collisionGroup,
		})
	elseif kind == "orbit" then
		return mover:orbit({
			center = resolveCenter(motion.center, hrp),
			radius = motion.radius,
			angularSpeed = motion.angularSpeed,
			duration = pickDuration(sync, hitDur, motion.duration),
			axis = motion.axis,
			startAngle = motion.startAngle,
			accelerationMultiplier = motion.accelerationMultiplier,
		})
	elseif kind == "springTo" then
		return mover:springTo({
			target = resolveWorldTarget(motion.target, hrp),
			frequency = motion.frequency,
			damping = motion.damping,
			maxDuration = pickOptionalDuration(sync, hitDur, motion.maxDuration),
			maxForce = motion.maxForce,
			maxVelocity = motion.maxVelocity,
			accelerationMultiplier = motion.accelerationMultiplier,
			applyAtCenterOfMass = motion.applyAtCenterOfMass,
		})
	end

	error(("[WeaponAttackRootMotion] unknown motion.kind %q"):format(tostring(kind)))
end

function WeaponAttackRootMotion.profileUsesRootMotion(profile: any): boolean
	if type(profile) ~= "table" then
		return false
	end
	local m = profile.motion
	return type(m) == "table" and m.kind ~= "none"
end

return WeaponAttackRootMotion
