local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = true

local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.WalkSpeed = PlayerConfig.walkSpeed
			if humanoid.UseJumpPower ~= nil then
				humanoid.JumpPower = PlayerConfig.jumpPower
			end
			humanoid.MaxHealth = PlayerConfig.maxHealth
			humanoid.Health = PlayerConfig.maxHealth
		end
	end)
end)
