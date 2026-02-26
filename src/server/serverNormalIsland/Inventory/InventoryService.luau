local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("ItemDefinitions"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

type ItemStack = InventoryTypes.ItemStack
type InventoryData = InventoryTypes.InventoryData

local InventoryService = {}
InventoryService.__index = InventoryService

local INVENTORY_SIZE = 15

-- Remote events
local remotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "InventoryRemotes"
	remotes.Parent = ReplicatedStorage
end

local updateInventory = Instance.new("RemoteEvent")
updateInventory.Name = "UpdateInventory"
updateInventory.Parent = remotes

local requestEquip = Instance.new("RemoteEvent")
requestEquip.Name = "RequestEquip"
requestEquip.Parent = remotes

local requestSwap = Instance.new("RemoteEvent")
requestSwap.Name = "RequestSwap"
requestSwap.Parent = remotes

local requestDrop = Instance.new("RemoteEvent")
requestDrop.Name = "RequestDrop"
requestDrop.Parent = remotes

function InventoryService.new()
	local self = setmetatable({}, InventoryService)
	return self
end

function InventoryService:Initialize()
	Players.PlayerAdded:Connect(function(player)
		self:CreateInventory(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupInventory(player)
	end)
	
	requestEquip.OnServerEvent:Connect(function(player, slotIndex)
		self:EquipSlot(player, slotIndex)
	end)
	
	requestSwap.OnServerEvent:Connect(function(player, fromSlot, toSlot)
		self:SwapSlots(player, fromSlot, toSlot)
	end)
	
	requestDrop.OnServerEvent:Connect(function(player, slotIndex)
		self:DropItem(player, slotIndex)
	end)
end

function InventoryService:CreateInventory(player: Player)
	-- The backpack is automatically created, we just need to sync the initial state
	self:SyncInventory(player)
end

function InventoryService:CleanupInventory(player: Player)
	-- Cleanup happens automatically when player leaves
	-- Just unequip any equipped tool
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
end

function InventoryService:GetInventory(player: Player): InventoryData?
	-- Build inventory data from backpack
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return nil end
	
	local inventory: InventoryData = {
		slots = {},
		equippedSlot = nil,
	}
	
	-- Get tools from backpack and character
	local character = player.Character
	
	-- Check backpack tools
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local slotIndex = tool:GetAttribute("SlotIndex")
			if slotIndex and slotIndex >= 1 and slotIndex <= INVENTORY_SIZE then
				inventory.slots[slotIndex] = {
					itemId = tool:GetAttribute("ItemId") or tool.Name,
					count = tool:GetAttribute("CurrentStack") or 1,
					maxStack = tool:GetAttribute("MaxStack") or 1,
				}
			end
		end
	end
	
	-- Check equipped tool
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				local slotIndex = tool:GetAttribute("SlotIndex")
				if slotIndex and slotIndex >= 1 and slotIndex <= INVENTORY_SIZE then
					inventory.slots[slotIndex] = {
						itemId = tool:GetAttribute("ItemId") or tool.Name,
						count = tool:GetAttribute("CurrentStack") or 1,
						maxStack = tool:GetAttribute("MaxStack") or 1,
					}
					inventory.equippedSlot = slotIndex
				end
			end
		end
	end
	
	return inventory
end

function InventoryService:SyncInventory(player: Player)
	local inventory = self:GetInventory(player)
	if inventory then
		-- Create a clean copy with all slots properly indexed for serialization
		local syncData = {
			slots = {},
			equippedSlot = inventory.equippedSlot
		}
		
		-- Ensure all slots are present in the table (even if nil)
		for i = 1, INVENTORY_SIZE do
			syncData.slots[i] = inventory.slots[i] or false  -- Use false instead of nil for empty slots
		end
		
		updateInventory:FireClient(player, syncData)
	end
end

function InventoryService:AddItem(player: Player, itemId: string, amount: number): boolean
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return false end
	
	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then
		warn(string.format("[InventoryService] Unknown item: %s", itemId))
		return false
	end
	
	local maxStack = itemData.stackMax or 1
	local remaining = amount
	local firstSlotWithItem = nil
	
	-- Get all tools (from backpack and character)
	local allTools = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(allTools, tool)
		end
	end
	local character = player.Character
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				table.insert(allTools, tool)
			end
		end
	end
	
	-- First, try to fill existing stacks
	for _, tool in ipairs(allTools) do
		if remaining <= 0 then break end
		
		if tool:GetAttribute("ItemId") == itemId then
			local currentStack = tool:GetAttribute("CurrentStack") or 1
			local toolMaxStack = tool:GetAttribute("MaxStack") or maxStack
			
			if currentStack < toolMaxStack then
				local space = toolMaxStack - currentStack
				local toAdd = math.min(space, remaining)
				
				tool:SetAttribute("CurrentStack", currentStack + toAdd)
				remaining = remaining - toAdd
				
				if not firstSlotWithItem then
					firstSlotWithItem = tool:GetAttribute("SlotIndex")
				end
			end
		end
	end
	
	-- Then create new tools for remaining items
	if remaining > 0 then
		-- Find empty slots
		local usedSlots = {}
		for _, tool in ipairs(allTools) do
			local slot = tool:GetAttribute("SlotIndex")
			if slot then
				usedSlots[slot] = true
			end
		end
		
		-- Create new tools in empty slots
		for slot = 1, INVENTORY_SIZE do
			if remaining <= 0 then break end
			
			if not usedSlots[slot] then
				local stackCount = math.min(remaining, maxStack)
				
				-- Create the tool
				local tool = self:CreateToolForItem(itemId, stackCount)
				if tool then
					tool:SetAttribute("SlotIndex", slot)
					tool:SetAttribute("ItemId", itemId)
					tool:SetAttribute("CurrentStack", stackCount)
					tool:SetAttribute("MaxStack", maxStack)
					
				tool.Parent = backpack
					remaining = remaining - stackCount
					
					if not firstSlotWithItem then
						firstSlotWithItem = slot
					end
				end
			end
		end
	end
	
	-- Auto-equip if this is the first item and nothing is equipped
	local currentInventory = self:GetInventory(player)
	if firstSlotWithItem and currentInventory and not currentInventory.equippedSlot then
		self:EquipSlot(player, firstSlotWithItem)
	else
		self:SyncInventory(player)
	end
	
	return remaining == 0
end

function InventoryService:EquipSlot(player: Player, slotIndex: number)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not backpack or not humanoid then return end
	
	-- Validate slot
	if slotIndex < 1 or slotIndex > INVENTORY_SIZE then return end
	
	-- Check if this slot is already equipped
	local currentlyEquipped = nil
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("SlotIndex") == slotIndex then
			currentlyEquipped = tool
			break
		end
	end
	
	-- If clicking the already equipped slot, unequip
	if currentlyEquipped then
		humanoid:UnequipTools()
		self:SyncInventory(player)
		return
	end
	
	-- Unequip current tool
	humanoid:UnequipTools()
	
	-- Find and equip the tool in this slot
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("SlotIndex") == slotIndex then
			humanoid:EquipTool(tool)
			break
		end
	end
	
	self:SyncInventory(player)
end

function InventoryService:UnequipCurrent(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
	
	self:SyncInventory(player)
end

function InventoryService:SwapSlots(player: Player, fromSlot: number, toSlot: number)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	if not backpack then return end
	
	-- Validate slots
	if fromSlot < 1 or fromSlot > INVENTORY_SIZE then return end
	if toSlot < 1 or toSlot > INVENTORY_SIZE then return end
	if fromSlot == toSlot then return end
	
	-- Find tools in the slots
	local fromTool = nil
	local toTool = nil
	
	-- Check backpack
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local slot = tool:GetAttribute("SlotIndex")
			if slot == fromSlot then
				fromTool = tool
			elseif slot == toSlot then
				toTool = tool
			end
		end
	end
	
	-- Check character (for equipped tools)
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				local slot = tool:GetAttribute("SlotIndex")
				if slot == fromSlot then
					fromTool = tool
				elseif slot == toSlot then
					toTool = tool
				end
			end
		end
	end
	
	-- Swap the slot indices
	if fromTool then
		fromTool:SetAttribute("SlotIndex", toSlot)
	end
	if toTool then
		toTool:SetAttribute("SlotIndex", fromSlot)
	end
	
	self:SyncInventory(player)
end

function InventoryService:CreateToolForItem(itemId: string, stackCount: number): Tool?
	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then return nil end
	
	-- Try to find prefab
	local lootFolder = ReplicatedStorage:FindFirstChild("Loot")
	if not lootFolder then return nil end
	
	local categoryFolder = lootFolder:FindFirstChild(itemData.category)
	if not categoryFolder then return nil end
	
	local prefab = nil
	for _, descendant in ipairs(categoryFolder:GetDescendants()) do
		if (descendant:IsA("Tool") or descendant:IsA("Model")) and descendant.Name == itemId then
			prefab = descendant
			break
		end
	end
	
	if not prefab then
		-- Create a basic tool
		local tool = Instance.new("Tool")
		tool.Name = itemData.displayName or itemId
		tool.RequiresHandle = true
		
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 2)
		handle.CanCollide = false
		handle.Parent = tool
		
		return tool
	end
	
	local tool: Tool
	if prefab:IsA("Tool") then
		tool = prefab:Clone()
	else
		-- Convert model to tool
		tool = Instance.new("Tool")
		tool.Name = itemData.displayName or itemId
		tool.RequiresHandle = true
		
		local clone = prefab:Clone()
		for _, child in ipairs(clone:GetChildren()) do
			child.Parent = tool
			if child:IsA("BasePart") and child.Name == "Handle" then
				-- Good, already has handle
			elseif child:IsA("BasePart") and not tool:FindFirstChild("Handle") then
				child.Name = "Handle"
			end
		end
		clone:Destroy()
	end
	
	return tool
end

function InventoryService:RemoveItem(player: Player, slotIndex: number)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	if not backpack then return end
	
	-- Find and remove the tool
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("SlotIndex") == slotIndex then
			tool:Destroy()
			self:SyncInventory(player)
			return
		end
	end
	
	-- Check character for equipped tool
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("SlotIndex") == slotIndex then
				tool:Destroy()
				self:SyncInventory(player)
				return
			end
		end
	end
end

function InventoryService:DropItem(player: Player, slotIndex: number)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	if not backpack or not character then return end
	
	-- Validate slot
	if slotIndex < 1 or slotIndex > INVENTORY_SIZE then return end
	
	-- Find the tool to drop
	local toolToDrop = nil
	
	-- Check backpack
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("SlotIndex") == slotIndex then
			toolToDrop = tool
			break
		end
	end
	
	-- Check character for equipped tool
	if not toolToDrop and character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("SlotIndex") == slotIndex then
				-- Unequip first
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:UnequipTools()
				end
				toolToDrop = tool
				break
			end
		end
	end
	
	if not toolToDrop then return end
	
	-- Get drop position
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local dropPosition = hrp.Position + hrp.CFrame.LookVector * 3
	local dropImpulse = hrp.CFrame.LookVector * 10 + Vector3.new(0, 5, 0)
	
	-- Get the DropFactory
	local DropFactory = require(script.Parent.Parent:WaitForChild("LootSystem"):WaitForChild("DropFactory"))
	
	-- Drop the item using the existing tool
	local itemId = toolToDrop:GetAttribute("ItemId") or toolToDrop.Name
	local stackCount = toolToDrop:GetAttribute("CurrentStack") or 1
	
	-- Parent to workspace temporarily to prevent destruction
	toolToDrop.Parent = workspace
	
	-- Spawn the drop using the existing tool
	DropFactory:SpawnDrop(itemId, stackCount, dropPosition, dropImpulse, toolToDrop)
	
	-- Sync inventory
	self:SyncInventory(player)
end

-- Create singleton
local instance = InventoryService.new()
return instance
