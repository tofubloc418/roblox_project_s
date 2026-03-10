# Item & Weapon System

This document is the master specification for the item system in Project S. It defines item taxonomy, data schemas, weapon mechanics, and how every module fits together. All other system docs (modifiers, persistence, ReplicatedStorage layout) reference the types and concepts defined here.

---

## I. Design Principles

1. **Template + Instance separation.** Every item type has exactly one **template** (shared, immutable definition). Every item a player owns is an **instance** (unique copy with its own level, modifiers, durability, etc.).
2. **Config-driven stats, script-driven behavior.** Item stats and base data live in Luau config modules. Complex behaviors (abilities, consumables) live as self-contained script assets in ReplicatedStorage. Visual prefabs exist only for 3D rendering.
3. **Category → Subcategory → TemplateId.** Items are organized in a strict three-level hierarchy so the RNG system can efficiently sample "give me any Melee weapon" or "give me a Greatsword specifically."
4. **Modifier-ready from day one.** Every item instance carries a modifier list. The modifier system is a separate, pluggable module that generates and evaluates modifiers without touching item logic.
5. **Persistence-friendly serialization.** Every item instance can round-trip to a plain Lua table (no metatables, no Instance references) for DataStore storage.

---

## II. Item Taxonomy

### Categories

Every item belongs to exactly one top-level category. Categories determine which equipment slot (if any) an item can occupy, what config module governs its behavior, and how it appears in the UI.

| Category | Equippable? | Slot(s) | Stackable? | Description |
|----------|-------------|---------|------------|-------------|
| **Weapon** | Yes | Weapon1, Weapon2 | No | Melee and ranged weapons. |
| **Armor** | Yes | Armor | No | Defensive gear with resistances. Arc Raiders–style: one armor slot. |
| **Backpack** | Yes | Backpack | No | Determines inventory capacity. |
| **Consumable** | Yes (quick-use) | QuickUse slots | Yes | Healing items, buff potions, throwables. |
| **Material** | No | — | Yes | Crafting resources, mob drops, ores. |
| **Currency** | No | — | Yes (special) | Gold, tokens. Tracked as a number, not individual stacks. |
| **KeyItem** | No | — | No | Quest items, keys, progression tokens. |

**Arc Raiders–style loadout:** At any given time, players can equip at most **1 Backpack**, **1 Armor**, and **2 Weapons**.

### Weapon Subcategories

Weapons are divided into **class weapons** (standard subcategories) and **unique weapons** (one-of-a-kind items that may not fit any class).

#### Class Weapons

| Subcategory | Hands | Damage Type | Typical Scaling | Examples |
|-------------|-------|-------------|-----------------|----------|
| **Dagger** | 1H | Physical | Dex | Stiletto, Parrying Dagger |
| **StraightSword** | 1H | Physical | Str/Dex | Longsword, Broadsword |
| **Greatsword** | 2H | Physical | Str | Claymore, Zweihander |
| **Katana** | 1H/2H | Physical | Dex | Uchigatana, Nagakiba |
| **CurvedSword** | 1H | Physical | Dex | Scimitar, Falchion |
| **Axe** | 1H | Physical | Str | Hand Axe, Battle Axe |
| **Greataxe** | 2H | Physical | Str | Greataxe, Crescent Axe |
| **Hammer** | 1H | Physical | Str | Mace, Morning Star |
| **GreatHammer** | 2H | Physical | Str | Great Mace, Giant-Crusher |
| **Spear** | 1H/2H | Physical | Dex/Str | Pike, Partisan |
| **Halberd** | 2H | Physical | Str/Dex | Halberd, Glaive |
| **Fist** | 1H | Physical | Str/Dex | Caestus, Claws |
| **Whip** | 1H | Physical | Dex | Whip, Thorned Whip |
| **Staff** | 1H/2H | Magic | Int | Sorcerer Staff, Crystal Staff |
| **Seal** | 1H | Magic | Int | Sacred Seal, Finger Seal |
| **Bow** | 2H | Physical | Dex | Shortbow, Longbow |
| **Crossbow** | 1H/2H | Physical | Str | Light Crossbow, Heavy Crossbow |

