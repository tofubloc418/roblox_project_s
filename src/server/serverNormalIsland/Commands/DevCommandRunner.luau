--!strict
-- Shared dev command logic; returns { lines, isWarning } for Cmdr server handlers.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceBootstrap = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataServiceBootstrap"))
local InventoryService     = require(script.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
local AbilityDataService   = require(script.Parent.Parent:WaitForChild("Abilities"):WaitForChild("AbilityDataService"))
local AbilityRegistry      = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry"))
local InventoryTypes       = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes")) :: any
local ItemRegistry         = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))

export type Result = { lines: { string }, isWarning: boolean }

local function resolveTarget(sender: Player, args: { string }, argIndex: number?): Player?
	local idx  = argIndex or 1
	local name = args[idx]
	if name and name ~= "" then
		local p = Players:FindFirstChild(name)
		if not p then return nil end
		return p :: Player
	end
	return sender
end

local function errResult(msg: string): Result
	return { lines = { "[Dev] ⚠ " .. msg }, isWarning = true }
end

local function okResult(...: string): Result
	return { lines = { ... }, isWarning = false }
end

function runGive(sender: Player, args: { string }): Result
	local target: Player?
	local templateId: string
	local count: number

	local firstArg = args[1]
	local maybePlayer = firstArg and firstArg ~= "" and Players:FindFirstChild(firstArg)
	if maybePlayer then
		target = maybePlayer :: Player
		templateId = args[2] or ""
		count = tonumber(args[3]) or 1
	else
		target = sender
		templateId = firstArg or ""
		count = tonumber(args[2]) or 1
	end

	if not templateId or templateId == "" then
		return errResult("Usage: /give [player] <templateId> [count]  •  Use /items to browse IDs.")
	end

	local template = ItemRegistry.GetTemplate(templateId)
	if not template then
		return errResult(string.format("'%s' is not a registered item. Use /items to browse.", templateId))
	end

	local canonicalId = template.templateId
	local item, added = InventoryService.AddItem(target :: Player, canonicalId, count)
	if not item then
		return errResult("AddItem returned nil — inventory may be full.")
	end

	local who = target == sender and "yourself" or (target :: Player).Name
	if added < count then
		return okResult(string.format("[Dev] Gave %d × %s to %s (requested %d; inventory full)  (iid: %s)", added, canonicalId, who, count, item.iid))
	end
	return okResult(string.format("[Dev] Gave %d × %s to %s  (iid: %s)", added, canonicalId, who, item.iid))
end

function runItems(sender: Player, args: { string }): Result
	local rawFilter = args[1]
	local lfilter   = rawFilter and string.lower(rawFilter) or nil
	local all       = ItemRegistry.GetAll()

	local result: { { id: string, name: string, cat: string } } = {}
	for id, template in pairs(all) do
		local lid  = string.lower(id)
		local lnam = string.lower(template.displayName or "")
		local lcat = string.lower(template.category or "")
		if not lfilter
			or string.find(lid,  lfilter, 1, true)
			or string.find(lnam, lfilter, 1, true)
			or string.find(lcat, lfilter, 1, true)
		then
			table.insert(result, {
				id   = id,
				name = template.displayName or id,
				cat  = template.category or "?",
			})
		end
	end
	table.sort(result, function(a, b) return a.id < b.id end)

	local header = string.format(
		"[Dev] %d item(s)%s:",
		#result,
		lfilter and string.format(' matching "%s"', rawFilter) or ""
	)
	local lines: { string } = { header }
	for _, entry in ipairs(result) do
		table.insert(lines, string.format("  %-32s  [%s]  %s", entry.id, entry.cat, entry.name))
	end
	return { lines = lines, isWarning = false }
end

function runData(sender: Player, args: { string }): Result
	local target = resolveTarget(sender, args)
	if not target then
		return errResult(string.format("Player '%s' not found.", args[1] or ""))
	end

	local ds   = DataServiceBootstrap.GetDataService()
	local data = ds:get(target, {})

	if type(data) ~= "table" then
		return errResult(string.format("No data found for '%s'.", target.Name))
	end

	local lines: { string } = { string.format("[Dev] Raw data for '%s':", target.Name) }
	for k, v in pairs(data) do
		if type(v) == "table" then
			table.insert(lines, "  [" .. tostring(k) .. "] = (table)")
			if k == "inventory" and type(v.slots) == "table" then
				local c = 0
				for _ in pairs(v.slots) do c += 1 end
				table.insert(lines, "    slots: " .. tostring(c) .. " item(s)")
			end
		else
			table.insert(lines, "  [" .. tostring(k) .. "] = " .. tostring(v))
		end
	end
	return { lines = lines, isWarning = false }
