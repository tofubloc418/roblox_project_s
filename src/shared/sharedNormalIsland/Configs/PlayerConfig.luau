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
	jumpPower: number,
	maxHealth: number,
	humanoidRigType: string, -- "R15" | "R6"
	scale: PlayerScale,
	-- Camera/controls
	forceShiftLock: boolean,
	shiftLockZoom: number,
	shiftLockOffset: Vector3?,
	cameraFaceYawOffsetDeg: number,
}

local PlayerConfig: PlayerStats = {
	walkSpeed = 80,
	jumpPower = 100,
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
}

return PlayerConfig

