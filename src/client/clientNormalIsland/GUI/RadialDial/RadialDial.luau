--!strict
--[[
	RadialDial
	==========
	Arc Raiders-style radial item selector. Generic component — knows nothing
	about quick-slots, weapons, or inventory. Receives pre-resolved slot data.

	Visual structure (back to front, no full-screen overlay):
	  • Outer/inner circle outlines (annulus).
	  • 8 RadialDialSegment children (annular sector + icon square per slot).
	  • Center TextLabel showing the hovered slot's displayName.

	All visual constants come from RadialDialConfig.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig       = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig      = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local RadialDialConfig  = require(script.Parent:WaitForChild("RadialDialConfig"))
local RadialDialTypes   = require(script.Parent:WaitForChild("RadialDialTypes"))
local RadialDialSegment = require(script.Parent:WaitForChild("RadialDialSegment"))

type RadialDialProps = RadialDialTypes.RadialDialProps

local ZI = LayoutConfig.ZIndex
local RC = RadialDialConfig
local DialZI = RC.ZIndex

local function makeCircle(
	name: string,
	diameter: number,
	cx: number,
	cy: number,
	strokeThickness: number
)
	return React.createElement("Frame", {
		Name = name,
		Size = UDim2.fromOffset(diameter, diameter),
		Position = UDim2.fromOffset(cx, cy),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = DialZI.Annulus,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0.5, 0),
		}),
		Stroke = React.createElement("UIStroke", {
			Thickness    = strokeThickness,
			Color        = RC.CircleStrokeColor,
			Transparency = RC.CircleStrokeTransparency,
		}),
	})
end

local function RadialDial(props: RadialDialProps)
	if not props.visible then
		return nil
	end

	local slots          = props.slots
	local highlightedIdx = props.highlightedIndex
	local viewportSize   = props.viewportSize
	local cx             = viewportSize.X / 2
	local cy             = viewportSize.Y / 2

	-- Scale all dimensions with viewport (reference = design at 1080 short edge).
	local refSize = RC.ReferenceViewportSize
	local scale  = math.min(viewportSize.X, viewportSize.Y) / refSize

	local outerRadius   = RC.OuterRadius * scale
	local innerRadius   = RC.InnerRadius * scale
	local strokeThickness = RC.CircleStrokeThickness * scale
	local labelWidth    = (2 * RC.InnerRadius - 20) * scale
	local labelHeight   = 34 * scale
	local labelFontSize = math.max(1, math.floor(RC.CenterLabelFontSize * scale))

	-- ── Segment elements ────────────────────────────────────────────────────
	local segmentElements: { [string]: any } = {}
	for i = 1, RC.SlotCount do
		local slotData = slots[i]
		if slotData then
			segmentElements["Segment_" .. i] = React.createElement(RadialDialSegment, {
				key       = "Segment_" .. tostring(i),
				slotIndex = i,
				slotData  = slotData,
				isHovered = highlightedIdx == i,
				cx        = cx,
				cy        = cy,
				scale     = scale,
			})
		end
	end

	-- ── Center label text ────────────────────────────────────────────────────
	local labelText: string
	if highlightedIdx then
		local slot = slots[highlightedIdx]
		labelText = if slot then slot.displayName else "Cancel"
	else
		labelText = "Cancel"
	end

	return React.createElement("Frame", {
		Name = "RadialDial",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = ZI.MainFrame,
	}, {
		OuterCircle = makeCircle("OuterCircle", 2 * outerRadius, cx, cy, strokeThickness),
		InnerCircle = makeCircle("InnerCircle", 2 * innerRadius, cx, cy, strokeThickness),

		Segments = React.createElement("Frame", {
			Name = "Segments",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = DialZI.AnnularSector,
		}, segmentElements),

		CenterLabel = React.createElement("TextLabel", {
			Name = "CenterLabel",
			Size = UDim2.fromOffset(labelWidth, labelHeight),
			Position = UDim2.fromOffset(cx - labelWidth / 2, cy - labelHeight / 2),
			BackgroundTransparency = 1,
			Text = labelText,
			TextColor3 = RC.CenterLabelColor,
			Font = ThemeConfig.Font.FamilySecondary,
			TextSize = labelFontSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = DialZI.CenterLabel,
		}),
	})
end

return RadialDial
