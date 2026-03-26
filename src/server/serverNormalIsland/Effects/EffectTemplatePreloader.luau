--!strict
--[[
	Reads VfxIndex and SfxIndex, loads every asset once, and parents clonable
	templates under ReplicatedStorage.EffectAssets with two flat subdirectories:

	  EffectAssets/
	    VFX/<nameID>   -- Model / BasePart clones from InsertService
	    SFX/<nameID>   -- Sound instances with SoundId pre-set

	Scripts clone or reference templates by nameID only — never by rbxassetid.
]]

local ContentProvider = game:GetService("ContentProvider")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxIndex = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Effects"):WaitForChild("VfxIndex")) :: any
local SfxIndex = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Effects"):WaitForChild("SfxIndex")) :: any

local ROOT_NAME = "EffectAssets"

local EffectTemplatePreloader = {}

local function parseAssetId(raw: string): number?
	local idStr = string.match(raw, "rbxassetid://(%d+)")
	if idStr then
		local n = tonumber(idStr)
		if n and n > 0 then
			return n
		end
	end
	return nil
end

local function extractInner(container: Model): Instance?
	for _, child in container:GetChildren() do
		if child:IsA("Model") then
			return child
		end
	end
	for _, child in container:GetChildren() do
		if child:IsA("BasePart") then
			return child
		end
	end
	return container:GetChildren()[1]
end

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing :: Folder
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function EffectTemplatePreloader.Initialize()
	local root = ensureFolder(ReplicatedStorage, ROOT_NAME)
	local vfxFolder = ensureFolder(root, "VFX")
	local sfxFolder = ensureFolder(root, "SFX")

	for nameId, rawId in VfxIndex :: { [string]: string } do
		if vfxFolder:FindFirstChild(nameId) then
			continue
		end
		local assetNum = parseAssetId(rawId)
		if not assetNum then
			warn(string.format("[EffectTemplatePreloader] Invalid VFX id for '%s': %s", nameId, rawId))
			continue
		end
		local ok, container = pcall(function()
			return InsertService:LoadAsset(assetNum)
		end)
		if not ok or not container or not container:IsA("Model") then
			warn(string.format("[EffectTemplatePreloader] LoadAsset failed for VFX '%s' (id=%d): %s", nameId, assetNum, tostring(container)))
			continue
		end
		local inner = extractInner(container :: Model)
		if not inner then
			warn(string.format("[EffectTemplatePreloader] No usable child in VFX '%s' (id=%d)", nameId, assetNum))
			container:Destroy()
			continue
		end
		local template = inner:Clone()
		template.Name = nameId
		template.Parent = vfxFolder
		container:Destroy()
	end

	local soundsToPreload: { Instance } = {}
	for nameId, rawId in SfxIndex :: { [string]: string } do
		if sfxFolder:FindFirstChild(nameId) then
			continue
		end
		if not parseAssetId(rawId) then
			warn(string.format("[EffectTemplatePreloader] Invalid SFX id for '%s': %s", nameId, rawId))
			continue
		end
		local s = Instance.new("Sound")
		s.Name = nameId
		s.SoundId = rawId
		s.Parent = sfxFolder
		table.insert(soundsToPreload, s)
	end

	if #soundsToPreload > 0 then
		pcall(function()
			ContentProvider:PreloadAsync(soundsToPreload)
		end)
	end

	print(string.format("[EffectTemplatePreloader] Loaded %d VFX, %d SFX into %s",
		#vfxFolder:GetChildren(), #sfxFolder:GetChildren(), ROOT_NAME))
end

return EffectTemplatePreloader
