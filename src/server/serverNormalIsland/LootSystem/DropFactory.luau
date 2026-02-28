--[[
	DropFactory
	Creates physical pickup instances for dropped items
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local _Players = game:GetService("Players")

-- Shared modules
local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("ItemDefinitions"))

local DropFactory = {}
DropFactory.__index = DropFactory

local MIN_SEPARATION = 3 -- studs; hardcoded minimum distance between drops

function DropFactory.new()
	local self = setmetatable({}, DropFactory)
	
	-- Ensure dropped items container exists
	self.DroppedItemsContainer = Workspace:FindFirstChild("DroppedItems")
	if not self.DroppedItemsContainer then
		self.DroppedItemsContainer = Instance.new("Folder")
		self.DroppedItemsContainer.Name = "DroppedItems"
		self.DroppedItemsContainer.Parent = Workspace
	end
	
	-- Cache for prefabs
	self._prefabCache = {}
	self.InventoryService = nil -- Will be set during initialization
	return self
end

function DropFactory:Initialize(inventoryService)
	self.InventoryService = inventoryService
end

-- Remove any ProximityPrompt descendants from an instance
function DropFactory:RemovePickupPrompts(instance: Instance)
	for _, d in ipairs(instance:GetDescendants()) do
		if d:IsA("ProximityPrompt") or (d:IsA("BasePart") and d.Name == "Bubble") then
			d:Destroy()
		end
	end
end

-- Create a floating bubble visual and anchor the drop slightly off the ground
function DropFactory:ApplyFloatingBubble(dropModel: Instance)
	local primaryPart: BasePart?
	if dropModel:IsA("Model") then
		primaryPart = dropModel.PrimaryPart or dropModel:FindFirstChildWhichIsA("BasePart")
	elseif dropModel:IsA("BasePart") then
		primaryPart = dropModel
	elseif dropModel:IsA("Tool") then
		local h = dropModel:FindFirstChild("Handle", true)
		if h and h:IsA("BasePart") then
			primaryPart = h
		end
	end
	if not primaryPart then return end

	-- Anchor the drop in place while on the ground
	primaryPart.Anchored = true

	-- Compute bubble size
	local diameter = 2
	if dropModel:IsA("Model") then
		local _, size = dropModel:GetBoundingBox()
		diameter = math.max(size.X, math.max(size.Y, size.Z)) * 1.4
	elseif primaryPart then
		diameter = math.max(primaryPart.Size.X, math.max(primaryPart.Size.Y, primaryPart.Size.Z)) * 1.4
	end

	-- Create bubble
	local bubble = Instance.new("Part")
	bubble.Name = "Bubble"
	bubble.Shape = Enum.PartType.Ball
	bubble.Material = Enum.Material.ForceField
	bubble.Color = Color3.fromRGB(185, 230, 255)
	bubble.Transparency = 0.35
	bubble.Size = Vector3.new(diameter, diameter, diameter)
	bubble.Anchored = true
	bubble.CanCollide = false
	bubble.CanQuery = false
	bubble.CanTouch = false
	bubble.CFrame = primaryPart.CFrame * CFrame.new(0, 0.25, 0)
	bubble.Parent = dropModel
end

-- Compute a representative world position for a drop (Handle/PrimaryPart or pivot)
function DropFactory:GetDropWorldPosition(dropModel: Instance): Vector3?
	if dropModel:IsA("Model") or dropModel:IsA("Tool") then
		local dm: any = dropModel
		local cf = dm:GetPivot()
		return cf.Position
	elseif dropModel:IsA("BasePart") then
		local bp: any = dropModel
		return bp.Position
	end
	return nil
end

-- Move a drop to a given world position (preserve current rotation)
function DropFactory:SetDropWorldPosition(dropModel: Instance, newPosition: Vector3)
	if dropModel:IsA("Model") or dropModel:IsA("Tool") then
		local dm: any = dropModel
		local current = dm:GetPivot()
		dm:PivotTo(CFrame.new(newPosition) * CFrame.fromMatrix(Vector3.new(), current.XVector, current.YVector))
	elseif dropModel:IsA("BasePart") then
		local bp: any = dropModel
		bp.CFrame = CFrame.new(newPosition)
	end
end

-- Light repulsion of the newly spawned drop away from nearby existing drops
function DropFactory:ResolveSeparationForNewDrop(newDrop: Instance)
	if not self.DroppedItemsContainer then return end

	local function computePush(fromPos: Vector3, toPos: Vector3)
		local delta = toPos - fromPos
		delta = Vector3.new(delta.X, 0, delta.Z) -- horizontal only
		local dist = delta.Magnitude
		if dist <= 1e-3 then
			-- Random small nudge to break symmetry
			local angle = math.random() * math.pi * 2
			return Vector3.new(math.cos(angle), 0, math.sin(angle)) * (MIN_SEPARATION * 0.5)
		end
		if dist >= MIN_SEPARATION then
			return Vector3.new(0, 0, 0)
		end
		local needed = MIN_SEPARATION - dist
		return (-delta.Unit) * needed * 0.5 -- move half the overlap away
	end

	local iterations = 8
	for _ = 1, iterations do
		local pos = self:GetDropWorldPosition(newDrop)
		if not pos then return end
		local totalPush = Vector3.new(0, 0, 0)
		for _, other in ipairs(self.DroppedItemsContainer:GetChildren()) do
			if other ~= newDrop then
				local otherPos = self:GetDropWorldPosition(other)
				if otherPos then
					totalPush += computePush(pos, otherPos)
				end
			end
		end
		if totalPush.Magnitude < 0.01 then
			break
		end
		-- Clamp step size for stability
		local step = totalPush
		local maxStep = 2
		if step.Magnitude > maxStep then
			step = step.Unit * maxStep
		end
		local newPos = Vector3.new(pos.X, pos.Y, pos.Z) + step
		self:SetDropWorldPosition(newDrop, newPos)
	end
end

-- Spawn a dropped item
function DropFactory:SpawnDrop(itemId: string, stackCount: number, position: Vector3, impulse: Vector3?, existingTool: Tool?)
	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then
		warn("Invalid item ID for drop:", itemId)
		return nil
	end
	
	local dropModel: Instance
	
	-- If we have an existing tool (from player dropping), use it
	if existingTool then
		dropModel = existingTool
		-- Clear the slot index as it's no longer in inventory
		dropModel:SetAttribute("SlotIndex", nil)
	else
		-- Create new tool from prefab
		local prefab = self:GetItemPrefab(itemId)
		if not prefab then
			warn(string.format("No prefab found for item '%s'; skipping spawn", tostring(itemId)))
			return nil
		end
		
		if prefab:IsA("Tool") then
			dropModel = prefab:Clone()
		else
			-- Convert Model to Tool (preserve Muzzle; don't rename it)
			local tool = Instance.new("Tool")
			tool.Name = itemData.displayName or itemId
			tool.RequiresHandle = true
			
			local clone = prefab:Clone()
			local hasHandle = false
			local primaryForHandle: BasePart? = nil
			
			-- Move children into the tool without renaming Muzzle
			for _, child in ipairs(clone:GetChildren()) do
				child.Parent = tool
				if child:IsA("BasePart") then
					if child.Name == "Handle" then
						hasHandle = true
					end
					if not primaryForHandle then
						primaryForHandle = child
					end
				end
			end
			clone:Destroy()
			
			-- Ensure a Handle exists (do NOT repurpose Muzzle)
			if not hasHandle then
				local handle = Instance.new("Part")
				handle.Name = "Handle"
				handle.Size = Vector3.new(1, 1, 1)
				handle.Transparency = 1
				handle.CanCollide = false
				handle.CanQuery = false
				handle.CanTouch = false
				handle.Parent = tool
				if primaryForHandle then
					handle.CFrame = (primaryForHandle :: BasePart).CFrame
				end
			end
			
			dropModel = tool
		end
		
		-- Set attributes for new drops
		dropModel:SetAttribute("ItemId", itemId)
		dropModel:SetAttribute("CurrentStack", stackCount)
		dropModel:SetAttribute("MaxStack", itemData.stackMax or 1)
	end

	-- Position the drop
	if dropModel:IsA("Model") or dropModel:IsA("Tool") then
		dropModel:PivotTo(CFrame.new(position + Vector3.new(0, 1, 0)))
	elseif dropModel:IsA("BasePart") then
		dropModel.Position = position + Vector3.new(0, 1, 0)
	end
	
	-- Mark as pickup
	dropModel:SetAttribute("IsPickup", true)
	
	-- Disable default Roblox auto-pickup for Tools by turning off Handle touch
	if dropModel:IsA("Tool") then
		local handle = dropModel:FindFirstChild("Handle", true)
		if handle and handle:IsA("BasePart") then
			handle.CanTouch = false
		end
	end
	
	if impulse then
		self:ApplyImpulse(dropModel, impulse)
	end
	
	dropModel.Parent = self.DroppedItemsContainer

	-- Apply floating bubble visual
	self:ApplyFloatingBubble(dropModel)

	-- Lightly separate from neighbors to avoid overlapping pickup prompts
	self:ResolveSeparationForNewDrop(dropModel)
	
	-- Setup pickup interaction
	self:SetupPickupInteraction(dropModel)
	
	return dropModel
end

-- Get item prefab
function DropFactory:GetItemPrefab(itemId: string)
	if self._prefabCache[itemId] ~= nil then
		return self._prefabCache[itemId]
	end

	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then
		self._prefabCache[itemId] = nil
		return nil
	end

	local lootRoot = ReplicatedStorage:FindFirstChild("Loot")
	if not lootRoot then
		self._prefabCache[itemId] = nil
		return nil
	end

	local categoryFolder = lootRoot:FindFirstChild(itemData.category)
	if not categoryFolder then
		self._prefabCache[itemId] = nil
		return nil
	end

	local found: Instance? = nil
	-- Prefer a Tool directly under category
	for _, child in ipairs(categoryFolder:GetChildren()) do
		if child:IsA("Tool") and child.Name == itemId then
			found = child
			break
		end
	end
	-- Fallback: any Tool in descendants
	if not found then
		for _, descendant in ipairs(categoryFolder:GetDescendants()) do
			if descendant:IsA("Tool") and descendant.Name == itemId then
				found = descendant
				break
			end
		end
	end
	-- Fallback: Model directly under category
	if not found then
		for _, child in ipairs(categoryFolder:GetChildren()) do
			if child:IsA("Model") and child.Name == itemId then
				found = child
				break
			end
		end
	end
	-- Fallback: any Model in descendants
	if not found then
		for _, descendant in ipairs(categoryFolder:GetDescendants()) do
			if descendant:IsA("Model") and descendant.Name == itemId then
				found = descendant
				break
			end
		end
	end

	self._prefabCache[itemId] = found
	return found
end

-- Apply physics impulse to dropped item
function DropFactory:ApplyImpulse(dropModel: Instance, impulse: Vector3)
	local primaryPart
	
	if dropModel:IsA("Model") then
		primaryPart = dropModel.PrimaryPart or dropModel:FindFirstChildWhichIsA("BasePart")
	elseif dropModel:IsA("BasePart") then
		primaryPart = dropModel
	end
	
	if primaryPart then
		-- Ensure part is unanchored
		primaryPart.Anchored = false
		
		-- Apply velocity
		if primaryPart.AssemblyMass then
			primaryPart.AssemblyLinearVelocity = impulse
		else
			-- Fallback for older physics
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Velocity = impulse
			bodyVelocity.Parent = primaryPart
			
			-- Remove after a short time
			Debris:AddItem(bodyVelocity, 0.1)
		end
		
		-- Add some rotation for visual effect
		primaryPart.AssemblyAngularVelocity = Vector3.new(
			math.random(-5, 5),
			math.random(-5, 5),
			math.random(-5, 5)
		)
	end
end

-- Setup pickup interaction
function DropFactory:SetupPickupInteraction(dropModel: Instance)
	-- Use a ProximityPrompt (appear when close, press key while aiming)
	local primaryPart
	if dropModel:IsA("Model") then
		primaryPart = dropModel.PrimaryPart or dropModel:FindFirstChildWhichIsA("BasePart")
	elseif dropModel:IsA("BasePart") then
		primaryPart = dropModel
	elseif dropModel:IsA("Tool") then
		primaryPart = dropModel:FindFirstChild("Handle", true)
	end
	if not primaryPart then return end

	local existing = primaryPart:FindFirstChildOfClass("ProximityPrompt")
	if existing then existing:Destroy() end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick Up"
	local itemId = dropModel:GetAttribute("ItemId") or dropModel.Name

	local function updatePromptText()
		local def = ItemDefinitions.GetItem(itemId)
		local displayName = (def and def.displayName) or tostring(itemId)
		local count = dropModel:GetAttribute("CurrentStack") or dropModel:GetAttribute("StackCount") or 1
		prompt.ObjectText = string.format("%s x%d", displayName, count)
	end

	updatePromptText()
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = true
	prompt.MaxActivationDistance = 6
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = primaryPart

	-- Keep label in sync with stack count changes while in world
	dropModel:GetAttributeChangedSignal("CurrentStack"):Connect(updatePromptText)
	dropModel:GetAttributeChangedSignal("StackCount"):Connect(updatePromptText)

	prompt.Triggered:Connect(function(player)
		if dropModel.Parent and not dropModel:GetAttribute("PickedUp") then
			dropModel:SetAttribute("PickedUp", true)
			self:Pickup(dropModel, player)
		end
	end)
end

-- Pickup handling for new backpack system
function DropFactory:Pickup(dropModel: Instance, player: Player)
	local itemId = dropModel:GetAttribute("ItemId") or dropModel.Name
	local pickupCount = dropModel:GetAttribute("CurrentStack") or dropModel:GetAttribute("StackCount") or 1
	
	local InventoryService = self.InventoryService
	if not InventoryService then
		warn("InventoryService not initialized")
		return
	end
	
	-- Remove any lingering prompts before parenting to inventory/character
	self:RemovePickupPrompts(dropModel)
	
	-- If it's already a tool, we can potentially reuse it
	if dropModel:IsA("Tool") then
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return end
		
		local itemData = ItemDefinitions.GetItem(itemId)
		local maxStack = (itemData and itemData.stackMax) or 1
		local character = player.Character
		
		-- Ensure world-anchoring is removed
		local h = dropModel:FindFirstChild("Handle", true)
		if h and h:IsA("BasePart") then
			h.Anchored = false
		end
		
		-- Prefer stacking into an equipped tool first
		if character and pickupCount > 0 then
			for _, tool in ipairs(character:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("ItemId") == itemId then
					local currentStack = tool:GetAttribute("CurrentStack") or 1
					local toolMaxStack = tool:GetAttribute("MaxStack") or maxStack
					if currentStack < toolMaxStack then
						local space = toolMaxStack - currentStack
						local toAdd = math.min(space, pickupCount)
						tool:SetAttribute("CurrentStack", currentStack + toAdd)
						pickupCount = pickupCount - toAdd
						if pickupCount <= 0 then
							dropModel:Destroy()
							InventoryService:SyncInventory(player)
							return
						end
					end
				end
			end
		end
		
		-- Check if we can stack with existing items in backpack
		local _stacked = false
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("ItemId") == itemId then
				local currentStack = tool:GetAttribute("CurrentStack") or 1
				local toolMaxStack = tool:GetAttribute("MaxStack") or maxStack
				
				if currentStack < toolMaxStack then
					local space = toolMaxStack - currentStack
					local toAdd = math.min(space, pickupCount)
					
					tool:SetAttribute("CurrentStack", currentStack + toAdd)
					pickupCount = pickupCount - toAdd
					
					if pickupCount <= 0 then
						_stacked = true
						break
					end
				end
			end
		end
		
		-- If we still have items to add, find an empty slot
		if pickupCount > 0 then
			-- Find used slots
			local usedSlots = {}
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") then
					local slot = tool:GetAttribute("SlotIndex")
					if slot then
						usedSlots[slot] = true
					end
				end
			end
			
			-- Check character for equipped tools
			if character then
				for _, tool in ipairs(character:GetChildren()) do
					if tool:IsA("Tool") then
						local slot = tool:GetAttribute("SlotIndex")
						if slot then
							usedSlots[slot] = true
						end
					end
				end
			end
			
			-- Find empty slot
			local invSize = self.InventoryService and self.InventoryService.INVENTORY_SIZE or 16
			for slot = 1, invSize do
				if not usedSlots[slot] then
					-- Use the existing tool
					dropModel:SetAttribute("SlotIndex", slot)
					dropModel:SetAttribute("CurrentStack", pickupCount)
					dropModel:SetAttribute("IsPickup", false)
					dropModel.Parent = backpack
					
					-- Sync inventory
					InventoryService:SyncInventory(player)
					return
				end
			end
			
			-- No space available
			return
		end
		
		-- If fully stacked, destroy the pickup
		dropModel:Destroy()
		InventoryService:SyncInventory(player)
	else
		-- Not a tool, use the regular AddItem method
		local success = InventoryService:AddItem(player, itemId, pickupCount)
		if success then
			dropModel:Destroy()
		end
	end
end

-- Clear all dropped items (for round reset)
function DropFactory:ClearAllDrops()
	self.DroppedItemsContainer:ClearAllChildren()
end

-- Create singleton instance
local instance = DropFactory.new()

return instance