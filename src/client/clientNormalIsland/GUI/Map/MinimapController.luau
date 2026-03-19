--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))
local MapMath = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MapMath"))

local MinimapView = require(script.Parent:WaitForChild("MinimapView"))
local HudBuilder = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("HudBuilder"))
local CursorManager = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("CursorManager"))
local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindsClient = require(script.Parent.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))

local Controller = {}
Controller.enabled = true
Controller.lastUpdateTime = 0

local _screenGui: ScreenGui
local mini, full
local playerIcon: ImageLabel
local fullMapPlayerIcon: ImageLabel
local timerLabel: TextLabel

function Controller:Initialize()
	local build = HudBuilder.buildMinimap(playerGui)
	_screenGui = build.ScreenGui
	mini = build.Mini
	full = build.Full
	playerIcon = build.PlayerIcon
	fullMapPlayerIcon = build.FullMapPlayerIcon

	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "MatchTimer"
	timerLabel.AnchorPoint = Vector2.new(0.5, 0)
	timerLabel.Size = UDim2.fromOffset(120, 18)
	timerLabel.Position = UDim2.fromOffset(0, 0)
	timerLabel.BackgroundTransparency = 0.3
	timerLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Text = "00:00"
	timerLabel.Parent = _screenGui
end

function Controller:Update()
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	local now = tick()
	if (now - self.lastUpdateTime) < MinimapConfig.Minimap.UpdateThrottle then return end
	self.lastUpdateTime = now

	local uv = MapMath.worldToUV(hrp.Position)
	MinimapView.panTo(mini, uv)
	local rot = math.deg(math.atan2(hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Z))
	playerIcon.Rotation = -rot + MinimapConfig.PlayerIcon.RotationOffset

	if full.Frame.Visible then
		fullMapPlayerIcon.Position = MapMath.uvToFullMapPosition(uv)
		fullMapPlayerIcon.Rotation = -rot + MinimapConfig.PlayerIcon.RotationOffset
	end
end

function Controller:ToggleFullMap()
	full.Frame.Visible = not full.Frame.Visible
	CursorManager.setEnabledFor("FullMap", full.Frame.Visible)
end

function Controller:SetupInput()
	KeybindsClient.bindAction(KeybindIds.ToggleMap, function(_name, state, _input)
		if state == Enum.UserInputState.Begin then
			self:ToggleFullMap()
		end
		return Enum.ContextActionResult.Sink
	end, {
		actionName = "ToggleMap",
	})
end

function Controller:Start()
	player.CharacterAdded:Connect(function()
		task.wait(1)
		self:Initialize()
	end)
	if player.Character then self:Initialize() end
	self:SetupInput()
	RunService.Heartbeat:Connect(function()
		if self.enabled and mini then self:Update() end
		local matchInfo = ReplicatedStorage:FindFirstChild("MatchInfo")
		local start = matchInfo and matchInfo:FindFirstChild("StartTime")
		if start and timerLabel then
			local elapsed = os.time() - start.Value
			if elapsed < 0 then elapsed = 0 end
			local m = math.floor(elapsed / 60)
			local s = elapsed % 60
			timerLabel.Text = string.format("%02d:%02d", m, s)
			if mini and mini.Frame then
				local f = mini.Frame
				local pos = f.AbsolutePosition
				local size = f.AbsoluteSize
				local x = pos.X + size.X * 0.5
				local y = pos.Y + size.Y + 4
				timerLabel.Position = UDim2.fromOffset(x, y)
				timerLabel.AnchorPoint = Vector2.new(0.5, 0)
			end
		end
	end)
end

(Controller :: any):Start()

return Controller
