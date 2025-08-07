--!strict
-- MinimapController: Client-side minimap controller for static image minimap

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local structureModules = ReplicatedStorage:WaitForChild("Structure")
local MinimapConfig = require(structureModules:WaitForChild("MinimapConfig"))
local IslandConfig = require(structureModules:WaitForChild("IslandConfig"))

-- RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PingRemote = remoteEvents:WaitForChild("PingRemote") :: RemoteEvent

-- Controller
local MinimapController = {}
MinimapController.enabled = true
MinimapController.lastUpdateTime = 0
MinimapController.playerPings = {} :: {[number]: MinimapConfig.PingData}

-- UI Elements
local screenGui: ScreenGui
local minimapFrame: Frame
local fullMapFrame: Frame
local _minimapImage: ImageLabel
local _fullMapImage: ImageLabel
local playerIcon: ImageLabel
local fullMapPlayerIcon: ImageLabel
local pingContainer: Frame
local fullMapPingContainer: Frame

-- Create styled frame with border
local function createStyledFrame(name: string, size: UDim2, position: UDim2, bgColor: Color3, borderColor: Color3, borderSize: number): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = bgColor
    frame.BorderSizePixel = 0
    
    -- Add border
    local border = Instance.new("UIStroke")
    border.Color = borderColor
    border.Thickness = borderSize
    border.Parent = frame
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    return frame
end

-- Create map image
local function createMapImage(parent: Frame): ImageLabel
    local image = Instance.new("ImageLabel")
    image.Name = "MapImage"
    image.Size = UDim2.fromScale(1, 1)
    image.Position = UDim2.fromScale(0, 0)
    image.Image = MinimapConfig.getMinimapAsset()
    image.BackgroundTransparency = 1
    image.ScaleType = Enum.ScaleType.Stretch
    image.Parent = parent
    return image
end

-- Create minimap container (no rotation, just movement tracking)
local function createMinimapContainer(parent: Frame): Frame
    local container = Instance.new("Frame")
    container.Name = "MinimapContainer"
    container.Size = UDim2.fromScale(1, 1)
    container.Position = UDim2.fromScale(0, 0)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = true -- Clips content to frame bounds
    container.Parent = parent
    
    return container
end

-- Create player icon with rotation support
local function createPlayerIcon(parent: Frame, size: UDim2): ImageLabel
    local icon = Instance.new("ImageLabel")
    icon.Name = "PlayerIcon"
    icon.Size = size
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Image = MinimapConfig.PlayerIcon.Image
    icon.ImageColor3 = MinimapConfig.PlayerIcon.Color
    icon.BackgroundTransparency = 1
    icon.ZIndex = MinimapConfig.PlayerIcon.ZIndex
    icon.Parent = parent
    return icon
end

-- Create ping icon
local function createPingIcon(parent: Frame, pingData: MinimapConfig.PingData): ImageLabel
    local pingType = MinimapConfig.Ping.Types[pingData.Type]
    local icon = Instance.new("ImageLabel")
    icon.Name = "PingIcon_" .. tostring(pingData.Timestamp)
    icon.Size = MinimapConfig.Ping.IconSize
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Image = pingType.Icon
    icon.ImageColor3 = pingType.Color
    icon.BackgroundTransparency = 1
    icon.ZIndex = 4
    icon.Parent = parent
    
    -- Add pulse animation
    local pulseSize = UDim2.new(0, 32, 0, 32)
    local _normalSize = MinimapConfig.Ping.IconSize
    local tween = TweenService:Create(
        icon,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = pulseSize}
    )
    tween:Play()
    
    return icon
end

