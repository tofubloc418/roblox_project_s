--!strict

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local DataService = require(Packages:WaitForChild("DataService")) :: any
local DataServiceClient = DataService.client

local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindRegistry = require(keybindsFolder:WaitForChild("KeybindRegistry"))
local KeybindsCodec = require(keybindsFolder:WaitForChild("KeybindsCodec"))

type Subscriber = () -> ()
type BindCallback = (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult
type BindOptions = {
	actionName: string?,
	createTouchButton: boolean?,
}

type BindRecord = {
	id: number,
	casActionName: string,
	actionId: string,
	callback: BindCallback,
	createTouchButton: boolean,
}

local _overrideNamesByAction: { [string]: { string } } = {}
local _subscribers: { [number]: Subscriber } = {}
local _bindings: { [number]: BindRecord } = {}
local _nextSubscriberId = 0
local _nextBindingId = 0

-- When true, gameplay handlers (e.g. ability RequestUseAbility) should not fire for rebound keys.
local _gameplayActionsSuppressed = false

local function cloneStringArray(values: { string }): { string }
	local copy: { string } = {}
	for _, value in ipairs(values) do
		table.insert(copy, value)
	end
	return copy
end

local function notifySubscribers()
	for _, callback in pairs(_subscribers) do
		callback()
	end
end

local function keyCodeSetsOverlap(a: { Enum.KeyCode }, b: { Enum.KeyCode }): boolean
	local seen: { [Enum.KeyCode]: boolean } = {}
	for _, k in a do
		seen[k] = true
	end
	for _, k in b do
		if seen[k] then
			return true
		end
	end
	return false
end

local function bindRecord(record: BindRecord)
	ContextActionService:UnbindAction(record.casActionName)

	local overrideNames = _overrideNamesByAction[record.actionId]
	local keyCodes = if overrideNames ~= nil
		then KeybindsCodec.NamesToKeyCodes(overrideNames)
		else KeybindRegistry.GetDefaultKeyCodes(record.actionId)

	if #keyCodes == 0 then
		keyCodes = KeybindRegistry.GetDefaultKeyCodes(record.actionId)
	end

	if overrideNames ~= nil and #overrideNames == 0 then
		return
	end

	if #keyCodes == 0 then
		return
	end

	ContextActionService:BindAction(record.casActionName, record.callback, record.createTouchButton, table.unpack(keyCodes))
end

local function rebindAll()
	for _, record in pairs(_bindings) do
		bindRecord(record)
	end
end

local function readOverridesFromData(): { [string]: { string } }
	local rawOverrides = DataServiceClient:get({ "settings", "keybinds" })
	if type(rawOverrides) ~= "table" then
		return {}
	end

	local overrides: { [string]: { string } } = {}
	for actionId, rawValue in pairs(rawOverrides) do
		if type(actionId) == "string" and KeybindRegistry.Has(actionId) then
			local names = KeybindsCodec.NormalizeStoredValue(rawValue)
			if names then
				overrides[actionId] = names
			end
		end
	end

	return overrides
end

local function refreshOverrides()
	_overrideNamesByAction = readOverridesFromData()
	rebindAll()
	notifySubscribers()
end

local function tryConnectChangedSignal(path: { string }): boolean
	local ok, signal = pcall(function()
		return DataServiceClient:getChangedSignal(path)
	end)

	if ok and signal and type(signal.Connect) == "function" then
		signal:Connect(refreshOverrides)
		return true
	end

	return false
end

task.spawn(function()
	if not (DataServiceClient :: any).networker then
		DataServiceClient:init()
	end

	DataServiceClient:waitForData()
	refreshOverrides()

	if not tryConnectChangedSignal({ "settings", "keybinds" }) then
		tryConnectChangedSignal({ "settings" })
	end
end)

local KeybindsClient = {}

function KeybindsClient.getBinds(actionId: string): { Enum.KeyCode }
	local overrideNames = _overrideNamesByAction[actionId]
	if overrideNames then
		return KeybindsCodec.NamesToKeyCodes(cloneStringArray(overrideNames))
	end

	return KeybindRegistry.GetDefaultKeyCodes(actionId)
end

function KeybindsClient.getDisplayString(actionId: string): string
	return KeybindsCodec.FormatKeyCodes(KeybindsClient.getBinds(actionId))
end

function KeybindsClient.isInputForAction(actionId: string, input: InputObject): boolean
	local keyCode = input.KeyCode
	if keyCode == Enum.KeyCode.Unknown then
		return false
	end

	for _, candidate in ipairs(KeybindsClient.getBinds(actionId)) do
		if candidate == keyCode then
			return true
		end
	end

	return false
end

function KeybindsClient.bindAction(actionId: string, callback: BindCallback, options: BindOptions?): () -> ()
	_nextBindingId += 1

	local record: BindRecord = {
		id = _nextBindingId,
		casActionName = (options and options.actionName) or ("Keybind_" .. actionId .. "_" .. tostring(_nextBindingId)),
		actionId = actionId,
		callback = callback,
		createTouchButton = if options and options.createTouchButton ~= nil then options.createTouchButton else false,
	}

	_bindings[record.id] = record
	bindRecord(record)

	return function()
		local existing = _bindings[record.id]
		if not existing then
			return
		end

		ContextActionService:UnbindAction(existing.casActionName)
		_bindings[record.id] = nil
	end
end

function KeybindsClient.subscribe(callback: Subscriber): () -> ()
	_nextSubscriberId += 1
	local subscriberId = _nextSubscriberId
	_subscribers[subscriberId] = callback

	return function()
		_subscribers[subscriberId] = nil
	end
end

function KeybindsClient.setGameplayActionsSuppressed(suppressed: boolean)
	_gameplayActionsSuppressed = suppressed
end

function KeybindsClient.areGameplayActionsSuppressed(): boolean
	return _gameplayActionsSuppressed
end

-- Other registry actions that share at least one KeyCode with this action (for conflict UI).
function KeybindsClient.getOtherActionIdsSharingKeysWith(actionId: string): { string }
	local myKeys = KeybindsClient.getBinds(actionId)
	local out: { string } = {}
	for otherId, _ in KeybindRegistry.GetAll() do
		if otherId ~= actionId and keyCodeSetsOverlap(myKeys, KeybindsClient.getBinds(otherId)) then
			table.insert(out, otherId)
		end
	end
	table.sort(out)
	return out
end

-- Human-readable descriptions of conflicting actions (registry `description` field).
function KeybindsClient.getConflictDescriptionsForAction(actionId: string): { string }
	local ids = KeybindsClient.getOtherActionIdsSharingKeysWith(actionId)
	local labels: { string } = {}
	for _, id in ids do
		local entry = KeybindRegistry.Get(id)
		table.insert(labels, if entry then entry.description else id)
	end
	return labels
end

return table.freeze(KeybindsClient)
