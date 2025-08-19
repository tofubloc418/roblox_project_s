-- PlayerConfig
-- Default player movement/health stats applied on character spawn

export type PlayerStats = {
	walkSpeed: number,
	jumpPower: number,
	maxHealth: number,
}

local PlayerConfig: PlayerStats = {
	walkSpeed = 80,
	jumpPower = 100,
	maxHealth = 100,
}

return PlayerConfig


