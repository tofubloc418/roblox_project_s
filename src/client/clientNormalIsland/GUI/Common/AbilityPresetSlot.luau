--!strict
-- Ability slot: registry icon or text; settings vs HUD styling.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))
local RadialCooldownOverlay = require(script.Parent:WaitForChild("RadialCooldownOverlay"))

local C = ThemeConfig.Colors
local F = ThemeConfig.Font
local R = ThemeConfig.CornerRadius
local AB = ThemeConfig.AbilityBar

export type AbilityPresetSlotVariant = "settings" | "hud"

export type AbilityPresetSlotProps = {
	aid: string?,
	isUlt: boolean,
	variant: AbilityPresetSlotVariant,
	pixelSize: number,
	hudScale: number?,
	layoutOrder: number?,
	zIndex: number?,
	hudCooldownRemaining: number?,
	hudCooldownDuration: number?,
	hudAbilityBlocked: boolean?,
}

local SETTINGS_BG = Color3.fromRGB(45, 45, 52)

local function buildHudOverlays(
	zBase: number,
	innerCornerPx: number,
	hudScale: number,
	cooldownRemaining: number?,
	cooldownDuration: number?,
	abilityBlocked: boolean?
): { [string]: any }?
	local rem = cooldownRemaining or 0
	local dur = cooldownDuration or 0
	local blocked = abilityBlocked == true
	local ratio = if dur > 0 then math.clamp(rem / dur, 0, 1) else 0
	local showCd = ratio > 0.02
	local unusable = blocked or showCd
	if not unusable then
		return nil
	end

	local grayC = AB.CooldownUnusableOverlayColor
	local grayT = AB.CooldownUnusableOverlayTransparency
	local timerSize = math.round(AB.CooldownTimerTextSize * hudScale)
	local timerInset = math.round(4 * hudScale)
	local timerTopOffset = math.round(2 * hudScale)

	local out: { [string]: any } = {}

	out.UnusableGray = React.createElement("Frame", {
		Name = "UnusableGray",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = grayC,
		BackgroundTransparency = grayT,
		BorderSizePixel = 0,
		ZIndex = zBase + 1,
	}, if innerCornerPx > 0
		then {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, innerCornerPx) }),
		}
		else nil)

	if showCd then
		out.RadialCooldown = React.createElement(RadialCooldownOverlay, {
			remainingFraction = ratio,
			zIndex = zBase + 2,
			innerCornerPx = innerCornerPx,
		})
		out.CooldownTimer = React.createElement("TextLabel", {
			Name = "CooldownTimer",
			Size = UDim2.new(1, -timerInset, 0, timerSize + timerInset),
			Position = UDim2.new(0.5, 0, 0, timerTopOffset),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = tostring(math.ceil(rem)),
			TextColor3 = C.Text.Primary,
			Font = F.Family,
			TextSize = timerSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextStrokeTransparency = 0.5,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			ZIndex = zBase + 6,
		})
	end

	return out
end

