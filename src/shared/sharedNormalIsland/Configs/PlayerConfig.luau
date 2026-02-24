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
		height = 1.5,
		width = 1.5,
		depth = 1.5,
		head = 1.5,
	},
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

