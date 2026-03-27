--!strict

export type EasingId = "linear" | "quadOut" | "quadIn" | "cubicOut" | "cubicIn"

export type CreateMoverOptions = {
	--- Default true. If false, Humanoid walk/jump and core locomotion states stay untouched.
	suppressDefaultLocomotion: boolean?,
}

export type TranslateParams = {
	direction: Vector3,
	distance: number,
	duration: number,
	accelerationMultiplier: number?,
}

export type DashParams = {
	direction: Vector3,
	distance: number,
	duration: number,
	easing: EasingId?,
	accelerationMultiplier: number?,
}

export type KnockbackParams = {
	origin: Vector3,
	distance: number,
	duration: number,
	arcAngleDegrees: number?,
	accelerationMultiplier: number?,
	decay: boolean?,
	easing: EasingId?,
}

export type PullParams = {
	target: Vector3,
	speed: number,
	maxDuration: number,
	arrivalRadius: number?,
	accelerationMultiplier: number?,
}

export type LaunchParams = {
	height: number,
	accelerationMultiplier: number?,
}

export type SlamParams = {
	speed: number,
	maxDuration: number?,
	accelerationMultiplier: number?,
}

export type FloatParams = {
	duration: number,
	accelerationMultiplier: number?,
	hoverHeightGain: number?,
	targetY: number?,
}

export type SlideParams = {
	direction: Vector3,
	speed: number,
	duration: number,
	friction: number?,
	groundRayLength: number?,
	accelerationMultiplier: number?,
}

export type LungeParams = {
	direction: Vector3,
	distance: number?,
	duration: number?,
	accelerationMultiplier: number?,
}

export type TeleportParams = {
	target: CFrame,
	validatePath: boolean?,
	collisionGroup: string?,
}

export type OrbitParams = {
	center: Vector3,
	radius: number,
	angularSpeed: number,
	duration: number,
	axis: Vector3?,
	startAngle: number?,
	accelerationMultiplier: number?,
}

export type SpringToParams = {
	target: Vector3,
	frequency: number?,
	damping: number?,
	maxDuration: number?,
	maxForce: number?,
	maxVelocity: number?,
	accelerationMultiplier: number?,
	applyAtCenterOfMass: boolean?,
}

export type ShapecastPathParams = {
	exclude: { Instance }?,
	respectCanCollide: boolean?,
	collisionGroup: string?,
}

return {}
