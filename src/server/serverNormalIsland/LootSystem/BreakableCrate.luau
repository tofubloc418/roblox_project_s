--[[
	BreakableCrate
	Component that handles crate damage, crack stages, and breaking
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Shared modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("sharedNormalIsland"):WaitForChild("LootSystem")
local LootConfig = require(SharedModules:WaitForChild("LootConfig"))

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
	
	-- Initialize crack visuals
	self:UpdateCrackVisuals()
	
	return self
end

-- Register a crate with the system
function BreakableCrate:RegisterCrate(crateModel: Model, lootBoxService, damageService)
	-- Check if already registered
	if BreakableCrate.ActiveCrates[crateModel] then
		return BreakableCrate.ActiveCrates[crateModel]
	end
	
	-- Create new component
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
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Registered breakable crate: %s (HP: %d)", 
			component.CrateType, component.MaxHealth))
	end
	
	return component
end

-- Take damage
function BreakableCrate:TakeDamage(damage: number, source: any?)
	if self.IsBroken then
		return
	end
	
	-- Apply damage
	local oldHealth = self.Health
	self.Health = math.max(0, self.Health - damage)
	self.Model:SetAttribute("Health", self.Health)
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Crate %s took %d damage (%d -> %d HP)", 
			self.Model.Name, damage, oldHealth, self.Health))
	end
	
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
	local visualConfig = LootConfig.GetVisualState(self.CrateType)
	
	-- Method 1: Toggle child model visibility
	local stageNames = {
		[0] = visualConfig.Stage0 or "Stage0",
		[1] = visualConfig.Stage1 or "Stage1_Cracked",
		[2] = visualConfig.Stage2 or "Stage2_Heavy",
	}
	
	-- Hide all stages first
	for stage, name in pairs(stageNames) do
		local stagePart = self.Model:FindFirstChild(name)
		if stagePart then
			if stagePart:IsA("BasePart") then
				stagePart.Transparency = stage == self.CrackStage and 0 or 1
			elseif stagePart:IsA("Model") then
				for _, part in ipairs(stagePart:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = stage == self.CrackStage and 0 or 1
					end
				end
			end
		end
	end
	
	-- If no stage models exist, try alternative methods
	if not self.Model:FindFirstChild(stageNames[0]) then
		-- Method 2: Adjust transparency based on damage
		local primaryPart = self.Model.PrimaryPart or self.Model:FindFirstChildWhichIsA("BasePart")
		if primaryPart then
			-- Make more transparent as damaged
			local damageRatio = 1 - (self.Health / self.MaxHealth)
			primaryPart.Transparency = math.min(0.5, damageRatio * 0.5)
			
			-- Add crack decal if possible (stub)
			if self.CrackStage > 0 and not primaryPart:FindFirstChild("CrackDecal") then
				if LootConfig.DEBUG_MODE then
					print(string.format("Would add crack decal stage %d to crate", self.CrackStage))
				end
			end
		end
		
		-- Log what visual update would happen
		if LootConfig.DEBUG_MODE then
			print(string.format("Updated crate visuals to stage %d (HP: %d/%d)", 
				self.CrackStage, self.Health, self.MaxHealth))
		end
	end
end

-- Play crack sound effect
function BreakableCrate:PlayCrackSound()
	-- TODO: Play crack sound effect
	if LootConfig.DEBUG_MODE then
		print("Would play crack SFX for stage:", self.CrackStage)
	end
	
	-- Stub implementation - create a sound object that would play
	local sound = Instance.new("Sound")
	sound.Name = "CrackSound"
	sound.Volume = 0.5
	sound.SoundId = "rbxasset://sounds/impact_water_low.mp3" -- Placeholder sound
	sound.Parent = self.Model.PrimaryPart or self.Model:FindFirstChildWhichIsA("BasePart")
	
	-- Don't actually play in stub
	if false then
		sound:Play()
		Debris:AddItem(sound, 2)
	end
end

-- Break the crate and drop loot
function BreakableCrate:Break(source: any?)
	if self.IsBroken then
		return
	end
	
	self.IsBroken = true
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Crate %s broken!", self.Model.Name))
	end
	
	-- Play break effects
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
	
	BreakableCrate.ActiveCrates[self.Model] = nil
end

-- Play break effects
function BreakableCrate:PlayBreakEffects()
	-- TODO: Play break sound effect
	if LootConfig.DEBUG_MODE then
		print("Would play break SFX and VFX")
	end
	
	-- Stub implementation - create effects that would play
	local primaryPart = self.Model.PrimaryPart or self.Model:FindFirstChildWhichIsA("BasePart")
	if primaryPart then
		-- Sound effect
		local sound = Instance.new("Sound")
		sound.Name = "BreakSound"
		sound.Volume = 1
		sound.SoundId = "rbxasset://sounds/impact_wood_low.mp3" -- Placeholder sound
		sound.Parent = primaryPart
		
		-- Particle effect (stub)
		local attachment = Instance.new("Attachment")
		attachment.Parent = primaryPart
		
		local particleEmitter = Instance.new("ParticleEmitter")
		particleEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		particleEmitter.Rate = 100
		particleEmitter.Lifetime = NumberRange.new(0.5, 1)
		particleEmitter.Speed = NumberRange.new(5, 10)
		particleEmitter.SpreadAngle = Vector2.new(45, 45)
		particleEmitter.Parent = attachment
		
		-- Don't actually play in stub
		if false then
			sound:Play()
			particleEmitter.Enabled = true
			task.wait(0.1)
			particleEmitter.Enabled = false
			Debris:AddItem(attachment, 2)
			Debris:AddItem(sound, 2)
		end
	end
end

-- Static method to register all existing crates in workspace
function BreakableCrate.RegisterExistingCrates(lootBoxService, damageService)
	local registeredCount = 0
	
	-- Look for models with CrateType attribute
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("CrateType") then
			BreakableCrate:RegisterCrate(descendant, lootBoxService, damageService)
			registeredCount = registeredCount + 1
		end
	end
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Registered %d existing crates", registeredCount))
	end
	
	return registeredCount
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
