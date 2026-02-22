local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("LootSystem"):WaitForChild("ItemDefinitions"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
type ItemStack = InventoryTypes.ItemStack

local InventoryUI = {}

function InventoryUI.createScreens()
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local screen = Instance.new("ScreenGui")
	screen.Name = "InventoryScreen"
	screen.ResetOnSpawn = false
	screen.Enabled = false
	screen.Parent = playerGui
	
	local hotbar = Instance.new("ScreenGui")
	hotbar.Name = "Hotbar"
	hotbar.ResetOnSpawn = false
	hotbar.Enabled = true
	hotbar.Parent = playerGui
	
	return screen, hotbar
end

function InventoryUI.buildInventoryGrid(screen: ScreenGui, rows: number, cols: number)
	local frame = Instance.new("Frame")
	frame.Name = "Grid"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(cols * 80 + (cols-1)*8 + 16, rows * 80 + (rows-1)*8 + 16)
	frame.BackgroundTransparency = 0.2
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.Parent = screen
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = frame
	
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(80, 80)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = frame
	
	return frame
end

function InventoryUI.createSlot(parent: Instance, index: number)
	local button = Instance.new("ImageButton")
	button.Name = "Slot_" .. tostring(index)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.AutoButtonColor = false
	button.Image = ""
	button.LayoutOrder = index
	button.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 0.25)
	label.Position = UDim2.fromScale(0, 0.75)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1,1,1)
	label.Text = ""
	label.Parent = button
	
	local stackLabel = Instance.new("TextLabel")
	stackLabel.Name = "Stack"
	stackLabel.Size = UDim2.fromScale(0.4, 0.25)
	stackLabel.Position = UDim2.fromScale(0.6, 0)
	stackLabel.BackgroundTransparency = 1
	stackLabel.TextScaled = true
	stackLabel.TextColor3 = Color3.new(1,1,1)
	stackLabel.TextXAlignment = Enum.TextXAlignment.Right
	stackLabel.Text = ""
	stackLabel.Parent = button
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(120, 120, 120)
	stroke.Parent = button
	
	return button
end

function InventoryUI.buildHotbar(hotbar: ScreenGui, cols: number)
	local frame = Instance.new("Frame")
	frame.Name = "HotbarFrame"
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.fromScale(0.98, 0.98)
	frame.Size = UDim2.fromOffset(cols * 64 + (cols-1)*6 + 12, 64 + 12)
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.Parent = hotbar
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = frame
	
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(64, 64)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = frame
	
	return frame
end

function InventoryUI.renderSlot(slotButton: ImageButton, stack: ItemStack?, active: boolean)
	local label = slotButton:FindFirstChild("Label") :: TextLabel
	local stackLabel = slotButton:FindFirstChild("Stack") :: TextLabel
	local stroke = slotButton:FindFirstChildOfClass("UIStroke")
	
	-- Always clear first to ensure clean state
	slotButton.Image = ""
	slotButton.ImageTransparency = 1
	label.Text = ""
	stackLabel.Text = ""
	
	if stack then
		local itemData = ItemDefinitions.GetItem(stack.itemId)
		local displayName = (itemData and itemData.displayName) or stack.itemId
		

		
		-- Try to find an icon
		local iconFound = false
		if itemData then
			-- Look for icon in prefab
			local lootFolder = ReplicatedStorage:FindFirstChild("Loot")
			if lootFolder then
				local categoryFolder = lootFolder:FindFirstChild(itemData.category)

				if categoryFolder then
					for _, descendant in ipairs(categoryFolder:GetDescendants()) do
						if descendant.Name == stack.itemId then
							local iconImage = descendant:FindFirstChild("IconImage")
							if iconImage then
								local imageId: string? = nil
								if iconImage:IsA("StringValue") then
									imageId = iconImage.Value
								elseif iconImage:IsA("IntValue") or iconImage:IsA("NumberValue") then
									imageId = "rbxassetid://" .. tostring(iconImage.Value)
								elseif iconImage:IsA("ImageLabel") then
									imageId = iconImage.Image
								elseif iconImage:IsA("Decal") then
									imageId = iconImage.Texture
								end
								
								if imageId and imageId ~= "" then
									if string.match(imageId, "^%d+$") then
										imageId = "rbxassetid://" .. imageId
									end
									slotButton.Image = imageId
									slotButton.ImageTransparency = 0
									iconFound = true
								end
							end
							break
						end
					end
				end
			end
		end
		
		if not iconFound then
			label.Text = displayName
		end
		
		-- Show stack count
		if stack.maxStack > 1 then
			stackLabel.Text = string.format("%d/%d", stack.count, stack.maxStack)
		end
	end
	
	-- Update highlight
	if stroke then
		stroke.Thickness = active and 2 or 1
		stroke.Color = active and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(120, 120, 120)
	end
end

return InventoryUI
