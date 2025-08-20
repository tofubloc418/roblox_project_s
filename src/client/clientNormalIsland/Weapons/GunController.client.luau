local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local GunConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Weapons"):WaitForChild("GunConfigs"))

-- Wait for BulletRenderer to initialize (it's a client script, not a module)
while not _G.BulletRenderer do
	task.wait()
end
local BulletRenderer = _G.BulletRenderer

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("WeaponRemotes")
local fireGun = remotes:WaitForChild("FireGun")
local reloadGun = remotes:WaitForChild("ReloadGun")

local GunController = {}
GunController.__index = GunController

-- Resolve ONLY a BasePart named "Muzzle" directly under the Tool
local function getMuzzleCFrame(tool: Tool): CFrame?
	local node = tool:FindFirstChild("Muzzle", true)
	if node and node:IsA("Attachment") then
		return (node :: Attachment).WorldCFrame
	end
	return nil
end

function GunController.new()
	local self = setmetatable({}, GunController)
	self.equippedTool = nil
	self.config = nil
	self.reloading = false
	self.reloadPendingUntil = 0
	self.shooting = false
	self.lastShot = 0
	self.connections = {}
	self.originalWalkSpeed = 16
	return self
end

function GunController:Initialize()
	-- Listen for tool equip/unequip
	local character = player.Character or player.CharacterAdded:Wait()
	
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and GunConfigs[child.Name] then
			self:EquipGun(child)
		end
	end)
	
	character.ChildRemoved:Connect(function(child)
		if child == self.equippedTool then
			self:UnequipGun()
		end
	end)
	
	-- Handle reload input
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.R and self.equippedTool then
			self:Reload()
		end
	end)
end

function GunController:EquipGun(tool: Tool)
	self.equippedTool = tool
	local itemId = tool:GetAttribute("ItemId")
	self.config = GunConfigs[tool.Name] or (itemId and GunConfigs[itemId])
	if not self.config then
		warn("No gun config found for", tool.Name)
		return
	end
	
	-- Do not initialize ammo on client; server owns ammo state
	
	self.reloading = false
	self.shooting = false
	
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self.originalWalkSpeed = humanoid.WalkSpeed
	end
	
	-- Play equip sound
	local sounds = tool:FindFirstChild("Sounds")
	local equipSound = sounds and sounds:FindFirstChild("Gun Equip")
	if equipSound then
		equipSound:Play()
	end
	
	local currentAmmo = tool:GetAttribute("CurrentAmmo") or 0
	print(string.format("[Gun] Equipped %s - Ammo: %d/%d", tool.Name, currentAmmo, self.config.magazineCapacity))
	
	-- Setup shooting (Auto and Burst are hold-to-fire; Single is click-to-fire)
	if self.config.mode == "Auto" or self.config.mode == "Burst" then
		self.connections.activated = tool.Activated:Connect(function()
			self.shooting = true
			self:StartAutoFire()
		end)
		self.connections.deactivated = tool.Deactivated:Connect(function()
			self.shooting = false
			self:StopAutoFire()
		end)
	else
		self.connections.activated = tool.Activated:Connect(function()
			self:Fire()
		end)
	end
end

function GunController:UnequipGun()
	-- Disconnect all connections
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
	self.connections = {}
	
	-- Reset state
	self.shooting = false
	self:StopAutoFire()
	
	-- Reset walk speed
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = self.originalWalkSpeed
	end
	
	self.equippedTool = nil
	self.config = nil
end

