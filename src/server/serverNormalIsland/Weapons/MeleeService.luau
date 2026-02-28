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
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local config = MeleeConfigs[itemId] or MeleeConfigs.Fists
	if not config then
		return
	end

	-- Cooldown
	local now = os.clock()
	local last = self.playerCooldowns[player]
	if last and now - last < (config.cooldownSeconds or 0.5) then
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

	local hitModels = {}
	if config.hitShape == "Sphere" and config.hitRadius then
		local center = areaCFrame.Position
		local parts = Workspace:GetPartBoundsInRadius(center, config.hitRadius, params)
		for _, part in ipairs(parts) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m then hitModels[m] = true end
		end
	else
		local size = config.hitSize or Vector3.new(5, 4, 5)
		local parts = Workspace:GetPartBoundsInBox(areaCFrame, size, params)
		for _, part in ipairs(parts) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m then hitModels[m] = true end
		end
	end

	for model, _ in pairs(hitModels) do
		local targetHum = getHumanoid(model)
		if targetHum and targetHum.Health > 0 and model ~= character then
			DamageService:ApplyDamage(targetHum, config.damage, player)
		elseif model:GetAttribute("CrateType") then
			DamageService:ApplyDamage(model, config.damage, player)
		end
	end
end

local instance = MeleeService.new()
return instance


