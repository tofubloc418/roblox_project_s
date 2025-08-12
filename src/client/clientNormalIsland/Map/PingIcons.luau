--!strict
-- PingIcons: create consistent ping icons

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))

local PingIcons = {}

function PingIcons.create(parent: Frame, pingData: MinimapConfig.PingData): ImageLabel
    local pingType = MinimapConfig.Ping.Types[pingData.Type]
    local icon = Instance.new("ImageLabel")
    icon.Name = "PingIcon_" .. tostring(pingData.Timestamp)
    icon.Size = MinimapConfig.Ping.IconSize
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Image = pingType.Icon
    icon.ImageColor3 = pingType.Color
    icon.BackgroundTransparency = 1
    icon.ZIndex = 4
    icon.Parent = parent
    -- Pulse
    local pulseSize = UDim2.new(0, 32, 0, 32)
    local tween = TweenService:Create(icon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = pulseSize})
    tween:Play()
    return icon
end

return PingIcons

