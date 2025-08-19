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

	-- Shell visuals
	shellType: string,                 -- Which shell prefab to use (see ShellType enum below)
}

-- Shell type enum (maps to ReplicatedStorage/Gun/BulletShells children)
local ShellType = {
	Normal = "NormalShell",
	Sniper = "SniperShell",
	Shotgun = "ShotgunShell",
	Rifle = "RifleShell",
}

local GunConfigs: {[string]: GunConfig} = {
	M9 = {
		auto = true,
		fireRate = 10,
		damage = 15,
		headshotMultiplier = 2.5,
		range = 300,
		bulletSpread = 1.5,
		bulletsPerShot = 1,
		playerSlowdown = 0.5,
		magazineCapacity = 100,
		reloadTime = 3,
		bulletSpeed = 300,
		shellEjectForce = 15,
		shellType = ShellType.Normal,
	},
	
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
		shellType = ShellType.Rifle,
	},
	
	MP220 = {
		auto = false,
		fireRate = 5,
		damage = 12.5,
		headshotMultiplier = 1.5,
		range = 100,
		bulletSpread = 10,
		bulletsPerShot = 9,
		playerSlowdown = 0.7,
		magazineCapacity = 6,
		reloadTime = 3,
		bulletSpeed = 250,
		shellEjectForce = 45,
		shellType = ShellType.Shotgun,
	},
}

return GunConfigs
