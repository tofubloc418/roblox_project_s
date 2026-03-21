# Ability & Consumable System

This document specifies how abilities and consumable items work as self-contained, scriptable assets. It covers the tag-based compatibility system for weapon abilities, how abilities and consumables live in ReplicatedStorage as clonable assets with their own scripts, and how ability loadouts are persisted per weapon class.

---

## I. Design Principles

1. **Tag-based compatibility.** Each weapon has exactly one **weapon tag** (its type). Abilities declare a list of weapon tags they are compatible with. The system matches them automatically — no hardcoded weapon/ability pairings.
2. **Self-contained assets.** Each ability and each consumable is a Roblox Instance (Folder) in ReplicatedStorage with its own scripts. When activated, the asset is cloned and its scripts run. Shared infrastructure (damage service, debounce, VFX) is accessed via `require`, not duplicated.
3. **Unique weapons are first-class.** A unique weapon gets its own tag (e.g. `"Unique_Moonveil"`). Abilities exclusive to that weapon list only that tag. Universal abilities list broad tags. The system handles both identically.
4. **Per-class ability presets.** When a player configures which 5 abilities they want on "Greatswords," that choice is saved. Any Greatsword they equip in the future loads those same 5 abilities. Unique weapons have their own preset key.
5. **No centralized behavior services.** There is no `MedService` or `MeleeService` that hardcodes item behaviors. Each consumable and each ability owns its own behavior script. Shared code is exposed as utility modules that individual scripts call into.

---

## II. Tag System

### What Is a Weapon Tag?

A **weapon tag** is a single string that identifies the type of a weapon for ability compatibility. Each `WeaponTemplate` has exactly one `weaponTag`.

Typical patterns:

- **Class weapons**: weaponTag is the subcategory name, e.g. `"Greatsword"`, `"Dagger"`, `"Staff"`, `"Bow"`.
- **Unique weapons**: weaponTag is a unique identifier, e.g. `"Unique_Moonveil"` or simply the templateId. The system will standardize this automatically.

Abilities never inspect categories or subcategories directly — they only look at the weapon's single `weaponTag`.

### How Weapons Get Their Tag

Each `WeaponTemplate` in the item config has a `weaponTag` field:

```lua
["IronGreatsword"] = {
    -- ... all base fields ...
    subcategory = "Greatsword",
    weaponTag = "Greatsword",
}

["Moonveil"] = {
    -- ... all base fields ...
    subcategory = "Unique",
    weaponTag = "Unique_Moonveil", -- or "Moonveil", set by convention
}
```

**Rules:**
- Each weapon has exactly **one** `weaponTag`.
- Class weapons use their subcategory name as the tag by default.
- Unique weapons get a unique tag (usually derived from their name/templateId).

### How Abilities Declare Compatibility

Each ability asset has a `compatibleTags` list. An ability is compatible with a weapon if the weapon's single `weaponTag` appears in the ability's `compatibleTags`.

```
Ability "HeavySlash":
    compatibleTags = { "Greatsword", "Greataxe", "GreatHammer" }
    -- Compatible with any weapon whose weaponTag is one of these

Ability "QuickStep":
    compatibleTags = { "Dagger" }
    -- Compatible with weapons whose weaponTag is "Dagger"

Ability "UniversalParry":
    compatibleTags = { "Greatsword", "Dagger", "Katana", "Axe", "Bow", "Staff", ... }
    -- Compatible with every listed weapon type

Ability "MoonveilBeam":
    compatibleTags = { "Unique_Moonveil" }
    -- Exclusive to Moonveil (or other weapons that deliberately share this tag)
```

### Compatibility Check (pseudocode)

```lua
function isAbilityCompatible(abilityTags: {string}, weaponTag: string): boolean
    for _, abilityTag in abilityTags do
        if abilityTag == weaponTag then
            return true
        end
    end
    return false
end
```

