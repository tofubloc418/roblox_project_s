--!strict
--[[
	RadialDialConfig
	================
	All layout, dimension, colour, and gap constants for the Arc Raiders-style
	radial dial. Every value that affects the dial's appearance lives here.

	Geometry overview:
	  • Two concentric circle outlines at InnerRadius and OuterRadius.
	  • 8 segment slots fill the space between them, each spanning 45°.
	  • SlotGap creates visual separation between all edges.
	  • SegmentArcWidth / SegmentRadialDepth describe the visible fill area
	    of each slot (computed from the radii and gap values below).

	Segment fill:
	  Currently rendered as a Frame (BackgroundColor3 + UIGradient) so the
	  dial is visible during development without a real image asset.
	  When the donut-slice image (white fill, transparent background, 512×512,
	  donut centre at image centre) is uploaded, replace SegmentImageId and
	  switch the fill to an ImageLabel for the exact arc shape.
]]

local RadialDialConfig = {}

-- ── Scaling: all pixel dimensions are designed at this viewport (short edge). Dial scales with screen. ──
RadialDialConfig.ReferenceViewportSize = 1080   -- min(width, height) at which design values apply

-- ── Radii (at reference viewport) ────────────────────────────────────────────
RadialDialConfig.OuterRadius      = 300   -- px, centre to outer circle stroke
RadialDialConfig.InnerRadius      = 185   -- px, centre to inner circle stroke

-- ── Slot count & gaps ─────────────────────────────────────────────────────────
RadialDialConfig.SlotCount        = 8
RadialDialConfig.SlotGap          = 8     -- px gap on every edge of every segment

-- ── Icon ─────────────────────────────────────────────────────────────────────
RadialDialConfig.IconSize         = 48    -- px, fixed square icon

-- ── Center label ──────────────────────────────────────────────────────────────
RadialDialConfig.CenterLabelFontSize = 22
RadialDialConfig.CenterLabelColor    = Color3.fromRGB(255, 255, 255)
RadialDialConfig.CancelLabelText     = "Cancel"

-- ── Segment fill (idle) ───────────────────────────────────────────────────────
RadialDialConfig.SegmentFillColor        = Color3.fromRGB(35, 35, 42)
RadialDialConfig.SegmentFillTransparency = 0.45
RadialDialConfig.SegmentCornerRadius     = 6   -- px UICorner on the fill frame

-- ── Segment fill (hovered) ────────────────────────────────────────────────────
RadialDialConfig.HoveredFillColor        = Color3.fromRGB(255, 255, 255)
RadialDialConfig.HoveredFillTransparency = 0.0

-- ── Circle outlines ───────────────────────────────────────────────────────────
RadialDialConfig.CircleStrokeColor        = Color3.fromRGB(180, 180, 190)
RadialDialConfig.CircleStrokeTransparency = 0.3
RadialDialConfig.CircleStrokeThickness    = 1.5

-- ── Background overlay ────────────────────────────────────────────────────────
RadialDialConfig.OverlayColor        = Color3.fromRGB(0, 0, 0)
RadialDialConfig.OverlayTransparency = 0.6

-- ── Segment image (production — replace placeholder before ship) ───────────────
-- 45° donut-slice PNG (white fill, transparent bg, 512×512, centre at image centre).
RadialDialConfig.SegmentImageId   = "rbxassetid://84415060524194"

-- ── Ring background: translucent gray filling the area between the two circles (matches HUD loadout slot style). ──
RadialDialConfig.RingBackgroundColor        = Color3.fromRGB(35, 35, 42)   -- same as ThemeConfig.Colors.Slot
RadialDialConfig.RingBackgroundTransparency = 0.5

-- ── Highlighted segment (the one currently selected by virtual cursor): white opaque. ──
RadialDialConfig.HoveredSegmentColor        = Color3.fromRGB(255, 255, 255)
RadialDialConfig.HoveredSegmentTransparency = 0

-- ── Debug colors (annular sector = red, icon square = blue); both drawn transparent so ring shows as gray. ──
RadialDialConfig.UseDebugColors             = true
RadialDialConfig.AnnularSectorColor          = Color3.fromRGB(255, 0, 0)
RadialDialConfig.IconSquareColor            = Color3.fromRGB(0, 0, 255)
RadialDialConfig.AnnularSectorTransparency   = 1   -- transparent (ring uses RingBackground* instead)
RadialDialConfig.IconSquareTransparency     = 1   -- blue square transparent

-- ── Icon square (upright layer that holds the item image; may be larger than sector) ──
RadialDialConfig.IconSquareSize       = 110   -- px, square that holds the item icon (icons use transparent backgrounds)

-- ── Z-order (bottom to top: annulus → annular sector → icon square → center label) ──
RadialDialConfig.ZIndex = {
	Annulus       = 10,   -- circle outlines
	AnnularSector = 11,   -- red donut segments
	IconSquare    = 12,   -- blue squares (on top of segments)
	CenterLabel   = 13,
}

-- ── Derived values (computed once at require time) ────────────────────────────
RadialDialConfig.MidRadius        = (RadialDialConfig.OuterRadius + RadialDialConfig.InnerRadius) / 2

-- Arc length per slot at the mid-radius, minus the two lateral gap widths.
local arcPerSlot = 2 * math.pi * RadialDialConfig.MidRadius / RadialDialConfig.SlotCount
RadialDialConfig.SegmentArcWidth    = math.floor(arcPerSlot - 2 * RadialDialConfig.SlotGap)

-- Radial depth of the visible fill: distance between edges minus top/bottom gap.
RadialDialConfig.SegmentRadialDepth = RadialDialConfig.OuterRadius
	- RadialDialConfig.InnerRadius
	- 2 * RadialDialConfig.SlotGap

RadialDialConfig.SegmentOuterEdge = RadialDialConfig.OuterRadius - RadialDialConfig.SlotGap
RadialDialConfig.SegmentInnerEdge = RadialDialConfig.InnerRadius + RadialDialConfig.SlotGap

return RadialDialConfig
