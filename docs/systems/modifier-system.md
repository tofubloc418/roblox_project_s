# Modifier System

This document specifies the bonus modifier system: how modifiers are defined, how they are rolled onto items via RNG, and how they integrate with the existing stat pipeline. This system is designed to be fully modular — it can generate modifiers, evaluate them, and serialize them without any coupling to item logic or UI.

---

## I. Core Concepts

### What Is a Modifier?

A **modifier** is a bonus stat applied to an item instance. When a player equips an item, its modifiers feed into the `StatsService` modifier pipeline. Modifiers are the primary source of item power variance: two "Iron Longswords" may have completely different modifier rolls.

### Modifier vs StatModifier

The existing `StatsTypes.StatModifier` is the runtime representation consumed by `StatsService`. An `ItemModifier` is the persistence-friendly version stored on item instances. When an item is equipped, each `ItemModifier` is converted into a `StatModifier` with `source = "Equipment"` and injected into the player's modifier stack.

---

## II. ItemModifier Schema

```
ItemModifier {
    modifierId    : string             -- Unique within the item instance, e.g. "mod_1"
    statId        : DerivedStatId      -- Which stat this modifies (from StatsTypes)
    operation     : ModifierOperation  -- "Flat" | "PercentAdd" | "PercentMult"
    value         : number             -- The bonus value
    tier          : ModifierTier       -- "Minor" | "Standard" | "Major" | "Prime"
    displayName   : string?            -- Human-readable label, e.g. "of the Bear" (optional)
}
```

### Modifier Tiers

Tiers determine the value range a modifier can roll within. Higher tiers have better rolls and are rarer.

| Tier | Roll Range Multiplier | Drop Weight | Color (UI) |
|------|----------------------|-------------|------------|
| **Minor** | 0.5×–0.75× of base range | 40% | Grey |
| **Standard** | 0.75×–1.0× | 35% | White |
| **Major** | 1.0×–1.25× | 20% | Blue |
| **Prime** | 1.25×–1.5× | 5% | Gold |

The actual numeric ranges are defined per stat in the modifier pool (see below). The tier multiplier scales those ranges.

---

## III. Modifier Pools

A **modifier pool** is a collection of possible modifiers that can appear on an item. Each pool is identified by a `poolId` referenced by the item template's `modifierPoolId` field.

### Pool Definition Schema

```
ModifierPool {
    poolId        : string
    entries       : {ModifierPoolEntry}
}

ModifierPoolEntry {
    statId        : DerivedStatId
    operation     : ModifierOperation
    baseMin       : number     -- Minimum value before tier scaling
    baseMax       : number     -- Maximum value before tier scaling
    weight        : number     -- Relative probability of this entry being selected
    displayName   : string?    -- Optional affix name, e.g. "of Vitality"
}
```

### Example Pools

