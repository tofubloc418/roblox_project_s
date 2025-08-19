local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local GunConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Weapons"):WaitForChild("GunConfigs"))
local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))

-- Type definition for bullet data (matches BulletVisuals module)
type BulletData = {
	origin: Vector3,
	direction: Vector3,
	speed: number,
	gunName: string,
	shooterId: number,
	hitPosition: Vector3?,
}

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

local bulletVisualEvent = remotes:FindFirstChild("BulletVisual") or Instance.new("RemoteEvent")
bulletVisualEvent.Name = "BulletVisual"
bulletVisualEvent.Parent = remotes

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
	if not config then return end
	
	-- Check ammo
	local currentAmmo = tool:GetAttribute("CurrentAmmo")
	if currentAmmo == nil then
		currentAmmo = config.magazineCapacity
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
	
	-- Deduct ammo on server (initialize if needed)
	tool:SetAttribute("CurrentAmmo", math.max(0, (currentAmmo or 0) - 1))
	
	-- Eject shell
	self:EjectShell(handle, config)
	
	-- Fire bullets and broadcast visuals
	for i = 1, config.bulletsPerShot do
		-- Resolve ONLY an Attachment named "Muzzle" (typically under Handle)
		local node = tool:FindFirstChild("Muzzle", true)
		if not (node and node:IsA("Attachment")) then
			return -- No muzzle → do not fire
		end
		local muzzleCFrame: CFrame = (node :: Attachment).WorldCFrame

		-- Calculate direction with spread for this bullet from muzzle
		local muzzlePos = muzzleCFrame.Position
		local baseDirection = (mousePosition - muzzlePos).Unit
		local spread = math.rad(config.bulletSpread)
		
		-- Apply random spread
		local spreadX = (math.random() - 0.5) * spread
		local spreadY = (math.random() - 0.5) * spread
		
		local direction = CFrame.lookAt(muzzlePos, muzzlePos + baseDirection)
		direction = direction * CFrame.Angles(spreadX, spreadY, 0)
		direction = direction.LookVector
		
		-- Fire the actual bullet (damage calculation) and get hit position
		local hitPos = self:FireBullet(character, muzzlePos, direction, config)
		
		-- Broadcast bullet visual to all clients (include stop position if hit)
		local bulletData: BulletData = {
			origin = muzzlePos,
			direction = direction,
			speed = config.bulletSpeed,
			gunName = gunName,
			shooterId = player.UserId,
			hitPosition = hitPos,
		}
		bulletVisualEvent:FireAllClients(bulletData)
	end
end

function GunService:FireBullet(character: Model, origin: Vector3, direction: Vector3, config): Vector3?
	-- Direction is already calculated with spread, just apply range
	local rayDirection = direction * config.range
	
	-- Raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(origin, rayDirection, raycastParams)
	
	if result then
		local hitPart = result.Instance
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")
		
		if hitModel then
			-- Check for humanoid first
			local humanoid = hitModel:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Calculate damage
				local damage = config.damage
				if hitPart.Name == "Head" then
					damage = damage * config.headshotMultiplier
				end
				
				-- Apply damage through DamageService
				DamageService:ApplyDamage(humanoid, damage, Players:GetPlayerFromCharacter(character))
				
			-- Check if this model is a crate (has CrateType attribute)
			elseif hitModel:GetAttribute("CrateType") then
				-- Apply damage to the crate model
				local damage = config.damage
				local success = DamageService:ApplyDamage(hitModel, damage, Players:GetPlayerFromCharacter(character))
				if not success then end
			end
		end
		return result.Position
	end

	return nil
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
