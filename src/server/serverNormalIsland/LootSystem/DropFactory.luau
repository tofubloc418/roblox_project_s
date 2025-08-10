--[[
	DropFactory
	Creates physical pickup instances for dropped items
]]

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Shared modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("sharedNormalIsland"):WaitForChild("LootSystem")
local ItemDefinitions = require(SharedModules:WaitForChild("ItemDefinitions"))
local LootConfig = require(SharedModules:WaitForChild("LootConfig"))

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
	
	return self
end

-- Spawn a dropped item
function DropFactory:SpawnDrop(itemId: string, stackCount: number, position: Vector3, impulse: Vector3?)
	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then
		warn("Invalid item ID for drop:", itemId)
		return nil
	end
	
	-- Try to find item prefab (stub for now)
	local prefab = self:GetItemPrefab(itemId)
	local dropModel
	
	if prefab then
		-- Clone the prefab
		dropModel = prefab:Clone()
	else
		-- Create placeholder part
		dropModel = self:CreatePlaceholderDrop(itemId, stackCount)
		
		if LootConfig.DEBUG_MODE then
			warn(string.format("No prefab found for item '%s', using placeholder", itemId))
		end
	end
	
	-- Set position
	if dropModel:IsA("Model") then
		dropModel:PivotTo(CFrame.new(position + Vector3.new(0, 1, 0)))
	else
		dropModel.Position = position + Vector3.new(0, 1, 0)
	end
	
	-- Set attributes for pickup system
	dropModel:SetAttribute("ItemId", itemId)
	dropModel:SetAttribute("StackCount", stackCount)
	dropModel:SetAttribute("IsPickup", true)
	
	-- Apply physics impulse if specified
	if impulse then
		self:ApplyImpulse(dropModel, impulse)
	end
	
	-- Parent to world
	dropModel.Parent = self.DroppedItemsContainer
	
	-- Add pickup interaction (stub)
	self:SetupPickupInteraction(dropModel)
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Spawned drop: %s x%d at %s", itemId, stackCount, tostring(position)))
	end
	
	return dropModel
end

-- Get item prefab (stub - will be implemented when prefabs exist)
function DropFactory:GetItemPrefab(itemId: string)
	-- TODO: Look for prefab in ReplicatedStorage.Prefabs.Items[itemId]
	-- For now, return nil to use placeholder
	return nil
end

-- Create a placeholder drop part
function DropFactory:CreatePlaceholderDrop(itemId: string, stackCount: number)
	local itemData = ItemDefinitions.GetItem(itemId)
	
	local part = Instance.new("Part")
	part.Name = string.format("Pickup_%s_%d", itemId, stackCount)
	part.Size = Vector3.new(2, 2, 2)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = true
	part.Anchored = false
	
	-- Color based on rarity
	local rarityColors = {
		[ItemDefinitions.Rarities.COMMON] = Color3.fromRGB(128, 128, 128),
		[ItemDefinitions.Rarities.UNCOMMON] = Color3.fromRGB(0, 255, 0),
		[ItemDefinitions.Rarities.RARE] = Color3.fromRGB(0, 128, 255),
		[ItemDefinitions.Rarities.EPIC] = Color3.fromRGB(176, 0, 255),
		[ItemDefinitions.Rarities.LEGENDARY] = Color3.fromRGB(255, 176, 0),
	}
	
	part.Color = rarityColors[itemData.rarity] or Color3.fromRGB(255, 255, 255)
	
	-- Add a billboard GUI to show item info
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(4, 0, 2, 0)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = string.format("%s\nx%d", itemData.displayName, stackCount)
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = billboardGui
	
	billboardGui.Parent = part
	
	-- Add a selection box for visibility
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = part
	selectionBox.Color3 = part.Color
	selectionBox.LineThickness = 0.1
	selectionBox.Transparency = 0.5
	selectionBox.Parent = part
	
	return part
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

-- Setup pickup interaction (stub)
function DropFactory:SetupPickupInteraction(dropModel: Instance)
	-- TODO: Add ProximityPrompt or ClickDetector for pickup
	-- TODO: Connect to inventory system
	
	if LootConfig.DEBUG_MODE then
		-- Add a simple click detector for testing
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 10
		
		clickDetector.MouseClick:Connect(function(player)
			local itemId = dropModel:GetAttribute("ItemId")
			local stackCount = dropModel:GetAttribute("StackCount")
			
			print(string.format("Player %s picked up %s x%d", 
				player.Name, itemId or "unknown", stackCount or 1))
			
			-- Remove the drop (in real implementation, add to inventory first)
			dropModel:Destroy()
		end)
		
		if dropModel:IsA("Model") then
			clickDetector.Parent = dropModel.PrimaryPart or dropModel:FindFirstChildWhichIsA("BasePart")
		else
			clickDetector.Parent = dropModel
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
