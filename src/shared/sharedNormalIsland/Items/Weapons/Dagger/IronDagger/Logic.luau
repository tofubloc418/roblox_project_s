--!strict
--[[
	IronDagger / Logic
	Thin per-weapon script that wires the IronDagger model to the generic
	WeaponController. Any behaviour unique to this specific weapon (special
	abilities, unique VFX) would be added here.

	Called by the equip pipeline:
	  Logic.Equip(weaponModel, player)
	  Logic.Unequip()
]]

local TEMPLATE_ID = "IronDagger"

local Logic = {}

local _activeController = nil :: any -- WeaponControllerInstance | nil

--[[
	Logic.Equip(weaponModel, player, WeaponController)
	The equip pipeline passes in the cloned model, the owning player,
	and the WeaponController module reference (since it lives in client).
]]
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
