local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for the Design folder to be replicated
local Design = ReplicatedStorage:WaitForChild("Design")
local IslandConfig = require(Design.IslandConfig)

local FogController = {}

-- Configuration
local TRANSITION_DURATION = 2 -- seconds
local DEFAULT_FOG_START = 0
local DEFAULT_FOG_COLOR = Color3.fromRGB(192, 192, 192)

-- Store original lighting settings to restore later if needed
local originalLightingSettings = {
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    TimeOfDay = Lighting.TimeOfDay,
    Ambient = Lighting.Ambient
}

-- Apply island-specific lighting settings
local function applyIslandLighting()
    local tweenInfo = TweenInfo.new(
        TRANSITION_DURATION,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
    )
    
    -- Create lighting property changes
    local lightingProperties = {
        FogEnd = IslandConfig.fogDistance,
        FogStart = DEFAULT_FOG_START,
        FogColor = DEFAULT_FOG_COLOR,
        Ambient = IslandConfig.ambientColor
    }
    
    -- Set time of day directly (can't be tweened)
    Lighting.TimeOfDay = IslandConfig.timeOfDay
    
    -- Tween the lighting changes
    local lightingTween = TweenService:Create(Lighting, tweenInfo, lightingProperties)
    lightingTween:Play()
    
    print(string.format("Applied lighting for %s - Fog Distance: %d, Time: %s", 
        IslandConfig.islandName, 
        IslandConfig.fogDistance, 
        IslandConfig.timeOfDay))
end

-- Dynamic fog adjustment based on weather or events
local function adjustFogForConditions(condition, multiplier)
    condition = condition or "normal"
    multiplier = multiplier or 1.0
    
    local baseFogDistance = IslandConfig.fogDistance
    local newFogDistance = baseFogDistance * multiplier
    
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local fogTween = TweenService:Create(Lighting, tweenInfo, {
        FogEnd = newFogDistance
    })
    
    fogTween:Play()
    
    print(string.format("Adjusted fog for condition '%s': %d -> %d", condition, baseFogDistance, newFogDistance))
end

-- Restore original lighting (useful when leaving the island)
local function restoreOriginalLighting()
    local tweenInfo = TweenInfo.new(TRANSITION_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local restoreTween = TweenService:Create(Lighting, tweenInfo, originalLightingSettings)
    restoreTween:Play()
    
    print("Restored original lighting settings")
end

-- Handle time-based fog changes (e.g., morning mist, evening fog)
local function handleTimeBasedFog()
    local currentHour = tonumber(string.sub(Lighting.TimeOfDay, 1, 2))
    
    if currentHour >= 6 and currentHour <= 8 then
        -- Morning mist
        adjustFogForConditions("morning_mist", 0.7)
    elseif currentHour >= 18 and currentHour <= 20 then
        -- Evening fog
        adjustFogForConditions("evening_fog", 0.8)
    else
        -- Normal conditions
        adjustFogForConditions("normal", 1.0)
    end
end

-- Monitor lighting changes and respond accordingly
local function monitorLightingChanges()
    Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
        -- Small delay to allow the time change to settle
        wait(0.1)
        handleTimeBasedFog()
    end)
end

-- Initialize fog controller
local function initializeFogController()
    -- Apply initial island lighting
    applyIslandLighting()
    
    -- Set up time-based fog monitoring
    monitorLightingChanges()
    
    -- Handle initial time-based fog
    handleTimeBasedFog()
    
    print(string.format("FogController initialized for %s", IslandConfig.islandName))
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        restoreOriginalLighting()
    end
end)

-- Wait a moment for everything to load, then initialize
wait(1)
initializeFogController()

-- Expose some functions for other scripts to use
FogController.adjustFog = adjustFogForConditions
FogController.restoreLighting = restoreOriginalLighting
FogController.applyIslandLighting = applyIslandLighting

return FogController 