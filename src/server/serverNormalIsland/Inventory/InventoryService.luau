local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("ItemDefinitions"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))

type ItemStack = InventoryTypes.ItemStack
type InventoryData = InventoryTypes.InventoryData

local InventoryService = {}
InventoryService.__index = InventoryService

local INVENTORY_SIZE = 15

-- Player inventories
local playerInventories: { [Player]: InventoryData } = {}

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
	

end

function InventoryService:CreateInventory(player: Player)
	local inventory: InventoryData = {
		slots = {},
		equippedSlot = nil,
	}
	
	-- Initialize all slots to ensure proper serialization
	for i = 1, INVENTORY_SIZE do
		inventory.slots[i] = nil
	end
	
	playerInventories[player] = inventory
	self:SyncInventory(player)
end

function InventoryService:CleanupInventory(player: Player)
	-- Unequip any equipped tool
	local inventory = playerInventories[player]
	if inventory and inventory.equippedSlot then
		self:UnequipCurrent(player)
	end
	
	playerInventories[player] = nil
end

function InventoryService:GetInventory(player: Player): InventoryData?
	return playerInventories[player]
end

function InventoryService:SyncInventory(player: Player)
	local inventory = playerInventories[player]
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
	local inventory = playerInventories[player]
	if not inventory then return false end
	
	local itemData = ItemDefinitions.GetItem(itemId)
	if not itemData then
		warn(string.format("[InventoryService] Unknown item: %s", itemId))
		return false
	end
	
	local maxStack = itemData.stackMax or 1
	local remaining = amount
	local firstSlotWithItem = nil
	
	-- First, try to fill existing stacks
	for slot = 1, INVENTORY_SIZE do
		if remaining <= 0 then break end
		
		local stack = inventory.slots[slot]
		if stack and stack.itemId == itemId and stack.count < maxStack then
			local space = maxStack - stack.count
			local toAdd = math.min(space, remaining)
			
			stack.count = stack.count + toAdd
			remaining = remaining - toAdd
			
			if not firstSlotWithItem then
				firstSlotWithItem = slot
			end
		end
	end
	
	-- Then create new stacks
	for slot = 1, INVENTORY_SIZE do
		if remaining <= 0 then break end
		
		if not inventory.slots[slot] then
			local stackCount = math.min(remaining, maxStack)
			
			inventory.slots[slot] = {
				itemId = itemId,
				count = stackCount,
				maxStack = maxStack,
			}
			
			remaining = remaining - stackCount
			
			if not firstSlotWithItem then
				firstSlotWithItem = slot
			end
		end
	end
	
	-- Auto-equip if this is the first item and nothing is equipped
	if firstSlotWithItem and not inventory.equippedSlot then
		self:EquipSlot(player, firstSlotWithItem)
	else
		self:SyncInventory(player)
	end
	
	return remaining == 0
end

function InventoryService:EquipSlot(player: Player, slotIndex: number)
	local inventory = playerInventories[player]
	if not inventory then return end
	
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Validate slot
	if slotIndex < 1 or slotIndex > INVENTORY_SIZE then return end
	
	-- If clicking the already equipped slot, unequip
	if inventory.equippedSlot == slotIndex then
		self:UnequipCurrent(player)
		return
	end
	
	-- Unequip current
	self:UnequipCurrent(player)
	
	-- Equip new slot if it has an item
	local stack = inventory.slots[slotIndex]
	if stack then
		local tool = self:CreateToolFromStack(stack)
		if tool then
			tool.Parent = character
			humanoid:EquipTool(tool)
			inventory.equippedSlot = slotIndex
			

		end
	end
	
	self:SyncInventory(player)
end

function InventoryService:UnequipCurrent(player: Player)
	local inventory = playerInventories[player]
	if not inventory or not inventory.equippedSlot then return end
	
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
	
	-- Remove any tools from character
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end
	

	
	inventory.equippedSlot = nil
	self:SyncInventory(player)
end

function InventoryService:SwapSlots(player: Player, fromSlot: number, toSlot: number)
	local inventory = playerInventories[player]
	if not inventory then return end
	
	-- Validate slots
	if fromSlot < 1 or fromSlot > INVENTORY_SIZE then return end
	if toSlot < 1 or toSlot > INVENTORY_SIZE then return end
	if fromSlot == toSlot then return end
	

	
	-- Swap the slots
	local temp = inventory.slots[fromSlot]
	inventory.slots[fromSlot] = inventory.slots[toSlot]
	inventory.slots[toSlot] = temp
	

	
	-- Update equipped slot if needed
	if inventory.equippedSlot == fromSlot then
		inventory.equippedSlot = toSlot
	elseif inventory.equippedSlot == toSlot then
		inventory.equippedSlot = fromSlot
	end
	
	self:SyncInventory(player)
end

function InventoryService:CreateToolFromStack(stack: ItemStack): Tool?
	local itemData = ItemDefinitions.GetItem(stack.itemId)
	if not itemData then return nil end
	
	-- Try to find prefab
	local lootFolder = ReplicatedStorage:FindFirstChild("Loot")
	if not lootFolder then return nil end
	
	local categoryFolder = lootFolder:FindFirstChild(itemData.category)
	if not categoryFolder then return nil end
	
	local prefab = nil
	for _, descendant in ipairs(categoryFolder:GetDescendants()) do
		if (descendant:IsA("Tool") or descendant:IsA("Model")) and descendant.Name == stack.itemId then
			prefab = descendant
			break
		end
	end
	
	if not prefab then
		-- Create a basic tool
		local tool = Instance.new("Tool")
		tool.Name = itemData.displayName or stack.itemId
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
		tool.Name = itemData.displayName or stack.itemId
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
	
	-- Set stack info (for display purposes only)
	tool:SetAttribute("StackCount", stack.count)
	tool:SetAttribute("StackMax", stack.maxStack)
	
	return tool
end

-- Create singleton
local instance = InventoryService.new()
return instance