```
MeleeWeaponPool:
    { statId = "CritChance",    op = "Flat",       baseMin = 0.02, baseMax = 0.08, weight = 10 }
    { statId = "Armor",         op = "Flat",       baseMin = 5,    baseMax = 20,   weight = 8  }
    { statId = "MoveSpeed",     op = "Flat",       baseMin = 1,    baseMax = 4,    weight = 6  }
    { statId = "MaxHP",         op = "Flat",       baseMin = 10,   baseMax = 50,   weight = 8  }
    { statId = "AbilityHaste",  op = "Flat",       baseMin = 0.02, baseMax = 0.08, weight = 5  }
    { statId = "EnergyRegen",   op = "Flat",       baseMin = 1,    baseMax = 5,    weight = 5  }
    { statId = "PhysicalResist",op = "Flat",       baseMin = 0.01, baseMax = 0.05, weight = 4  }
    { statId = "LootBonus",     op = "PercentAdd", baseMin = 0.05, baseMax = 0.15, weight = 3  }

ArmorPool:
    { statId = "MaxHP",         op = "Flat",       baseMin = 15,   baseMax = 80,   weight = 10 }
    { statId = "PhysicalResist",op = "Flat",       baseMin = 0.02, baseMax = 0.08, weight = 8  }
    { statId = "MagicResist",   op = "Flat",       baseMin = 0.02, baseMax = 0.08, weight = 8  }
    { statId = "Armor",         op = "Flat",       baseMin = 5,    baseMax = 30,   weight = 10 }
    { statId = "MoveSpeed",     op = "Flat",       baseMin = 0.5,  baseMax = 3,    weight = 4  }
    { statId = "EnergyRegen",   op = "Flat",       baseMin = 1,    baseMax = 5,    weight = 5  }
    { statId = "MaxEnergy",     op = "Flat",       baseMin = 5,    baseMax = 25,   weight = 5  }

BackpackPool:
    { statId = "MaxHP",              op = "Flat",       baseMin = 10,   baseMax = 40,   weight = 8  }
    { statId = "MoveSpeed",          op = "Flat",       baseMin = 0.5,  baseMax = 2,    weight = 6  }
    { statId = "EnergyRegen",        op = "Flat",       baseMin = 1,    baseMax = 5,    weight = 7  }
    { statId = "LootBonus",          op = "PercentAdd", baseMin = 0.05, baseMax = 0.20, weight = 5  }
    { statId = "MaxEnergy",          op = "Flat",       baseMin = 5,    baseMax = 25,   weight = 6  }
```

### Config File Organization

```
Configs/
├── Modifiers/
│   ├── ModifierEnums.luau          -- ModifierTier, tier weights, tier multipliers
│   ├── ModifierPools.luau          -- All pool definitions keyed by poolId
│   └── ModifierService.luau        -- (shared) RNG roller, modifier creation, conversion to StatModifier
```

---

## IV. Modifier Rolling Algorithm

When an item instance is created (from a loot drop, crafting, etc.), the modifier system rolls its bonuses.

### Inputs

- `modifierPoolId` — from the item template
- `maxModifiers` — from the item template (max modifiers this item can have)
- `itemRarity` — influences how many modifiers actually roll
- `islandDifficulty` — scales roll quality (optional)

### Step 1: Determine Modifier Count

The number of modifiers an item actually gets is based on its rarity and capped by `maxModifiers`:

| Rarity | Min Modifiers | Max Modifiers |
|--------|--------------|---------------|
| Common | 0 | 1 |
| Uncommon | 1 | 2 |
| Rare | 2 | 3 |
| Epic | 3 | 4 |
| Legendary | 4 | maxModifiers |

The actual count is `Random(min, max)`, capped at `maxModifiers`.

### Step 2: Select Modifier Entries (no duplicates)

For each modifier slot, pick one `ModifierPoolEntry` from the pool using weighted random selection. **No duplicate stats** — once a stat is selected, it is removed from the candidate pool for subsequent rolls.

### Step 3: Roll Tier

For each selected entry, roll a `ModifierTier` using the tier weight table:

```
Minor:    40%
Standard: 35%
Major:    20%
Prime:     5%
```

### Step 4: Roll Value

Given the entry's `baseMin`/`baseMax` and the tier's multiplier range:

```
actualMin = baseMin * tierMultiplierLow
actualMax = baseMax * tierMultiplierHigh
value = Random(actualMin, actualMax)  -- uniform distribution within range
```

### Step 5: Apply Island Scaling (optional)

If the drop comes from a high-difficulty island, the entire value range shifts upward:

```
scaledValue = value * (1 + islandDifficultyBonus)
```

Where `islandDifficultyBonus` is a small multiplier (e.g. 0.0 for center islands, 0.5 for outermost).

### Step 6: Construct ItemModifier

```lua
{
    modifierId = "mod_" .. slotIndex,
    statId = entry.statId,
    operation = entry.operation,
    value = roundedValue,
    tier = rolledTier,
    displayName = entry.displayName,
}
```

---

## V. Modifier → StatModifier Conversion

