local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local GunConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Weapons"):WaitForChild("GunConfigs"))
local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))

local GunService = {}
GunService.__index = GunService

-- Remote events folder
local remotes = ReplicatedStorage:FindFirstChild("WeaponRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "WeaponRemotes"
	remotes.Parent = ReplicatedStorage
end

local fireGun = remotes:FindFirstChild("FireGun") or Instance.new("RemoteEvent")
fireGun.Name = "FireGun"
fireGun.Parent = remotes

function GunService.new()
	local self = setmetatable({}, GunService)
	self.playerCooldowns = {}
	return self
end

function GunService:Initialize()
	fireGun.OnServerEvent:Connect(function(player, tool, mousePosition)
		self:HandleShot(player, tool, mousePosition)
	end)
end

function GunService:HandleShot(player: Player, tool: Instance, mousePosition: Vector3)
	-- Validate player and tool
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Validate tool is equipped
	if tool.Parent ~= character then return end
	
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	
	-- Get gun config (try both tool name and ItemId attribute)
	local gunName = tool:GetAttribute("ItemId") or tool.Name
	local config = GunConfigs[gunName] or GunConfigs[tool.Name]
	if not config then
		warn("No config found for gun:", gunName)
		return
	end
	
	-- Check ammo
	local currentAmmo = tool:GetAttribute("CurrentAmmo")
	if not currentAmmo or currentAmmo <= 0 then
		return -- No ammo
	end
	
	-- Check cooldown
	local playerId = player.UserId
	local now = tick()
	local lastShot = self.playerCooldowns[playerId] and self.playerCooldowns[playerId][gunName] or 0
	local cooldown = 1 / config.fireRate
	
	if now - lastShot < cooldown then
		return -- Still on cooldown
	end
	
	-- Update cooldown
	if not self.playerCooldowns[playerId] then
		self.playerCooldowns[playerId] = {}
	end
	self.playerCooldowns[playerId][gunName] = now
	
	-- Deduct ammo on server
	tool:SetAttribute("CurrentAmmo", currentAmmo - 1)
	
	-- Eject shell
	self:EjectShell(handle, config)
	
	-- Fire bullets
	for i = 1, config.bulletsPerShot do
		self:FireBullet(character, handle.Position, mousePosition, config)
	end
end

function GunService:FireBullet(character: Model, origin: Vector3, targetPosition: Vector3, config)
	-- Calculate direction with spread
	local baseDirection = (targetPosition - origin).Unit
	local spread = math.rad(config.bulletSpread)
	
	-- Apply random spread
	local spreadX = (math.random() - 0.5) * spread
	local spreadY = (math.random() - 0.5) * spread
	
	local direction = CFrame.lookAt(origin, origin + baseDirection)
	direction = direction * CFrame.Angles(spreadX, spreadY, 0)
	direction = direction.LookVector * config.range
	
	-- Raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(origin, direction, raycastParams)
	
	if result then
		local hitPart = result.Instance
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")
		
		if hitModel then
			local humanoid = hitModel:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Calculate damage
				local damage = config.damage
				if hitPart.Name == "Head" then
					damage = damage * config.headshotMultiplier
				end
				
				-- Apply damage through DamageService
				DamageService:ApplyDamage(hitModel, damage, Players:GetPlayerFromCharacter(character))
			end
		end
	end
end

function GunService:EjectShell(handle: BasePart, config)
	local shell = Instance.new("Part")
	shell.CFrame = handle.CFrame * CFrame.new(0.5, 0.2, 0) * CFrame.fromEulerAnglesXYZ(1.5, 0, 0)
	shell.Size = Vector3.new(1, 1, 1)
	shell.BrickColor = BrickColor.new("Bronze")
	shell.Material = Enum.Material.Metal
	shell.CanCollide = false
	shell.BottomSurface = Enum.SurfaceType.Smooth
	shell.TopSurface = Enum.SurfaceType.Smooth
	shell.Name = "Shell"
	
	-- Random ejection velocity
	local randomX = math.random(-10, 10)
	local randomZ = math.random(-10, 10)
	shell.Velocity = handle.CFrame.RightVector * config.shellEjectForce + Vector3.new(randomX, 20, randomZ)
	shell.AssemblyAngularVelocity = Vector3.new(0, 200, 0)
	
	-- Add mesh for visual
	local mesh = Instance.new("SpecialMesh")
	mesh.Scale = Vector3.new(0.15, 0.4, 0.15)
	mesh.Parent = shell
	
	shell.Parent = workspace
	Debris:AddItem(shell, 5)
end

-- Singleton
local instance = GunService.new()
return instance
