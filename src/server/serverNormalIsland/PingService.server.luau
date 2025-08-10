--!strict
-- PingService: Server-side ping management with validation and beams
-- Improves on ChatGPT's basic approach with better validation and features

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Modules
local structureModules = ReplicatedStorage:WaitForChild("Structure")
local MinimapConfig = require(structureModules:WaitForChild("MinimapConfig"))

-- Create RemoteEvents folder
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Create ping remote
local PingRemote = Instance.new("RemoteEvent")
PingRemote.Name = "PingRemote"
PingRemote.Parent = remoteEvents

-- Type definitions
type PingData = {
    Type: "LOCATION" | "DANGER" | "HELP",
    Position: Vector3,
    PlayerId: number,
    Timestamp: number,
}

-- Ping storage
type PlayerPingData = {
    pings: {PingData},
    lastPingTime: number,
}

local playerPingData: {[Player]: PlayerPingData} = {}
local activePingBeams: {[string]: BasePart} = {}

-- Validate ping position
local function isValidPingPosition(position: Vector3): boolean
    -- Check world bounds
    if position.X < MinimapConfig.WorldBounds.Min.X or position.X > MinimapConfig.WorldBounds.Max.X then
        return false
    end
    if position.Z < MinimapConfig.WorldBounds.Min.Y or position.Z > MinimapConfig.WorldBounds.Max.Y then
        return false
    end
    
    -- Additional validation: ensure Y coordinate is reasonable
    if math.abs(position.Y) > 1000 then
        return false
    end
    
    return true
end

