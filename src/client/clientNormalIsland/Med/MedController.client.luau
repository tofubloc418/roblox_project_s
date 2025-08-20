local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local MedConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Med"):WaitForChild("MedConfigs"))

local remotes = ReplicatedStorage:WaitForChild("MedRemotes")
local useMed = remotes:WaitForChild("UseMed")

local MedController = {}
MedController.__index = MedController

function MedController.new()
	local self = setmetatable({}, MedController)
	self.equippedTool = nil
	self.config = nil
	self.connections = {}
	self.using = false
	self.originalWalkSpeed = 16
	return self
end

function MedController:Initialize()
	local character = player.Character or player.CharacterAdded:Wait()

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and (MedConfigs[child.Name] or (child:GetAttribute("ItemId") and MedConfigs[child:GetAttribute("ItemId")])) then
			self:EquipMed(child)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child == self.equippedTool then
			self:UnequipMed()
		end
	end)
end

function MedController:EquipMed(tool: Tool)
	self.equippedTool = tool
	local itemId = tool:GetAttribute("ItemId") or tool.Name
	self.config = MedConfigs[itemId]
	if not self.config then
		warn("No med config found for", tool.Name)
		return
	end

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self.originalWalkSpeed = humanoid.WalkSpeed
	end

	self.connections.activated = tool.Activated:Connect(function()
		self:Use()
	end)
end

function MedController:UnequipMed()
	for _, c in pairs(self.connections) do
		c:Disconnect()
	end
	self.connections = {}
	self.equippedTool = nil
	self.config = nil
	self.using = false
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = self.originalWalkSpeed
	end
end

function MedController:Use()
	if not self.equippedTool or not self.config or self.using then return end
	self.using = true

	-- Fire to server immediately so authoritative channel starts
	useMed:FireServer(self.equippedTool)

	-- Local feedback: slowdown, sound, particles during channel
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local useSpeed = self.config.useWalkSpeed
	if humanoid and useSpeed then
		humanoid.WalkSpeed = useSpeed
	end

	local sound = self.equippedTool:FindFirstChild("UseSound")
	if sound and sound:IsA("Sound") then
		sound:Play()
	end

	local usePart = self.equippedTool:FindFirstChild("UseParticle")
	local emitter = usePart and usePart:FindFirstChildOfClass("ParticleEmitter")
	if emitter then
		emitter.Enabled = true
	end

	task.wait(self.config.useTime or 0)

	if emitter then
		emitter.Enabled = false
	end
	if humanoid and self.originalWalkSpeed then
		humanoid.WalkSpeed = self.originalWalkSpeed
	end

	self.using = false
end

local controller = MedController.new()
controller:Initialize()

return controller