-- Initialize UI
function MinimapController:Initialize()
    -- Create ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MinimapUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Create minimap frame
    minimapFrame = createStyledFrame(
        "MinimapFrame",
        MinimapConfig.Minimap.Size,
        MinimapConfig.Minimap.Position,
        MinimapConfig.Minimap.BackgroundColor,
        MinimapConfig.Minimap.BorderColor,
        MinimapConfig.Minimap.BorderSize
    )
    minimapFrame.ClipsDescendants = true
    minimapFrame.Parent = screenGui
    
    -- Make the main frame circular for visual appeal
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0.5, 0)
    mainCorner.Parent = minimapFrame
    
    -- Create minimap container (no rotation)
    local minimapContainer = createMinimapContainer(minimapFrame)
    
    -- Add minimap image - static, no rotation, just follows player movement
    _minimapImage = createMapImage(minimapContainer)
    local zoomFactor = 3 -- Zoom level for tactical view
    _minimapImage.Size = UDim2.fromScale(zoomFactor, zoomFactor)
    _minimapImage.AnchorPoint = Vector2.new(0.5, 0.5) -- Center anchor
    _minimapImage.Position = UDim2.fromScale(0.5, 0.5) -- Center position
    
    -- Create ping container on top of image
    pingContainer = Instance.new("Frame")
    pingContainer.Name = "PingContainer"
    pingContainer.Size = UDim2.fromScale(1, 1)
    pingContainer.BackgroundTransparency = 1
    pingContainer.Parent = minimapContainer
    
    -- Create player icon on top
    playerIcon = createPlayerIcon(minimapContainer, MinimapConfig.PlayerIcon.Size)
    
    -- Create full map frame (hidden by default)
    fullMapFrame = createStyledFrame(
        "FullMapFrame",
        MinimapConfig.FullMap.Size,
        MinimapConfig.FullMap.Position,
        MinimapConfig.FullMap.BackgroundColor,
        MinimapConfig.FullMap.BorderColor,
        MinimapConfig.FullMap.BorderSize
    )
    fullMapFrame.Visible = false
    fullMapFrame.ZIndex = 10
    fullMapFrame.ClipsDescendants = true
    fullMapFrame.Parent = screenGui
    
    -- Add full map image
    _fullMapImage = createMapImage(fullMapFrame)
    
    -- Create ping container for full map
    fullMapPingContainer = Instance.new("Frame")
    fullMapPingContainer.Name = "PingContainer"
    fullMapPingContainer.Size = UDim2.fromScale(1, 1)
    fullMapPingContainer.BackgroundTransparency = 1
    fullMapPingContainer.Parent = fullMapFrame
    
    -- Create player icon for full map
    fullMapPlayerIcon = createPlayerIcon(fullMapFrame, MinimapConfig.PlayerIcon.Size)
    
    -- Add map title to full map
    local mapTitle = Instance.new("TextLabel")
    mapTitle.Name = "MapTitle"
    mapTitle.Text = IslandConfig.islandName
    mapTitle.Size = UDim2.new(1, 0, 0, 30)
    mapTitle.Position = UDim2.new(0, 0, 0, 5)
    mapTitle.BackgroundTransparency = 1
    mapTitle.TextColor3 = Color3.new(1, 1, 1)
    mapTitle.TextScaled = true
    mapTitle.Font = Enum.Font.SourceSansBold
    mapTitle.Parent = fullMapFrame
    
    -- Initial update
    self:UpdateMinimap(true)
end

-- Update minimap (throttled for performance)
function MinimapController:UpdateMinimap(forceUpdate: boolean?)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then return end
    
    local now = tick()
    local shouldUpdate = forceUpdate or (now - self.lastUpdateTime) >= MinimapConfig.Minimap.UpdateThrottle
    
    if shouldUpdate then
        self.lastUpdateTime = now
        
        -- Get player position in UV coordinates
        local playerUV = MinimapConfig.worldToUV(humanoidRootPart.Position)
        
        -- Calculate player rotation for icon display
        local rotation = math.atan2(
            humanoidRootPart.CFrame.LookVector.X,
            humanoidRootPart.CFrame.LookVector.Z
        )
        local rotationDegrees = math.deg(rotation)
        
        if _minimapImage then
            -- NO ROTATION: Just move the map to keep player centered
            -- Position the map so the player's world position is at the center of the view
            local zoomFactor = 3
            local offsetX = (0.5 - playerUV.X) * zoomFactor
            local offsetY = (0.5 - playerUV.Y) * zoomFactor
            _minimapImage.Position = UDim2.fromScale(0.5 + offsetX, 0.5 + offsetY)
        end
        
        -- Keep player icon centered but show rotation
        playerIcon.Position = UDim2.fromScale(0.5, 0.5)
        playerIcon.Rotation = rotationDegrees -- Show which way player is facing
        
        -- Update ping positions on static minimap
        for playerId, pingData in pairs(self.playerPings) do
            local pingIcon = pingContainer:FindFirstChild("PingIcon_" .. tostring(pingData.Timestamp))
            if pingIcon and pingIcon:IsA("ImageLabel") then
                -- Get ping and player positions in UV coordinates
                local pingUV = MinimapConfig.worldToUV(pingData.Position)
                local currentPlayerUV = MinimapConfig.worldToUV(humanoidRootPart.Position)
                
                -- Calculate relative position on minimap (no rotation needed)
                local zoomFactor = 3
                local relativePingX = (pingUV.X - currentPlayerUV.X) * zoomFactor + 0.5
                local relativePingY = (pingUV.Y - currentPlayerUV.Y) * zoomFactor + 0.5
                
                -- Check if ping is within visible bounds (circular)
                local distanceFromCenter = math.sqrt((relativePingX - 0.5)^2 + (relativePingY - 0.5)^2)
                if distanceFromCenter <= 0.5 then
                    pingIcon.Position = UDim2.fromScale(relativePingX, relativePingY)
                    pingIcon.Visible = true
                else
                    pingIcon.Visible = false
                end
            end
        end
    end
    
    -- Always update player position on full map if visible
    if fullMapFrame.Visible then
        local playerUV = MinimapConfig.worldToUV(humanoidRootPart.Position)
        fullMapPlayerIcon.Position = UDim2.fromScale(playerUV.X, playerUV.Y)
        
        -- Calculate rotation for full map
        local fullMapRotation = math.atan2(
            humanoidRootPart.CFrame.LookVector.X,
            humanoidRootPart.CFrame.LookVector.Z
        )
        fullMapPlayerIcon.Rotation = math.deg(fullMapRotation)
    end