#### Unique Weapons

Unique weapons use `subcategory = "Unique"` and have a dedicated weapon tag (e.g. `"Unique_{templateId}"`) that enables weapon-exclusive abilities. They do **not** carry multiple tags — their single `weaponTag` is what abilities match against. See [ability-system.md](./ability-system.md) for the full tag system.

### Consumable Subcategories

| Subcategory | Usable in Combat? | Notes |
|-------------|-------------------|-------|
| **Healing** | Yes | Bandages, medkits, flasks |
| **Buff** | Yes | Temporary stat boosts |
| **Throwable** | Yes | Grenades, firebombs |
| **Food** | Safezone only | Long-duration buffs, out-of-combat healing |

---

## III. Item Template Schema

An **item template** is the immutable definition of an item type. It lives in a config module and is shared by every instance of that item.

### Base Fields (all items)

```
ItemTemplate {
    templateId  : string        -- Unique key, e.g. "Longsword", "HealthPotion"
    displayName : string        -- Shown in UI, e.g. "Iron Longsword"
    description : string        -- Flavor/tooltip text
    category    : Category      -- "Weapon" | "Armor" | "Backpack" | "Consumable" | "Material" | "Currency" | "KeyItem"
    subcategory : string        -- e.g. "StraightSword", "Head", "Healing"
    rarity      : Rarity        -- "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
    iconId      : string        -- rbxassetid:// for the inventory icon
    weight      : number        -- Inventory weight (affects carry capacity)
    stackMax    : number        -- Max per stack (1 for non-stackable equipment)
    sellValue   : number        -- Base currency value when sold to NPC
    levelReq    : number?       -- Minimum player level to equip (nil = no requirement)
    canDrop     : boolean       -- Whether this item can be dropped into the world
    canTrade    : boolean       -- Whether this item can be traded to another player
}
```

### Weapon Extension

Weapons add scaling, combat stats, and ability slot configuration on top of the base template.

```
WeaponTemplate extends ItemTemplate {
    -- Damage
    baseAD            : number     -- Base physical attack damage
    baseMD            : number     -- Base magic attack damage
    basicAttackType   : "Physical" | "Magic"

    -- Attribute scaling (multipliers applied to player attributes)
    strengthScaling   : number     -- 0.0–2.0+  (S/A/B/C/D/E tier implied by value)
    dexterityScaling  : number
    intelligenceScaling : number

    -- Defense (when blocking with this weapon)
    blockPower        : number     -- Flat damage reduction while blocking
    parryMultiplier   : number     -- Multiplier on blockPower during parry window

    -- Combat behavior
    hands             : 1 | 2      -- 1H or 2H
    attackSpeed       : number     -- Attacks per second (base, before haste)
    range             : number     -- Effective range in studs
    staminaCost       : number     -- Energy per swing

    -- Hit detection (server-side, for basic attacks)
    hitShape          : "Box" | "Sphere" | "Cone"
    hitSize           : Vector3?   -- For Box
    hitRadius         : number?    -- For Sphere/Cone
    hitOffset         : Vector3    -- Relative to HumanoidRootPart
    hitAngle          : number?    -- For Cone (degrees)

    -- Animation set
    animationSet      : string     -- Key into AnimationSets config, e.g. "StraightSword"
    attackSequence    : {string}   -- Ordered list of attack animation names

    -- Weapon type & abilities (see ability-system.md)
    weaponTag         : string     -- Single weapon type tag, e.g. "Greatsword" or "Unique_Moonveil"
    abilityPresetKey  : string     -- Key for ability preset storage (usually matches subcategory or "Unique_{id}")
    maxAbilitySlots   : number     -- Typically 5
    maxUltimateSlots  : number     -- Typically 1
    innateAbility     : string?    -- Built-in weapon art (nil = none)

    -- Upgrade
    maxLevel          : number     -- Maximum reinforcement level (e.g. 10 or 25)
    levelScaling      : number     -- Multiplier per level for base damage (e.g. 0.05 = +5% per level)

    -- Modifier pools
    modifierPoolId    : string     -- Key into ModifierPools config for RNG bonus stats
    maxModifiers      : number     -- Max number of bonus modifiers this item can roll
}
```

