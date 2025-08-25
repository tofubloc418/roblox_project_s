--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))
local MapMath = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MapMath"))

local PingIcons = require(script.Parent:WaitForChild("PingIcons"))
local MinimapView = require(script.Parent:WaitForChild("MinimapView"))
local HudBuilder = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("HudBuilder"))
local CursorManager = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("CursorManager"))
local PlayersService = game:GetService("Players")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PingRemote = remoteEvents:WaitForChild("PingRemote") :: RemoteEvent

local Controller = {}
Controller.enabled = true
Controller.lastUpdateTime = 0
Controller.playerPings = {} :: {[number]: MinimapConfig.PingData}

local _screenGui: ScreenGui
local mini, full
local playerIcon: ImageLabel
local fullMapPlayerIcon: ImageLabel
local topHud
local timerLabel: TextLabel

function Controller:Initialize()
    local build = HudBuilder.buildMinimap(playerGui)
    _screenGui = build.ScreenGui
    mini = build.Mini
    full = build.Full
    playerIcon = build.PlayerIcon
    fullMapPlayerIcon = build.FullMapPlayerIcon

    -- Build top-right HUD
    topHud = HudBuilder.buildTopRightHud(playerGui)

    -- Match timer tucked just under the minimap
    timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "MatchTimer"
    timerLabel.AnchorPoint = Vector2.new(0.5, 0)
    timerLabel.Size = UDim2.fromOffset(120, 18)
    -- Position will be updated each frame relative to minimap; initialize near top-left to avoid nil
    timerLabel.Position = UDim2.fromOffset(0, 0)
    timerLabel.BackgroundTransparency = 0.3
    timerLabel.BackgroundColor3 = Color3.fromRGB(25,25,25)
    timerLabel.TextColor3 = Color3.fromRGB(255,255,255)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Text = "00:00"
    timerLabel.Parent = _screenGui
end

function Controller:Update()
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    local now = tick()
    if (now - self.lastUpdateTime) < MinimapConfig.Minimap.UpdateThrottle then return end
    self.lastUpdateTime = now

    local uv = MapMath.worldToUV(hrp.Position)
    MinimapView.panTo(mini, uv)
    local rot = math.deg(math.atan2(hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Z))
    playerIcon.Rotation = -rot + MinimapConfig.PlayerIcon.RotationOffset
    
    -- Update ping positions on minimap (like old system)
    for _, pingData in pairs(self.playerPings) do
        local pingIcon = mini.PingContainer:FindFirstChild("PingIcon_" .. tostring(pingData.Timestamp))
        if pingIcon and pingIcon:IsA("ImageLabel") then
            local pingUV = MapMath.worldToUV(pingData.Position)
            local zoomFactor = MinimapConfig.Minimap.ZoomFactor
            
            -- Calculate relative position (matching old system logic)
            local relativePingX = (uv.X - pingUV.X) * zoomFactor + 0.5
            local relativePingY = (uv.Y - pingUV.Y) * zoomFactor + 0.5
            
            -- Check if ping is within visible circular bounds
            local distanceFromCenter = math.sqrt((relativePingX - 0.5)^2 + (relativePingY - 0.5)^2)
            if distanceFromCenter <= 0.5 then
                pingIcon.Position = UDim2.fromScale(relativePingX, relativePingY)
                pingIcon.Visible = true
            else
                pingIcon.Visible = false
            end
        end
    end
    
    if full.Frame.Visible then
        fullMapPlayerIcon.Position = MapMath.uvToFullMapPosition(uv)
        fullMapPlayerIcon.Rotation = -rot + MinimapConfig.PlayerIcon.RotationOffset
    end
end

function Controller:ToggleFullMap()
    full.Frame.Visible = not full.Frame.Visible
    CursorManager.setEnabledFor("FullMap", full.Frame.Visible)
    if full.Frame.Visible then
        for _, pingData in pairs(self.playerPings) do
            local existing = full.PingContainer:FindFirstChild("PingIcon_" .. tostring(pingData.Timestamp))
            if not existing then
                local icon = PingIcons.create(full.PingContainer, pingData)
                icon.Position = MapMath.uvToFullMapPosition(MapMath.worldToUV(pingData.Position))
                icon.ZIndex = 12
            end
        end
    end
end

function Controller:CreatePing(worldPos: Vector3, pingType: string)
    PingRemote:FireServer(worldPos, (pingType :: any))
end

