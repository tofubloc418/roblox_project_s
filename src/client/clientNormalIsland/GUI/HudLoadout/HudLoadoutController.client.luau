--!strict
--[[
	HudLoadoutController
	====================
	Client-side controller for the in-game HUD equipment section.

	Responsibilities:
	  1. Create the ScreenGui and mount the React root.
	  2. Subscribe to HudLoadoutDataAdapter for state changes → re-render.
	  3. Bind input keys (1, 2, 3, Q, F) via ContextActionService.
	  4. Own the expandedWeapon logic (see §5 of spec).
	  5. Manage Q hold → show radial dial, Q release → hide and select.

	expandedWeapon rule (spec §5):
	  • Switching between Weapon1 and Weapon2 → update expandedWeapon to
	    the newly active weapon (collapses the other card's visual).
	  • Switching from a weapon to Q or Fists → leave expandedWeapon unchanged
	    (last active weapon keeps its visual).

	Q tap vs hold detection:
	  • Q Begin: record timestamp.
	  • Q End  : if held < HOLD_THRESHOLD_SECS → tap (equip current quick item).
	             if held ≥ HOLD_THRESHOLD_SECS → was hold; hide radial and apply selection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React")) :: any
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox")) :: any

local HudLoadoutDataAdapter = require(script.Parent:WaitForChild("HudLoadoutDataAdapter"))
local HudLoadoutTypes = require(script.Parent:WaitForChild("HudLoadoutTypes"))
local HudLoadoutApp = require(script.Parent:WaitForChild("HudLoadoutApp"))
local HudRadialDial = require(script.Parent:WaitForChild("HudRadialDial"))

type HudLoadoutState = HudLoadoutTypes.HudLoadoutState
type HudActiveSlot = HudLoadoutTypes.HudActiveSlot

local localPlayer = Players.LocalPlayer

local function getViewportSize(): Vector2
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

-- ── ScreenGuis ──────────────────────────────────────────────────────────────

local playerGui = localPlayer:WaitForChild("PlayerGui")

-- HUD loadout ScreenGui (always visible during gameplay)
local hudScreen = Instance.new("ScreenGui")
hudScreen.Name = "HudLoadoutScreen"
hudScreen.ResetOnSpawn = false
hudScreen.Enabled = true
hudScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
hudScreen.IgnoreGuiInset = true
hudScreen.Parent = playerGui

-- Radial dial ScreenGui (above HUD, below loadout; shown only while Q is held)
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

-- Forward-declared so renderHud closures can reference it before the body is set.
local handleSlotSwitch: (newSlot: HudActiveSlot) -> ()

-- ── Radial state ─────────────────────────────────────────────────────────────

local HOLD_THRESHOLD_SECS = 0.2    -- seconds before Q is treated as a hold

local radialVisible = false
local qPressTime: number? = nil
local highlightedIndex: number? = nil
-- When dial is open, mouse is center-locked; we use accumulated delta as a "virtual" cursor for sector selection.
local virtualCursorOffset = Vector2.new(0, 0)

-- ── Render helpers ───────────────────────────────────────────────────────────

local function renderHud()
	local state = HudLoadoutDataAdapter.getState()
	local abilityBarSlots = HudLoadoutDataAdapter.getAbilityBarSlots()
	hudRoot:render(React.createElement(HudLoadoutApp, {
		state = state,
		abilityBarSlots = abilityBarSlots,
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

-- ── expandedWeapon logic ─────────────────────────────────────────────────────

handleSlotSwitch = function(newSlot: HudActiveSlot)
	local prevState = HudLoadoutDataAdapter.getState()

	HudLoadoutDataAdapter.setActiveSlot(newSlot)

	-- Only update expandedWeapon when the player moves between weapon slots.
	-- Switching to Q or Fists intentionally leaves it unchanged.
	if newSlot == "Weapon1" or newSlot == "Weapon2" then
		-- If we are expanding a weapon for the first time (expandedWeapon is nil),
		-- or switching from one weapon to the other, set it to the new slot.
		if prevState.expandedWeapon ~= newSlot then
			HudLoadoutDataAdapter.setExpandedWeapon(newSlot)
		end
	end
end

-- ── Data adapter subscription ────────────────────────────────────────────────
-- Re-render HUD whenever adapter state changes (e.g. from external systems).
HudLoadoutDataAdapter.subscribe(function(_state: HudLoadoutState)
	renderHud()
end)

-- ── Radial dial mouse tracking ───────────────────────────────────────────────

-- Compute which of the 8 fixed slots an offset-from-center is pointing at.
-- offsetFromCenter: (dx, dy) from screen center. Returns nil when within radial dead zone (Cancel).
local VIRTUAL_CURSOR_DEADZONE_RADIUS = 70   -- virtual pixels; inside this circle = Cancel (larger = easier to cancel)
local VIRTUAL_CURSOR_MAX_RADIUS = 400

local function getHighlightedSlotFromOffset(offsetFromCenter: Vector2): number?
	local dx, dy = offsetFromCenter.X, offsetFromCenter.Y
	local distSq = dx * dx + dy * dy
	if distSq < VIRTUAL_CURSOR_DEADZONE_RADIUS * VIRTUAL_CURSOR_DEADZONE_RADIUS then
		return nil
	end

	-- Angle: 0 = right, clockwise. Normalize so 0 = top.
	local mouseAngle = math.atan2(dy, dx)                          -- [-π, π]
	local normalized = (mouseAngle + math.pi / 2) % (2 * math.pi)   -- [0, 2π], 0 = top

	local sectorSize = 2 * math.pi / 8
	local sectorIdx  = math.floor((normalized + sectorSize / 2) / sectorSize) % 8 + 1

	return sectorIdx
end

-- When dial opens: lock mouse, hide cursor/crosshair, take over camera so it follows the
-- character but does not rotate from mouse (Scriptable + manual update each frame).
-- When dial closes: restore camera type and cursor/crosshair visibility.
local previousCameraType: Enum.CameraType? = nil
local previousMouseIconEnabled: boolean? = nil
local GUIsHiddenForRadial: { ScreenGui } = {}

-- Saved when radial opens: camera look direction and offset from character root to camera (so we can follow character).
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

-- Update scriptable camera every frame so it follows the character (RenderStepped = after movement, before render).
RunService.RenderStepped:Connect(function()
	if not radialVisible then return end

	local cam = workspace.CurrentCamera
	-- Scriptable camera: follow character position but keep fixed look direction (no mouse rotation).
	-- Use localPlayer.Character (CameraSubject can be cleared when camera is Scriptable).
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

	-- Mouse is center-locked; use delta to update virtual cursor, then derive sector.
	local delta = UserInputService:GetMouseDelta()
	virtualCursorOffset = virtualCursorOffset + Vector2.new(delta.X, delta.Y)

	-- Clamp so we don't overflow and angle stays stable
	local len = math.sqrt(virtualCursorOffset.X * virtualCursorOffset.X + virtualCursorOffset.Y * virtualCursorOffset.Y)
	if len > VIRTUAL_CURSOR_MAX_RADIUS then
		local scale = VIRTUAL_CURSOR_MAX_RADIUS / len
		virtualCursorOffset = Vector2.new(virtualCursorOffset.X * scale, virtualCursorOffset.Y * scale)
	end

	highlightedIndex = getHighlightedSlotFromOffset(virtualCursorOffset)
	renderRadial()
end)

-- ── Key bindings ─────────────────────────────────────────────────────────────

-- Keys 1 and 2: weapon slots
ContextActionService:BindAction("HudWeapon1", function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		handleSlotSwitch("Weapon1")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.One)

ContextActionService:BindAction("HudWeapon2", function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		handleSlotSwitch("Weapon2")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Two)

-- Key 3: fists / unequip
ContextActionService:BindAction("HudFists", function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		HudLoadoutDataAdapter.setActiveSlot("Fists")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Three)

-- Key Q: tap = equip current quick slot; hold = radial dial
ContextActionService:BindAction("HudQuickUse", function(_name, inputState, _input)
	if inputState == Enum.UserInputState.Begin then
		qPressTime = os.clock()
		-- Start showing radial after a tiny delay handled in Heartbeat
		-- (we don't open it immediately to distinguish taps)

	elseif inputState == Enum.UserInputState.End then
		local pressTime = qPressTime
		qPressTime = nil

		if pressTime then
			local held = os.clock() - pressTime
			if held < HOLD_THRESHOLD_SECS then
				-- Tap: equip current quick-slot item
				HudLoadoutDataAdapter.setActiveSlot("QuickUse")
				-- Close radial if it somehow got opened
				if radialVisible then
					radialVisible = false
					radialScreen.Enabled = false
					setRadialDialOpen(false)
					renderRadial()
				end
			else
				-- Hold release: apply highlighted selection and equip quick slot (same as tap Q).
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
end, false, Enum.KeyCode.Q)

-- Heartbeat: open radial once Q has been held past the threshold
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

-- Key F: flashlight toggle
ContextActionService:BindAction("HudFlashlight", function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		HudLoadoutDataAdapter.toggleFlashlight()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.F)

-- ── Viewport resize ──────────────────────────────────────────────────────────

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

-- ── Initial render ───────────────────────────────────────────────────────────

renderHud()