### Armor Extension

```
ArmorTemplate extends ItemTemplate {
    armor             : number     -- Flat damage reduction
    physicalResist    : number     -- 0.0–1.0
    magicResist       : number     -- 0.0–1.0
    poise             : number     -- Resistance to stagger
    weight            : number     -- Heavier armor = slower movement
    statBonuses       : {StatBonus}? -- Intrinsic stat bonuses (e.g. +5 Vitality)
    modifierPoolId    : string
    maxModifiers      : number
    maxLevel          : number
    levelScaling      : number
}
```

**Armor behavior:**
- **No cosmetic effect.** Equipped armor does not change the player's character appearance. The character model stays the same.
- **Equip/unequip animation.** When the player equips or unequips armor, a "suiting up" / "suiting down" animation plays on the character. This is purely visual feedback; no mesh or cosmetic changes are applied.

### Backpack Extension

```
BackpackTemplate extends ItemTemplate {
    inventorySlots    : number     -- Number of inventory slots this backpack provides
    modifierPoolId    : string
    maxModifiers      : number
}
```

### Consumable Extension

Consumable behavior is NOT defined in the item template. Each consumable has its own self-contained scripts in `ReplicatedStorage.Assets.Consumables/{templateId}/`. The template only stores identity and basic constraints; all effect logic lives in the asset's `ConsumableServer.luau`. See [ability-system.md](./ability-system.md#v-consumable-assets-in-replicatedstorage) for the full consumable asset spec.

```
ConsumableTemplate extends ItemTemplate {
    useTime           : number     -- Channel time in seconds
    cooldown          : number?    -- Cooldown between uses
    usableInCombat    : boolean
    useWalkSpeed      : number?    -- Temporary speed while channeling (nil = no change)
}
```

The `templateId` of a consumable MUST match the folder name in `Assets/Consumables/`. This is how the `ConsumableService` links the inventory item to its runtime behavior.

---

## IV. Item Instance Schema

An **item instance** is a specific item a player owns. It wraps a template reference with per-instance mutable state.

```
ItemInstance {
    instanceId    : string           -- Globally unique ID (UUID or incrementing)
    templateId    : string           -- References ItemTemplate.templateId
    count         : number           -- Stack count (1 for non-stackable)
    level         : number           -- Upgrade/reinforcement level (starts at 0)
    modifiers     : {ItemModifier}   -- Rolled bonus stats (see modifier-system.md)
    durability    : number?          -- Current durability (nil = indestructible)
    customData    : {[string]: any}? -- Reserved for future per-instance state
}
```

**Note on abilities:** Abilities are NOT stored per-item-instance. They are stored as **ability presets** keyed by weapon class (or unique weapon ID). When a weapon is equipped, the system looks up the preset for that weapon's `abilityPresetKey` and populates the ability slots. See [ability-system.md](./ability-system.md#viii-ability-preset-persistence) for details.

```
-- REMOVED from ItemInstance:
-- abilities : {AbilitySlot}?   -- Now handled by abilityPresets in PlayerData
```

### Instance ID Generation

Every item instance gets a unique `instanceId` when created. Format: `"{templateId}_{timestamp}_{random4}"` (e.g. `"Longsword_1709337600_a3f2"`). This ID is the primary key in persistence and is never reused.

---

## V. Config Module Organization

All item templates live in config modules under `ReplicatedStorage.Configs.Items`. Each module exports a flat dictionary keyed by `templateId`.

