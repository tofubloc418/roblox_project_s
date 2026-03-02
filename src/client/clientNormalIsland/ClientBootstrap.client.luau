--!strict
-- Single entry point for client modules. Require any module that should run on the client here
-- instead of creating a new .client.luau for each one.

local GUI = script.Parent:WaitForChild("GUI")

require(GUI:WaitForChild("Map"):WaitForChild("MinimapController"))
require(GUI:WaitForChild("Hud"):WaitForChild("PlayerStatsHudController"))
