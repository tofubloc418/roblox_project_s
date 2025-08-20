local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MedConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Med"):WaitForChild("MedConfigs"))
local MedEnums = MedConfigs.MedEnums

local remotes = ReplicatedStorage:FindFirstChild("MedRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "MedRemotes"
	remotes.Parent = ReplicatedStorage
end

local useMed = remotes:FindFirstChild("UseMed") or Instance.new("RemoteEvent")
useMed.Name = "UseMed"
useMed.Parent = remotes

local MedService = {}
MedService.__index = MedService

function MedService.new()
	local self = setmetatable({}, MedService)
	self.playerUsing = {}
	return self
end

function MedService:Initialize()
	useMed.OnServerEvent:Connect(function(player: Player, tool: Instance)
		self:HandleUse(player, tool)
	end)
end

function MedService:HandleUse(player: Player, tool: Instance)
	local character = player.Character
	if not character or not tool or not tool:IsA("Tool") then return end
	if tool.Parent ~= character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if self.playerUsing[player] then
		return
	end

	local itemId = tool:GetAttribute("ItemId") or tool.Name
	local config = MedConfigs[itemId]
	if not config then
		return
	end

	self.playerUsing[player] = true

	-- Channel time before applying effects
	task.wait(config.useTime or 0)

	-- Re-validate still alive and still owning tool
	if not character.Parent then
		self.playerUsing[player] = nil
		return
	end
	if humanoid.Health <= 0 then
		self.playerUsing[player] = nil
		return
	end

	-- Apply instant heal or start HoT
	if config.mode == MedEnums.UsageMode.OverTime then
		local duration = config.hotDuration or 0
		local interval = math.max(0.05, config.tickInterval or 0.5)
		local perTick = config.healPerTick or 0
		local elapsed = 0
		while elapsed < duration and humanoid.Parent do
			if humanoid.Health <= 0 then break end
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + perTick)
			elapsed += interval
			task.wait(interval)
		end
	else
		local heal = config.healthAmount or 0
		if heal ~= 0 then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + heal)
		end
	end

	-- Apply adrenaline attribute if configured
	if config.adrenalineDelta and config.adrenalineDelta ~= 0 then
		local current = player:GetAttribute("Adrenaline") or 0
		local newValue = math.clamp(current + config.adrenalineDelta, 0, 100)
		player:SetAttribute("Adrenaline", newValue)
	end

	-- Consume one stack if present
	if tool and tool.Parent and tool:IsDescendantOf(character) then
		local currentStack = tool:GetAttribute("CurrentStack") or 1
		currentStack -= 1
		if currentStack <= 0 then
			tool:Destroy()
		else
			tool:SetAttribute("CurrentStack", currentStack)
		end
	end

	self.playerUsing[player] = nil
end

local instance = MedService.new()
return instance


