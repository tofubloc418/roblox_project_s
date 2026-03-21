--!strict
-- HUD loadout ScreenGui, quick-use hold→radial, weapon/keybind wiring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React")) :: any
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox")) :: any

local HudLoadoutDataAdapter = require(script.Parent:WaitForChild("HudLoadoutDataAdapter"))
local AbilityStateClient = require(script.Parent.Parent.Parent:WaitForChild("Abilities"):WaitForChild("AbilityStateClient"))
local HudLoadoutTypes = require(script.Parent:WaitForChild("HudLoadoutTypes"))
local HudLoadoutApp = require(script.Parent:WaitForChild("HudLoadoutApp"))
local HudRadialDial = require(script.Parent:WaitForChild("HudRadialDial"))
local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindsClient = require(script.Parent.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))

type HudLoadoutState = HudLoadoutTypes.HudLoadoutState
type HudActiveSlot = HudLoadoutTypes.HudActiveSlot

local localPlayer = Players.LocalPlayer

local function getViewportSize(): Vector2
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

-- ── ScreenGuis ──────────────────────────────────────────────────────────────

local playerGui = localPlayer:WaitForChild("PlayerGui")

local hudScreen = Instance.new("ScreenGui")
hudScreen.Name = "HudLoadoutScreen"
hudScreen.ResetOnSpawn = false
hudScreen.Enabled = true
hudScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
hudScreen.IgnoreGuiInset = true
hudScreen.Parent = playerGui

local radialScreen = Instance.new("ScreenGui")
radialScreen.Name = "HudRadialScreen"
radialScreen.ResetOnSpawn = false
radialScreen.Enabled = false
radialScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
radialScreen.IgnoreGuiInset = true
radialScreen.Parent = playerGui

-- ── React roots ─────────────────────────────────────────────────────────────

local hudRoot = ReactRoblox.createRoot(hudScreen)
local radialRoot = ReactRoblox.createRoot(radialScreen)

local handleSlotSwitch: (newSlot: HudActiveSlot) -> ()

-- ── Radial dial state ───────────────────────────────────────────────────────

local HOLD_THRESHOLD_SECS = 0.2

local radialVisible = false
local qPressTime: number? = nil
local highlightedIndex: number? = nil
local virtualCursorOffset = Vector2.new(0, 0)

-- ── Render ─────────────────────────────────────────────────────────────────

local function renderHud()
	local state = HudLoadoutDataAdapter.getState()
	local abilityBarPreset = HudLoadoutDataAdapter.getAbilityBarPreset()
	hudRoot:render(React.createElement(HudLoadoutApp, {
		state = state,
		abilityBarPreset = abilityBarPreset,
		viewportSize = getViewportSize(),
		onSlot1 = function()
			handleSlotSwitch("Weapon1")
		end,
		onSlot2 = function()
			handleSlotSwitch("Weapon2")
		end,
		onSlot3 = function()
			HudLoadoutDataAdapter.setActiveSlot("Fists")
		end,
		onQuickUse = function()
			HudLoadoutDataAdapter.setActiveSlot("QuickUse")
		end,
	}))
end

local function renderRadial()
	local state = HudLoadoutDataAdapter.getState()
	radialRoot:render(React.createElement(HudRadialDial, {
		items            = state.quickUseItems,
		highlightedIndex = highlightedIndex,
		visible          = radialVisible,
		viewportSize     = getViewportSize(),
	}))
end

-- ── Weapon bar: expanded weapon ─────────────────────────────────────────────

handleSlotSwitch = function(newSlot: HudActiveSlot)
	local prevState = HudLoadoutDataAdapter.getState()

	HudLoadoutDataAdapter.setActiveSlot(newSlot)

	-- Only update expandedWeapon when the player moves between weapon slots.
	-- Switching to QuickUse or Fists leaves expandedWeapon unchanged.
	if newSlot == "Weapon1" or newSlot == "Weapon2" then
		-- If we are expanding a weapon for the first time (expandedWeapon is nil),
		-- or switching from one weapon to the other, set it to the new slot.
		if prevState.expandedWeapon ~= newSlot then
			HudLoadoutDataAdapter.setExpandedWeapon(newSlot)
		end
	end
