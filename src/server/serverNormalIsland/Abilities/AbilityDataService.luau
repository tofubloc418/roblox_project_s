--!strict
-- abilityPresets[presetKey]: five slots; stored with string keys "1".."5". Batch updates via TryApplyPresetOperations.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceBootstrap = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataServiceBootstrap"))
local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))

local DataService = DataServiceBootstrap.GetDataService() :: any

type AbilityPresetsData = InventoryTypes.AbilityPresetsData
type SerializedPreset = InventoryTypes.SerializedPreset
type SerializedPresetSlot = InventoryTypes.SerializedPresetSlot

export type PresetOperation = {
	presetKey: string,
	slotIndex: number,
	abilityId: string?,
}

local function waitForProfile(player: Player): boolean
	-- Match InventoryService /dev data: yield until profile is ready (path-based get can fail if we only check hasProfile).
	DataServiceBootstrap.WaitForPlayerData(player)
	return true
end

local function rawGetAbilityPresets(player: Player): AbilityPresetsData?
	local ds: any = DataService
	local pathGet: any = nil
	if type(ds.get) == "function" then
		pathGet = ds:get(player, { "abilityPresets" })
	elseif type(ds.Get) == "function" then
		pathGet = ds:Get(player, { "abilityPresets" })
	end
	if type(pathGet) == "table" then
		return pathGet :: AbilityPresetsData?
	end
	local root: any = nil
	if type(ds.get) == "function" then
		root = ds:get(player, {})
	elseif type(ds.Get) == "function" then
		root = ds:Get(player, {})
	end
	if type(root) == "table" and type(root.abilityPresets) == "table" then
		return root.abilityPresets :: AbilityPresetsData?
	end
	return nil
end

local function setAtPath(player: Player, path: { string }, value: any)
	DataService:set(player, path, value)
end

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

local MAX_PRESET_SLOTS = 5
local MAX_ULTIMATE_PER_PRESET = 1

type WorkingPreset = { [number]: SerializedPresetSlot? }

local function loadWorkingFromRaw(raw: any): WorkingPreset
	local w: WorkingPreset = {}
	for i = 1, MAX_PRESET_SLOTS do
		local row = InventoryTypes.getSlotItem(raw, i)
		if row and type(row) == "table" and type(row.aid) == "string" and row.aid ~= "" then
			w[i] = ({
				aid = row.aid,
				ult = if row.ult == true then true else nil,
			}) :: SerializedPresetSlot
		end
	end
	return w
end

local function countUltimatesWorking(w: WorkingPreset): number
	local n = 0
	for i = 1, MAX_PRESET_SLOTS do
		local slot = w[i]
		if slot and slot.ult then
			n += 1
		end
	end
	return n
end

local function workingToStoredPreset(w: WorkingPreset): SerializedPreset
	local out: any = {}
	for i = 1, MAX_PRESET_SLOTS do
		local s = w[i]
		if s then
			out[tostring(i)] = ({
				aid = s.aid,
				ult = if s.ult == true then true else nil,
			}) :: SerializedPresetSlot
		end
	end
	return out
end

local function validateWorkingPreset(presetKey: string, w: WorkingPreset): string?
	local seenAid: { [string]: boolean } = {}
	for i = 1, MAX_PRESET_SLOTS do
		local slot = w[i]
		if not slot then
			continue
		end
		local aid = slot.aid
		local config = AbilityRegistry.GetAbility(aid)
		if not config then
			return string.format("Unknown ability '%s'.", aid)
		end
		if not table.find(config.compatibleTags, presetKey) then
			return string.format("'%s' is not compatible with '%s'.", aid, presetKey)
		end
		if seenAid[aid] then
			return string.format("Preset '%s' cannot include the same ability more than once ('%s').", presetKey, aid)
		end
		seenAid[aid] = true
	end
	if countUltimatesWorking(w) > MAX_ULTIMATE_PER_PRESET then
		return string.format("Preset '%s' can only have one ultimate ability.", presetKey)
	end
	return nil
end

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

