--!strict
--[[
	Blocky R15 appearance + Humanoid scale NumberValues from PlayerConfig.
	R15 work runs deferred after ApplyDescription; then CharacterAttachmentSetup runs.
	R6 only sets rig type here; Initializer applies attachments after humanoid stats.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig")) :: any
local MovementAnimationConfig =
	require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MovementAnimationConfig")) :: any
local CharacterAttachmentSetup = require(script.Parent:WaitForChild("CharacterAttachmentSetup"))

local BlockyCharacterSetup = {}

local function applyBodyScaleNumberValues(humanoid: Humanoid)
	local scale = PlayerConfig.scale
	if not scale then
		return
	end
	local function setScale(name: string, value: number)
		local s: Instance? = humanoid:FindFirstChild(name)
		if not s then
			local nv = Instance.new("NumberValue")
			nv.Name = name
			nv.Parent = humanoid
			s = nv
		end
		if s:IsA("NumberValue") then
			s.Value = value
		end
	end
	setScale("BodyHeightScale", scale.height)
	setScale("BodyWidthScale", scale.width)
	setScale("BodyDepthScale", scale.depth)
	setScale("HeadScale", scale.head)
end

local function applyBlockyR15Description(humanoid: Humanoid)
	local ok, dc = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok or not dc then
		return
	end
	dc.Head = 0
	dc.Torso = 0
	dc.LeftArm = 0
	dc.RightArm = 0
	dc.LeftLeg = 0
	dc.RightLeg = 0
	dc.HeadScale = 1
	dc.HeightScale = 1
	dc.WidthScale = 1
	dc.DepthScale = 1
	dc.BodyTypeScale = 0
	dc.ProportionScale = 0
	MovementAnimationConfig.ApplyHumanoidDescriptionOverrides(dc)
	pcall(function()
		humanoid:ApplyDescription(dc)
	end)
	applyBodyScaleNumberValues(humanoid)
end

--- Sets rig type and, for R15, deferred blocky body + scale + attachment sockets.
function BlockyCharacterSetup.Apply(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if PlayerConfig.humanoidRigType == "R15" then
		humanoid.RigType = Enum.HumanoidRigType.R15
		task.defer(function()
			applyBlockyR15Description(humanoid)
			CharacterAttachmentSetup.Apply(character)
		end)
	else
		humanoid.RigType = Enum.HumanoidRigType.R6
	end
end

return BlockyCharacterSetup
