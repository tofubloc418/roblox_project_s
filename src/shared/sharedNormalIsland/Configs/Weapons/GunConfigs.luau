export type GunConfig = {
	-- Firing mode
	mode: string,                      -- "Single" | "Auto" | "Burst"
	shotDelay: number,                 -- Seconds between trigger pulls (or between shots in Auto)
	burstDelay: number?,               -- Seconds between shots within a burst (Burst only)
	burstCount: number?,               -- Shots per burst (Burst only)

	-- Damage / reach
	damage: number,
	headshotMultiplier: number,
	range: number,

	-- Ammo
	ammoType: string,                  -- See AmmoTypes enum below
	
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

-- Ammo type enum aligned with Surviv.io
-- Reference: Surviv.io Ammunition types ([surviv.io wiki](https://survivio.fandom.com/wiki/Ammunition))
local AmmoTypes = {
	NINE_MM = "9mm",
	FIVE_FIVE_SIX_MM = "5.56mm",
	SEVEN_SIX_TWO_MM = "7.62mm",
	TWELVE_GAUGE = "12 Gauge",
	FIFTY_AE = ".50 AE",
	THREE_ZERO_EIGHT_SUBSONIC = ".308 Subsonic",
	FORTY_FIVE_ACP = ".45 ACP",
}

local GunConfigs: {[string]: GunConfig} = {
	M9 = {
		mode = "Burst",
		shotDelay = 0.35,
		burstDelay = 0.06,
		burstCount = 3,
		damage = 15,
		headshotMultiplier = 2.5,
		range = 300,
		ammoType = AmmoTypes.NINE_MM,
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
		mode = "Auto",
		shotDelay = 0.1,
		damage = 25,
		headshotMultiplier = 2,
		range = 400,
		ammoType = AmmoTypes.SEVEN_SIX_TWO_MM,
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
		mode = "Single",
		shotDelay = 0.2,
		damage = 12.5,
		headshotMultiplier = 1.5,
		range = 100,
		ammoType = AmmoTypes.TWELVE_GAUGE,
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
