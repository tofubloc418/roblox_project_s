# Modifier Pool Table

Complete reference of all possible equipment modifiers. Each row is one stat + tier combination. The Min/Max columns are the **actual roll range** for that tier — no additional scaling is applied.

## Legend

- **Op**: Flat = added directly to the stat, %Add = additive percentage bonus
- **Equipment**: W = Weapon, A = Armor, B = Backpack, Ac = Accessory
- **Weight**: Relative probability of this stat being selected when rolling modifiers. Higher = more common.

---

| Stat | Tier | Op | Min | Max | Weight | Equipment |
|------|------|----|-----|-----|--------|-----------|
| MaxHP | Minor | Flat | 5 | 15 | 10 | W, A, B, Ac |
| MaxHP | Standard | Flat | 15 | 40 | 10 | W, A, B, Ac |
| MaxHP | Major | Flat | 40 | 80 | 10 | W, A, B, Ac |
| MaxHP | Prime | Flat | 80 | 150 | 10 | W, A, B, Ac |
| MaxMana | Minor | Flat | 5 | 10 | 6 | W, A, Ac |
| MaxMana | Standard | Flat | 10 | 25 | 6 | W, A, Ac |
| MaxMana | Major | Flat | 25 | 50 | 6 | W, A, Ac |
| MaxMana | Prime | Flat | 50 | 90 | 6 | W, A, Ac |
| MaxEnergy | Minor | Flat | 3 | 8 | 6 | W, A, B, Ac |
| MaxEnergy | Standard | Flat | 8 | 18 | 6 | W, A, B, Ac |
| MaxEnergy | Major | Flat | 18 | 35 | 6 | W, A, B, Ac |
| MaxEnergy | Prime | Flat | 35 | 60 | 6 | W, A, B, Ac |
| CritChance | Minor | Flat | 0.005 | 0.01 | 8 | W, Ac |
| CritChance | Standard | Flat | 0.01 | 0.025 | 8 | W, Ac |
| CritChance | Major | Flat | 0.025 | 0.05 | 8 | W, Ac |
| CritChance | Prime | Flat | 0.05 | 0.08 | 8 | W, Ac |
| MoveSpeed | Minor | Flat | 0.5 | 1.0 | 5 | A, B, Ac |
| MoveSpeed | Standard | Flat | 1.0 | 2.0 | 5 | A, B, Ac |
| MoveSpeed | Major | Flat | 2.0 | 3.5 | 5 | A, B, Ac |
| MoveSpeed | Prime | Flat | 3.5 | 5.0 | 5 | A, B, Ac |
| PhysicalResist | Minor | Flat | 0.005 | 0.015 | 7 | W, A, B, Ac |
| PhysicalResist | Standard | Flat | 0.015 | 0.03 | 7 | W, A, B, Ac |
| PhysicalResist | Major | Flat | 0.03 | 0.05 | 7 | W, A, B, Ac |
| PhysicalResist | Prime | Flat | 0.05 | 0.08 | 7 | W, A, B, Ac |
| MagicResist | Minor | Flat | 0.005 | 0.015 | 7 | W, A, B, Ac |
| MagicResist | Standard | Flat | 0.015 | 0.03 | 7 | W, A, B, Ac |
| MagicResist | Major | Flat | 0.03 | 0.05 | 7 | W, A, B, Ac |
| MagicResist | Prime | Flat | 0.05 | 0.08 | 7 | W, A, B, Ac |
| Armor | Minor | Flat | 2 | 8 | 8 | W, A, B, Ac |
| Armor | Standard | Flat | 8 | 18 | 8 | W, A, B, Ac |
| Armor | Major | Flat | 18 | 35 | 8 | W, A, B, Ac |
| Armor | Prime | Flat | 35 | 55 | 8 | W, A, B, Ac |
| AbilityHaste | Minor | Flat | 0.005 | 0.015 | 5 | W, Ac |
| AbilityHaste | Standard | Flat | 0.015 | 0.03 | 5 | W, Ac |
| AbilityHaste | Major | Flat | 0.03 | 0.05 | 5 | W, Ac |
| AbilityHaste | Prime | Flat | 0.05 | 0.08 | 5 | W, Ac |
| EnergyRegen | Minor | Flat | 0.5 | 1.5 | 5 | A, B, Ac |
| EnergyRegen | Standard | Flat | 1.5 | 3.0 | 5 | A, B, Ac |
| EnergyRegen | Major | Flat | 3.0 | 5.0 | 5 | A, B, Ac |
| EnergyRegen | Prime | Flat | 5.0 | 8.0 | 5 | A, B, Ac |
| ManaRegen | Minor | Flat | 0.5 | 1.0 | 5 | W, A, Ac |
| ManaRegen | Standard | Flat | 1.0 | 2.5 | 5 | W, A, Ac |
| ManaRegen | Major | Flat | 2.5 | 4.5 | 5 | W, A, Ac |
| ManaRegen | Prime | Flat | 4.5 | 7.0 | 5 | W, A, Ac |
| LootBonus | Minor | %Add | 0.02 | 0.05 | 3 | W, B, Ac |
| LootBonus | Standard | %Add | 0.05 | 0.10 | 3 | W, B, Ac |
| LootBonus | Major | %Add | 0.10 | 0.18 | 3 | W, B, Ac |
| LootBonus | Prime | %Add | 0.18 | 0.25 | 3 | W, B, Ac |
| FallDamageReduction | Minor | Flat | 0.01 | 0.04 | 3 | A, B |
| FallDamageReduction | Standard | Flat | 0.04 | 0.08 | 3 | A, B |
| FallDamageReduction | Major | Flat | 0.08 | 0.15 | 3 | A, B |
| FallDamageReduction | Prime | Flat | 0.15 | 0.25 | 3 | A, B |

---

## Design Notes

**Stat availability by equipment slot:**

| Stat | Weapon | Armor | Backpack | Accessory |
|------|--------|-------|----------|-----------|
| MaxHP | ✓ | ✓ | ✓ | ✓ |
| MaxMana | ✓ | ✓ | – | ✓ |
| MaxEnergy | ✓ | ✓ | ✓ | ✓ |
| CritChance | ✓ | – | – | ✓ |
| MoveSpeed | – | ✓ | ✓ | ✓ |
| PhysicalResist | ✓ | ✓ | ✓ | ✓ |
| MagicResist | ✓ | ✓ | ✓ | ✓ |
| Armor | ✓ | ✓ | ✓ | ✓ |
| AbilityHaste | ✓ | – | – | ✓ |
| EnergyRegen | – | ✓ | ✓ | ✓ |
| ManaRegen | ✓ | ✓ | – | ✓ |
| LootBonus | ✓ | – | ✓ | ✓ |
| FallDamageReduction | – | ✓ | ✓ | – |

**Balancing rationale:**
- **Weapons** favor offensive stats (CritChance, AbilityHaste) and light defensive stats.
- **Armor** is the primary defensive slot (HP, resists, Armor, EnergyRegen, FallDamageReduction).
- **Backpacks** specialize in utility and mobility (MoveSpeed, EnergyRegen, LootBonus, FallDamageReduction).
- **Accessories** are the most versatile slot with access to nearly everything, but no FallDamageReduction.
- **WalkSpeed and RunSpeed** are excluded — MoveSpeed is the unified modifier that feeds into both via StatFormulas.

---

[← Modifier System](./modifier-system.md)
