--!strict
-- Brief bottom toast for ability preset validation errors.

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))

local attachedHost: ScreenGui? = nil
local layer: ScreenGui? = nil
local root: Frame? = nil
local inner: Frame? = nil
local label: TextLabel? = nil
local hideGeneration = 0

local function teardown()
	if layer then
		layer:Destroy()
	end
	layer = nil
	root = nil
	inner = nil
	label = nil
	attachedHost = nil
end

local function ensure(host: ScreenGui)
	if attachedHost == host and layer and root and label then
		return
	end
	teardown()
	attachedHost = host

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AbilityPresetToastLayer"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = host.IgnoreGuiInset
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.DisplayOrder = (host.DisplayOrder or 0) + 3
	screenGui.Enabled = true
	screenGui.Parent = host.Parent

	local r = Instance.new("Frame")
	r.Name = "ToastRoot"
	r.Size = UDim2.new(1, 0, 1, 0)
	r.BackgroundTransparency = 1
	r.BorderSizePixel = 0
	r.Parent = screenGui

	local inn = Instance.new("Frame")
	inn.Name = "ToastInner"
	inn.AnchorPoint = Vector2.new(0.5, 1)
	inn.Position = UDim2.new(0.5, 0, 1, -24)
	inn.Size = UDim2.new(0, 420, 0, 0)
	inn.AutomaticSize = Enum.AutomaticSize.Y
	inn.BackgroundColor3 = ThemeConfig.Colors.MainFrame
	inn.BackgroundTransparency = 0.05
	inn.BorderSizePixel = 0
	inn.Visible = false
	inn.ZIndex = 10
	inn.Parent = r

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, ThemeConfig.CornerRadius.Slot)
	corner.Parent = inn

	local stroke = Instance.new("UIStroke")
	stroke.Color = ThemeConfig.Colors.Stroke.Default
	stroke.Thickness = ThemeConfig.Colors.Stroke.Thickness
	stroke.Transparency = ThemeConfig.Colors.Stroke.Transparency
	stroke.Parent = inn

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = inn

	local lbl = Instance.new("TextLabel")
	lbl.Name = "ToastText"
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.Font = ThemeConfig.Font.FamilySecondary
	lbl.TextColor3 = ThemeConfig.Colors.Text.Primary
	lbl.TextSize = 15
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.ZIndex = 11
	lbl.Parent = inn

	layer = screenGui
	root = r
	inner = inn
	label = lbl
end

local AbilityPresetToast = {}

function AbilityPresetToast.attach(hostScreenGui: ScreenGui)
	ensure(hostScreenGui)
end

function AbilityPresetToast.showError(hostScreenGui: ScreenGui, message: string, durationSec: number?)
	ensure(hostScreenGui)
	if not inner or not label then
		return
	end
	hideGeneration += 1
	local gen = hideGeneration
	label.Text = message
	inner.Visible = true
	local dur = durationSec or 3.5
	task.delay(dur, function()
		if gen == hideGeneration and inner then
			inner.Visible = false
		end
	end)
end

return AbilityPresetToast
