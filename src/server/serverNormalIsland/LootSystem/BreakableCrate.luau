--[[
	BreakableCrate
	Component that handles crate damage, crack stages, and breaking
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Shared modules
local LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))

local BreakableCrate = {}
BreakableCrate.__index = BreakableCrate

-- Static registry of all active crates
BreakableCrate.ActiveCrates = {}

function BreakableCrate.new(crateModel: Model)
	local self = setmetatable({}, BreakableCrate)
	
	self.Model = crateModel
	self.CrateType = crateModel:GetAttribute("CrateType") or "Normal"
	self.MaxHealth = crateModel:GetAttribute("MaxHealth") or 100
	self.Health = crateModel:GetAttribute("Health") or self.MaxHealth
	self.CrackStage = 0
	self.IsBroken = false
	
	-- Services (will be set during registration)
	self.LootBoxService = nil
	self.DamageService = nil
	
	-- Initialize visuals
	self:UpdateCrackVisuals()
	
	return self
end

-- Register a crate with the system
function BreakableCrate:RegisterCrate(crateModel: Model, lootBoxService, damageService)
	-- Check if already registered
	if BreakableCrate.ActiveCrates[crateModel] then
		return BreakableCrate.ActiveCrates[crateModel]
	end
	
	-- Assign attributes from LootConfig before component construction
	local crateType = crateModel:GetAttribute("CrateType") or "Normal"
	local crateCfg = LootConfig.GetCrateConfig(crateType)
	if crateCfg then
		crateModel:SetAttribute("CrateId", crateModel:GetAttribute("CrateId") or ("manual_" .. crateModel:GetFullName()))
		crateModel:SetAttribute("MaxHealth", crateCfg.MaxHealth or 100)
		crateModel:SetAttribute("Health", crateCfg.MaxHealth or 100)
		crateModel:SetAttribute("CrackStage", crateModel:GetAttribute("CrackStage") or 0)
		crateModel:SetAttribute("BundleCount", crateCfg.BundleCount or 1)
		if crateCfg.Whitelist then
			crateModel:SetAttribute("Whitelist", game:GetService("HttpService"):JSONEncode(crateCfg.Whitelist))
		end
		if crateCfg.GuaranteeAtLeast then
			crateModel:SetAttribute("GuaranteeAtLeast", game:GetService("HttpService"):JSONEncode(crateCfg.GuaranteeAtLeast))
		end
	end

	-- Create new component after attributes are set
	local component = BreakableCrate.new(crateModel)
	component.LootBoxService = lootBoxService
	component.DamageService = damageService
	
	-- Register with damage service
	if damageService then
		damageService:RegisterDamageable(crateModel, function(damage, source)
			component:TakeDamage(damage, source)
		end)
	end
	
	-- Store in registry
	BreakableCrate.ActiveCrates[crateModel] = component
	
	-- Clean up when model is destroyed
	crateModel.AncestryChanged:Connect(function()
		if not crateModel.Parent then
			BreakableCrate.ActiveCrates[crateModel] = nil
			if damageService then
				damageService:UnregisterDamageable(crateModel)
			end
		end
	end)
	

	
	return component
end

-- Take damage
function BreakableCrate:TakeDamage(damage: number, source: any?)
	if self.IsBroken then
		return
	end
	
	local _oldHealth = self.Health
	self.Health = math.max(0, self.Health - damage)
	self.Model:SetAttribute("Health", self.Health)
	

	
	-- Check if broken
	if self.Health <= 0 then
		self:Break(source)
		return
	end
	
	-- Update crack stage
	local oldStage = self.CrackStage
	self.CrackStage = self:CalculateCrackStage()
	self.Model:SetAttribute("CrackStage", self.CrackStage)
	
	-- Update visuals if stage changed
	if oldStage ~= self.CrackStage then
		self:UpdateCrackVisuals()
		self:PlayCrackSound()
	end
end

-- Calculate crack stage based on health percentage
function BreakableCrate:CalculateCrackStage(): number
	local healthPercent = (self.Health / self.MaxHealth) * 100
	
	if healthPercent > 75 then
		return 0 -- Normal
	elseif healthPercent > 50 then
		return 1 -- Light crack
	elseif healthPercent > 25 then
		return 2 -- Heavy crack
	else
		return 2 -- Still heavy crack until broken
	end
