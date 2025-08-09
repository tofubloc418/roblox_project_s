--!strict
-- MinimapView: builds a panning minimap content under a masked frame

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local structureModules = ReplicatedStorage:WaitForChild("Structure")
local MinimapConfig = require(structureModules:WaitForChild("MinimapConfig"))
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
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = parent

    local border = Instance.new("UIStroke")
    border.Color = MinimapConfig.Minimap.BorderColor
    border.Thickness = MinimapConfig.Minimap.BorderSize
    border.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8) -- Rounded square corners
    corner.Parent = frame
    
    -- Add shadow effect for sleek 3D appearance (only for minimap)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    -- Use config size + small shadow thickness
    local shadowThickness = 4
    shadow.Size = UDim2.new(
        MinimapConfig.Minimap.Size.X.Scale, 
        MinimapConfig.Minimap.Size.X.Offset + shadowThickness,
        MinimapConfig.Minimap.Size.Y.Scale, 
        MinimapConfig.Minimap.Size.Y.Offset + shadowThickness
    )
    -- Use config position + small shadow offset
    local shadowOffset = 4
    shadow.Position = UDim2.new(
        MinimapConfig.Minimap.Position.X.Scale,
        MinimapConfig.Minimap.Position.X.Offset + shadowOffset,
        MinimapConfig.Minimap.Position.Y.Scale,
        MinimapConfig.Minimap.Position.Y.Offset + shadowOffset
    )
    shadow.AnchorPoint = Vector2.new(0, 0)
    shadow.BackgroundColor3 = Color3.new(0.117647, 0.062745, 0.007843) -- Black shadow
    shadow.BackgroundTransparency = 0.8 -- Semi-transparent
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 0 -- Behind everything
    shadow.Parent = parent -- Same parent as minimap frame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 8)
    shadowCorner.Parent = shadow
    
    -- Add subtle gradient overlay for premium look
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 40, 45)), -- Lighter at top
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 20, 25))  -- Darker at bottom
    }
    gradient.Rotation = 90 -- Top to bottom
    gradient.Parent = frame

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

