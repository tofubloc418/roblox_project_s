# ReplicatedStorage Layout & Asset Organization

This document specifies how item assets (visual models, icons) are organized in ReplicatedStorage so the system can resolve them efficiently at runtime. It also covers the full ReplicatedStorage folder tree including configs, shared modules, and network remotes.

---

## I. Design Principles

1. **Config data lives in Luau modules, not on Instances.** Icons are referenced by `iconId` strings in templates. Visual meshes are resolved by `templateId` path. No attributes or value objects on prefabs.
2. **Mirror the config hierarchy.** The asset folder structure matches the config file structure: `Assets/Items/Weapons/Greatswords/IronGreatsword`. If you can find the config, you can find the asset.
3. **Prefabs are visual-only.** A prefab is a Model with MeshParts/Parts for rendering. It has no scripts, no tools, no gameplay logic. The server clones it when spawning a world drop or equipping a weapon visually.
4. **Flat within subcategories.** Each subcategory folder contains items directly — no further nesting. This keeps lookups O(1) via `folder:FindFirstChild(templateId)`.

---

## II. Full ReplicatedStorage Tree

```
ReplicatedStorage/
│
├── Configs/                          -- Luau config modules (synced from src/shared via Rojo)
│   ├── PlayerConfig.luau
│   ├── IslandConfig.luau
│   ├── MinimapConfig.luau
│   ├── OccupancyMap.luau
│   │
│   ├── Stats/
│   │   ├── StatsTypes.luau
│   │   ├── StatsConfig.luau
│   │   └── StatFormulas.luau
│   │
│   ├── Items/                        -- NEW: item template configs
│   │   ├── ItemEnums.luau
│   │   ├── ItemRegistry.luau
│   │   ├── Weapons/
│   │   │   ├── Daggers.luau
│   │   │   ├── StraightSwords.luau
│   │   │   ├── Greatswords.luau
│   │   │   ├── Katanas.luau
│   │   │   ├── Axes.luau
│   │   │   ├── Greataxes.luau
│   │   │   ├── Hammers.luau
│   │   │   ├── GreatHammers.luau
│   │   │   ├── Spears.luau
│   │   │   ├── Halberds.luau
│   │   │   ├── FistWeapons.luau
│   │   │   ├── Whips.luau
│   │   │   ├── Staves.luau
│   │   │   ├── Seals.luau
│   │   │   ├── Bows.luau
│   │   │   └── Crossbows.luau
│   │   ├── Armor/
│   │   │   └── Armor.luau
│   │   ├── Backpacks/
│   │   │   └── Backpacks.luau
│   │   ├── Consumables/
│   │   │   ├── Healing.luau
│   │   │   ├── Buffs.luau
│   │   │   ├── Throwables.luau
│   │   │   └── Food.luau
│   │   ├── Materials/
│   │   │   └── Materials.luau
│   │   └── KeyItems/
│   │       └── KeyItems.luau
│   │
│   ├── Modifiers/                    -- NEW: modifier pools and enums
│   │   ├── ModifierEnums.luau
│   │   └── ModifierPools.luau
│   │
│   ├── Weapons/                      -- DEPRECATED: will be removed when ability system is built
│   │   └── MeleeConfigs.luau         -- Replaced by WeaponTemplate fields + per-ability scripts
│   │
│   └── Med/                          -- DEPRECATED: will be removed when consumable system is built
│       └── MedConfigs.luau           -- Replaced by per-consumable scripts in Assets/Consumables/
│
├── Inventory/                        -- Shared types
│   └── InventoryTypes.luau
│
├── Modules/                          -- Shared utility modules
│   ├── RoundState.luau
│   ├── MapMath.luau
│   └── FastCastRedux.luau
│
├── Packages/                         -- Third-party (React, ReactRoblox)
│   └── ...
│
├── Assets/                           -- Visual prefabs, ability scripts, consumable scripts
│   ├── Items/                        -- Visual-only prefabs (3D models for world/equip display)
│   │   ├── Weapons/
│   │   │   ├── Daggers/
│   │   │   │   ├── Stiletto          (Model)
│   │   │   │   └── ParryingDagger    (Model)
│   │   │   ├── StraightSwords/
│   │   │   │   ├── Longsword         (Model)
│   │   │   │   └── Broadsword        (Model)
│   │   │   ├── Greatswords/
│   │   │   │   ├── IronGreatsword    (Model)
│   │   │   │   └── Claymore          (Model)
│   │   │   ├── Katanas/
│   │   │   ├── Axes/
│   │   │   ├── Greataxes/
│   │   │   ├── Hammers/
│   │   │   ├── GreatHammers/
│   │   │   ├── Spears/
│   │   │   ├── Halberds/
│   │   │   ├── FistWeapons/
│   │   │   ├── Whips/
│   │   │   ├── Staves/
│   │   │   ├── Seals/
│   │   │   ├── Bows/
│   │   │   ├── Crossbows/
│   │   │   └── Unique/              -- Unique weapon prefabs
│   │   │       ├── Moonveil/         (Model)
│   │   │       └── RiversOfBlood/    (Model)
│   │   ├── Armor/
│   │   │   ├── LightVest             (Model — icon only; no cosmetic mesh)
│   │   │   └── ...
│   │   ├── Backpacks/
│   │   │   └── ...
│   │   ├── Materials/
│   │   │   └── ...
│   │   └── KeyItems/
│   │       └── ...
│   │
│   ├── Abilities/                    -- Self-contained ability assets (scripts + animations + VFX)
│   │   ├── HeavySlash/              (Folder)
│   │   │   ├── AbilityConfig.luau   (ModuleScript — metadata, tags, costs, tuning)
│   │   │   ├── AbilityServer.luau   (ModuleScript — server-side behavior)
│   │   │   ├── AbilityClient.luau   (ModuleScript — client-side visuals/input)
│   │   │   ├── Animations/          (Folder — Animation instances)
│   │   │   ├── VFX/                 (Folder — ParticleEmitters, Beams)
│   │   │   └── SFX/                 (Folder — Sound instances)
│   │   ├── QuickStep/
│   │   ├── UniversalParry/
│   │   ├── WarCry/
│   │   ├── Whirlwind/
│   │   ├── MoonveilBeam/            -- Unique-weapon-exclusive ability
│   │   └── ...
│   │
│   └── Consumables/                  -- Self-contained consumable assets (scripts + animations)
│       ├── Bandage/                  (Folder)
│       │   ├── ConsumableConfig.luau (ModuleScript — metadata, constraints, tuning)
│       │   ├── ConsumableServer.luau (ModuleScript — server-side behavior)
│       │   ├── ConsumableClient.luau (ModuleScript — client-side visuals)
│       │   ├── Animations/           (Folder)
│       │   └── SFX/                  (Folder)
│       ├── Medkit/
│       ├── FragGrenade/
│       │   ├── ConsumableConfig.luau
│       │   ├── ConsumableServer.luau
│       │   ├── ConsumableClient.luau
│       │   ├── Projectile/           (Model — the grenade mesh)
│       │   └── VFX/
│       ├── StrengthElixir/
│       └── ...
│
├── InventoryRemotes/                 -- Created at runtime by server
│   ├── SyncFullState     (RemoteEvent)
│   ├── SyncSlotUpdate    (RemoteEvent)
│   ├── SyncCurrency      (RemoteEvent)
│   ├── RequestMove       (RemoteEvent)
│   ├── RequestEquip      (RemoteEvent)
│   ├── RequestUnequip    (RemoteEvent)
│   ├── RequestDrop       (RemoteEvent)
│   ├── RequestUseQuick   (RemoteEvent)
│   ├── RequestAssignQuick(RemoteEvent)
│   ├── RequestStashTransfer (RemoteEvent)
│   ├── RequestAbility    (RemoteEvent)   -- Activate ability
│   ├── AbilityActivated  (RemoteEvent)   -- Server→Clients: VFX notification
│   ├── AbilityCooldownSync (RemoteEvent) -- Server→Client: cooldown state
│   ├── RequestSetAbilityPreset (RemoteEvent) -- Set/clear ability in preset
│   ├── SyncAbilityPresets (RemoteEvent)  -- Full preset sync on join
│   ├── RequestUseConsumable (RemoteEvent) -- Use consumable from quick bar
│   └── ConsumableActivated (RemoteEvent) -- Server→Clients: VFX notification
│
└── MatchInfo/                        -- Created at runtime by server
    └── StartTime         (NumberValue)
```

