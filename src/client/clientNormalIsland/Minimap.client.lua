local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the Design folder to be replicated
local IslandConfig = require(ReplicatedStorage.Design.IslandConfig)

local Minimap = {}

-- GUI Configuration
local MINIMAP_SIZE = UDim2.new(0, 200, 0, 200)
local MINIMAP_POSITION = UDim2.new(1, -220, 0, 20)
local ICON_SIZE = UDim2.new(0, 8, 0, 8)

-- Create the main minimap GUI
local function createMinimapGUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MinimapGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MinimapFrame"
    mainFrame.Size = MINIMAP_SIZE
    mainFrame.Position = MINIMAP_POSITION
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleLabel.BorderSizePixel = 0
    titleLabel.Text = IslandConfig.islandName
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    
    -- Title corner
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleLabel
    
    -- Map area
    local mapArea = Instance.new("Frame")
    mapArea.Name = "MapArea"
    mapArea.Size = UDim2.new(1, -10, 1, -35)
    mapArea.Position = UDim2.new(0, 5, 0, 30)
    mapArea.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
    mapArea.BorderSizePixel = 1
    mapArea.BorderColor3 = Color3.fromRGB(60, 60, 60)
    mapArea.Parent = mainFrame
    
    local mapCorner = Instance.new("UICorner")
    mapCorner.CornerRadius = UDim.new(0, 4)
    mapCorner.Parent = mapArea
    
    return screenGui, mapArea
end

-- Convert world position to minimap position
local function worldToMinimapPosition(worldPos, mapArea)
    local boundarySize = IslandConfig.boundarySize
    local boundaryCenter = IslandConfig.boundaryCenter
    
    -- Calculate relative position within boundary
    local relativeX = (worldPos.X - (boundaryCenter.X - boundarySize.X/2)) / boundarySize.X
    local relativeZ = (worldPos.Z - (boundaryCenter.Z - boundarySize.Z/2)) / boundarySize.Z
    
    -- Convert to GUI coordinates (flip Z for proper map orientation)
    local guiX = relativeX
    local guiY = 1 - relativeZ
    
    return UDim2.new(guiX, -ICON_SIZE.X.Offset/2, guiY, -ICON_SIZE.Y.Offset/2)
end

-- Create spawn point icons
local function createSpawnPointIcons(mapArea)
    -- For now, just show a few representative spawn points since the full list is server-side
    -- In a real implementation, you'd want to send the generated spawn points from server to client
    local representativeSpawns = {
        Vector3.new(0, 10, 0),
        Vector3.new(500, 10, 500),
        Vector3.new(-500, 10, -500),
        Vector3.new(500, 10, -500),
        Vector3.new(-500, 10, 500)
    }
    
    for i, spawnPoint in ipairs(representativeSpawns) do
        local icon = Instance.new("Frame")
        icon.Name = "SpawnPoint" .. i
        icon.Size = ICON_SIZE
        icon.Position = worldToMinimapPosition(spawnPoint, mapArea)
        icon.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        icon.BorderSizePixel = 1
        icon.BorderColor3 = Color3.fromRGB(0, 150, 0)
        icon.Parent = mapArea
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0.5, 0)
        iconCorner.Parent = icon
        
        -- Add glow effect
        local glow = Instance.new("UIStroke")
        glow.Color = Color3.fromRGB(0, 255, 0)
        glow.Thickness = 1
        glow.Transparency = 0.5
        glow.Parent = icon
    end
end

-- Create player position indicator
local function createPlayerIndicator(mapArea)
    local playerIcon = Instance.new("Frame")
    playerIcon.Name = "PlayerIndicator"
    playerIcon.Size = UDim2.new(0, 12, 0, 12)
    playerIcon.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    playerIcon.BorderSizePixel = 2
    playerIcon.BorderColor3 = Color3.fromRGB(255, 255, 255)
    playerIcon.Parent = mapArea
    
    local playerCorner = Instance.new("UICorner")
    playerCorner.CornerRadius = UDim.new(0.5, 0)
    playerCorner.Parent = playerIcon
    
    return playerIcon
end

-- Update player position on minimap
local function updatePlayerPosition(playerIcon, mapArea)
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local position = humanoidRootPart.Position
            playerIcon.Position = worldToMinimapPosition(position, mapArea)
        end
    end
end

-- Initialize the minimap
local function initializeMinimap()
    -- Create the GUI
    local screenGui, mapArea = createMinimapGUI()
    
    -- Add spawn point icons
    createSpawnPointIcons(mapArea)
    
    -- Create player indicator
    local playerIcon = createPlayerIndicator(mapArea)
    
    -- Update player position continuously
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        updatePlayerPosition(playerIcon, mapArea)
    end)
    
    -- Clean up when player leaves
    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            connection:Disconnect()
            screenGui:Destroy()
        end
    end)
    
    print("Minimap initialized for " .. IslandConfig.islandName)
end

-- Wait for character to spawn before initializing
if player.Character then
    initializeMinimap()
else
    player.CharacterAdded:Wait()
    initializeMinimap()
end 