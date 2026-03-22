--!strict
-- Arc Raiders-style gradient border: white/blue/purple rim that animates around slots on hover.
-- Reusable for loadout, inventory, and looting UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig = require(script.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent:WaitForChild("LayoutConfig"))

export type GradientBorderProps = {
	-- Size: number for square (offset), or UDim2 for custom
	size: number | UDim2,
	-- When true, fit within the given size (container=size, inner=size-2*border). Use when parent has no extra space.
	fitWithin: boolean?,
	-- Border width in pixels
	borderWidth: number?,
	-- Corner radius for the border (matches slot)
	cornerRadius: number?,
	-- Background color for the inner slot (mask)
	innerColor: Color3?,
	-- Inner mask transparency (default 0). Use for HUD slots that match semi-transparent Slot fill.
	innerTransparency: number?,
	-- Optional: pass through to content
	layoutOrder: number?,
	-- When true, gradient rim stays visible (and animates) without hover — e.g. HUD ultimate slot
	alwaysShowGradient: boolean?,
	-- When true with alwaysShowGradient: no top HoverOverlay (avoids TextButton hand cursor). Content sits above InnerMask and still receives hover for slot visuals.
	omitHoverOverlay: boolean?,
	-- Content children (the slot element)
	children: { [string]: any }?,
	-- When set, this ref is assigned the root Frame (same area that receives hover for gradient). Use for drop-target hit-testing so it matches gradient highlight.
	containerRef: { current: GuiObject? }?,
	-- Event passthrough
	onMouseEnter: (() -> ())?,
	onMouseLeave: (() -> ())?,
	onActivated: (() -> ())?,
	onMouseButton1Down: (() -> ())?,
}

local DEFAULT_BORDER_WIDTH = 2
local ANIMATION_SPEED = 90 -- degrees per second
local RANDOM_SPEED_VARIANCE = 0.4 -- ±40% speed variation

