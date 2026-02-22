local MedEnums = {
	UsageMode = {
		Instant = "Instant",
		OverTime = "OverTime",
	},
}

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

local Items: { [string]: MedConfig } = {
	Bandage = cfg({
		useTime = 3,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 15,
		useWalkSpeed = 10,
	}),

	Medkit = cfg({
		useTime = 6,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 100,
		useWalkSpeed = 10,
	}),

	Soda = cfg({
		useTime = 1.5,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 0,
		adrenalineDelta = 25,
		useWalkSpeed = 10,
	}),

	Pill = cfg({
		useTime = 1,
		mode = MedEnums.UsageMode.Instant,
		healthAmount = 0,
		adrenalineDelta = 50,
		useWalkSpeed = 10,
	}),
}

local Module = {
	Items = Items,
	MedEnums = MedEnums,
	-- Global adrenaline-based healing/leak settings
	AdrenalineHealPerSecondBase = 1,
	AdrenalineLeakPerSecond = 1,
	AdrenalineThresholdMid = 50,
	AdrenalineThresholdHigh = 75,
	AdrenalineMidMultiplier = 1.5,
	AdrenalineHighMultiplier = 2,
}

return Module


