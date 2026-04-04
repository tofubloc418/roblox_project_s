--!strict
--[[
	WeaponService (Server)
	- Validates client hit claims sent via `WeaponAttackRequest`.
	- Owns replicated weapon visuals via `WeaponVisualEquipRequest` so other
	  players can see equipped weapons.

	INITIALISED BY: Initializer.server.luau  →  WeaponService:Initialize()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))
local WeaponBasicAttackProfiles =
	require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("AnimationProfiles"):WaitForChild("WeaponBasicAttackProfiles") :: ModuleScript) :: any
local InventoryService = require(script.Parent.Parent:WaitForChild("Inventory"):WaitForChild("InventoryService"))
local WeaponAssetLayout = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("WeaponAssetLayout"))
local WeaponModelAssetLoader = require(script.Parent:WaitForChild("WeaponModelAssetLoader"))

local Items = ReplicatedStorage:WaitForChild("Items")
local Weapons = Items:WaitForChild("Weapons")

-- ── Remote setup ────────────────────────────────────────────────────────────

local weaponRemotes = ReplicatedStorage:FindFirstChild("WeaponRemotes")
if not weaponRemotes then
	weaponRemotes = Instance.new("Folder")
	weaponRemotes.Name = "WeaponRemotes"
	weaponRemotes.Parent = ReplicatedStorage
end

local weaponAttackRemote = weaponRemotes:FindFirstChild("WeaponAttackRequest")
if not weaponAttackRemote then
	weaponAttackRemote = Instance.new("RemoteEvent")
	weaponAttackRemote.Name = "WeaponAttackRequest"
	weaponAttackRemote.Parent = weaponRemotes
end

-- Equips weapon visuals (replicated models) on the server so other players can see them.
-- Clients still own animation + hit detection logic locally.
local weaponVisualEquipRemote = weaponRemotes:FindFirstChild("WeaponVisualEquipRequest")
if not weaponVisualEquipRemote then
	weaponVisualEquipRemote = Instance.new("RemoteEvent")
	weaponVisualEquipRemote.Name = "WeaponVisualEquipRequest"
	weaponVisualEquipRemote.Parent = weaponRemotes
end

-- ── Constants ───────────────────────────────────────────────────────────────

local PING_BUFFER_STUDS = 6 -- extra leniency for latency
local LOS_RAYCAST_PARAMS = RaycastParams.new()
LOS_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

-- Visual-equipping constants / replication handles
local WEAPON_VISUAL_MODEL_NAME = "EquippedWeapon"
local WEAPON_TEMPLATE_ATTR_ON_CHARACTER = "EquippedWeaponTemplateId"
local WEAPON_TEMPLATE_ATTR_ON_MODEL = "TemplateId"

local _weaponModelTemplateCache: { [string]: Model } = {}
local function getWeaponModelTemplate(templateId: string): Model?
	local cached = _weaponModelTemplateCache[templateId]
	if cached then
		return cached
	end

	local registryTemplate = ItemRegistry.GetTemplate(templateId)
	if not registryTemplate then
		return nil
	end

	local modelAssetId = (registryTemplate :: any).modelAssetId
	if WeaponModelAssetLoader.ParseAssetId(modelAssetId) then
		local fromRoblox = WeaponModelAssetLoader.LoadTemplateModel(templateId, modelAssetId)
		if fromRoblox then
			_weaponModelTemplateCache[templateId] = fromRoblox
		end
		return fromRoblox
	end

	local itemFolder = WeaponAssetLayout.GetWeaponItemFolder(Weapons, templateId)
	if not itemFolder then
		return nil
	end

	local modelTemplate = itemFolder:FindFirstChild(templateId) or itemFolder:FindFirstChildOfClass("Model")
	if not modelTemplate or not modelTemplate:IsA("Model") then
		return nil
	end

	_weaponModelTemplateCache[templateId] = modelTemplate
	return modelTemplate
end

local function unequipWeaponVisual(character: Model)
	local existing = character:FindFirstChild(WEAPON_VISUAL_MODEL_NAME)
	if existing then
		existing:Destroy()
	end
	character:SetAttribute(WEAPON_TEMPLATE_ATTR_ON_CHARACTER, nil)
end

local function attachWeaponGripMotor(character: Model, weaponModel: Model, template: any)
	local handle = weaponModel:FindFirstChild("Handle") or weaponModel.PrimaryPart
	if not (handle and handle:IsA("BasePart")) then
		return
	end

	local rightHand = character:FindFirstChild("RightHand")
	if not (rightHand and rightHand:IsA("BasePart")) then
		return
	end

	local handlePart = handle :: BasePart
	local existingMotor = handlePart:FindFirstChild("RightGrip")
	if existingMotor and existingMotor:IsA("Motor6D") then
		return -- already attached by the server (or a previous equip)
	end

	local motor = Instance.new("Motor6D")
	motor.Name = "RightGrip"
	motor.Part0 = rightHand :: BasePart
	motor.Part1 = handlePart
	motor.C0 = if template.gripC0 then template.gripC0 else CFrame.new(0, 0, 0)
	motor.C1 = if template.gripC1 then template.gripC1 else CFrame.new(0, 0, 0)
	motor.Parent = handlePart