At scale (hundreds of abilities × dozens of tags), this can be optimized with a Set lookup, but the naive approach is fine for <100 abilities.

---

## III. Ability Assets in ReplicatedStorage

### What an Ability Asset Is

An ability asset is a **Folder** in `ReplicatedStorage.Assets.Abilities` that contains everything needed to run the ability: metadata, scripts, animations, VFX, sounds. When a player equips a weapon and the ability system populates their slots, the relevant ability folders are referenced (not cloned to the character — scripts run from shared modules that receive the asset as context).

### Folder Structure

```
ReplicatedStorage/
└── Assets/
    └── Abilities/
        ├── HeavySlash/                      (Folder)
        │   ├── AbilityConfig.luau           (ModuleScript — metadata + stats)
        │   ├── AbilityServer.luau           (ModuleScript — server-side logic)
        │   ├── AbilityClient.luau           (ModuleScript — client-side visuals/input)
        │   ├── Animations/                  (Folder)
        │   │   ├── Windup     (Animation)
        │   │   └── Swing      (Animation)
        │   ├── VFX/                         (Folder)
        │   │   └── SlashTrail (ParticleEmitter / Beam)
        │   └── SFX/                         (Folder)
        │       └── Impact     (Sound)
        │
        ├── QuickStep/
        │   ├── AbilityConfig.luau
        │   ├── AbilityServer.luau
        │   ├── AbilityClient.luau
        │   └── ...
        │
        ├── MoonveilBeam/
        │   ├── AbilityConfig.luau
        │   ├── AbilityServer.luau
        │   ├── AbilityClient.luau
        │   └── ...
        │
        └── UniversalParry/
            ├── AbilityConfig.luau
            ├── AbilityServer.luau
            ├── AbilityClient.luau
            └── ...
```

### AbilityConfig.luau

The metadata module. This is a ModuleScript that returns a table with the ability's identity, compatibility, costs, and tuning values. It does NOT contain behavior logic.

```
AbilityConfig {
    abilityId       : string           -- Unique key, matches the folder name
    displayName     : string           -- Shown in UI
    description     : string           -- Tooltip text
    iconId          : string           -- rbxassetid:// for the ability icon
    isUltimate      : boolean          -- Whether this counts toward the 1-ultimate limit

    -- Compatibility
    compatibleTags  : {string}         -- List of weapon tags this ability works with

    -- Cost & cooldown
    energyCost      : number?          -- Energy consumed on activation
    manaCost        : number?          -- Mana consumed on activation
    cooldown        : number           -- Seconds before the ability can be used again
    charges         : number?          -- Max charges (nil = no charge system, just cooldown)
    chargeTime      : number?          -- Seconds per charge recovery

    -- Scaling
    adScaling       : number?          -- Multiplier on Total AD for this ability's damage
    mdScaling       : number?          -- Multiplier on Total MD
    damageType      : "Physical" | "Magic" | "True" | nil

    -- Tuning (ability-specific, read by its own scripts)
    params          : {[string]: any}  -- Arbitrary key/value pairs for ability-specific tuning
}
```

The `params` table is intentionally open-ended. Each ability's scripts know what keys to expect. Examples:
- `HeavySlash`: `{ chargeTime = 1.2, hitMultiplier = 2.5, superArmorFrames = 10 }`
- `QuickStep`: `{ dashDistance = 15, iFrames = 0.3, followupWindow = 0.5 }`
- `MoonveilBeam`: `{ beamLength = 40, beamWidth = 3, tickDamage = 20 }`

### AbilityServer.luau

A ModuleScript that exports the server-side behavior. The ability runtime calls methods on this module when the ability activates.

```
Required interface:

AbilityServer.Activate(context: AbilityContext) -> ()
AbilityServer.Deactivate(context: AbilityContext) -> ()   -- Optional: cleanup
AbilityServer.CanActivate(context: AbilityContext) -> boolean  -- Optional: custom validation
```

