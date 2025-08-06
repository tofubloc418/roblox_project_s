-- !strict
-- MinimapController: Client-side minimap and full map UI controller

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local sharedModules = ReplicatedStorage:WaitForChild("sharedNormalIsland"):WaitForChild("Modules")
local MinimapConfig = require(sharedModules:WaitForChild("MinimapConfig"))
local MinimapRenderer = require(sharedModules:WaitForChild("MinimapRenderer"))

-- RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PingRemote = remoteEvents:WaitForChild("PingRemote") :: RemoteEvent

-- Controller
local MinimapController = {}
MinimapController.enabled = true
MinimapController.currentZoom = MinimapConfig.Minimap.DefaultZoom
MinimapController.lastUpdateTime = 0
MinimapController.playerPings = {} :: {[number]: MinimapConfig.PingData}

-- UI Elements
local screenGui: ScreenGui
local minimapFrame: Frame
local fullMapFrame: Frame
local minimapRenderer: any
local fullMapRenderer: any
local playerIcon: ImageLabel
local fullMapPlayerIcon: ImageLabel

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
    local normalSize = MinimapConfig.Ping.IconSize
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
    minimapFrame.Parent = screenGui
    
    -- Create map container inside minimap
    local minimapContainer = Instance.new("Frame")
    minimapContainer.Name = "MapContainer"
    minimapContainer.Size = UDim2.fromScale(1, 1)
    minimapContainer.BackgroundTransparency = 1
    minimapContainer.ClipsDescendants = true
    minimapContainer.Parent = minimapFrame
    
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
    fullMapFrame.Parent = screenGui
    
    -- Create map container inside full map
    local fullMapContainer = Instance.new("Frame")
    fullMapContainer.Name = "MapContainer"
    fullMapContainer.Size = UDim2.fromScale(1, 1)
    fullMapContainer.BackgroundTransparency = 1
    fullMapContainer.ClipsDescendants = true
    fullMapContainer.Parent = fullMapFrame
    
    -- Initialize renderers
    minimapRenderer = MinimapRenderer.new(minimapContainer)
    fullMapRenderer = MinimapRenderer.new(fullMapContainer)
    
    -- Create player icons
    playerIcon = createPlayerIcon(minimapContainer, MinimapConfig.PlayerIcon.Size)
    fullMapPlayerIcon = createPlayerIcon(fullMapContainer, MinimapConfig.PlayerIcon.Size)
    
    -- Add map title to full map
    local mapTitle = Instance.new("TextLabel")
    mapTitle.Name = "MapTitle"
    mapTitle.Text = "Island Map"
    mapTitle.Size = UDim2.new(1, 0, 0, 30)
    mapTitle.Position = UDim2.new(0, 0, 0, 5)
    mapTitle.BackgroundTransparency = 1
    mapTitle.TextColor3 = Color3.new(1, 1, 1)
    mapTitle.TextScaled = true
    mapTitle.Font = Enum.Font.SourceSansBold
    mapTitle.Parent = fullMapFrame
    
    -- Add zoom controls to minimap
    self:CreateZoomControls()
    
    -- Initial render
    self:UpdateMinimap(true)
end

-- Create zoom controls
function MinimapController:CreateZoomControls()
    local zoomInButton = Instance.new("TextButton")
    zoomInButton.Name = "ZoomIn"
    zoomInButton.Text = "+"
    zoomInButton.Size = UDim2.new(0, 20, 0, 20)
    zoomInButton.Position = UDim2.new(1, -25, 0, 5)
    zoomInButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    zoomInButton.TextColor3 = Color3.new(1, 1, 1)
    zoomInButton.Parent = minimapFrame
    
    local zoomOutButton = Instance.new("TextButton")
    zoomOutButton.Name = "ZoomOut"
    zoomOutButton.Text = "-"
    zoomOutButton.Size = UDim2.new(0, 20, 0, 20)
    zoomOutButton.Position = UDim2.new(1, -25, 0, 30)
    zoomOutButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    zoomOutButton.TextColor3 = Color3.new(1, 1, 1)
    zoomOutButton.Parent = minimapFrame
    
    zoomInButton.MouseButton1Click:Connect(function()
        self:Zoom(MinimapConfig.Controls.ZoomSpeed)
    end)
    
    zoomOutButton.MouseButton1Click:Connect(function()
        self:Zoom(1 / MinimapConfig.Controls.ZoomSpeed)
    end)
end

-- Zoom functionality
function MinimapController:Zoom(multiplier: number)
    self.currentZoom = math.clamp(
        self.currentZoom * multiplier,
        MinimapConfig.Minimap.MinZoom,
        MinimapConfig.Minimap.MaxZoom
    )
    self:UpdateMinimap(true)
end

-- World to UI position conversion (improved from ChatGPT)
local function worldToUI(worldPos: Vector3, centerPos: Vector3, viewRadius: number, mapSize: Vector2): UDim2
    local relX = (worldPos.X - centerPos.X) / (viewRadius * 2) + 0.5
    local relZ = (worldPos.Z - centerPos.Z) / (viewRadius * 2) + 0.5
    
    -- Clamp to keep icons visible
    relX = math.clamp(relX, 0, 1)
    relZ = math.clamp(relZ, 0, 1)
    
    return UDim2.fromScale(relX, relZ)
