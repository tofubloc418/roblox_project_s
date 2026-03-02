# Data Persistence & Storage

This document specifies how player data is stored, serialized, and loaded. Since items are persistent across playthroughs, the system must reliably record every item instance — including its level, modifiers, abilities, and slot assignments — and restore it exactly on rejoin.

---

## I. Design Principles

1. **DataStore as single source of truth.** The server holds authoritative state. Clients never write to DataStore directly.
2. **Compact serialization.** DataStore has a 4MB limit per key. Item data uses short field names and avoids redundancy (template data is never stored — only the `templateId` reference).
3. **Atomic saves.** Player data is saved as a single DataStore key per player. All sub-systems (inventory, equipment, stash, stats) are nested fields in one table.
4. **Session locking.** To prevent duplication exploits, the system uses session locking: only one server can own a player's data at a time.
5. **Auto-save with dirty tracking.** Data is saved periodically (every 60s) and on player leave, but only if the data has changed since the last save.

---

## II. Player Data Schema

All persistent data for a player is stored under a single DataStore key: `"player_{userId}"`.

```
PlayerData {
    version       : number           -- Schema version for migrations
    lastSaved     : number           -- os.time() of last save
    sessionId     : string           -- Lock: server JobId that owns this data

    -- Character progression
    character     : CharacterData

    -- Inventory & equipment (current session / field loadout)
    inventory     : InventoryData
    equipment     : EquipmentData
    quickUse      : QuickUseData

    -- Village stash (persistent safe storage)
    stash         : StashData

    -- Ability loadouts (per weapon class)
    abilityPresets : AbilityPresetsData

    -- Currency
    currency      : CurrencyData

    -- Settings & misc
    settings      : PlayerSettings
}
```

### CharacterData

```
CharacterData {
    level            : number
    experience       : number
    attributePoints  : number           -- Unspent points
    attributes       : CoreAttributes   -- { Vitality, Intelligence, Endurance, Strength, Dexterity, Luck }
}
```

### InventoryData (field inventory)

The in-session inventory that the player carries while exploring. Fixed size (16 slots by default; upgradeable via Backpack item).

```
InventoryData {
    maxSlots  : number                       -- Default 16, increased by Backpack
    slots     : { [number]: SerializedItem? } -- Sparse: slot 1–maxSlots, nil = empty
}
```

### EquipmentData

Currently equipped items. Each slot holds a serialized item or nil.

```
EquipmentData {
    backpack   : SerializedItem?
    armor      : SerializedItem?
    weapon1    : SerializedItem?
    weapon2    : SerializedItem?
}
```

### QuickUseData

Items assigned to the quick-use bar. These are **references** to items in the inventory (by `instanceId`), not copies. When serialized, they store the `instanceId` so the system can re-link on load.

```
QuickUseData {
    slots              : { [number]: string? }  -- slot 1–8, value = instanceId or nil
    currentSlotIndex   : number?                -- Which quick slot is "active" for Q tap
}
```

### StashData (village storage)

Safe storage accessible only in safezone villages. Much larger capacity than field inventory.

```
StashData {
    maxSlots  : number                        -- Default 100, upgradeable
    slots     : { [number]: SerializedItem? } -- Sparse
}
```

### CurrencyData

```
CurrencyData {
    gold      : number    -- Primary currency
    premium   : number?   -- Optional premium currency (if applicable)
}
```

### AbilityPresetsData

Stores the player's ability loadout per weapon class. When a weapon is equipped, its `abilityPresetKey` (from `WeaponTemplate`) is used to look up the preset. See [ability-system.md](./ability-system.md#viii-ability-preset-persistence) for full design.

```
AbilityPresetsData {
    [presetKey: string]: SerializedPreset    -- e.g. "Greatsword", "Dagger", "Unique_Moonveil"
}

SerializedPreset {
    [slotIndex: number]: SerializedPresetSlot?   -- slots 1–5, nil = empty
}

SerializedPresetSlot {
    aid  : string      -- abilityId
    ult  : boolean?    -- isUltimate (omitted if false)
}
```

Example:

```lua
abilityPresets = {
    ["Greatsword"] = {
        [1] = { aid = "HeavySlash" },
        [2] = { aid = "WarCry" },
        [3] = { aid = "Whirlwind", ult = true },
        [4] = { aid = "UniversalParry" },
    },
    ["Unique_Moonveil"] = {
        [1] = { aid = "MoonveilBeam", ult = true },
        [2] = { aid = "QuickStep" },
        [3] = { aid = "UniversalParry" },
    },
}
```

Each preset is ~50–150 bytes. With ~20 weapon classes + a handful of unique weapons ≈ 25 presets max → ~3 KB total.

### PlayerSettings

