# Normal Island — Module Reference

## Configs (ReplicatedStorage.Configs)

### IslandConfig

Island dimensions and spawn settings (studs).

| Field | Value | Description |
|-------|-------|-------------|
| `coreSize` | 1600×100×1600 | Core land (grass) area |
| `sandRimWidth` | 100 | Sand rim around core |
| `oceanWidth` | 300 | Ocean around sand rim |
| `totalSize` | 2400×100×2400 | Total island + ocean |
| `spawnRadius` | 50 | Spawn point radius |
| `spawnAreaSize` | 1800×100×1800 | Core + sand rim (spawnable area) |
| `spawnAreaCenter` | (0, 300, 0) | Center of spawn area |
| `maxPlayers` | 100 | Max players per server |

### MinimapConfig

Minimap/FullMap UI, ping types, per-island assets. `worldToUV`, `uvToWorld`, `getMinimapAsset()`.

### OccupancyMap

2D grid for spawn point management. Cell size 10, total width 1900. `FREE`, `WATER`, `RESERVED`. `initialize()`, `worldToGridIndex()`, `isAreaFree()`, `markCircularArea()`, `markWaterAreas()`.

### PlayerConfig

Player stats: `walkSpeed`, `runSpeed`, `jumpPower`, `maxHealth`, `humanoidRigType`, `scale`, stamina/adrenaline/fall-damage params.

### MedConfigs

Med item configs: Bandage, Medkit, Soda, Pill. Each has `useTime`, `mode` (Instant/OverTime), `healthAmount`, `adrenalineDelta`, `useWalkSpeed`.

### LootConfig

Crate types (Normal, NormalPlus, WeaponCrate, GrenadeBox, MedicalCrate, Elite, etc.), rarity weights, category weights, `BundleCount`, `MaxHealth`.

### ItemDefinitions

Item categories (GUN, GRENADE, AMMO, MED, ARMOR, ATTACHMENT), rarities (COMMON–LEGENDARY).

---

## Modules (ReplicatedStorage.Modules)

### MapMath

`worldToUV`, `uvToWorld`, `uvToFullMapPosition`, `uvToMinimapContentPosition`, `minimapPanForPlayerUV`.

### RoundState

Singleton for round seed and deterministic RNG. `Initialize(seed)`, `GetSeed()`, `GetCrateRollRng(crateId)`.

### FastCastRedux

Raycast-based projectile system for guns.

---

## Server

### Initializer

Bootstraps all services: RoundState, InventoryService, DropFactory, LootBoxService, BreakableCrate, GunService, MeleeService, MedService. Enforces R15, character config (scale, WalkSpeed, etc.). Registers static crates in workspace (models with `CrateType` attribute). Exposes `MatchInfo.StartTime`.

### PlayerSpawner

Occupancy-based spawn points (100 targets, 30-stud separation). Uses IslandConfig, OccupancyMap, PlayerConfig. Applies character config on spawn.

### PingService

Validates and broadcasts pings. Creates beam effects. One active ping per player.

### DamageService

Handles damage application (used by BreakableCrate, weapons).

### GunService / MeleeService

Weapon logic. GunToolScript: server-side gun tool behavior.

### MedService

Authoritative med item usage (heal, adrenaline). Listens on MedRemotes.UseMed.

### InventoryService

Player inventory state. Listens on InventoryRemotes (UpdateInventory, RequestEquip, RequestSwap).

### LootBoxService / DropFactory / BreakableCrate

Crate breaking, item drops. BreakableCrate registers static crates in workspace (models with `CrateType` attribute). Loot rolls use deterministic RNG per crate via `CrateId`.

### Stamina / FallDamage

Stamina drain (sprint, swim, jump). Fall damage based on fall distance (6.25 damage/stud beyond 4 studs, capped at 100).

---

## Client

### MinimapController (Map)

Entry: `MinimapController.client.luau` requires `Map/MinimapController`. Builds minimap, full map, top-right HUD (health, stamina, player count), match timer. Handles M toggle, right-click+C ping, CursorManager for full map. Updates player icon, ping positions.

### HudBuilder

`buildMinimap(playerGui)`, `buildInventory(rows, cols)`, `buildTopRightHud(playerGui)`.

### CursorManager

`setEnabledFor(source, enabled)`. Shows cursor when UI is open (FullMap, Inventory). Sets `ReplicatedStorage.UICursorEnabled`.

### Crosshair

Disabled (hidden). Stub can be re-enabled by setting `root.Visible = true` and restoring crosshair lines.

### Sprint

Left Ctrl toggles sprint. Uses `WantsSprint` attribute, Stamina server sync. Jump blocked when stamina &lt; cost (ContextActionService).

### InventoryController / InventoryUI

Tab toggles inventory. Renders grid + hotbar from server updates. Drag/drop swap, equip. Uses CursorManager for inventory open.

### MedController

Listens for med Tools (Bandage, Medkit, etc.) in character. On Activated: fires UseMed to server, slows WalkSpeed, plays sound/particles for `useTime`, then restores.

### GunController / MeleeController / BulletRenderer

Weapon input and visuals.
