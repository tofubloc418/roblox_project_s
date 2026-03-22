--!strict

-- HudBuilder: centralizes client HUD UI construction (minimap, top-right HUD)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Minimap dependencies
local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))
local MapModules = script.Parent.Parent:WaitForChild("Map")
local MinimapView = require(MapModules:WaitForChild("MinimapView"))
local FullMapView = require(MapModules:WaitForChild("FullMapView"))

local HudBuilder = {}

export type MinimapBuild = {
	ScreenGui: ScreenGui,
	Mini: { Frame: Frame, Content: Frame, Image: ImageLabel },
	Full: { Frame: Frame, Image: ImageLabel },
	PlayerIcon: ImageLabel,
	FullMapPlayerIcon: ImageLabel,
}

-- Build minimap/full-map UI and player icons
function HudBuilder.buildMinimap(playerGui: PlayerGui): MinimapBuild
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MinimapUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local mini = MinimapView.new(screenGui)

	local playerIcon = Instance.new("ImageLabel")
	playerIcon.Name = "PlayerIcon"
	playerIcon.Size = MinimapConfig.PlayerIcon.Size
	playerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	playerIcon.Position = UDim2.fromScale(0.5, 0.5)
	playerIcon.Image = MinimapConfig.PlayerIcon.Image
	playerIcon.ImageColor3 = MinimapConfig.PlayerIcon.Color
	playerIcon.BackgroundTransparency = 1
	playerIcon.ZIndex = 5
	playerIcon.Parent = mini.Frame

	local full = FullMapView.new(screenGui)
	local fullMapPlayerIcon = playerIcon:Clone()
	fullMapPlayerIcon.Name = "FullMapPlayerIcon"
	fullMapPlayerIcon.ZIndex = 13
	fullMapPlayerIcon.Parent = full.Frame

	return {
		ScreenGui = screenGui,
		Mini = mini,
		Full = full,
		PlayerIcon = playerIcon,
		FullMapPlayerIcon = fullMapPlayerIcon,
	}
end

-- HUD: Player core stats (health, energy, mana) at bottom-left

function HudBuilder.buildPlayerStatsHud(playerGui: PlayerGui)
	local screen = Instance.new("ScreenGui")
	screen.Name = "PlayerStatsHUD"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local barWidth = 360
	local barHeight = 12
	local barGap = 10
	local outlineThickness = 3

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0, 1)
	container.Position = UDim2.fromScale(0.02, 0.98)
	container.Size = UDim2.fromOffset(barWidth, barHeight * 3 + barGap * 2)
	container.BackgroundTransparency = 1
	container.Parent = screen

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = container

	local barsContainer = Instance.new("Frame")
	barsContainer.Name = "Bars"
	barsContainer.Size = UDim2.fromOffset(barWidth, container.Size.Y.Offset)
	barsContainer.BackgroundTransparency = 1
	barsContainer.BorderSizePixel = 0
	barsContainer.Parent = container

	local function makeBar(name: string, color: Color3, layoutOrder: number)
		-- Transparent outline container (squared)
		local outline = Instance.new("Frame")
		outline.Name = name .. "Outline"
		outline.Size = UDim2.fromOffset(barWidth, barHeight)
		outline.BackgroundTransparency = 1
		outline.BorderSizePixel = 0
		outline.LayoutOrder = layoutOrder
		outline.Parent = barsContainer

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.6
		stroke.Thickness = outlineThickness
		stroke.Parent = outline

		-- Transparent back: only outline shows in unfilled area
		local back = Instance.new("Frame")
		back.Name = name .. "Back"
		back.Size = UDim2.fromScale(1, 1)
		back.BackgroundTransparency = 1
		back.BorderSizePixel = 0
		back.Parent = outline

		-- Cap (invisible, used only for layout; unfilled area stays transparent)
		local cap = Instance.new("Frame")
		cap.Name = name .. "Cap"
		cap.AnchorPoint = Vector2.new(1, 0.5)
		cap.Position = UDim2.fromScale(1, 0.5)
		cap.Size = UDim2.fromScale(1, 1)
		cap.BackgroundTransparency = 1
		cap.BorderSizePixel = 0
		cap.ZIndex = 2
		cap.Parent = back

		-- Current fill, left-anchored so bar depletes right-to-left (squared)
		local fill = Instance.new("Frame")
		fill.Name = name .. "Fill"
		fill.AnchorPoint = Vector2.new(0, 0.5)
		fill.Position = UDim2.fromScale(0, 0.5)
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.ZIndex = 3
		fill.Parent = back

		return back, fill, cap
	end

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, barGap)
	layout.Parent = barsContainer

	local _, manaFill, manaCap = makeBar("Mana", Color3.fromRGB(70, 170, 220), 1)
	local _, energyFill, energyCap = makeBar("Energy", Color3.fromRGB(221, 175, 22), 2)
	local _, healthFill, healthCap = makeBar("Health", Color3.fromRGB(216, 45, 45), 3)

	return {
		Screen = screen,
		UIScaleInstance = uiScale,
		HealthFill = healthFill,
		HealthCap = healthCap,
		EnergyFill = energyFill,
		EnergyCap = energyCap,
		ManaFill = manaFill,
		ManaCap = manaCap,
	}
end

return HudBuilder
