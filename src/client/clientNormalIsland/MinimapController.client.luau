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
    
    -- Add minimap image
    _minimapImage = createMapImage(minimapFrame)
    
    -- Create ping container on top of image
    pingContainer = Instance.new("Frame")
    pingContainer.Name = "PingContainer"
    pingContainer.Size = UDim2.fromScale(1, 1)
    pingContainer.BackgroundTransparency = 1
    pingContainer.Parent = minimapFrame
    
    -- Create player icon on top
    playerIcon = createPlayerIcon(minimapFrame, MinimapConfig.PlayerIcon.Size)
    
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
        
        -- Update player icon position on minimap
        playerIcon.Position = UDim2.fromScale(playerUV.X, playerUV.Y)
        
        -- Update player rotation
        local rotation = math.atan2(
            humanoidRootPart.CFrame.LookVector.X,
            humanoidRootPart.CFrame.LookVector.Z
        )
        playerIcon.Rotation = math.deg(rotation)
        
        -- Update ping positions on minimap
        for playerId, pingData in pairs(self.playerPings) do
            local pingIcon = pingContainer:FindFirstChild("PingIcon_" .. tostring(pingData.Timestamp))
            if pingIcon and pingIcon:IsA("ImageLabel") then
                local pingUV = MinimapConfig.worldToUV(pingData.Position)
                pingIcon.Position = UDim2.fromScale(pingUV.X, pingUV.Y)
            end
        end
    end
    
    -- Always update player position on full map if visible
    if fullMapFrame.Visible then
        local playerUV = MinimapConfig.worldToUV(humanoidRootPart.Position)
        fullMapPlayerIcon.Position = UDim2.fromScale(playerUV.X, playerUV.Y)
        fullMapPlayerIcon.Rotation = playerIcon.Rotation
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
    
    -- Set positions
    local pingUV = MinimapConfig.worldToUV(pingData.Position)
    minimapIcon.Position = UDim2.fromScale(pingUV.X, pingUV.Y)
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
                
                -- Convert UV to world position
                local worldPos = MinimapConfig.uvToWorld(Vector2.new(relX, relY))
                
                self:CreatePing(worldPos, "LOCATION")
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