```
PlayerSettings {
    keybinds        : { [string]: string }?   -- Custom keybind overrides
    uiScale         : number?
    -- Extend as needed
}
```

---

## III. Serialized Item Format

Every item instance is serialized to a compact table for storage. **Template data is never stored** — only the `templateId`, which is used to look up the immutable template on load.

### Full Format

```
SerializedItem {
    iid   : string              -- instanceId (unique)
    tid   : string              -- templateId (references ItemRegistry)
    cnt   : number?             -- count (omitted if 1, i.e. non-stackable)
    lvl   : number?             -- level (omitted if 0)
    dur   : number?             -- durability (omitted if nil/max)
    mods  : {SerializedMod}?    -- modifiers (omitted if empty)
    cdat  : {[string]: any}?    -- customData (omitted if empty)
}
```

**Note:** Abilities are NOT stored per-item. They are stored as per-class presets in `abilityPresets` (see section II above). This avoids redundancy: if a player has 5 Greatswords, they share one ability preset.

### SerializedMod (compact modifier)

```
SerializedMod {
    mid : string               -- modifierId
    sid : string               -- statId (DerivedStatId)
    op  : string               -- operation ("Flat" | "PercentAdd" | "PercentMult")
    val : number               -- value
    t   : string               -- tier ("Minor" | "Standard" | "Major" | "Prime")
}
```

### Example: Serialized Legendary Greatsword

```lua
{
    iid  = "IronGreatsword_1709337600_a3f2",
    tid  = "IronGreatsword",
    lvl  = 7,
    mods = {
        { mid = "mod_1", sid = "CritChance",   op = "Flat", val = 0.06, t = "Major" },
        { mid = "mod_2", sid = "MaxHP",        op = "Flat", val = 35,   t = "Standard" },
        { mid = "mod_3", sid = "Armor",        op = "Flat", val = 12,   t = "Minor" },
    },
    -- Abilities are NOT stored here. They come from abilityPresets["Greatsword"].
}
```

### Example: Serialized Bandage Stack

```lua
{
    iid = "Bandage_1709338000_b1c4",
    tid = "Bandage",
    cnt = 10,
}
```

### Size Estimates

| Item Type | Estimated Bytes (JSON) |
|-----------|----------------------|
| Simple stackable (no mods) | ~60 bytes |
| Armor with 2 modifiers | ~200 bytes |
| Weapon with 4 mods | ~300 bytes |

Items: 16 inventory slots + 4 equipment slots + 100 stash slots ≈ 120 items max:
- Worst case (all weapons with max mods): 126 × 300 = ~37 KB
- Typical case: ~15–25 KB

Ability presets: ~25 presets × ~120 bytes = ~3 KB

Total typical case: ~20–30 KB — well within DataStore's 4 MB limit.

---

## IV. DataStore Architecture

### Key Structure

| DataStore Name | Key Pattern | Contents |
|---------------|-------------|----------|
| `PlayerData_v1` | `"player_{userId}"` | Full `PlayerData` table |

One DataStore, one key per player. The `_v1` suffix is the store version; if a breaking migration is needed, a new store name is created and old data is migrated on first load.

### Session Locking

To prevent item duplication from multi-server exploits:

1. On `PlayerAdded`, the server reads the player's DataStore key.
2. If `sessionId` is set and does not match the current server's `game.JobId`, the data is stale from a crashed server. The system waits up to 30 seconds, re-reading periodically, before force-claiming.
3. On successful claim, `sessionId` is set to the current `game.JobId` and the data is saved immediately.
4. On `PlayerRemoving`, `sessionId` is cleared and a final save is performed.
5. On `BindToClose`, all active player data is saved with `sessionId` cleared.

### Save Pipeline

```
1. Player action mutates in-memory data
2. DataManager marks data as dirty
3. Auto-save loop (every 60s) checks dirty flag
4. If dirty: serialize → UpdateAsync → clear dirty flag
5. On PlayerRemoving: immediate save (if dirty)
6. On BindToClose: save all remaining players
```

### Load Pipeline

```
1. PlayerAdded fires
2. DataManager:LoadPlayerData(player) called
3. Read DataStore key with GetAsync
4. If nil: create default PlayerData (new player)
5. Run migration if data.version < CURRENT_VERSION
6. Claim session lock (set sessionId = game.JobId)
7. Hydrate in-memory data structures
8. Sync initial state to client
```

---

## V. Server-Side Data Manager

The `DataManager` module is the sole gateway to DataStore operations. No other module reads or writes DataStore directly.

### API Surface

```
DataManager.LoadPlayerData(player: Player) -> PlayerData
DataManager.SavePlayerData(player: Player) -> boolean
DataManager.GetPlayerData(player: Player) -> PlayerData?   -- In-memory only, no DataStore call
DataManager.MarkDirty(player: Player)                       -- Flags data for next save cycle
DataManager.SaveAll()                                       -- Called by BindToClose
```

