--!strict
-- Structural and positional constants for the Loadout GUI.
-- Visual/theme values (colors, fonts, corner radii, padding) live in ThemeConfig.

local LayoutConfig = {}

--[[
	VIEWPORT
]]
-- Fallback viewport size when the actual camera size is unavailable
LayoutConfig.DefaultViewportSize = Vector2.new(1920, 1080)

--[[
	UNIFIED CONTAINER
	The main loadout frame (holds the title + all 3 columns).
	Anchored to the right edge, centered vertically.
	VerticalMarginScale: distance from top/bottom of screen (equal both sides).
	Smaller value = frame is taller = more room for content.
]]
LayoutConfig.Container = {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(0.95, 0.5),
	VerticalMarginScale = 0.10, -- 10% from top and bottom
}

--[[
	ZINDEX LAYERS
	Used with ZIndexBehavior = Global on the ScreenGui so values are
	compared across the entire hierarchy, not just among siblings.

	Draw order (lowest first):
	  MainFrame → GradientLayer → InnerMask → Content/Slots → HoverOverlay
]]
LayoutConfig.ZIndex = {
	MainFrame   = 0,
	GradientLayer = 10,
	InnerMask   = 11,
	Content     = 12, -- slots, labels, and all slot children render here
	HoverOverlay = 13,
}

--[[
	SLOT DEFAULT SIZES (pixels)
	Fallback sizes used when no size prop is passed. In practice the
	parent panel always computes and passes an explicit size.
]]
LayoutConfig.DefaultSlotSize = {
	Backpack  = 72,
	Equipment = 64,
	Ability   = 36,
	QuickUse  = 56,
}

--[[
	SLOT LABEL POSITIONS
	Scale-based positions for the text labels rendered inside each slot.
	XPos / YPos refer to the Position property's Scale components.
]]
LayoutConfig.SlotLabel = {
	-- Backpack slot: item name in the bottom strip, stack count top-right
	Backpack = {
		LabelHeightScale = 0.25,
		LabelXPos        = 0,
		LabelYPos        = 0.75,
		StackWidthScale  = 0.5,
		StackXPos        = 0.5,
		StackYPos        = 0,
	},
	-- QuickUse slot: same layout but slightly taller strips
	QuickUse = {
		LabelHeightScale = 0.3,
		LabelXPos        = 0,
		LabelYPos        = 0.7,
		StackWidthScale  = 0.4,
		StackXPos        = 0.6,
		StackYPos        = 0,
	},
	-- Equipment / weapon slot: label centred inside the slot
	Equipment = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position    = UDim2.fromScale(0.5, 0.5),
	},
	-- Stack count in top-right corner (Inventory, Equipment, QuickUse)
	StackCorner = {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0.04),
		WidthScale = 0.45,
		HeightScale = 0.28,
	},
}

--[[
	QUICK-USE GRID STRUCTURE
]]
LayoutConfig.QuickUse = {
	SlotCount = 8,
	Cols      = 4,
	Rows      = 2,
}

--[[
	HUD LOADOUT (in-game equipment section, lower-right corner)
	Anchored to the bottom-right of the screen.
]]
LayoutConfig.HudLoadout = {
	AnchorPoint = Vector2.new(1, 1),
	Position    = UDim2.fromScale(0.98, 0.98),
	-- ZIndex layer for the HUD Loadout ScreenGui (above world, below loadout)
	ZIndex      = 5,
}

return LayoutConfig
