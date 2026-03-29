--!strict
--[[
	IronSpear / Logic
	Thin per-weapon script that wires the IronSpear model to the generic
	WeaponController.

	Called by the equip pipeline:
	  Logic.Equip(weaponModel, player, WeaponController)
	  Logic.Unequip()
]]

local TEMPLATE_ID = "IronSpear"

local Logic = {}

local _activeController = nil :: any

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
