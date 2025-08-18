--[[
	BulletVisuals
	Shared configuration and utilities for bullet rendering
]]

local BulletVisuals = {}

-- Bullet visual configuration
BulletVisuals.Config = {
	-- Bullet appearance
	bulletSize = Vector3.new(0.1, 0.1, 0.5),
	bulletColor = Color3.fromRGB(180, 170, 150), -- Metallic gray
	bulletMaterial = Enum.Material.Metal,
	bulletTransparency = 0.2,
	
	-- Trail appearance
	trailColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)), -- Light yellow/white
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 200)), -- Gray
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150)), -- Darker gray
	}),
	trailTransparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	}),
	trailLifetime = 0.3,
	trailMinLength = 0,
	trailMaxLength = 20,
	trailWidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 0),
	}),
	
	-- Performance
	maxPoolSize = 50, -- Maximum bullets in pool
	bulletLifetime = 2, -- Seconds before bullet is recycled
}

-- Create a bullet visual with trail
function BulletVisuals.CreateBullet(): (Part, Trail)
	local bullet = Instance.new("Part")
	bullet.Name = "Bullet"
	bullet.Size = BulletVisuals.Config.bulletSize
	bullet.Color = BulletVisuals.Config.bulletColor
	bullet.Material = BulletVisuals.Config.bulletMaterial
	bullet.Transparency = BulletVisuals.Config.bulletTransparency
	bullet.CanCollide = false
	bullet.CanQuery = false
	bullet.CanTouch = false
	bullet.Anchored = true
	bullet.CFrame = CFrame.new(0, -1000, 0) -- Start hidden
	
	-- Add attachments for trail
	local frontAttachment = Instance.new("Attachment")
	frontAttachment.Name = "Front"
	frontAttachment.Position = Vector3.new(0, 0, -bullet.Size.Z/2)
	frontAttachment.Parent = bullet
	
	local backAttachment = Instance.new("Attachment")
	backAttachment.Name = "Back"
	backAttachment.Position = Vector3.new(0, 0, bullet.Size.Z/2)
	backAttachment.Parent = bullet
	
	-- Create smoke trail
	local trail = Instance.new("Trail")
	trail.Name = "SmokeTrail"
	trail.Attachment0 = backAttachment
	trail.Attachment1 = frontAttachment
	trail.Color = BulletVisuals.Config.trailColor
	trail.Transparency = BulletVisuals.Config.trailTransparency
	trail.Lifetime = BulletVisuals.Config.trailLifetime
	trail.MinLength = BulletVisuals.Config.trailMinLength
	trail.MaxLength = BulletVisuals.Config.trailMaxLength
	trail.WidthScale = BulletVisuals.Config.trailWidthScale
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = bullet
	
	return bullet, trail
end

-- Lightweight bullet data for networking
export type BulletData = {
	origin: Vector3,
	direction: Vector3,
	speed: number,
	gunName: string,
	shooterId: number,
}

return BulletVisuals
