local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local MeleeConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Weapons"):WaitForChild("MeleeConfigs"))

local remotes = ReplicatedStorage:WaitForChild("MeleeRemotes")
local meleeAttack = remotes:WaitForChild("MeleeAttack")

local MeleeController = {}
MeleeController.__index = MeleeController

function MeleeController.new()
    local self = setmetatable({}, MeleeController)
    self.equippedTool = nil
    self.config = nil
    self.animator = nil
    self.animations = { Equip = nil, Unequip = nil }
    self.attackTracks = {}
    self.sequenceIndex = 1
    self.attacking = false
    self.autoConn = nil
    self.lastAttackAt = 0
    self.sounds = { Equip = nil, Attack = nil, Unequip = nil }
    return self
end

local function getAnimator(): Animator?
    local character = player.Character
    if not character then return nil end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    return animator
end

local function hasAnyToolEquipped(): boolean
    local character = player.Character
    if not character then return false end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return true
        end
    end
    return false
end

local function loadAnim(animator: Animator, animInstance: Instance): AnimationTrack?
    if not animator or not animInstance or not animInstance:IsA("Animation") then return nil end
    return animator:LoadAnimation(animInstance)
end

local function findAnim(toolOrFolder: Instance, name: string): Instance?
    local anims = toolOrFolder and toolOrFolder:FindFirstChild("Animations")
    if anims then
        local child = anims:FindFirstChild(name)
        if child and child:IsA("Animation") then return child end
    end
    return nil
end

local function findSound(toolOrFolder: Instance, name: string): Sound?
    local sounds = toolOrFolder and toolOrFolder:FindFirstChild("Sounds")
    if sounds then
        local s = sounds:FindFirstChild(name)
        if s and s:IsA("Sound") then return s end
    end
    return nil
end

function MeleeController:Initialize()
    local character = player.Character or player.CharacterAdded:Wait()

    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and MeleeConfigs[child.Name] then
            self:EquipMelee(child)
        end
    end)

    character.ChildRemoved:Connect(function(child)
        if child == self.equippedTool then
            self:UnequipMelee()
        end
    end)

    -- Fists: handle when no tool equipped
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not hasAnyToolEquipped() then
                self:Attack("Fists")
            end
        end
    end)
end

function MeleeController:EquipMelee(tool: Tool)
    self.equippedTool = tool
    self.config = MeleeConfigs[tool.Name]
    self.animator = getAnimator()
    self.attackTracks = {}
    self.sequenceIndex = 1
    self.lastAttackAt = 0
    self.sounds = { Equip = nil, Attack = nil, Unequip = nil }

    -- Load animations
    if self.animator and self.config then
        -- Equip/Unequip
        local equipName = self.config.animations and self.config.animations.Equip
        local _unequipName = self.config.animations and self.config.animations.Unequip
        if equipName then
            local inst = findAnim(tool, equipName)
            if inst then self.animations.Equip = loadAnim(self.animator, inst) end
            if self.animations.Equip then self.animations.Equip:Play() end
        end

        -- Attack sequence
        for _, name in ipairs(self.config.attackSequence or {}) do
            local inst = findAnim(tool, name)
            if inst then
                local track = loadAnim(self.animator, inst)
                if track then table.insert(self.attackTracks, track) end
            end
        end
    end

    -- Load sounds from tool
    self.sounds.Equip = findSound(tool, "Equip")
    self.sounds.Attack = findSound(tool, "Attack")
    self.sounds.Unequip = findSound(tool, "Unequip")
    if self.sounds.Equip then self.sounds.Equip:Play() end

    -- Bind input for this tool
    tool.Activated:Connect(function()
        if self.config and self.config.auto then
            -- Start auto attack loop (Attack() enforces cooldown)
            if not self.autoConn then
                self.attacking = true
                self.autoConn = RunService.Heartbeat:Connect(function()
                    if not self.attacking then return end
                    self:Attack(tool.Name)
                end)
            end
        else
            self:Attack(tool.Name)
        end
    end)
    tool.Deactivated:Connect(function()
        self.attacking = false
        if self.autoConn then
            self.autoConn:Disconnect()
            self.autoConn = nil
        end
    end)

    tool.Unequipped:Connect(function()
        if self.animations.Unequip then self.animations.Unequip:Play() end
        if self.sounds.Unequip then self.sounds.Unequip:Play() end
        self:UnequipMelee()
    end)
end

function MeleeController:UnequipMelee()
    self.attacking = false
    if self.autoConn then
        self.autoConn:Disconnect()
        self.autoConn = nil
    end
    self.equippedTool = nil
    self.config = nil
    self.animator = nil
    self.animations = { Equip = nil, Unequip = nil }
    self.attackTracks = {}
    self.sequenceIndex = 1
    self.sounds = { Equip = nil, Attack = nil, Unequip = nil }
end

function MeleeController:Attack(itemId: string)
    -- Prevent fists attack when any tool is currently equipped (guns, med, etc.)
    if itemId == "Fists" and hasAnyToolEquipped() then
        return
    end
    local cfg = MeleeConfigs[itemId] or MeleeConfigs.Fists
    local cd = (cfg and cfg.cooldownSeconds) or 0.5
    local now = tick()
    if now - (self.lastAttackAt or 0) < cd then
        return
    end
    self.lastAttackAt = now
    local animator = getAnimator()
    if animator then
        local tracks = self.attackTracks
        -- Fists: load on demand from ReplicatedStorage
        if itemId == "Fists" then
            local folder = ReplicatedStorage:FindFirstChild("Animations")
            folder = folder and folder:FindFirstChild("Melee")
            folder = folder and folder:FindFirstChild("Fists")
            if folder then
                local anim = folder:FindFirstChild(cfg.attackSequence[1] or "Attack")
                if anim and anim:IsA("Animation") then
                    local track = animator:LoadAnimation(anim)
                    if track then
                        track:Play()
                    end
                end
            end
            -- Fists attack sound from ReplicatedStorage/Sounds/Melee/Fists/Attack
            local sf = ReplicatedStorage:FindFirstChild("Sounds")
            sf = sf and sf:FindFirstChild("Melee")
            sf = sf and sf:FindFirstChild("Fists")
            local fistSound = sf and sf:FindFirstChild("Attack")
            if fistSound and fistSound:IsA("Sound") then
                fistSound:Play()
            end
        else
            if #tracks > 0 then
                local track = tracks[self.sequenceIndex]
                if track then
                    track:Play()
                end
                self.sequenceIndex += 1
                if self.sequenceIndex > #tracks then self.sequenceIndex = 1 end
            end
            -- Play tool Attack sound
            if self.sounds.Attack then self.sounds.Attack:Play() end
        end
    end

    meleeAttack:FireServer(itemId)
end

local controller = MeleeController.new()
controller:Initialize()

return controller