The `AbilityContext` is provided by the ability runtime system:

```
AbilityContext {
    player          : Player
    character       : Model
    humanoid        : Humanoid
    weaponTemplate  : WeaponTemplate       -- The equipped weapon's template data
    weaponInstance  : ItemInstance          -- The equipped weapon's instance data
    abilityConfig   : AbilityConfig        -- This ability's config
    abilityAsset    : Folder               -- The ability's asset folder (for animations, VFX, SFX)
    damageService   : DamageService        -- Reference to the universal damage system
    statsService    : StatsService         -- Reference to stats for scaling calculations
    debounce        : DebounceHelper       -- Shared debounce utility
}
```

This context gives each ability script access to everything it needs without requiring it to set up its own references. The ability script focuses purely on behavior.

### AbilityClient.luau

A ModuleScript that exports client-side visual/input behavior. Called by the client-side ability runtime.

```
Required interface:

AbilityClient.OnActivate(context: ClientAbilityContext) -> ()
AbilityClient.OnDeactivate(context: ClientAbilityContext) -> ()  -- Optional
AbilityClient.OnInput(context: ClientAbilityContext, input: InputObject) -> ()  -- Optional: for charged/held abilities
```

Client scripts handle: animation playback, VFX spawning, camera shake, UI indicators (charge bars, range indicators). They do NOT handle damage, hit detection, or state mutation — that is server-only.

---

## IV. Ability Runtime System

The runtime system is the framework that manages ability slots, validates inputs, fires ability scripts, and handles cooldowns/charges.

### Server: AbilityService

```
AbilityService:Initialize()
AbilityService:EquipAbilities(player, weaponSlot: "Weapon1" | "Weapon2")
AbilityService:UnequipAbilities(player, weaponSlot)
AbilityService:ActivateAbility(player, slotIndex: number)
AbilityService:GetCompatibleAbilities(weaponTemplate: WeaponTemplate) -> {AbilityConfig}
AbilityService:GetAbilityConfig(abilityId: string) -> AbilityConfig?
AbilityService:GetAbilityAsset(abilityId: string) -> Folder?
```

### Activation Flow

```
1. Client presses ability key (1–5)
2. Client fires RequestAbility remote with { weaponSlot, abilitySlotIndex }
3. AbilityService validates:
   a. Player has a weapon in that slot
   b. Ability slot is populated
   c. Ability is not on cooldown
   d. Player has enough energy/mana
   e. Ability's CanActivate returns true (if defined)
4. AbilityService deducts energy/mana
5. AbilityService calls AbilityServer.Activate(context)
6. AbilityService starts cooldown timer
7. AbilityService fires AbilityActivated remote to all nearby clients
8. Client-side runtime calls AbilityClient.OnActivate(context) for VFX/animations
```

### Ability Registry

On server startup, `AbilityService` scans `ReplicatedStorage.Assets.Abilities` and requires every `AbilityConfig.luau` it finds. This builds a lookup table:

```
_abilityRegistry[abilityId] = {
    config = AbilityConfig,
    asset = Folder,
    serverModule = AbilityServer (lazy-loaded on first use),
}
```

The scan is automatic — adding a new ability folder with an `AbilityConfig.luau` is all that's needed for discovery.

---

## V. Consumable Assets in ReplicatedStorage

### Design: Every Consumable Has Its Own Scripts

The old approach (centralized `MedService` + `MedConfigs`) is deprecated. Each consumable item is a self-contained asset with its own behavior, just like abilities.

### Folder Structure