end

local function equipWeaponVisual(player: Player, templateId: string)
	local character = player.Character
	if not character then
		return
	end

	if character:GetAttribute(WEAPON_TEMPLATE_ATTR_ON_CHARACTER) == templateId then
		return -- already equipped (avoid re-cloning)
	end

	unequipWeaponVisual(character)
	if templateId == "Fists" then
		return
	end

	local template = ItemRegistry.GetTemplate(templateId)
	if not template then
		return
	end

	local modelTemplate = getWeaponModelTemplate(templateId)
	if not modelTemplate then
		return
	end

	local clone = modelTemplate:Clone()
	clone.Name = WEAPON_VISUAL_MODEL_NAME
	clone.Parent = character
	clone:SetAttribute(WEAPON_TEMPLATE_ATTR_ON_MODEL, templateId)
	character:SetAttribute(WEAPON_TEMPLATE_ATTR_ON_CHARACTER, templateId)

	attachWeaponGripMotor(character, clone, template)
end

-- ── Module ──────────────────────────────────────────────────────────────────

export type WeaponService = {
	_cooldowns: { [Player]: number },
	Initialize: (self: WeaponService) -> (),
	_HandleHitClaim: (self: WeaponService, attacker: Player, templateId: string, targetPlayer: Player, claimedHitPos: Vector3) -> ()
}

local WeaponService = ({
	_cooldowns = {}
} :: any) :: WeaponService

function WeaponService:Initialize()
	weaponAttackRemote.OnServerEvent:Connect(function(attacker: Player, templateId: string, targetPlayer: Player, claimedHitPos: Vector3)
		self:_HandleHitClaim(attacker, templateId, targetPlayer, claimedHitPos)
	end)

	weaponVisualEquipRemote.OnServerEvent:Connect(function(player: Player, templateId: any)
		if typeof(templateId) ~= "string" then
			return
		end

		-- Validate ownership so clients can not request arbitrary weapons visually.
		if templateId ~= "Fists" then
			local equipment = InventoryService.GetEquipment(player)
			if not equipment then
				return
			end

			local w1Tid = equipment.Weapon1 and equipment.Weapon1.tid or nil
			local w2Tid = equipment.Weapon2 and equipment.Weapon2.tid or nil
			if w1Tid ~= templateId and w2Tid ~= templateId then
				return
			end
		end

		equipWeaponVisual(player, templateId)
	end)

	-- Clean up cooldowns when a player leaves
	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player] = nil
	end)
end

-- ── Sanity Checks ───────────────────────────────────────────────────────────

function WeaponService:_HandleHitClaim(attacker: Player, templateId: string, targetPlayer: Player, claimedHitPos: Vector3)
	-- 1. Basic validation
	if typeof(templateId) ~= "string" or typeof(claimedHitPos) ~= "Vector3" then
		return
	end

	local stats = ItemRegistry.GetTemplate(templateId)
	if not stats then
		warn("[WeaponService] Unknown templateId: " .. tostring(templateId))
		return
	end

	local attackerCharacter = attacker.Character
	if not attackerCharacter then return end

	local attackerHumanoid = attackerCharacter:FindFirstChildOfClass("Humanoid")
	if not attackerHumanoid or attackerHumanoid.Health <= 0 then return end

	local attackerRoot = attackerCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
	if not attackerRoot then return end

	-- Validate target
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	local targetCharacter = targetPlayer.Character
	if not targetCharacter then return end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then return end

	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
	if not targetRoot then return end

	-- 2. Cooldown check
	local now = os.clock()
	local lastAttack = self._cooldowns[attacker] or 0

	local minCooldown = math.huge
	for _, entry in ipairs(stats.attackSequence or {}) do
		local motionId = entry.attackMotionId
		if type(motionId) == "string" and motionId ~= "" then
			local attackProfile = WeaponBasicAttackProfiles.GetProfile(motionId)
			if attackProfile and attackProfile.hitDuration < minCooldown then
				minCooldown = attackProfile.hitDuration
			end
		end
	end

	if now - lastAttack < (minCooldown * 0.8) then
		-- Slightly more lenient than config to account for latency
		warn("[WeaponService] Cooldown violation from " .. attacker.Name)
		return
	end
	self._cooldowns[attacker] = now

	-- 3. Distance check
	local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
	local maxAllowed = (stats.reach or 5) + PING_BUFFER_STUDS
	if distance > maxAllowed then
		warn(string.format(
			"[WeaponService] Distance violation from %s: %.1f studs (max %.1f)",
			attacker.Name, distance, maxAllowed
		))
		return
	end

	-- 4. Line-of-sight check
	LOS_RAYCAST_PARAMS.FilterDescendantsInstances = { attackerCharacter, targetCharacter }
	local direction = targetRoot.Position - attackerRoot.Position
	local losResult = Workspace:Raycast(attackerRoot.Position, direction, LOS_RAYCAST_PARAMS)
	if losResult then
		-- Something solid is between attacker and target → reject
		warn("[WeaponService] LoS blocked for " .. attacker.Name)
		return
	end

	-- ── All checks passed → apply damage ────────────────────────────────
	DamageService.CalculateAndApply(attacker, templateId, targetPlayer)
end

return WeaponService