end

-- Update minimap (throttled for performance)
function MinimapController:UpdateMinimap(forceRender: boolean?)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then return end
    
    local now = tick()
    local shouldUpdate = forceRender or (now - self.lastUpdateTime) >= MinimapConfig.Minimap.UpdateThrottle
    
    if shouldUpdate then
        self.lastUpdateTime = now
        
        -- Update minimap render
        minimapRenderer:Render(humanoidRootPart.Position, self.currentZoom)
        
        -- Update player rotation
        local rotation = math.atan2(
            humanoidRootPart.CFrame.LookVector.X,
            humanoidRootPart.CFrame.LookVector.Z
        )
        playerIcon.Rotation = math.deg(rotation)
        
        -- Update ping positions on minimap
        for playerId, pingData in pairs(self.playerPings) do
            local pingIcon = minimapFrame:FindFirstChild("PingIcon_" .. tostring(pingData.Timestamp))
            if pingIcon and pingIcon:IsA("ImageLabel") then
                pingIcon.Position = worldToUI(
                    pingData.Position,
                    humanoidRootPart.Position,
                    self.currentZoom,
                    minimapFrame.AbsoluteSize
                )
            end
        end
    end
    
    -- Always update player position on full map
    if fullMapFrame.Visible then
        fullMapPlayerIcon.Position = worldToUI(
            humanoidRootPart.Position,
            Vector3.new(0, 0, 0),
            math.max(MinimapConfig.WorldBounds.Max.X, MinimapConfig.WorldBounds.Max.Y),
            fullMapFrame.AbsoluteSize
        )
        fullMapPlayerIcon.Rotation = playerIcon.Rotation
    end
end

-- Handle map toggle
function MinimapController:ToggleFullMap()
    fullMapFrame.Visible = not fullMapFrame.Visible
    
    if fullMapFrame.Visible then
        -- Render full map when opened
        fullMapRenderer:RenderFullMap()
        
        -- Update ping positions on full map
        for playerId, pingData in pairs(self.playerPings) do
            local existingIcon = fullMapFrame:FindFirstChild("PingIcon_" .. tostring(pingData.Timestamp))
            if not existingIcon then
                local icon = createPingIcon(fullMapFrame:FindFirstChild("MapContainer"), pingData)
                icon.Position = worldToUI(
                    pingData.Position,
                    Vector3.new(0, 0, 0),
                    math.max(MinimapConfig.WorldBounds.Max.X, MinimapConfig.WorldBounds.Max.Y),
                    fullMapFrame.AbsoluteSize
                )
            end
        end
    end
end

-- Handle ping creation
function MinimapController:CreatePing(position: Vector3, pingType: MinimapConfig.PingType)
    PingRemote:FireServer(position, pingType)
end

-- Handle ping from server
function MinimapController:OnPingReceived(pingData: MinimapConfig.PingData)
    -- Store ping data
    self.playerPings[pingData.PlayerId] = pingData
    
    -- Create icons on both maps
    local minimapIcon = createPingIcon(minimapFrame:FindFirstChild("MapContainer"), pingData)
    local fullMapIcon = createPingIcon(fullMapFrame:FindFirstChild("MapContainer"), pingData)
    
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
        elseif input.KeyCode == MinimapConfig.Controls.ZoomInKey then
            self:Zoom(MinimapConfig.Controls.ZoomSpeed)
        elseif input.KeyCode == MinimapConfig.Controls.ZoomOutKey then
            self:Zoom(1 / MinimapConfig.Controls.ZoomSpeed)
        end
    end)
    
    -- Ping on C + right click
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton2 and
           UserInputService:IsKeyDown(MinimapConfig.Controls.PingModifierKey) then
            
            local mouse = player:GetMouse()
            local targetFrame = fullMapFrame.Visible and fullMapFrame or minimapFrame
            
            -- Check if click is on map
            local mousePos = UserInputService:GetMouseLocation()
            local mapContainer = targetFrame:FindFirstChild("MapContainer") :: Frame
            if not mapContainer then return end
            
            local absPos = mapContainer.AbsolutePosition
            local absSize = mapContainer.AbsoluteSize
            
            if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
               mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
                
                -- Calculate world position from click
                local relX = (mousePos.X - absPos.X) / absSize.X
                local relZ = (mousePos.Y - absPos.Y) / absSize.Y
                
                local worldPos: Vector3
                if targetFrame == fullMapFrame then
                    -- Full map uses world coordinates
                    worldPos = Vector3.new(
                        MinimapConfig.WorldBounds.Min.X + relX * (MinimapConfig.WorldBounds.Max.X - MinimapConfig.WorldBounds.Min.X),
                        0,
                        MinimapConfig.WorldBounds.Min.Y + relZ * (MinimapConfig.WorldBounds.Max.Y - MinimapConfig.WorldBounds.Min.Y)
                    )
                else
                    -- Minimap is relative to player
                    local character = player.Character
                    if character then
                        local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
                        if hrp then
                            worldPos = Vector3.new(
                                hrp.Position.X + (relX - 0.5) * self.currentZoom * 2,
                                0,
                                hrp.Position.Z + (relZ - 0.5) * self.currentZoom * 2
                            )
                        end
                    end
                end
                
                if worldPos then
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
MinimapController:Start() 