export type GunConfig = {
	-- Shooting mechanics
	auto: boolean,                    -- Full auto or semi-auto
	fireRate: number,                  -- Rounds per second
	damage: number,                    -- Base damage per bullet
	headshotMultiplier: number,        -- Headshot damage multiplier
	range: number,                     -- Max range in studs
	
	-- Spread and accuracy
	bulletSpread: number,              -- Spread angle in degrees
	bulletsPerShot: number,            -- Number of bullets per shot (1 for most guns, multiple for shotguns)
	
	-- Movement
	playerSlowdown: number,            -- Speed multiplier while shooting (0.9 = 90% speed)
	
	-- Magazine
	magazineCapacity: number,          -- Rounds per magazine
	reloadTime: number,                -- Time to reload in seconds
	
	-- Visual/Audio
	bulletSpeed: number,               -- Visual bullet travel speed
	shellEjectForce: number,           -- Shell ejection velocity
}

local GunConfigs: {[string]: GunConfig} = {
	M9 = {
		auto = false,
		fireRate = 4,  -- 4 shots per second
		damage = 15,
		headshotMultiplier = 2.5,
		range = 300,
		bulletSpread = 1,
		bulletsPerShot = 1,
		playerSlowdown = 0.95,
		magazineCapacity = 8,
		reloadTime = 1.5,
		bulletSpeed = 300,
		shellEjectForce = 35,
	},
	
	-- Example configs for future weapons
	AK47 = {
		auto = true,
		fireRate = 10,
		damage = 25,
		headshotMultiplier = 2,
		range = 400,
		bulletSpread = 2.5,
		bulletsPerShot = 1,
		playerSlowdown = 0.8,
		magazineCapacity = 30,
		reloadTime = 2.5,
		bulletSpeed = 350,
		shellEjectForce = 40,
	},
	
	Shotgun = {
		auto = false,
		fireRate = 1,
		damage = 12,  -- Per pellet
		headshotMultiplier = 1.5,
		range = 100,
		bulletSpread = 8,
		bulletsPerShot = 8,  -- 8 pellets
		playerSlowdown = 0.7,
		magazineCapacity = 6,
		reloadTime = 3,
		bulletSpeed = 250,
		shellEjectForce = 45,
	},
}

return GunConfigs