end

-- Update crack visuals
function BreakableCrate:UpdateCrackVisuals()
	local primaryPart = self.Model.PrimaryPart or self.Model:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then
		return
	end
	-- Remove legacy overlay visuals if they exist
	local overlayFolder = self.Model:FindFirstChild("CrackOverlays")
	if overlayFolder then
		overlayFolder:Destroy()
	end

	-- Simple visual: adjust transparency proportional to damage
	local damageRatio = 1 - (self.Health / self.MaxHealth)
	primaryPart.Transparency = math.min(0.5, damageRatio * 0.5)
end

-- Play crack sound effect
function BreakableCrate:PlayCrackSound()
	-- Optionally play a small crack sound if present as a child
	local sound = self.Model:FindFirstChild("CrackSound")
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

-- Break the crate and drop loot
function BreakableCrate:Break(source: any?)
	if self.IsBroken then
		return
	end
	
	self.IsBroken = true
	

	
	-- 1) Play break sound if provided by authoring
	local breakSound = self.Model:FindFirstChild("BreakSound")
	if breakSound and breakSound:IsA("Sound") then
		breakSound:Play()
	end
	
	-- 2) Play procedural break effects (shatter)
	self:PlayBreakEffects()
	
	-- Roll and drop loot
	if self.LootBoxService then
		self.LootBoxService:RollAndDrop(self.Model)
	else
		-- Fallback: just destroy the crate
		self.Model:Destroy()
	end
	
	-- Unregister from systems
	if self.DamageService then
		self.DamageService:UnregisterDamageable(self.Model)
	end
	
	-- Remove the crate after effects
	BreakableCrate.ActiveCrates[self.Model] = nil
	if self.Model and self.Model.Parent then
		self.Model:Destroy()
	end
end

-- Play break effects
function BreakableCrate:PlayBreakEffects()
	local primaryPart = self.Model.PrimaryPart or self.Model:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then
		return
	end
	
	-- Simple shatter: spawn small shards that fly outwards briefly
	local shardCount = math.random(10, 16)
	for i = 1, shardCount do
		local shard = Instance.new("WedgePart")
		shard.Name = "Shard"
		shard.Size = Vector3.new(0.25 + math.random() * 0.25, 0.15 + math.random() * 0.2, 0.25 + math.random() * 0.25)
		shard.Material = primaryPart.Material
		shard.Color = primaryPart.Color
		shard.CanCollide = false
		shard.CanQuery = false
		shard.CanTouch = false
		shard.Anchored = false
		shard.CFrame = primaryPart.CFrame * CFrame.new(
			(math.random() - 0.5) * (primaryPart.Size.X * 0.4),
			(math.random() - 0.5) * (primaryPart.Size.Y * 0.4),
			(math.random() - 0.5) * (primaryPart.Size.Z * 0.4)
		) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
		shard.Parent = workspace
		
		-- Give it an outward impulse
		local dir = (shard.Position - primaryPart.Position).Unit
		local speed = 20 + math.random() * 25
		shard.AssemblyLinearVelocity = dir * speed + Vector3.new(0, 15 + math.random() * 10, 0)
		shard.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		
		Debris:AddItem(shard, 2)
	end
end

-- Static method to register all existing crates in workspace
function BreakableCrate.RegisterExistingCrates(lootBoxService, damageService)
	local registeredByType = {}
	
	-- Look for models with CrateType attribute
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("CrateType") then
			local crateType = descendant:GetAttribute("CrateType")
			BreakableCrate:RegisterCrate(descendant, lootBoxService, damageService)
			registeredByType[crateType] = (registeredByType[crateType] or 0) + 1
		end
	end
	
	local total = 0
	for crateType, count in pairs(registeredByType) do
		print(string.format("[BreakableCrate] Registered %d %s crates", count, crateType))
		total = total + count
	end
	
	return total
end

-- Static method to clear all crates
function BreakableCrate.ClearAll()
	for crateModel, component in pairs(BreakableCrate.ActiveCrates) do
		if crateModel and crateModel.Parent then
			crateModel:Destroy()
		end
	end
	
	BreakableCrate.ActiveCrates = {}
end

return BreakableCrate
