--!strict
-- Shared `abilityPresets` cache + change subscription for Settings and HUD (ModuleScript so it can be required).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("DataService")) :: any
local DataServiceClient = DataService.client

local subscribers: { () -> () } = {}
local cachedPresets: { [string]: any } = {}
local initialized = false

local function notifySubscribers()
	for _, cb in ipairs(subscribers) do
		task.defer(cb)
	end
end

local function pullPresetsFromService()
	local ap = DataServiceClient:get({ "abilityPresets" })
	cachedPresets = if type(ap) == "table" then ap else {}
	notifySubscribers()
end

local AbilityPresetsBridge = {}

function AbilityPresetsBridge.ensureInitialized()
	if initialized then
		return
	end
	initialized = true
	if not (DataServiceClient :: any).networker then
		DataServiceClient:init()
	end
	DataServiceClient:waitForData()
	pullPresetsFromService()
	local sig = DataServiceClient:getChangedSignal({ "abilityPresets" })
	if sig and type(sig.Connect) == "function" then
		sig:Connect(pullPresetsFromService)
	end
end

function AbilityPresetsBridge.get(): { [string]: any }
	return cachedPresets
end

function AbilityPresetsBridge.subscribe(callback: () -> ()): () -> ()
	table.insert(subscribers, callback)
	return function()
		local i = table.find(subscribers, callback)
		if i then
			table.remove(subscribers, i)
		end
	end
end

return AbilityPresetsBridge
