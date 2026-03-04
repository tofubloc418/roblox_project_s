# Asset Placement & Code Additions Guide

This guide explains **where** to put each type of in-game asset (weapons, armor, backpacks, consumables, abilities) in ReplicatedStorage and in the codebase, and **what** you must add in code so the current systems recognize and use them. It is written for adding one of each asset type in a simple, structured way.

**Related documentation:**
- [ReplicatedStorage layout & asset organization](../systems/replicated-storage.md) — full folder tree and prefab rules
- [Item & weapon system](../systems/item-system.md) — template schemas and taxonomy
- [Ability & consumable system](../systems/ability-system.md) — ability/consumable asset structure and tag system

---

## 1. Overview

| Asset type   | Definition (data)              | Model / prefab                    | Behavior / scripts                 |
|-------------|--------------------------------|-----------------------------------|------------------------------------|
| **Weapon**  | `Configs/Items/Weapons/`       | `Assets/Items/Weapons/`           | (Future: equip/attack system)       |
| **Armor**   | `Configs/Items/Armor/`         | `Assets/Items/Armor/`             | (Future: equip animation)           |
| **Backpack**| `Configs/Items/Backpacks/`     | `Assets/Items/Backpacks/`         | (Future, if any)                    |
| **Consumable** | `Configs/Items/Consumables/` | Optional in asset folder          | `Assets/Consumables/<id>/`         |
| **Ability** | *(no item template)*           | —                                 | `Assets/Abilities/<id>/`           |

**Icons:** No separate “background icon image” is required. Each item template has an `iconId` field (e.g. `""` or an `rbxassetid://`). The current `ItemIconResolver` can return `nil` and the display name until you add real icon resolution.

---

## 2. Weapons

### 2.1 Purpose

Weapons are equippable items that go in **Weapon1** or **Weapon2**. Each weapon has a **template** (definition in config) and a **prefab** (3D model in ReplicatedStorage). The model is cloned when the weapon is equipped or dropped in the world.

### 2.2 Where to put things (Studio → ReplicatedStorage)

| What        | Path | Notes |
|------------|------|--------|
| **Model**  | `ReplicatedStorage.Assets.Items.Weapons.<Subcategory>.<templateId>` | e.g. `Assets.Items.Weapons.Greatswords.IronGreatsword` |
| **Unique weapon model** | `ReplicatedStorage.Assets.Items.Weapons.Unique.<templateId>` | e.g. `Assets.Items.Weapons.Unique.Moonveil` |

**Model requirements:**
- **Name** of the Model = `templateId` exactly (e.g. `IronGreatsword`). This is how the system finds the prefab.
- **Handle** — a child `BasePart` (MeshPart or Part) named `"Handle"`. Required; it is the grip welded to the character’s hand.
- Other visual parts (blade, guard, etc.) should be **welded to Handle** (WeldConstraint or Motor6D).
- **No scripts** on the model. Behavior is in server/client modules.
- Optional: **GripAttachment** on Handle (precise grip point); **Muzzle** (Attachment) for ranged weapons (projectile spawn).
- Parts: **Anchored = false**; **CanCollide = false** on everything except Handle if you use it for world drops.

### 2.3 What to add in the codebase

