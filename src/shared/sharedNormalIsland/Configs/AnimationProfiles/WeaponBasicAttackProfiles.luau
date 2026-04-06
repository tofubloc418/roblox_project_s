--!strict
-- Basic attack id → animation, motion, hit timing (absolute seconds; use X/60 for frame counts), movement locks.
-- Stance: WeaponStanceAnimationProfiles. Timing: hitbox window, comboTimeLimitMin, comboTimeLimitMax.

export type MotionEasingId = "linear" | "quadOut" | "quadIn" | "cubicOut" | "cubicIn"

export type MovementLockFlag = "Walk" | "Sprint" | "Jump" | "Swim" | "All"

export type DirectionRef = "HumanoidRootPartLookFlat" | "HumanoidRootPartLook" | "HumanoidMoveDirection"

export type OriginRef = {
	ref: "BehindRootFlat",
	behindStuds: number,
}

export type WorldTargetRef = {
	ref: "InFrontOfRootFlat",
	forwardStuds: number,
}

export type WorldCenterRef = {
	ref: "HumanoidRootPartWorldPosition",
	offset: Vector3?,
}

export type TeleportTargetRef = {
	ref: "RootForwardFlat",
	forwardStuds: number,
	preserveCharacterYaw: boolean?,
}

export type MotionNone = {
	kind: "none",
}

export type MotionTranslate = {
	kind: "translate",
	direction: DirectionRef,
	distance: number,
	duration: number,
	accelerationMultiplier: number?,
}

export type MotionDash = {
	kind: "dash",
	direction: DirectionRef,
	distance: number,
	duration: number,
	easing: MotionEasingId?,
	accelerationMultiplier: number?,
}

export type MotionLunge = {
	kind: "lunge",
	direction: DirectionRef,
	distance: number?,
	duration: number?,
	accelerationMultiplier: number?,
}

export type MotionKnockback = {
	kind: "knockback",
	origin: OriginRef,
	distance: number,
	duration: number,
	arcAngleDegrees: number?,
	accelerationMultiplier: number?,
	decay: boolean?,
	easing: MotionEasingId?,
}

export type MotionPull = {
	kind: "pull",
	target: WorldTargetRef,
	speed: number,
	maxDuration: number,
	arrivalRadius: number?,
	accelerationMultiplier: number?,
}

export type MotionLaunch = {
	kind: "launch",
	height: number,
	accelerationMultiplier: number?,
}

export type MotionSlam = {
	kind: "slam",
	speed: number,
	maxDuration: number?,
	accelerationMultiplier: number?,
}

export type MotionFloat = {
	kind: "float",
	duration: number,
	accelerationMultiplier: number?,
	hoverHeightGain: number?,
	targetY: number?,
}

export type MotionSlide = {
	kind: "slide",
	direction: DirectionRef,
	speed: number,
	duration: number,
	friction: number?,
	groundRayLength: number?,
	accelerationMultiplier: number?,
}

export type MotionTeleport = {
	kind: "teleport",
	target: TeleportTargetRef,
	validatePath: boolean?,
	collisionGroup: string?,
}

export type MotionOrbit = {
	kind: "orbit",
	center: WorldCenterRef,
	radius: number,
	angularSpeed: number,
	duration: number,
	axis: Vector3?,
	startAngle: number?,
	accelerationMultiplier: number?,
}

export type MotionSpringTo = {
	kind: "springTo",
	target: WorldTargetRef,
	frequency: number?,
	damping: number?,
	maxDuration: number?,
	maxForce: number?,
	maxVelocity: number?,
	accelerationMultiplier: number?,
	applyAtCenterOfMass: boolean?,
}

export type WeaponBasicAttackMotionSpec =
	MotionNone
	| MotionTranslate
	| MotionDash
	| MotionLunge
	| MotionKnockback
	| MotionPull
	| MotionLaunch
	| MotionSlam
	| MotionFloat
	| MotionSlide
	| MotionTeleport
	| MotionOrbit
	| MotionSpringTo

export type WeaponBasicAttackProfile = {
	animationId: string,
	motion: WeaponBasicAttackMotionSpec,
	--- When true, root-motion step length tracks the resolved hit duration at runtime.
	syncMotionDurationFromHit: boolean?,
	hitboxStartTime: number?,
	hitboxEndTime: number?,
	comboTimeLimitMin: number?,
	comboTimeLimitMax: number?,
	movementLocks: { MovementLockFlag }?,
}

local BASIC_ATTACK_STEP: MotionTranslate = {
	kind = "translate",
	direction = "HumanoidRootPartLookFlat",
	distance = 2.25,
	duration = 0.2,
}

local LOCK_ALL: { MovementLockFlag } = { "All" }

