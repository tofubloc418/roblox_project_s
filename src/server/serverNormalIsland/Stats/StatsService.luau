-- StatsService
-- Server singleton managing per-player stat containers and replicating stats to Player attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Stats")
local StatsConfig = require(StatsFolder:WaitForChild("StatsConfig"))
local StatContainer = require(script.Parent:WaitForChild("StatContainer"))

local StatsService = {}
StatsService.__index = StatsService

function StatsService.new()
	local self = setmetatable({}, StatsService)
	self._containers = {}
	return self
end

local function replicateToPlayer(player: Player, container: any)
	local derived = container:GetAllDerived()
	for _, statName in ipairs(StatsConfig.ReplicatedStats) do
		local value = derived[statName]
		if value ~= nil then
			player:SetAttribute(statName, value)
		end
	end
	-- Backward compatibility: Stamina system expects MaxStamina
	player:SetAttribute("MaxStamina", derived.MaxEnergy or 100)
end

local function createContainerForPlayer(self: any, player: Player)
	local container = StatContainer.new()
	self._containers[player] = container

	-- Replicate on change
	container.Changed:Connect(function()
		replicateToPlayer(player, container)
	end)

	-- Initial replication
	replicateToPlayer(player, container)
end

function StatsService:Initialize()
	-- Handle players already in game (e.g. Studio testing)
	for _, player in ipairs(Players:GetPlayers()) do
		createContainerForPlayer(self, player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		createContainerForPlayer(self, player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._containers[player] = nil
	end)
end

function StatsService:GetContainer(player: Player): any?
	return self._containers[player]
end

function StatsService:GetStat(player: Player, statName: string): number?
	local container = self._containers[player]
	if not container then
		return nil
	end
	return container:GetDerivedStat(statName :: any)
end

function StatsService:GetAttributes(player: Player)
	local container = self._containers[player]
	if not container then
		return nil
	end
	return container:GetAttributes()
end

function StatsService:SetAttribute(player: Player, attrName: string, value: number)
	local container = self._containers[player]
	if not container then
		return
	end
	container:SetAttribute(attrName :: any, value)
end

function StatsService:AddModifier(player: Player, modifier: any)
	local container = self._containers[player]
	if not container then
		return
	end
	container:AddModifier(modifier)
end

function StatsService:RemoveModifier(player: Player, modifierId: string)
	local container = self._containers[player]
	if not container then
		return
	end
	container:RemoveModifier(modifierId)
end

function StatsService:RemoveModifiersBySource(player: Player, source: string)
	local container = self._containers[player]
	if not container then
		return false
	end
	return container:RemoveModifiersBySource(source :: any)
end

local instance = StatsService.new()
return instance
