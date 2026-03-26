--!strict

export type EasingId = "linear" | "quadOut" | "quadIn" | "cubicOut" | "cubicIn"

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
	arcAngleDegrees: number?, -- tilt away from horizontal (0 = flat, 45 = more upward)
	accelerationMultiplier: number?,
	decay: boolean?, -- if true, ease out to zero by end of duration
	easing: EasingId?, -- used when decay is true
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
	hoverHeightGain: number?, -- P gain when targetY is set (world studs error -> added vertical force scale)
	targetY: number?, -- optional vertical hold (uses hoverHeightGain)
}

export type SlideParams = {
	direction: Vector3,
	speed: number,
	duration: number,
	friction: number?, -- per-second decay factor (0-1), default 0.92
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
	collisionGroup: string?, -- if set, assigned to RaycastParams on ray (caller must configure collision groups)
}

export type OrbitParams = {
	center: Vector3,
	radius: number,
	angularSpeed: number, -- radians per second, positive = right-hand around axis
	duration: number,
	axis: Vector3?,
	startAngle: number?,
	accelerationMultiplier: number?,
}

export type SpringToParams = {
	target: Vector3,
	frequency: number?, -- AlignPosition.Responsiveness proxy, default 10
	damping: number?, -- MaxVelocity cap, default 40
	maxDuration: number?, -- max time before auto-complete
	maxForce: number?, -- AlignPosition force cap; if nil, derived from mass * accelerationMultiplier
	maxVelocity: number?,
	accelerationMultiplier: number?, -- used when maxForce is nil
	applyAtCenterOfMass: boolean?,
}

export type ShapecastPathParams = {
	exclude: { Instance }?,
	respectCanCollide: boolean?,
	collisionGroup: string?,
}

-- Internal mover handle (see Mover.luau)
export type MoverInternal = {
	destroy: (self: MoverInternal) -> (),
	cancelAll: (self: MoverInternal) -> (),
	getRoot: (self: MoverInternal) -> BasePart,
	getCharacter: (self: MoverInternal) -> Model,
	getCachedMass: (self: MoverInternal) -> number,
	acquireLinearVelocity: (self: MoverInternal, owner: any, vectorVelocity: Vector3, maxForce: number) -> (),
	releaseLinearVelocity: (self: MoverInternal, owner: any) -> (),
	acquireVectorForce: (self: MoverInternal, owner: any, force: Vector3) -> (),
	releaseVectorForce: (self: MoverInternal, owner: any) -> (),
	acquireAlignPosition: (
		self: MoverInternal,
		owner: any,
		targetWorldPosition: Vector3,
		maxForce: number,
		maxVelocity: number,
		responsiveness: number,
		applyAtCenterOfMass: boolean
	) -> (),
	releaseAlignPosition: (self: MoverInternal, owner: any) -> (),
	registerFrameUpdate: (self: MoverInternal, owner: any, fn: (dt: number) -> ()) -> (),
	unregisterFrameUpdate: (self: MoverInternal, owner: any) -> (),
	trackActive: (self: MoverInternal, token: any) -> (),
	untrackActive: (self: MoverInternal, token: any) -> (),
}

export type ActiveMovement = {
	Cancel: (self: ActiveMovement) -> (),
	IsActive: (self: ActiveMovement) -> boolean,
	Completed: {
		Connect: (self: any, cb: (didComplete: boolean) -> ()) -> { Disconnect: () -> () },
	},
}

return {}
