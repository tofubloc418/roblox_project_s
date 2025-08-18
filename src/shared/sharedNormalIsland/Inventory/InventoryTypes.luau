export type ItemStack = {
	itemId: string,
	count: number,
	maxStack: number,
}

export type InventoryData = {
	slots: { [number]: ItemStack? },
	equippedSlot: number?,
}

return {}
