--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modules = ReplicatedStorage:WaitForChild("Modules")
local signalModule = modules:WaitForChild("Signal")

return require(signalModule :: any)
