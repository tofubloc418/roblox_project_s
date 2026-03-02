--!strict
--[[
	RadialDialSegment
	=================
	Renders one slot of the radial dial as two separate layers:

	  1. AnnularSectorLayer — ImageLabel showing a 45° donut slice (SegmentImageId),
	     centered at the dial, rotated for this slot. Used for mouse hit detection only;
	     does NOT contain the item icon. Color: debug red or inventory gray from config.

	  2. IconSquareLayer   — Frame at the arc midpoint, always upright (rotation 0).
	     This is the square that holds the item image. Color: debug blue or inventory gray.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig      = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local RadialDialConfig = require(script.Parent:WaitForChild("RadialDialConfig"))
local RadialDialTypes  = require(script.Parent:WaitForChild("RadialDialTypes"))

type RadialSlotData = RadialDialTypes.RadialSlotData

local RC = RadialDialConfig
local TC = ThemeConfig

export type RadialDialSegmentProps = {
	slotIndex: number,
	slotData: RadialSlotData,
	isHovered: boolean,
	cx: number,
	cy: number,
	-- Scale factor from viewport (all pixel dimensions multiplied by this).
	scale: number,
}

local function RadialDialSegment(props: RadialDialSegmentProps)
	local slotIndex = props.slotIndex
	local slotData  = props.slotData
	local isHovered = props.isHovered
	local cx        = props.cx
	local cy        = props.cy
	local scale     = props.scale

	-- Segment rotation: slot 1 at top (−90°), clockwise. Annular sector image is a 45° slice.
	local segRotation    = (slotIndex - 1) * 45
	local centerAngleRad = math.rad(-90 + (slotIndex - 1) * 45)

	-- Scaled dimensions (dial scales with viewport).
	local midRadius   = RC.MidRadius * scale
	local outerRadius = RC.OuterRadius * scale
	local sectorSize  = 2 * outerRadius
	local iconSquareSize = RC.IconSquareSize * scale

	-- Arc midpoint — centre of the icon square (always upright).
	local midX = cx + midRadius * math.cos(centerAngleRad)
	local midY = cy + midRadius * math.sin(centerAngleRad)
	-- Ring: translucent gray by default; highlighted segment (current selection) is white opaque.
	local ringColor        = isHovered and RC.HoveredSegmentColor or RC.RingBackgroundColor
	local ringTransparency = isHovered and RC.HoveredSegmentTransparency or RC.RingBackgroundTransparency
	local squareColor      = (RC.UseDebugColors and RC.IconSquareColor) or TC.Colors.Slot

	local hasIcon = slotData.iconId ~= nil and slotData.iconId ~= ""
	local DialZI = RC.ZIndex

	return React.createElement("Frame", {
		Name = "Segment_" .. tostring(slotIndex),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = DialZI.AnnularSector,
	}, {
		-- ── Ring background: translucent gray donut slice (area between circles; matches HUD loadout). ──
		AnnularSectorLayer = React.createElement("ImageLabel", {
			Name = "AnnularSector",
			Size = UDim2.fromOffset(sectorSize, sectorSize),
			Position = UDim2.fromOffset(cx, cy),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = segRotation,
			Image = RC.SegmentImageId,
			ImageColor3 = ringColor,
			ImageTransparency = ringTransparency,
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = DialZI.AnnularSector,
		}),

		-- ── Icon square layer: upright at arc midpoint, transparent (icons have transparent backgrounds). ──
		IconSquareLayer = React.createElement("Frame", {
			Name = "IconSquare",
			Size = UDim2.fromOffset(iconSquareSize, iconSquareSize),
			Position = UDim2.fromOffset(midX, midY),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = 0,
			BackgroundColor3 = squareColor,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = DialZI.IconSquare,
		}, {
			Icon = hasIcon and React.createElement("ImageLabel", {
				Name = "Icon",
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = slotData.iconId :: string,
				ImageTransparency = 0,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = DialZI.IconSquare,
			}) or nil,
		}),
	})
end

return RadialDialSegment
