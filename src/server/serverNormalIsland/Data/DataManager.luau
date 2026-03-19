--!strict
-- DataManager (template shim)
-- Exports only createDefaultData for use by DataServiceBootstrap as the
-- ProfileStore/default template. All persistence and session logic is handled
-- by the leifstout/dataservice package.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))
local StatsConfig    = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Stats"):WaitForChild("StatsConfig"))

type PlayerData = InventoryTypes.PlayerData

local CURRENT_VERSION = 1

local DataManager = {}

--[[
	createDefaultData(userId: number) -> PlayerData
	Returns the default PlayerData shape for new players. Used as the
	dataService/ProfileStore template (typically with userId 0).
]]
function DataManager.createDefaultData(userId: number): PlayerData
	return {
		version   = CURRENT_VERSION,
		lastSaved = os.time(),
		sessionId = "",

		character = {
			level           = 1,
			experience      = 0,
			attributePoints = 0,
			attributes      = {
				Vitality     = StatsConfig.DefaultAttributes.Vitality,
				Intelligence = StatsConfig.DefaultAttributes.Intelligence,
				Endurance    = StatsConfig.DefaultAttributes.Endurance,
				Strength     = StatsConfig.DefaultAttributes.Strength,
				Dexterity    = StatsConfig.DefaultAttributes.Dexterity,
				Luck         = StatsConfig.DefaultAttributes.Luck,
			},
		} :: InventoryTypes.CharacterData,

		inventory = { maxSlots = 16, slots = {} },

		equipment = {
			Backpack = nil,
			Armor    = nil,
			Weapon1  = nil,
			Weapon2  = nil,
		},

		quickUse = {
			slots            = {},
			currentSlotIndex = nil,
		},

		stash = { maxSlots = 100, slots = {} },

		abilityPresets = {},

		currency = { gold = 0 },

		settings = {
			keybinds = {},
		},
	}
end

return DataManager
