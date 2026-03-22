--!strict
-- Weapon slot card: keybind bar + optional icon strip (tweens height when collapsed).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local HudKeybindBar = require(script.Parent:WaitForChild("HudKeybindBar"))

local H = ThemeConfig.HudLoadout
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius

local TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type HudWeaponCardProps = {
	keybind: string,
	weaponName: string?,
	iconImage: string?,
	isActive: boolean,
	showVisual: boolean,
	width: number?,
	hudScale: number?,
	layoutOrder: number?,
	onActivated: (() -> ())?,
}

local function HudWeaponCard(props: HudWeaponCardProps)
	local size = props.width or H.SlotSize
	local hudScale = props.hudScale or 1
	local imageId = props.iconImage or ""
	local scaledSlotHeight = math.round(H.SlotSize * hudScale)
	local scaledCorner = math.round(R.Slot * hudScale)

	local clipRef = React.useRef(nil :: Frame?)
	local prevShowVisual = React.useRef(props.showVisual)
	local isFirstRender = React.useRef(true)

	React.useEffect(function()
		local frame = clipRef.current
		if not frame then return end

		local targetHeight = if props.showVisual then scaledSlotHeight else 0
		local targetSize = UDim2.new(0, size, 0, targetHeight)

		if isFirstRender.current then
			isFirstRender.current = false
			frame.Size = targetSize
		elseif prevShowVisual.current ~= props.showVisual then
			prevShowVisual.current = props.showVisual
			local tween = TweenService:Create(frame, TWEEN_INFO, { Size = targetSize })
			tween:Play()
		end
	end, { props.showVisual, size, scaledSlotHeight } :: { any })

	local initialVisualHeight = if props.showVisual then scaledSlotHeight else 0

	return React.createElement("Frame", {
		Name = "HudWeaponCard_" .. props.keybind,
		Size = UDim2.new(0, size, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 1,
		ClipsDescendants = false,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),

		Bar = React.createElement(HudKeybindBar, {
			keybind = props.keybind,
			label = nil,
			isActive = props.isActive,
			width = size,
			hudScale = hudScale,
			layoutOrder = 1,
			onActivated = props.onActivated,
		}),

		ClipFrame = React.createElement("Frame", {
			Name = "ClipFrame",
			Size = UDim2.new(0, size, 0, initialVisualHeight),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			LayoutOrder = 2,
			ref = clipRef,
		}, {
			Slot = React.createElement("ImageButton", {
				Name = "WeaponSlot",
				Size = UDim2.new(0, size, 0, scaledSlotHeight),
				BackgroundColor3 = C.Slot,
				BackgroundTransparency = C.SlotTransparency,
				AutoButtonColor = false,
				Image = imageId,
				ImageTransparency = imageId == "" and 1 or 0,
				ZIndex = LayoutConfig.ZIndex.Content,
				[React.Event.Activated] = props.onActivated,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, scaledCorner),
				}),
				Stroke = React.createElement("UIStroke", {
					Thickness = C.Stroke.Thickness,
					Color = C.Stroke.Default,
					Transparency = C.Stroke.Transparency,
				}),
			}),
		}),
	})
end

return HudWeaponCard
