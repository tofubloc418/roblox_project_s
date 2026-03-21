--!strict
-- Client VFX for PlaceholderSlash (particle ball, slides forward).

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

type AbilityClientContext = {
	player: Player,
	character: Model,
	abilityId: string,
	slotIndex: number,
	animator: Animator?,
}

local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local TRAVEL_STUDS = 22
local TRAVEL_SECONDS = 0.32

local PlaceholderSlash = {}

function PlaceholderSlash.OnStarted(context: AbilityClientContext)
	local character = context.character
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local look = root.CFrame.LookVector
	local head = character:FindFirstChild("Head") :: BasePart?
	local startCenter: Vector3
	if head then
		startCenter = head.Position + look * 0.55
	else
		startCenter = root.Position + root.CFrame.UpVector * 1.65 + look * 0.5
	end
	local endCenter = startCenter + look * TRAVEL_STUDS

	local ball = Instance.new("Part")
	ball.Name = "PlaceholderSlashBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * 3.0
	ball.Transparency = 1
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CastShadow = false
	ball.CFrame = CFrame.lookAt(startCenter, startCenter - look)
	ball.Parent = workspace

	local att = Instance.new("Attachment")
	att.Name = "SlashBallEmit"
	att.Parent = ball

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "SlashBall"
	pe.Parent = att
	pe.Texture = TEX_SPARK
	pe.LockedToPart = true
	pe.Rate = 585
	pe.Lifetime = NumberRange.new(0.16, 0.28)
	pe.Speed = NumberRange.new(3, 12.6)
	pe.SpreadAngle = Vector2.new(144, 144)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.65),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Color = ColorSequence.new(Color3.fromRGB(140, 220, 255))
	pe.EmissionDirection = Enum.NormalId.Front
	pe.Orientation = Enum.ParticleOrientation.VelocityParallel
	pe.VelocityInheritance = 0
	pe.Acceleration = Vector3.zero
	pe.Enabled = true

	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local alpha = math.clamp((os.clock() - t0) / TRAVEL_SECONDS, 0, 1)
		local p = startCenter:Lerp(endCenter, alpha)
		ball.CFrame = CFrame.lookAt(p, p - look)
		if alpha >= 1 then
			conn:Disconnect()
			pe.Enabled = false
			Debris:AddItem(ball, 0.55)
		end
	end)
end

return PlaceholderSlash
