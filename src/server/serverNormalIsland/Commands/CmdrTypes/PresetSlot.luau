--!strict
-- Cmdr type: ability preset slot index 1–5.

local presetSlotType = {
	Transform = function(text: string): number?
		return tonumber(text)
	end,

	Validate = function(value: number?): (boolean, string?)
		if value == nil or value ~= math.floor(value) or value < 1 or value > 5 then
			return false, "Slot must be an integer from 1 to 5."
		end
		return true
	end,

	Parse = function(value: number): number
		return value
	end,

	Autocomplete = function(): { string }
		return { "1", "2", "3", "4", "5" }
	end,
}

return function(registry)
	registry:RegisterType("presetSlot", presetSlotType)
end
