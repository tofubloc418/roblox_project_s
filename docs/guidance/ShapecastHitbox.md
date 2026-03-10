# ShapecastHitbox API Documentation

`ShapecastHitbox` is a high-performance hitbox module that enables precise hit registration for melee weapons and projectiles via Raycasts, Blockcasts, and Spherecasts. 

This guide outlines how to use the API and how to configure your physical models to work seamlessly with the system.

## 1. Model Setup Requirements

To cast hitboxes from a model or part, you must place specific instances within it. `ShapecastHitbox` will scan the provided instance for these points and cast from them.

### Defining Damage Points
- **Instances**: Add an `Attachment` or `Bone` into the part you want to become the hitbox.
- **Naming/Tagging**: You must rename this `Attachment` or `Bone` to `"DmgPoint"` or add the CollectionService tag `"DmgPoint"` to it.

### Configuring Cast Types
By default, all `"DmgPoint"` instances will behave as standard **Raycasts**. To use a **Blockcast** or **Spherecast**, you have two options:

**Method 1: Using Attributes (Per-Point Configuration)**
You can adjust individual points by adding specific attributes directly to the `Attachment` or `Bone`.
- **`CastType`** (String): Set to `"Blockcast"`, `"Spherecast"`, or `"Raycast"`.
- **`CastSize`** (Vector3): Required for `"Blockcast"`. Defines the dimensions of the block.
- **`CastRadius`** (Number): Required for `"Spherecast"`. Defines the radius of the sphere.
- **`CastCFrame`** (CFrame): Optional for `"Blockcast"`. Adjusts the orientation of the blockcast.

**Method 2: Using Code (Global Hitbox Configuration)**
If you want the entire hitbox (all points) to be a specific shape, you can overwrite them programmatically using `Hitbox:SetCastData()`.

---

## 2. Hitbox Initialization

### `ShapecastHitbox.new(instance: Instance, raycastParams: RaycastParams?) -> Hitbox`
Creates a new hitbox referencing the `instance`. It automatically searches for any descendants marked as `"DmgPoint"`.
```lua
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {character}

local hitbox = ShapecastHitbox.new(weaponModel, params)
```

---

## 3. Hitbox Configuration & Methods

### `Hitbox:SetCastData(castData: CastData)`
Sets the default cast shapes for all points in the hitbox. If an individual point has attributes (from Method 1), the attributes take priority.
```lua
hitbox:SetCastData({
    CastType = "Blockcast",
    Size = Vector3.new(2, 2, 2),
    CFrame = CFrame.identity
})
```

### `Hitbox:SetResolution(resolution: number)`
Sets the raycast refresh rate. Capped to the user's current frame rate. Lower resolution means slightly less accuracy but better performance. Default is `60`.
```lua
hitbox:SetResolution(30)
```

### `Hitbox:Reconcile()`
Rescans the initialized model for any newly added `"DmgPoint"` instances since creation. This shouldn't be run highly frequently.
```lua
hitbox:Reconcile()
```

---

## 4. Activation Methods

### `Hitbox:HitStart(timer: number?, overrideParams: RaycastParams?)`
Activates the hitbox. You can optionally supply a `timer` (in seconds) which automatically stops the hitbox after the duration. You can also temporarily override the active `RaycastParams`.
```lua
-- Runs for 0.5 seconds then automatically calls HitStop()
hitbox:HitStart(0.5)
```

### `Hitbox:HitStop()`
Deactivates the hitbox and stops raycasting.

### `Hitbox:Destroy()`
Irreversibly cleans up and garbage-collects the hitbox. Always do this when the weapon is unequipped or destroyed to prevent memory leaks.

---

## 5. Hitbox Callbacks (Chainable)

All callback functions are highly chainable for cleaner code. 

> **Important**: Keep in mind that calling callbacks multiple times (e.g., in a loop) creates stacking event connections. You must clean up those callbacks within `OnStopped` via the `cleanCallbacks` function to prevent memory leaks and duplicate logic executions.

### `Hitbox:BeforeStart(callback: () -> ())`
Fires right before the hitbox starts casting. Usually used to set initial state values.

### `Hitbox:OnHit(callback: (raycastResult: RaycastResult, segmentHit: Segment) -> ())`
Fires every time the cast intersects with an un-ignored part. **ShapecastHitbox detects multiple hits per part intentionally for performance**, so you must debounce hit targets yourself.

### `Hitbox:OnUpdate(callback: (deltaTime: number) -> ())`
Fires every frame while the hitbox exists, regardless of whether it's currently active.

### `Hitbox:OnStopped(callback: (cleanCallbacks: () -> ()) -> ())`
Fires when the hitbox finishes stopping. Provide the argument `cleanCallbacks` to easily clean all previously chained connections.

### Comprehensive Callback Example
```lua
local hitbox = ShapecastHitbox.new(weapon)
local targetsHit = {}

hitbox:BeforeStart(function()
    table.clear(targetsHit)
end):OnHit(function(raycastResult, segmentHit)
    -- Debouncing hit targets so we don't damage them multiple times
    local hitModel = raycastResult.Instance.Parent
    if targetsHit[hitModel] then return end
    targetsHit[hitModel] = true

    local humanoid = hitModel:FindFirstChild("Humanoid")
    if humanoid then humanoid:TakeDamage(25) end
end):OnStopped(function(cleanCallbacks)
    -- Always clean callbacks if you plan to reuse this exact hitbox instance
    -- to prevent stacked connections!
    cleanCallbacks()
end)

-- Execute the hitbox logic
hitbox:HitStart(1) -- run for 1 second
```

---

## 6. Debugging

You can preview hitboxes by enabling debugging in the module settings. Access settings using:
```lua
ShapecastHitbox.Settings.Debug_Visible = true
```
This renders trails and adornments so you can visually verify your points and cast shapes!
