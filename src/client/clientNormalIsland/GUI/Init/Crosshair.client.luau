-- Crosshair (disabled; set root.Visible = true to re-enable)
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
root.Visible = false
root.Parent = gui
