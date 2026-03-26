--!strict
-- Listens for SetHitboxDebug remote (from Cmdr hitbox command). Applies ShapecastHitbox debug state on this client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

if not RunService:IsStudio() then return end

local Weapons = script.Parent.Parent:WaitForChild("Weapons")
local WeaponController = require(Weapons:WaitForChild("WeaponController")) :: any

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

local weaponDebugEnabled = false
local function applyWeaponDebug(state: string?)
	local newState: boolean
	if state == "on" then
		newState = true
	elseif state == "off" then
		newState = false
	else
		newState = not weaponDebugEnabled
	end

	weaponDebugEnabled = newState
	WeaponController.SetDebugEnabled(newState)
end

local devRemotes = ReplicatedStorage:FindFirstChild("DevRemotes")
local setHitboxDebug = devRemotes and devRemotes:FindFirstChild("SetHitboxDebug") :: RemoteEvent?
local setWeaponDebug = devRemotes and devRemotes:FindFirstChild("SetWeaponDebug") :: RemoteEvent?
if setHitboxDebug then
	setHitboxDebug.OnClientEvent:Connect(function(state: string?)
		applyHitboxDebug(state or "toggle")
	end)
end

if setWeaponDebug then
	setWeaponDebug.OnClientEvent:Connect(function(state: string?)
		applyWeaponDebug(state or "toggle")
	end)
end
