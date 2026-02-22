--[[
	DamageService (Minimal)
	
	Purpose: Provide a tiny, centralized entry-point to apply damage to registered
	objects during loot system testing. No combat helpers (projectiles, explosions,
	melee) are implemented here yet. Weapons will call ApplyDamage in the future.
	
	Scope: Registry + ApplyDamage only. No resistance math, no queries.
]]

local DamageService = {}
DamageService.__index = DamageService

function DamageService.new()
	local self = setmetatable({}, DamageService)
	
	-- Registry of damageable objects
	self.DamageableRegistry = {}
	
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
function DamageService:ApplyDamage(target: Instance, amount: number, source: any?)
	-- Check if it's a humanoid (direct damage)
	if target:IsA("Humanoid") then
		if amount <= 0 then return false end
		target:TakeDamage(amount)
		return true
	end
	
	-- Check if it's a Model with a Humanoid (for backwards compatibility)
	if target:IsA("Model") then
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if amount <= 0 then return false end
			humanoid:TakeDamage(amount)
			return true
		end
	end
	
	-- Check registry for custom damageable objects (like crates)
	local registryEntry = self.DamageableRegistry[target]
	if not registryEntry then
		return false -- Target not damageable
	end
	
	-- Validate amount
	if amount <= 0 then return false end
	
	-- Call the damage handler
	if registryEntry.handler then
		registryEntry.handler(amount, source)
		return true
	end
	
	return false
end

-- Clear all registrations (for round reset)
function DamageService:ClearRegistry()
	self.DamageableRegistry = {}
end

-- Create singleton instance
local instance = DamageService.new()

return instance
