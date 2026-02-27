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
	-- Stamina
	baseMaxStamina: number,
	staminaRegenPerSecond: number,
	staminaRunDrainPerSecond: number,
	staminaSwimDrainPerSecond: number,
	staminaSwimHealthDrainPerSecond: number,
	jumpStaminaCost: number,
	-- Adrenaline
	baseMaxAdrenaline: number,
	-- Fall damage (damage per stud beyond threshold, capped)
	fallDamageMinHeight: number, -- studs fallen before damage starts
	fallDamagePerStud: number, -- damage per stud beyond threshold
	fallDamageCap: number, -- max damage
}

local PlayerConfig: PlayerStats = {
	walkSpeed = 14,
	runSpeed = 50,
	jumpPower = 50,
	maxHealth = 100,
	humanoidRigType = "R15",
	scale = {
		height = 1.0,
		width = 1.0,
		depth = 1.0,
		head = 1.0,
	},
	baseMaxStamina = 100,
	staminaRegenPerSecond = 12,
	staminaRunDrainPerSecond = 7.5,
	staminaSwimDrainPerSecond = 15,
	staminaSwimHealthDrainPerSecond = 5,
	jumpStaminaCost = 5,
	baseMaxAdrenaline = 100,
	fallDamageMinHeight = 4,
	fallDamagePerStud = 6.25,
	fallDamageCap = 100,
}

return PlayerConfig

