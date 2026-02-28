# Loadout UI Overview

This document describes the loadout screen in detail, breaking down the structure and core behaviors for each section. The design is strongly influenced by the Arc Raiders loadout UI.

![Reference: Arc Raiders Loadout UI](../images/arc%20raiders%20loadout%20ui.png)

---

## Layout

The loadout screen consists of three main sections, ordered left-to-right:

1. **Equipment**
2. **Inventory**
3. **Quick Use Slots**

*Note: There is also a "Safe Pocket" feature in the Arc Raiders UI, but this will **not** be a feature of our game (at least not in this aspect.)*

---

## 1. Equipment Section

- **Structure:**  
  - The Equipment section is visually and functionally inspired by Arc Raiders.
  - At the top: *Backpack* slot and *Shield* slot.
  - Below: Two *Equipped Weapon* slots.

- **Weapon Abilities:**  
  - Unlike Arc Raiders (which feature weapon augments like mags, silencers, etc.), our system replaces those augment slots with **ability slots**.
  - Each weapon can have **up to 5 abilities** equipped.
    - A maximum of **one** of these can be an *Ultimate* ability.  
      (Alternatively, a weapon may have 5 non-ultimate abilities.)
  - Players may freely arrange the order of abilities; their chosen order will be reflected in the in-game HUD's "active weapon abilities" UI. 

---

## 2. Inventory Section

- **Function:**  
  - The Inventory section displays a grid of square slots.
  - Each slot can contain a stack of items.
  - The maximum stack size per item is defined by its config.  

---

## 3. Quick Use Section

- **Functionality:**  
  - The Quick Use bar displays items the player can move here from their inventory.
  - It functions similarly to a separate, smaller inventory—**but only items with the `usable` tag can occupy these slots**.
  - In the inventory screen, this is a UI similar to the normal Inventory UI.  
    In-game, it will correspond to a radial selector for selecting the current usable items (just like in Arc Raiders).  

---