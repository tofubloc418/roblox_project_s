--!strict
-- Preset slot reads (getSlotItem) and AbilityRegistry-based visuals for HUD + Settings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes")) :: any

local AbilityPresetSlotUtils = {}

-- `presetKey_slot` with slot 1–5 only (e.g. Unique_Blade_3 → Unique_Blade, 3).
function AbilityPresetSlotUtils.parsePresetSlotId(slotId: string): (string?, number?)
	local presetKey, digit = string.match(slotId, "^(.+)_([1-5])$")
	if not presetKey or not digit then
		return nil, nil
	end
	return presetKey, tonumber(digit)
end

function AbilityPresetSlotUtils.readSlot(preset: { [any]: any }?, slotIndex: number): (string?, boolean)
	if not preset or type(preset) ~= "table" then
		return nil, false
	end
	local row = InventoryTypes.getSlotItem(preset, slotIndex)
	if not row or type(row) ~= "table" then
		return nil, false
	end
	local aid = type(row.aid) == "string" and row.aid ~= "" and row.aid or nil
	local isUlt = row.ult == true
	return aid, isUlt
end

export type ResolvedVisual = {
	iconId: string,
	displayName: string,
	hasIcon: boolean,
}

function AbilityPresetSlotUtils.resolveVisual(abilityId: string): ResolvedVisual
	local reg = AbilityRegistry.GetAbility(abilityId)
	if not reg then
		return {
			iconId = "",
			displayName = abilityId,
			hasIcon = false,
		}
	end
	local displayName = reg.displayName or reg.abilityId
	local iconId = type(reg.iconId) == "string" and reg.iconId or ""
	local hasIcon = iconId ~= "" and iconId ~= "rbxassetid://0"
	return {
		iconId = if hasIcon then iconId else "",
		displayName = displayName,
		hasIcon = hasIcon,
	}
end

return AbilityPresetSlotUtils
