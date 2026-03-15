--!strict
-- Listens for SetHitboxDebug remote (from Cmdr hitbox command). Applies ShapecastHitbox debug state on this client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

if not RunService:IsStudio() then return end

local _shapecastHitbox: any = nil
local function getShapecastHitbox(): any?
	if _shapecastHitbox then return _shapecastHitbox end
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	if not packages then return nil end
	local mod = packages:FindFirstChild("shapecasthitbox")
	if not mod then return nil end
	_shapecastHitbox = require(mod :: ModuleScript) :: any
	return _shapecastHitbox
end

local function applyHitboxDebug(state: string?)
	local ShapecastHitbox = getShapecastHitbox()
	if not ShapecastHitbox then
		warn("[Dev] ShapecastHitbox package not found.")
		return
	end
	local current = ShapecastHitbox.Settings.Debug_Visible
	local newState: boolean
	if state == "on" then
		newState = true
	elseif state == "off" then
		newState = false
	else
		newState = not current
	end
	ShapecastHitbox.Settings.Debug_Visible = newState
	print(string.format("[Dev] Hitbox debug visuals: %s", newState and "ON ✓" or "OFF ✗"))
end

local devRemotes = ReplicatedStorage:FindFirstChild("DevRemotes")
local setHitboxDebug = devRemotes and devRemotes:FindFirstChild("SetHitboxDebug") :: RemoteEvent?
if setHitboxDebug then
	setHitboxDebug.OnClientEvent:Connect(function(state: string?)
		applyHitboxDebug(state or "toggle")
	end)
end
