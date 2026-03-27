--!strict
-- Snapshots Humanoid locomotion; sets RootMotion_LocomotionLock on the character and owning Player for client sync.

local Players = game:GetService("Players")

local ATTR_LOCOMOTION_LOCK = "RootMotion_LocomotionLock"

local STATES: { Enum.HumanoidStateType } = {
	Enum.HumanoidStateType.Running,
	Enum.HumanoidStateType.Climbing,
}

local LocomotionSuppress = {}

function LocomotionSuppress.begin(humanoid: Humanoid): () -> ()
	local characterModel: Model? = nil
	local lockedPlayer: Player? = nil
	local parent = humanoid.Parent
	if parent and parent:IsA("Model") then
		local model = parent :: Model
		characterModel = model
		model:SetAttribute(ATTR_LOCOMOTION_LOCK, true)
		local plr = Players:GetPlayerFromCharacter(model)
		if plr then
			lockedPlayer = plr
			plr:SetAttribute(ATTR_LOCOMOTION_LOCK, true)
		end
	end

	local snapWalk = humanoid.WalkSpeed
	local snapJumpHeight = humanoid.JumpHeight
	local snapUseJumpPower = humanoid.UseJumpPower
	local snapJumpPower = humanoid.JumpPower

	local stateSnaps: { { s: Enum.HumanoidStateType, on: boolean } } = {}
	for _, st in STATES do
		table.insert(stateSnaps, { s = st, on = humanoid:GetStateEnabled(st) })
		pcall(function()
			humanoid:SetStateEnabled(st, false)
		end)
	end

	humanoid.WalkSpeed = 0
	if snapUseJumpPower then
		humanoid.JumpPower = 0
	else
		humanoid.JumpHeight = 0
	end

	return function()
		if characterModel then
			characterModel:SetAttribute(ATTR_LOCOMOTION_LOCK, false)
		end
		if lockedPlayer then
			lockedPlayer:SetAttribute(ATTR_LOCOMOTION_LOCK, false)
		end

		humanoid.WalkSpeed = snapWalk
		if snapUseJumpPower then
			humanoid.JumpPower = snapJumpPower
		else
			humanoid.JumpHeight = snapJumpHeight
		end
		for _, row in stateSnaps do
			pcall(function()
				humanoid:SetStateEnabled(row.s, row.on)
			end)
		end
	end
end

return LocomotionSuppress
