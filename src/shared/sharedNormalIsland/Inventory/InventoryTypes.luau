--!strict
-- InventoryTypes
-- Shared type definitions for the inventory / loadout system.
--
-- ── TWO LAYERS OF TYPES ────────────────────────────────────────────────────────
--
-- PERSISTENCE LAYER  (prefix "Stored" / full PlayerData schema)
--   Used by DataManager and services on the server; sent to the client via
--   InventoryRemotes.SyncFullState as an InventorySyncPayload.
--   Items are serialised to compact tables (SerializedItem) so DataStore
--   writes are small. Template data is NEVER stored; only templateId.
--
-- UI LAYER  (legacy types: ItemStack, InventoryData, EquipmentData, etc.)
--   Consumed by all existing React components (InventoryPanel, EquipmentPanel,
--   HudLoadout, etc.). These stay unchanged so the UI keeps working.
--   The controllers convert server payloads into UI-layer types.
--
-- ─────────────────────────────────────────────────────────────────────────────

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION A  –  UI LAYER  (unchanged; used by React components)
-- ═══════════════════════════════════════════════════════════════════════════════

-- A single item as the UI understands it (rendered in an inventory/equipment slot).
export type ItemStack = {
	itemId: string,
	count: number,
	maxStack: number,
}

-- Inventory grid state consumed by InventoryPanel.
export type InventoryData = {
	slots: { [number]: ItemStack? },
	equippedSlot: number?,
}

-- Equipment panel state keyed by PascalCase slot name.
export type EquipmentSlotId = "Backpack" | "Armor" | "Weapon1" | "Weapon2"
export type EquipmentData = { [EquipmentSlotId]: ItemStack? }

-- Quick-use bar state for the HUD radial / QuickUsePanel.
export type QuickUseData = { slots: { [number]: ItemStack? } }

-- Ability slot within a weapon card.
export type AbilitySlotData = { abilityId: string, isUltimate: boolean }

-- Weapon card data (item + its ability configuration).
export type WeaponData = { itemId: string, abilities: { [number]: AbilitySlotData? } }

-- Full state bundle passed from LoadoutController to LoadoutApp.
export type LoadoutData = {
	inventory: InventoryData,
	equipment: EquipmentData?,
	weapons: { [number]: WeaponData? }?,
	quickUse: QuickUseData?,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION B  –  PERSISTENCE LAYER  (server storage + client sync payload)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── Modifier (compact, for DataStore) ────────────────────────────────────────
export type SerializedMod = {
	mid: string,  -- modifierId (unique within this item instance)
	sid: string,  -- DerivedStatId (e.g. "MaxHP", "CritChance")
	op: string,   -- ModifierOperation: "Flat" | "PercentAdd" | "PercentMult"
	val: number,  -- rolled value
	t: string,    -- ModifierTier: "Minor" | "Standard" | "Major" | "Prime"
}

-- ── Item instance (compact, for DataStore) ────────────────────────────────────
-- Template data is NEVER stored here – only the templateId reference.
-- Fields are omitted when at default values to save bytes.
export type SerializedItem = {
	iid: string,               -- instanceId (globally unique, never reused)
	tid: string,               -- templateId → looked up in ItemRegistry
	cnt: number?,              -- stack count   (nil = 1)
	lvl: number?,              -- upgrade level (nil = 0)
	dur: number?,              -- durability    (nil = indestructible / max)
	mods: { SerializedMod }?,  -- bonus modifiers (nil = no modifiers)
	cdat: { [string]: any }?,  -- custom per-instance data (reserved)
}

-- ── Ability presets ───────────────────────────────────────────────────────────
-- Stored per weapon tag / preset key (e.g. "Greatsword", "Unique_Moonveil").
-- When a weapon is equipped, its abilityPresetKey is used to look up the preset.
export type SerializedPresetSlot = {
	aid: string,   -- abilityId
	ult: boolean?, -- isUltimate (nil = false)
}
export type SerializedPreset = { [number]: SerializedPresetSlot? } -- slots 1–5
export type AbilityPresetsData = { [string]: SerializedPreset }    -- presetKey → preset

-- ── Container identifier ──────────────────────────────────────────────────────
export type ContainerId = "inventory" | "stash" | "equipment" | "quickuse"

-- ── Stored containers ─────────────────────────────────────────────────────────
-- Used inside PlayerData; different from the UI-layer types above.

export type StoredInventoryData = {
	maxSlots: number,
	slots: { [number]: SerializedItem? },
}

-- PascalCase keys match EquipmentSlotId for easy indexing.
export type StoredEquipmentData = {
	Backpack: SerializedItem?,
	Armor: SerializedItem?,
	Weapon1: SerializedItem?,
	Weapon2: SerializedItem?,
}

-- quickUse.slots stores instanceId references (not copies of items).
export type StoredQuickUseData = {
	slots: { [number]: string? }, -- slot index → instanceId (or nil = empty)
	currentSlotIndex: number?,
}

export type StashData = {
	maxSlots: number,
	slots: { [number]: SerializedItem? },
}

-- ── Supporting PlayerData sub-schemas ─────────────────────────────────────────
export type CurrencyData = {
	gold: number,
	premium: number?,
}

export type PlayerSettings = {
	keybinds: { [string]: string }?,
	uiScale: number?,
}

export type CharacterData = {
	level: number,
	experience: number,
	attributePoints: number, -- unspent points available for distribution
	attributes: {
		Vitality: number,
		Intelligence: number,
		Endurance: number,
		Strength: number,
		Dexterity: number,
		Luck: number,
	},
}

-- ── Full player data schema ───────────────────────────────────────────────────
-- Stored as one DataStore key: "PLAYER_{userId}".
-- version is incremented when the schema changes; migrations run on load.
export type PlayerData = {
	version: number,
	lastSaved: number,  -- os.time() of last successful save
	sessionId: string,  -- game.JobId of the server that owns this data (session lock)

	character: CharacterData,
	inventory: StoredInventoryData,
	equipment: StoredEquipmentData,
	quickUse: StoredQuickUseData,
	stash: StashData,
	abilityPresets: AbilityPresetsData,
	currency: CurrencyData,
	settings: PlayerSettings,
}

-- ── Sync payload  (server → client, via SyncFullState remote) ─────────────────
-- Contains only what the client UI needs; omits server-only fields like sessionId.
export type InventorySyncPayload = {
	inventory: StoredInventoryData,
	equipment: StoredEquipmentData,
	quickUse: StoredQuickUseData,
	currency: CurrencyData,
}

return {}
