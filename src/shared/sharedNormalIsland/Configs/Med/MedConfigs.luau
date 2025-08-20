local MedEnums = {
	UsageMode = {
		Instant = "Instant",
		OverTime = "OverTime",
	},
}

local MedConfigs = {}

export type MedConfig = {
	useTime: number, -- seconds to channel before applying effect
	mode: string, -- MedEnums.UsageMode.Instant | MedEnums.UsageMode.OverTime
	healthAmount: number?, -- applied once for Instant
	hotDuration: number?, -- total duration for OverTime
	tickInterval: number?, -- seconds between ticks for OverTime
	healPerTick: number?, -- heal per tick for OverTime
	adrenalineDelta: number?, -- optional adrenaline change
	useWalkSpeed: number?, -- temporary WalkSpeed while using (nil = no change)
}

local function cfg(data: MedConfig): MedConfig
	return data
end

local configs: { [string]: MedConfig } = {
	Bandage = cfg({
		useTime = 3,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 20,
		useWalkSpeed = 8,
	}),

	Medkit = cfg({
		useTime = 5,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 75,
		useWalkSpeed = 6,
	}),

	Soda = cfg({
		useTime = 1.5,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 0,
		adrenalineDelta = 15,
		useWalkSpeed = 16,
	}),

	Pill = cfg({
		useTime = 1,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 0,
		adrenalineDelta = 10,
		useWalkSpeed = 16,
	}),
}

-- Expose enums on the same module table for consumers
configs.MedEnums = MedEnums

return configs


