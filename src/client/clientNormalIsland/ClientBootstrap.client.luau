--!strict
-- Single entry point for client modules. Require any module that should run on the client here
-- instead of creating a new .client.luau for each one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUI = script.Parent:WaitForChild("GUI")

local CmdrClient = ReplicatedStorage:WaitForChild("CmdrClient")
if CmdrClient:IsA("ModuleScript") then
	local Cmdr = require(CmdrClient :: ModuleScript)
	Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
else
	local init = (CmdrClient :: Instance):FindFirstChild("init")
	if init and init:IsA("ModuleScript") then
		local Cmdr = require(init)
		Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
	end
end

require(GUI:WaitForChild("Map"):WaitForChild("MinimapController"))
require(GUI:WaitForChild("Hud"):WaitForChild("PlayerStatsHudController"))
