--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signal")) :: any

export type Entry = {
	multiplier: number,
}

local DEFAULT_MULTIPLIER = 1

local _entries: { [string]: Entry } = {}
local _currentMultiplier = DEFAULT_MULTIPLIER

local MovementSpeedMultipliers = {
	Changed = Signal.new(),
}

local function computeMultiplier(): number
	local nextMultiplier = DEFAULT_MULTIPLIER
	for _, entry in pairs(_entries) do
		if entry.multiplier < nextMultiplier then
			nextMultiplier = entry.multiplier
		end
	end
	return nextMultiplier
end

local function emitIfChanged()
	local nextMultiplier = computeMultiplier()
	if nextMultiplier == _currentMultiplier then
		return
	end

	_currentMultiplier = nextMultiplier
	MovementSpeedMultipliers.Changed:Fire(nextMultiplier)
end

function MovementSpeedMultipliers.Set(tag: string, multiplier: number, duration: number?)
	assert(type(tag) == "string" and #tag > 0, "MovementSpeedMultipliers.Set: tag must be a non-empty string")
	assert(type(multiplier) == "number", "MovementSpeedMultipliers.Set: multiplier must be a number")

	local entry: Entry = {
		multiplier = math.max(0, multiplier),
	}
	_entries[tag] = entry

	if type(duration) == "number" and duration > 0 then
		task.delay(duration, function()
			if _entries[tag] == entry then
				MovementSpeedMultipliers.Clear(tag)
			end
		end)
	end

	emitIfChanged()
end

function MovementSpeedMultipliers.Clear(tag: string)
	if _entries[tag] == nil then
		return
	end

	_entries[tag] = nil
	emitIfChanged()
end

function MovementSpeedMultipliers.GetMultiplier(): number
	return _currentMultiplier
end

function MovementSpeedMultipliers.GetActive(): { [string]: number }
	local snapshot: { [string]: number } = {}
	for tag, entry in pairs(_entries) do
		snapshot[tag] = entry.multiplier
	end
	return snapshot
end

return table.freeze(MovementSpeedMultipliers)
