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

All persistent data for a player is stored under a single DataStore key: `"PLAYER_{userId}"`.

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

## IV. DataStore Architecture & DataService

Persistence is provided by the **leifstout/dataservice** package, which uses **ProfileStore** (or equivalent) under the hood. The server initializes the dataService with a default `PlayerData` template; session locking and auto-save are handled by the package.

### Key Structure

| Store Name   | Key Pattern     | Contents           |
|-------------|-----------------|--------------------|
| `PlayerData_v1` | `"PLAYER_{userId}"` | Full `PlayerData` table |

One store, one key per player. The default template is built from `DataManager.createDefaultData(0)` in the server **DataServiceBootstrap** module.

### Session Locking

Session locking is handled by the dataService/ProfileStore layer: only one server owns a player's data at a time. The package manages claim/release on `PlayerAdded` / `PlayerRemoving` and `BindToClose`.

### Replication

Replication to the client is **automatic** when the server updates data via the dataService path-based API (`set` / `update`). No manual `SyncToClient` or `SyncAbilityPresets` calls are used; the client reads from the dataService client API (`get`, and optionally `getChangedSignal` for path-based updates).

### Load Pipeline

1. `PlayerAdded` fires.
2. Initializer (or bootstrap) waits for the player's data via `DataServiceBootstrap.WaitForPlayerData(player)`.
3. The package loads the profile (or creates from template with Reconcile).
4. Server code reads/writes via path-based `DataService:get(player, path)` and `DataService:set(player, path, value)` (or equivalent). The client receives replicated updates automatically.
5. Character attributes are applied from loaded data to `StatsService` as before.

---

## V. Server-Side Data Access (dataService)

The **dataService** package is the gateway to persistence. The server uses path-based get/set/update; the **DataServiceBootstrap** module initializes the package and exposes `WaitForPlayerData(player)` for the Initializer.

### Path-Based API (server)

- **Read:** `DataService:get(player, path)` — e.g. `get(player, {})` for full data, `get(player, {"inventory", "slots"})` for a subtree.
- **Write:** `DataService:set(player, path, value)` — e.g. `set(player, {"equipment", "Weapon1"}, item)`.

Paths align with the schema: `{"inventory"}`, `{"inventory","slots", slotIndex}`, `{"equipment","Weapon1"}`, `{"quickUse","slots", index}`, `{"abilityPresets", presetKey}`, etc.

### DataManager (template only)

The **DataManager** module now only exports `createDefaultData(userId)` for use as the ProfileStore/default template. It does not perform load, save, or cache operations; those are handled by the dataService package.

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
InventoryService:SyncToClient(player)  -- No-op; replication is automatic via dataService
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

### State replication (dataService)

Inventory, equipment, quickUse, currency, and abilityPresets are **replicated to the client automatically** by the dataService package when the server calls `set`/`update` on the path-based API. The client reads state via the dataService client API (`get`, and optionally `getChangedSignal` for path-based updates). LoadoutController and HudLoadoutDataAdapter build their UI state from these reads; they do not rely on SyncFullState or SyncAbilityPresets for state.

### Remotes (InventoryRemotes)

All gameplay remotes remain under `ReplicatedStorage.InventoryRemotes`. **Request** remotes are unchanged; **sync** remotes are no longer fired by the server for state (dataService replicates instead).

| Remote | Direction | Purpose |
|--------|-----------|---------|
| `SyncFullState` | Server → Client | **No longer fired.** State comes from dataService client. |
| `SyncSlotUpdate` | Server → Client | **No longer fired.** |
| `SyncCurrency` | Server → Client | **No longer fired.** |
| `RequestMove` | Client → Server | Drag-and-drop move/swap |
| `RequestEquip` | Client → Server | Equip item to equipment slot |
| `RequestUnequip` | Client → Server | Unequip from equipment slot |
| `RequestDrop` | Client → Server | Drop item into world |
| `RequestUseQuick` | Client → Server | Use consumable in quick slot |
| `RequestAssignQuick` | Client → Server | Assign item to quick bar |
| `RequestStashTransfer` | Client → Server | Move between inventory and stash |
| `RequestAbility` | Client → Server | Activate an ability |
| `AbilityActivated` | Server → Clients | Notify nearby clients for VFX |
| `AbilityCooldownSync` | Server → Client | Sync cooldown state |
| `RequestSetAbilityPreset` | Client → Server | Set/clear ability in preset |
| `SyncAbilityPresets` | Server → Client | **No longer fired.** Presets come from dataService. |
| `RequestUseConsumable` | Client → Server | Use consumable from quick bar |
| `ConsumableActivated` | Server → Clients | Notify nearby clients for VFX |

### Sync strategy

- The client obtains initial and updated state via the dataService client API (path-based `get` and, if available, `getChangedSignal`). No manual sync remotes are used for inventory/equipment/quickUse/abilityPresets.
- All mutations go through server request remotes; the server updates state via the dataService path-based API, and replication to the client is automatic.

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
DataServiceBootstrap (inits dataService server + template)
    ↓
dataService package (ProfileStore, path-based get/set, replication)
    ↓
InventoryService (DataService:get/set paths: inventory, equipment, quickUse, stash)
AbilityDataService (DataService:get/set paths: abilityPresets)
    ↓
StatsService (equipment modifiers via StatModifier)
    ↓
ModifierService (converts ItemModifier → StatModifier)

AbilityService (reads abilityPresets via AbilityDataService; fires ability remotes)
ConsumableService (calls InventoryService; fires consumable remotes)

Client UI (LoadoutController, HudLoadoutDataAdapter)
    ↓ request remotes (RequestMove, RequestEquip, etc.)
Server handlers (validate, then DataService:set/update)
    ↓ replication automatic
dataService client (client reads via get / getChangedSignal)
```

---

[← Item System](./item-system.md) | [← Modifier System](./modifier-system.md) | [ReplicatedStorage Layout →](./replicated-storage.md)
