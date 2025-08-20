local bandage_tool = script.Parent
local particle = bandage_tool.UseParticle
local particleEmitter = particle.ParticleEmitter
local Players = game:GetService("Players")


local debounce = false
local useTime = 3 -- seconds to use bandage
local healAmount = 20
local healing = false
particleEmitter.Enabled = false

bandage_tool.Activated:Connect(function()
	local character = bandage_tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not debounce then
		humanoid.WalkSpeed = 8
		particleEmitter.Enabled = true
		debounce = true
		healing = true
		bandage_tool["bandage usage"]:Play()
		task.wait(useTime)
		humanoid.Health = humanoid.Health + 20
		debounce = false
		humanoid.WalkSpeed = 16
		particleEmitter.Enabled = false
	end
end)
