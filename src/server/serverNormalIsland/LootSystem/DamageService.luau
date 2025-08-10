--[[
	DamageService
	Centralized damage handling for all damageable objects including crates
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("sharedNormalIsland"):WaitForChild("LootSystem")
local LootConfig = require(SharedModules:WaitForChild("LootConfig"))

local DamageService = {}
DamageService.__index = DamageService

function DamageService.new()
	local self = setmetatable({}, DamageService)
	
	-- Registry of damageable objects
	self.DamageableRegistry = {}
	
	-- Damage type definitions
	self.DamageTypes = {
		MELEE = "Melee",
		BULLET = "Bullet",
		EXPLOSIVE = "Explosive",
		ENVIRONMENTAL = "Environmental",
	}
	
	return self
end

-- Register a damageable object
function DamageService:RegisterDamageable(object: Instance, handler: (number, any) -> ())
	if not object then
		warn("Cannot register nil object as damageable")
		return
	end
	
	self.DamageableRegistry[object] = {
		handler = handler,
		lastDamageTime = 0,
	}
	
	-- Clean up when object is destroyed
	object.AncestryChanged:Connect(function()
		if not object.Parent then
			self.DamageableRegistry[object] = nil
		end
	end)
end

-- Unregister a damageable object
function DamageService:UnregisterDamageable(object: Instance)
	self.DamageableRegistry[object] = nil
end

-- Apply damage to an object
function DamageService:ApplyDamage(target: Instance, amount: number, source: any?, damageType: string?)
	-- Validate target
	local registryEntry = self.DamageableRegistry[target]
	if not registryEntry then
		return false -- Target not damageable
	end
	
	-- Validate amount
	if amount <= 0 then
		return false
	end
	
	-- Apply damage type modifiers for crates
	if target:GetAttribute("CrateType") then
		amount = self:ApplyCrateDamageModifiers(target, amount, damageType)
	end
	
	-- Rate limiting (prevent damage spam)
	local currentTime = tick()
	if currentTime - registryEntry.lastDamageTime < 0.1 then
		return false -- Too soon since last damage
	end
	registryEntry.lastDamageTime = currentTime
	
	-- Call the damage handler
	if registryEntry.handler then
		registryEntry.handler(amount, source)
		
		if LootConfig.DEBUG_MODE then
			print(string.format("Applied %d damage to %s (type: %s)", 
				amount, target.Name, damageType or "Unknown"))
		end
		
		return true
	end
	
	return false
end

-- Apply crate-specific damage modifiers
function DamageService:ApplyCrateDamageModifiers(crate: Instance, baseDamage: number, damageType: string?): number
	local crateType = crate:GetAttribute("CrateType")
	if not crateType then
		return baseDamage
	end
	
	local crateConfig = LootConfig.GetCrateConfig(crateType)
	if not crateConfig or not crateConfig.DamageResistance then
		return baseDamage
	end
	
	-- Apply resistance multiplier
	local resistance = crateConfig.DamageResistance[damageType or "Default"] or 1.0
	local modifiedDamage = math.floor(baseDamage * resistance)
	
	if LootConfig.DEBUG_MODE and resistance ~= 1.0 then
		print(string.format("Damage modified by %.1fx resistance: %d -> %d", 
			resistance, baseDamage, modifiedDamage))
	end
	
	return modifiedDamage
end

-- Handle projectile hit
function DamageService:HandleProjectileHit(hit: BasePart, projectileData: any)
	-- Find the model that was hit
	local targetModel = hit:FindFirstAncestorOfClass("Model")
	if not targetModel then
		return false
	end
	
	-- Check if it's registered as damageable
	if self.DamageableRegistry[targetModel] then
		local damage = projectileData.damage or 10
		local damageType = projectileData.damageType or self.DamageTypes.BULLET
		
		return self:ApplyDamage(targetModel, damage, projectileData.source, damageType)
	end
	
	return false
end

-- Handle explosion damage (area of effect)
function DamageService:HandleExplosion(position: Vector3, radius: number, damage: number, source: any?)
	local damageApplied = {}
	
	-- Find all parts in radius
	local region = Region3.new(
		position - Vector3.new(radius, radius, radius),
		position + Vector3.new(radius, radius, radius)
	)
	region = region:ExpandToGrid(4)
	
	local parts = Workspace:FindPartsInRegion3(region, nil, math.huge)
	
	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		
		if model and self.DamageableRegistry[model] and not damageApplied[model] then
			local distance = (model:GetPivot().Position - position).Magnitude
			
			if distance <= radius then
				-- Calculate falloff damage
				local falloff = 1 - (distance / radius)
				local finalDamage = math.floor(damage * falloff)
				
				if finalDamage > 0 then
					self:ApplyDamage(model, finalDamage, source, self.DamageTypes.EXPLOSIVE)
					damageApplied[model] = true
				end
			end
		end
	end
	
	return damageApplied
end

-- Handle melee damage
function DamageService:HandleMeleeHit(attacker: Player, target: Instance, damage: number)
	if not target then
		return false
	end
	
	-- Find the model that was hit
	local targetModel = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
	if not targetModel then
		return false
	end
	
	return self:ApplyDamage(targetModel, damage, attacker, self.DamageTypes.MELEE)
end

-- Get all damageable objects in radius
function DamageService:GetDamageablesInRadius(position: Vector3, radius: number): {Instance}
	local results = {}
	
	for object, _ in pairs(self.DamageableRegistry) do
		if object and object.Parent then
			local objectPos = object:IsA("Model") and object:GetPivot().Position or object.Position
			local distance = (objectPos - position).Magnitude
			
			if distance <= radius then
				table.insert(results, object)
			end
		end
	end
	
	return results
end

-- Clear all registrations (for round reset)
function DamageService:ClearRegistry()
	self.DamageableRegistry = {}
end

-- Create singleton instance
local instance = DamageService.new()

return instance
