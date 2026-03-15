--!strict
-- Cmdr type: remove slot (equipment names + numeric 1–20).

local EQUIPMENT_SLOTS = { "Backpack", "Armor", "Weapon1", "Weapon2" }

local removeSlotType = {
	Validate = function(value: string): (boolean, string?)
		if type(value) ~= "string" or value == "" then
			return false, "Slot is required."
		end
		return true
	end,

	Parse = function(value: string): string
		return (value and value:gsub("^%s+", ""):gsub("%s+$", "")) or ""
	end,

	Autocomplete = function(): { string }
		local out: { string } = table.clone(EQUIPMENT_SLOTS)
		for i = 1, 20 do
			out[i + #EQUIPMENT_SLOTS] = tostring(i)
		end
		return out
	end,
}

return function(registry)
	registry:RegisterType("removeSlot", removeSlotType)
end
