--!strict
--[[
	Loads weapon Model templates from Roblox via InsertService when the item template sets `modelAssetId`.

	The uploaded asset should be a Model. InsertService returns a wrapper Model with at least one child Model.
]]

local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local HOLDER_NAME = "_WeaponModelAssetTemplates"

local WeaponModelAssetLoader = {}

local function parseAssetId(raw: any): number?
	if raw == nil then
		return nil
	end
	if type(raw) == "number" and raw > 0 then
		return raw
	end
	if type(raw) == "string" then
		local direct = tonumber(raw)
		if direct and direct > 0 then
			return direct
		end
		local idStr = string.match(raw, "rbxassetid://(%d+)")
		if idStr then
			local n = tonumber(idStr)
			if n and n > 0 then
				return n
			end
		end
	end
	return nil
end

WeaponModelAssetLoader.ParseAssetId = parseAssetId

function WeaponModelAssetLoader.LoadTemplateModel(templateId: string, modelAssetIdRaw: any): Model?
	local assetId = parseAssetId(modelAssetIdRaw)
	if not assetId then
		return nil
	end

	local ok, container = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not ok then
		warn(
			string.format(
				"[WeaponModelAssetLoader] LoadAsset threw for templateId=%s assetId=%s: %s",
				templateId,
				tostring(assetId),
				tostring(container)
			)
		)
		return nil
	end

	if container == nil or not container:IsA("Model") then
		warn(
			string.format(
				"[WeaponModelAssetLoader] LoadAsset returned invalid instance for templateId=%s assetId=%s",
				templateId,
				tostring(assetId)
			)
		)
		if typeof(container) == "Instance" then
			(container :: Instance):Destroy()
		end
		return nil
	end

	local inner: Model? = nil
	for _, child in (container :: Model):GetChildren() do
		if child:IsA("Model") then
			inner = child
			break
		end
	end

	if not inner then
		warn(string.format("[WeaponModelAssetLoader] Asset has no Model child (templateId=%s assetId=%s)", templateId, tostring(assetId)))
		container:Destroy()
		return nil
	end

	local holder = ServerStorage:FindFirstChild(HOLDER_NAME)
	if not holder then
		holder = Instance.new("Folder")
		holder.Name = HOLDER_NAME
		holder.Parent = ServerStorage
	end

	local existing = holder:FindFirstChild("_Template_" .. templateId)
	if existing and existing:IsA("Model") then
		existing:Destroy()
	end

	local template = inner:Clone()
	template.Name = "_Template_" .. templateId
	template.Parent = holder

	container:Destroy()
	return template
end

return WeaponModelAssetLoader
