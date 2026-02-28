# Combat & Damage System Specification

## The 6-Step Damage Pipeline

The damage calculation in Project S follows a consistent pipeline that applies attribute scaling, ability multipliers, defenses, and mitigation in a specific order.

### Step 1: Attribute Bonuses to Attack Damage

Attributes contribute to damage through weapon scaling multipliers:

- **Bonus AD** = (Attacker's Strength × Weapon's Strength Scaling) + (Attacker's Dexterity × Weapon's Dexterity Scaling)
- **Bonus MD** = Attacker's Intelligence × Weapon's Intelligence Scaling

### Step 2: Total Base Damage

Combine weapon base stats with attribute bonuses:

- **Total AD** = Weapon AD + Bonus AD
- **Total MD** = Weapon MD + Bonus MD

### Step 3: Apply Ability Scaling

Abilities modify damage through scaling factors. Basic attacks use 1.0 scaling for both types:

- **Ability-Scaled AD** = Total AD × Ability's AD Scaling Factor
- **Ability-Scaled MD** = Total MD × Ability's MD Scaling Factor
- *(Basic attacks: AD Scaling = 1.0, MD Scaling = 1.0)*

### Step 4: Apply Defender Resistances

Resistances reduce damage before armor is applied:

- **Unresisted AD** = Ability-Scaled AD × (1 - Defender's Physical Resistance)
- **Unresisted MD** = Ability-Scaled MD × (1 - Defender's Magic Resistance)
- **Pre-Mitigation Damage** = Unresisted AD + Unresisted MD

### Step 5: Apply Critical Strike

Critical strikes multiply damage by 1.5x if RNG succeeds:

- If Attacker's Critical RNG succeeds (based on Attacker's Critical Chance):
  - **True Damage** = Pre-Mitigation Damage × 1.5
- Otherwise:
  - **True Damage** = Pre-Mitigation Damage

### Step 6: Apply Mitigation & Defense

Final damage is reduced by armor and active defense:

- **Total Armor** = Defender's Armor from all sources

| Defense State | Damage Dealt Formula |
|---------------|---------------------|
| **No Defense** | True Damage − Total Armor |
| **Blocking** | True Damage − Total Armor − Attacker's Weapon Block Power |
| **Parrying** | True Damage − Total Armor − (Attacker's Weapon Block Power × Defender's Weapon Parry Multiplier) |

---

## Equipment Stats

See [Equipment System](./equipment.md) for detailed stat descriptions and tables.

## Implementation

See the Lua implementation in the source code for reference implementations of this damage pipeline.

---

[Back to Overview](./game-design.md)
