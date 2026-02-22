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
	staminaSwimHealthDrainPerSecond: number,
	jumpStaminaCost: number,
	-- Adrenaline
	baseMaxAdrenaline: number,
	-- Fall damage
	fallDamageMinSpeed: number, -- velocity magnitude to start taking damage
	fallDamageMaxSpeed: number, -- velocity magnitude that maps to max damage
	fallDamageMaxPercent: number, -- percent of MaxHealth dealt at/above max speed (0..1)
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
	staminaSwimHealthDrainPerSecond = 5,
	jumpStaminaCost = 20,
	baseMaxAdrenaline = 100,
	fallDamageMinSpeed = 50,
	fallDamageMaxSpeed = 120,
	fallDamageMaxPercent = 0.7,
}

return PlayerConfig

