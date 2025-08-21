-- MeleeConfigs

export type MeleeConfig = {
	-- Input
	auto: boolean,
	cooldownSeconds: number,

	-- Damage
	damage: number,

	-- Hit area (relative to HumanoidRootPart)
	hitShape: string, -- "Box" | "Sphere"
	hitSize: Vector3?, -- for Box
	hitRadius: number?, -- for Sphere
	hitOffset: Vector3, -- forward/up/right from HRP
	yawDegrees: number?, -- rotate around vertical

	-- Animations
	animations: { Equip: string?, Unequip: string? }?,
	attackSequence: { string },
}

local function cfg(data: MeleeConfig): MeleeConfig
	return data
end

local MeleeConfigs: { [string]: MeleeConfig } = {
	Fists = cfg({
		auto = false,
		cooldownSeconds = 0.5,
		damage = 24,
		hitShape = "Box",
		hitSize = Vector3.new(5, 4, 5),
		hitOffset = Vector3.new(0, 0, -3),
		yawDegrees = 0,
		animations = nil,
		attackSequence = { "Attack1" },
	}),

	Knife = cfg({
		auto = false,
		cooldownSeconds = 0.6,
		damage = 35,
		hitShape = "Box",
		hitSize = Vector3.new(6, 4, 6),
		hitOffset = Vector3.new(0, 0, -3.5),
		yawDegrees = 0,
		animations = { Equip = "Equip", Unequip = "Unequip" },
		attackSequence = { "Attack" },
	}),

	Bat = cfg({
		auto = true,
		cooldownSeconds = 0.8,
		damage = 45,
		hitShape = "Box",
		hitSize = Vector3.new(7, 5, 7),
		hitOffset = Vector3.new(0, 0, -4),
		yawDegrees = 20,
		animations = { Equip = "Equip", Unequip = "Unequip" },
		attackSequence = { "Attack1", "Attack2" },
	}),
}

return MeleeConfigs


