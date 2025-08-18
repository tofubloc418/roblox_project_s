--[[
	DropFactory
	Creates physical pickup instances for dropped items
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Shared modules
local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("ItemDefinitions"))

local DropFactory = {}
DropFactory.__index = DropFactory

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

-- Spawn a dropped item
function DropFactory:SpawnDrop(itemId: string, stackCount: number, position: Vector3, impulse: Vector3?)
	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then
		warn("Invalid item ID for drop:", itemId)
		return nil
	end
	
	local prefab = self:GetItemPrefab(itemId)
	if not prefab then
		warn(string.format("No prefab found for item '%s'; skipping spawn", tostring(itemId)))
		return nil
	end
	
	local dropModel: Instance
	
	-- For Tools, clone directly (no wrapper needed for gun system)
	if prefab:IsA("Tool") then
		dropModel = prefab:Clone()
		-- Clear any attributes from the prefab
		dropModel:SetAttribute("StackCount", nil)
		dropModel:SetAttribute("StackMax", nil)
		dropModel:SetAttribute("ItemId", nil)
	else
		-- Wrap non-Tool items in a Model to prevent auto-pickup
		local itemClone = prefab:Clone()
		local wrapper = Instance.new("Model")
		wrapper.Name = itemClone.Name .. "_Pickup"
		
		-- Parent item to wrapper
		itemClone.Parent = wrapper
		
		-- Set wrapper's PrimaryPart for positioning
		if itemClone:IsA("BasePart") then
			wrapper.PrimaryPart = itemClone
		else
			local primaryPart = itemClone:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				wrapper.PrimaryPart = primaryPart
			end
		end
		
		dropModel = wrapper
	end

	-- Position the drop
	if dropModel:IsA("Model") then
		dropModel:PivotTo(CFrame.new(position + Vector3.new(0, 1, 0)))
	elseif dropModel:IsA("BasePart") then
		dropModel.Position = position + Vector3.new(0, 1, 0)
	end
	
	-- Set attributes on the wrapper/model
	dropModel:SetAttribute("ItemId", itemId)
	dropModel:SetAttribute("StackCount", stackCount)
	dropModel:SetAttribute("StackMax", (itemData and itemData.stackMax) or 1)
	dropModel:SetAttribute("IsPickup", true)
	
	if impulse then
		self:ApplyImpulse(dropModel, impulse)
	end
	
	dropModel.Parent = self.DroppedItemsContainer
	
	-- Setup pickup for all drops (Tools are now wrapped in Models)
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

	local found
	for _, descendant in ipairs(categoryFolder:GetDescendants()) do
		if (descendant:IsA("Model") or descendant:IsA("Tool")) and descendant.Name == itemId then
			found = descendant
			break
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
	-- Auto-pickup when a player walks very close to the drop
	local primaryPart
	if dropModel:IsA("Model") then
		primaryPart = dropModel.PrimaryPart or dropModel:FindFirstChildWhichIsA("BasePart")
	elseif dropModel:IsA("BasePart") then
		primaryPart = dropModel
	elseif dropModel:IsA("Tool") then
		-- For Tools, use the Handle as the primary part
		primaryPart = dropModel:FindFirstChild("Handle")
	end
	if not primaryPart then
		return
	end

	-- Ensure touch events are permitted
	primaryPart.CanTouch = true

	-- Helper to resolve a player from a touched part
	local function getPlayerFromHit(hit: BasePart): Player?
		local model = hit:FindFirstAncestorOfClass("Model")
		if model then
			return Players:GetPlayerFromCharacter(model)
		end
		return nil
	end

	-- Fast path: pick up on physical contact
	primaryPart.Touched:Connect(function(hit)
		if dropModel.Parent and not dropModel:GetAttribute("PickedUp") then
			local player = getPlayerFromHit(hit)
			if player then
				dropModel:SetAttribute("PickedUp", true)
				self:Pickup(dropModel, player)
			end
		end
	end)

	-- Poll nearby players and auto-pickup when within small radius
	task.spawn(function()
		local pickupRadius = 3.0 -- very close, practically on top
		while dropModel.Parent do
			task.wait(0.1)
			if dropModel:GetAttribute("PickedUp") then
				break
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local hrp = char and (char:FindFirstChild("HumanoidRootPart") :: any) or (char and char.PrimaryPart)
				if hrp and (hrp.Position - primaryPart.Position).Magnitude <= pickupRadius then
					if not dropModel:GetAttribute("PickedUp") then
						dropModel:SetAttribute("PickedUp", true)
						self:Pickup(dropModel, player)
					end
					return
				end
			end
		end
	end)
end

-- Simplified inventory pickup
function DropFactory:Pickup(dropModel: Instance, player: Player)
	local itemId = dropModel:GetAttribute("ItemId") or "unknown"
	local pickupCount = dropModel:GetAttribute("StackCount") or 1
	

	
	-- Use the new inventory service
	local InventoryService = self.InventoryService
	if InventoryService then
		local success = InventoryService:AddItem(player, itemId, pickupCount)
		if not success then

		end
	else

	end
	
	-- Destroy the pickup
	dropModel:Destroy()
end

-- Clear all dropped items (for round reset)
function DropFactory:ClearAllDrops()
	self.DroppedItemsContainer:ClearAllChildren()
end

-- Create singleton instance
local instance = DropFactory.new()

return instance