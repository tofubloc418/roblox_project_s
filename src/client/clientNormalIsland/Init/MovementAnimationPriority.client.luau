--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type MovementAnimCfg = {
	LocomotionIdSet: { [number]: boolean },
	ParseAssetIdNumber: (string?) -> number?,
}

local MovementAnimationConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MovementAnimationConfig")) :: MovementAnimCfg

local localPlayer = Players.LocalPlayer
local bumpSet = MovementAnimationConfig.LocomotionIdSet

local function hookAnimator(animator: Animator)
	animator.AnimationPlayed:Connect(function(track: AnimationTrack)
		local anim = track.Animation
		if not anim then
			return
		end
		local num = MovementAnimationConfig.ParseAssetIdNumber(anim.AnimationId)
		if num and bumpSet[num] then
			track.Priority = Enum.AnimationPriority.Movement
		end
	end)
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 15) :: Humanoid?
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
		or (humanoid:WaitForChild("Animator", 15) :: Animator?)
	if not animator then
		return
	end

	hookAnimator(animator)
end

if localPlayer.Character then
	task.spawn(onCharacterAdded, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
