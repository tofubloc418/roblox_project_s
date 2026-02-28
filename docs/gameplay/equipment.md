# Equipment System

## Weapon Stats

Each weapon defines base damage values and scaling multipliers that determine how a character's attributes contribute to damage.

| Stat | Description |
|------|-------------|
| **Weapon AD** | Base physical damage value |
| **Weapon MD** | Base magic damage value |
| **Strength Scaling** | Multiplier for attribute contribution to physical damage |
| **Dexterity Scaling** | Multiplier for attribute contribution to physical damage |
| **Intelligence Scaling** | Multiplier for attribute contribution to magic damage |
| **Block Power** | Flat damage reduction while blocking |
| **Parry Multiplier** | Multiplier for Block Power during a successful parry |
| **BasicAttackType** | Determines if basic clicks deal Physical or Magic damage |

### Scaling Example

A heavy sword with:
- Strength Scaling = 1.2
- Dexterity Scaling = 0.3
- Intelligence Scaling = 0.0

A character with Strength = 20, Dexterity = 10, Intelligence = 5 would get:
- Bonus AD = (20 × 1.2) + (10 × 0.3) + (5 × 0.0) = 24 + 3 + 0 = 27 bonus AD

See [Combat & Damage System](./combat-system.md) for how scaling integrates into damage calculations.

---

## Armor Stats

Armor and resistances reduce incoming damage through different mechanisms.

| Stat | Description |
|------|-------------|
| **Armor** | Flat damage reduction applied at the final step of damage calculation |
| **Physical Resist** | Percentage reduction (0.0 - 1.0) applied to physical damage before armor |
| **Magic Resist** | Percentage reduction (0.0 - 1.0) applied to magic damage before armor |

### Defense Mechanics

- **Resistances** are applied early in the damage pipeline and reduce damage by a percentage
- **Armor** is applied last and reduces damage by a flat amount
- **Active Defense** (blocking/parrying) adds additional flat reduction on top of armor

See [Combat & Damage System](./combat-system.md) for details on how these stack in the damage pipeline.

---

## Bonus Stats (Accessories & RNG)

| Stat | Description |
|------|-------------|
| **Crit Chance** | Flat % increase to critical probability |
| **Ability Haste** | % reduction to ability cooldowns |
| **Energy/Mana Regen** | Flat recovery increases per second |
| **Move Speed** | Flat velocity increase |
| **Loot Bonus** | Multiplier for finding rare items |

---

[Back to Overview](./game-design.md)
