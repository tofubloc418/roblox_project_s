--!strict
-- PlaceholderUlt: server only validates + cooldown. Visuals run in client Scripts.

local AbilityStateRuntime = require(script.Parent.Parent:WaitForChild("AbilityStateRuntime"))

type ExecutionContext = AbilityStateRuntime.AbilityExecutionContextLike

local MAIN_TRACK = "main"
local MAIN_COOLDOWN_SECONDS = 2

local PlaceholderUlt = {}

function PlaceholderUlt.CanUse(player: Player, context: ExecutionContext): boolean
	return AbilityStateRuntime.IsAbilityReady(player, context.abilityId)
end

function PlaceholderUlt.Execute(player: Player, context: ExecutionContext): boolean
	AbilityStateRuntime.StartCooldown(player, context.abilityId, MAIN_TRACK, MAIN_COOLDOWN_SECONDS)
	return true
end

return PlaceholderUlt
