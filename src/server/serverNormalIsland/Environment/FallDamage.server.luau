local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))
local StatsService = require(script.Parent.Parent:WaitForChild("Stats"):WaitForChild("StatsService"))

-- Damage per stud beyond 4 studs, capped at 100
local fallStartHeight: {[Player]: number} = {}

local function onCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Freefall then
			local root = character:FindFirstChild("HumanoidRootPart")
			fallStartHeight[player] = root and root.Position.Y or 0
		elseif new == Enum.HumanoidStateType.Landed then
			local root = character:FindFirstChild("HumanoidRootPart")
			local startY = fallStartHeight[player]
			fallStartHeight[player] = nil

			if not root or not startY then return end

			local fallDistance = startY - root.Position.Y
			if fallDistance <= 0 then return end

			local minHeight = PlayerConfig.fallDamageMinHeight or 4
			local perStud = PlayerConfig.fallDamagePerStud or 6.25
			local cap = PlayerConfig.fallDamageCap or 100

			if fallDistance > minHeight then
				local damage = math.min((fallDistance - minHeight) * perStud, cap)
				local container = StatsService:GetContainer(player)
				local reduction = if container then container:GetDerivedStat("FallDamageReduction") else 0
				local finalDamage = damage * (1 - reduction)
				if finalDamage > 0 then
					humanoid:TakeDamage(finalDamage)
				end
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		onCharacter(plr, char)
	end)
end)
