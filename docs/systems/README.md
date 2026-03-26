# Systems Documentation

Technical specifications for the core backend systems of Project S. These docs describe the architecture, data schemas, and module interfaces that should be implemented. They are design documents — not descriptions of existing code.

## Documents

| Document | Scope |
|----------|-------|
| [Item & Weapon System](./item-system.md) | Item taxonomy, template schemas (weapons, armor, consumables, etc.), item instance lifecycle, equipment slots, config module organization, weapon tags, unique weapons |
| [Ability & Consumable System](./ability-system.md) | Tag-based weapon/ability compatibility, self-contained ability and consumable assets with scripts, ability preset persistence per weapon class, runtime activation flow, shared utility modules |
| [Modifier System](./modifier-system.md) | Bonus stat modifiers on items, modifier pools, RNG rolling algorithm, tier system, integration with StatsService, rerolling mechanics |
| [Data Persistence](./data-persistence.md) | PlayerData schema (including ability presets), serialized item format, DataStore architecture, session locking, save/load pipeline, InventoryService API, client-server sync remotes, stash system |
| [ReplicatedStorage Layout](./replicated-storage.md) | Full folder tree (items, abilities, consumables), asset specs, asset resolver API, Rojo sync mapping, naming conventions, performance considerations |
| [Movement Lock](./movement-lock.md) | Client-side movement interruption (walk/sprint/jump/swim), `MovementLock` registry, enforcer, weapon `movementLocks`, ability usage |

## Reading Order

1. Start with **Item System** — it defines all the types and concepts referenced by the other docs.
2. Read **Ability & Consumable System** next — it defines how abilities and consumables work as self-contained assets, the tag system for weapon/ability compatibility, and per-class ability presets.
3. Read **Modifier System** — it extends items with RNG bonus stats.
4. Read **Data Persistence** — it defines how items, modifiers, and ability presets are stored and synced.
5. Read **ReplicatedStorage Layout** — it defines where visual assets, ability assets, and consumable assets live.

## Relationship to Gameplay Docs

The gameplay docs in `docs/gameplay/` describe *what* the game is (design, combat, attributes). The system docs here describe *how* the backend implements it. Cross-references:

- `gameplay/equipment.md` → `systems/item-system.md` (weapon stats, armor, scaling)
- `gameplay/combat-system.md` → `systems/item-system.md` + `systems/ability-system.md` (damage pipeline, abilities, weapon arts)
- `gameplay/attributes.md` → `systems/modifier-system.md` (modifiers feed into attribute-derived stats)
- `gameplay/world-progression.md` → `systems/modifier-system.md` (island difficulty scales modifier quality)

## What Was Deprecated

The following old modules were removed as part of this redesign:

| Removed | Replaced By |
|---------|-------------|
| `Configs/LootSystem/ItemDefinitions.luau` | `Configs/Items/ItemRegistry.luau` + per-subcategory config files |
| `Configs/LootSystem/LootConfig.luau` | New `LootService` (not yet built) |
| `Configs/LootSystem/LootPools.luau` | `ItemRegistry.GetRandomTemplate()` + `ModifierPools` |
| `Configs/LootSystem/DropRules.luau` | New `DropService` (not yet built) |
| `LootSystem/DropFactory.luau` | New `DropService` (world drop spawning) |
| `LootSystem/LootBoxService.luau` | New `LootService` (loot table rolls) |
| `LootSystem/BreakableCrate.luau` | Will be rebuilt as needed |
| `Inventory/InventoryService.luau` | New `InventoryService` backed by `DataManager` |
| `GUI/Loadout/ItemIconResolver.luau` | `AssetResolver` + direct `iconId` from templates |

Modules that were **kept** (still functional, will be adapted):
- `Configs/Stats/*` — stat system (used by modifier pipeline)
- `Inventory/InventoryTypes.luau` — shared types (will be updated to new schemas)
- All GUI components — UI rendering stays, data source changes

Modules **marked for deprecation** (still functional, will be removed when new systems are built):
- `Configs/Weapons/MeleeConfigs.luau` — replaced by `WeaponTemplate` fields + per-ability scripts in `Assets/Abilities/`
- `Configs/Med/MedConfigs.luau` — replaced by per-consumable scripts in `Assets/Consumables/`
- `server/Weapons/MeleeService.luau` — replaced by `AbilityService` + `BasicAttackService`
- `server/Med/MedService.luau` — replaced by `ConsumableService`
- `client/Weapons/MeleeController.client.luau` — replaced by client-side ability runtime
- `client/Med/MedController.client.luau` — replaced by client-side consumable runtime
