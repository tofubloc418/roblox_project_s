--!strict
-- PlaceholderSlash: client script for animation/VFX when the ability starts.

-- Context shape passed by AbilityExecutionController (no shared module require).
type AbilityClientContext = {
	player: Player,
	character: Model,
	abilityId: string,
	slotIndex: number,
	animator: Animator?,
}

local PlaceholderSlash = {}

function PlaceholderSlash.OnStarted(context: AbilityClientContext)
	local _animator = context.animator
end

return PlaceholderSlash
