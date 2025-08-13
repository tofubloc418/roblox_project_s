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

	-- Minimal: directly call the handler with the raw amount
	-- Weapons will handle all damage math in the future.
	
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
