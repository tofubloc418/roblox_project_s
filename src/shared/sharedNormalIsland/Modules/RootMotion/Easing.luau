--!strict

local function linear(t: number): number
	return t
end

local function quadOut(t: number): number
	return 1 - (1 - t) * (1 - t)
end

local function quadIn(t: number): number
	return t * t
end

local function cubicOut(t: number): number
	local u = 1 - t
	return 1 - u * u * u
end

local function cubicIn(t: number): number
	return t * t * t
end

local registry: { [string]: (number) -> number } = {
	linear = linear,
	quadOut = quadOut,
	quadIn = quadIn,
	cubicOut = cubicOut,
	cubicIn = cubicIn,
}

local function byId(id: string?): (number) -> number
	if not id then
		return linear
	end
	return registry[id] or linear
end

return {
	byId = byId,
}
