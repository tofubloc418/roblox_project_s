# Items, weapon assets, and abilities

Rojo maps `src/shared/sharedNormalIsland/` to **`ReplicatedStorage`**. Configs live under `ReplicatedStorage.Configs`, shared item models under `ReplicatedStorage.Items`, and so on.

---

## How item data is registered

1. Add a **ModuleScript** under `src/shared/sharedNormalIsland/Configs/Items/` that **returns a table** keyed by `templateId` → template object.
2. Use **`ItemEnums`** (`Configs/Items/ItemEnums.luau`) for `category`, `subcategory`, `rarity`, and `weaponTag` instead of raw strings.
3. Wire the module in **`ItemRegistry.luau`**: the `registerFile(...)` calls at the bottom `require` each file and register every entry in the returned table.

`ItemRegistry` only asserts `templateId` and `category` at register time; weapons carry many more fields consumed by combat and clients—**copy an existing weapon file** (`Weapons/Greatswords.luau`, `Weapons/Axes.luau`, etc.) and edit.

---

## Weapons (3D asset + client logic)

**ReplicatedStorage path**

`Items.Weapons.<weaponTag>.<templateId>/`

- **`weaponTag`** must match the template’s `weaponTag` string (usually `ItemEnums.WeaponTag.*`).
- Standard weapon assets live at `Items.Weapons.<weaponTag>.<templateId>/`.
- Unique weapon assets live at `Items.Weapons.Unique.<templateId>/` while still keeping a unique `weaponTag` / `abilityPresetKey` such as `Unique_<templateId>`.
- **`modelAssetId`**: Roblox **Model** asset id in the same string form as other asset fields, e.g. **`"rbxassetid://1234567890"`**. Use **`"rbxassetid://0"`** when the mesh comes from a **`Model`** in the item folder instead. The server loads non-zero ids with `InsertService:LoadAsset` and clones the result for the equipped visual (`WeaponService`). With `"rbxassetid://0"`, the server uses a **`Model`** in the same folder named `<templateId>` or the first `Model` found.
- **`Logic`** (ModuleScript): required. The client requires it and calls `Equip(weaponModel, player, WeaponController)` / `Unequip()`. Use any existing weapon’s `Logic.luau` as a template.

Repo layout mirrors Studio: e.g. `src/shared/sharedNormalIsland/Items/Weapons/Axe/IronAxe/` with `Logic.luau` (and, only when `modelAssetId` is not set, a `Model` for the mesh). Unique examples follow `src/shared/sharedNormalIsland/Items/Weapons/Unique/<templateId>/`.

**New weapon type (tag)**  
If abilities and folders should key off a new tag, add it to **`ItemEnums.WeaponTag`** and **`ItemEnums.WeaponTagDisplayName`**.

---

## Armor, backpack, and other equipment categories

**Inventory** allows `Armor` and `Backpack` slots when the item template’s **`category`** matches that slot (`Weapon` for Weapon1/Weapon2, `Armor` for Armor, `Backpack` for Backpack)—see `InventoryService`’s slot map.

There is **no shared pipeline** in this repo that loads a 3D model for armor or backpack from a fixed path; registering the template is enough for inventory/UI.

---

## Consumables

Register templates with **`ItemEnums.Category.Consumable`** and a **`ItemEnums.Subcategory`** (e.g. `Healing`). Example fields: `TestItems.luau` → `TestBandage` (`useTime`, `cooldown`, `usableInCombat`).

Quick-use slots only accept consumables. **`RequestUseConsumable`** exists as a remote but **has no server handler** yet—there is no in-game “use consumable” behavior to hook today.

---

## Abilities (separate from items)

Abilities are **not** item templates.

1. **Config** — `src/shared/sharedNormalIsland/Configs/Abilities/`: module returns a list/table of **`AbilityConfig`** rows (`AbilityTypes.luau`). Include **`compatibleTags`** (weapon tag strings that may slot this ability). New files must be **`registerFile`’d** in **`AbilityRegistry.luau`** (same pattern as `Placeholder.luau`).
2. **Server** — `src/server/serverNormalIsland/Abilities/Scripts/<abilityId>.luau`: ModuleScript named like **`abilityId`**, with **`Execute`**, optional **`CanUse`** (see `PlaceholderSlash.luau`).
3. **Client** (optional) — `src/client/clientNormalIsland/Abilities/Scripts/<abilityId>.luau`: optional **`OnStarted`** when `AbilityStarted` fires (`AbilityExecutionController.client.luau`).

Preset keys for the ability bar come from **`GetPresetKey`**: `abilityPresetKey` on the weapon template if set, otherwise **`weaponTag`**.

---

## Icons

Templates use **`iconId`**. **`ItemIconResolver`** treats `nil`, `""`, and `rbxassetid://0` as “no icon” and falls back to **`displayName`**.

---

## Checklists

### Weapon

- [ ] Template in `Configs/Items/Weapons/<Module>.luau` (match fields to an existing weapon).
- [ ] `ItemEnums` updated if this is a **new** `weaponTag`.
- [ ] `registerFile(...)` for that module in **`ItemRegistry.luau`**.
- [ ] Folder **`Items.Weapons.<weaponTag>.<templateId>/`** with **`Logic`** ModuleScript plus **`modelAssetId`** on the template or an equip **Model** in that folder.

### Armor, backpack, or other equipment item

- [ ] Template `category` matches the target slot (`Armor`, `Backpack`, `Weapon`, …).
- [ ] Module under `Configs/Items/...` + **`registerFile`** in **`ItemRegistry.luau`**.

### Consumable (data only today)

- [ ] `category = Consumable`, subcategory from **`ItemEnums.Subcategory`**.
- [ ] Module + **`registerFile`** in **`ItemRegistry.luau`**.

### Ability

- [ ] Row in **`Configs/Abilities/`** with **`compatibleTags`** covering the right weapon tags / preset keys.
- [ ] **`AbilityRegistry.luau`** `registerFile` if you added a new config module.
- [ ] **`serverNormalIsland/Abilities/Scripts/<abilityId>.luau`** with **`Execute`** (and **`CanUse`** if needed).
- [ ] (Optional) **`clientNormalIsland/Abilities/Scripts/<abilityId>.luau`** with **`OnStarted`**.
