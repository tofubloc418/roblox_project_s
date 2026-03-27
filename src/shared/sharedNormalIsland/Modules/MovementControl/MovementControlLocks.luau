--!strict

local MovementLock = require(script.Parent:WaitForChild("MovementLock")) :: any
local MovementSpeedMultipliers = require(script.Parent:WaitForChild("MovementSpeedMultipliers")) :: any

export type MovementFlag = "Walk" | "Sprint" | "Jump" | "Swim" | "All"

local MovementControlLocks = {}

local function collectState(flags: { MovementFlag }): ({ "Sprint" | "Jump" | "Swim" }, boolean)
	local stateFlags: { "Sprint" | "Jump" | "Swim" } = {}
	local appliesWalkMultiplier = false

	for _, rawFlag in pairs(flags) do
		if rawFlag == "All" then
			appliesWalkMultiplier = true
			table.insert(stateFlags, "Sprint")
			table.insert(stateFlags, "Jump")
			table.insert(stateFlags, "Swim")
		elseif rawFlag == "Walk" then
			appliesWalkMultiplier = true
		elseif rawFlag == "Sprint" or rawFlag == "Jump" or rawFlag == "Swim" then
			table.insert(stateFlags, rawFlag)
		end
	end

	return stateFlags, appliesWalkMultiplier
end

function MovementControlLocks.Lock(tag: string, flags: { MovementFlag }, duration: number?, walkMultiplier: number?)
	assert(type(tag) == "string" and #tag > 0, "MovementControlLocks.Lock: tag must be a non-empty string")
	assert(type(flags) == "table", "MovementControlLocks.Lock: flags must be a table")

	local stateFlags, appliesWalkMultiplier = collectState(flags)
	if appliesWalkMultiplier then
		MovementSpeedMultipliers.Set(tag, if type(walkMultiplier) == "number" then walkMultiplier else 0, duration)
	else
		MovementSpeedMultipliers.Clear(tag)
	end
	if #stateFlags > 0 then
		MovementLock.Lock(tag, stateFlags, duration)
	else
		MovementLock.Unlock(tag)
	end
end

function MovementControlLocks.Unlock(tag: string)
	MovementSpeedMultipliers.Clear(tag)
	MovementLock.Unlock(tag)
end

function MovementControlLocks.SetWalkMultiplier(tag: string, multiplier: number, duration: number?)
	MovementSpeedMultipliers.Set(tag, multiplier, duration)
end

function MovementControlLocks.ClearWalkMultiplier(tag: string)
	MovementSpeedMultipliers.Clear(tag)
end

return table.freeze(MovementControlLocks)
