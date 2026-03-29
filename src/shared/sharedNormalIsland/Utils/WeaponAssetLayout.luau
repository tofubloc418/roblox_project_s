--!strict
-- ReplicatedStorage.Items.Weapons/<weaponTag>/<templateId>
-- Unique weapons are stored under ReplicatedStorage.Items.Weapons/Unique/<templateId>.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry")) :: any

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
	local subcategory = (template :: any).subcategory
	local tagFolderName = if subcategory == "UniqueWeapon" then "Unique" else tag
	local tagFolder = weaponsRoot:FindFirstChild(tagFolderName)
	if not tagFolder then
		return nil
	end
	return tagFolder:FindFirstChild(templateId)
end

return WeaponAssetLayout
