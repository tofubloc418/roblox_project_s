export type ItemStack = {
	itemId: string,
	count: number,
	maxStack: number,
}

export type InventoryData = {
	slots: { [number]: ItemStack? },
	equippedSlot: number?,
}

-- Entry-point types for loadout UI (filled when equipment/abilities features land)
export type EquipmentSlotId = "Backpack" | "Shield" | "Weapon1" | "Weapon2"
export type AbilitySlotData = { abilityId: string, isUltimate: boolean }
export type WeaponData = { itemId: string, abilities: { [number]: AbilitySlotData? } }
export type EquipmentData = { [EquipmentSlotId]: ItemStack? }
export type QuickUseData = { slots: { [number]: ItemStack? } }
export type LoadoutData = {
	inventory: InventoryData,
	equipment: EquipmentData?,
	weapons: { [number]: WeaponData? }?,
	quickUse: QuickUseData?,
}

return {}
