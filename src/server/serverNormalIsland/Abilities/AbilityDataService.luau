--!strict
-- AbilityDataService
-- Per-player ability preset slots (path: abilityPresets → presetKey → slots 1–5).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceBootstrap = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataServiceBootstrap"))
local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes")) :: any

local DataService = DataServiceBootstrap.GetDataService() :: any

type AbilityPresetsData = InventoryTypes.AbilityPresetsData
type SerializedPreset = InventoryTypes.SerializedPreset
type SerializedPresetSlot = InventoryTypes.SerializedPresetSlot

local function waitForProfile(player: Player): boolean
	if not DataService:hasProfile(player) then
		DataService:waitForData(player)
	end
	return true
end

local function rawGetAbilityPresets(player: Player): AbilityPresetsData?
	return DataService:get(player, { "abilityPresets" }) :: AbilityPresetsData?
end

local function setAtPath(player: Player, path: { string }, value: any)
	DataService:set(player, path, value)
end

-- Profile must be loaded; ensure `abilityPresets` exists as a table before nested writes.
local function getOrInitAbilityPresets(player: Player): AbilityPresetsData?
	waitForProfile(player)
	local presets = rawGetAbilityPresets(player)
	if presets == nil or type(presets) ~= "table" then
		setAtPath(player, { "abilityPresets" }, {})
		presets = rawGetAbilityPresets(player)
	end
	if type(presets) ~= "table" then
		return nil
	end
	return presets
end

local function getAbilityPresets(player: Player): AbilityPresetsData?
	return getOrInitAbilityPresets(player)
end

local function setAbilityPresetKey(player: Player, presetKey: string, preset: SerializedPreset)
	if not getOrInitAbilityPresets(player) then
		return
	end
	DataService:set(player, { "abilityPresets", presetKey }, preset)
end

-- ── Constants ─────────────────────────────────────────────────────────────────

local MAX_PRESET_SLOTS = 5
local MAX_ULTIMATE_PER_PRESET = 1

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function countUltimates(preset: SerializedPreset): number
	local n = 0
	for _, slot in pairs(preset) do
		if slot and slot.ult then
			n += 1
		end
	end
	return n
end

-- ── Public API ────────────────────────────────────────────────────────────────

local AbilityDataService = {}

function AbilityDataService.GetAbilityPresets(player: Player): AbilityPresetsData?
	return getAbilityPresets(player)
end

function AbilityDataService.GetPresetForKey(player: Player, presetKey: string): SerializedPreset
	local presets = getAbilityPresets(player)
	if not presets then
		return {}
	end
	return presets[presetKey] or {}
end

function AbilityDataService.SetPresetSlot(
	player: Player,
	presetKey: string,
	slotIndex: number,
	abilityId: string?
): boolean
	local presets = getAbilityPresets(player)
	if not presets then
		return false
	end

	if type(presetKey) ~= "string" or #presetKey == 0 then
		return false
	end
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > MAX_PRESET_SLOTS then
		return false
	end
	if abilityId ~= nil and (type(abilityId) ~= "string" or #abilityId == 0) then
		return false
	end

	local preset: SerializedPreset = {}
	for k, v in pairs(presets[presetKey] or {}) do
		preset[k] = v
	end

	if abilityId == nil then
		preset[slotIndex] = nil
		setAbilityPresetKey(player, presetKey, preset)
		return true
	end

	local config = AbilityRegistry.GetAbility(abilityId)
	if not config then
		return false
	end

	local isActuallyUltimate = config.isUltimate == true

	if isActuallyUltimate then
		local existingSlot = preset[slotIndex]
		local alreadyUlt = existingSlot and existingSlot.ult
		if not alreadyUlt then
			local ultCount = countUltimates(preset)
			if ultCount >= MAX_ULTIMATE_PER_PRESET then
				for i, slot in pairs(preset) do
					if slot and slot.ult then
						preset[i] = nil
						break
					end
				end
			end
		end
	end

	preset[slotIndex] = ({
		aid = abilityId,
		ult = isActuallyUltimate and true or nil,
	}) :: SerializedPresetSlot

	setAbilityPresetKey(player, presetKey, preset)
	return true
end

function AbilityDataService.ClearPreset(player: Player, presetKey: string)
	if type(presetKey) ~= "string" then
		return
	end
	setAbilityPresetKey(player, presetKey, {})
end

function AbilityDataService.Initialize()
	local remoteFolder = ReplicatedStorage:WaitForChild("InventoryRemotes")
	local requestSetPreset = remoteFolder:WaitForChild("RequestSetAbilityPreset") :: RemoteEvent

	requestSetPreset.OnServerEvent:Connect(function(
		player: Player,
		presetKey: any,
		slotIndex: any,
		abilityId: any
	)
		if type(presetKey) ~= "string" or type(slotIndex) ~= "number" then
			return
		end
		if abilityId ~= nil and type(abilityId) ~= "string" then
			return
		end
		AbilityDataService.SetPresetSlot(player, presetKey, slotIndex, abilityId)
	end)
end

return AbilityDataService
