--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signal")) :: any

export type MovementType = "Walk" | "Sprint" | "Jump" | "Swim"
export type LockFlag = MovementType | "All"
export type LockedFlags = {
	Walk: boolean,
	Sprint: boolean,
	Jump: boolean,
	Swim: boolean,
}

type LockEntry = {
	flags: LockedFlags,
}

local MOVEMENT_TYPES: { MovementType } = {
	"Walk",
	"Sprint",
	"Jump",
	"Swim",
}

local VALID_MOVEMENT_TYPES: { [string]: boolean } = {
	Walk = true,
	Sprint = true,
	Jump = true,
	Swim = true,
	All = true,
}

local function newLockedFlags(): LockedFlags
	return {
		Walk = false,
		Sprint = false,
		Jump = false,
		Swim = false,
	}
end

local function cloneLockedFlags(flags: LockedFlags): LockedFlags
	return {
		Walk = flags.Walk == true,
		Sprint = flags.Sprint == true,
		Jump = flags.Jump == true,
		Swim = flags.Swim == true,
	}
end

local function lockedFlagsEqual(a: LockedFlags, b: LockedFlags): boolean
	for _, movementType in ipairs(MOVEMENT_TYPES) do
		if a[movementType] ~= b[movementType] then
			return false
		end
	end
	return true
end

local function lockedFlagsToArray(flags: LockedFlags): { MovementType }
	local result: { MovementType } = {}
	for _, movementType in ipairs(MOVEMENT_TYPES) do
		if flags[movementType] then
			table.insert(result, movementType)
		end
	end
	return result
end

local function normalizeFlags(flags: { LockFlag }): LockedFlags
	local normalized = newLockedFlags()

	for _, rawFlag in pairs(flags) do
		if type(rawFlag) == "string" and VALID_MOVEMENT_TYPES[rawFlag] then
			if rawFlag == "All" then
				for _, movementType in ipairs(MOVEMENT_TYPES) do
					normalized[movementType] = true
				end
			else
				normalized[rawFlag :: MovementType] = true
			end
		end
	end

	return normalized
end

local _locks: { [string]: LockEntry } = {}
local _lastLockedFlags = newLockedFlags()

local MovementLock = {
	Changed = Signal.new(),
	LockAdded = Signal.new(),
	LockRemoved = Signal.new(),
}

local function getAggregateLockedFlags(): LockedFlags
	local aggregate = newLockedFlags()

	for _, entry in pairs(_locks) do
		for _, movementType in ipairs(MOVEMENT_TYPES) do
			if entry.flags[movementType] then
				aggregate[movementType] = true
			end
		end
	end

	return aggregate
end

local function emitIfChanged()
	local nextLockedFlags = getAggregateLockedFlags()
	if lockedFlagsEqual(nextLockedFlags, _lastLockedFlags) then
		return
	end

	_lastLockedFlags = nextLockedFlags
	MovementLock.Changed:Fire(cloneLockedFlags(nextLockedFlags))
end

function MovementLock.IsLocked(flag: MovementType): boolean
	return _lastLockedFlags[flag] == true
end

function MovementLock.GetLockedFlags(): LockedFlags
	return cloneLockedFlags(_lastLockedFlags)
end

function MovementLock.GetActiveLocks(): { [string]: { MovementType } }
	local snapshot: { [string]: { MovementType } } = {}

	for tag, entry in pairs(_locks) do
		snapshot[tag] = lockedFlagsToArray(entry.flags)
	end

	return snapshot
end

function MovementLock.Lock(tag: string, flags: { LockFlag }, duration: number?)
	assert(type(tag) == "string" and #tag > 0, "MovementLock.Lock: tag must be a non-empty string")
	assert(type(flags) == "table", "MovementLock.Lock: flags must be a table")

	local normalizedFlags = normalizeFlags(flags)

	local entry: LockEntry = {
		flags = normalizedFlags,
	}
	_locks[tag] = entry

	if type(duration) == "number" and duration > 0 then
		task.delay(duration, function()
			if _locks[tag] == entry then
				MovementLock.Unlock(tag)
			end
		end)
	end

	MovementLock.LockAdded:Fire(tag, lockedFlagsToArray(normalizedFlags))
	emitIfChanged()
end

function MovementLock.Unlock(tag: string)
	local entry = _locks[tag]
	if not entry then
		return
	end

	_locks[tag] = nil
	MovementLock.LockRemoved:Fire(tag, lockedFlagsToArray(entry.flags))
	emitIfChanged()
end

return table.freeze(MovementLock)
