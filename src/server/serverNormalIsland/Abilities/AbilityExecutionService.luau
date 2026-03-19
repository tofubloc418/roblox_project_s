--!strict
-- AbilityExecutionService
-- Dispatches RequestUseAbility → per-ability Execute() and notifies the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityDataService = require(script.Parent:WaitForChild("AbilityDataService"))
local GetPresetKey = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("GetPresetKey"))
local InventoryService = require(script.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

type StoredEquipmentData = InventoryTypes.StoredEquipmentData

export type AbilityExecutionContext = {
	player: Player,
	character: Model,
	humanoid: Humanoid?,
	rootPart: BasePart?,
	abilityId: string,
	slotIndex: number,
	weaponTemplateId: string?,
	presetKey: string,
}

local AbilityExecutionService = {}

local _requestUseAbility: RemoteEvent
local _abilityStarted: RemoteEvent

-- Resolve preset key from equipment.
local function getPresetKeyFromEquipment(equipment: StoredEquipmentData?): string
	if not equipment then return "Unarmed" end
	if equipment.Weapon1 and equipment.Weapon1.tid then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon1")
	end
	if equipment.Weapon2 and equipment.Weapon2.tid then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon2")
	end
	return "Unarmed"
end

-- Creates RequestUseAbility + AbilityStarted remotes (must run after InventoryService.Initialize()).
function AbilityExecutionService.Initialize()
	local remoteFolder = ReplicatedStorage:WaitForChild("InventoryRemotes")

	local function ensureRemote(name: string): RemoteEvent
		local existing = remoteFolder:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			return existing :: RemoteEvent
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
		return remote
	end

	_requestUseAbility = ensureRemote("RequestUseAbility")
	_abilityStarted = ensureRemote("AbilityStarted")

	_requestUseAbility.OnServerEvent:Connect(function(player: Player, slotIndex: number, _presetKeyOptional: string?)
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart

		local equipment = InventoryService.GetEquipment(player)
		local presetKey = getPresetKeyFromEquipment(equipment)

		local preset = AbilityDataService.GetPresetForKey(player, presetKey)
		local slot = preset[slotIndex]
		if not slot or not slot.aid or #slot.aid == 0 then
			return
		end

		local abilityId = slot.aid

		-- Resolve weapon template id for the weapon used with this preset (for damage context).
		local weaponTemplateId: string? = nil
		if equipment and equipment.Weapon1 and equipment.Weapon1.tid then
			local key1 = GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon1")
			if key1 == presetKey then
				weaponTemplateId = equipment.Weapon1.tid
			end
		end
		if not weaponTemplateId and equipment and equipment.Weapon2 and equipment.Weapon2.tid then
			local key2 = GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon2")
			if key2 == presetKey then
				weaponTemplateId = equipment.Weapon2.tid
			end
		end

		local context: AbilityExecutionContext = {
			player = player,
			character = character,
			humanoid = humanoid,
			rootPart = rootPart,
			abilityId = abilityId,
			slotIndex = slotIndex,
			weaponTemplateId = weaponTemplateId,
			presetKey = presetKey,
		}

		local scriptsFolder = script.Parent:FindFirstChild("Scripts")
		if not scriptsFolder then return end

		local abilityModule = scriptsFolder:FindFirstChild(abilityId)
		if not abilityModule or not abilityModule:IsA("ModuleScript") then
			return
		end

		local ok, abilityScript = pcall(require, abilityModule :: ModuleScript)
		if not ok or type(abilityScript) ~= "table" then
			return
		end

		local executeFn = abilityScript.Execute
		if type(executeFn) ~= "function" then
			return
		end

		local success = executeFn(player, context)
		if success then
			_abilityStarted:FireClient(player, abilityId, slotIndex)
		end
	end)
end

return AbilityExecutionService