local profiles: { [string]: WeaponBasicAttackProfile } = {
	["Dagger_Attack_01"] = {
		animationId = "rbxassetid://120794561550510",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 30 / 60,
		comboTimeLimitMin = 30 / 60,
		comboTimeLimitMax = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["Dagger_Attack_02"] = {
		animationId = "rbxassetid://96019133363181",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 30 / 60,
		comboTimeLimitMin = 30 / 60,
		comboTimeLimitMax = 40 / 60,
		movementLocks = LOCK_ALL,
	},
	["Axe_Attack_01"] = {
		animationId = "rbxassetid://107791038673413",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 28 / 60,
		comboTimeLimitMin = 28 / 60,
		comboTimeLimitMax = 43 / 60,
		movementLocks = LOCK_ALL,
	},
	["Axe_Attack_02"] = {
		animationId = "rbxassetid://75612209059589",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 28 / 60,
		comboTimeLimitMin = 28 / 60,
		comboTimeLimitMax = 43 / 60,
		movementLocks = LOCK_ALL,
	},
	["Axe_Attack_03"] = {
		animationId = "rbxassetid://82850857726878",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 45 / 60,
		comboTimeLimitMin = 45 / 60,
		comboTimeLimitMax = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Fists_Attack_01"] = {
		animationId = "rbxassetid://75340875929110",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 12 / 60,
		comboTimeLimitMin = 12 / 60,
		comboTimeLimitMax = 30 / 60,
		movementLocks = LOCK_ALL,
	},
	["Fists_Attack_02"] = {
		animationId = "rbxassetid://139690446894863",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 12 / 60,
		comboTimeLimitMin = 12 / 60,
		comboTimeLimitMax = 30 / 60,
		movementLocks = LOCK_ALL,
	},
	["Greatsword_Attack_01"] = {
		animationId = "rbxassetid://131503597112629",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 30 / 60,
		comboTimeLimitMin = 30 / 60,
		comboTimeLimitMax = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Greatsword_Attack_02"] = {
		animationId = "rbxassetid://76915436584618",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 30 / 60,
		comboTimeLimitMin = 30 / 60,
		comboTimeLimitMax = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Greatsword_Attack_03"] = {
		animationId = "rbxassetid://91378915906650",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 30 / 60,
		comboTimeLimitMin = 30 / 60,
		comboTimeLimitMax = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["ThrustingSword_Attack_01"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		movementLocks = LOCK_ALL,
	},
	["ThrustingSword_Attack_02"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		movementLocks = LOCK_ALL,
	},
	["Spear_Attack_01"] = {
		animationId = "rbxassetid://123819797815811",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 25 / 60,
		comboTimeLimitMin = 26 / 60,
		comboTimeLimitMax = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["Spear_Attack_02"] = {
		animationId = "rbxassetid://83639902733736",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 26 / 60,
		comboTimeLimitMin = 26 / 60,
		comboTimeLimitMax = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["Katana_Attack_01"] = {
		animationId = "rbxassetid://85750836456935",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 20 / 60,
		comboTimeLimitMin = 25 / 60,
		comboTimeLimitMax = 40 / 60,
		movementLocks = LOCK_ALL,
	},
	["Katana_Attack_02"] = {
		animationId = "rbxassetid://78686882887415",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 25 / 60,
		comboTimeLimitMin = 30 / 60,
		comboTimeLimitMax = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Quarterstaff_Attack_01"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 22 / 60,
		comboTimeLimitMin = 22 / 60,
		comboTimeLimitMax = 48 / 60,
		movementLocks = LOCK_ALL,
	},
	["Quarterstaff_Attack_02"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 24 / 60,
		comboTimeLimitMin = 24 / 60,
		comboTimeLimitMax = 52 / 60,
		movementLocks = LOCK_ALL,
	},
	["GreatSageQuarterstaff_Attack_01"] = {
		animationId = "rbxassetid://105352510281942",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 20 / 60,
		comboTimeLimitMin = 20 / 60,
		comboTimeLimitMax = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["GreatSageQuarterstaff_Attack_02"] = {
		animationId = "rbxassetid://71121279249417",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 25 / 60,
		comboTimeLimitMin = 25 / 60,
		comboTimeLimitMax = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["GreatSageQuarterstaff_Attack_03"] = {
		animationId = "rbxassetid://106474276062391",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitboxStartTime = 0,
		hitboxEndTime = 30 / 60,
		comboTimeLimitMin = 70 / 60,
		comboTimeLimitMax = 60 / 60,
		movementLocks = LOCK_ALL,
	},
}

local WeaponBasicAttackProfiles = {}

function WeaponBasicAttackProfiles.GetProfile(attackMotionId: string): WeaponBasicAttackProfile?
	if type(attackMotionId) ~= "string" or attackMotionId == "" then
		return nil
	end
	return profiles[attackMotionId]
end

function WeaponBasicAttackProfiles.GetAll(): { [string]: WeaponBasicAttackProfile }
	return profiles
end

return WeaponBasicAttackProfiles
