local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local GunConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Weapons"):WaitForChild("GunConfigs"))
local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local FastCast = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FastCastRedux"))

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

local bulletHitEvent = remotes:FindFirstChild("BulletHit") or Instance.new("RemoteEvent")
bulletHitEvent.Name = "BulletHit"
bulletHitEvent.Parent = remotes

function GunService.new()
	local self = setmetatable({}, GunService)
	self.playerCooldowns = {}
	self.caster = FastCast.new()
	return self
end

function GunService:Initialize()
	fireGun.OnServerEvent:Connect(function(player, tool, mousePosition)
		self:HandleShot(player, tool, mousePosition)
	end)

	-- Apply damage when a cast actually hits something
	self.caster.RayHit:Connect(function(cast, result, velocity, position)
		local data = cast.UserData
		if not data then return end
		local hitPart = result.Instance
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")
		if hitModel then
			local hum = hitModel:FindFirstChildOfClass("Humanoid")
			if hum then
				local damage = data.config.damage
				if hitPart.Name == "Head" then
					damage = damage * data.config.headshotMultiplier
				end
				DamageService:ApplyDamage(hum, damage, data.shooter)
			elseif hitModel:GetAttribute("CrateType") then
				DamageService:ApplyDamage(hitModel, data.config.damage, data.shooter)
			end
		end
		-- Clamp tracers at hit
		bulletHitEvent:FireAllClients({
			shooterId = data.shooterId,
			origin = data.origin,
			direction = data.direction,
			hitPosition = position,
		})
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
		
		-- Broadcast bullet visual to all clients (stop position will be sent on hit)
		local bulletData: BulletData = {
			origin = muzzlePos,
			direction = direction,
			speed = config.bulletSpeed,
			gunName = gunName,
			shooterId = player.UserId,
			hitPosition = nil,
		}
		bulletVisualEvent:FireAllClients(bulletData)

		-- FastCast projectile with speed
		local behavior = FastCast.newBehavior()
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude
		behavior.RaycastParams = params
		behavior.AutoIgnoreContainer = true
		behavior.Acceleration = Vector3.new(0, 0, 0)
		local initialVelocity = direction * (config.bulletSpeed or 300)
		local cast = self.caster:Fire(muzzlePos, direction, initialVelocity, behavior)
		if cast then
			cast.UserData = {
				shooter = player,
				shooterId = player.UserId,
				origin = muzzlePos,
				direction = direction,
				config = config,
			}
		end
	end
end


function GunService:EjectShell(handle: BasePart, config)
	local shellsFolder = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild("BulletShells")
	local shellName = (config and config.shellType) or "NormalShell"
	local shellPrefab = shellsFolder:FindFirstChild(shellName)
	if not shellPrefab then return end

	local ejectCFrame = handle.CFrame * CFrame.new(0.5, 0.2, 0) * CFrame.fromEulerAnglesXYZ(1.5, 0, 0)
	local linear = handle.CFrame.RightVector * config.shellEjectForce + Vector3.new(math.random(-10, 10), 20, math.random(-10, 10))
	local angular = Vector3.new(0, 200, 0)

	if shellPrefab:IsA("Model") then
		local clone = shellPrefab:Clone()
		local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		if not primary then clone:Destroy(); return end
		clone:PivotTo(ejectCFrame)
		clone.Parent = workspace
		primary.CanCollide = true
		primary.AssemblyLinearVelocity = linear
		primary.AssemblyAngularVelocity = angular
		Debris:AddItem(clone, 5)
		return
	end

	if shellPrefab:IsA("BasePart") then
		local part = (shellPrefab:Clone()) :: BasePart
		part.CFrame = ejectCFrame
		part.CanCollide = true
		part.Parent = workspace
		part.AssemblyLinearVelocity = linear
		part.AssemblyAngularVelocity = angular
		Debris:AddItem(part, 5)
	end
end

-- Singleton
local instance = GunService.new()
return instance