end

-- ── Subscriptions (adapter, keybinds, ability state, cooldown tick) ────────

HudLoadoutDataAdapter.subscribe(function(_state: HudLoadoutState)
	renderHud()
end)
KeybindsClient.subscribe(function()
	renderHud()
end)
AbilityStateClient.subscribe(function()
	renderHud()
end)

RunService.Heartbeat:Connect(function()
	if AbilityStateClient.anyCooldownActive() then
		renderHud()
	end
end)

-- ── Quick-use radial (virtual cursor, camera, open/close) ─────────────────

-- 8-way sectors from cursor offset; nil = cancel dead zone.
local VIRTUAL_CURSOR_DEADZONE_RADIUS = 70
local VIRTUAL_CURSOR_MAX_RADIUS = 400

local function getHighlightedSlotFromOffset(offsetFromCenter: Vector2): number?
	local dx, dy = offsetFromCenter.X, offsetFromCenter.Y
	local distSq = dx * dx + dy * dy
	if distSq < VIRTUAL_CURSOR_DEADZONE_RADIUS * VIRTUAL_CURSOR_DEADZONE_RADIUS then
		return nil
	end

	local mouseAngle = math.atan2(dy, dx)
	local normalized = (mouseAngle + math.pi / 2) % (2 * math.pi)

	local sectorSize = 2 * math.pi / 8
	local sectorIdx  = math.floor((normalized + sectorSize / 2) / sectorSize) % 8 + 1

	return sectorIdx
end

local previousCameraType: Enum.CameraType? = nil
local previousMouseIconEnabled: boolean? = nil
local GUIsHiddenForRadial: { ScreenGui } = {}

local radialCameraLookVector: Vector3? = nil
local radialCameraOffsetFromRoot: Vector3? = nil

local CROSSHAIR_GUI_NAMES = { "CrosshairGui", "ShiftLockGui", "CursorGui" }

local function setRadialDialOpen(open: boolean)
	local cam = workspace.CurrentCamera
	if open then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition

		previousMouseIconEnabled = UserInputService.MouseIconEnabled
		UserInputService.MouseIconEnabled = false

		table.clear(GUIsHiddenForRadial)
		for _, child in ipairs(playerGui:GetChildren()) do
			if child:IsA("ScreenGui") then
				for _, name in ipairs(CROSSHAIR_GUI_NAMES) do
					if child.Name == name and child.Enabled then
						child.Enabled = false
						table.insert(GUIsHiddenForRadial, child :: ScreenGui)
						break
					end
				end
			end
		end

		if cam then
			previousCameraType = cam.CameraType
			cam.CameraType = Enum.CameraType.Scriptable
			radialCameraLookVector = cam.CFrame.LookVector
			local character = localPlayer.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
				if root then
					radialCameraOffsetFromRoot = cam.CFrame.Position - root.Position
				else
					radialCameraOffsetFromRoot = Vector3.new(0, 0, 0)
				end
			else
				radialCameraOffsetFromRoot = Vector3.new(0, 0, 0)
			end
		end

		virtualCursorOffset = Vector2.new(0, 0)
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default

		if previousMouseIconEnabled ~= nil then
			UserInputService.MouseIconEnabled = previousMouseIconEnabled
			previousMouseIconEnabled = nil
		end

		for _, gui in ipairs(GUIsHiddenForRadial) do
			if gui.Parent then
				gui.Enabled = true
			end
		end
		table.clear(GUIsHiddenForRadial)

		if cam and previousCameraType ~= nil then
			cam.CameraType = previousCameraType
			previousCameraType = nil
		end
		radialCameraLookVector = nil
		radialCameraOffsetFromRoot = nil

		virtualCursorOffset = Vector2.new(0, 0)
	end
end

