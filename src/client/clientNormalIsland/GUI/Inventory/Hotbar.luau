--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local InventorySlot = require(script.Parent:WaitForChild("InventorySlot"))

type ItemStack = InventoryTypes.ItemStack
type InventoryData = InventoryTypes.InventoryData

export type HotbarProps = {
	cols: number,
	inventoryData: InventoryData,
	onEquip: (index: number) -> (),
}

local function Hotbar(props: HotbarProps)
	local cols = props.cols
	local inventoryData = props.inventoryData

	local width = cols * 64 + (cols - 1) * 6 + 12
	local height = 64 + 12

	local children: { [string | number]: React.Element } = {
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}),
		GridLayout = React.createElement("UIGridLayout", {
			CellSize = UDim2.fromOffset(64, 64),
			CellPadding = UDim2.fromOffset(6, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i = 1, cols do
		local stack = inventoryData.slots[i]
		if stack == false then
			stack = nil
		end
		local isActive = inventoryData.equippedSlot == i
		children["Slot" .. i] = React.createElement(InventorySlot, {
			index = i,
			stack = stack,
			active = isActive,
			onDragStart = function() end,
			onEquip = function()
				props.onEquip(i)
			end,
		})
	end

	return React.createElement("Frame", {
		Name = "HotbarFrame",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.98, 0.98),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.3,
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
	}, children)
end

return Hotbar
