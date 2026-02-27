--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local InventoryTypes = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("InventoryTypes"))
local InventoryGrid = require(script.Parent:WaitForChild("InventoryGrid"))

type InventoryData = InventoryTypes.InventoryData

export type InventoryAppProps = {
	inventoryData: InventoryData,
	rows: number,
	cols: number,
	gridRef: { current: Frame? }?,
	onDragStart: (index: number) -> (),
	onEquip: (index: number) -> (),
	onMouseEnter: (index: number) -> (),
	onMouseLeave: (index: number) -> (),
}

local function InventoryApp(props: InventoryAppProps)
	return React.createElement("Frame", {
		Name = "InventoryApp",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Grid = React.createElement(InventoryGrid, {
			rows = props.rows,
			cols = props.cols,
			inventoryData = props.inventoryData,
			gridRef = props.gridRef,
			onDragStart = props.onDragStart,
			onEquip = props.onEquip,
			onMouseEnter = props.onMouseEnter,
			onMouseLeave = props.onMouseLeave,
		}),
	})
end

return InventoryApp
