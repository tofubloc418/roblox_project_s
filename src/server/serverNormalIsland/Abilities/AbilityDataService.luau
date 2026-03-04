--!strict
-- AbilityDataService
-- Manages per-player ability preset data.
--
-- WHAT IT DOES:
--   - Stores ability loadouts in PlayerData.abilityPresets, keyed by weaponTag
--     (the single tag every WeaponTemplate carries, e.g. "Greatsword").
--   - Validates preset mutations: slot range, ultimate-slot cap, basic type checks.
--   - Syncs the full preset table to the client on load and on every change.
--   - Handles RequestSetAbilityPreset remote from the client.
--   - Provides GetCompatibleAbilities() for filtering abilities by weapon tag
--     (returns a list of AbilityConfig tables from ReplicatedStorage/Assets/Abilities/).
--
-- WHAT IT DOES NOT DO:
--   - No ability activation, cooldown tracking, or damage.
--   - No DataStore access — all persistence is via DataManager.
--   - No inventory mutations — reads EquipmentData to find active weapons but
--     never moves items.
--
-- PRESET KEY:
--   A preset key is the weapon's abilityPresetKey field (set by WeaponTemplate).
--   For class weapons: abilityPresetKey == weaponTag  (e.g. "Greatsword")
--   For unique weapons: abilityPresetKey == "Unique_<templateId>"
--   All weapons of the same class share one preset until the player modifies it.
--
-- TAG COMPATIBILITY:
--   weapon.weaponTag  : string  — one tag per weapon
--   ability.compatibleTags : {string} — ability is compatible if weapon's tag appears
--   Compatibility check: table.find(abilityConfig.compatibleTags, weapon.weaponTag) ~= nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager    = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataManager"))
local _ItemRegistry  = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

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

-- Return the AbilityConfig module for a given abilityId, or nil if not found.
-- Abilities live in ReplicatedStorage/Assets/Abilities/<abilityId>/AbilityConfig.
local function _getAbilityConfig(abilityId: string): any?
	local abilitiesFolder = ReplicatedStorage:FindFirstChild("Assets")
		and ReplicatedStorage.Assets:FindFirstChild("Abilities")
	if not abilitiesFolder then return nil end

	local abilityFolder = abilitiesFolder:FindFirstChild(abilityId)
	if not abilityFolder then return nil end

	local configModule = abilityFolder:FindFirstChild("AbilityConfig")
	if not configModule then return nil end

	local ok, config = pcall(require, configModule)
	return ok and config or nil
end

-- ── Public API ────────────────────────────────────────────────────────────────

local AbilityDataService = {}

--[[
	GetAbilityPresets(player)
	Returns the full AbilityPresetsData for the player.
	Returns nil if data is not loaded.
]]
function AbilityDataService.GetAbilityPresets(player: Player): AbilityPresetsData?
	local data = DataManager.GetPlayerData(player)
	return data and data.abilityPresets or nil
end

--[[
	GetPresetForKey(player, presetKey)
	Returns the SerializedPreset for a specific weapon tag / preset key.
	Returns an empty table (not nil) if no preset has been saved yet for that key.
]]
function AbilityDataService.GetPresetForKey(player: Player, presetKey: string): SerializedPreset
	local data = DataManager.GetPlayerData(player)
	if not data then return {} end
	return data.abilityPresets[presetKey] or {}
end

--[[
	SetPresetSlot(player, presetKey, slotIndex, abilityId?, isUltimate?)
	Sets or clears one ability slot within a preset.
	  - abilityId = nil  → clears the slot.
	  - isUltimate       → true for the ultimate ability slot.
	  - Enforces: slotIndex in [1, MAX_PRESET_SLOTS], max 1 ultimate.
	Returns true on success, false on validation failure.
]]
function AbilityDataService.SetPresetSlot(
	player: Player,
	presetKey: string,
	slotIndex: number,
	abilityId: string?,
	isUltimate: boolean?
): boolean

	local data = DataManager.GetPlayerData(player)
	if not data then return false end

	-- Validate inputs.
	if type(presetKey) ~= "string" or #presetKey == 0 then return false end
	if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > MAX_PRESET_SLOTS then
		return false
	end
	if abilityId ~= nil and (type(abilityId) ~= "string" or #abilityId == 0) then
		return false
	end

	-- Ensure preset table exists.
	if not data.abilityPresets[presetKey] then
		data.abilityPresets[presetKey] = {}
	end
	local preset = data.abilityPresets[presetKey]

	-- Clearing the slot.
	if abilityId == nil then
		preset[slotIndex] = nil
		DataManager.MarkDirty(player)
		AbilityDataService.SyncAbilityPresets(player)
		return true
	end

	-- Enforce ultimate cap: at most MAX_ULTIMATE_PER_PRESET per preset.
	if isUltimate then
		local existingSlot = preset[slotIndex]
		local alreadyUlt   = existingSlot and existingSlot.ult
		if not alreadyUlt then
			local ultCount = countUltimates(preset)
			if ultCount >= MAX_ULTIMATE_PER_PRESET then
				-- Evict the existing ultimate to make room.
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

	DataManager.MarkDirty(player)
	AbilityDataService.SyncAbilityPresets(player)
	return true
end

--[[
	ClearPreset(player, presetKey)
	Removes all ability assignments for a given weapon tag / preset key.
]]
function AbilityDataService.ClearPreset(player: Player, presetKey: string)
	local data = DataManager.GetPlayerData(player)
	if not data or type(presetKey) ~= "string" then return end
	data.abilityPresets[presetKey] = {}
	DataManager.MarkDirty(player)
	AbilityDataService.SyncAbilityPresets(player)
end

--[[
	GetCompatibleAbilities(weaponTag)
	Returns all AbilityConfig tables from ReplicatedStorage/Assets/Abilities/ whose
	compatibleTags list contains weaponTag.
	Returns an empty table until ability assets exist in that folder.
]]
function AbilityDataService.GetCompatibleAbilities(weaponTag: string): { any }
	local result: { any } = {}
	if type(weaponTag) ~= "string" or #weaponTag == 0 then return result end

	local abilitiesFolder = ReplicatedStorage:FindFirstChild("Assets")
		and (ReplicatedStorage.Assets :: any):FindFirstChild("Abilities")
	if not abilitiesFolder then return result end

	for _, abilityFolder in ipairs(abilitiesFolder:GetChildren()) do
		local configModule = abilityFolder:FindFirstChild("AbilityConfig")
		if configModule then
			local ok, config = pcall(require, configModule)
			if ok and type(config) == "table" and type(config.compatibleTags) == "table" then
				if table.find(config.compatibleTags, weaponTag) then
					table.insert(result, config)
				end
			end
		end
	end

	return result
end

--[[
	SyncAbilityPresets(player)
	Fires the SyncAbilityPresets RemoteEvent to the given player with their
	full AbilityPresetsData.
]]
function AbilityDataService.SyncAbilityPresets(player: Player)
	local data = DataManager.GetPlayerData(player)
	if not data then return end
	_syncAbilityPresets:FireClient(player, data.abilityPresets)
end

-- ── Initialization ────────────────────────────────────────────────────────────

--[[
	Initialize()
	Hooks up the RequestSetAbilityPreset remote from InventoryRemotes folder.
	Must be called AFTER InventoryService.Initialize() so the folder exists.
]]
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
