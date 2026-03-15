--!strict
-- Cmdr type: item template ID with autocomplete.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))

local itemTemplateIdType = {
	Validate = function(value: string): (boolean, string?)
		if type(value) ~= "string" or value == "" then
			return false, "Template ID is required."
		end
		local template = ItemRegistry.GetTemplate(value)
		if not template then
			return false, ("'%s' is not a registered item. Use /items to browse."):format(value)
		end
		return true
	end,

	Parse = function(value: string): string
		local template = ItemRegistry.GetTemplate(value)
		return template and template.templateId or value
	end,

	Autocomplete = function(): { string }
		local out: { string } = {}
		for id, _ in pairs(ItemRegistry.GetAll()) do
			table.insert(out, id)
		end
		table.sort(out)
		return out
	end,
}

return function(registry)
	registry:RegisterType("itemTemplateId", itemTemplateIdType)
end
