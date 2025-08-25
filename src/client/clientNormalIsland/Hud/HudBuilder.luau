--!strict

-- HudBuilder: centralizes client HUD UI construction (minimap and inventory UI)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Minimap dependencies
local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))
local MapModules = script.Parent.Parent:WaitForChild("Map")
local MinimapView = require(MapModules:WaitForChild("MinimapView"))
local FullMapView = require(MapModules:WaitForChild("FullMapView"))

-- Inventory dependencies
local InventoryModules = script.Parent.Parent:WaitForChild("Inventory")
local InventoryUI = require(InventoryModules:WaitForChild("InventoryUI"))

local HudBuilder = {}

export type MinimapBuild = {
	ScreenGui: ScreenGui,
	Mini: { Frame: Frame, Content: Frame, Image: ImageLabel, PingContainer: Frame },
	Full: { Frame: Frame, Image: ImageLabel, PingContainer: Frame },
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

export type InventoryBuild = {
	Screen: ScreenGui,
	HotbarGui: ScreenGui,
	Grid: Frame,
	Hotbar: Frame,
	SlotButtons: { ImageButton },
	HotbarButtons: { ImageButton },
}

-- Build inventory screens, grid, hotbar and slots
function HudBuilder.buildInventory(rows: number, cols: number): InventoryBuild
	local screen, hotbarGui = InventoryUI.createScreens()
	local grid = InventoryUI.buildInventoryGrid(screen, rows, cols)
	local hotbar = InventoryUI.buildHotbar(hotbarGui, cols)

	local slotButtons: { ImageButton } = {}
	local totalSlots = rows * cols
	for i = 1, totalSlots do
		slotButtons[i] = InventoryUI.createSlot(grid, i)
	end

	local hotbarButtons: { ImageButton } = {}
	for i = 1, cols do
		hotbarButtons[i] = InventoryUI.createSlot(hotbar, i)
	end

	return {
		Screen = screen,
		HotbarGui = hotbarGui,
		Grid = grid,
		Hotbar = hotbar,
		SlotButtons = slotButtons,
		HotbarButtons = hotbarButtons,
	}
end

-- HUD: Health/Stamina bars and player count (top-right)

function HudBuilder.buildTopRightHud(playerGui: PlayerGui)
	local screen = Instance.new("ScreenGui")
	screen.Name = "TopRightHUD"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(1, 0)
	container.Position = UDim2.fromScale(0.99, 0.02)
	-- sizing constants
	local barWidth = 200
	local barHeight = 8
	local boxWidth = 44
	local gap = 12
	container.Size = UDim2.fromOffset(barWidth + gap + boxWidth, 36)
	container.BackgroundTransparency = 1
	container.Parent = screen

	-- Horizontal layout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = container

	local barsContainer = Instance.new("Frame")
	barsContainer.Name = "Bars"
	barsContainer.Size = UDim2.fromOffset(barWidth, 36)
	barsContainer.BackgroundTransparency = 1
	barsContainer.BorderSizePixel = 0
	barsContainer.LayoutOrder = 1
	barsContainer.Parent = container

	local function makeBar(name: string, color: Color3)
		local back = Instance.new("Frame")
		back.Name = name .. "Back"
		back.Size = UDim2.fromOffset(barWidth, barHeight)
		back.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		back.BorderSizePixel = 0
		back.Parent = barsContainer
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = back
		-- Max capacity cap (translucent), fills from right to left
		local cap = Instance.new("Frame")
		cap.Name = name .. "Cap"
		cap.AnchorPoint = Vector2.new(1, 0.5)
		cap.Position = UDim2.fromScale(1, 0.5)
		cap.Size = UDim2.fromScale(1, 1)
		cap.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		cap.BackgroundTransparency = 0.6
		cap.BorderSizePixel = 0
		cap.ZIndex = 2
		cap.Parent = back
		local capCorner = Instance.new("UICorner")
		capCorner.CornerRadius = UDim.new(0, 4)
		capCorner.Parent = cap
		-- Current fill, from right to left
		local fill = Instance.new("Frame")
		fill.Name = name .. "Fill"
		fill.AnchorPoint = Vector2.new(1, 0.5)
		fill.Position = UDim2.fromScale(1, 0.5)
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.ZIndex = 3
		fill.Parent = back
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 4)
		fillCorner.Parent = fill
		return back, fill, cap
	end

	local healthBack, healthFill, healthCap = makeBar("Health", Color3.fromRGB(220, 70, 70))
	healthBack.Position = UDim2.fromOffset(0, 2)
	local staminaBack, staminaFill, staminaCap = makeBar("Stamina", Color3.fromRGB(70, 170, 220))
	staminaBack.Position = UDim2.fromOffset(0, 20)

	local countBox = Instance.new("Frame")
	countBox.Name = "PlayerCountBox"
	countBox.LayoutOrder = 2
	countBox.Size = UDim2.fromOffset(boxWidth, boxWidth)
	countBox.BackgroundColor3 = Color3.fromRGB(25,25,25)
	countBox.BackgroundTransparency = 0.35
	countBox.BorderSizePixel = 0
	countBox.Parent = container
	local cbCorner = Instance.new("UICorner")
	cbCorner.CornerRadius = UDim.new(0, 8)
	cbCorner.Parent = countBox

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "PlayerCount"
	countLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	countLabel.Position = UDim2.fromScale(0.5, 0.5)
	countLabel.Size = UDim2.fromScale(1, 1)
	countLabel.BackgroundTransparency = 1
	countLabel.TextColor3 = Color3.fromRGB(255,255,255)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Text = "0"
	countLabel.Parent = countBox

	return {
		Screen = screen,
		HealthFill = healthFill,
		HealthCap = healthCap,
		StaminaFill = staminaFill,
		StaminaCap = staminaCap,
		PlayerCount = countLabel,
	}
end

return HudBuilder




