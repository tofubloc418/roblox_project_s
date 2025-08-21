local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MedModule = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Med"):WaitForChild("MedConfigs"))
local MedConfigs = MedModule.Items
local MedEnums = MedModule.MedEnums

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
	self._tickerStarted = false
	return self
end

function MedService:Initialize()
	useMed.OnServerEvent:Connect(function(player: Player, tool: Instance)
		self:HandleUse(player, tool)
	end)

	-- Ensure adrenaline attribute exists for joining players
	game:GetService("Players").PlayerAdded:Connect(function(plr)
		if plr:GetAttribute("Adrenaline") == nil then
			plr:SetAttribute("Adrenaline", 0)
		end
	end)

	-- Start global adrenaline ticker once
	if not self._tickerStarted then
		self._tickerStarted = true
		task.spawn(function()
			local Players = game:GetService("Players")
			local last = os.clock()
			while true do
				local now = os.clock()
				local dt = now - last
				last = now
				-- Cap dt to avoid huge jumps on lag spikes
				dt = math.clamp(dt, 0, 0.5)

				local baseHeal = MedModule.AdrenalineHealPerSecondBase or 0
				local leakRate = MedModule.AdrenalineLeakPerSecond or 0
				local tMid = MedModule.AdrenalineThresholdMid or 50
				local tHigh = MedModule.AdrenalineThresholdHigh or 75
				local mMid = MedModule.AdrenalineMidMultiplier or 1.5
				local mHigh = MedModule.AdrenalineHighMultiplier or 2

				for _, plr in ipairs(Players:GetPlayers()) do
					local adrenaline = plr:GetAttribute("Adrenaline") or 0
					if adrenaline > 0 then
						-- Heal based on adrenaline thresholds
						local rate = baseHeal
						if adrenaline > tHigh then
							rate = baseHeal * mHigh
						elseif adrenaline > tMid then
							rate = baseHeal * mMid
						end
						local healAmount = rate * dt
						local character = plr.Character
						if character then
							local humanoid = character:FindFirstChildOfClass("Humanoid")
							if humanoid and humanoid.Health > 0 then
								humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
							end
						end

						-- Leak adrenaline over time
						local newAdr = math.max(0, adrenaline - leakRate * dt)
						if newAdr ~= adrenaline then
							plr:SetAttribute("Adrenaline", newAdr)
						end
					end
				end

				-- Tick at ~10 Hz
				task.wait(0.1)
			end
		end)
	end
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

	-- Apply instant effects
	local heal = config.healthAmount or 0
	if heal ~= 0 then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + heal)
	end

	-- Apply adrenaline attribute if configured
	-- Apply adrenaline change (Soda/Pill increase absolute amount)
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


