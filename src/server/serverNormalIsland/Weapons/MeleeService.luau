local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local MeleeConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Weapons"):WaitForChild("MeleeConfigs"))

local remotes = ReplicatedStorage:FindFirstChild("MeleeRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "MeleeRemotes"
	remotes.Parent = ReplicatedStorage
end

local meleeAttack = remotes:FindFirstChild("MeleeAttack") or Instance.new("RemoteEvent")
meleeAttack.Name = "MeleeAttack"
meleeAttack.Parent = remotes

local MeleeService = {}
MeleeService.__index = MeleeService

function MeleeService.new()
	local self = setmetatable({}, MeleeService)
	self.playerCooldowns = {}
	return self
end

function MeleeService:Initialize()
	meleeAttack.OnServerEvent:Connect(function(player: Player, itemId: string)
		self:HandleAttack(player, itemId)
	end)
end

local function getHumanoid(model: Instance)
	if not model or not model:IsA("Model") then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

function MeleeService:HandleAttack(player: Player, itemId: string)
	local character = player.Character
	if not character then
		print(string.format("[Melee] Blocked: no character player=%s item=%s", player.Name, tostring(itemId)))
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		print(string.format("[Melee] Blocked: dead/no humanoid player=%s item=%s", player.Name, tostring(itemId)))
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		print(string.format("[Melee] Blocked: no HRP player=%s item=%s", player.Name, tostring(itemId)))
		return
	end

	local config = MeleeConfigs[itemId] or MeleeConfigs.Fists
	if not config then
		print(string.format("[Melee] Blocked: no config player=%s item=%s", player.Name, tostring(itemId)))
		return
	end

	print(string.format("[Melee] Attack start player=%s item=%s dmg=%.1f cooldown=%.2f shape=%s",
		player.Name,
		tostring(itemId),
		config.damage or -1,
		config.cooldownSeconds or -1,
		tostring(config.hitShape)
	))

	-- Cooldown
	local now = os.clock()
	local last = self.playerCooldowns[player]
	if last and now - last < (config.cooldownSeconds or 0.5) then
		print(string.format("[Melee] Blocked: cooldown player=%s dt=%.2f need=%.2f", player.Name, now - last, config.cooldownSeconds or 0.5))
		return
	end
	self.playerCooldowns[player] = now

	-- Build overlap params to ignore self
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	-- Compute area
	local offset = config.hitOffset or Vector3.new(0, 0, -3)
	local yaw = math.rad(config.yawDegrees or 0)
	local areaCFrame = hrp.CFrame * CFrame.new(offset.X, offset.Y, offset.Z) * CFrame.Angles(0, yaw, 0)
	print(string.format("[Melee] Area hrp=(%.1f,%.1f,%.1f) center=(%.1f,%.1f,%.1f) yaw=%.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z, areaCFrame.Position.X, areaCFrame.Position.Y, areaCFrame.Position.Z, math.deg(yaw)))

	local hitModels = {}
	if config.hitShape == "Sphere" and config.hitRadius then
		local center = areaCFrame.Position
		local parts = Workspace:GetPartBoundsInRadius(center, config.hitRadius, params)
		print(string.format("[Melee] Query sphere r=%.1f parts=%d", config.hitRadius, #parts))
		for _, part in ipairs(parts) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m then hitModels[m] = true end
		end
	else
		local size = config.hitSize or Vector3.new(5, 4, 5)
		local parts = Workspace:GetPartBoundsInBox(areaCFrame, size, params)
		print(string.format("[Melee] Query box size=(%.1f,%.1f,%.1f) parts=%d", size.X, size.Y, size.Z, #parts))
		for _, part in ipairs(parts) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m then hitModels[m] = true end
		end
	end

	local numModels = 0
	for model, _ in pairs(hitModels) do numModels += 1 end
	print(string.format("[Melee] Unique models hit=%d", numModels))

	for model, _ in pairs(hitModels) do
		local targetHum = getHumanoid(model)
		if targetHum and targetHum.Health > 0 and model ~= character then
			print(string.format("[Melee] ApplyDamage humanoid=%s hp=%.1f dmg=%.1f", model.Name, targetHum.Health, config.damage))
			DamageService:ApplyDamage(targetHum, config.damage, player)
		elseif model:GetAttribute("CrateType") then
			print(string.format("[Melee] ApplyDamage crate=%s dmg=%.1f", model.Name, config.damage))
			DamageService:ApplyDamage(model, config.damage, player)
		else
			print(string.format("[Melee] Skip model=%s (no humanoid/crate)", model.Name))
		end
	end

	print("[Melee] Attack end")
end

local instance = MeleeService.new()
return instance


