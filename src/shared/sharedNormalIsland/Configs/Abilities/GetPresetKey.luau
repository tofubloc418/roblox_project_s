--!strict
-- Preset key resolution for ability loadouts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry")) :: any
local ItemEnums = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemEnums")) :: any
local _InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes")) :: any

type StoredEquipmentData = _InventoryTypes.StoredEquipmentData

local DEFAULT_PRESET_KEY = ItemEnums.WeaponTag.Fists

local GetPresetKey = {}

function GetPresetKey.GetPresetKeyForTemplateId(templateId: string): string
	local template = ItemRegistry.GetTemplate(templateId)
	if not template then
		return DEFAULT_PRESET_KEY
	end
	local key = (template :: any).abilityPresetKey or (template :: any).weaponTag
	return (type(key) == "string" and #key > 0) and key or DEFAULT_PRESET_KEY
end

--[[
	GetPresetKeyForEquipmentSlot(equipment, slotId)
	Returns the ability preset key for a weapon slot (Weapon1 or Weapon2).
	Returns DEFAULT_PRESET_KEY if the slot is empty.
]]
function GetPresetKey.GetPresetKeyForEquipmentSlot(
	equipment: StoredEquipmentData,
	slotId: "Weapon1" | "Weapon2"
): string
	local item = equipment[slotId]
	if not item or not item.tid then
		return DEFAULT_PRESET_KEY
	end
	return GetPresetKey.GetPresetKeyForTemplateId(item.tid)
end

--[[
	GetAbilityBarPresetKey(activeSlot, expandedWeapon, equipment)
	Returns the preset key for the HUD ability bar (current or last active weapon).
]]
function GetPresetKey.GetAbilityBarPresetKey(
	activeSlot: string,
	expandedWeapon: string?,
	equipment: StoredEquipmentData
): string
	if activeSlot == "Fists" then
		return GetPresetKey.GetPresetKeyForTemplateId("Fists")
	end
	if activeSlot == "Weapon1" then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon1")
	end
	if activeSlot == "Weapon2" then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon2")
	end
	if expandedWeapon == "Weapon1" or expandedWeapon == "Weapon2" then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, expandedWeapon :: "Weapon1" | "Weapon2")
	end
	return DEFAULT_PRESET_KEY
end

return GetPresetKey
