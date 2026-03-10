local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

-- CONFIGURATION
local PLACE_ID = 0

local door = script.Parent
local hinge = door:WaitForChild("Doorframe"):WaitForChild("Hinge")
local base = door:WaitForChild("Base")
local prompt = base:WaitForChild("ProximityPrompt")

-- Door animation settings
local goalOpen = {
	CFrame = hinge.CFrame * CFrame.Angles(0, math.rad(90), 0)
}

local tweenInfo = TweenInfo.new(0.5)
local tweenOpen = TweenService:Create(hinge, tweenInfo, goalOpen)

prompt.ActionText = "Enter"
prompt.ObjectText = "Door"

prompt.Triggered:Connect(function(player)
	-- Play opening animation first for feedback
	tweenOpen:Play()
	
	-- Teleport the player after a tiny delay to see the door shift (optional)
	task.wait(0.1)
	
	-- Teleport logic
	-- Note: You must enable 'Allow Private Servers' or have the places under the same Experience
	TeleportService:Teleport(PLACE_ID, player)
end)