When a player equips an item, each `ItemModifier` on the instance is converted to a `StatsTypes.StatModifier` and injected into `StatsService`:

```lua
local function toStatModifier(itemMod: ItemModifier, instanceId: string): StatModifier
    return {
        id = instanceId .. "_" .. itemMod.modifierId,
        source = "Equipment",
        stat = itemMod.statId,
        operation = itemMod.operation,
        value = itemMod.value,
        duration = nil,  -- permanent while equipped
        metadata = {
            instanceId = instanceId,
            tier = itemMod.tier,
        },
    }
end
```

When unequipped, all `StatModifier` entries whose `metadata.instanceId` matches are removed and stats are recalculated.

---

## VI. Modifier Rerolling

An NPC service (blacksmith or enchanter) can **reroll** modifiers on an item:

### Full Reroll

Destroys all existing modifiers and re-runs the rolling algorithm. Cost scales with item rarity and level.

### Targeted Reroll

Rerolls a single modifier slot, keeping all others. More expensive than full reroll. The stat pool excludes stats already present on other slots (no-duplicate rule still applies).

### Tier Upgrade

Attempts to upgrade a single modifier's tier (e.g. Minor → Standard). Success chance decreases with higher tiers. On failure, the modifier is unchanged (not destroyed).

---

## VII. Modifier Display in UI

### Tooltip Format

Each modifier is displayed as a single line in the item tooltip:

```
[Tier Color] +{value} {StatName}   ({TierName})
```

Examples:
```
[Grey]  +3% Crit Chance         (Minor)
[White] +15 Max HP               (Standard)
[Blue]  +0.08 Ability Haste      (Major)
[Gold]  +45 Armor                (Prime)
```

### Stat Formatting Rules

| Operation | Format | Example |
|-----------|--------|---------|
| Flat (small decimal) | `+{value * 100}%` | CritChance 0.05 → "+5%" |
| Flat (integer-range) | `+{value}` | MaxHP 25 → "+25" |
| PercentAdd | `+{value * 100}%` | LootBonus 0.10 → "+10%" |
| PercentMult | `×{value}` | Rare, e.g. ×1.15 |

Whether a stat uses percentage or integer display is determined by a lookup table in the UI config (e.g. CritChance, PhysicalResist, MagicResist → percentage; MaxHP, Armor, MoveSpeed → integer).

---

## VIII. Modifier Serialization

For DataStore persistence, modifiers serialize to a compact table:

```lua
-- Serialized format (one modifier)
{
    mid = "mod_1",        -- modifierId
    sid = "CritChance",   -- statId
    op  = "Flat",         -- operation
    val = 0.05,           -- value
    t   = "Major",        -- tier
}
```

See [data-persistence.md](./data-persistence.md) for the full item serialization spec.

---

## IX. Integration with Existing Systems

### StatsTypes.luau — No Changes Required

The existing `StatModifier` type already supports everything needed:
- `id`: unique per modifier per item instance
- `source`: `"Equipment"` for item modifiers
- `stat`: any `DerivedStatId`
- `operation`: `"Flat"`, `"PercentAdd"`, `"PercentMult"`
- `value`: the rolled number
- `duration`: `nil` for permanent (while equipped)
- `metadata`: stores `instanceId` and `tier` for removal/display

### StatsService — Minor Extension

The only addition needed is a method to bulk-add/remove equipment modifiers:

```
StatsService:ApplyEquipmentModifiers(player, instanceId, modifiers: {ItemModifier})
StatsService:RemoveEquipmentModifiers(player, instanceId)
```

These are convenience wrappers around the existing `AddModifier`/`RemoveModifier` methods.

### Loot System

The loot system calls `ModifierService.RollModifiers(template, rarity, islandDifficulty)` to produce a `{ItemModifier}` array, then attaches it to the newly created `ItemInstance`.

---

[← Item System](./item-system.md) | [Data Persistence →](./data-persistence.md) | [ReplicatedStorage Layout →](./replicated-storage.md)
