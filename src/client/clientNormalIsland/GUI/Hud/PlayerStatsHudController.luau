--!strict

-- PlayerStatsHudController: builds and updates the bottom-left player stats HUD (health, energy, mana).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HudBuilder = require(script.Parent:WaitForChild("HudBuilder"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))

local Controller = {}
local statsHud

local function getViewportSize(): Vector2
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

local function applyHudScale()
	if not statsHud or not statsHud.UIScaleInstance then
		return
	end

	statsHud.UIScaleInstance.Scale = LayoutConfig.getHudScale(getViewportSize())
end

function Controller:Initialize()
	statsHud = HudBuilder.buildPlayerStatsHud(playerGui)
	applyHudScale()
end

function Controller:Start()
	player.CharacterAdded:Connect(function()
		task.wait(1)
		self:Initialize()
	end)
	if player.Character then
		self:Initialize()
	end
	RunService.Heartbeat:Connect(function()
		if not statsHud then return end
		applyHudScale()
		local character = player.Character
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if hum then
			local hpFrac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			statsHud.HealthFill.Size = UDim2.fromScale(hpFrac, 1)
			if statsHud.HealthCap then
				statsHud.HealthCap.Size = UDim2.fromScale(1, 1)
			end
		end
		local energy = player:GetAttribute("Stamina") or 0
		local maxEnergy = player:GetAttribute("MaxStamina") or 100
		local energyFrac = math.clamp(maxEnergy > 0 and (energy / maxEnergy) or 0, 0, 1)
		statsHud.EnergyFill.Size = UDim2.fromScale(energyFrac, 1)
		if statsHud.EnergyCap then
			statsHud.EnergyCap.Size = UDim2.fromScale(1, 1)
		end
		local mana = player:GetAttribute("Mana") or 0
		local maxMana = player:GetAttribute("MaxMana") or 100
		local manaFrac = math.clamp(maxMana > 0 and (mana / maxMana) or 0, 0, 1)
		statsHud.ManaFill.Size = UDim2.fromScale(manaFrac, 1)
		if statsHud.ManaCap then
			statsHud.ManaCap.Size = UDim2.fromScale(1, 1)
		end
	end)
end

(Controller :: any):Start()

return Controller