```
ReplicatedStorage/
└── Assets/
    └── Consumables/
        ├── Bandage/                         (Folder)
        │   ├── ConsumableConfig.luau        (ModuleScript — metadata + stats)
        │   ├── ConsumableServer.luau        (ModuleScript — server behavior)
        │   ├── ConsumableClient.luau        (ModuleScript — client visuals)
        │   ├── Animations/
        │   │   └── UseAnim    (Animation)
        │   └── SFX/
        │       └── Wrap       (Sound)
        │
        ├── Medkit/
        │   ├── ConsumableConfig.luau
        │   ├── ConsumableServer.luau
        │   ├── ConsumableClient.luau
        │   └── ...
        │
        ├── FragGrenade/
        │   ├── ConsumableConfig.luau
        │   ├── ConsumableServer.luau
        │   ├── ConsumableClient.luau
        │   ├── Projectile/              (Model — the grenade mesh)
        │   └── VFX/
        │       └── Explosion (ParticleEmitter)
        │
        └── StrengthElixir/
            ├── ConsumableConfig.luau
            ├── ConsumableServer.luau
            ├── ConsumableClient.luau
            └── ...
```

### ConsumableConfig.luau

```
ConsumableConfig {
    consumableId    : string           -- Matches the folder name AND the item templateId
    displayName     : string
    description     : string
    iconId          : string

    -- Usage constraints
    useTime         : number           -- Channel time in seconds
    cooldown        : number?
    usableInCombat  : boolean
    useWalkSpeed    : number?          -- Temporary speed while channeling (nil = no change)

    -- Tuning (consumable-specific)
    params          : {[string]: any}  -- Open-ended, read by the consumable's own scripts
}
```

Example `params` for different consumables:
- `Bandage`: `{ healAmount = 15, mode = "Instant" }`
- `Medkit`: `{ healAmount = 100, mode = "Instant" }`
- `FragGrenade`: `{ damage = 80, damageType = "Physical", aoeRadius = 12, fuseTime = 2.5 }`
- `StrengthElixir`: `{ duration = 30, statBoosts = { { stat = "MaxHP", op = "Flat", value = 50 } } }`

### ConsumableServer.luau / ConsumableClient.luau

Same interface pattern as abilities:

```
ConsumableServer.Use(context: ConsumableContext) -> boolean
ConsumableServer.Cancel(context: ConsumableContext) -> ()       -- Optional: interrupt handling
ConsumableServer.CanUse(context: ConsumableContext) -> boolean  -- Optional: custom validation

ConsumableClient.OnUseStart(context: ClientConsumableContext) -> ()
ConsumableClient.OnUseComplete(context: ClientConsumableContext) -> ()
ConsumableClient.OnCancel(context: ClientConsumableContext) -> ()
```

### ConsumableContext

```
ConsumableContext {
    player            : Player
    character         : Model
    humanoid          : Humanoid
    consumableConfig  : ConsumableConfig
    consumableAsset   : Folder
    damageService     : DamageService
    statsService      : StatsService
    inventoryService  : InventoryService   -- To decrement stack count
    debounce          : DebounceHelper
}
```

### Consumable Registry

Like abilities, `ConsumableService` scans `ReplicatedStorage.Assets.Consumables` on startup and builds a registry:

```
_consumableRegistry[consumableId] = {
    config = ConsumableConfig,
    asset = Folder,
    serverModule = ConsumableServer (lazy-loaded),
}
```

### Linking to Item Templates

A consumable item in `ItemRegistry` references its behavior asset through `templateId`. The `templateId` in the item config MUST match the folder name in `Assets/Consumables/`. This is how the system connects the inventory item to its runtime behavior:

```
Player uses quick-slot item with templateId = "Bandage"
  → ConsumableService looks up _consumableRegistry["Bandage"]
  → Calls ConsumableServer.Use(context)
```

---

## VI. Shared Utilities (the "Codebase Advantage")

Individual ability and consumable scripts should NOT reinvent common functionality. These shared modules live in `ReplicatedStorage.Modules` (or `ServerScriptService` for server-only code) and are `require`'d by individual scripts:

| Module | Location | Purpose |
|--------|----------|---------|
| `DamageService` | Server | The universal 6-step damage pipeline. Abilities call `DamageService:DealDamage(attacker, target, params)`. |
| `StatsService` | Server | Read/modify player stats. Abilities check energy, apply buffs. |
| `HitDetection` | Server | Shared raycasting, box overlap, sphere overlap utilities. Abilities describe hit shapes; this module executes them. |
| `DebounceHelper` | Shared | Prevents double-activation. Used by both abilities and consumables. |
| `AnimationHelper` | Client | Load and play animations from an asset's `Animations/` folder. |
| `VFXHelper` | Client | Spawn, attach, and clean up particle emitters/beams from `VFX/` folder. |
| `SFXHelper` | Client | Play sounds from `SFX/` folder. |
| `ProjectileService` | Server | Spawn and simulate projectiles (for ranged abilities, throwables). |
| `StatusEffectService` | Server | Apply/remove debuffs (burn, freeze, stun, etc.) with duration tracking. |

The ability/consumable scripts focus on **what** happens (sequence of events, timing, conditions), while shared modules handle **how** (damage math, physics, VFX rendering).

---

## VII. Unique Weapons — Detailed Design

### What Makes a Weapon "Unique"

A unique weapon is a weapon that does not cleanly fit into any existing weapon class. It may:
- Have a completely novel moveset
- Combine mechanics from multiple classes
- Have abilities that only work with it
- Have an animation set not shared by any other weapon

### Subcategory for Unique Weapons

Unique weapons use `subcategory = "Unique"` in their template. They are stored in a separate config file and asset folder:

```
Configs/Items/Weapons/UniqueWeapons.luau
Assets/Items/Weapons/Unique/Moonveil/
Assets/Items/Weapons/Unique/RiversOfBlood/
```

### How Unique-Only Abilities Work

A unique weapon gets a dedicated weaponTag like `"Unique_Moonveil"`. An ability exclusive to that weapon sets:

```lua
compatibleTags = { "Unique_Moonveil" }
```

Since no other weapon will ever use that tag (unless you intentionally share it), the ability is exclusive to that weapon type.

### Unique Weapon Animation Sets

Unique weapons may define their own `animationSet` string (e.g. `"Moonveil"` instead of `"Katana"`). The animation system loads from `Assets/Items/Weapons/Unique/Moonveil/Animations/` for basic attacks, while ability animations come from each ability's own `Animations/` folder.

---

## VIII. Ability Preset Persistence

### The Problem

Players configure 5 abilities per weapon. But they may own many weapons of the same class. When they equip a different Greatsword, they expect the same 5 Greatsword abilities to be there.

### The Solution: Per-Class Ability Presets

The player's saved data includes an `abilityPresets` table, keyed by the **preset key** of the weapon. For class weapons, the preset key is the subcategory (e.g. `"Greatsword"`). For unique weapons, the preset key is `"Unique_{templateId}"` (e.g. `"Unique_Moonveil"`).

### WeaponTemplate Field

```
WeaponTemplate {
    -- ... existing fields ...
    tags              : {string}
    abilityPresetKey  : string     -- The key used for ability preset storage
}
```

For class weapons: `abilityPresetKey = "Greatsword"` (matches subcategory).
For unique weapons: `abilityPresetKey = "Unique_Moonveil"` (unique per weapon).

### Preset Data Structure

```
AbilityPreset {
    [slotIndex: number]: AbilitySlotPreset?   -- slots 1–5
}

AbilitySlotPreset {
    abilityId   : string
    isUltimate  : boolean
}
```

### How It Works

```
1. Player equips IronGreatsword (abilityPresetKey = "Greatsword")
2. System looks up abilityPresets["Greatsword"]
3. If found: populates weapon's 5 ability slots from the preset
4. If not found: weapon has empty ability slots (player must configure)

5. Player opens ability management UI and assigns abilities
6. System validates each ability is compatible with the weapon's `weaponTag`
7. System saves the new configuration to abilityPresets["Greatsword"]
8. Player later equips a different Greatsword → same preset loads
```