end

function runInvreport(sender: Player, args: { string }): Result
	local target = resolveTarget(sender, args)
	if not target then
		return errResult(string.format("Player '%s' not found.", args[1] or ""))
	end

	local ds = DataServiceBootstrap.GetDataService()
	local data = (type(ds.get) == "function" and ds:get(target, {})) or (type(ds.Get) == "function" and ds:Get(target, {})) or nil
	if type(data) ~= "table" then
		return errResult(string.format("No data found for '%s'.", target.Name))
	end

	local inventory = type(data.inventory) == "table" and data.inventory or nil
	local equipment = type(data.equipment) == "table" and data.equipment or nil
	local quickUse  = type(data.quickUse)  == "table" and data.quickUse  or nil
	local stash     = type(data.stash)     == "table" and data.stash     or nil

	if not inventory and not equipment and not quickUse and not stash then
		return errResult(string.format("No inventory data found for '%s'.", target.Name))
	end

	local function formatItemLine(prefix: string, slotLabel: string, item: any): string
		if not item or type(item) ~= "table" then
			return string.format("%s %s: (empty)", prefix, slotLabel)
		end
		local tid = tostring(item.tid)
		local cnt = tonumber(item.cnt) or 1
		return string.format("%s %s: %s x%d", prefix, slotLabel, tid, cnt)
	end

	local lines: { string } = {}
	table.insert(lines, string.format("[Dev] Inventory report for '%s':", target.Name))

	table.insert(lines, "  [LOADOUT / EQUIPMENT]")
	if equipment then
		table.insert(lines, formatItemLine("    ", "Backpack", equipment.Backpack))
		table.insert(lines, formatItemLine("    ", "Armor",    equipment.Armor))
		table.insert(lines, formatItemLine("    ", "Weapon1",  equipment.Weapon1))
		table.insert(lines, formatItemLine("    ", "Weapon2",  equipment.Weapon2))
	else
		table.insert(lines, "    (no equipment data)")
	end

	table.insert(lines, "  [BACKPACK]")
	if inventory and type(inventory.slots) == "table" then
		for slot = 1, inventory.maxSlots or 0 do
			local item = InventoryTypes.getSlotItem(inventory.slots, slot)
			table.insert(lines, formatItemLine("    ", "Slot " .. tostring(slot), item))
		end
	else
		table.insert(lines, "    (no backpack data)")
	end

	table.insert(lines, "  [QUICK SLOTS]")
	if quickUse and type(quickUse.slots) == "table" then
		for slot = 1, 8 do
			local item = InventoryTypes.getSlotItem(quickUse.slots, slot)
			table.insert(lines, formatItemLine("    ", "Slot " .. tostring(slot), item))
		end
	else
		table.insert(lines, "    (no quick slot data)")
	end

	table.insert(lines, "  [STASH]")
	if stash and type(stash.slots) == "table" then
		for slot = 1, stash.maxSlots or 0 do
			local item = InventoryTypes.getSlotItem(stash.slots, slot)
			table.insert(lines, formatItemLine("    ", "Slot " .. tostring(slot), item))
		end
	else
		table.insert(lines, "    (no stash data)")
	end

	return { lines = lines, isWarning = false }
end

local MAX_ULTIMATE_PER_PRESET = 1

local function countUltimatesInPreset(preset: { [any]: any }): number
	local n = 0
	for _, slot in pairs(preset) do
		if type(slot) == "table" and slot.ult then
			n += 1
		end
	end
	return n
end

