--!strict
-- MinimapController: Client-side minimap controller for static image minimap

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

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
local pingContainer: Frame -- will be child of minimap content
local fullMapPingContainer: Frame
local minimapContent: Frame -- content that pans (holds image + pings)

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
    
    -- Make the main frame circular for visual appeal
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0.5, 0)
    mainCorner.Parent = minimapFrame
    
    -- Create minimap content (pans under mask)
    minimapContent = Instance.new("Frame")
    minimapContent.Name = "MinimapContent"
    local zoomFactor = 3
    minimapContent.Size = UDim2.fromScale(zoomFactor, zoomFactor)
    minimapContent.AnchorPoint = Vector2.new(0.5, 0.5)
    minimapContent.Position = UDim2.fromScale(0.5, 0.5)
    minimapContent.BackgroundTransparency = 1
    minimapContent.ClipsDescendants = false
    minimapContent.Parent = minimapFrame
    
    -- Add minimap image (fills content)
    _minimapImage = createMapImage(minimapContent)
    _minimapImage.Size = UDim2.fromScale(1, 1)
    _minimapImage.Position = UDim2.fromScale(0, 0)
    
    -- Create ping container inside content so pings pan with the map
    pingContainer = Instance.new("Frame")
    pingContainer.Name = "PingContainer"
    pingContainer.Size = UDim2.fromScale(1, 1)
    pingContainer.BackgroundTransparency = 1
    pingContainer.Parent = minimapContent
    
    -- Create player icon on top (stays centered)
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

    -- Center the full map on screen
    fullMapFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fullMapFrame.Position = UDim2.fromScale(0.5, 0.5)

    -- Force full map to be square
    local fullMapAspect = Instance.new("UIAspectRatioConstraint")
    fullMapAspect.AspectRatio = 1
    fullMapAspect.Parent = fullMapFrame
    
    -- Add full map image
    _fullMapImage = createMapImage(fullMapFrame)
    _fullMapImage.Size = UDim2.fromScale(1, 1)
    _fullMapImage.Position = UDim2.fromScale(0, 0)
    _fullMapImage.ImageColor3 = Color3.new(1, 1, 1)
    _fullMapImage.ScaleType = Enum.ScaleType.Fit
    _fullMapImage.ZIndex = 11
    
    -- Create ping container for full map
    fullMapPingContainer = Instance.new("Frame")
    fullMapPingContainer.Name = "PingContainer"
    fullMapPingContainer.Size = UDim2.fromScale(1, 1)
    fullMapPingContainer.BackgroundTransparency = 1
    fullMapPingContainer.ZIndex = 12
    fullMapPingContainer.Parent = fullMapFrame
    
    -- Create player icon for full map
    fullMapPlayerIcon = createPlayerIcon(fullMapFrame, MinimapConfig.PlayerIcon.Size)
    fullMapPlayerIcon.ZIndex = 13
    
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
        
        -- Pan content to keep player centered
        do
            local zoomFactor = 3
            local offsetX = (playerUV.X - 0.5) * zoomFactor
            local offsetY = (playerUV.Y - 0.5) * zoomFactor
            minimapContent.Position = UDim2.fromScale(0.5 + offsetX, 0.5 + offsetY)
        end
        
        -- Keep player icon centered but show rotation
        playerIcon.Position = UDim2.fromScale(0.5, 0.5)
        playerIcon.Rotation = -rotationDegrees + MinimapConfig.PlayerIcon.RotationOffset -- Invert so UI matches character turn direction
    end
    
    -- Always update player position on full map if visible
    if fullMapFrame.Visible then
        local playerUV = MinimapConfig.worldToUV(humanoidRootPart.Position)
        fullMapPlayerIcon.Position = UDim2.fromScale(1 - playerUV.X, 1 - playerUV.Y)
        
        -- Calculate rotation for full map
        local fullMapRotation = math.atan2(
            humanoidRootPart.CFrame.LookVector.X,
            humanoidRootPart.CFrame.LookVector.Z
        )
        fullMapPlayerIcon.Rotation = -math.deg(fullMapRotation) + MinimapConfig.PlayerIcon.RotationOffset
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
                icon.Position = UDim2.fromScale(1 - pingUV.X, 1 - pingUV.Y)
            end
        end
    end
