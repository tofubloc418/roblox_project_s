--!strict
-- ReplicatedStorage.Items.Weapons/<weaponTag>/<templateId> (Model, Logic, …)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))

local WeaponAssetLayout = {}

function WeaponAssetLayout.GetWeaponItemFolder(weaponsRoot: Instance, templateId: string): Instance?
	local template = ItemRegistry.GetTemplate(templateId)
	if not template then
		return nil
	end
	local tag = (template :: any).weaponTag
	if type(tag) ~= "string" or tag == "" then
		return nil
	end
	local tagFolder = weaponsRoot:FindFirstChild(tag)
	if not tagFolder then
		return nil
	end
	return tagFolder:FindFirstChild(templateId)
end

return WeaponAssetLayout
