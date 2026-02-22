local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local _Players = game:GetService("Players")

local GunConfigs = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Weapons"):WaitForChild("GunConfigs"))
local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local FastCast = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FastCastRedux"))
local InventoryService = require(script.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))

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
local reloadGun = remotes:FindFirstChild("ReloadGun") or Instance.new("RemoteEvent")
reloadGun.Name = "ReloadGun"
reloadGun.Parent = remotes

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

	reloadGun.OnServerEvent:Connect(function(player, tool)
		self:HandleReload(player, tool)
	end)

	-- Apply damage when a cast actually hits something
	self.caster.RayHit:Connect(function(cast, result, velocity, position)
		local data = cast.UserData
		if not data then return end
		local hitPart = result.Instance
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")
		local partName = hitPart and hitPart.Name or "?"
		local modelName = hitModel and hitModel.Name or "?"
		print(string.format("[Gun] RayHit shooter=%s gun=%s part=%s model=%s pos=(%.1f,%.1f,%.1f)", tostring(data.shooterId), tostring(data.gunName or "?"), partName, modelName, position.X, position.Y, position.Z))
		if hitModel then
			local hum = hitModel:FindFirstChildOfClass("Humanoid")
			if hum then
				local damage = data.config.damage
				if partName == "Head" then
					damage = damage * data.config.headshotMultiplier
				end
				DamageService:ApplyDamage(hum, damage, data.shooter)
				print(string.format("[Gun] Damage applied to humanoid=%s damage=%.1f", hum.Parent and hum.Parent.Name or "?", damage))
			elseif hitModel:GetAttribute("CrateType") then
				DamageService:ApplyDamage(hitModel, data.config.damage, data.shooter)
				print(string.format("[Gun] Damage applied to crate=%s damage=%.1f", modelName, data.config.damage))
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

	self.caster.CastTerminating:Connect(function(cast)
		local data = cast.UserData
		if data then
			print(string.format("[Gun] CastTerminating shooter=%s gun=%s traveled end", tostring(data.shooterId), tostring(data.gunName or "?")))
		end
	end)
end


function GunService:HandleReload(player: Player, tool: Instance)
	local character = player.Character
	if not character then
		print("[Gun] Reload blocked: no character")
		return
	end
	if not tool or not tool:IsA("Tool") then
		print("[Gun] Reload blocked: invalid tool")
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if tool.Parent ~= character and (not backpack or tool.Parent ~= backpack) then
		print("[Gun] Reload blocked: tool not owned by player")
		return
	end

	local gunName = tool:GetAttribute("ItemId") or tool.Name
	local config = GunConfigs[gunName] or GunConfigs[tool.Name]
	if not config then
		print("[Gun] Reload blocked: no config for", gunName)
		return
	end

	local before = tool:GetAttribute("CurrentAmmo")
	if before == nil then
		before = 0
	end

	local magCap = config.magazineCapacity or 0
	if before >= magCap then
		print("[Gun] Reload blocked: already full")
		return
	end

	-- Determine ammo type and how many rounds needed
	local ammoItemId = config.ammoType
	if not ammoItemId or ammoItemId == "" then
		-- Fallback: fill without consuming ammo (legacy behavior)
		tool:SetAttribute("CurrentAmmo", magCap)
		print(string.format("[Gun] Reload server (no ammo type) shooter=%s gun=%s ammo: %d -> %d", player.Name, gunName, before, magCap))
		return
	end

	local need = magCap - before
	if need <= 0 then
		print("[Gun] Reload blocked: no need")
		return
	end

	-- Collect ammo stacks from character and backpack
	local function iterateAmmoTools()
		local yielded = {}
		local character = player.Character
		if character then
			for _, inst in ipairs(character:GetChildren()) do
				if inst:IsA("Tool") and inst:GetAttribute("ItemId") == ammoItemId then
					table.insert(yielded, inst)
				end
			end
		end
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, inst in ipairs(backpack:GetChildren()) do
				if inst:IsA("Tool") and inst:GetAttribute("ItemId") == ammoItemId then
					table.insert(yielded, inst)
				end
			end
		end
		return yielded
	end

	local ammoTools = iterateAmmoTools()
	local totalAvailable = 0
	for _, ammoTool in ipairs(ammoTools) do
		totalAvailable += (ammoTool:GetAttribute("CurrentStack") or 0)
	end

	if totalAvailable <= 0 then
		print("[Gun] Reload blocked: no ammo in inventory")
		return
	end

	local toLoad = math.min(need, totalAvailable)
	local remaining = toLoad
	for _, ammoTool in ipairs(ammoTools) do
		if remaining <= 0 then break end
		local count = ammoTool:GetAttribute("CurrentStack") or 0
		if count > 0 then
			local take = math.min(count, remaining)
			local newCount = count - take
			if newCount <= 0 then
				ammoTool:Destroy()
			else
				ammoTool:SetAttribute("CurrentStack", newCount)
			end
			remaining -= take
		end
	end

	local after = math.clamp(before + toLoad, 0, magCap)
	tool:SetAttribute("CurrentAmmo", after)
	print(string.format("[Gun] Reload server shooter=%s gun=%s ammo: %d -> %d (loaded=%d need=%d avail=%d)", player.Name, gunName, before, after, toLoad, need, totalAvailable))

	-- Sync inventory to reflect ammo consumption
	if InventoryService and InventoryService.SyncInventory then
		InventoryService:SyncInventory(player)
	end
end


function GunService:HandleShot(player: Player, tool: Instance, mousePosition: Vector3)
	-- Validate player and tool
	local character = player.Character
	if not character then
		print("[Gun] Blocked: no character")
		return
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		print("[Gun] Blocked: dead/no humanoid")
		return
	end
	
	-- Validate tool is equipped
	if tool.Parent ~= character then
		print("[Gun] Blocked: tool not equipped")
		return
	end
	
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		print("[Gun] Blocked: no Handle")
		return
	end
	
	-- Get gun config (try both tool name and ItemId attribute)
	local gunName = tool:GetAttribute("ItemId") or tool.Name
	local config = GunConfigs[gunName] or GunConfigs[tool.Name]
	if not config then
		print("[Gun] Blocked: no config for", gunName)
		return
	end

	-- Resolve muzzle before ammo deduction to avoid consuming ammo on failure
	local muzzleNode = tool:FindFirstChild("Muzzle", true)
	if not (muzzleNode and muzzleNode:IsA("Attachment")) then
		print("[Gun] Blocked: no Muzzle attachment")
		return
	end

	-- Cooldown
	local playerId = player.UserId
	local now = tick()
	local lastShot = self.playerCooldowns[playerId] and self.playerCooldowns[playerId][gunName] or 0
	local cooldown = config.shotDelay or 0
	if now - lastShot < cooldown then
		print(string.format("[Gun] Blocked: cooldown (%.2fs left)", cooldown - (now - lastShot)))
		return
	end

	-- Update cooldown
	if not self.playerCooldowns[playerId] then
		self.playerCooldowns[playerId] = {}
	end
	self.playerCooldowns[playerId][gunName] = now

	-- Ammo accounting per trigger
	local burstCount = (config.burstCount or 1)
	local ammoCost = burstCount * (config.bulletsPerShot or 1)
	local currentAmmo = tool:GetAttribute("CurrentAmmo")
	if currentAmmo == nil then currentAmmo = config.magazineCapacity end
	if currentAmmo < ammoCost then
		print(string.format("[Gun] Blocked: not enough ammo need=%d have=%d", ammoCost, currentAmmo))
		return
	end

	tool:SetAttribute("CurrentAmmo", currentAmmo - ammoCost)
	print(string.format("[Gun] Trigger shooter=%s gun=%s mode=%s ammo: %d -> %d (cost=%d) burstCount=%d pellets=%d", player.Name, gunName, tostring(config.mode), currentAmmo, currentAmmo - ammoCost, ammoCost, burstCount, config.bulletsPerShot or 1))

	local function fireOneShot()
		local muzzleCFrame: CFrame = (muzzleNode :: Attachment).WorldCFrame
		local muzzlePos = muzzleCFrame.Position
		local baseDirection = (mousePosition - muzzlePos).Unit
		local spread = math.rad(config.bulletSpread)
		
		-- Apply random spread per shot
		local spreadX = (math.random() - 0.5) * spread
		local spreadY = (math.random() - 0.5) * spread
		local direction = CFrame.lookAt(muzzlePos, muzzlePos + baseDirection)
		direction = direction * CFrame.Angles(spreadX, spreadY, 0)
		direction = direction.LookVector
		
		print(string.format("[Gun] FireOne shooter=%s dir=(%.2f,%.2f,%.2f)", player.Name, direction.X, direction.Y, direction.Z))
		
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

		-- Eject shell for this shot
		self:EjectShell(handle, config)

		-- FastCast projectile with speed
		local behavior = FastCast.newBehavior()
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude
		behavior.RaycastParams = params
		behavior.AutoIgnoreContainer = true
		behavior.Acceleration = Vector3.new(0, 0, 0)
		behavior.MaxDistance = config.range or 1000
		behavior.HighFidelitySegmentSize = 0.25
		local initialVelocity = direction * (config.bulletSpeed or 300)
		local cast = self.caster:Fire(muzzlePos, direction, initialVelocity, behavior)
		if cast then
			cast.UserData = {
				shooter = player,
				shooterId = player.UserId,
				origin = muzzlePos,
				direction = direction,
				config = config,
				gunName = gunName,
			}
		else
			print("[Gun] WARN: caster:Fire returned nil")
		end
	end

	-- Fire according to mode
	if config.mode == "Burst" then
		local gap = config.burstDelay or 0.05
		for n = 1, burstCount do
			for i = 1, (config.bulletsPerShot or 1) do
				fireOneShot()
			end
			if n < burstCount then task.wait(gap) end
		end
	else
		for i = 1, (config.bulletsPerShot or 1) do
			fireOneShot()
		end
	end
end

function GunService:EjectShell(handle: BasePart, config)
	local shellsFolder = ReplicatedStorage:WaitForChild("BulletShells")
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
