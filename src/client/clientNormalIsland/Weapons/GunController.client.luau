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

local GunController = {}
GunController.__index = GunController

-- Try to find a muzzle attachment/part to use as the spawn origin
local function getMuzzleCFrame(tool: Tool): CFrame?
	local function findMuzzleIn(instance: Instance): Instance?
		-- Prefer an Attachment named "Muzzle" or containing "Muzzle"
		for _, obj in ipairs(instance:GetDescendants()) do
			if obj:IsA("Attachment") then
				local name = string.lower(obj.Name)
				if name == "muzzle" or string.find(name, "muzzle") then
					return obj
				end
			end
		end
		-- Fallback to a BasePart named "Muzzle"/"Barrel"
		for _, obj in ipairs(instance:GetDescendants()) do
			if obj:IsA("BasePart") then
				local name = string.lower(obj.Name)
				if name == "muzzle" or name == "barrel" or string.find(name, "muzzle") then
					return obj
				end
			end
		end
		return nil
	end

	local found = findMuzzleIn(tool)
	if found then
		if found:IsA("Attachment") then
			return (found :: Attachment).WorldCFrame
		elseif found:IsA("BasePart") then
			return (found :: BasePart).CFrame
		end
	end

	-- Fallback to handle
	local handle = tool:FindFirstChild("Handle")
	return handle and (handle :: BasePart).CFrame or nil
end

function GunController.new()
	local self = setmetatable({}, GunController)
	self.equippedTool = nil
	self.config = nil
	self.reloading = false
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
	
	-- Initialize CurrentAmmo attribute if not set
	if not tool:GetAttribute("CurrentAmmo") then
		tool:SetAttribute("CurrentAmmo", self.config.magazineCapacity)
	end
	
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
	
	-- Setup shooting
	if self.config.auto then
		-- Full auto
		self.connections.activated = tool.Activated:Connect(function()
			self.shooting = true
			self:StartAutoFire()
		end)
		
		self.connections.deactivated = tool.Deactivated:Connect(function()
			self.shooting = false
			self:StopAutoFire()
		end)
	else
		-- Semi auto
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
	
	-- Check fire rate cooldown
	local now = tick()
	local cooldown = 1 / self.config.fireRate
	if now - self.lastShot < cooldown then
		return
	end
	
	-- Check ammo from tool attribute
	local currentAmmo = self.equippedTool:GetAttribute("CurrentAmmo") or 0
	if currentAmmo <= 0 then
		self:Reload()
		return
	end
	
	self.lastShot = now
	-- Update ammo attribute
	self.equippedTool:SetAttribute("CurrentAmmo", currentAmmo - 1)
	currentAmmo = currentAmmo - 1
	
	print(string.format("[Gun] Fired - Ammo: %d/%d", currentAmmo, self.config.magazineCapacity))
	
	-- Get mouse position
	local mouse = player:GetMouse()
	local mousePosition = mouse.Hit.Position
	
	-- Create visual bullets with new renderer
	local muzzleCFrame = getMuzzleCFrame(self.equippedTool)
	if muzzleCFrame then
		for i = 1, self.config.bulletsPerShot do
			-- Calculate direction with spread from muzzle
			local muzzlePos = muzzleCFrame.Position
			local baseDirection = (mousePosition - muzzlePos).Unit
			local spread = math.rad(self.config.bulletSpread)
			
			-- Apply random spread
			local spreadX = (math.random() - 0.5) * spread
			local spreadY = (math.random() - 0.5) * spread
			
			local direction = CFrame.lookAt(muzzlePos, muzzlePos + baseDirection)
			direction = direction * CFrame.Angles(spreadX, spreadY, 0)
			direction = direction.LookVector
			
			-- Use the new bullet renderer
			BulletRenderer:RenderLocalBullet(muzzlePos, direction, self.config.bulletSpeed, self.equippedTool.Name)
		end
	end
	
	-- Send to server
	print(string.format("[Gun] Sending FireServer with tool %s to position %s", 
		self.equippedTool.Name, tostring(mousePosition)))
	fireGun:FireServer(self.equippedTool, mousePosition)
	print("[Gun] FireServer sent")
	
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
	
	-- Auto reload if empty
	if currentAmmo <= 0 then
		task.wait(0.1)
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
		-- Reset ammo to full magazine
		self.equippedTool:SetAttribute("CurrentAmmo", self.config.magazineCapacity)
		self.reloading = false
		print(string.format("[Gun] Reloaded - Ammo: %d/%d", self.config.magazineCapacity, self.config.magazineCapacity))
	end
end

-- Old CreateVisualBullet function removed - now using BulletRenderer

-- Initialize singleton
local controller = GunController.new()
controller:Initialize()

return controller