end

-- Handle map toggle
function MinimapController:ToggleFullMap()
    fullMapFrame.Visible = not fullMapFrame.Visible
    
    if fullMapFrame.Visible then
        -- Update ping positions on full map
        for playerId, pingData in pairs(self.playerPings) do
            local existingIcon = fullMapPingContainer:FindFirstChild("PingIcon_" .. tostring(pingData.Timestamp))
            if not existingIcon then
                local icon = createPingIcon(fullMapPingContainer, pingData)
                local pingUV = MinimapConfig.worldToUV(pingData.Position)
                icon.Position = UDim2.fromScale(pingUV.X, pingUV.Y)
            end
        end
    end
end

-- Handle ping creation
function MinimapController:CreatePing(position: Vector3, pingType: "LOCATION" | "DANGER" | "HELP")
    PingRemote:FireServer(position, pingType)
end

-- Handle ping from server
function MinimapController:OnPingReceived(pingData: MinimapConfig.PingData)
    -- Store ping data
    (self :: any).playerPings[pingData.PlayerId] = pingData
    
    -- Create icons on both maps
    local minimapIcon = createPingIcon(pingContainer, pingData)
    local fullMapIcon = createPingIcon(fullMapPingContainer, pingData)
    
    -- Set initial positions for full map (minimap will be updated in UpdateMinimap)
    local pingUV = MinimapConfig.worldToUV(pingData.Position)
    fullMapIcon.Position = UDim2.fromScale(pingUV.X, pingUV.Y)
    
    -- Schedule removal
    local lifetime = MinimapConfig.Ping.Types[pingData.Type].Lifetime
    task.wait(lifetime)
    
    minimapIcon:Destroy()
    fullMapIcon:Destroy()
    self.playerPings[pingData.PlayerId] = nil
end

-- Input handling
function MinimapController:SetupInput()
    -- Map toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == MinimapConfig.Controls.ToggleMapKey then
            self:ToggleFullMap()
        end
    end)
    
    -- Ping on C + click
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton2 and
           UserInputService:IsKeyDown(MinimapConfig.Controls.PingModifierKey) then
            
            local _mouse = player:GetMouse()
            local targetFrame = fullMapFrame.Visible and fullMapFrame or minimapFrame
            
            -- Check if click is on map
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = targetFrame.AbsolutePosition
            local absSize = targetFrame.AbsoluteSize
            
            if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
               mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
                
                -- Calculate UV position from click
                local relX = (mousePos.X - absPos.X) / absSize.X
                local relY = (mousePos.Y - absPos.Y) / absSize.Y
                
                -- For minimap, convert from circular coordinates
                if not fullMapFrame.Visible then
                    -- Convert circular click to world position
                    local centerX, centerY = 0.5, 0.5
                    local clickX = relX - centerX
                    local clickY = relY - centerY
                    
                    -- Check if click is within circle
                    local distance = math.sqrt(clickX^2 + clickY^2)
                    if distance <= 0.5 then
                        -- Convert back to world coordinates
                        local worldPos = MinimapConfig.uvToWorld(Vector2.new(relX, relY))
                        self:CreatePing(worldPos, "LOCATION")
                    end
                else
                    -- Full map click (unchanged)
                    local worldPos = MinimapConfig.uvToWorld(Vector2.new(relX, relY))
                    self:CreatePing(worldPos, "LOCATION")
                end
            end
        end
    end)
end

-- Start the controller
function MinimapController:Start()
    -- Wait for character
    player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to load
        self:Initialize()
    end)
    
    if player.Character then
        self:Initialize()
    end
    
    -- Setup input
    self:SetupInput()
    
    -- Connect to ping events
    PingRemote.OnClientEvent:Connect(function(pingData: MinimapConfig.PingData)
        self:OnPingReceived(pingData)
    end)
    
    -- Update loop
    RunService.Heartbeat:Connect(function()
        if self.enabled and minimapFrame then
            self:UpdateMinimap()
        end
    end)
end

-- Initialize
(MinimapController :: any):Start()