**Step 1 — Item template (config)**  
Create or edit a Luau module under **Configs/Items/Weapons/** (e.g. `Greatswords.luau`). The path in source is `src/shared/sharedNormalIsland/Configs/Items/Weapons/`.

Define a table with at least:

- **Base:** `templateId`, `displayName`, `description`, `category = "Weapon"`, `subcategory` (e.g. `"Greatsword"`), `rarity`, `iconId` (can be `""`), `weight`, `stackMax = 1`, `sellValue`, `levelReq`, `canDrop`, `canTrade`
- **Weapon:** `weaponTag` (e.g. `"Greatsword"`), `abilityPresetKey` (same as `weaponTag` for class weapons; for uniques use e.g. `"Unique_Moonveil"`)

Example (minimal):

```lua
local ItemRegistry = require(script.Parent.Parent.Parent:WaitForChild("ItemRegistry"))

local IronGreatsword = {
    templateId   = "IronGreatsword",
    displayName  = "Iron Greatsword",
    description  = "A heavy two-handed blade.",
    category     = "Weapon",
    subcategory  = "Greatsword",
    rarity       = "Common",
    iconId       = "",
    weight       = 10,
    stackMax     = 1,
    sellValue    = 50,
    levelReq     = 1,
    canDrop      = true,
    canTrade     = true,
    weaponTag    = "Greatsword",
    abilityPresetKey = "Greatsword",
}

ItemRegistry.Register(IronGreatsword)
```

**Step 2 — Register the template**  
In that same module, call `ItemRegistry.Register(yourWeaponTemplate)` for each weapon (as in the example above).

**Step 3 — Wire the config into the registry**  
In **Configs/Items/ItemRegistry.luau**, in the “Sub-module auto-discovery” section at the bottom, add:

```lua
require(script.Parent.Weapons.Greatswords)  -- or your filename
```

After this, `ItemRegistry.GetTemplate("IronGreatsword")` will return the template. Inventory and equip validation use this; a future equip system will clone the model from `Assets/Items/Weapons/Greatswords/IronGreatsword`.

### 2.4 Checklist

- [ ] Model in `Assets.Items.Weapons.<Subcategory>.<templateId>` (or `Unique.<templateId>`) with **Name** = templateId
- [ ] Handle part present and named `"Handle"`
- [ ] Config module under `Configs/Items/Weapons/` with template table and `ItemRegistry.Register(...)`
- [ ] `require(script.Parent.Weapons.<YourFile>)` added in ItemRegistry.luau

---

## 3. Armor

### 3.1 Purpose

Armor is equippable in the **Armor** slot only. Equipped armor does **not** change character appearance; it only triggers a “suiting up” / “suiting down” animation when equipped or unequipped. The prefab is used for world drops or a simple placeholder if needed.

### 3.2 Where to put things (Studio → ReplicatedStorage)

| What   | Path | Notes |
|--------|------|--------|
| **Model** (optional) | `ReplicatedStorage.Assets.Items.Armor.<templateId>` | Simple model or placeholder; not used for character cosmetics |

### 3.3 What to add in the codebase

**Step 1 — Item template**  
Create or edit a module under **Configs/Items/Armor/** (e.g. `Armor.luau`). Define a table with the same base fields as any item; use `category = "Armor"` and a `subcategory` (e.g. `"Body"`).

**Step 2 — Register and require**  
In that module, call `ItemRegistry.Register(armorTemplate)`. In **ItemRegistry.luau**, add:

```lua
require(script.Parent.Armor.Armor)
```

No extra code is required for the asset itself. The equip “suiting up” animation will be wired elsewhere when you implement it.

### 3.4 Checklist

- [ ] Optional model in `Assets.Items.Armor.<templateId>` if you want a world-drop or placeholder
- [ ] Config module under `Configs/Items/Armor/` with template and `ItemRegistry.Register(...)`
- [ ] `require(script.Parent.Armor.<YourFile>)` in ItemRegistry.luau

---

## 4. Backpacks

### 4.1 Purpose

Backpacks are equippable in the **Backpack** slot. They typically affect inventory capacity or other backpack-specific logic (defined elsewhere). The prefab is the visual representation when needed.

### 4.2 Where to put things (Studio → ReplicatedStorage)

| What   | Path | Notes |
|--------|------|--------|
| **Model** | `ReplicatedStorage.Assets.Items.Backpacks.<templateId>` | Name = templateId; optional Handle if shown on character later |

### 4.3 What to add in the codebase

**Step 1 — Item template**  
Create or edit a module under **Configs/Items/Backpacks/** (e.g. `Backpacks.luau`). Define a table with base fields and `category = "Backpack"`.

**Step 2 — Register and require**  
Call `ItemRegistry.Register(backpackTemplate)`. In **ItemRegistry.luau** add:

```lua
require(script.Parent.Backpacks.Backpacks)
```

### 4.4 Checklist

- [ ] Model in `Assets.Items.Backpacks.<templateId>` with Name = templateId
- [ ] Config module under `Configs/Items/Backpacks/` with template and `ItemRegistry.Register(...)`
- [ ] Corresponding `require` in ItemRegistry.luau

---

## 5. Consumables (e.g. healing item)

### 5.1 Purpose

Consumables are items that can be assigned to **quick-use** slots and used in the world. Each consumable type has its **own behavior** implemented in a self-contained folder under `Assets/Consumables/`. There is no central “MedService” that hardcodes each consumable; the folder’s scripts define what happens when the item is used.

### 5.2 Where to put things (Studio → ReplicatedStorage)

| What   | Path | Notes |
|--------|------|--------|
| **Folder** | `ReplicatedStorage.Assets.Consumables.<templateId>` | Folder name **must** match the item’s `templateId` (e.g. `Bandage`) |

**Inside the folder:**

| Child | Type | Required? | Purpose |
|-------|------|-----------|---------|
| **ConsumableConfig** | ModuleScript | Yes | Returns a table: metadata, constraints, tuning (e.g. cooldown, duration). |
| **ConsumableServer** | ModuleScript | Yes | Server logic when the item is used (e.g. heal player, apply buff). |
| **ConsumableClient** | ModuleScript | Yes | Client-side visuals, sounds, input feedback. |
| **Animations/** | Folder | No | Animation instances for use animation. |
| **VFX/** | Folder | No | ParticleEmitters, Beams, etc. |
| **SFX/** | Folder | No | Sound instances. |
| **Projectile/** | Model | No | For throwables; mesh to clone as projectile. |

The folder name (e.g. `Bandage`) is how the game links an inventory item (whose `tid` = templateId) to this behavior.

### 5.3 What to add in the codebase

**Step 1 — Item template**  
Create or edit a module under **Configs/Items/Consumables/** (e.g. `Healing.luau`). Define a table with `category = "Consumable"`, `subcategory` (e.g. `"Healing"`), and all base fields. The **templateId must match the folder name** under `Assets/Consumables/` (e.g. `Bandage`).

**Step 2 — Register and require**  
Call `ItemRegistry.Register(consumableTemplate)` and add the appropriate `require(script.Parent.Consumables.Healing)` (or your file) in ItemRegistry.luau.

**Step 3 — Implement behavior**  
Implement **ConsumableServer** and **ConsumableClient** inside the asset folder. When you add the “use consumable” flow (e.g. handling `RequestUseConsumable`), the game will require the folder’s modules by templateId; no new central service is needed beyond that wiring.

### 5.4 Checklist

- [ ] Folder `Assets.Consumables.<templateId>` with ConsumableConfig, ConsumableServer, ConsumableClient
- [ ] Optional: Animations/, VFX/, SFX/, Projectile/
- [ ] Item template in Configs/Items/Consumables/ with same templateId; `ItemRegistry.Register(...)`
- [ ] `require(script.Parent.Consumables.<YourFile>)` in ItemRegistry.luau
- [ ] ConsumableServer/Client scripts implement the desired behavior

---

## 6. Abilities

### 6.1 Purpose

Abilities are **not** items. They are slotted onto weapons (up to 5 per weapon tag) and activated in combat. Each ability is a self-contained folder under `Assets/Abilities/` with its own scripts, animations, and VFX. Compatibility with weapons is determined by **tags**: each weapon has one `weaponTag`; each ability has a list `compatibleTags`. An ability can be slotted on a weapon if the weapon’s tag is in that list.

### 6.2 Where to put things (Studio → ReplicatedStorage)

| What   | Path | Notes |
|--------|------|--------|
| **Folder** | `ReplicatedStorage.Assets.Abilities.<abilityId>` | Folder name = abilityId (e.g. `HeavySlash`) |

**Inside the folder:**

| Child | Type | Required? | Purpose |
|-------|------|-----------|---------|
| **AbilityConfig** | ModuleScript | Yes | Returns a table with at least **compatibleTags** (array of weapon tags, e.g. `{ "Greatsword", "Greataxe" }`), plus name, costs, tuning. |
| **AbilityServer** | ModuleScript | Yes | Server logic when the ability is activated (damage, buffs, cooldowns). |
| **AbilityClient** | ModuleScript | Yes | Client input, VFX, sounds. |
| **Animations/** | Folder | No | Animation instances. |
| **VFX/** | Folder | No | Slash trails, beams, etc. |
| **SFX/** | Folder | No | Sound instances. |

### 6.3 What to add in the codebase

**Nothing in ItemRegistry or item config.** Abilities are not items and are not registered as templates.

**AbilityDataService** already scans `ReplicatedStorage.Assets.Abilities` and, for each child folder, requires **AbilityConfig**. It uses **compatibleTags** to implement `GetCompatibleAbilities(weaponTag)`. So:

- **Folder name** must match the **abilityId** you use in ability presets (e.g. `HeavySlash`).
- **AbilityConfig** must return a table that includes `compatibleTags` (array of strings). Example:

```lua
return {
    abilityId       = "HeavySlash",
    displayName     = "Heavy Slash",
    compatibleTags  = { "Greatsword", "Greataxe", "GreatHammer" },
    -- ... costs, cooldown, etc.
}
```

When a player configures their ability bar for a weapon (e.g. Greatsword), the UI uses `GetCompatibleAbilities("Greatsword")` to list only abilities whose `compatibleTags` includes `"Greatsword"`. The preset (which 5 abilities are slotted) is stored per weapon tag in `PlayerData.abilityPresets`. Activation and cooldowns are implemented inside each ability’s Server/Client scripts when you build that layer.

### 6.4 Checklist

- [ ] Folder `Assets.Abilities.<abilityId>` with AbilityConfig, AbilityServer, AbilityClient
- [ ] AbilityConfig exports `compatibleTags` (array of weapon tags)
- [ ] Optional: Animations/, VFX/, SFX/
- [ ] No item template or ItemRegistry changes required

---

## 7. Icons and images

No separate “background icon image” is required for the system to function. Each item template has an **iconId** field (string). You can:

- Leave it `""` and use the current **ItemIconResolver** (returns `nil` and the item’s display name).
- Later set `iconId` to an `rbxassetid://...` and update ItemIconResolver (or an AssetResolver) to return that asset ID for tooltips and inventory slots.

---

## 8. Quick reference table

| Asset       | ReplicatedStorage path (Studio) | Code: config / registration |
|------------|----------------------------------|-----------------------------|
| **Weapon** | `Assets.Items.Weapons.<Subcategory>.<templateId>` or `Assets.Items.Weapons.Unique.<templateId>` (Model, Handle) | Configs/Items/Weapons/*.luau → Register; require in ItemRegistry |
| **Armor**  | `Assets.Items.Armor.<templateId>` (optional Model) | Configs/Items/Armor/*.luau → Register; require in ItemRegistry |
| **Backpack** | `Assets.Items.Backpacks.<templateId>` (Model) | Configs/Items/Backpacks/*.luau → Register; require in ItemRegistry |
| **Consumable** | `Assets.Consumables.<templateId>/` (Config + Server + Client + optional Animations/VFX/SFX/Projectile) | Configs/Items/Consumables/*.luau → Register; require in ItemRegistry |
| **Ability** | `Assets.Abilities.<abilityId>/` (AbilityConfig + AbilityServer + AbilityClient + optional Animations/VFX/SFX) | No item config; folder name = abilityId; compatibleTags in AbilityConfig |

---

## 9. Summary

- **Weapons, armor, backpacks, consumables:** each needs an **item template** in the right **Configs/Items/** module and a call to **ItemRegistry.Register(...)**, plus a **require** in **ItemRegistry.luau**. Weapons, armor, and backpacks need a **prefab** (Model) under **Assets/Items/**; consumables need a **folder** under **Assets/Consumables/** with config and behavior scripts.
- **Abilities:** no item template. Add a **folder** under **Assets/Abilities/** with **AbilityConfig** (including **compatibleTags**), **AbilityServer**, and **AbilityClient**. The existing AbilityDataService discovers them automatically.
- **Icons:** optional; use **iconId** on templates and resolve in ItemIconResolver when you add real assets.

For full prefab rules, tag system, and data persistence, see the [systems documentation](../systems/README.md).
