--!strict
-- Cooldown pie: UIGradient clears blue where elapsed so UnusableGray shows through (no gray layer on blue).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React")) :: any

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))

local AB = ThemeConfig.AbilityBar

local BLUE_SWEEP_TRANSPARENCY_RIGHT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.499, 1),
	NumberSequenceKeypoint.new(0.501, 0),
	NumberSequenceKeypoint.new(1, 0),
})
local BLUE_SWEEP_TRANSPARENCY_LEFT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.499, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
})
local SWEEP_GRADIENT_COLOR = ColorSequence.new(Color3.new(1, 1, 1))

local BLUE_DISK_BLEED_PX = 2

export type RadialCooldownOverlayProps = {
	remainingFraction: number,
	zIndex: number,
	innerCornerPx: number,
}

local function RadialCooldownOverlay(props: RadialCooldownOverlayProps)
	local p = math.clamp(props.remainingFraction, 0, 1)
	if p <= 0.001 then
		return nil :: any
	end

	local thetaHide = (1 - p) * 360
	local rightRot = math.clamp(-thetaHide, -180, 0)
	local leftRot = math.clamp(-thetaHide + 180, -180, 0)
	local innerCorner = props.innerCornerPx
	local z = props.zIndex

	local blue = AB.CooldownRadialFillColor
	local blueT = AB.CooldownRadialFillTransparency

	local clipCorner = if innerCorner > 0
		then React.createElement("UICorner", { CornerRadius = UDim.new(0, innerCorner) })
		else nil

	local blueFillSize = UDim2.new(2, BLUE_DISK_BLEED_PX * 2, 1, BLUE_DISK_BLEED_PX * 2)
	local blueCornerRight = if innerCorner > 0
		then React.createElement("UICorner", { CornerRadius = UDim.new(0, innerCorner) })
		else nil
	local blueCornerLeft = if innerCorner > 0
		then React.createElement("UICorner", { CornerRadius = UDim.new(0, innerCorner) })
		else nil

	return React.createElement("Frame", {
		Name = "RadialCooldownOverlay",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		BorderSizePixel = 0,
		ZIndex = z,
	}, {
		ClipCorner = clipCorner,
		RightClip = React.createElement("Frame", {
			Name = "RightClip",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			BorderSizePixel = 0,
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ZIndex = z,
		}, {
			RightBlue = React.createElement("Frame", {
				Name = "RightBlue",
				Size = blueFillSize,
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = blue,
				BackgroundTransparency = blueT,
				BorderSizePixel = 0,
				Rotation = 0,
				ZIndex = z,
			}, {
				BlueCorner = blueCornerRight,
				Sweep = React.createElement("UIGradient", {
					Rotation = rightRot,
					Color = SWEEP_GRADIENT_COLOR,
					Transparency = BLUE_SWEEP_TRANSPARENCY_RIGHT,
				}),
			}),
		}),
		LeftClip = React.createElement("Frame", {
			Name = "LeftClip",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			BorderSizePixel = 0,
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			ZIndex = z,
		}, {
			LeftBlue = React.createElement("Frame", {
				Name = "LeftBlue",
				Size = blueFillSize,
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = blue,
				BackgroundTransparency = blueT,
				BorderSizePixel = 0,
				Rotation = 0,
				ZIndex = z,
			}, {
				BlueCorner = blueCornerLeft,
				Sweep = React.createElement("UIGradient", {
					Rotation = leftRot,
					Color = SWEEP_GRADIENT_COLOR,
					Transparency = BLUE_SWEEP_TRANSPARENCY_LEFT,
				}),
			}),
		}),
	})
end

return RadialCooldownOverlay
