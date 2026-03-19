--!strict
-- Resolves abilityId to icon and display name via AbilityRegistry.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))

local AbilityIconResolver = {}

-- Returns (iconId, displayName) for a given abilityId. iconId may be nil/empty; callers show displayName as fallback.
function AbilityIconResolver.getIconForAbility(abilityId: string): (string?, string?)
	local config = AbilityRegistry.GetAbility(abilityId)
	if not config then
		return nil, abilityId
	end
	local displayName = config.displayName or config.abilityId
	local iconId = config.iconId
	if iconId == nil or iconId == "" or iconId == "rbxassetid://0" then
		return nil, displayName
	end
	return iconId, displayName
end

return AbilityIconResolver
