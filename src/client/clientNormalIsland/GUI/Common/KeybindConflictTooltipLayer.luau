--!strict
--[[
	Floating conflict tooltip for keybind rows. Own ScreenGui under PlayerGui (same pattern as DragDropManager),
	DisplayOrder above settings + drag ghost. Inner frame is opaque so text stays crisp over the game UI.
]]

local Workspace = game:GetService("Workspace")

local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))

local attachedHost: ScreenGui? = nil
local layer: ScreenGui? = nil
local tipRoot: Frame? = nil
local tipInner: Frame? = nil
local tipLabel: TextLabel? = nil

local TIP_ZINDEX = 1000
local GAP_PX = 8
local VIEWPORT_MARGIN = 6

local function teardown()
	if layer then
		layer:Destroy()
		layer = nil
		tipRoot = nil
		tipInner = nil
		tipLabel = nil
	end
	attachedHost = nil
end

local function ensureLayer(host: ScreenGui)
	if attachedHost == host and layer and tipRoot and tipInner and tipLabel then
		return
	end
	teardown()
	attachedHost = host

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KeybindConflictTooltipLayer"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = host.IgnoreGuiInset
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.DisplayOrder = (host.DisplayOrder or 0) + 2
	screenGui.Enabled = true
	screenGui.Parent = host.Parent

	local root = Instance.new("Frame")
	root.Name = "ConflictTooltipRoot"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Visible = false
	root.ZIndex = TIP_ZINDEX
	root.Parent = screenGui

	local S = ThemeConfig.KeybindsPage
	local inner = Instance.new("Frame")
	inner.Name = "ConflictTooltipInner"
	inner.BorderSizePixel = 0
	inner.Size = UDim2.new(1, 0, 0, 0)
	inner.AutomaticSize = Enum.AutomaticSize.Y
	inner.ZIndex = TIP_ZINDEX
	inner.Parent = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, S.ButtonCornerRadius)
	corner.Parent = inner

	local stroke = Instance.new("UIStroke")
	stroke.Color = ThemeConfig.Colors.Stroke.Default
	stroke.Thickness = ThemeConfig.Colors.Stroke.Thickness
	stroke.Transparency = ThemeConfig.Colors.Stroke.Transparency
	stroke.Parent = inner

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = inner

	local label = Instance.new("TextLabel")
	label.Name = "ConflictTooltipText"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = ThemeConfig.Font.FamilySecondary
	label.TextColor3 = S.ConflictTooltipText
	label.TextTransparency = 0
	label.TextStrokeTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.TextSize = S.ConflictTooltipTextSize
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.ZIndex = TIP_ZINDEX + 1
	label.Parent = inner

	layer = screenGui
	tipRoot = root
	tipInner = inner
	tipLabel = label
end

local function viewportSize(): Vector2
	local cam = Workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

export type ShowOpts = {
	hostScreenGui: ScreenGui,
	text: string,
	anchorLeftX: number,
	centerY: number,
	maxWidth: number,
}

local function applyPosition(opts: ShowOpts)
	if not tipRoot or not tipLabel then
		return
	end

	local tipW = tipRoot.AbsoluteSize.X
	local tipH = tipRoot.AbsoluteSize.Y
	if tipW < 1 or tipH < 1 then
		return
	end

	local rightX = opts.anchorLeftX - GAP_PX
	local leftX = rightX - tipW
	if leftX < VIEWPORT_MARGIN then
		leftX = VIEWPORT_MARGIN
	end

	local vp = viewportSize()
	if leftX + tipW > vp.X - VIEWPORT_MARGIN then
		leftX = math.max(VIEWPORT_MARGIN, vp.X - VIEWPORT_MARGIN - tipW)
	end

	local y = opts.centerY - tipH * 0.5
	y = math.clamp(y, VIEWPORT_MARGIN, math.max(VIEWPORT_MARGIN, vp.Y - tipH - VIEWPORT_MARGIN))
	tipRoot.Position = UDim2.fromOffset(math.floor(leftX), math.floor(y))
end

local KeybindConflictTooltipLayer = {}

function KeybindConflictTooltipLayer.attach(hostScreenGui: ScreenGui)
	ensureLayer(hostScreenGui)
end

function KeybindConflictTooltipLayer.show(opts: ShowOpts)
	KeybindConflictTooltipLayer.apply(opts)
end

function KeybindConflictTooltipLayer.apply(opts: ShowOpts)
	ensureLayer(opts.hostScreenGui)
	if not tipRoot or not tipInner or not tipLabel then
		return
	end

	local S = ThemeConfig.KeybindsPage
	tipInner.BackgroundColor3 = S.ConflictTooltipBackground
	tipInner.BackgroundTransparency = S.ConflictTooltipTransparency
	tipLabel.Text = opts.text
	tipLabel.TextSize = S.ConflictTooltipTextSize
	tipLabel.TextColor3 = S.ConflictTooltipText
	tipLabel.TextTransparency = 0
	tipLabel.TextStrokeTransparency = 1
	tipRoot.Size = UDim2.fromOffset(opts.maxWidth, 0)
	tipRoot.AutomaticSize = Enum.AutomaticSize.Y
	tipRoot.Visible = true

	applyPosition(opts)
end

function KeybindConflictTooltipLayer.reposition(opts: ShowOpts)
	KeybindConflictTooltipLayer.apply(opts)
end

function KeybindConflictTooltipLayer.hide()
	if tipRoot then
		tipRoot.Visible = false
	end
end

return KeybindConflictTooltipLayer
