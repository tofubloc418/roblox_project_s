--!strict
-- DevCommandHandler (Server)
-- Receives developer chat commands from DevCommands.client.luau, validates them,
-- executes server-side logic, and fires results back to the requesting client.
-- Restricted to Studio sessions to prevent use in production.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

if not RunService:IsStudio() then return end

-- ── Service references ────────────────────────────────────────────────────────
-- This script is at SSS/Commands/DevCommandHandler, so Parent.Parent = SSS root.

local DataServiceBootstrap = require(script.Parent.Parent:WaitForChild("Data"):WaitForChild("DataServiceBootstrap"))
local InventoryService     = require(script.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
local InventoryTypes       = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes")) :: any
local ItemRegistry         = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))

-- ── Remote setup ──────────────────────────────────────────────────────────────
-- This server script creates the DevRemotes folder and its events so that the
-- client can WaitForChild on them without a race condition.

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then return existing :: Folder end
	if existing then existing:Destroy() end
	local f      = Instance.new("Folder")
	f.Name       = name
	f.Parent     = parent
	return f
end

local function ensureRemote(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing :: RemoteEvent end
	if existing then existing:Destroy() end
	local r      = Instance.new("RemoteEvent")
	r.Name       = name
	r.Parent     = parent
	return r
end

local devRemotes          = ensureFolder(ReplicatedStorage, "DevRemotes")
local devCommandRemote    = ensureRemote(devRemotes, "DevCommand")       -- Client → Server
local devCommandResult    = ensureRemote(devRemotes, "DevCommandResult") -- Server → Client

-- ── Reply helpers ─────────────────────────────────────────────────────────────

local function reply(player: Player, lines: { string }, isWarning: boolean?)
	devCommandResult:FireClient(player, lines, isWarning == true)
end

local function replyOk(player: Player, ...: string)
	reply(player, { ... }, false)
end

local function replyErr(player: Player, msg: string)
	reply(player, { "[Dev] ⚠ " .. msg }, true)
end

-- Resolve a player by name, defaulting to the sender if no name is given.
local function resolveTarget(sender: Player, args: { string }, argIndex: number?): Player?
	local idx  = argIndex or 1
	local name = args[idx]
	if name and name ~= "" then
		local p = Players:FindFirstChild(name)
		if not p then
			replyErr(sender, string.format("Player '%s' not found.", name))
			return nil
		end
		return p :: Player
	end
	return sender
end

-- ── Command dispatcher ────────────────────────────────────────────────────────

devCommandRemote.OnServerEvent:Connect(function(sender: Player, command: any, args: any)
	-- Sanity-check inbound types.
	if type(command) ~= "string" then return end
	if type(args) ~= "table" then args = {} end

	-- ── /give <templateId> [count] ──────────────────────────────────────────
	if command == "give" then
		local templateId = args[1]
		local count      = tonumber(args[2]) or 1

		if not templateId or templateId == "" then
			replyErr(sender, "Usage: /give <templateId> [count]  •  Use /items to browse IDs.")
			return
		end

		local template = ItemRegistry.GetTemplate(templateId)
		if not template then
			replyErr(sender, string.format("'%s' is not a registered item. Use /items to browse.", templateId))
			return
		end

		local canonicalId = template.templateId
		local item = InventoryService.AddItem(sender, canonicalId, count)
		if item then
			replyOk(sender, string.format("[Dev] Gave %d × %s  (iid: %s)", count, canonicalId, item.iid))
		else
			replyErr(sender, "AddItem returned nil — inventory may be full.")
		end

	-- ── /items [filter] ─────────────────────────────────────────────────────
	elseif command == "items" then
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
		reply(sender, lines, false)

	-- ── /data [playerName] ──────────────────────────────────────────────────
	elseif command == "data" then
		local target = resolveTarget(sender, args)
		if not target then return end

		local ds   = DataServiceBootstrap.GetDataService()
		local data = ds:get(target, {})

		if type(data) == "table" then
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
			reply(sender, lines, false)
		else
			replyErr(sender, string.format("No data found for '%s'.", target.Name))
		end

	-- ── /invreport [playerName] ─────────────────────────────────────────────
	-- Reads from the server DataService (DataStore-backed profile), not from client or UI.
	elseif command == "invreport" then
		local target = resolveTarget(sender, args)
		if not target then return end

		local ds = DataServiceBootstrap.GetDataService()
		local data = (type(ds.get) == "function" and ds:get(target, {})) or (type(ds.Get) == "function" and ds:Get(target, {})) or nil
		if type(data) ~= "table" then
			replyErr(sender, string.format("No data found for '%s'.", target.Name))
			return
		end

		local inventory = type(data.inventory) == "table" and data.inventory or nil
		local equipment = type(data.equipment) == "table" and data.equipment or nil
		local quickUse  = type(data.quickUse)  == "table" and data.quickUse  or nil
		local stash     = type(data.stash)     == "table" and data.stash     or nil

		if not inventory and not equipment and not quickUse and not stash then
			replyErr(sender, string.format("No inventory data found for '%s'.", target.Name))
			return
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

		-- Equipment / loadout
		table.insert(lines, "  [LOADOUT / EQUIPMENT]")
		if equipment then
			table.insert(lines, formatItemLine("    ", "Backpack", equipment.Backpack))
			table.insert(lines, formatItemLine("    ", "Armor",    equipment.Armor))
			table.insert(lines, formatItemLine("    ", "Weapon1",  equipment.Weapon1))
			table.insert(lines, formatItemLine("    ", "Weapon2",  equipment.Weapon2))
		else
			table.insert(lines, "    (no equipment data)")
		end

		-- Inventory (backpack grid). Use getSlotItem so string keys from DataStore are read.
		table.insert(lines, "  [BACKPACK]")
		if inventory and type(inventory.slots) == "table" then
			for slot = 1, inventory.maxSlots or 0 do
				local item = InventoryTypes.getSlotItem(inventory.slots, slot)
				table.insert(lines, formatItemLine("    ", "Slot " .. tostring(slot), item))
			end
		else
			table.insert(lines, "    (no backpack data)")
		end

		-- Quick slots
		table.insert(lines, "  [QUICK SLOTS]")
		if quickUse and type(quickUse.slots) == "table" then
			for slot = 1, 8 do
				local item = InventoryTypes.getSlotItem(quickUse.slots, slot)
				table.insert(lines, formatItemLine("    ", "Slot " .. tostring(slot), item))
			end
		else
			table.insert(lines, "    (no quick slot data)")
		end

		-- Stash
		table.insert(lines, "  [STASH]")
		if stash and type(stash.slots) == "table" then
			for slot = 1, stash.maxSlots or 0 do
				local item = InventoryTypes.getSlotItem(stash.slots, slot)
				table.insert(lines, formatItemLine("    ", "Slot " .. tostring(slot), item))
			end
		else
			table.insert(lines, "    (no stash data)")
		end

		reply(sender, lines, false)

	-- ── /save [playerName] ──────────────────────────────────────────────────
	elseif command == "save" then
		local target = resolveTarget(sender, args)
		if not target then return end

		local ds = DataServiceBootstrap.GetDataService()
		if type(ds.forceSave) == "function" then
			ds:forceSave(target)
			replyOk(sender, string.format("[Dev] Saved data for '%s'.", target.Name))
		else
			replyErr(sender, "forceSave is not available on this DataService implementation.")
		end
	end
end)

print("[DevCommandHandler] Server command handler ready.")
