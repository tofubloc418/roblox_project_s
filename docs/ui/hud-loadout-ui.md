# HUD Loadout UI Specification

This document specifies the in-game HUD equipment section that appears in the lower-right corner of the screen. The design is inspired by the Arc Raiders equipment HUD, adapted to our game's systems and constraints.

---

## 1. Action key area (top of section)

- **Unarmed:** Do **not** implement an action key for "unarmed". There is no separate unarmed key in this UI.
- **Flashlight:** For now, only the **flashlight** action is shown in this area, with its keybind (e.g. a bar with the key centered).
- This area sits above or beside the main slot columns as the single "action" row for now.

---

## 2. Slot types and keybinds (four slots)

There are four logical slots, each with a **bar** attached to the top of a **visual slot**:

| Slot        | Keybind | Purpose                                      |
|------------|---------|----------------------------------------------|
| Quick slot | **Q**   | Current quick-use item; radial to change it. |
| Unequip    | **3**   | "Fists" — unequip all (like Arc Raiders' unarmed). |
| Weapon 1   | **1**   | First weapon slot.                           |
| Weapon 2   | **2**   | Second weapon slot.                          |

- **Bar (all slots):** A bar attached to the **top** of the square visual slot. The bar shows the **keybind**, centered.
- **Weapon bars only:** Keybind is **left-aligned**, weapon **name** is **right-aligned** in the same bar.
- Because the weapon bar must fit the name, the weapon **visual slot** is **slightly wider than a square** (still compact compared to Arc Raiders' long rectangles). Bar width matches the slot width.

---

## 3. Column layout (three columns)

- **Three columns**, left to right:
  1. **Left:** Q (quick slot).
  2. **Middle:** 3 (unequip / fists).
  3. **Right:** 1 and 2 (weapon slots, stacked vertically).

- **Spacing:** **16 pt** gap between each of the three column wrapper frames.
- **Alignment:** All three column frames are **bottom-aligned** with each other.

---

## 4. Weapon slots (right column) — no ammo, square-ish shape

- **No ammo display.** We do not show ammo in this HUD (bows are an exception handled elsewhere; not a problem for this UI).
- **Shape:** Arc Raiders uses long rectangles for gun shape + ammo. Our weapon icons are **square** (same as in inventory). Weapon slots are therefore **smaller in width**, **closer to squares** than long rectangles—with the caveat that the weapon slot is **slightly wider than a square** so the top bar can fit the keybind + weapon name (see above).
- **Two weapon cards** in the right column share the same **16 pt** gap as between the three columns (i.e. 16 pt between the two weapon cards).

---

## 5. Weapon column: active vs inactive, show/hide behavior

- **Equipped (active) weapon:** Shows both the **label bar** (key + name) and the **visual slot** (weapon icon).
- **Inactive weapon:** Shows **only the label bar** (no visual slot).

**When the active weapon changes:**

- **Switch between weapon 1 and weapon 2:**  
  The weapon that becomes **inactive** has its **visual card shrink to nothing** (only the label bar remains). The newly active weapon gains the full bar + visual.

- **Switch from a weapon to Q or 3 (quick slot or unequip):**  
  The weapon cards **do not change**. The **last active weapon** keeps showing its **full visual** (bar + visual slot); nothing shrinks. Only when the user switches to the *other* weapon do we run the shrink/expand logic.

**Vertical growth:**

- Because columns are **bottom-aligned**, showing or hiding the weapon visual cards **only ever pushes content upward**; the bottom of the column stays fixed.

---

## 6. Quick slot (Q) behavior

- **Tap Q:** Equip the **current** quick slot item (the one selected in the radial).
- **Hold Q + move mouse:** Open the **radial dial** to choose which quick slot item is "current," then equip that item. The radial options must match the **quick slot section of the loadout** (same items, same order).

For a full technical breakdown of how the radial dial works -- segment rendering, hover effect, virtual cursor, camera lock, slot selection math, and how to reuse the module for other purposes -- see **[radial-dial.md](radial-dial.md)**.

---

## 7. Integration with loadout and single source of truth

- **Sync with loadout:**  
  The HUD equipment section must be **directly synced** with:
  - The **loadout equipment area** (weapons, etc.).
  - The **loadout quick slot area** (quick-use items).

- **Weapons:** What appears in the two weapon slots on the HUD must **match** the two equipped weapons in the loadout.
- **Quick slots:** The **radial dial** for quick use must show and operate on the **same items** as the quick slot section of the loadout.

- **Single source of truth:**  
  The **player HUD loadout section** and the **loadout screen** must share **one source of truth** that defines:
  - Which weapons are equipped (slots 1 and 2).
  - Which items are in the quick slots and which one is "current" for Q.
  - Unequip state (3 / fists).

- **Modularization for data:**  
  The HUD loadout UI code must be **modularized** so that:
  - It is straightforward to **connect the UI to the source-of-truth database** later.
  - Data flow (read/update of equipped weapons, quick slot items, current quick slot) can be swapped or wired to a backend without rewriting the whole UI.

---

## 8. Summary Checklist

- [ ] **Action area:** No unarmed key; only flashlight for now.
- [ ] **Four slots:** Q, 3, 1, 2 — each with a top bar (keybind centered; for weapons: key left, name right) and visual slot.
- [ ] **Weapon slots:** No ammo; slightly wider than square to fit name in bar; 16 pt gap between the two weapon cards.
- [ ] **Three columns:** Q | 3 | 1—2; 16 pt gap between columns; bottom-aligned.
- [ ] **Active weapon:** Bar + visual; inactive: bar only. Shrink visual only when switching between weapon 1 and 2; no change when switching to Q or 3.
- [ ] **Q:** Tap = equip current quick item; hold + mouse = radial to set current and equip. Radial matches loadout quick slots.
- [ ] **Slot 3:** Fists (unequip all).
- [ ] **Single source of truth:** HUD and loadout share one source of truth; UI code modular for future database connection.