---

## III. Asset Prefab Specification

### What a Prefab Is

A prefab is a **Model** in ReplicatedStorage that represents the visual appearance of an item. It is never a Tool, Script, or anything with behavior. The server clones it when needed (world drops, character weapon display).

### Prefab Structure

```
Model (Name = templateId, e.g. "IronGreatsword")
├── Handle            (MeshPart or Part — REQUIRED)
│                      The grip/attachment point. Welded to character's hand when equipped.
│                      Name MUST be "Handle" for the equip system to find it.
│
├── Blade             (MeshPart or Part — optional additional visual parts)
├── Guard             (MeshPart or Part — optional)
├── Pommel            (MeshPart or Part — optional)
│
├── GripAttachment    (Attachment on Handle — optional)
│                      Precise grip point. If absent, Handle.CFrame center is used.
│
└── Muzzle            (Attachment — optional, for ranged weapons)
                       Projectile spawn point.
```

### Rules

1. **Name = templateId.** The Model's Name must exactly match the `templateId` in the config. This is how the asset resolver finds it.
2. **Handle is required.** Every prefab must have a BasePart child named `"Handle"`. This is the part that gets welded to the character's hand.
3. **All parts welded to Handle.** Additional visual parts must be welded (Motor6D or WeldConstraint) to Handle so they move as a unit.
4. **No scripts.** Prefabs must not contain any scripts. All behavior is driven by server/client modules.
5. **No attributes for gameplay data.** Gameplay stats live in config modules. Prefabs are purely visual.
6. **Anchored = false.** All parts should be unanchored (they'll be positioned by the equip system).
7. **CanCollide = false** on all parts except Handle (which may need collision for world drops).

### Armor Prefabs

**Armor has no cosmetic effect.** Equipped armor does not change the player's character appearance. The character model stays the same. Armor prefabs exist only for:
- **Inventory icon** — resolved via `iconId` in the template (no 3D mesh needed for display)
- **World drop model** — when dropped, a simple placeholder model can be used (e.g. a generic crate or icon billboard)

When the player equips or unequips armor, a "suiting up" / "suiting down" animation plays on the character for visual feedback. No mesh or cosmetic changes are applied.

### Ability Assets

Ability assets are **Folders** (not Models) in `Assets/Abilities/`. Each folder is a self-contained unit with its own scripts, animations, VFX, and sounds. The `AbilityService` scans this folder on startup to build its registry.

**Required children:**
- `AbilityConfig.luau` (ModuleScript) — metadata, compatibility tags, costs, tuning params
- `AbilityServer.luau` (ModuleScript) — server-side activation/deactivation logic
- `AbilityClient.luau` (ModuleScript) — client-side visual feedback

**Optional children:**
- `Animations/` (Folder) — Animation instances used by this ability
- `VFX/` (Folder) — ParticleEmitters, Beams, and other visual effects
- `SFX/` (Folder) — Sound instances

The folder name MUST match the `abilityId` in `AbilityConfig.luau`. See [ability-system.md](./ability-system.md#iii-ability-assets-in-replicatedstorage) for the full spec.

### Consumable Assets

Consumable assets follow the same pattern as abilities: **Folders** in `Assets/Consumables/`, each with its own scripts.

**Required children:**
- `ConsumableConfig.luau` (ModuleScript) — metadata, constraints, tuning params
- `ConsumableServer.luau` (ModuleScript) — server-side use logic
- `ConsumableClient.luau` (ModuleScript) — client-side visual feedback

**Optional children:**
- `Animations/` (Folder) — Use animations
- `VFX/` (Folder) — Visual effects
- `SFX/` (Folder) — Sound effects
- `Projectile/` (Model) — For throwables, the projectile mesh to clone

The folder name MUST match the consumable's `templateId` in the item config. This is how `ConsumableService` links the inventory item to its behavior. See [ability-system.md](./ability-system.md#v-consumable-assets-in-replicatedstorage) for the full spec.

---

## IV. Asset Resolver

The `AssetResolver` module replaces the old `ItemIconResolver`. It provides two lookups:

### API

```
AssetResolver.GetIcon(templateId: string) -> string?
AssetResolver.GetPrefab(templateId: string) -> Model?
AssetResolver.GetPrefabPath(templateId: string) -> string?
```

### Icon Resolution

Icons are **not** stored on prefabs. They are stored as `iconId` strings in the item template config:

```lua
local template = ItemRegistry.GetTemplate("IronGreatsword")
local iconId = template.iconId  -- "rbxassetid://123456789"
```

This is a pure table lookup — no Instance traversal, no `FindFirstChild` chains. The UI reads `iconId` directly from the template.

### Prefab Resolution

When the system needs a 3D model (world drop, character weapon display), it resolves the prefab:

```lua
function AssetResolver.GetPrefab(templateId: string): Model?
    local template = ItemRegistry.GetTemplate(templateId)
    if not template then return nil end

    local assetsRoot = ReplicatedStorage:FindFirstChild("Assets")
    if not assetsRoot then return nil end

    local itemsRoot = assetsRoot:FindFirstChild("Items")
    if not itemsRoot then return nil end

    -- Navigate: Items/{Category}/{Subcategory}/{templateId}
    local categoryFolder = itemsRoot:FindFirstChild(template.category)
    if not categoryFolder then return nil end

    local subcategoryFolder = categoryFolder:FindFirstChild(template.subcategory)
    if not subcategoryFolder then return nil end

    return subcategoryFolder:FindFirstChild(templateId)
end
```

This is a 4-level `FindFirstChild` chain — fast because each level has a known name. No iteration over descendants.

### Prefab Caching

`AssetResolver` caches resolved prefabs in a `_cache[templateId] = Model` dictionary. The cache is populated on first access and never invalidated (prefabs in ReplicatedStorage don't change at runtime).

---

## V. Rojo Sync Mapping

The Rojo project file (`NormalIsland1.project.json`) maps source directories to Roblox containers:

| Roblox Path | Source Path | Notes |
|-------------|-------------|-------|
| `ReplicatedStorage` | `src/shared/sharedNormalIsland` | Configs, Inventory types, Modules |
| `ServerScriptService` | `src/server/serverNormalIsland` | InventoryService, DataManager, etc. |
| `StarterPlayerScripts` | `src/client/clientNormalIsland` | GUI controllers, HUD, etc. |

### What Rojo Syncs vs What's in Studio

| Content | Managed By | Location |
|---------|-----------|----------|
| Config Luau modules | **Rojo** (source files) | `src/shared/.../Configs/Items/` |
| Item prefabs (3D models) | **Studio** (manual placement) | `ReplicatedStorage.Assets.Items.*` (in .rbxl) |
| Ability assets (Folders with scripts + animations) | **Studio** (manual placement) | `ReplicatedStorage.Assets.Abilities.*` (in .rbxl) |
| Consumable assets (Folders with scripts + animations) | **Studio** (manual placement) | `ReplicatedStorage.Assets.Consumables.*` (in .rbxl) |
| GUI ScreenGuis | **Rojo** (React components) | `src/client/.../GUI/` |
| Remotes | **Runtime** (server creates) | `ReplicatedStorage.InventoryRemotes` |

**Asset folders (Items, Abilities, Consumables) are NOT synced by Rojo.** They live in the Studio .rbxl file because they contain 3D models, Animation instances, ParticleEmitters, Sounds, and other Instance-based content that must be authored in Studio. The ModuleScript children (AbilityConfig, AbilityServer, etc.) are authored directly inside Studio as part of the asset. Rojo handles only the Luau source code for configs, services, and GUI components.

To keep ability/consumable scripts version-controlled, consider using Rojo's `$path` for the `Assets/Abilities` and `Assets/Consumables` folders, syncing only the `.luau` scripts while leaving Animations/VFX/SFX in Studio. Alternatively, manage all assets purely within the Studio file and document the expected structure in this doc.

---

## VI. Adding New Assets: Checklists

### Adding a New Weapon

1. **Config:** Add template to the appropriate config file (e.g. `Configs/Items/Weapons/StraightSwords.luau` or `UniqueWeapons.luau`)
   - Set `iconId = "rbxassetid://YOUR_ICON"`
   - Set `tags` array (must include `"All"` + class/style/element/unique tags)
   - Set `abilityPresetKey` (class name or `"Unique_{templateId}"`)
   - Set all required `WeaponTemplate` fields

2. **Prefab:** In Studio, create a Model in `ReplicatedStorage.Assets.Items.Weapons.{Subcategory}/`
   - Name it exactly as the `templateId`
   - Add a `Handle` BasePart, weld additional visual parts to it
   - No scripts, no attributes

3. **Icon:** Upload a square icon image to Roblox, paste `rbxassetid://` into `iconId`

4. **Done.** `ItemRegistry` auto-discovers the config. `AssetResolver` finds the prefab. Tag system enables ability compatibility automatically.

### Adding a New Ability

1. **Asset folder:** Create a Folder in `ReplicatedStorage.Assets.Abilities/{abilityId}`
2. **AbilityConfig.luau:** Set `abilityId`, `displayName`, `compatibleTags`, costs, cooldown, scaling, `params`
3. **AbilityServer.luau:** Implement `Activate(context)` (and optionally `Deactivate`, `CanActivate`)
4. **AbilityClient.luau:** Implement `OnActivate(context)` (and optionally `OnDeactivate`, `OnInput`)
5. **Animations/VFX/SFX:** Add child folders with the ability's visual/audio assets
6. **Done.** `AbilityService` auto-discovers on startup via folder scan. Players see it in the ability management UI if their weapon's tags match.

### Adding a New Consumable

1. **Config:** Add template to the appropriate consumable config file (e.g. `Configs/Items/Consumables/Healing.luau`)
   - Set `templateId` to match the asset folder name exactly
2. **Asset folder:** Create a Folder in `ReplicatedStorage.Assets.Consumables/{templateId}`
3. **ConsumableConfig.luau:** Set `consumableId`, `useTime`, `cooldown`, `params` (consumable-specific tuning)
4. **ConsumableServer.luau:** Implement `Use(context)` (and optionally `Cancel`, `CanUse`)
5. **ConsumableClient.luau:** Implement `OnUseStart(context)` (and optionally `OnUseComplete`, `OnCancel`)
6. **Animations/VFX/SFX:** Add child folders with visual/audio assets
7. **Done.** `ConsumableService` auto-discovers on startup. `InventoryService` links the item to its behavior via `templateId` match.

---

## VII. Folder Naming Conventions

| Level | Naming Rule | Examples |
|-------|------------|---------|
| Category folders | PascalCase, plural if a group | `Weapons`, `Armor`, `Consumables`, `Materials` |
| Subcategory folders | PascalCase, plural | `Greatswords`, `Daggers`, `Healing`, `Buffs` |
| Item prefab names | PascalCase, matches `templateId` exactly | `IronGreatsword`, `Stiletto`, `HealthPotion` |
| Config module files | PascalCase, matches subcategory | `Greatswords.luau`, `Healing.luau` |

### Why PascalCase?

- Matches Roblox Instance naming conventions.
- Matches Luau module naming conventions in the existing codebase.
- Avoids issues with case-sensitive file systems (Rojo on macOS/Linux).

---

## VIII. Performance Considerations

### Startup Cost

- `ItemRegistry` requires all sub-modules on first access. With ~17 weapon subcategory files + armor + consumables + materials ≈ 26 modules. Each is a small table. Total initialization: negligible (<10ms).
- `AbilityService` scans `Assets/Abilities/` and requires each `AbilityConfig.luau`. With ~50–100 abilities, this is <50ms.
- `ConsumableService` scans `Assets/Consumables/` and requires each `ConsumableConfig.luau`. With ~20–50 consumables, this is <20ms.
- Server modules (`AbilityServer.luau`, `ConsumableServer.luau`) are lazy-loaded on first use, not on startup.

### Memory

Asset content in ReplicatedStorage is replicated to all clients. Keep complexity reasonable:
- Target: <20 parts per weapon prefab
- Armor: no 3D prefab required (no cosmetic effect); icon only
- Ability assets: lightweight (a few Animations, ParticleEmitters, Sounds). Scripts are ModuleScripts with negligible memory.
- Consumable assets: similar to abilities.
- Use MeshParts with baked textures rather than many small Part unions

### Network

ReplicatedStorage contents are sent to every client on join:
- ~200 item prefabs at ~20 parts each = ~4,000 parts
- ~100 ability assets at ~5 instances each = ~500 instances
- ~50 consumable assets at ~5 instances each = ~250 instances
- Total: ~4,750 instances — well within acceptable limits for a Roblox game.

If the item/ability count grows significantly (500+ items, 200+ abilities), consider lazy-loading or streaming: only replicate assets for items the player has encountered.

---

[← Item System](./item-system.md) | [← Modifier System](./modifier-system.md) | [← Data Persistence](./data-persistence.md)
