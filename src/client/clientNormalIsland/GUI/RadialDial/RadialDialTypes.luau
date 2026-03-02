--!strict
-- Type definitions for the generic RadialDial component.

-- Data for a single slot in the radial dial.
export type RadialSlotData = {
	-- Asset ID string (e.g. "rbxassetid://12345"). nil when slot is empty.
	iconId: string?,
	-- Shown in the center label when this slot is hovered.
	displayName: string,
	isEmpty: boolean,
}

-- Props accepted by the generic RadialDial component.
export type RadialDialProps = {
	-- All 8 slots must be present (1–8 indexed). Use isEmpty = true for unfilled slots.
	slots: { [number]: RadialSlotData },
	-- Which slot is currently highlighted by the mouse (1–8), or nil for none.
	highlightedIndex: number?,
	-- Controls visibility of the entire overlay.
	visible: boolean,
	-- Current camera viewport size for absolute positioning.
	viewportSize: Vector2,
}

return {}
