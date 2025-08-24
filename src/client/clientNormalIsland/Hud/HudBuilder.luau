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
	container.Size = UDim2.fromOffset(260, 36)
	container.BackgroundTransparency = 1
	container.Parent = screen

	local function makeBar(name: string, color: Color3)
		local back = Instance.new("Frame")
		back.Name = name .. "Back"
		back.Size = UDim2.fromOffset(120, 8)
		back.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		back.BorderSizePixel = 0
		back.Parent = container
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = back
		local fill = Instance.new("Frame")
		fill.Name = name .. "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.Parent = back
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 4)
		fillCorner.Parent = fill
		return back, fill
	end

	local healthBack, healthFill = makeBar("Health", Color3.fromRGB(220, 70, 70))
	healthBack.Position = UDim2.fromOffset(0, 2)
	local staminaBack, staminaFill = makeBar("Stamina", Color3.fromRGB(70, 170, 220))
	staminaBack.Position = UDim2.fromOffset(0, 20)

	local countBox = Instance.new("Frame")
	countBox.Name = "PlayerCountBox"
	countBox.AnchorPoint = Vector2.new(1, 0)
	countBox.Position = UDim2.fromOffset(260, 0)
	countBox.Size = UDim2.fromOffset(56, 36)
	countBox.BackgroundColor3 = Color3.fromRGB(25,25,25)
	countBox.BackgroundTransparency = 0.1
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
		StaminaFill = staminaFill,
		PlayerCount = countLabel,
	}
end

return HudBuilder




