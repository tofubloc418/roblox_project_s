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
	local primaryPart = self.Model.PrimaryPart or self.Model:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then
		return
	end
	
	-- Ensure consistent container for generated visuals
	local overlayFolder = self.Model:FindFirstChild("CrackOverlays")
	if not overlayFolder then
		overlayFolder = Instance.new("Folder")
		overlayFolder.Name = "CrackOverlays"
		overlayFolder.Parent = self.Model
	end
	
	-- Clear previous overlays
	for _, child in ipairs(overlayFolder:GetChildren()) do
		child:Destroy()
	end
	
	-- Base visual: slight transparency proportional to damage
	local damageRatio = 1 - (self.Health / self.MaxHealth)
	primaryPart.Transparency = math.min(0.5, damageRatio * 0.5)
	
	-- Stage-driven generated imperfections
	local function createWeld(part)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = primaryPart
		weld.Part1 = part
		weld.Parent = part
	end
	
	local function addCrackLine(length: number)
		local line = Instance.new("Part")
		line.Name = "CrackLine"
		line.Anchored = false
		line.CanCollide = false
		line.CanQuery = false
		line.CanTouch = false
		line.Material = Enum.Material.SmoothPlastic
		line.Color = Color3.fromRGB(20, 20, 20)
		line.Transparency = 0.1
		line.Size = Vector3.new(length, 0.03, 0.03)
		line.Parent = overlayFolder
		
		-- Random position on a face of the primary part
		local size = primaryPart.Size
		local faceIndex = math.random(1, 6)
		local normalVecs = {
			Vector3.new(0, 1, 0),
			Vector3.new(0, -1, 0),
			Vector3.new(1, 0, 0),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 0, 1),
			Vector3.new(0, 0, -1),
		}
		local normal = normalVecs[faceIndex]
		
		local half = size * 0.5
		local localPos = Vector3.new(
			(math.random() - 0.5) * (size.X - 0.2),
			(math.random() - 0.5) * (size.Y - 0.2),
			(math.random() - 0.5) * (size.Z - 0.2)
		)
		-- Snap to chosen face by setting the coordinate along the normal to +/- half extent
		if normal.X ~= 0 then
			localPos = Vector3.new(math.sign(normal.X) * half.X + (0.01 * normal.X), localPos.Y, localPos.Z)
		elseif normal.Y ~= 0 then
			localPos = Vector3.new(localPos.X, math.sign(normal.Y) * half.Y + (0.01 * normal.Y), localPos.Z)
		else
			localPos = Vector3.new(localPos.X, localPos.Y, math.sign(normal.Z) * half.Z + (0.01 * normal.Z))
		end
		
		local worldPos = primaryPart.CFrame:PointToWorldSpace(localPos)
		local tangentA = (math.abs(normal.Y) == 1) and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
		local tangent = (tangentA:Cross(normal)).Unit
		local angle = math.random() * math.pi
		local dir = (tangent * math.cos(angle) + normal:Cross(tangent) * math.sin(angle)).Unit
		
		line.CFrame = CFrame.lookAt(worldPos, worldPos + dir) * CFrame.new(line.Size.X * -0.5, 0, 0)
		createWeld(line)
	end
	
	local function addChip()
		local chip = Instance.new("WedgePart")
		chip.Name = "Chip"
		chip.Anchored = false
		chip.CanCollide = false
		chip.CanQuery = false
		chip.CanTouch = false
		chip.Material = primaryPart.Material
		chip.Color = primaryPart.Color:lerp(Color3.new(1,1,1), 0.2)
		chip.Transparency = 0.1
		chip.Size = Vector3.new(0.2 + math.random() * 0.2, 0.1 + math.random() * 0.15, 0.2 + math.random() * 0.2)
		chip.Parent = overlayFolder
		
		local size = primaryPart.Size
		local faceIndex = math.random(1, 6)
		local normalVecs = {
			Vector3.new(0, 1, 0),
			Vector3.new(0, -1, 0),
			Vector3.new(1, 0, 0),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 0, 1),
			Vector3.new(0, 0, -1),
		}
		local normal = normalVecs[faceIndex]
		local half = size * 0.5
		local localPos = Vector3.new(
			(math.random() - 0.5) * (size.X - 0.2),
			(math.random() - 0.5) * (size.Y - 0.2),
			(math.random() - 0.5) * (size.Z - 0.2)
		)
		if normal.X ~= 0 then
			localPos = Vector3.new(math.sign(normal.X) * half.X + (0.01 * normal.X), localPos.Y, localPos.Z)
		elseif normal.Y ~= 0 then
			localPos = Vector3.new(localPos.X, math.sign(normal.Y) * half.Y + (0.01 * normal.Y), localPos.Z)
		else
			localPos = Vector3.new(localPos.X, localPos.Y, math.sign(normal.Z) * half.Z + (0.01 * normal.Z))
		end
		local worldPos = primaryPart.CFrame:PointToWorldSpace(localPos)
		chip.CFrame = CFrame.new(worldPos) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
		createWeld(chip)
	end
	
	if self.CrackStage == 0 then
		-- No overlays
	elseif self.CrackStage == 1 then
		for i = 1, math.random(4, 6) do
			addCrackLine(0.8 + math.random() * 2.0)
		end
	elseif self.CrackStage == 2 then
		for i = 1, math.random(10, 14) do
			addCrackLine(0.8 + math.random() * 2.5)
		end
		for i = 1, math.random(2, 4) do
			addChip()
		end
	end
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Updated crate overlays to stage %d (HP: %d/%d)", self.CrackStage, self.Health, self.MaxHealth))
	end
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
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Crate %s broken!", self.Model.Name))
	end
	
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