RunService.RenderStepped:Connect(function()
	if not radialVisible then return end

	local cam = workspace.CurrentCamera
	if cam and radialCameraLookVector and radialCameraOffsetFromRoot then
		local character = localPlayer.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
			if root then
				local camPos = root.Position + radialCameraOffsetFromRoot
				cam.CFrame = CFrame.lookAt(camPos, camPos + radialCameraLookVector)
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not radialVisible then return end

	local delta = UserInputService:GetMouseDelta()
	virtualCursorOffset = virtualCursorOffset + Vector2.new(delta.X, delta.Y)

	local len = math.sqrt(virtualCursorOffset.X * virtualCursorOffset.X + virtualCursorOffset.Y * virtualCursorOffset.Y)
	if len > VIRTUAL_CURSOR_MAX_RADIUS then
		local scale = VIRTUAL_CURSOR_MAX_RADIUS / len
		virtualCursorOffset = Vector2.new(virtualCursorOffset.X * scale, virtualCursorOffset.Y * scale)
	end

	highlightedIndex = getHighlightedSlotFromOffset(virtualCursorOffset)
	renderRadial()
end)

-- ── HUD keybinds ────────────────────────────────────────────────────────────

KeybindsClient.bindAction(KeybindIds.HudWeapon1, function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		handleSlotSwitch("Weapon1")
	end
	return Enum.ContextActionResult.Sink
end, {
	actionName = "HudWeapon1",
})

KeybindsClient.bindAction(KeybindIds.HudWeapon2, function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		handleSlotSwitch("Weapon2")
	end
	return Enum.ContextActionResult.Sink
end, {
	actionName = "HudWeapon2",
})

KeybindsClient.bindAction(KeybindIds.HudFists, function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		HudLoadoutDataAdapter.setActiveSlot("Fists")
	end
	return Enum.ContextActionResult.Sink
end, {
	actionName = "HudFists",
})

KeybindsClient.bindAction(KeybindIds.HudQuickUse, function(_name, inputState, _input)
	if inputState == Enum.UserInputState.Begin then
		qPressTime = os.clock()

	elseif inputState == Enum.UserInputState.End then
		local pressTime = qPressTime
		qPressTime = nil

		if pressTime then
			local held = os.clock() - pressTime
			if held < HOLD_THRESHOLD_SECS then
				HudLoadoutDataAdapter.setActiveSlot("QuickUse")
				if radialVisible then
					radialVisible = false
					radialScreen.Enabled = false
					setRadialDialOpen(false)
					renderRadial()
				end
			else
				if radialVisible then
					if highlightedIndex then
						HudLoadoutDataAdapter.setCurrentQuickSlotIndex(highlightedIndex)
						HudLoadoutDataAdapter.setActiveSlot("QuickUse")
					end
					radialVisible = false
					radialScreen.Enabled = false
					setRadialDialOpen(false)
					highlightedIndex = nil
					renderRadial()
					renderHud()
				end
			end
		end
	end
	return Enum.ContextActionResult.Sink
end, {
	actionName = "HudQuickUse",
})

RunService.Heartbeat:Connect(function()
	if qPressTime and not radialVisible then
		local held = os.clock() - qPressTime
		if held >= HOLD_THRESHOLD_SECS then
			radialVisible = true
			radialScreen.Enabled = true
			setRadialDialOpen(true)
			renderRadial()
		end
	end
end)

KeybindsClient.bindAction(KeybindIds.HudFlashlight, function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		HudLoadoutDataAdapter.toggleFlashlight()
	end
	return Enum.ContextActionResult.Sink
end, {
	actionName = "HudFlashlight",
})

-- ── Viewport resize ─────────────────────────────────────────────────────────

local lastViewportSize = getViewportSize()
RunService.Heartbeat:Connect(function()
	local current = getViewportSize()
	if current ~= lastViewportSize then
		lastViewportSize = current
		renderHud()
		if radialVisible then
			renderRadial()
		end
	end
end)

-- ── Initial render ──────────────────────────────────────────────────────────

renderHud()
