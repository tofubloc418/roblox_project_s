--!strict
-- Server: cooldown only. Client VFX in client Abilities/Scripts/PlaceholderSlash.

local AbilityStateRuntime = require(script.Parent.Parent:WaitForChild("AbilityStateRuntime"))

type ExecutionContext = AbilityStateRuntime.AbilityExecutionContextLike

local MAIN_TRACK = "main"
local MAIN_COOLDOWN_SECONDS = 2

local PlaceholderSlash = {}

function PlaceholderSlash.CanUse(player: Player, context: ExecutionContext): boolean
	return AbilityStateRuntime.IsAbilityReady(player, context.abilityId)
end

function PlaceholderSlash.Execute(player: Player, context: ExecutionContext): boolean
	AbilityStateRuntime.StartCooldown(player, context.abilityId, MAIN_TRACK, MAIN_COOLDOWN_SECONDS)
	return true
end

return PlaceholderSlash