```
Configs/
├── Items/
│   ├── ItemEnums.luau              -- Category, Subcategory, Rarity enums
│   ├── ItemRegistry.luau           -- Aggregates all templates; provides lookup API
│   ├── Weapons/
│   │   ├── Daggers.luau            -- All dagger templates
│   │   ├── StraightSwords.luau     -- All straight sword templates
│   │   ├── Greatswords.luau        -- All greatsword templates
│   │   ├── Katanas.luau
│   │   ├── Axes.luau
│   │   ├── Greataxes.luau
│   │   ├── Hammers.luau
│   │   ├── GreatHammers.luau
│   │   ├── Spears.luau
│   │   ├── Halberds.luau
│   │   ├── FistWeapons.luau
│   │   ├── Whips.luau
│   │   ├── Staves.luau
│   │   ├── Seals.luau
│   │   ├── Bows.luau
│   │   ├── Crossbows.luau
│   │   └── UniqueWeapons.luau     -- All unique weapon templates
│   ├── Armor/
│   │   └── Armor.luau
│   ├── Backpacks/
│   │   └── Backpacks.luau
│   ├── Consumables/
│   │   ├── Healing.luau
│   │   ├── Buffs.luau
│   │   ├── Throwables.luau
│   │   └── Food.luau
│   ├── Materials/
│   │   └── Materials.luau
│   └── KeyItems/
│       └── KeyItems.luau
```

### ItemRegistry API

`ItemRegistry` is the single access point for looking up any item template. It auto-requires all sub-modules and builds lookup tables.

```
ItemRegistry.GetTemplate(templateId: string) -> ItemTemplate?
ItemRegistry.GetTemplatesByCategory(category: string) -> {ItemTemplate}
ItemRegistry.GetTemplatesBySubcategory(subcategory: string) -> {ItemTemplate}
ItemRegistry.GetTemplatesByRarity(rarity: string) -> {ItemTemplate}
ItemRegistry.GetWeaponTemplates() -> {WeaponTemplate}
ItemRegistry.GetRandomTemplate(filter: FilterOptions?) -> ItemTemplate?
ItemRegistry.TemplateExists(templateId: string) -> boolean
```

**FilterOptions** allows the loot/RNG system to query subsets:

```
FilterOptions {
    category?    : string | {string}
    subcategory? : string | {string}
    rarity?      : string | {string}
    minLevel?    : number
    maxLevel?    : number
}
```

### ItemEnums

Centralized enum tables so all modules reference the same strings:

```
ItemEnums.Category    = { Weapon, Armor, Backpack, Consumable, Material, Currency, KeyItem }
ItemEnums.Subcategory = { Dagger, StraightSword, Greatsword, ..., Unique, ..., Healing, Buff, Throwable, ... }
ItemEnums.Rarity      = { Common, Uncommon, Rare, Epic, Legendary }
ItemEnums.DamageType  = { Physical, Magic, True }
ItemEnums.Hands       = { OneHanded = 1, TwoHanded = 2 }
ItemEnums.HitShape    = { Box, Sphere, Cone }
ItemEnums.WeaponTag   = { Greatsword, Dagger, Katana, Axe, Bow, Staff, ..., Unique_Moonveil, Unique_RiversOfBlood, ... }
```

Note: `WeaponTag` values are conventionally aligned with subcategory names for class weapons (e.g. `"Greatsword"`, `"Dagger"`). Unique weapon tags (`"Unique_Moonveil"`, etc.) are dynamic strings derived from templateIds. The enum table lists commonly used tags for autocomplete and documentation purposes.

---

## VI. How Adding a New Item Works

### Step 1: Choose the right config file

A new Greatsword goes in `Configs/Items/Weapons/Greatswords.luau`. A new healing potion goes in `Configs/Items/Consumables/Healing.luau`.

### Step 2: Add the template entry

Add a new keyed entry to the module's table. All required fields for the category must be present. Example for a weapon:

```lua
["IronGreatsword"] = {
    templateId = "IronGreatsword",
    displayName = "Iron Greatsword",
    description = "A sturdy greatsword forged from iron.",
    category = Enums.Category.Weapon,
    subcategory = Enums.Subcategory.Greatsword,
    rarity = Enums.Rarity.Common,
    iconId = "rbxassetid://000000",
    weight = 12,
    stackMax = 1,
    sellValue = 150,
    levelReq = 5,
    canDrop = true,
    canTrade = true,
    baseAD = 120,
    baseMD = 0,
    basicAttackType = "Physical",
    strengthScaling = 1.2,
    dexterityScaling = 0.3,
    intelligenceScaling = 0.0,
    blockPower = 40,
    parryMultiplier = 1.5,
    hands = 2,
    attackSpeed = 0.8,
    range = 8,
    staminaCost = 25,
    hitShape = "Box",
    hitSize = Vector3.new(8, 5, 10),
    hitOffset = Vector3.new(0, 0, -5),
    animationSet = "Greatsword",
    attackSequence = { "Attack1", "Attack2", "Attack3" },
    weaponTag = "Greatsword",
    abilityPresetKey = "Greatsword",
    maxAbilitySlots = 5,
    maxUltimateSlots = 1,
    innateAbility = nil,
    maxLevel = 10,
    levelScaling = 0.05,
    modifierPoolId = "MeleeWeaponPool",
    maxModifiers = 3,
},
```

### Step 3: Add the visual prefab

Place a Model or MeshPart in `ReplicatedStorage.Assets.Items.Weapons.Greatswords.IronGreatsword`. See [replicated-storage.md](./replicated-storage.md) for the full layout spec.

### Step 4: Done

`ItemRegistry` auto-discovers the template on require. The loot system can now roll it. The inventory system can now create instances of it. The UI resolves its icon from `iconId` in the template. No wiring needed.

---

## VII. Item Instance Lifecycle

```
1. CREATION
   ├── Loot drop: LootService rolls a template + modifiers → creates ItemInstance
   ├── Crafting: CraftingService combines materials → creates ItemInstance
   ├── Shop purchase: ShopService deducts currency → creates ItemInstance
   └── Quest reward: QuestService grants → creates ItemInstance

2. STORAGE
   ├── Field inventory: player's in-session inventory (16 slots)
   ├── Equipment: equipped in loadout slots (Backpack, Armor, Weapon1, Weapon2)
   ├── Quick-use: assigned to quick-use bar (8 slots)
   └── Stash: persistent safe storage in village (larger capacity)

3. MUTATION
   ├── Level up: blacksmith upgrades → level++, stats recalculated
   ├── Modifier reroll: special NPC → replaces modifiers via RNG
   ├── Durability loss: combat use → durability-- (if applicable)
   ├── Repair: blacksmith → durability restored
   └── Stack change: consume/loot → count adjusted

4. REMOVAL
   ├── Consumed: consumable used → count-- (destroyed at 0)
   ├── Dropped: player drops → removed from inventory, spawned in world
   ├── Sold: NPC transaction → removed, currency added
   ├── Traded: player trade → transferred to other player's data
   └── Destroyed: broken durability or explicit destroy
```

---

## VIII. Equipment Slots

**Arc Raiders–style loadout:** At any given time, players can equip at most **1 Backpack**, **1 Armor**, and **2 Weapons**.

| Slot | Category Allowed | Max Items | Notes |
|------|-----------------|-----------|-------|
| **Backpack** | Backpack | 1 | Determines inventory capacity. |
| **Armor** | Armor | 1 | Defensive gear. No cosmetic effect; character appearance stays the same. Equip/unequip plays a "suiting up" animation. |
| **Weapon1** | Weapon | 1 | Primary weapon. Has 5 ability sub-slots. |
| **Weapon2** | Weapon | 1 | Secondary weapon. Has 5 ability sub-slots. |

### Stat Contribution

When a player equips an item, its stats are fed into the existing `StatsService` as `StatModifier` entries with `source = "Equipment"`. When unequipped, those modifiers are removed. This integrates cleanly with the existing modifier pipeline in `StatsTypes.luau`.