-- Create ping beam effect
local function createPingBeam(position: Vector3, pingType: string): BasePart?
    local pingConfig = MinimapConfig.Ping.Types[pingType]
    if not pingConfig then return nil end
    
    -- Create base part for beam
    local beamPart = Instance.new("Part")
    beamPart.Name = "PingBeam"
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Transparency = 1
    beamPart.Size = Vector3.new(1, 1, 1)
    beamPart.Position = position + Vector3.new(0, 2, 0)
    beamPart.Parent = workspace
    
    -- Create attachments
    local bottomAttachment = Instance.new("Attachment")
    bottomAttachment.Position = Vector3.new(0, 0, 0)
    bottomAttachment.Parent = beamPart
    
    local topAttachment = Instance.new("Attachment")
    topAttachment.Position = Vector3.new(0, MinimapConfig.Ping.BeamHeight, 0)
    topAttachment.Parent = beamPart
    
    -- Create beam
    local beam = Instance.new("Beam")
    beam.Attachment0 = bottomAttachment
    beam.Attachment1 = topAttachment
    beam.Color = pingConfig.BeamColor
    beam.FaceCamera = true
    beam.Width0 = MinimapConfig.Ping.BeamWidth
    beam.Width1 = MinimapConfig.Ping.BeamWidth * 0.5
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.0),
        NumberSequenceKeypoint.new(1, 0.0)
    })
    beam.Parent = beamPart
    
    -- Add particle effect at top
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particleEmitter.Color = pingConfig.BeamColor
    particleEmitter.Lifetime = NumberRange.new(1, 2)
    particleEmitter.Rate = 10
    particleEmitter.Speed = NumberRange.new(2)
    particleEmitter.SpreadAngle = Vector2.new(45, 45)
    particleEmitter.Parent = topAttachment
    
    -- Add PointLight for visibility
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Color = pingConfig.Color
    light.Range = 30
    light.Parent = beamPart
    
    -- Create ground marker
    local groundMarker = Instance.new("Part")
    groundMarker.Name = "PingGroundMarker"
    groundMarker.Anchored = true
    groundMarker.CanCollide = false
    groundMarker.Material = Enum.Material.Neon
    groundMarker.Size = Vector3.new(4, 0.2, 4)
    groundMarker.Shape = Enum.PartType.Cylinder
    groundMarker.Color = pingConfig.Color
    groundMarker.Position = position
    groundMarker.Orientation = Vector3.new(0, 0, 90)
    groundMarker.Parent = workspace
    
    -- Pulse animation for ground marker
    local pulseSpeed = 2
    local _pulseSize = 1.5
    RunService.Heartbeat:Connect(function()
        if groundMarker.Parent then
            local scale = 1 + math.sin(tick() * pulseSpeed) * 0.2
            groundMarker.Size = Vector3.new(4 * scale, 0.2, 4 * scale)
            groundMarker.Transparency = 0.3 + math.sin(tick() * pulseSpeed) * 0.2
        end
    end)
    
    -- Schedule cleanup with graceful fade out
    local TweenService = game:GetService("TweenService")
    local total = MinimapConfig.Ping.LifetimeSeconds
    local fade = MinimapConfig.Ping.FadeOutSeconds
    local baseWidth0 = MinimapConfig.Ping.BeamWidth
    local baseWidth1 = MinimapConfig.Ping.BeamWidth * 0.5
    
    task.delay(math.max(total - fade, 0), function()
        local fadeInfo = TweenInfo.new(fade, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        -- Drive beam fade via NumberValue
        local fadeValue = Instance.new("NumberValue")
        fadeValue.Value = 0
        fadeValue.Parent = beamPart
        fadeValue:GetPropertyChangedSignal("Value"):Connect(function()
            local f = math.clamp(fadeValue.Value, 0, 1)
            -- Uniform transparency along the beam
            beam.Transparency = NumberSequence.new(f)
            -- Thin the beam as it fades
            beam.Width0 = baseWidth0 * (1 - f)
            beam.Width1 = baseWidth1 * (1 - f)
        end)
        TweenService:Create(fadeValue, fadeInfo, {Value = 1}):Play()
        
        -- Fade auxiliary visuals
        TweenService:Create(light, fadeInfo, {Brightness = 0}):Play()
        TweenService:Create(groundMarker, fadeInfo, {Transparency = 1}):Play()
        TweenService:Create(particleEmitter, fadeInfo, {Rate = 0}):Play()
        
        task.delay(fade + 0.05, function()
            if fadeValue then fadeValue:Destroy() end
        end)
    end)
    
    Debris:AddItem(beamPart, total)
    Debris:AddItem(groundMarker, total)
    
    return beamPart
end

-- Handle ping request from client
local function onPingRequest(player: Player, position: Vector3?, pingTypeStr: string?)
    print("[PingService] Request from", player.Name, "type:", pingTypeStr, "pos:", position)
    -- Validate inputs
    if not position or not pingTypeStr then
        warn("[PingService] Invalid ping request from", player.Name)
        return
    end
    
    -- Validate ping type
    local pingType = pingTypeStr :: MinimapConfig.PingType
    if not MinimapConfig.Ping.Types[pingType] then
        warn("[PingService] Invalid ping type from", player.Name, ":", pingTypeStr)
        return
    end
    print("[PingService] Type validated:", pingType)
    
    -- Validate position
    if not isValidPingPosition(position) then
        warn("[PingService] Invalid ping position from", player.Name, ":", position)
        return
    end
    print("[PingService] Position validated within bounds")
    
    -- Check cooldown
    local playerData = playerPingData[player]
    if not playerData then
        playerData = {
            pings = {},
            lastPingTime = 0
        }
        playerPingData[player] = playerData
    end
    
    local now = tick()
    if now - playerData.lastPingTime < MinimapConfig.Ping.Cooldown then
        print("[PingService] In cooldown; skipping")
        return -- Still in cooldown
    end
    
    -- Always replace existing pings for this player (single active ping policy)
    do
        for key, beam in pairs(activePingBeams) do
            if string.find(key, tostring(player.UserId) .. "_") == 1 then
                if beam and beam.Parent then beam:Destroy() end
                activePingBeams[key] = nil
            end
        end
        playerData.pings = {}
    end
    
    -- Create ping data
    local pingData: MinimapConfig.PingData = {
        Type = pingType :: "LOCATION" | "DANGER" | "HELP",
        Position = position,
        PlayerId = player.UserId,
        Timestamp = now,
    }
    
    -- Store ping
    table.insert(playerData.pings, pingData)
    playerData.lastPingTime = now
    print("[PingService] Stored ping; broadcasting to clients")

    -- Broadcast to all clients immediately
    PingRemote:FireAllClients(pingData)
    
    -- Create beam effect (visual only)
    local beam = createPingBeam(position, pingType)
    if beam then
        local beamKey = string.format("%d_%d", player.UserId, pingData.Timestamp)
        activePingBeams[beamKey] = beam
        print("[PingService] Beam created and registered:", beamKey)
        
        -- Clean up after lifetime
        task.wait(MinimapConfig.Ping.LifetimeSeconds)
        
        -- Remove from storage
        for i, ping in ipairs(playerData.pings) do
            if ping.Timestamp == pingData.Timestamp then
                table.remove(playerData.pings, i)
                break
            end
        end
        
        activePingBeams[beamKey] = nil
        print("[PingService] Beam expired and cleaned:", beamKey)
    end
end

-- Clean up on player leave
local function onPlayerRemoving(player: Player)
    local playerData = playerPingData[player]
    if playerData then
        -- Clean up all beams
        for _, ping in ipairs(playerData.pings) do
            local beamKey = string.format("%d_%d", player.UserId, ping.Timestamp)
            local beam = activePingBeams[beamKey]
            if beam and beam.Parent then
                beam:Destroy()
            end
            activePingBeams[beamKey] = nil
        end
    end
    
    playerPingData[player] = nil
end

-- Initialize service
PingRemote.OnServerEvent:Connect(onPingRequest)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("[PingService] Initialized with validation and beam effects") 