-- PlayerConfig
-- Default player movement/health stats applied on character spawn

export type PlayerStats = {
	walkSpeed: number,
	jumpPower: number,
	maxHealth: number,
}

local PlayerConfig: PlayerStats = {
	walkSpeed = 16, -- Roblox default
	jumpPower = 50, -- Roblox default
	maxHealth = 100,
}

return PlayerConfig