local function createGradientColors()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(100, 180, 255)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(180, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
end

local function GradientBorder(props: GradientBorderProps)
	local size = props.size
	local borderWidth = props.borderWidth or ThemeConfig.GradientBorder.BorderWidth or DEFAULT_BORDER_WIDTH
	local cornerRadius = props.cornerRadius or ThemeConfig.CornerRadius.Slot
	local innerColor = props.innerColor or ThemeConfig.Colors.Slot
	local innerTransparency = props.innerTransparency

	local isHovered, setIsHovered = React.useState(false)
	local alwaysShowGradient = props.alwaysShowGradient == true
	local omitHoverOverlay = props.omitHoverOverlay == true
	local gradientRef = React.useRef(nil :: Instance?)
	local rotationRef = React.useRef(0)
	local speedRef = React.useRef(ANIMATION_SPEED * (1 + (math.random() - 0.5) * RANDOM_SPEED_VARIANCE))

	-- Forward root Frame ref so drop-target hit-test uses the same area as gradient hover
	local function setContainerRef(inst: Instance?)
		if props.containerRef then
			props.containerRef.current = (inst and inst:IsA("GuiObject") and inst :: GuiObject) or nil
		end
	end
	React.useEffect(function()
		return function()
			if props.containerRef then
				props.containerRef.current = nil
			end
		end
	end, { props.containerRef } :: { any })

	local fitWithin = props.fitWithin or false
	local containerSize: UDim2
	local innerSize: UDim2
	if fitWithin then
		-- Fit within allocated space: container = size, inner = container minus border (uniform px ring)
		-- For UDim2: inner must use Scale 1 relative to container, not inherit scale (else left/right borders become huge)
		if typeof(size) == "number" then
			containerSize = UDim2.fromOffset(size, size)
			innerSize = UDim2.fromOffset(size - 2 * borderWidth, size - 2 * borderWidth)
		else
			containerSize = size
			innerSize = UDim2.new(1, -2 * borderWidth, 1, -2 * borderWidth)
		end
	else
		-- Extend beyond: container = size + 2*border, inner = size (for grids with extra space)
		if typeof(size) == "number" then
			local s = size + 2 * borderWidth
			containerSize = UDim2.fromOffset(s, s)
			innerSize = UDim2.fromOffset(size, size)
		else
			containerSize = UDim2.new(
				size.X.Scale,
				size.X.Offset + 2 * borderWidth,
				size.Y.Scale,
				size.Y.Offset + 2 * borderWidth
			)
			innerSize = size
		end
	end

	React.useEffect(function()
		if not isHovered and not alwaysShowGradient then
			return
		end

		local connection = RunService.Heartbeat:Connect(function(dt)
			local gradient = gradientRef.current
			if gradient and gradient:IsA("UIGradient") then
				rotationRef.current = (rotationRef.current + speedRef.current * dt) % 360
				gradient.Rotation = rotationRef.current
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, { isHovered, alwaysShowGradient } :: { any })

	local function onMouseEnter()
		setIsHovered(true)
		if props.onMouseEnter then
			props.onMouseEnter()
		end
	end

	local function onMouseLeave()
		setIsHovered(false)
		if props.onMouseLeave then
			props.onMouseLeave()
		end
	end

	-- Inject hover handlers into children so we detect hover when mouse is over the slot (loadout grids).
	-- Skipped when omitHoverOverlay: top TextButton is omitted too; gradient uses alwaysShowGradient only.
	local childrenWithHover = props.children
	if not omitHoverOverlay and props.children and React.Children and React.Children.map then
		local mapped = React.Children.map(props.children, function(child)
			if React.isValidElement(child :: any) then
				local el = child :: any
				local existingEnter = el.props and el.props[React.Event.MouseEnter]
				local existingLeave = el.props and el.props[React.Event.MouseLeave]
				return React.cloneElement(child, {
					[React.Event.MouseEnter] = function(...)
						onMouseEnter()
						if existingEnter then existingEnter(...) end
					end,
					[React.Event.MouseLeave] = function(...)
						onMouseLeave()
						if existingLeave then existingLeave(...) end
					end,
				})
			end
			return child
		end)
		childrenWithHover = mapped or props.children
	end

	local borderChildren: { [string]: any } = {
		GradientLayer = React.createElement("Frame", {
			Name = "GradientLayer",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = (isHovered or alwaysShowGradient) and 0 or 1,
			ZIndex = LayoutConfig.ZIndex.GradientLayer,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, cornerRadius + borderWidth) }),
			Gradient = React.createElement("UIGradient", {
				Color = createGradientColors(),
				Rotation = 0,
				ref = gradientRef,
			}),
		}),
		InnerMask = React.createElement("Frame", {
			Name = "InnerMask",
			Size = innerSize,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = innerColor,
			BackgroundTransparency = if type(innerTransparency) == "number" then innerTransparency else 0,
			ZIndex = LayoutConfig.ZIndex.InnerMask,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, cornerRadius) }),
		}),
		Content = React.createElement("Frame", {
			Name = "Content",
			Size = innerSize,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, childrenWithHover),
	}

	if not omitHoverOverlay then
		-- Transparent overlay on top so hover works when InnerMask/content do not fill the slot; TextButton = hand cursor.
		borderChildren.HoverOverlay = (function()
			local overlayProps: { [string]: any } = {
				Name = "HoverOverlay",
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = LayoutConfig.ZIndex.HoverOverlay,
				[React.Event.MouseEnter] = onMouseEnter,
				[React.Event.MouseLeave] = onMouseLeave,
			}
			if props.onMouseButton1Down then
				overlayProps[React.Event.MouseButton1Down] = props.onMouseButton1Down
			end
			if props.onActivated then
				overlayProps[React.Event.Activated] = props.onActivated
			end
			return React.createElement("TextButton", overlayProps)
		end)()
	end

	return React.createElement("Frame", {
		Name = "GradientBorderContainer",
		Size = containerSize,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		ref = setContainerRef,
	}, borderChildren)
end

return GradientBorder