-- Validates full result (compatibleTags + one ultimate per preset), then writes; no partial commit.
function AbilityDataService.TryApplyPresetOperations(player: Player, operations: { PresetOperation }): (boolean, string?)
	if not getAbilityPresets(player) then
		return false, "Data not loaded."
	end
	local presetsAny = rawGetAbilityPresets(player)
	if type(presetsAny) ~= "table" then
		return false, "Data not loaded."
	end
	if type(operations) ~= "table" or #operations == 0 then
		return false, "Invalid request."
	end

	local touchedKeys: { [string]: boolean } = {}
	for _, op in ipairs(operations) do
		if type(op) ~= "table" then
			return false, "Invalid request."
		end
		if type((op :: any).presetKey) ~= "string" or #(op :: any).presetKey == 0 then
			return false, "Invalid preset."
		end
		local si = (op :: any).slotIndex
		if type(si) ~= "number" or si < 1 or si > MAX_PRESET_SLOTS then
			return false, "Invalid slot."
		end
		touchedKeys[(op :: any).presetKey] = true
	end

	local work: { [string]: WorkingPreset } = {}
	for key in pairs(touchedKeys) do
		work[key] = loadWorkingFromRaw((presetsAny :: any)[key])
	end

	for _, op in ipairs(operations) do
		local pk = (op :: any).presetKey :: string
		local si = (op :: any).slotIndex :: number
		local aid = (op :: any).abilityId
		if aid ~= nil and (type(aid) ~= "string" or #aid == 0) then
			return false, "Invalid ability."
		end
		local w = work[pk]
		if not w then
			return false, "Invalid preset."
		end
		if aid == nil then
			w[si] = nil
		else
			local cfg = AbilityRegistry.GetAbility(aid)
			if not cfg then
				return false, string.format("Unknown ability '%s'.", aid)
			end
			w[si] = ({
				aid = aid,
				ult = cfg.isUltimate == true and true or nil,
			}) :: SerializedPresetSlot
		end
	end

	for key in pairs(touchedKeys) do
		local err = validateWorkingPreset(key, work[key])
		if err then
			return false, err
		end
	end

	for key in pairs(touchedKeys) do
		setAbilityPresetKey(player, key, workingToStoredPreset(work[key]))
	end
	return true, nil
end

function AbilityDataService.SetPresetSlot(
	player: Player,
	presetKey: string,
	slotIndex: number,
	abilityId: string?
): boolean
	local ok = AbilityDataService.TryApplyPresetOperations(player, {
		{
			presetKey = presetKey,
			slotIndex = slotIndex,
			abilityId = abilityId,
		} :: PresetOperation,
	})
	return ok
end

function AbilityDataService.ClearPreset(player: Player, presetKey: string)
	if type(presetKey) ~= "string" then
		return
	end
	setAbilityPresetKey(player, presetKey, {})
end

function AbilityDataService.Initialize()
	local remoteFolder = ReplicatedStorage:WaitForChild("InventoryRemotes")
	local requestApplyOps = remoteFolder:WaitForChild("RequestApplyAbilityPresetOps") :: RemoteFunction

	local existingBf = remoteFolder:FindFirstChild("ApplyAbilityPresetOpsBindable")
	if existingBf and not existingBf:IsA("BindableFunction") then
		existingBf:Destroy()
		existingBf = nil
	end
	local applyBindable = if existingBf
		then existingBf :: BindableFunction
		else (function()
			local bf = Instance.new("BindableFunction")
			bf.Name = "ApplyAbilityPresetOpsBindable"
			bf.Parent = remoteFolder
			return bf
		end)()

	local function normalizePresetOperations(ops: any): ({ PresetOperation }, string?)
		if type(ops) ~= "table" then
			return {}, "Invalid request."
		end
		local normalized: { PresetOperation } = {}
		for _, op in ipairs(ops) do
			if type(op) ~= "table" then
				return {}, "Invalid request."
			end
			local pk = op.presetKey
			local si = op.slotIndex
			local aid = op.abilityId
			if type(pk) ~= "string" or type(si) ~= "number" then
				return {}, "Invalid request."
			end
			if aid ~= nil and type(aid) ~= "string" then
				return {}, "Invalid request."
			end
			table.insert(normalized, {
				presetKey = pk,
				slotIndex = si,
				abilityId = aid,
			})
		end
		return normalized, nil
	end

	applyBindable.OnInvoke = function(player: Player, ops: any): any
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return { ok = false, error = "Invalid player." }
		end
		local normalized, normErr = normalizePresetOperations(ops)
		if normErr then
			return { ok = false, error = normErr }
		end
		local ok, err = AbilityDataService.TryApplyPresetOperations(player, normalized)
		return { ok = ok, error = err }
	end

	requestApplyOps.OnServerInvoke = function(player: Player, ops: any): any
		if type(ops) ~= "table" then
			return { ok = false, error = "Invalid request." }
		end
		local normalized, normErr = normalizePresetOperations(ops)
		if normErr then
			return { ok = false, error = normErr }
		end
		local ok, err = AbilityDataService.TryApplyPresetOperations(player, normalized)
		if ok then
			return { ok = true }
		end
		return { ok = false, error = err or "Failed." }
	end
end

return AbilityDataService
