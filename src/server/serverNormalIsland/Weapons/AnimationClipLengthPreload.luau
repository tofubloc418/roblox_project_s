--!strict
-- Loads each WeaponBasicAttackProfiles animation once on a throwaway rig and fills AnimationClipLengthCache.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeaponBasicAttackProfiles =
	require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("AnimationProfiles"):WaitForChild("WeaponBasicAttackProfiles") :: ModuleScript) :: any
local AnimationClipLengthCache =
	require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationClipLengthCache") :: ModuleScript) :: any

local AnimationClipLengthPreload = {}

local function createProbeAnimator(): (Animator?, Folder?)
	local folder = Instance.new("Folder")
	folder.Name = "__AnimationClipLengthProbe"
	folder.Parent = Workspace

	local model = Instance.new("Model")
	model.Name = "Rig"
	model.Parent = folder

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Size = Vector3.new(2, 2, 1)
	root.Parent = model

	model.PrimaryPart = root

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	return animator, folder
end

function AnimationClipLengthPreload.preloadWeaponBasicAttackLibrary(): ()
	local animator, folder = createProbeAnimator()
	if not animator then
		return
	end

	local seen: { [string]: boolean } = {}
	for _, profile in pairs(WeaponBasicAttackProfiles.GetAll()) do
		local assetId = profile.animationId
		if type(assetId) == "string" and assetId ~= "" and assetId ~= "rbxassetid://0" and not seen[assetId] then
			seen[assetId] = true
			AnimationClipLengthCache.probeAndCache(animator, assetId)
		end
	end

	if folder then
		folder:Destroy()
	end
end

return AnimationClipLengthPreload
