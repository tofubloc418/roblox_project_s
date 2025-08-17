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
local LootConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("LootConfig"))

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
	return self
end

-- Spawn a dropped item
function DropFactory:SpawnDrop(itemId: string, stackCount: number, position: Vector3, impulse: Vector3?)
	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then
		warn("Invalid item ID for drop:", itemId)
		return nil
	end
	
	local prefab = self:GetItemPrefab(itemId)
	local dropModel: Instance
	if prefab then
		dropModel = prefab:Clone()
	else
		dropModel = self:CreatePlaceholderDrop(itemId, stackCount)
		if LootConfig.DEBUG_MODE then
			warn(string.format("No prefab found for item '%s', using placeholder", itemId))
		end
	end

	if dropModel:IsA("Model") then
		dropModel:PivotTo(CFrame.new(position + Vector3.new(0, 1, 0)))
	elseif dropModel:IsA("BasePart") then
		dropModel.Position = position + Vector3.new(0, 1, 0)
	elseif dropModel:IsA("Tool") then
		local handle = (dropModel:FindFirstChild("Handle") :: any)
		if handle and handle:IsA("BasePart") then
			handle.CFrame = CFrame.new(position + Vector3.new(0, 1, 0))
		end
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
	
	-- Add pickup interaction only for non-Tool placeholders/models
	if not dropModel:IsA("Tool") then
		self:SetupPickupInteraction(dropModel)
	end
	
	if LootConfig.DEBUG_MODE then
		print(string.format("Spawned drop: %s x%d at %s", itemId, stackCount, tostring(position)))
	end
	
	return dropModel
end

-- Get item prefab (stub - will be implemented when prefabs exist)
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
	-- Auto-pickup when a player walks very close to the drop
	local primaryPart
	if dropModel:IsA("Model") then
		primaryPart = dropModel.PrimaryPart or dropModel:FindFirstChildWhichIsA("BasePart")
	elseif dropModel:IsA("BasePart") then
		primaryPart = dropModel
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

-- Minimal inventory pickup
function DropFactory:Pickup(dropModel: Instance, player: Player)
	local itemId = dropModel:GetAttribute("ItemId") or "unknown"
	local itemData = ItemDefinitions.GetItem(itemId)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		backpack = Instance.new("Backpack")
		backpack.Parent = player
	end

	local tool: Tool
	local prefab = self:GetItemPrefab(itemId)
	if prefab then
		tool = Instance.new("Tool")
		tool.Name = (itemData and itemData.displayName) or tostring(itemId)
		tool:SetAttribute("ItemId", itemId)
		tool.RequiresHandle = true

		-- Flatten prefab into tool and set a Handle
		local clone = prefab:Clone()
		local handlePart: BasePart? = nil
		local baseParts = {}
		for _, inst in ipairs(clone:GetDescendants()) do
			if inst:IsA("BasePart") then
				table.insert(baseParts, inst)
			end
		end
		if #baseParts > 0 then
			-- Choose first part as handle
			handlePart = baseParts[1]
			if handlePart then
				handlePart.Name = "Handle"
			end
			for _, part in ipairs(baseParts) do
				part.Anchored = false
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.Massless = true
				part.Parent = tool
				if part ~= handlePart then
					if handlePart then
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = handlePart
						weld.Part1 = part
						weld.Parent = handlePart
					end
				end
			end
		else
			-- No parts in prefab, fallback to placeholder handle
			local ph = Instance.new("Part")
			ph.Name = "Handle"
			ph.Size = Vector3.new(1.2, 1.2, 2)
			ph.CanCollide = false
			ph.CanQuery = false
			ph.CanTouch = false
			ph.Massless = true
			ph.Parent = tool
		end
		clone:Destroy()
		tool.Parent = backpack
	else
		-- No prefab found, create a simple placeholder tool
		tool = Instance.new("Tool")
		tool.Name = (itemData and itemData.displayName) or tostring(itemId)
		tool:SetAttribute("ItemId", itemId)
		tool.RequiresHandle = true
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1.2, 1.2, 2)
		handle.CanCollide = false
		handle.CanQuery = false
		handle.CanTouch = false
		handle.Massless = true
		local rarity = itemData and itemData.rarity
		local rarityColors = {
			[ItemDefinitions.Rarities.COMMON] = Color3.fromRGB(128, 128, 128),
			[ItemDefinitions.Rarities.UNCOMMON] = Color3.fromRGB(0, 255, 0),
			[ItemDefinitions.Rarities.RARE] = Color3.fromRGB(0, 128, 255),
			[ItemDefinitions.Rarities.EPIC] = Color3.fromRGB(176, 0, 255),
			[ItemDefinitions.Rarities.LEGENDARY] = Color3.fromRGB(255, 176, 0),
		}
		handle.Color = (rarity and rarityColors[rarity]) or Color3.fromRGB(200, 200, 200)
		handle.Parent = tool
		tool.Parent = backpack
	end

	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end

	if LootConfig.DEBUG_MODE then
		print(string.format("Gave %s a tool for item '%s'", player.Name, tostring(itemId)))
	end

	dropModel:Destroy()
end

-- Clear all dropped items (for round reset)
function DropFactory:ClearAllDrops()
	self.DroppedItemsContainer:ClearAllChildren()
end

-- Create singleton instance
local instance = DropFactory.new()

return instance