end

-- Handle ping creation
function MinimapController:CreatePing(position: Vector3, pingType: string)
    PingRemote:FireServer(position, (pingType :: any))
end

-- Handle ping from server
function MinimapController:OnPingReceived(pingData: MinimapConfig.PingData)
    -- Store ping data (single ping per player policy on client side too)
    -- Clear existing icon for this player if present
    local existing = self.playerPings[pingData.PlayerId]
    if existing then
        local oldMinimap = pingContainer:FindFirstChild("PingIcon_" .. tostring(existing.Timestamp))
        if oldMinimap then oldMinimap:Destroy() end
        local oldFull = fullMapPingContainer:FindFirstChild("PingIcon_" .. tostring(existing.Timestamp))
        if oldFull then oldFull:Destroy() end
    end
    (self :: any).playerPings[pingData.PlayerId] = pingData
    
    -- Create icons on both maps
    local minimapIcon = createPingIcon(pingContainer, pingData)
    local fullMapIcon = createPingIcon(fullMapPingContainer, pingData)
    
    -- Ensure ZIndex above map images
    minimapIcon.ZIndex = 6
    fullMapIcon.ZIndex = 12
    
    -- Place using UV (will pan with content on minimap)
    local pingUV = MinimapConfig.worldToUV(pingData.Position)
    minimapIcon.Position = UDim2.fromScale(1 - pingUV.X, 1 - pingUV.Y)
    fullMapIcon.Position = UDim2.fromScale(1 - pingUV.X, 1 - pingUV.Y)
    
    -- Schedule removal (icons do NOT fade)
    local lifetime = MinimapConfig.Ping.LifetimeSeconds
    task.delay(lifetime, function()
        if minimapIcon.Parent then minimapIcon:Destroy() end
        if fullMapIcon.Parent then fullMapIcon:Destroy() end
        self.playerPings[pingData.PlayerId] = nil
    end)
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
            
            -- Only allow pinging on FULL MAP
            if not fullMapFrame.Visible then
                return
            end
            
            -- Compute mouse position adjusted for GUI inset (top bar)
            local inset = GuiService:GetGuiInset()
            local mousePos = UserInputService:GetMouseLocation() - inset
            
            -- Use the full map image rect for accurate UV
            local imgPos = _fullMapImage.AbsolutePosition
            local imgSize = _fullMapImage.AbsoluteSize
            
            if mousePos.X >= imgPos.X and mousePos.X <= imgPos.X + imgSize.X and
               mousePos.Y >= imgPos.Y and mousePos.Y <= imgPos.Y + imgSize.Y then
                
                local relX = (mousePos.X - imgPos.X) / imgSize.X
                local relY = (mousePos.Y - imgPos.Y) / imgSize.Y
                
                -- Inverse of player icon mapping on the full map (which uses 1-uv)
                local uv = Vector2.new(1 - relX, 1 - relY)
                local worldPos = MinimapConfig.uvToWorld(uv)
                self:CreatePing(worldPos, "LOCATION")
            end
        end
    end)
end

function MinimapController:Start()
    player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to load
        self:Initialize()
    end)
    
    if player.Character then
        self:Initialize()
    end
    
    self:SetupInput()
    
    PingRemote.OnClientEvent:Connect(function(pingData: MinimapConfig.PingData)
        self:OnPingReceived(pingData)
    end)
    
    RunService.Heartbeat:Connect(function()
        if self.enabled and minimapFrame then
            self:UpdateMinimap()
        end
    end)
end

(MinimapController :: any):Start()