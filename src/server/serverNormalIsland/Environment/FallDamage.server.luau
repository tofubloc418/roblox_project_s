local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))
local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))

-- Track fall start velocity per player
local fallStartSpeed: {[Player]: number} = {}

local function onCharacter(player: Player, character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Freefall then
            -- record vertical speed magnitude at start of fall
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                local v = root.AssemblyLinearVelocity
                fallStartSpeed[player] = math.abs(v.Y)
            else
                fallStartSpeed[player] = 0
            end
        elseif new == Enum.HumanoidStateType.Landed then
            local root = character:FindFirstChild("HumanoidRootPart")
            local impactSpeed = 0
            if root then
                local v = root.AssemblyLinearVelocity
                -- Use downward velocity magnitude at impact
                impactSpeed = math.max(0, -(v.Y))
            end
            local start = fallStartSpeed[player] or 0
            local effective = math.max(start, impactSpeed)

            local minS = PlayerConfig.fallDamageMinSpeed or 50
            local maxS = PlayerConfig.fallDamageMaxSpeed or 120
            local maxPct = PlayerConfig.fallDamageMaxPercent or 0.7

            if effective > minS then
                local t = math.clamp((effective - minS) / math.max(1, (maxS - minS)), 0, 1)
                local humanoidObj = humanoid
                local maxHealth = humanoidObj.MaxHealth
                local damage = maxHealth * maxPct * t
                if damage > 0 then
                    DamageService:ApplyDamage(humanoidObj, damage, player)
                    print(string.format("[FallDamage] %s speed=%.1f damage=%.1f", player.Name, effective, damage))
                end
            end
            fallStartSpeed[player] = nil
        end
    end)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        onCharacter(plr, char)
    end)
end)


