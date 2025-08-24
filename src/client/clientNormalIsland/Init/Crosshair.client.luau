-- Simple cross crosshair that stays at screen center
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CrosshairGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Crosshair"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Size = UDim2.fromOffset(1, 1)
root.Position = UDim2.fromScale(0.5, 0.5)
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Parent = gui

-- Settings
local lineLength = 8
local lineThickness = 2
local color = Color3.new(1, 1, 1)
local gap = 3

local function makeLine(name, size, pos)
    local f = Instance.new("Frame")
    f.Name = name
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.Parent = root
end

-- Horizontal left
makeLine(
    "Left",
    UDim2.fromOffset(lineLength, lineThickness),
    UDim2.fromScale(0.5 - (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.X, 0.5)
)

-- Horizontal right
makeLine(
    "Right",
    UDim2.fromOffset(lineLength, lineThickness),
    UDim2.fromScale(0.5 + (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.X, 0.5)
)

-- Vertical top
makeLine(
    "Top",
    UDim2.fromOffset(lineThickness, lineLength),
    UDim2.fromScale(0.5, 0.5 - (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.Y)
)

-- Vertical bottom
makeLine(
    "Bottom",
    UDim2.fromOffset(lineThickness, lineLength),
    UDim2.fromScale(0.5, 0.5 + (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.Y)
)

-- Keep centered across resizes
local function rebuild()
    for _, child in ipairs(root:GetChildren()) do child:Destroy() end
    makeLine("Left", UDim2.fromOffset(lineLength, lineThickness), UDim2.fromScale(0.5 - (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.X, 0.5))
    makeLine("Right", UDim2.fromOffset(lineLength, lineThickness), UDim2.fromScale(0.5 + (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.X, 0.5))
    makeLine("Top", UDim2.fromOffset(lineThickness, lineLength), UDim2.fromScale(0.5, 0.5 - (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.Y))
    makeLine("Bottom", UDim2.fromOffset(lineThickness, lineLength), UDim2.fromScale(0.5, 0.5 + (gap + lineLength * 0.5) / workspace.CurrentCamera.ViewportSize.Y))
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        rebuild()
    end
end)

if workspace.CurrentCamera then
    rebuild()
end

-- Hide crosshair when UI cursor is enabled (optional tie-in)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cursorFlag = Instance.new("BoolValue")
cursorFlag.Name = "UICursorEnabled"
cursorFlag.Value = false
cursorFlag.Parent = ReplicatedStorage
cursorFlag.Changed:Connect(function()
    root.Visible = not cursorFlag.Value
end)