---

## IX. Integration Points

### Combat System

The 6-step damage pipeline in `combat-system.md` consumes weapon stats directly:
- **Step 1** reads `strengthScaling`, `dexterityScaling`, `intelligenceScaling` from the equipped weapon's template.
- **Step 2** reads `baseAD`, `baseMD` from the template, plus level bonuses: `baseAD * (1 + level * levelScaling)`.
- **Steps 4–6** read armor/resistance values from equipped armor templates.

### Stats System

`StatsTypes.luau` already defines `StatModifier` with `source: "Equipment"`. When equipment changes, the equipment service:
1. Removes all modifiers with `source = "Equipment"` for the old item.
2. Adds new modifiers for the new item's base stats + its rolled bonus modifiers.
3. Calls `StatsService:RecalculateDerived(player)`.

### UI System

The existing UI components (`LoadoutApp`, `HudLoadoutApp`, `RadialDial`) remain structurally intact. They need to be rewired to read from the new data source:
- `ItemIconResolver` is replaced by reading `iconId` directly from the template via `ItemRegistry.GetTemplate(templateId).iconId`.
- `InventoryTypes.luau` will be updated to use `ItemInstance` instead of the old `ItemStack`.
- `HudLoadoutDataAdapter` stub state will be replaced with real data from the inventory/equipment service.

### Loot / RNG System

The loot system uses `ItemRegistry.GetRandomTemplate(filter)` to select what item to drop, then the modifier system rolls bonus stats. See [modifier-system.md](./modifier-system.md) for details.

---

## X. Relationship to Existing Code

### Kept (still functional)

| Module | Why |
|--------|-----|
| `Configs/Stats/StatsTypes.luau` | Core stat/modifier types used by the new system. |
| `Configs/Stats/StatsConfig.luau` | Stat tuning values. |
| `Inventory/InventoryTypes.luau` | Shared types consumed by UI. Will be updated to new schemas. |
| All GUI components | UI rendering is data-driven and stays. Data source changes. |

### Deprecated (to be removed when new systems are built)

| Module | Replaced By |
|--------|-------------|
| `Configs/LootSystem/*` (ItemDefinitions, LootConfig, LootPools, DropRules) | `ItemRegistry` + `LootService` (already deleted) |
| `LootSystem/DropFactory.luau` | New world-drop system (already deleted) |
| `LootSystem/LootBoxService.luau` | New `LootService` (already deleted) |
| `LootSystem/BreakableCrate.luau` | Rebuilt as needed (already deleted) |
| `Inventory/InventoryService.luau` | New `InventoryService` backed by `DataManager` (already deleted) |
| `GUI/Loadout/ItemIconResolver.luau` | `AssetResolver` + direct `iconId` from templates (placeholder in place) |
| `Configs/Weapons/MeleeConfigs.luau` | `WeaponTemplate.hitShape/hitSize/attackSequence` + `BasicAttackService` + per-ability scripts in `Assets/Abilities/`. See [ability-system.md](./ability-system.md). |
| `Configs/Med/MedConfigs.luau` | Per-consumable scripts in `Assets/Consumables/`. See [ability-system.md](./ability-system.md#v-consumable-assets-in-replicatedstorage). |
| `server/Weapons/MeleeService.luau` | `AbilityService` + `BasicAttackService` + individual ability scripts. |
| `server/Med/MedService.luau` | `ConsumableService` + individual consumable scripts. |
| `client/Weapons/MeleeController.client.luau` | Client-side ability runtime. |
| `client/Med/MedController.client.luau` | Client-side consumable runtime. |

**Note:** MeleeConfigs, MedConfigs, and their services still exist in the codebase and are functional. They will be removed after the new ability/consumable asset systems are implemented.

---

[Next: Ability System →](./ability-system.md) | [Modifier System →](./modifier-system.md) | [Data Persistence →](./data-persistence.md) | [ReplicatedStorage Layout →](./replicated-storage.md)
