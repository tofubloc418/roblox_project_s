-- PlayerConfig
-- Default player movement/health stats applied on character spawn

export type PlayerScale = {
	height: number,
	width: number,
	depth: number,
	head: number,
}

export type PlayerStats = {
	walkSpeed: number,
	runSpeed: number,
	jumpPower: number,
	maxHealth: number,
	humanoidRigType: string, -- "R15" | "R6"
	scale: PlayerScale,
	-- Camera/controls
	forceShiftLock: boolean,
	shiftLockZoom: number,
	shiftLockOffset: Vector3?,
	cameraFaceYawOffsetDeg: number,
	-- Stamina
	baseMaxStamina: number,
	staminaRegenPerSecond: number,
	staminaRunDrainPerSecond: number,
	staminaSwimDrainPerSecond: number,
	jumpStaminaCost: number,
}

local PlayerConfig: PlayerStats = {
	walkSpeed = 14,
	runSpeed = 50,
	jumpPower = 50,
	maxHealth = 100,
	humanoidRigType = "R15",
	scale = {
		height = 1,
		width = 1,
		depth = 1,
		head = 1,
	},
	forceShiftLock = false,
	shiftLockZoom = 12,
	shiftLockOffset = Vector3.new(5, 0.2, 0),
	cameraFaceYawOffsetDeg = -30,
	baseMaxStamina = 100,
	staminaRegenPerSecond = 12,
	staminaRunDrainPerSecond = 15,
	staminaSwimDrainPerSecond = 15,
	jumpStaminaCost = 20,
}

return PlayerConfig

