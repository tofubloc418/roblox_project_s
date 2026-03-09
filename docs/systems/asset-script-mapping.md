# Asset-Script Mapping

## Overview
This document outlines the standard architecture for mapping functional behavior to physical in-game models (like weapons, abilities, interactables) in this repository.

## Architecture Pattern: Data & Class Separation
We enforce a strict separation between physical assets (Models, Parts) and logic (Scripts). Scripts should **never** be placed inside Models directly. Instead, models and scripts live in separate hierarchies, and the scripts "claim" or act upon the models at runtime.

### 1. Folder Structure
- **Assets Directory (`ReplicatedStorage/Assets/`)**: Contains pure physical instances (e.g., your exported `.rbxmx` models). These should be entirely devoid of any scripts.
- **Code Directory (`ReplicatedStorage/Modules/`)**: Contains the modular `.luau` files responsible for the behavior of those assets.

### 2. The Implementation Pattern
Instead of placing a `Script` under an interactable object, a "Manager" or "Controller" handles the item's creation and binding. 

When an event triggers that requires an asset (such as a Player equipping a weapon), the specific manager does the following:
1. Clones the actual model out of `ReplicatedStorage/Assets`.
2. Passes that model's Roblox Instance reference into the item's corresponding Behavior Module.

**Example Behavior Module Pattern:**
```lua
local DaggerLogic = {}

-- The pure model is passed to this module upon equip/spawn
function DaggerLogic.Equip(weaponModel: Model, player: Player)
    -- All logic is bound to the passed-in model instance here
    -- There is an expectation that the model has specific named parts
    
    local hitbox = weaponModel:FindFirstChild("Hitbox") :: BasePart
    
    hitbox.Touched:Connect(function(hit) 
        -- Handle collision logic here
    end)
end

function DaggerLogic.Unequip(weaponModel: Model, player: Player)
    -- Cleanup logic
end

return DaggerLogic
```

### Benefits of this Pattern
- **Asset Swapping is Painless:** Builders, modelers, or even yourself can delete, replace, and overhaul a `.rbxmx` asset. As long as the base requirements (like a `Hitbox` part continuing to exist) are met, the code will flawlessly run.
- **Zero Risk Code Deletion:** Modifying a physical asset inside of Studio cannot accidentally delete embedded code blocks.
- **Single Source of Truth:** All your Luau cleanly lives together securely inside your IDE workspace tree.
- **Polymorphism Support:** Multiple distinct physical dagger models can share the exact same `DaggerLogic` without replicating the actual script.
