--[[
	BulletRenderer (Client)
	Efficient bullet rendering system using object pooling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local BulletVisuals = require(ReplicatedStorage:WaitForChild("Weapons"):WaitForChild("BulletVisuals"))

type BulletData = BulletVisuals.BulletData

local BulletRenderer = {}
BulletRenderer.__index = BulletRenderer

function BulletRenderer.new()
	local self = setmetatable({}, BulletRenderer)
	
	-- Object pool for bullets
	self.bulletPool = {}
	self.activeBullets = {}
	
	-- Pre-create bullets for the pool
	self:InitializePool()
	
	-- Bullet container
	local container = workspace:FindFirstChild("BulletContainer")
	if not container then
		container = Instance.new("Folder")
		container.Name = "BulletContainer"
		container.Parent = workspace
	end
	self.container = container
	
	return self
end

function BulletRenderer:InitializePool()
	for i = 1, BulletVisuals.Config.maxPoolSize do
		local bullet, trail = BulletVisuals.CreateBullet()
		bullet.Parent = nil -- Keep out of workspace until needed
		table.insert(self.bulletPool, {
			part = bullet,
			trail = trail,
			inUse = false,
		})
	end
end

function BulletRenderer:GetBulletFromPool()
	-- Find an available bullet
	for _, bulletData in ipairs(self.bulletPool) do
		if not bulletData.inUse then
			bulletData.inUse = true
			return bulletData
		end
	end
	
	-- If pool is exhausted, create a new one (but warn)
	warn("Bullet pool exhausted! Consider increasing pool size")
	local bullet, trail = BulletVisuals.CreateBullet()
	local bulletData = {
		part = bullet,
		trail = trail,
		inUse = true,
	}
	table.insert(self.bulletPool, bulletData)
	return bulletData
end

function BulletRenderer:ReturnToPool(bulletData)
	bulletData.inUse = false
	bulletData.part.Parent = nil
	bulletData.part.CFrame = CFrame.new(0, -1000, 0)
	bulletData.trail.Enabled = false
	
	-- Remove from active bullets
	for i, active in ipairs(self.activeBullets) do
		if active.bulletData == bulletData then
			table.remove(self.activeBullets, i)
			break
		end
	end
end

function BulletRenderer:RenderBullet(data: BulletData, isLocalShot: boolean)
	local bulletData = self:GetBulletFromPool()
	if not bulletData then return end
	
	local bullet = bulletData.part
	local trail = bulletData.trail
	
	-- Position and orient the bullet
	bullet.CFrame = CFrame.lookAt(data.origin, data.origin + data.direction)
	bullet.Parent = self.container
	
	-- Enable trail
	trail.Enabled = true
	
	-- Store active bullet info
	local activeBullet = {
		bulletData = bulletData,
		startTime = tick(),
		origin = data.origin,
		direction = data.direction,
		speed = data.speed,
		distance = 0,
		maxDistance = (data.hitPosition and (data.hitPosition - data.origin).Magnitude) or 500,
		isLocalShot = isLocalShot,
		shooterId = data.shooterId,
	}
	
	table.insert(self.activeBullets, activeBullet)
	
	-- If this is someone else's bullet, add a slight delay to account for network latency
	if not isLocalShot then
		activeBullet.distance = data.speed * 0.05 -- Advance by ~50ms to compensate for latency
	end
end

function BulletRenderer:Update(deltaTime)
	local toRemove = {}
	
	for i, activeBullet in ipairs(self.activeBullets) do
		local bulletData = activeBullet.bulletData
		local bullet = bulletData.part
		
		-- Update bullet position
		local moveDistance = activeBullet.speed * deltaTime
		activeBullet.distance = activeBullet.distance + moveDistance
		
		-- Check if bullet should be removed
		if activeBullet.distance >= activeBullet.maxDistance or 
		   (tick() - activeBullet.startTime) > BulletVisuals.Config.bulletLifetime then
			table.insert(toRemove, activeBullet)
		else
			-- Update position
			local newPosition = activeBullet.origin + (activeBullet.direction * activeBullet.distance)
			bullet.CFrame = CFrame.lookAt(newPosition, newPosition + activeBullet.direction)
		end
	end
	
	-- Return bullets to pool
	for _, activeBullet in ipairs(toRemove) do
		self:ReturnToPool(activeBullet.bulletData)
	end
end

function BulletRenderer:Initialize()
	-- Update loop for bullet movement
	RunService.Heartbeat:Connect(function(deltaTime)
		self:Update(deltaTime)
	end)
	
	-- Listen for bullet visual events
	local remotes = ReplicatedStorage:WaitForChild("WeaponRemotes")
	local bulletVisualEvent = remotes:FindFirstChild("BulletVisual")
	if not bulletVisualEvent then
		bulletVisualEvent = Instance.new("RemoteEvent")
		bulletVisualEvent.Name = "BulletVisual"
		bulletVisualEvent.Parent = remotes
	end
	
	-- Handle networked bullets from other players
	bulletVisualEvent.OnClientEvent:Connect(function(data: BulletData)
		-- Don't render our own bullets from the server (we already rendered them locally)
		if data.shooterId ~= localPlayer.UserId then
			self:RenderBullet(data, false)
		end
	end)

	-- Clamp tracers to actual server hit
	local bulletHitEvent = remotes:FindFirstChild("BulletHit") or Instance.new("RemoteEvent")
	bulletHitEvent.Name = "BulletHit"
	bulletHitEvent.Parent = remotes
	bulletHitEvent.OnClientEvent:Connect(function(data)
		local shooterId = data.shooterId
		local hitPosition = data.hitPosition :: Vector3?
		local direction = data.direction :: Vector3
		if not hitPosition then return end
		-- Find best matching active bullet from same shooter via direction alignment and closest origin
		local best, bestScore = nil, -math.huge
		for _, active in ipairs(self.activeBullets) do
			if active.shooterId == shooterId then
				local score = active.direction:Dot(direction)
				if score > bestScore then
					best = active
					bestScore = score
				end
			end
		end
		if best then
			best.maxDistance = (hitPosition - best.origin).Magnitude
		end
	end)
end

-- Export for use by GunController
function BulletRenderer:RenderLocalBullet(origin: Vector3, direction: Vector3, speed: number, gunName: string)
	local data: BulletData = {
		origin = origin,
		direction = direction,
		speed = speed,
		gunName = gunName,
		shooterId = localPlayer.UserId,
	}
	self:RenderBullet(data, true)
end

-- Create singleton
local renderer = BulletRenderer.new()
renderer:Initialize()

-- Export the renderer
_G.BulletRenderer = renderer

return renderer