### In-Memory Cache

Once loaded, `PlayerData` lives in a server-side dictionary: `_cache[player.UserId] = playerData`. All gameplay systems read/write this cache. The cache is authoritative during the session; DataStore is only touched on save/load.

---

## VI. Inventory Service (New)

The new `InventoryService` operates on `PlayerData` tables, not Roblox Tool instances.

### API Surface

```
InventoryService:Initialize()
InventoryService:GetInventory(player) -> InventoryData
InventoryService:GetEquipment(player) -> EquipmentData
InventoryService:GetQuickUse(player) -> QuickUseData

-- Item operations
InventoryService:AddItem(player, templateId, count?, modifiers?) -> ItemInstance?
InventoryService:RemoveItem(player, instanceId) -> boolean
InventoryService:MoveItem(player, fromContainer, fromSlot, toContainer, toSlot) -> boolean
InventoryService:SwapItems(player, containerA, slotA, containerB, slotB) -> boolean

-- Equipment operations
InventoryService:EquipItem(player, instanceId, slot: EquipmentSlotId) -> boolean
InventoryService:UnequipItem(player, slot: EquipmentSlotId) -> boolean

-- Quick-use operations
InventoryService:AssignQuickUse(player, instanceId, quickSlot: number) -> boolean
InventoryService:ClearQuickUse(player, quickSlot: number) -> boolean
InventoryService:UseQuickItem(player, quickSlot: number) -> boolean

-- Stash operations (safezone only)
InventoryService:GetStash(player) -> StashData
InventoryService:TransferToStash(player, inventorySlot, stashSlot) -> boolean
InventoryService:TransferFromStash(player, stashSlot, inventorySlot) -> boolean

-- Sync
InventoryService:SyncToClient(player)  -- Fires UpdateInventory remote
```

### Containers

The system uses a `Container` abstraction to unify inventory, stash, and equipment:

| Container | ID String | Slot Type | Max Slots |
|-----------|-----------|-----------|-----------|
| Field Inventory | `"inventory"` | Numbered (1–N) | 16 (upgradeable by Backpack) |
| Stash | `"stash"` | Numbered (1–N) | 100 (upgradeable) |
| Equipment | `"equipment"` | Named (`"backpack"`, `"armor"`, `"weapon1"`, `"weapon2"`) | Fixed (4 slots) |
| Quick Use | `"quickuse"` | Numbered (1–8) | Fixed (8 slots) |

`MoveItem` and `SwapItems` work across any two containers, enabling drag-and-drop between inventory, stash, and equipment in the UI.

---

## VII. Client-Server Sync

### Remotes

All remotes live under `ReplicatedStorage.InventoryRemotes` (same folder name as before, reused).

| Remote | Direction | Payload | Purpose |
|--------|-----------|---------|---------|
| `SyncFullState` | Server → Client | `{ inventory, equipment, quickUse, currency }` | Sent on join and after bulk changes |
| `SyncSlotUpdate` | Server → Client | `{ container, slot, item: SerializedItem? }` | Granular single-slot update |
| `SyncCurrency` | Server → Client | `{ gold, premium? }` | Currency change notification |
| `RequestMove` | Client → Server | `{ fromContainer, fromSlot, toContainer, toSlot }` | Drag-and-drop move/swap |
| `RequestEquip` | Client → Server | `{ instanceId, slot }` | Equip item to equipment slot |
| `RequestUnequip` | Client → Server | `{ slot }` | Unequip from equipment slot |
| `RequestDrop` | Client → Server | `{ instanceId }` | Drop item into world |
| `RequestUseQuick` | Client → Server | `{ quickSlot }` | Use consumable in quick slot |
| `RequestAssignQuick` | Client → Server | `{ instanceId, quickSlot }` | Assign item to quick bar |
| `RequestStashTransfer` | Client → Server | `{ direction, fromSlot, toSlot }` | Move between inventory and stash |
| `RequestAbility` | Client → Server | `{ weaponSlot, abilitySlotIndex }` | Activate an ability |
| `AbilityActivated` | Server → Clients | `{ playerId, abilityId, weaponSlot }` | Notify nearby clients for VFX |
| `AbilityCooldownSync` | Server → Client | `{ abilityId, remainingCooldown }` | Sync cooldown state |
| `RequestSetAbilityPreset` | Client → Server | `{ presetKey, slotIndex, abilityId?, isUltimate? }` | Set/clear ability in preset |
| `SyncAbilityPresets` | Server → Client | `{ presets: AbilityPresetsData }` | Full preset sync on join |
| `RequestUseConsumable` | Client → Server | `{ quickSlot }` | Use consumable from quick bar |
| `ConsumableActivated` | Server → Clients | `{ playerId, consumableId }` | Notify nearby clients for VFX |

