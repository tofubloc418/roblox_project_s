--!strict
-- Cmdr type: weapon tag / preset key (autocomplete = AbilityRegistry compatible tags only).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))

local weaponTagType = {
	Validate = function(value: string): (boolean, string?)
		if type(value) ~= "string" or value == "" then
			return false, "Weapon tag (preset key) is required."
		end
		return true
	end,

	Parse = function(value: string): string
		return value
	end,

	Autocomplete = function(): { string }
		return AbilityRegistry.GetAllCompatibleTags()
	end,
}

return function(registry)
	registry:RegisterType("weaponTag", weaponTagType)
end
