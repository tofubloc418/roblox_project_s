--!strict
--[[
	IronGreatsword / Logic
	Thin per-weapon script that wires the IronGreatsword model to the generic
	WeaponController. Grip uses template gripC0/gripC1 (WeaponService RightGrip).

	Called by the equip pipeline:
	  Logic.Equip(weaponModel, player, WeaponController)
	  Logic.Unequip()
]]

local TEMPLATE_ID = "IronGreatsword"

local Logic = {}

local _activeController = nil :: any -- WeaponControllerInstance | nil

function Logic.Equip(weaponModel: Model, player: Player, WeaponController: any)
	if _activeController then
		_activeController:Destroy()
		_activeController = nil
	end

	_activeController = WeaponController.new(weaponModel, player, TEMPLATE_ID)
	_activeController:Equip()
end

function Logic.Unequip()
	if _activeController then
		_activeController:Destroy()
		_activeController = nil
	end
end

return Logic
