--!strict
--[[
	Fists / Logic
	Thin per-weapon script that wires the Fists 'model' (usually the character)
	to the generic WeaponController.
]]

local TEMPLATE_ID = "Fists"

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
