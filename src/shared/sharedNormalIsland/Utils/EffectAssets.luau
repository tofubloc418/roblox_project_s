--!strict
--[[
	Shared helpers for cloning VFX templates and playing SFX by nameID.
	All templates live under ReplicatedStorage.EffectAssets (populated by the
	server-side EffectTemplatePreloader at boot).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectAssets = {}

local function vfxFolder(): Folder?
	local root = ReplicatedStorage:FindFirstChild("EffectAssets")
	return root and root:FindFirstChild("VFX") :: Folder?
end

local function sfxFolder(): Folder?
	local root = ReplicatedStorage:FindFirstChild("EffectAssets")
	return root and root:FindFirstChild("SFX") :: Folder?
end

function EffectAssets.CloneVfx(nameId: string): Instance?
	if nameId == "" then
		return nil
	end
	local folder = vfxFolder()
	if not folder then
		return nil
	end
	local template = folder:FindFirstChild(nameId)
	if not template then
		return nil
	end
	return template:Clone()
end

function EffectAssets.PlaySound(nameId: string, parent: Instance)
	if nameId == "" then
		return
	end
	local folder = sfxFolder()
	if not folder then
		return
	end
	local template = folder:FindFirstChild(nameId)
	if template and template:IsA("Sound") then
		local s = template:Clone()
		s.Parent = parent
		s:Play()
		s.Ended:Connect(function()
			s:Destroy()
		end)
		return
	end
end

return EffectAssets
