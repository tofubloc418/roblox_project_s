--!strict
-- DragDropManager: ghost visual, slot hit-testing, and drop callbacks for loadout/stash drag-and-drop.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

export type DragContainerId = "backpack" | "equipment" | "quickuse" | "stash" | "loot"

export type DragDescriptor = {
	container: DragContainerId,
	index: number?,
	slotId: string?,
}

export type DragGhostVisual = {
	imageId: string,
	labelText: string,
	stackText: string,
}

export type DragState = {
	active: boolean,
	source: DragDescriptor?,
	ghost: DragGhostVisual?,
	position: Vector2?,
}

type PendingDrag = {
	source: DragDescriptor,
	ghost: DragGhostVisual,
	startPosition: Vector2,
}

type ActiveDrag = {
	source: DragDescriptor,
	ghost: DragGhostVisual,
}

local localPlayer = Players.LocalPlayer

local DRAG_THRESHOLD_PX = 10
local GHOST_SIZE = 64
local GHOST_OFFSET = Vector2.new(18, 18)
local GHOST_ZINDEX = 1000

local attachedScreen: ScreenGui? = nil
local ghostLayer: ScreenGui? = nil
local ghostFrame: Frame? = nil
local ghostIcon: ImageLabel? = nil
local ghostLabel: TextLabel? = nil
local ghostStack: TextLabel? = nil

local stateSubscribers: { (DragState) -> () } = {}
local dropSubscribers: { (DragDescriptor, DragDescriptor?, Vector2) -> () } = {}

local currentPointerPosition = Vector2.zero
local pendingDrag: PendingDrag? = nil
local activeDrag: ActiveDrag? = nil
local suppressNextActivation = false
local currentHoveredTarget: DragDescriptor? = nil

local function buildState(): DragState
	if activeDrag then
		return {
			active = true,
			source = activeDrag.source,
			ghost = activeDrag.ghost,
			position = currentPointerPosition,
		}
	end

	return {
		active = false,
		source = nil,
		ghost = nil,
		position = nil,
	}
end

local function notifyStateChanged()
	local snapshot = buildState()
	for _, callback in ipairs(stateSubscribers) do
		callback(snapshot)
	end
end

local function ensureGhostLayer(screenGui: ScreenGui)
	if attachedScreen == screenGui and ghostLayer and ghostFrame and ghostIcon and ghostLabel and ghostStack then
		return
	end

	if ghostLayer then
		ghostLayer:Destroy()
	end

	attachedScreen = screenGui

	local layer = Instance.new("ScreenGui")
	layer.Name = "DragDropLayer"
	layer.ResetOnSpawn = false
	layer.IgnoreGuiInset = screenGui.IgnoreGuiInset
	layer.ZIndexBehavior = Enum.ZIndexBehavior.Global
	layer.DisplayOrder = (screenGui.DisplayOrder or 0) + 1
	layer.Enabled = true
	layer.Parent = screenGui.Parent

	local frame = Instance.new("Frame")
	frame.Name = "GhostFrame"
	frame.Size = UDim2.fromOffset(GHOST_SIZE, GHOST_SIZE)
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = GHOST_ZINDEX
	frame.Parent = layer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.2
	stroke.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "GhostIcon"
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = GHOST_ZINDEX + 1
	icon.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "GhostLabel"
	label.Size = UDim2.fromScale(1, 0.28)
	label.Position = UDim2.fromScale(0, 0.72)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.ZIndex = GHOST_ZINDEX + 2
	label.Parent = frame

	local stack = Instance.new("TextLabel")
	stack.Name = "GhostStack"
	stack.Size = UDim2.fromScale(0.45, 0.22)
	stack.Position = UDim2.fromScale(0.55, 0)
	stack.BackgroundTransparency = 1
	stack.TextColor3 = Color3.fromRGB(180, 180, 190)
	stack.Font = Enum.Font.Gotham
	stack.TextScaled = true
	stack.TextXAlignment = Enum.TextXAlignment.Right
	stack.ZIndex = GHOST_ZINDEX + 2
	stack.Parent = frame

	ghostLayer = layer
	ghostFrame = frame
	ghostIcon = icon
	ghostLabel = label
	ghostStack = stack
end

