--!strict
-- One ability preset cell: AbilityRegistry icon or text fallback (`settings` vs `hud` styling).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

local C = ThemeConfig.Colors
local F = ThemeConfig.Font
local R = ThemeConfig.CornerRadius

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

	return React.createElement("Frame", {
		Name = "AbilityPresetSlot",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = bg,
		BackgroundTransparency = if variant == "hud" then C.SlotTransparency else 0,
		ClipsDescendants = true,
		LayoutOrder = props.layoutOrder or 0,
		ZIndex = z,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
		Stroke = if variant == "hud"
			then React.createElement("UIStroke", {
				Color = if props.isUlt and aid then C.Stroke.Active else C.Stroke.Default,
				Thickness = if props.isUlt and aid then C.Stroke.ActiveThickness else C.Stroke.Thickness,
				Transparency = C.Stroke.Transparency,
			})
			else nil,
		Icon = if hasIcon
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
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.Slot) }),
			})
			else nil,
		Label = if aid and not hasIcon
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
			else nil,
	})
end

return AbilityPresetSlot
