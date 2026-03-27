# `slam`

Applies **downward** `LinearVelocity` each frame until the character is **grounded** (per ray + vertical velocity check) or **`maxDuration`** elapses.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `speed` | `number` | Yes | Magnitude of downward velocity (`Vector3.new(0, -speed, 0)`). |
| `maxDuration` | `number?` | No | Default **`4`** seconds: safety cap if ground is never detected. |
| `accelerationMultiplier` | `number?` | No | Scales `maxForce`. |

## Behavior

- Each frame: if `PhysicsHelpers.isGrounded(rootPart, 3.5, nil)` and `AssemblyLinearVelocity.Y <= 1.5`, movement **completes** (treated as landed).
- Otherwise reapplies downward velocity (until timeout).

## Limitations

- **Ground detection** uses a default downward ray from root (excluding the character’s parent model). Steep inward corners, thin triggers, or unusual `Humanoid`/hip height can cause false negatives → runs until `maxDuration`.
- Does not guarantee damage or hitbox events; this module only moves the rig.
- Hard-coded grounded ray length **`3.5`** and velocity threshold **`1.5`** are not exposed as parameters on this move type.

## See also

- [`slide`](./slide.md) — ground-normal-aware horizontal slide.
- `sharedNormalIsland/Modules/RootMotion/PhysicsHelpers.luau` — `isGrounded`.