local function updateGhostVisual()
	if not ghostFrame or not ghostIcon or not ghostLabel or not ghostStack then
		return
	end

	if not activeDrag then
		ghostFrame.Visible = false
		return
	end

	ghostFrame.Visible = true
	ghostFrame.Position = UDim2.fromOffset(
		math.floor(currentPointerPosition.X + GHOST_OFFSET.X),
		math.floor(currentPointerPosition.Y + GHOST_OFFSET.Y)
	)

	local ghost = activeDrag.ghost
	ghostIcon.Image = ghost.imageId
	ghostIcon.ImageTransparency = if ghost.imageId == "" then 1 else 0
	ghostLabel.Text = ghost.labelText
	ghostStack.Text = ghost.stackText
end

local function clearDragState()
	pendingDrag = nil
	activeDrag = nil
	currentHoveredTarget = nil
	updateGhostVisual()
	notifyStateChanged()
end

local DragDropManager = {}

function DragDropManager.attachGhostLayer(screenGui: ScreenGui)
	ensureGhostLayer(screenGui)
	updateGhostVisual()
end

function DragDropManager.prepareDrag(source: DragDescriptor, ghost: DragGhostVisual)
	local pointer = UserInputService:GetMouseLocation()
	currentPointerPosition = Vector2.new(pointer.X, pointer.Y)
	pendingDrag = {
		source = source,
		ghost = ghost,
		startPosition = currentPointerPosition,
	}
	activeDrag = nil
	updateGhostVisual()
	notifyStateChanged()
end

function DragDropManager.cancelDrag()
	clearDragState()
end

function DragDropManager.getState(): DragState
	return buildState()
end

function DragDropManager.isDragging(): boolean
	return activeDrag ~= nil
end

function DragDropManager.consumeActivatedSuppression(): boolean
	if suppressNextActivation then
		suppressNextActivation = false
		return true
	end

	return false
end

function DragDropManager.subscribe(callback: (DragState) -> ()): () -> ()
	table.insert(stateSubscribers, callback)
	callback(buildState())

	return function()
		local index = table.find(stateSubscribers, callback)
		if index then
			table.remove(stateSubscribers, index)
		end
	end
end

function DragDropManager.subscribeToDrop(callback: (DragDescriptor, DragDescriptor?, Vector2) -> ()): () -> ()
	table.insert(dropSubscribers, callback)

	return function()
		local index = table.find(dropSubscribers, callback)
		if index then
			table.remove(dropSubscribers, index)
		end
	end
end
function DragDropManager.notifyHoverEnter(descriptor: DragDescriptor)
	-- Only track hover while a drag is pending or active so normal hover doesn't affect drops.
	if not pendingDrag and not activeDrag then
		return
	end
	currentHoveredTarget = descriptor
end

function DragDropManager.notifyHoverLeave(descriptor: DragDescriptor)
	if currentHoveredTarget == nil then
		return
	end

	if currentHoveredTarget.container == descriptor.container
		and currentHoveredTarget.index == descriptor.index
		and currentHoveredTarget.slotId == descriptor.slotId
	then
		currentHoveredTarget = nil
	end
end

UserInputService.InputChanged:Connect(function(input: InputObject, _gameProcessedEvent: boolean)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local pointer = UserInputService:GetMouseLocation()
	currentPointerPosition = Vector2.new(pointer.X, pointer.Y)

	if pendingDrag and not activeDrag then
		local delta = currentPointerPosition - pendingDrag.startPosition
		if delta.Magnitude >= DRAG_THRESHOLD_PX then
			activeDrag = {
				source = pendingDrag.source,
				ghost = pendingDrag.ghost,
			}
			pendingDrag = nil
		end
	end

	updateGhostVisual()
	notifyStateChanged()
end)

UserInputService.InputEnded:Connect(function(input: InputObject, _gameProcessedEvent: boolean)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local pointer = UserInputService:GetMouseLocation()
	currentPointerPosition = Vector2.new(pointer.X, pointer.Y)

	if activeDrag then
		local source = activeDrag.source
		local target = currentHoveredTarget
		local dropPoint = currentPointerPosition
		suppressNextActivation = true
		for _, callback in ipairs(dropSubscribers) do
			callback(source, target, dropPoint)
		end
	end

	clearDragState()
end)

localPlayer.AncestryChanged:Connect(function(_, parent)
	if not parent then
		clearDragState()
	end
end)

return DragDropManager