function runAbilityPresets(sender: Player, args: { string }): Result
	local target = resolveTarget(sender, args)
	if not target then
		return errResult(string.format("Player '%s' not found.", args[1] or ""))
	end

	local presets = AbilityDataService.GetAbilityPresets(target)
	if presets == nil then
		return errResult(string.format("No ability preset data loaded for '%s'.", target.Name))
	end

	local keys: { string } = {}
	for k in pairs(presets) do
		if type(k) == "string" then
			table.insert(keys, k)
		end
	end
	table.sort(keys)

	if #keys == 0 then
		return okResult(string.format("[Dev] No ability presets stored for '%s'.", target.Name))
	end

	local lines: { string } = { string.format("[Dev] Ability presets for '%s':", target.Name) }
	for _, presetKey in ipairs(keys) do
		local preset = presets[presetKey]
		if type(preset) ~= "table" then
			table.insert(lines, string.format("  [%s]: (invalid)", presetKey))
		else
			local parts: { string } = {}
			for slot = 1, 5 do
				local slotData = InventoryTypes.getSlotItem(preset, slot)
				if slotData and type(slotData) == "table" and type(slotData.aid) == "string" then
					local ult = slotData.ult and " ult" or ""
					table.insert(parts, string.format("%d=%s%s", slot, slotData.aid, ult))
				else
					table.insert(parts, string.format("%d=(empty)", slot))
				end
			end
			table.insert(lines, string.format("  [%s]: %s", presetKey, table.concat(parts, ", ")))
		end
	end
	return { lines = lines, isWarning = false }
end

function runSetAbilityPreset(
	sender: Player,
	abilityId: string,
	weaponTag: string,
	slotIndex: number,
	target: Player?
): Result
	local who = target or sender
	local config = AbilityRegistry.GetAbility(abilityId)
	if not config then
		return errResult(string.format("Unknown ability '%s'.", abilityId))
	end
	if not table.find(config.compatibleTags, weaponTag) then
		return errResult(
			string.format(
				"Ability '%s' is not compatible with weapon tag '%s' (allowed: %s).",
				abilityId,
				weaponTag,
				table.concat(config.compatibleTags, ", ")
			)
		)
	end

	local preset = AbilityDataService.GetPresetForKey(who, weaponTag)
	local isUlt = config.isUltimate == true
	if isUlt then
		local existing = InventoryTypes.getSlotItem(preset, slotIndex)
		local alreadyUlt = type(existing) == "table" and existing.ult == true
		if not alreadyUlt and countUltimatesInPreset(preset) >= MAX_ULTIMATE_PER_PRESET then
			return errResult(
				string.format(
					"Preset '%s' already has an ultimate in another slot; clear it or replace the existing ultimate slot.",
					weaponTag
				)
			)
		end
	end

	local ok = AbilityDataService.SetPresetSlot(who, weaponTag, slotIndex, abilityId)
	if not ok then
		return errResult(string.format("Failed to set preset (data not loaded for '%s'?).", who.Name))
	end

	local label = who == sender and "your" or (who.Name .. "'s")
	return okResult(
		string.format(
			"[Dev] Set %s preset [%s] slot %d to %s%s.",
			label,
			weaponTag,
			slotIndex,
			abilityId,
			isUlt and " (ultimate)" or ""
		)
	)
end

function runRemoveAbilityPresetSlot(sender: Player, weaponTag: string, slotIndex: number, target: Player?): Result
	local who = target or sender
	local ok = AbilityDataService.SetPresetSlot(who, weaponTag, slotIndex, nil)
	if not ok then
		return errResult(string.format("Failed to clear slot (data not loaded for '%s'?).", who.Name))
	end
	local label = who == sender and "your" or (who.Name .. "'s")
	return okResult(string.format("[Dev] Cleared %s preset [%s] slot %d.", label, weaponTag, slotIndex))
end

function runSave(sender: Player, args: { string }): Result
	local target = resolveTarget(sender, args)
	if not target then
		return errResult(string.format("Player '%s' not found.", args[1] or ""))
	end

	local ds = DataServiceBootstrap.GetDataService()
	if type(ds.forceSave) == "function" then
		ds:forceSave(target)
		return okResult(string.format("[Dev] Saved data for '%s'.", target.Name))
	end
	return errResult("forceSave is not available on this DataService implementation.")
end

return {
	runGive = runGive,
	runItems = runItems,
	runData = runData,
	runInvreport = runInvreport,
	runSave = runSave,
	runAbilityPresets = runAbilityPresets,
	runSetAbilityPreset = runSetAbilityPreset,
	runRemoveAbilityPresetSlot = runRemoveAbilityPresetSlot,
}
