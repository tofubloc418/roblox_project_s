--!strict
--[[
	ActiveWeaponManager (Client)
	Listens to HUD activeSlot changes and equips/unequips the corresponding weapon logic.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local WeaponController = require(script.Parent:WaitForChild("WeaponController")) :: any

local GUI = script.Parent.Parent:WaitForChild("GUI")
local HudLoadoutDataAdapter = require(GUI:WaitForChild("HudLoadout"):WaitForChild("HudLoadoutDataAdapter")) :: any

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry")) :: any
local Items = ReplicatedStorage:WaitForChild("Items")
local Weapons = Items:WaitForChild("Weapons")
local FistsLogic = require(Weapons:WaitForChild("Fists"):WaitForChild("Fists"):WaitForChild("Logic")) :: any

local currentActiveSlot = nil
local currentEquippedTemplateId = nil :: string?
local currentWeaponLogic = nil :: any
local currentWeaponModel = nil :: Model?

local function unequipCurrent()
	if currentWeaponLogic then
		currentWeaponLogic.Unequip()
		currentWeaponLogic = nil
	end
	if currentWeaponModel and currentWeaponModel ~= localPlayer.Character then
		currentWeaponModel:Destroy()
		currentWeaponModel = nil
	end
end

local function equipWeaponByTemplateId(templateId: string)
	local character = localPlayer.Character
	if not character then return end

	local template = ItemRegistry.GetTemplate(templateId)
	if not template or not template.subcategory then return end

	local subcategoryFolder = Weapons:FindFirstChild(template.subcategory)
	local itemFolder = subcategoryFolder and subcategoryFolder:FindFirstChild(templateId)
	if not itemFolder then return end

	local logic = itemFolder:FindFirstChild("Logic")
	if not logic then return end
	local LogicModule = require(logic) :: any

	local modelTemplate = itemFolder:FindFirstChild(templateId) or itemFolder:FindFirstChildOfClass("Model")
	if not modelTemplate or not modelTemplate:IsA("Model") then return end

	local clone = modelTemplate:Clone()
	clone.Parent = character
	currentWeaponLogic = LogicModule
	currentWeaponModel = clone
	LogicModule.Equip(clone, localPlayer, WeaponController)
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

	unequipCurrent()

	if currentActiveSlot == "Fists" then
		local character = localPlayer.Character
		if character then
			FistsLogic.Equip(character, localPlayer, WeaponController)
			currentWeaponLogic = FistsLogic
			currentWeaponModel = character
		end
	elseif desiredTemplateId then
		equipWeaponByTemplateId(desiredTemplateId)
	end
end

HudLoadoutDataAdapter.subscribe(onSlotChanged)

localPlayer.CharacterAdded:Connect(function(character)
	if currentActiveSlot == "Fists" then
		FistsLogic.Equip(character, localPlayer, WeaponController)
		currentWeaponLogic = FistsLogic
		currentWeaponModel = character
	elseif currentActiveSlot == "Weapon1" or currentActiveSlot == "Weapon2" then
		local desiredTemplateId = getDesiredTemplateIdForState(HudLoadoutDataAdapter.getState())
		if desiredTemplateId then
			currentWeaponModel = nil
			equipWeaponByTemplateId(desiredTemplateId)
		end
	end
end)
