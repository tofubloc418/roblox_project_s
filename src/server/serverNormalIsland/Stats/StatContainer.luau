-- StatContainer
-- Per-player object that holds core attributes, modifier stack, and computes final derived stats.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Stats")
local StatsTypes = require(StatsFolder:WaitForChild("StatsTypes"))
local StatsConfig = require(StatsFolder:WaitForChild("StatsConfig"))
local StatFormulas = require(StatsFolder:WaitForChild("StatFormulas"))

type CoreAttributes = StatsTypes.CoreAttributes
type CoreAttributeId = StatsTypes.CoreAttributeId
type StatModifier = StatsTypes.StatModifier
type ModifierSource = StatsTypes.ModifierSource
type DerivedStatId = StatsTypes.DerivedStatId
type DerivedStats = StatsTypes.DerivedStats

local StatContainer = {}
StatContainer.__index = StatContainer

function StatContainer.new()
	local self = setmetatable({}, StatContainer)

	-- Copy default attributes
	local defaults = StatsConfig.DefaultAttributes
	self._coreAttributes = {
		Vitality = defaults.Vitality,
		Intelligence = defaults.Intelligence,
		Endurance = defaults.Endurance,
		Strength = defaults.Strength,
		Dexterity = defaults.Dexterity,
		Luck = defaults.Luck,
	}

	self._modifiers = {} :: { StatModifier }
	self._derivedCache = {} :: { [DerivedStatId]: number }
	self._dirty = true

	-- Changed signal (BindableEvent for RBXScriptSignal compatibility)
	local changedEvent = Instance.new("BindableEvent")
	self.Changed = changedEvent.Event

	function self._fireChanged()
		changedEvent:Fire()
	end

	return self
end

function StatContainer:SetAttribute(name: CoreAttributeId, value: number)
	if self._coreAttributes[name] ~= nil then
		self._coreAttributes[name] = math.max(0, value)
		self._dirty = true
	end
end

function StatContainer:GetAttribute(name: CoreAttributeId): number?
	return self._coreAttributes[name]
end

function StatContainer:GetAttributes(): CoreAttributes
	return table.clone(self._coreAttributes)
end

function StatContainer:AddModifier(modifier: StatModifier)
	table.insert(self._modifiers, modifier)
	self._dirty = true
end

function StatContainer:RemoveModifier(id: string)
	for i = #self._modifiers, 1, -1 do
		if self._modifiers[i].id == id then
			table.remove(self._modifiers, i)
			self._dirty = true
			return true
		end
	end
	return false
end

function StatContainer:RemoveModifiersBySource(source: ModifierSource)
	local removed = false
	for i = #self._modifiers, 1, -1 do
		if self._modifiers[i].source == source then
			table.remove(self._modifiers, i)
			removed = true
		end
	end
	if removed then
		self._dirty = true
	end
	return removed
end

local function applyModifiers(baseValue: number, statId: DerivedStatId, modifiers: { StatModifier }): number
	local flatSum = 0
	local percentAddSum = 0
	local percentMults = {}

	for _, mod in ipairs(modifiers) do
		if mod.stat ~= statId then
			continue
		end
		if mod.operation == "Flat" then
			flatSum += mod.value
		elseif mod.operation == "PercentAdd" then
			percentAddSum += mod.value
		elseif mod.operation == "PercentMult" then
			table.insert(percentMults, mod.value)
		end
	end

	local result = baseValue + flatSum
	result = result * (1 + percentAddSum)
	for _, mult in ipairs(percentMults) do
		result = result * (1 + mult)
	end

	return result
end

function StatContainer:Recalculate()
	if not self._dirty then
		return
	end

	local baseDerived = StatFormulas.calculateAllDerived(self._coreAttributes)
	local caps = StatsConfig.DerivedStatCaps

	for statId, baseValue in pairs(baseDerived) do
		local value = applyModifiers(baseValue, statId, self._modifiers)

		local cap = caps[statId]
		if cap then
			value = math.clamp(value, cap.min, cap.max)
		end

		self._derivedCache[statId] = value
	end

	self._dirty = false
	self._fireChanged()
end

function StatContainer:GetDerivedStat(statName: DerivedStatId): number
	self:Recalculate()
	return self._derivedCache[statName] or 0
end

function StatContainer:GetAllDerived(): DerivedStats
	self:Recalculate()
	return table.clone(self._derivedCache) :: any
end

return StatContainer