### Sync Strategy

- **Full sync** on join and after any operation that touches multiple slots (e.g. sorting, bulk stash transfer). Includes `SyncFullState` for inventory/equipment and `SyncAbilityPresets` for all ability presets.
- **Granular sync** (`SyncSlotUpdate`) for single-slot changes (equip, use, pick up one item). Reduces bandwidth and avoids re-rendering the entire UI.
- **Ability preset sync**: When a player changes an ability preset (via the ability management UI), the server confirms and the client updates its local mirror. The full preset table is only sent on join; individual changes are confirmed per-slot.
- The client maintains a local mirror of inventory state and ability presets for immediate UI rendering. All mutations go through server remotes; the client never mutates its mirror directly.

---

## VIII. Stash System

The stash is a large persistent storage accessible only in safezone villages.

### Access Control

- `InventoryService:TransferToStash` and `TransferFromStash` check whether the player's character is currently in a safezone. If not, the operation is rejected.
- Safezone detection: the server checks if the character's `HumanoidRootPart` is within a safezone boundary volume (tagged with `CollectionService` tag `"Safezone"`).

### Stash UI

The stash is a separate screen (not the Tab loadout). It shows two grids side by side:
- Left: Stash slots (scrollable, potentially 100+ slots)
- Right: Field inventory (16 slots)

Drag-and-drop between the two grids calls `RequestStashTransfer`.

### Stash Capacity

The base stash has 100 slots. The equipped Backpack item increases field inventory capacity but does not affect stash. Stash capacity can be upgraded through gameplay progression (quests, currency, etc.).

---

## IX. Data Migration

When the schema changes, the `version` field in `PlayerData` is used to run sequential migrations.

```
CURRENT_VERSION = 1

Migrations = {
    [1] = function(data)
        -- v0 → v1: initial schema
        -- No migration needed for v1 (first version)
        return data
    end,
}
```

Each migration function receives the old data table and returns the updated table. Migrations run sequentially: if a player's data is at version 3 and current is 5, migrations 4 and 5 run in order.

### Migration Rules

1. **Never remove fields** in a migration — only add or rename.
2. **Always provide defaults** for new fields.
3. **Log all migrations** for debugging.
4. **Test migrations** against sample data before deploying.

---

## X. Error Handling & Safety

### DataStore Failures

- All DataStore calls are wrapped in `pcall`.
- On `GetAsync` failure: retry up to 3 times with exponential backoff (2s, 4s, 8s). If all fail, the player is kicked with a message explaining the issue.
- On `UpdateAsync` failure during auto-save: retry next cycle. Log the failure.
- On `UpdateAsync` failure during `PlayerRemoving`: retry immediately up to 3 times. If all fail, log a critical error (data may be stale on next join but session lock prevents duplication).

### Rollback Protection

- The auto-save loop keeps a copy of the last successfully saved state.
- If the in-memory state is detected as corrupt (e.g. negative item counts, invalid templateIds), the system rolls back to the last saved state and logs the issue.

### Budget Management

- Roblox DataStore has request budgets. The system checks `DataStoreService:GetRequestBudgetForRequestType()` before each call.
- If budget is low, saves are deferred to the next cycle.
- `BindToClose` gets a 30-second window; the system prioritizes saving players with dirty data first.

---

## XI. Module Dependency Graph

```
DataManager (sole DataStore access)
    ↓ provides PlayerData cache (inventory, equipment, abilityPresets, etc.)
InventoryService (reads/writes inventory/equipment cache)
    ↓ calls
StatsService (equipment modifiers via StatModifier)
    ↓ calls
ModifierService (converts ItemModifier → StatModifier)

AbilityService (reads/writes abilityPresets cache)
    ↓ reads ability assets from ReplicatedStorage.Assets.Abilities
    ↓ calls DamageService, StatsService, HitDetection, StatusEffects
    ↓ fires ability remotes to clients

ConsumableService (reads consumable assets from ReplicatedStorage.Assets.Consumables)
    ↓ calls InventoryService (decrement stack), DamageService, StatsService
    ↓ fires consumable remotes to clients

InventoryService + AbilityService + ConsumableService
    ↓ fire remotes
Client UI (LoadoutController, HudLoadoutController, AbilityManagement)
    ↓ sends requests
Server services (validate and execute)
    ↓ mark dirty
DataManager (saves on next cycle)
```

---

[← Item System](./item-system.md) | [← Modifier System](./modifier-system.md) | [ReplicatedStorage Layout →](./replicated-storage.md)
