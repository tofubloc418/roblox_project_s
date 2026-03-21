--!strict
-- LoS, cone/radius targeting, weapon template fallback for ability scripts.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local AbilityCombatShared = {}

function AbilityCombatShared.resolveWeaponTemplateId(weaponTemplateId: string?): string
	if weaponTemplateId and #weaponTemplateId > 0 then
		return weaponTemplateId
	end
	return "Fists"
end

function AbilityCombatShared.hasLineOfSight(
	filterInstances: { Instance },
	fromPosition: Vector3,
	toPosition: Vector3
): boolean
	local delta = toPosition - fromPosition
	local distance = delta.Magnitude
	if distance < 0.05 then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filterInstances
	local hit = Workspace:Raycast(fromPosition, delta.Unit * distance, params)
	return hit == nil
end

function AbilityCombatShared.findClosestEnemyInCone(
	attacker: Player,
	attackerCharacter: Model,
	origin: Vector3,
	lookVector: Vector3,
	maxRange: number,
	halfAngleDeg: number
): Player?
	local look = lookVector.Unit
	local best: Player? = nil
	local bestDist = maxRange

	for _, other in Players:GetPlayers() do
		if other ~= attacker and other.Character then
			local hum = other.Character:FindFirstChildOfClass("Humanoid")
			local root = other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and root and hum.Health > 0 then
				local offset = root.Position - origin
				local dist = offset.Magnitude
				if dist > 0.05 and dist <= maxRange then
					local angle = math.deg(math.acos(math.clamp(look:Dot(offset.Unit), -1, 1)))
					if angle <= halfAngleDeg and dist < bestDist then
						local losOk = AbilityCombatShared.hasLineOfSight(
							{ attackerCharacter, other.Character },
							origin,
							root.Position
						)
						if losOk then
							bestDist = dist
							best = other
						end
					end
				end
			end
		end
	end

	return best
end

function AbilityCombatShared.findEnemyPlayersInRadius(
	attacker: Player,
	attackerCharacter: Model,
	origin: Vector3,
	radius: number
): { Player }
	local found: { Player } = {}

	for _, other in Players:GetPlayers() do
		if other ~= attacker and other.Character then
			local hum = other.Character:FindFirstChildOfClass("Humanoid")
			local root = other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and root and hum.Health > 0 then
				local dist = (root.Position - origin).Magnitude
				if dist <= radius then
					local losOk = AbilityCombatShared.hasLineOfSight(
						{ attackerCharacter, other.Character },
						origin,
						root.Position
					)
					if losOk then
						table.insert(found, other)
					end
				end
			end
		end
	end

	return found
end

return AbilityCombatShared
