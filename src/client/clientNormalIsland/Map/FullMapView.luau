--!strict
-- FullMapView: builds full-screen map with square aspect and ping container

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))

local FullMapView = {}

export type FullMapViewType = {
    Frame: Frame,
    Image: ImageLabel,
    PingContainer: Frame,
}

function FullMapView.new(parent: Instance): FullMapViewType
    local frame = Instance.new("Frame")
    frame.Name = "FullMapFrame"
    frame.Size = MinimapConfig.FullMap.Size
    frame.Position = MinimapConfig.FullMap.Position
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundColor3 = MinimapConfig.FullMap.BackgroundColor
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 10
    frame.ClipsDescendants = true
    frame.Parent = parent

    local border = Instance.new("UIStroke")
    border.Color = MinimapConfig.FullMap.BorderColor
    border.Thickness = MinimapConfig.FullMap.BorderSize
    border.Parent = frame

    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 1
    aspect.Parent = frame

    local img = Instance.new("ImageLabel")
    img.Name = "MapImage"
    img.Size = UDim2.fromScale(1, 1)
    img.Position = UDim2.fromScale(0, 0)
    img.Image = MinimapConfig.getMinimapAsset()
    img.BackgroundTransparency = 1
    img.ScaleType = Enum.ScaleType.Fit
    img.ZIndex = 11
    img.Parent = frame

    local pings = Instance.new("Frame")
    pings.Name = "PingContainer"
    pings.Size = UDim2.fromScale(1, 1)
    pings.BackgroundTransparency = 1
    pings.ZIndex = 12
    pings.Parent = frame

    return {Frame = frame, Image = img, PingContainer = pings}
end

return FullMapView

