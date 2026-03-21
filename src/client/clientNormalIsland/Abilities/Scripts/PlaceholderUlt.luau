--!strict
-- PlaceholderUlt: omni burst from torso center; staggered waves with rising speed read as an expanding shell.

local Debris = game:GetService("Debris")

type AbilityClientContext = {
	player: Player,
	character: Model,
	abilityId: string,
	slotIndex: number,
	animator: Animator?,
}

local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local WAVE_COUNT = 7
local WAVE_INTERVAL = 0.052

local PlaceholderUlt = {}

function PlaceholderUlt.OnStarted(context: AbilityClientContext)
	local character = context.character
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local att = Instance.new("Attachment")
	att.Name = "PlaceholderUltBody"
	att.Position = Vector3.new(0, 1, 0)
	att.Parent = root

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "UltExpand"
	pe.Parent = att
	pe.Texture = TEX_SMOKE
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.55, 0.95)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 1.2
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.35, 1.1),
		NumberSequenceKeypoint.new(1, 1.85),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.65, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 120)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(200, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 40, 120)),
	})
	pe.EmissionDirection = Enum.NormalId.Front
	pe.Orientation = Enum.ParticleOrientation.VelocityParallel
	pe.VelocityInheritance = 0
	pe.Acceleration = Vector3.zero

	task.spawn(function()
		for wave = 1, WAVE_COUNT do
			local v0 = 4 + wave * 7
			pe.Speed = NumberRange.new(v0, v0 + 10)
			pe:Emit(48)
			if wave < WAVE_COUNT then
				task.wait(WAVE_INTERVAL)
			end
		end
		Debris:AddItem(att, 2.2)
	end)
end

return PlaceholderUlt
