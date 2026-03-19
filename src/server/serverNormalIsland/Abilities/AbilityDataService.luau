--!strict
-- AbilityDataService
-- Stores per-player ability presets (slot assignments) and provides compatibility
-- lookups for the ability UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceBootstrap = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataServiceBootstrap"))
local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))
local _ItemRegistry  = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))

local DataService = DataServiceBootstrap.GetDataService()

local function getAbilityPresets(player: Player): AbilityPresetsData?
	local ds = DataService
	if type(ds.get) == "function" then
		return ds.get(player, { "abilityPresets" }) :: AbilityPresetsData?
	end
	if type(ds.Get) == "function" then
		return ds.Get(player, { "abilityPresets" }) :: AbilityPresetsData?
	end
	return nil
end

local function setAbilityPresetKey(player: Player, presetKey: string, preset: SerializedPreset)
	local ds = DataService
	local path = { "abilityPresets", presetKey }
	if type(ds.set) == "function" then ds.set(player, path, preset); return end
	if type(ds.Set) == "function" then ds.Set(player, path, preset); return end
	if type((ds :: any).set) == "function" then (ds :: any):set(player, path, preset) end
end

type PlayerData         = InventoryTypes.PlayerData
type AbilityPresetsData = InventoryTypes.AbilityPresetsData
type SerializedPreset   = InventoryTypes.SerializedPreset
type SerializedPresetSlot = InventoryTypes.SerializedPresetSlot
type StoredEquipmentData = InventoryTypes.StoredEquipmentData

-- ── Constants ─────────────────────────────────────────────────────────────────

local MAX_PRESET_SLOTS     = 5  -- ability slots per weapon class (indices 1–5)
local MAX_ULTIMATE_PER_PRESET = 1  -- at most 1 ultimate per preset

-- ── Remote references (populated in Initialize) ───────────────────────────────

local _syncAbilityPresets:      RemoteEvent
local _requestSetAbilityPreset: RemoteEvent

-- ── Internal helpers ──────────────────────────────────────────────────────────

-- Count how many slots in a preset are flagged as ultimate.
local function countUltimates(preset: SerializedPreset): number
	local n = 0
	for _, slot in pairs(preset) do
		if slot and slot.ult then n += 1 end
	end
	return n
end

-- ── Public API ────────────────────────────────────────────────────────────────

local AbilityDataService = {}

-- Returns the player's full AbilityPresetsData (or nil if not loaded).
function AbilityDataService.GetAbilityPresets(player: Player): AbilityPresetsData?
	return getAbilityPresets(player)
end

-- Returns the SerializedPreset for a specific weapon tag / preset key.
function AbilityDataService.GetPresetForKey(player: Player, presetKey: string): SerializedPreset
	local presets = getAbilityPresets(player)
	if not presets then return {} end
	return presets[presetKey] or {}
end

-- Sets or clears one ability slot within a preset.
function AbilityDataService.SetPresetSlot(
	player: Player,
	presetKey: string,
	slotIndex: number,
	abilityId: string?,
	isUltimate: boolean?
): boolean

	local presets = getAbilityPresets(player)
	if not presets then return false end

	if type(presetKey) ~= "string" or #presetKey == 0 then return false end
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

	if isUltimate then
		local existingSlot = preset[slotIndex]
		local alreadyUlt   = existingSlot and existingSlot.ult
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
		ult = isUltimate and true or nil,
	}) :: SerializedPresetSlot

	setAbilityPresetKey(player, presetKey, preset)
	return true
end

-- Removes all ability assignments for a given preset key.
function AbilityDataService.ClearPreset(player: Player, presetKey: string)
	if type(presetKey) ~= "string" then return end
	setAbilityPresetKey(player, presetKey, {})
end

-- Returns all compatible abilities for a weapon tag.
function AbilityDataService.GetCompatibleAbilities(weaponTag: string): { AbilityRegistry.AbilityConfig }
	return AbilityRegistry.GetAbilitiesByCompatibleTag(weaponTag)
end

-- No-op (replication is automatic via dataService); kept for API compatibility.
function AbilityDataService.SyncAbilityPresets(_player: Player) end

-- ── Initialization ────────────────────────────────────────────────────────────

-- Hooks up RequestSetAbilityPreset (must run after InventoryService.Initialize()).
function AbilityDataService.Initialize()
	local remoteFolder = ReplicatedStorage:WaitForChild("InventoryRemotes")

	_syncAbilityPresets      = remoteFolder:WaitForChild("SyncAbilityPresets") :: RemoteEvent
	_requestSetAbilityPreset = remoteFolder:WaitForChild("RequestSetAbilityPreset") :: RemoteEvent

	-- Client requests a preset slot change.
	-- Arguments: presetKey (string), slotIndex (number), abilityId (string?), isUltimate (boolean?)
	_requestSetAbilityPreset.OnServerEvent:Connect(function(
		player: Player,
		presetKey: any,
		slotIndex: any,
		abilityId: any,
		isUltimate: any
	)
		if type(presetKey) ~= "string" or type(slotIndex) ~= "number" then return end
		if abilityId ~= nil and type(abilityId) ~= "string" then return end
		local ultimate: boolean? = if type(isUltimate) == "boolean" then isUltimate else nil
		AbilityDataService.SetPresetSlot(player, presetKey, slotIndex, abilityId, ultimate)
	end)
end

return AbilityDataService
