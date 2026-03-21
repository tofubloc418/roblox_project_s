--!strict
-- One ability preset cell: AbilityRegistry icon or text fallback (`settings` vs `hud` styling).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local GradientBorder = require(script.Parent.Parent:WaitForChild("GradientBorder"))

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
	layoutOrder: number?,
	zIndex: number?,
}

local SETTINGS_BG = Color3.fromRGB(45, 45, 52)

local function AbilityPresetSlot(props: AbilityPresetSlotProps)
	local aid = props.aid
	local visual = if aid then AbilityPresetSlotUtils.resolveVisual(aid) else nil
	local hasIcon = visual and visual.hasIcon or false
	local iconId = if visual then visual.iconId else ""
	local displayName = if visual then visual.displayName elseif aid then aid else ""

	local variant = props.variant
	local size = props.pixelSize
	local z = props.zIndex or LayoutConfig.ZIndex.Content

	local bg = if variant == "hud" then C.Slot else SETTINGS_BG

	local iconTransparency = 1
	if hasIcon and iconId ~= "" then
		iconTransparency = 0
	end

	local iconElement = if hasIcon
		then React.createElement("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.fromScale(0, 0),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Image = iconId,
			ImageTransparency = iconTransparency,
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
			TextColor3 = C.Text.Primary,
			Font = F.FamilySecondary,
			TextScaled = true,
			TextWrapped = true,
			ZIndex = z,
		})
		else nil

	if variant == "hud" then
		local hudR = AB.HudCornerRadius
		local inset = AB.HudInset
		local osTheme = AB.HudOuterStroke
		local isUltActive = props.isUlt and aid
		local innerS = AB.HudInnerStroke
		local innerCorner = if hudR > 0 then math.max(0, hudR - 1) else 0

		if isUltActive then
			return React.createElement(GradientBorder, {
				size = size,
				fitWithin = true,
				borderWidth = ThemeConfig.GradientBorder.BorderWidth,
				cornerRadius = hudR,
				innerColor = C.Slot,
				alwaysShowGradient = true,
				layoutOrder = props.layoutOrder or 0,
			}, {
				Body = React.createElement("Frame", {
					Name = "AbilityPresetSlot",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = C.Slot,
					BackgroundTransparency = C.SlotTransparency,
					ClipsDescendants = true,
					ZIndex = z,
				}, {
					InnerStroke = React.createElement("UIStroke", {
						Color = innerS.Color,
						Thickness = innerS.Thickness,
						Transparency = innerS.Transparency,
						LineJoinMode = Enum.LineJoinMode.Miter,
					}),
					Icon = iconElement,
					Label = labelElement,
				}),
			})
		end

		local outerColor = osTheme.Default
		local outerTransparency = osTheme.DefaultTransparency
		local outerThickness = osTheme.DefaultThickness

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
			}),
			Rim = React.createElement("Frame", {
				Name = "HudSlotRim",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
				BackgroundTransparency = 1,
				ZIndex = z,
			}, {
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
			}),
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
