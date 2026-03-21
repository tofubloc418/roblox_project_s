--!strict
-- Cmdr type: registered ability ID with autocomplete.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))

local abilityIdType = {
	Validate = function(value: string): (boolean, string?)
		if type(value) ~= "string" or value == "" then
			return false, "Ability ID is required."
		end
		if not AbilityRegistry.GetAbility(value) then
			return false, ("'%s' is not a registered ability."):format(value)
		end
		return true
	end,

	Parse = function(value: string): string
		return value
	end,

	Autocomplete = function(): { string }
		return AbilityRegistry.GetAllAbilityIds()
	end,
}

return function(registry)
	registry:RegisterType("abilityId", abilityIdType)
end