function GunController:Fire()
	if not self.equippedTool or not self.config then return end
	if self.reloading then return end
	if self.reloadPendingUntil and tick() < self.reloadPendingUntil then return end
	
	-- Cooldown using shotDelay
	local now = tick()
	local cooldown = self.config.shotDelay or 0
	if now - self.lastShot < cooldown then
		return
	end
	
	-- Check ammo from tool attribute; require enough for this trigger
	local currentAmmo = self.equippedTool:GetAttribute("CurrentAmmo") or 0
	local burstCount = (self.config.burstCount or 1)
	local ammoCost = burstCount * (self.config.bulletsPerShot or 1)
	if currentAmmo < ammoCost then
		self:Reload()
		-- Wait for server to update ammo or reload to complete before allowing another Fire
		-- This avoids ping-ponging between empty shots and reload requests
		local startTime = tick()
		local timeout = 3
		while tick() - startTime < timeout do
			local updatedAmmo = self.equippedTool and self.equippedTool:GetAttribute("CurrentAmmo") or 0
			if updatedAmmo and updatedAmmo >= ammoCost then
				break
			end
			task.wait(0.05)
		end
		return
	end
	
	self.lastShot = now
	-- Predict ammo locally for logging only; server authoritatively updates attribute
	local predicted = currentAmmo - ammoCost
	print(string.format("[Gun] Fired - Ammo: %d/%d", predicted, self.config.magazineCapacity))
	
	-- Get mouse position
	local mouse = player:GetMouse()
	local mousePosition = mouse.Hit.Position

	-- Send to server immediately so authoritative burst starts without waiting on client visuals
	print(string.format("[Gun] Sending FireServer with tool %s to position %s", 
		self.equippedTool.Name, tostring(mousePosition)))
	fireGun:FireServer(self.equippedTool, mousePosition)
	print("[Gun] FireServer sent")
	
	-- Create visual bullets with new renderer
	local muzzleCFrame = getMuzzleCFrame(self.equippedTool)
	if muzzleCFrame then
		local burstShots = (self.config.burstCount or 1)
		local gap = self.config.burstDelay or 0.05
		for n = 1, burstShots do
			for i = 1, self.config.bulletsPerShot do
				-- Re-evaluate muzzle each bullet for accuracy
				local currentMuzzle = getMuzzleCFrame(self.equippedTool) or muzzleCFrame
				local muzzlePos = currentMuzzle.Position
				local baseDirection = (mousePosition - muzzlePos).Unit
				local spread = math.rad(self.config.bulletSpread)
				
				-- Apply random spread per bullet
				local spreadX = (math.random() - 0.5) * spread
				local spreadY = (math.random() - 0.5) * spread
				
				local direction = CFrame.lookAt(muzzlePos, muzzlePos + baseDirection)
				direction = direction * CFrame.Angles(spreadX, spreadY, 0)
				direction = direction.LookVector
				
				-- Render local bullet visual for this pellet/shot
				BulletRenderer:RenderLocalBullet(muzzlePos, direction, self.config.bulletSpeed, self.equippedTool.Name)
			end
			if n < burstShots then
				task.wait(gap)
			end
		end
	end
	
	-- Play shot sound
	local sounds = self.equippedTool:FindFirstChild("Sounds")
	local shotSound = sounds and sounds:FindFirstChild("Gun Shot")
	if shotSound then
		shotSound:Play()
	end
	
	-- Apply movement slowdown
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = self.originalWalkSpeed * self.config.playerSlowdown
		task.wait(0.2)
		if humanoid then
			humanoid.WalkSpeed = self.originalWalkSpeed
		end
	end
	
	-- Auto reload if empty after firing
	if predicted <= 0 then
		self:Reload()
	end
end

function GunController:StartAutoFire()
	if self.autoFireConnection then return end
	
	self.autoFireConnection = RunService.Heartbeat:Connect(function()
		if self.shooting and not self.reloading then
			self:Fire()
		end
	end)
end

function GunController:StopAutoFire()
	if self.autoFireConnection then
		self.autoFireConnection:Disconnect()
		self.autoFireConnection = nil
	end
end

function GunController:Reload()
	if not self.equippedTool or not self.config then return end
	if self.reloading then return end
	
	local currentAmmo = self.equippedTool:GetAttribute("CurrentAmmo") or 0
	if currentAmmo >= self.config.magazineCapacity then return end
	
	self.reloading = true
	print(string.format("[Gun] Reloading %s...", self.equippedTool.Name))
	
	-- Play reload sound
	local sounds = self.equippedTool:FindFirstChild("Sounds")
	local reloadSound = sounds and sounds:FindFirstChild("Gun Reload")
	if reloadSound then
		reloadSound:Play()
	end
	
	-- Stop shooting during reload
	self.shooting = false
	
	task.wait(self.config.reloadTime)
	
	if self.equippedTool then -- Check tool is still equipped
		-- Ask server to authoritatively reload
		self.reloadPendingUntil = tick() + math.max(0.5, (self.config.reloadTime or 0) * 0.25)
		reloadGun:FireServer(self.equippedTool)
		-- Wait for ammo attribute to replicate fully to magazine capacity
		local timeoutAt = tick() + 3
		local target = self.config.magazineCapacity or 1
		while tick() < timeoutAt do
			local updatedAmmo = self.equippedTool:GetAttribute("CurrentAmmo") or 0
			if updatedAmmo >= target then
				break
			end
			task.wait(0.05)
		end
		self.reloadPendingUntil = 0
		self.reloading = false
	end
end

-- Old CreateVisualBullet function removed - now using BulletRenderer

-- Initialize singleton
local controller = GunController.new()
controller:Initialize()

return controller
