--!strict
-- PlaceholderSlash: example server ability script.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))
local AbilityExecutionService = require(script.Parent.Parent:WaitForChild("AbilityExecutionService"))
local DamageService = require(script.Parent.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))

type AbilityExecutionContext = AbilityExecutionService.AbilityExecutionContext

local PlaceholderSlash = {}

function PlaceholderSlash.Execute(player: Player, context: AbilityExecutionContext): boolean
	local scaling = AbilityRegistry.GetDamageScaling(context.abilityId)
	local weaponTemplateId = context.weaponTemplateId
	if not weaponTemplateId then
		return true
	end

	return true
end

return PlaceholderSlash