### Validation on Load

When loading a preset, each ability is re-validated against the current weapon's `weaponTag`:
- If an ability is no longer compatible (e.g. the ability was updated), it is removed from that slot.
- If the ability no longer exists, it is removed.
- This prevents stale presets from causing errors.

### Edge Case: Unique Weapons vs Class Weapons

A unique weapon like Moonveil has `abilityPresetKey = "Unique_Moonveil"`, NOT `"Katana"`. Even if both a Katana class weapon and Moonveil use abilities that list `"Katana"` or `"Unique_Moonveil"` in their `compatibleTags`, they have **separate** presets. This is intentional: the player may want different ability layouts on their generic Katana vs their Moonveil.

---

## IX. Persistence Schema Additions

### Addition to PlayerData

```
PlayerData {
    -- ... existing fields ...
    abilityPresets  : AbilityPresetsData
}
```

### AbilityPresetsData

```
AbilityPresetsData {
    [presetKey: string]: SerializedPreset
}

SerializedPreset {
    [slotIndex: number]: SerializedPresetSlot?
}

SerializedPresetSlot {
    aid  : string      -- abilityId
    ult  : boolean?    -- isUltimate (omitted if false)
}
```

### Example Serialized Data

```lua
abilityPresets = {
    ["Greatsword"] = {
        [1] = { aid = "HeavySlash" },
        [2] = { aid = "WarCry" },
        [3] = { aid = "Whirlwind", ult = true },
        [4] = { aid = "UniversalParry" },
        -- slot 5 empty (nil)
    },
    ["Dagger"] = {
        [1] = { aid = "QuickStep" },
        [2] = { aid = "Backstab" },
        [3] = { aid = "PoisonCoat" },
    },
    ["Unique_Moonveil"] = {
        [1] = { aid = "MoonveilBeam", ult = true },
        [2] = { aid = "QuickStep" },
        [3] = { aid = "UniversalParry" },
    },
}
```

### Size Impact

Each preset is ~50–150 bytes. With ~20 weapon classes + a handful of unique weapons ≈ 25 presets max → ~3 KB. Negligible impact on DataStore budget.

---

## X. Ability Management UI

### Where It Lives

The ability management screen is accessed from the **loadout screen's equipment panel**. When the player clicks on a weapon card's ability slot area, a sub-screen opens showing:

1. The weapon's 5 ability slots (top)
2. A scrollable grid of all compatible abilities (bottom)

### Filtering

The grid shows only abilities whose `compatibleTags` contain the equipped weapon's `weaponTag`. Incompatible abilities are hidden entirely (not greyed out — to avoid clutter).

### Ultimate Limit

The UI enforces the 1-ultimate limit:
- If an ultimate is already equipped in one slot and the player tries to assign another, the old one is unslotted.
- Alternatively, the UI can grey out other ultimate abilities once one is equipped and show a tooltip.

### Save Behavior

When the player changes an ability assignment (Settings Abilities tab drag-and-drop, swaps):
1. Client builds one or more operations `{ presetKey, slotIndex, abilityId? }` and invokes `RequestApplyAbilityPresetOps` (RemoteFunction).
2. Server applies all operations to in-memory working presets, then validates: each ability must exist and `compatibleTags` must include that preset key; at most one ultimate per preset.
3. If validation fails, nothing is written and the client shows the returned `error` string. If it succeeds, server commits each affected preset via DataService and replication updates the client.

---

## XI. Remotes (Ability & Consumable)

### Added to InventoryRemotes (or a new AbilityRemotes folder)

