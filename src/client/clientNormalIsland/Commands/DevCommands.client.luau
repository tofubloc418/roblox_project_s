--!strict
-- DevCommands (Client)
-- Registers in-game chat slash commands for developer use.
-- Commands that only need client data are handled here directly.
-- Commands that need server authority are routed via RemoteEvent.
--
-- COMMANDS:
--   /give <templateId> [count]   -- add an item to your inventory
--   /items [filter]              -- list all registered item IDs
--   /data [playerName]           -- print raw player data
--   /save [playerName]           -- force-save player data
--   /stats [playerName]          -- print player attributes & leaderstats
--   /players                     -- list players in server
--   /loaded                      -- show data-load status per player
--   /hitbox [on|off]             -- toggle ShapecastHitbox debug visuals
--   /help                        -- show this command list in chat

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TextChatService   = game:GetService("TextChatService")

-- Only active in Studio (protection against accidental production exposure).
if not RunService:IsStudio() then return end

local localPlayer = Players.LocalPlayer

-- ── Packages (lazy-loaded to avoid blocking on WaitForChild at startup) ──────

local _shapecastHitbox: any = nil
local function getShapecastHitbox(): any?
	if _shapecastHitbox then return _shapecastHitbox end
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	if not packages then return nil end
	local mod = packages:FindFirstChild("shapecasthitbox")
	if not mod then return nil end
	_shapecastHitbox = require(mod :: ModuleScript) :: any
	return _shapecastHitbox
end

-- ── Remotes ───────────────────────────────────────────────────────────────────

-- DevCommandHandler.server.luau creates these; WaitForChild until ready.
local devRemotes          = ReplicatedStorage:WaitForChild("DevRemotes", 15)
assert(devRemotes, "[DevCommands] DevRemotes folder not found after 15s.")

local devCommandRemote       = devRemotes:WaitForChild("DevCommand",       10) :: RemoteEvent
local devCommandResultRemote = devRemotes:WaitForChild("DevCommandResult", 10) :: RemoteEvent

-- Print lines received from the server.
devCommandResultRemote.OnClientEvent:Connect(function(lines: { string }, isWarning: boolean)
	for _, line in ipairs(lines) do
		if isWarning then warn(line) else print(line) end
	end
end)

-- ── Chat output helper ────────────────────────────────────────────────────────
-- Sends a system message to the local chat window (RBXGeneral channel).
-- Falls back to print() if the channel isn't available.
local function chatPrint(text: string)
	local ok, channel = pcall(function()
		return TextChatService
			:FindFirstChild("TextChannels")
			:FindFirstChild("RBXGeneral")
	end)
	if ok and channel then
		(channel :: TextChannel):DisplaySystemMessage(text)
	else
		print(text)
	end
end

-- ── Command registration helper ───────────────────────────────────────────────

local function registerCommand(alias: string, handler: (args: { string }) -> ())
	local cmd      = Instance.new("TextChatCommand")
	cmd.Name       = "DevCmd_" .. alias
	cmd.PrimaryAlias        = "/" .. alias
	cmd.AutocompleteVisible = false -- don't pollute the autocomplete list
	cmd.Parent     = TextChatService

	cmd.Triggered:Connect(function(_source, unfilteredText: string)
		-- Split on spaces, skip the command name (index 1).
		local parts = string.split(unfilteredText:gsub("^%s+", ""), " ")
		local args: { string } = {}
		for i = 2, #parts do
			if parts[i] ~= "" then
				table.insert(args, parts[i])
			end
		end
		handler(args)
	end)
end

-- ── Client-only commands ──────────────────────────────────────────────────────

-- /help
registerCommand("help", function(_args)
	local lines = {
		"━━━━━━  Dev Commands  ━━━━━━",
		"── Inventory ──",
		"  /give <id> [count]   Give yourself an item",
		"  /items [filter]      List all registered items",
		"── Data ──",
		"  /data [player]       Print raw player data",
		"  /save [player]       Force-save player data",
		"── Player ──",
		"  /stats [player]      Attributes & leaderstats",
		"  /players             List players in server",
		"  /loaded              Data-load status",
		"── Debug ──",
		"  /hitbox [on|off]     ShapecastHitbox visuals",
		"  /help                Show this list",
		"━━━━━━━━━━━━━━━━━━━━━━━━━━━",
	}
	for _, line in ipairs(lines) do
		chatPrint(line)
	end
end)

-- /hitbox [on|off]
registerCommand("hitbox", function(args)
	local ShapecastHitbox = getShapecastHitbox()
	if not ShapecastHitbox then
		warn("[Dev] ShapecastHitbox package not found.")
		return
	end
	local current  = ShapecastHitbox.Settings.Debug_Visible
	local newState: boolean
	if args[1] == "on" then
		newState = true
	elseif args[1] == "off" then
		newState = false
	else
		newState = not current -- toggle
	end
	ShapecastHitbox.Settings.Debug_Visible = newState
	print(string.format("[Dev] Hitbox debug visuals: %s", newState and "ON ✓" or "OFF ✗"))
end)

-- /players
registerCommand("players", function(_args)
	local list = Players:GetPlayers()
	print(string.format("[Dev] %d player(s) in server:", #list))
	for i, p in ipairs(list) do
		print(string.format("  %d) %s (UserId=%d)", i, p.Name, p.UserId))
	end
end)

-- /loaded
registerCommand("loaded", function(_args)
	local list = Players:GetPlayers()
	print(string.format("[Dev] Data load status (%d player(s)):", #list))
	for _, p in ipairs(list) do
		if p:GetAttribute("_DataLoaded") then
			print(string.format("  [OK]      %s", p.Name))
		else
			warn(string.format("  [NO DATA] %s", p.Name))
		end
	end
end)

-- /stats [playerName]
registerCommand("stats", function(args)
	local target: Player?
	if args[1] then
		target = Players:FindFirstChild(args[1]) :: Player?
		if not target then
			warn(string.format("[Dev] Player '%s' not found.", args[1]))
			return
		end
	else
		target = localPlayer
	end

	local p = target :: Player
	print(string.format("[Dev] Stats for '%s':", p.Name))

	local attributes = p:GetAttributes()
	local attrCount  = 0
	for _ in pairs(attributes) do attrCount += 1 end
	print(string.format("  --- Attributes (%d) ---", attrCount))
	for k, v in pairs(attributes) do
		print(string.format("    [%s] = %s", tostring(k), tostring(v)))
	end

	local leaderstats = p:FindFirstChild("leaderstats")
	if leaderstats then
		local children = leaderstats:GetChildren()
		print(string.format("  --- leaderstats (%d) ---", #children))
		for _, stat in ipairs(children) do
			if stat:IsA("ValueBase") then
				print(string.format("    [%s] = %s", stat.Name, tostring((stat :: any).Value)))
			end
		end
	else
		print("  --- No leaderstats found ---")
	end
end)

-- ── Server-routed commands ────────────────────────────────────────────────────

-- /give <templateId> [count]
registerCommand("give", function(args)
	if not args[1] then
		warn("[Dev] Usage: /give <templateId> [count]")
		return
	end
	devCommandRemote:FireServer("give", args)
end)

-- /items [filter]
registerCommand("items", function(args)
	devCommandRemote:FireServer("items", args)
end)

-- /data [playerName]
registerCommand("data", function(args)
	devCommandRemote:FireServer("data", args)
end)

-- /save [playerName]
registerCommand("save", function(args)
	devCommandRemote:FireServer("save", args)
end)

print("[DevCommands] Chat commands registered. Type /give, /items, /data, /save, /stats, /players, /loaded, /hitbox")
