--[[
	RoundState
	Manages round seed for deterministic RNG across the loot system
]]

local RoundState = {}
RoundState.__index = RoundState

-- Singleton instance
local instance = nil

function RoundState.new()
	local self = setmetatable({}, RoundState)
	
	self.RoundSeed = 0
	self.IsInitialized = false
	self._rngCache = {} -- Cache RNG instances for crates
	
	return self
end

-- Get or create singleton instance
function RoundState.GetInstance()
	if not instance then
		instance = RoundState.new()
	end
	return instance
end

-- Initialize with a new round seed (server only)
function RoundState:Initialize(seed: number?)
	if game:GetService("RunService"):IsClient() then
		warn("RoundState:Initialize should only be called on server")
		return
	end
	
	self.RoundSeed = seed or os.time()
	self.IsInitialized = true
	self._rngCache = {} -- Clear cache on new round
	
	print("Round initialized with seed:", self.RoundSeed)
end

-- Get the round seed (read-only)
function RoundState:GetSeed(): number
	return self.RoundSeed
end

-- Get a deterministic RNG for a specific crate
function RoundState:GetCrateRollRng(crateId: string): Random
	if not self.IsInitialized then
		warn("RoundState not initialized, using default seed")
		self:Initialize()
	end
	
	-- Check cache first
	if self._rngCache[crateId] then
		return self._rngCache[crateId]
	end
	
	-- Create deterministic seed from round seed and crate ID
	local crateSeed = 0
	for i = 1, #crateId do
		crateSeed = crateSeed + string.byte(crateId, i) * i
	end
	
	-- Combine with round seed
	local combinedSeed = self.RoundSeed + crateSeed
	
	-- Create and cache RNG instance
	local rng = Random.new(combinedSeed)
	self._rngCache[crateId] = rng
	
	return rng
end

-- Get a general RNG for procedural spawning
function RoundState:GetSpawnRng(): Random
	if not self.IsInitialized then
		warn("RoundState not initialized, using default seed")
		self:Initialize()
	end
	
	return Random.new(self.RoundSeed)
end

-- Reset the round state (for testing or new rounds)
function RoundState:Reset()
	self.RoundSeed = 0
	self.IsInitialized = false
	self._rngCache = {}
end

-- Export singleton getter for convenience
RoundState.Current = RoundState.GetInstance

return RoundState