| Remote | Direction | Payload | Purpose |
|--------|-----------|---------|---------|
| `RequestAbility` | Client → Server | `{ weaponSlot, abilitySlotIndex }` | Activate an ability |
| `AbilityActivated` | Server → Clients | `{ playerId, abilityId, weaponSlot }` | Notify nearby clients for VFX |
| `AbilityCooldownSync` | Server → Client | `{ abilityId, remainingCooldown }` | Sync cooldown state |
| `RequestApplyAbilityPresetOps` | Client → Server (invoke) | `{ { presetKey, slotIndex, abilityId? }, ... }` | Atomic multi-op apply; return `{ ok: bool, error?: string }` |
| `SyncAbilityPresets` | Server → Client | `{ presets: AbilityPresetsData }` | Full preset sync on join |
| `RequestUseConsumable` | Client → Server | `{ quickSlot }` | Use a consumable from quick bar |
| `ConsumableActivated` | Server → Clients | `{ playerId, consumableId }` | Notify nearby clients for VFX |

---

## XII. What Gets Deprecated

### Modules to Remove

| Module | Reason |
|--------|--------|
| `Configs/Weapons/MeleeConfigs.luau` | Combat behavior moves to per-weapon `hitShape`/`hitSize`/`attackSequence` in `WeaponTemplate` + per-ability scripts in `Assets/Abilities/`. Fists become a built-in fallback handled by the weapon system, not a config. |
| `Configs/Med/MedConfigs.luau` | Consumable behavior moves to per-item scripts in `Assets/Consumables/`. |
| `server/Weapons/MeleeService.luau` | Replaced by `AbilityService` + individual ability scripts. Basic attack behavior will be handled by a `BasicAttackService` that reads from `WeaponTemplate`. |
| `server/Med/MedService.luau` | Replaced by `ConsumableService` + individual consumable scripts. |
| `client/Weapons/MeleeController.client.luau` | Client-side input moves to the ability runtime system. |
| `client/Med/MedController.client.luau` | Client-side input moves to the consumable runtime system. |

These modules are NOT removed yet — they are functional and will continue working until the new systems are built. They are listed here as the migration target.

---

## XIII. Integration Summary

```
                              ┌─────────────────────────────┐
                              │     ReplicatedStorage        │
                              │  ┌─────────────────────────┐ │
                              │  │ Assets/Abilities/       │ │
                              │  │   HeavySlash/           │ │
                              │  │   QuickStep/            │ │
                              │  │   MoonveilBeam/         │ │
                              │  ├─────────────────────────┤ │
                              │  │ Assets/Consumables/     │ │
                              │  │   Bandage/              │ │
                              │  │   FragGrenade/          │ │
                              │  ├─────────────────────────┤ │
                              │  │ Configs/Items/          │ │
                              │  │   (weapon templates     │ │
                              │  │    with tags field)     │ │
                              │  └─────────────────────────┘ │
                              └──────────┬──────────────────┘
                                         │
              ┌──────────────────────────┼──────────────────────────┐
              │                          │                          │
     AbilityService              ConsumableService          ItemRegistry
   (scans Abilities/)          (scans Consumables/)       (scans Configs/)
              │                          │                          │
   ┌──────────┴─────────┐    ┌──────────┴──────────┐              │
   │ AbilityServer.lua  │    │ ConsumableServer.lua │              │
   │ (per-ability logic) │    │ (per-consumable)     │              │
   └──────────┬─────────┘    └──────────┬──────────┘              │
              │                          │                          │
              ├──── DamageService ◄──────┤                          │
              ├──── StatsService  ◄──────┤                          │
              ├──── HitDetection  ◄──────┘                          │
              └──── StatusEffects                                   │
                                                                    │
                                              Tag matching ◄────────┘
                                        (weapon.weaponTag ∈ ability.compatibleTags)
                                                    │
                                                    ▼
                                           Ability Presets
                                        (per-class, persisted)
```

---

[← Item System](./item-system.md) | [← Modifier System](./modifier-system.md) | [← Data Persistence](./data-persistence.md) | [← ReplicatedStorage Layout](./replicated-storage.md)
