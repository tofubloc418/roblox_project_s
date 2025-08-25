--!strict
-- MinimapView: builds a panning minimap content under a masked frame

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))
local MapMath = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MapMath"))

local MinimapView = {}

export type MinimapViewType = {
    Frame: Frame,
    Content: Frame,
    Image: ImageLabel,
    PingContainer: Frame,
}

function MinimapView.new(parent: Instance): MinimapViewType
    local frame = Instance.new("Frame")
    frame.Name = "MinimapFrame"
    frame.Size = MinimapConfig.Minimap.Size
    frame.Position = MinimapConfig.Minimap.Position
    frame.BackgroundColor3 = MinimapConfig.Minimap.BackgroundColor
    frame.BorderSizePixel = 4
    frame.BorderColor3 = Color3.fromRGB(0,0,0)
    frame.ClipsDescendants = true
    frame.Parent = parent

    local content = Instance.new("Frame")
    content.Name = "Content"
    local zoomFactor = MinimapConfig.Minimap.ZoomFactor
    content.Size = UDim2.fromScale(zoomFactor, zoomFactor)
    content.AnchorPoint = Vector2.new(0.5, 0.5)
    content.Position = UDim2.fromScale(0.5, 0.5)
    content.BackgroundTransparency = 1
    content.Parent = frame

    local img = Instance.new("ImageLabel")
    img.Name = "MapImage"
    img.Size = UDim2.fromScale(1, 1)
    img.Position = UDim2.fromScale(0, 0)
    img.Image = MinimapConfig.getMinimapAsset()
    img.BackgroundTransparency = 1
    img.ScaleType = Enum.ScaleType.Stretch
    img.Parent = content

    local pings = Instance.new("Frame")
    pings.Name = "PingContainer"
    pings.Size = UDim2.fromScale(1, 1)
    pings.BackgroundTransparency = 1
    pings.Parent = frame

    return {Frame = frame, Content = content, Image = img, PingContainer = pings}
end

function MinimapView.panTo(view: MinimapViewType, playerUV: Vector2)
    view.Content.Position = MapMath.minimapPanForPlayerUV(playerUV, MinimapConfig.Minimap.ZoomFactor)
end

return MinimapView

