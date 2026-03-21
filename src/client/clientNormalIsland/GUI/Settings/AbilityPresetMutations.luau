--!strict
-- Drag descriptors → preset ops; InvokeServer(RequestApplyAbilityPresetOps).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityPresetSlotUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("AbilityPresetSlotUtils"))
local DragDropManager = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DragDropManager"))

type DragDescriptor = DragDropManager.DragDescriptor

export type PresetOperation = {
	presetKey: string,
	slotIndex: number,
	abilityId: string?,
}

local AbilityPresetMutations = {}

function AbilityPresetMutations.buildPresetOperations(
	source: DragDescriptor,
	target: DragDescriptor,
	presets: { [string]: any }
): { PresetOperation }?
	if target.container ~= "ability_preset" or not target.slotId then
		return nil
	end
	local tk, ti = AbilityPresetSlotUtils.parsePresetSlotId(target.slotId :: string)
	if not tk or not ti then
		return nil
	end

	if source.container == "ability_pool" then
		local poolId = source.slotId
		if type(poolId) ~= "string" or #poolId == 0 then
			return nil
		end
		return {
			{
				presetKey = tk,
				slotIndex = ti,
				abilityId = poolId,
			},
		}
	end

	if source.container == "ability_preset" and source.slotId then
		local sk, si = AbilityPresetSlotUtils.parsePresetSlotId(source.slotId :: string)
		if not sk or not si then
			return nil
		end
		if sk == tk and si == ti then
			return nil
		end
		local a = AbilityPresetSlotUtils.readSlot(presets[sk], si)
		if not a then
			return nil
		end
		local b = AbilityPresetSlotUtils.readSlot(presets[tk], ti)
		if b then
			return {
				{ presetKey = tk, slotIndex = ti, abilityId = a },
				{ presetKey = sk, slotIndex = si, abilityId = b },
			}
		else
			return {
				{ presetKey = tk, slotIndex = ti, abilityId = a },
				{ presetKey = sk, slotIndex = si, abilityId = nil },
			}
		end
	end

	return nil
end

function AbilityPresetMutations.invokeApplyOperations(ops: { PresetOperation }): (boolean, string?)
	local folder = ReplicatedStorage:WaitForChild("InventoryRemotes")
	local rf = folder:WaitForChild("RequestApplyAbilityPresetOps")
	if not rf:IsA("RemoteFunction") then
		return false, "Server not ready."
	end
	local result = (rf :: RemoteFunction):InvokeServer(ops)
	if type(result) ~= "table" then
		return false, "Unknown error."
	end
	if result.ok == true then
		return true, nil
	end
	local err = result.error
	return false, if type(err) == "string" then err else "Cannot apply ability preset."
end

return AbilityPresetMutations