local function AbilityPresetSlot(props: AbilityPresetSlotProps)
	local aid = props.aid
	local visual = if aid then AbilityPresetSlotUtils.resolveVisual(aid) else nil
	local hasIcon = visual and visual.hasIcon or false
	local iconId = if visual then visual.iconId else ""
	local displayName = if visual then visual.displayName elseif aid then aid else ""

	local variant = props.variant
	local size = props.pixelSize
	local z = props.zIndex or LayoutConfig.ZIndex.Content
	local hudScale = props.hudScale or 1

	local bg = if variant == "hud" then C.Slot else SETTINGS_BG

	local iconTransparency = 1
	if hasIcon and iconId ~= "" then
		iconTransparency = 0
	end

	local rem = props.hudCooldownRemaining or 0
	local dur = props.hudCooldownDuration or 0
	local ratio = if dur > 0 then math.clamp(rem / dur, 0, 1) else 0
	local showCd = variant == "hud" and ratio > 0.02
	local blockedHud = variant == "hud" and props.hudAbilityBlocked == true
	local unusableHud = blockedHud or showCd

	local iconElement = if hasIcon
		then React.createElement("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.fromScale(0, 0),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Image = iconId,
			ImageTransparency = if unusableHud then math.max(iconTransparency, 0.35) else iconTransparency,
			ImageColor3 = if unusableHud then Color3.fromRGB(140, 140, 150) else Color3.new(1, 1, 1),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = z,
		}, if variant == "hud"
			then nil
			else {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
			})
		else nil

	local labelElement = if aid and not hasIcon
		then React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.9),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = displayName,
			TextColor3 = if unusableHud then Color3.fromRGB(160, 160, 170) else C.Text.Primary,
			Font = F.FamilySecondary,
			TextScaled = true,
			TextWrapped = true,
			ZIndex = z,
		})
		else nil

	if variant == "hud" then
		local hudR = math.round(AB.HudCornerRadius * hudScale)
		local inset = math.round(AB.HudInset * hudScale)
		local osTheme = AB.HudOuterStroke
		local isUltActive = props.isUlt and aid
		local innerS = AB.HudInnerStroke
		local innerCorner = if hudR > 0 then math.max(0, hudR - 1) else 0
		local outerThickness = math.max(1, math.round(osTheme.DefaultThickness * hudScale))
		local gradientBorderWidth = math.max(1, math.round(ThemeConfig.GradientBorder.BorderWidth * hudScale))

		local rimInset = if isUltActive then math.max(0, inset - gradientBorderWidth) else inset

		local rimChildren: { [string]: any } = {
			InnerCorner = if innerCorner > 0
				then React.createElement("UICorner", { CornerRadius = UDim.new(0, innerCorner) })
				else nil,
			InnerStroke = React.createElement("UIStroke", {
				Color = innerS.Color,
				Thickness = innerS.Thickness,
				Transparency = innerS.Transparency,
				LineJoinMode = Enum.LineJoinMode.Miter,
			}),
			Icon = iconElement,
			Label = labelElement,
		}
		local ov = buildHudOverlays(
			z,
			innerCorner,
			hudScale,
			props.hudCooldownRemaining,
			props.hudCooldownDuration,
			props.hudAbilityBlocked
		)
		if ov then
			for k, el in pairs(ov) do
				rimChildren[k] = el
			end
		end

		local rim = React.createElement("Frame", {
			Name = "HudSlotRim",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -rimInset * 2, 1, -rimInset * 2),
			BackgroundTransparency = 1,
			ZIndex = z,
			ClipsDescendants = true,
		}, rimChildren)

		if isUltActive then
			return React.createElement(GradientBorder, {
				size = size,
				fitWithin = true,
				borderWidth = gradientBorderWidth,
				cornerRadius = hudR,
				innerColor = C.Slot,
				innerTransparency = C.SlotTransparency,
				alwaysShowGradient = true,
				layoutOrder = props.layoutOrder or 0,
			}, {
				Rim = rim,
			})
		end

		local outerColor = osTheme.Default
		local outerTransparency = osTheme.DefaultTransparency

		return React.createElement("Frame", {
			Name = "AbilityPresetSlot",
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = bg,
			BackgroundTransparency = C.SlotTransparency,
			ClipsDescendants = true,
			LayoutOrder = props.layoutOrder or 0,
			ZIndex = z,
		}, {
			Corner = if hudR > 0 then React.createElement("UICorner", { CornerRadius = UDim.new(0, hudR) }) else nil,
			OuterStroke = React.createElement("UIStroke", {
				Color = outerColor,
				Thickness = outerThickness,
				Transparency = outerTransparency,
				LineJoinMode = Enum.LineJoinMode.Miter,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			}),
			Rim = rim,
		})
	end

	return React.createElement("Frame", {
		Name = "AbilityPresetSlot",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = bg,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		LayoutOrder = props.layoutOrder or 0,
		ZIndex = z,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
		Icon = iconElement,
		Label = labelElement,
	})
end

return AbilityPresetSlot
