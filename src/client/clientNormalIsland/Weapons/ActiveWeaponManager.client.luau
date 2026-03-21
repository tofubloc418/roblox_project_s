--!strict
--[[
	ActiveWeaponManager (Client)
	Listens to HUD activeSlot changes.
	- Server: owns weapon visuals (replicated `EquippedWeapon` model + `RightGrip`).
	- Client: owns weapon behaviour (animations, hit detection, input).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local WeaponController = require(script.Parent:WaitForChild("WeaponController")) :: any

local GUI = script.Parent.Parent:WaitForChild("GUI")
local HudLoadoutDataAdapter = require(GUI:WaitForChild("HudLoadout"):WaitForChild("HudLoadoutDataAdapter")) :: any

local WeaponAssetLayout = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("WeaponAssetLayout")) :: any
local Items = ReplicatedStorage:WaitForChild("Items")
local Weapons = Items:WaitForChild("Weapons")
local FistsLogic = require(Weapons:WaitForChild("Fists"):WaitForChild("Fists"):WaitForChild("Logic")) :: any

local weaponRemotes = ReplicatedStorage:WaitForChild("WeaponRemotes")
local weaponVisualEquipRemote = weaponRemotes:WaitForChild("WeaponVisualEquipRequest") :: RemoteEvent

local WEAPON_VISUAL_MODEL_NAME = "EquippedWeapon"
local WEAPON_TEMPLATE_ATTR_ON_MODEL = "TemplateId"

local currentActiveSlot = nil
local currentEquippedTemplateId = nil :: string?
local currentServerVisualTemplateId = nil :: string?
local currentWeaponLogic = nil :: any
local equipRequestSeq = 0
local logicCache: { [string]: any } = {}

local function unequipCurrent()
	if currentWeaponLogic then
		currentWeaponLogic.Unequip()
		currentWeaponLogic = nil
	end
end

local function getLogicModuleForTemplateId(templateId: string): any?
	local itemFolder = WeaponAssetLayout.GetWeaponItemFolder(Weapons, templateId)
	if not itemFolder then return end

	local logic = itemFolder:FindFirstChild("Logic")
	if not logic then return end
	if logicCache[templateId] then
		return logicCache[templateId]
	end

	local LogicModule = require(logic) :: any
	logicCache[templateId] = LogicModule
	return LogicModule
end

local function equipWeaponByTemplateId(templateId: string)
	local character = localPlayer.Character
	if not character then return end

	local desiredSeq = equipRequestSeq
	local LogicModule = getLogicModuleForTemplateId(templateId)
	if not LogicModule then return end

	-- Wait for the server to attach the replicated weapon model to this character.
	local weaponModel = character:WaitForChild(WEAPON_VISUAL_MODEL_NAME, 2)
	if equipRequestSeq ~= desiredSeq then
		return -- slot changed while we were waiting
	end
	if not weaponModel or not weaponModel:IsA("Model") then
		return
	end
	if weaponModel:GetAttribute(WEAPON_TEMPLATE_ATTR_ON_MODEL) ~= templateId then
		return -- stale weapon (rapid slot switching)
	end

	currentWeaponLogic = LogicModule
	LogicModule.Equip(weaponModel :: Model, localPlayer, WeaponController)
end

local function getDesiredTemplateIdForState(state: any): string?
	if state.activeSlot == "Fists" then
		return "Fists"
	end

	if state.activeSlot == "Weapon1" then
		return state.weapon1 and state.weapon1.itemId or nil
	end

	if state.activeSlot == "Weapon2" then
		return state.weapon2 and state.weapon2.itemId or nil
	end

	return nil
end

local function onSlotChanged(state: any)
	local desiredTemplateId = getDesiredTemplateIdForState(state)
	if state.activeSlot == currentActiveSlot and desiredTemplateId == currentEquippedTemplateId then
		return
	end

	currentActiveSlot = state.activeSlot
	currentEquippedTemplateId = desiredTemplateId

	-- Tell the server what weapon visual should be equipped for other players to see.
	-- (For QuickUse or an empty weapon slot, we use "Fists" to unequip the weapon visual.)
	local serverDesiredTemplateId = desiredTemplateId or "Fists"
	if serverDesiredTemplateId ~= currentServerVisualTemplateId then
		currentServerVisualTemplateId = serverDesiredTemplateId
		weaponVisualEquipRemote:FireServer(serverDesiredTemplateId)
	end

	unequipCurrent()

	if currentActiveSlot == "Fists" then
		local character = localPlayer.Character
		if character then
			FistsLogic.Equip(character, localPlayer, WeaponController)
			currentWeaponLogic = FistsLogic
		end
	elseif desiredTemplateId then
		equipRequestSeq += 1
		-- Note: server equip already requested above; we just wait for the model and attach logic.
		equipWeaponByTemplateId(desiredTemplateId)
	end
end

HudLoadoutDataAdapter.subscribe(onSlotChanged)

localPlayer.CharacterAdded:Connect(function(character)
	unequipCurrent()

	if currentActiveSlot == "Fists" then
		currentServerVisualTemplateId = "Fists"
		weaponVisualEquipRemote:FireServer("Fists")

		FistsLogic.Equip(character, localPlayer, WeaponController)
		currentWeaponLogic = FistsLogic
	elseif currentActiveSlot == "Weapon1" or currentActiveSlot == "Weapon2" then
		local desiredTemplateId = getDesiredTemplateIdForState(HudLoadoutDataAdapter.getState())
		local serverDesiredTemplateId = desiredTemplateId or "Fists"
		currentServerVisualTemplateId = serverDesiredTemplateId
		weaponVisualEquipRemote:FireServer(serverDesiredTemplateId)

		if desiredTemplateId then
			equipRequestSeq += 1
			equipWeaponByTemplateId(desiredTemplateId)
		end
	end
end)
