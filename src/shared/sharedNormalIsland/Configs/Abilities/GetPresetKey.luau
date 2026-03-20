--!strict
-- Preset key resolution for ability loadouts.
-- Empty Weapon1/Weapon2 or Fists slot use "Unarmed". Otherwise use template.abilityPresetKey or template.weaponTag.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))

type StoredEquipmentData = InventoryTypes.StoredEquipmentData

local UNARMED_KEY = "Unarmed"

local GetPresetKey = {}

--[[
	GetPresetKeyForEquipmentSlot(equipment, slotId)
	Returns the ability preset key for a weapon slot (Weapon1 or Weapon2).
	Returns "Unarmed" if the slot is empty.
]]
function GetPresetKey.GetPresetKeyForEquipmentSlot(
	equipment: StoredEquipmentData,
	slotId: "Weapon1" | "Weapon2"
): string
	local item = equipment[slotId]
	if not item or not item.tid then
		return UNARMED_KEY
	end
	local template = ItemRegistry.GetTemplate(item.tid)
	if not template then
		return UNARMED_KEY
	end
	local key = (template :: any).abilityPresetKey or (template :: any).weaponTag
	return (type(key) == "string" and #key > 0) and key or UNARMED_KEY
end

--[[
	GetAbilityBarPresetKey(activeSlot, expandedWeapon, equipment)
	Returns the preset key for the HUD ability bar (current or last active weapon).
	- When activeSlot is Weapon1 or Weapon2, uses that slot's weapon (or Unarmed if empty).
	- When activeSlot is Fists or QuickUse, uses expandedWeapon (last active weapon slot) or Unarmed.
]]
function GetPresetKey.GetAbilityBarPresetKey(
	activeSlot: string,
	expandedWeapon: string?,
	equipment: StoredEquipmentData
): string
	if activeSlot == "Weapon1" then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon1")
	end
	if activeSlot == "Weapon2" then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon2")
	end
	-- Fists or QuickUse: show last active weapon's abilities
	if expandedWeapon == "Weapon1" or expandedWeapon == "Weapon2" then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, expandedWeapon :: "Weapon1" | "Weapon2")
	end
	return UNARMED_KEY
end

return GetPresetKey
