--!strict
-- Shared dev command logic; returns { lines, isWarning } for Cmdr server handlers.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceBootstrap = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataServiceBootstrap"))
local InventoryService     = require(script.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
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
}
