--!strict
--[[
	Knife / Logic
	Thin per-weapon script that wires the Knife model to the generic
	WeaponController. Uses C0/C1 from template for grip (WeaponRigging).

	Called by the equip pipeline:
	  Logic.Equip(weaponModel, player, WeaponController)
	  Logic.Unequip()
]]

local TEMPLATE_ID = "Knife"

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
