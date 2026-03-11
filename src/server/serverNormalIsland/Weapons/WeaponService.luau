--!strict
--[[
	WeaponService (Server)
	Validates client hit claims sent via the WeaponAttackRequest RemoteEvent.
	Performs sanity checks (cooldown, distance, line-of-sight) and applies
	damage through DamageService when validation passes.

	INITIALISED BY: Initializer.server.luau  →  WeaponService:Initialize()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DamageService = require(script.Parent.Parent:WaitForChild("Combat"):WaitForChild("DamageService"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemRegistry"))

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

-- ── Constants ───────────────────────────────────────────────────────────────

local PING_BUFFER_STUDS = 6 -- extra leniency for latency
local LOS_RAYCAST_PARAMS = RaycastParams.new()
LOS_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

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
		if entry.hitDuration < minCooldown then
			minCooldown = entry.hitDuration
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
