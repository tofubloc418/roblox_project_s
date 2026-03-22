--!strict
-- RequestUseAbility → CanUse/Execute; fires AbilityStarted to all clients. Cooldowns use AbilityStateRuntime.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityDataService = require(script.Parent:WaitForChild("AbilityDataService"))
local GetPresetKey = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("GetPresetKey"))
local ItemEnums = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemEnums"))
local InventoryService = require(script.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes")) :: any

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

local function getPresetKeyFromEquipment(equipment: StoredEquipmentData?): string
	if not equipment then
		return ItemEnums.WeaponTag.Fists
	end
	if equipment.Weapon1 and equipment.Weapon1.tid then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon1")
	end
	if equipment.Weapon2 and equipment.Weapon2.tid then
		return GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon2")
	end
	return ItemEnums.WeaponTag.Fists
end

local function allowedBarPresetKeys(equipment: StoredEquipmentData?): { [string]: boolean }
	local allowed: { [string]: boolean } = {}
	if not equipment then
		allowed[ItemEnums.WeaponTag.Fists] = true
		return allowed
	end
	local anyWeapon = false
	if equipment.Weapon1 and equipment.Weapon1.tid then
		allowed[GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon1")] = true
		anyWeapon = true
	end
	if equipment.Weapon2 and equipment.Weapon2.tid then
		allowed[GetPresetKey.GetPresetKeyForEquipmentSlot(equipment, "Weapon2")] = true
		anyWeapon = true
	end
	if not anyWeapon then
		allowed[ItemEnums.WeaponTag.Fists] = true
	end
	return allowed
end

local function resolveBarPresetKey(equipment: StoredEquipmentData?, clientKey: any): string
	if type(clientKey) == "string" and #clientKey > 0 then
		local ok = allowedBarPresetKeys(equipment)[clientKey]
		if ok then
			return clientKey
		end
	end
	return getPresetKeyFromEquipment(equipment)
end

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

	_requestUseAbility.OnServerEvent:Connect(function(player: Player, slotIndex: number, clientBarPresetKey: any?)
		if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > 5 or slotIndex % 1 ~= 0 then
			return
		end
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local rootPart: BasePart? = if hrp and hrp:IsA("BasePart") then hrp else character.PrimaryPart

		local equipment = InventoryService.GetEquipment(player)
		local presetKey = resolveBarPresetKey(equipment, clientBarPresetKey)

		local preset = AbilityDataService.GetPresetForKey(player, presetKey)
		local slotRow = InventoryTypes.getSlotItem(preset, slotIndex)
		if not slotRow or type(slotRow) ~= "table" then
			return
		end
		local abilityId = slotRow.aid
		if type(abilityId) ~= "string" or #abilityId == 0 then
			return
		end

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

		local canUseFn = abilityScript.CanUse
		if type(canUseFn) == "function" then
			local okCan, allowed = pcall(canUseFn, player, context)
			if not okCan or allowed ~= true then
				return
			end
		end

		local executeFn = abilityScript.Execute
		if type(executeFn) ~= "function" then
			return
		end

		local success = executeFn(player, context)
		if success then
			_abilityStarted:FireAllClients(player.UserId, abilityId, slotIndex)
		end
	end)
end

return AbilityExecutionService
