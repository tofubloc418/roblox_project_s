--!strict
-- Cmdr type: remove container (backpack → inventory internally).

local CONTAINERS = { backpack = true, equipment = true, quickuse = true, stash = true }

local function trim(s: string): string
	return s:lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local removeContainerType = {
	Validate = function(value: string): (boolean, string?)
		if type(value) ~= "string" or value == "" then
			return false, "Container is required."
		end
		if not CONTAINERS[trim(value)] then
			return false, "Use: backpack, equipment, quickuse, or stash."
		end
		return true
	end,

	Parse = function(value: string): string
		local key = trim(value)
		return if key == "backpack" then "inventory" else key
	end,

	Autocomplete = function(): { string }
		return { "backpack", "equipment", "quickuse", "stash" }
	end,
}

return function(registry)
	registry:RegisterType("removeContainer", removeContainerType)
end
