--!strict
local InventoryService = require(script.Parent.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))

local CONTAINERS = { inventory = true, equipment = true, quickuse = true, stash = true }
local EQUIPMENT_SLOTS = { "Backpack", "Armor", "Weapon1", "Weapon2" }

local function normalizeEquipmentSlot(s: string): string?
	local key = s and (s:gsub("^%s+", ""):gsub("%s+$", ""))
	if not key or key == "" then return nil end
	for _, slot in ipairs(EQUIPMENT_SLOTS) do
		if key:lower() == slot:lower() then
			return slot
		end
	end
	return nil
end

return function(context, container: string, slotRaw: string, target: Player?)
	if not CONTAINERS[container] then
		return "Invalid container. Use: backpack, equipment, quickuse, or stash."
	end
	local player = target or context.Executor

	local slot: number | string
	if container == "equipment" then
		local es = normalizeEquipmentSlot(slotRaw)
		if not es then
			return "Invalid equipment slot. Use: Backpack, Armor, Weapon1, or Weapon2."
		end
		slot = es
	else
		local n = tonumber(slotRaw and slotRaw:gsub("^%s+", ""):gsub("%s+$", ""))
		if not n or n < 1 or n ~= math.floor(n) then
			return "Slot must be a positive integer (e.g. 1, 5)."
		end
		slot = n
	end

	local ok = InventoryService.RemoveItemAt(player, container :: "inventory" | "equipment" | "quickuse" | "stash", slot)
	if not ok then
		return "No item in that slot, or invalid slot."
	end
	local label = if container == "inventory" then "backpack" else container
	return ("Removed item from %s slot %s for %s."):format(label, tostring(slot), player.Name)
end
