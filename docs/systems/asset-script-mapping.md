# Asset-Script Mapping & Item Organization

## Overview
This document outlines the standard architecture for mapping functional behavior to physical in-game models (like weapons, armor, interactables) across the repository. It defines our file structure, separation of code vs. assets, and how external resources like animations, sounds, and VFX should be handled.

## Architecture Pattern: Data & Class Separation
We enforce a strict separation between physical assets (Models, Parts) and purely functional logic (Scripts). Scripts should **never** be parented directly inside of Models (`.rbxmx` files). 

Instead, the script that defines a weapon's or item's behavior claims and acts upon the physical model dynamically at runtime.

### 1. Folder Structure: The "One Folder Per Item" Pattern
To keep the codebase maintainable, we group the `.rbxmx` asset and its corresponding `.luau` logic into a single dedicated folder per item. These items are strictly categorized into subdirectories based on our `ItemEnums` subcategories (e.g., `Dagger`, `Greatsword`, `Consumable`).

Unlike generic utility scripts (which live in `ReplicatedStorage/Modules`), items deserve their own dedicated root directory to avoid cluttering core game modules.

**Example Structure (`ReplicatedStorage/Items/`):**
```text
src/shared/sharedNormalIsland/Items/ (Maps to ReplicatedStorage/Items/)
├── Weapons/
│   ├── Dagger/
│   │   ├── IronDagger/
│   │   │   ├── IronDagger.rbxmx      <-- The pure visual asset (No Scripts inside)
│   │   │   └── IronDaggerLogic.luau  <-- The controller script for this specific item
│   │   └── SteelDagger/
│   │       ├── SteelDagger.rbxmx
│   │       └── SteelDaggerLogic.luau
│   ├── Greatsword/
│   │   └── BusterSword/
│   │       ├── BusterSword.rbxmx
│   │       └── BusterSwordLogic.luau
├── Armor/
└── Consumables/
    └── HealthPotion/
        ├── HealthPotion.rbxmx
        └── HealthPotionLogic.luau
```

### 2. The Implementation Pattern
When an event triggers that requires an item (such as a Player equipping an `IronDagger`), the game’s core equipping pipeline does the following:

1. Looks up the item directory (`ReplicatedStorage/Items/Weapons/Dagger/IronDagger`).
2. Clones the actual model (`IronDagger.rbxmx`).
3. Passes that cloned Instance into the item's corresponding logic module (`IronDaggerLogic.luau`).

**Example Logic Module Pattern:**
```luau
local IronDaggerLogic = {}

-- The pure model is passed to this module upon equip/spawn
function IronDaggerLogic.Equip(weaponModel: Model, player: Player)
    -- All logic is bound to the passed-in model instance here.
    -- The script expects the model to have a "Hitbox" part.
    local hitbox = weaponModel:FindFirstChild("Hitbox") :: BasePart
    
    hitbox.Touched:Connect(function(hit) 
        -- Handle collision logic here
    end)
end

function IronDaggerLogic.Unequip(weaponModel: Model, player: Player)
    -- Cleanup logic: disconnect events, destroy hitbox attachments, etc.
end

return IronDaggerLogic
```

### 3. Handling Animations, VFX, and Sounds
Roblox heavily relies on asset IDs for Animations and Audio. You must decide whether to physically store these items as Instances in the codebase or simply reference them by their `rbxassetid://` strings.

#### Shared vs. Unique Resources
* **Shared Resources:** Things like a generic `GreatswordSwing` animation, or a standard `MetalClash` sound effect that applies to many items.
* **Unique Resources:** A unique VFX particle emitter that forms exactly on the blade of the `BusterSword`.

#### Best Practices for Organization
1. **Animations and Sounds (Reference via ID):**
   You **do not need** to physically store `Animation` or `Sound` instances in the `.rbxmx` files or Rojo codebase unless they are strictly required to be previewed visually inside Roblox Studio. 
   Instead, store their IDs in your item configurations (`Configs/Items/`). Your codebase should create the `Animation` or `Sound` instance at runtime dynamically using the ID string.
   
2. **Shared VFX/Particles (`ReplicatedStorage/SharedResources/`):**
   If multiple weapons use the same spark particle, store a single instance of that ParticleEmitter in a shared directory (`src/shared/sharedNormalIsland/SharedResources/VFX/Sparks.rbxmx`). The item script can clone this standard emitter and attach it to the weapon's model at runtime.

3. **Unique VFX (Stored within Item `.rbxmx`):**
   If a weapon has highly customized visual effects (e.g., a fiery aura that is perfectly sized and positioned to a specific sword mesh), those particle emitters and attachments should be saved natively inside the weapon's `BusterSword.rbxmx` model. The logic module (`BusterSwordLogic.luau`) can simply toggle `Particles.Enabled = true` when required.

### Benefits of this Pattern
- **Self-Contained Items:** Everything required to make the `IronDagger` work visually and mechanically is grouped flawlessly into a single folder. 
- **Asset Swapping is Painless:** Modelers can completely overhaul the `.rbxmx` visual asset without ever touching code. As long as base requirements (e.g. naming the blade part `Hitbox`) are met, the code continues to execute flawlessly.
- **Single Source of Truth:** Your Luau lives cleanly inside your IDE workspace, safe from accidental deletion that occurs frequently when working with scripts embedded inside Studio instances.