function Controller:OnPingReceived(pingData: MinimapConfig.PingData)
    local prev = self.playerPings[pingData.PlayerId]
    if prev then
        local oldMini = mini.PingContainer:FindFirstChild("PingIcon_" .. tostring(prev.Timestamp))
        if oldMini then oldMini:Destroy() end
        local oldFull = full.PingContainer:FindFirstChild("PingIcon_" .. tostring(prev.Timestamp))
        if oldFull then oldFull:Destroy() end
    end
    (self :: any).playerPings[pingData.PlayerId] = pingData

    -- Place minimap icon in static container, accounting for current content pan
    local miniIcon = PingIcons.create(mini.PingContainer, pingData)
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then
            local pingUV = MapMath.worldToUV(pingData.Position)
            local playerUV = MapMath.worldToUV(hrp.Position)
            local zoomFactor = MinimapConfig.Minimap.ZoomFactor
            
            -- Calculate relative position (like old system)
            local relativePingX = (playerUV.X - pingUV.X) * zoomFactor + 0.5
            local relativePingY = (playerUV.Y - pingUV.Y) * zoomFactor + 0.5
            
            miniIcon.Position = UDim2.fromScale(relativePingX, relativePingY)
        end
    end
    miniIcon.ZIndex = 6

    local fullIcon = PingIcons.create(full.PingContainer, pingData)
    fullIcon.Position = MapMath.uvToFullMapPosition(MapMath.worldToUV(pingData.Position))
    fullIcon.ZIndex = 12

    local lifetime = MinimapConfig.Ping.LifetimeSeconds
    task.delay(lifetime, function()
        if miniIcon.Parent then miniIcon:Destroy() end
        if fullIcon.Parent then fullIcon:Destroy() end
        self.playerPings[pingData.PlayerId] = nil
    end)
end

function Controller:SetupInput()
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == MinimapConfig.Controls.ToggleMapKey then
            self:ToggleFullMap()
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 and UserInputService:IsKeyDown(MinimapConfig.Controls.PingModifierKey) then
            if not full.Frame.Visible then return end
            local inset = GuiService:GetGuiInset()
            local mousePos = UserInputService:GetMouseLocation() - inset
            local imgPos = full.Image.AbsolutePosition
            local imgSize = full.Image.AbsoluteSize
            if mousePos.X >= imgPos.X and mousePos.X <= imgPos.X + imgSize.X and mousePos.Y >= imgPos.Y and mousePos.Y <= imgPos.Y + imgSize.Y then
                local relX = (mousePos.X - imgPos.X) / imgSize.X
                local relY = (mousePos.Y - imgPos.Y) / imgSize.Y
                local uv = Vector2.new(1 - relX, 1 - relY)
                self:CreatePing(MapMath.uvToWorld(uv), "LOCATION")
            end
        end
    end)
end

function Controller:Start()
    player.CharacterAdded:Connect(function()
        task.wait(1)
        self:Initialize()
    end)
    if player.Character then self:Initialize() end
    self:SetupInput()
    PingRemote.OnClientEvent:Connect(function(p)
        self:OnPingReceived(p)
    end)
    RunService.Heartbeat:Connect(function()
        if self.enabled and mini then self:Update() end
        -- Update timer and HUD elements
        local matchInfo = ReplicatedStorage:FindFirstChild("MatchInfo")
        local start = matchInfo and matchInfo:FindFirstChild("StartTime")
        if start and timerLabel then
            local elapsed = os.time() - start.Value
            if elapsed < 0 then elapsed = 0 end
            local m = math.floor(elapsed / 60)
            local s = elapsed % 60
            timerLabel.Text = string.format("%02d:%02d", m, s)
            -- Reposition below minimap every frame in case layout changes
            if mini and mini.Frame then
                local f = mini.Frame
                local pos = f.AbsolutePosition
                local size = f.AbsoluteSize
                local x = pos.X + size.X * 0.5
                local y = pos.Y + size.Y + 4
                timerLabel.Position = UDim2.fromOffset(x, y)
                timerLabel.AnchorPoint = Vector2.new(0.5, 0)
            end
        end
        -- Health/Stamina bars
        local character = player.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum and topHud then
            local hpFrac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            topHud.HealthFill.Size = UDim2.fromScale(hpFrac, 1)
            if topHud.HealthCap then
                -- Health cap is full width; adjust if you later support max health modifiers
                topHud.HealthCap.Size = UDim2.fromScale(1, 1)
            end
        end
        -- Stamina from player attribute "Stamina" (0..max) and "MaxStamina"
        if topHud then
            local stamina = player:GetAttribute("Stamina") or 0
            local maxStamina = player:GetAttribute("MaxStamina") or 100
            local stFrac = math.clamp(maxStamina > 0 and (stamina / maxStamina) or 0, 0, 1)
            topHud.StaminaFill.Size = UDim2.fromScale(stFrac, 1)
            if topHud.StaminaCap then
                -- Dynamic capacity cap: fraction of absolute maximum (baseMaxStamina or larger via meds)
                -- Here, cap spans 100% of the bar since MaxStamina already represents the current cap.
                -- If you introduce a global absolute maximum, scale cap to (MaxStamina / absoluteMax).
                topHud.StaminaCap.Size = UDim2.fromScale(1, 1)
            end
            -- Player count
            local count = #PlayersService:GetPlayers()
            topHud.PlayerCount.Text = tostring(count)
        end
    end)
end

(Controller :: any):Start()

return Controller

