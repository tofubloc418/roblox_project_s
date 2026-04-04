--!strict
-- Shared library: basic attack profile id → animation + hit timing + movement locks + RootMotion motion spec.
-- Consumed by client WeaponController + WeaponAttackRootMotion; server WeaponService (cooldown). Do not duplicate on weapon entries.
-- Idle / equip / unequip / block: WeaponStanceAnimationProfiles.luau (idleMotionId, … on templates).

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
	--- When true, motion duration-like fields are overridden by this profile's hitDuration when running the attack.
	syncMotionDurationFromHit: boolean?,
	hitDuration: number,
	--- If nil, combo expiry uses hitDuration (see WeaponController).
	comboTimeLimit: number?,
	movementLocks: { MovementLockFlag }?,
}

-- Small in-place step along flat look (≈ one foot forward while swinging). Duration follows hit window when sync is on.
local BASIC_ATTACK_STEP: MotionTranslate = {
	kind = "translate",
	direction = "HumanoidRootPartLookFlat",
	distance = 2.25,
	duration = 0.2,
}

local LOCK_ALL: { MovementLockFlag } = { "All" }

-- Keys: <WeaponTag>_Attack_<NN> (NN = 01, 02, …) — aligns with ItemEnums.WeaponTag for shared basic attacks.
local profiles: { [string]: WeaponBasicAttackProfile } = {
	["Dagger_Attack_01"] = {
		animationId = "rbxassetid://120794561550510",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 30 / 60,
		comboTimeLimit = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["Dagger_Attack_02"] = {
		animationId = "rbxassetid://96019133363181",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 30 / 60,
		comboTimeLimit = 40 / 60,
		movementLocks = LOCK_ALL,
	},
	["Axe_Attack_01"] = {
		animationId = "rbxassetid://107791038673413",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 28 / 60,
		comboTimeLimit = 43 / 60,
		movementLocks = LOCK_ALL,
	},
	["Axe_Attack_02"] = {
		animationId = "rbxassetid://75612209059589",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 28 / 60,
		comboTimeLimit = 43 / 60,
		movementLocks = LOCK_ALL,
	},
	["Axe_Attack_03"] = {
		animationId = "rbxassetid://82850857726878",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 45 / 60,
		comboTimeLimit = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Fists_Attack_01"] = {
		animationId = "rbxassetid://75340875929110",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 12 / 60,
		comboTimeLimit = 30 / 60,
		movementLocks = LOCK_ALL,
	},
	["Fists_Attack_02"] = {
		animationId = "rbxassetid://139690446894863",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 12 / 60,
		comboTimeLimit = 30 / 60,
		movementLocks = LOCK_ALL,
	},
	["Greatsword_Attack_01"] = {
		animationId = "rbxassetid://131503597112629",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 30 / 60,
		comboTimeLimit = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Greatsword_Attack_02"] = {
		animationId = "rbxassetid://76915436584618",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 30 / 60,
		comboTimeLimit = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Greatsword_Attack_03"] = {
		animationId = "rbxassetid://91378915906650",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 30 / 60,
		comboTimeLimit = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["ThrustingSword_Attack_01"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 0.2,
	},
	["ThrustingSword_Attack_02"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 0.2,
	},
	["Spear_Attack_01"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 26 / 60,
		comboTimeLimit = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["Spear_Attack_02"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 26 / 60,
		comboTimeLimit = 50 / 60,
		movementLocks = LOCK_ALL,
	},
	["Katana_Attack_01"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 24 / 60,
		comboTimeLimit = 52 / 60,
		movementLocks = LOCK_ALL,
	},
	["Katana_Attack_02"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 24 / 60,
		comboTimeLimit = 52 / 60,
		movementLocks = LOCK_ALL,
	},
	["Katana_Attack_03"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 32 / 60,
		comboTimeLimit = 60 / 60,
		movementLocks = LOCK_ALL,
	},
	["Quarterstaff_Attack_01"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 22 / 60,
		comboTimeLimit = 48 / 60,
		movementLocks = LOCK_ALL,
	},
	["Quarterstaff_Attack_02"] = {
		animationId = "rbxassetid://0",
		motion = BASIC_ATTACK_STEP,
		syncMotionDurationFromHit = true,
		hitDuration = 24 / 60,
		comboTimeLimit = 52 / 60,
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
