# `slam`

Applies **downward** `LinearVelocity` each frame until the character is **grounded** (per ray + vertical velocity check) or **`maxDuration`** elapses.

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `speed` | `number` | Yes | — | Downward velocity magnitude (`Vector3.new(0, -speed, 0)`). |
| `maxDuration` | `number?` | No | **4** (s) | Safety cap if ground is never detected. |
| `accelerationMultiplier` | `number?` | No | **1000** | `MaxForce = AssemblyMass ×` this value. |

Ground detection (not tunable via params): ray length **3.5**, land when grounded and `AssemblyLinearVelocity.Y <= 1.5`.

## Behavior

- Each frame: if `PhysicsHelpers.isGrounded(rootPart, 3.5, nil)` and `AssemblyLinearVelocity.Y <= 1.5`, movement **completes** (treated as landed).
- Otherwise reapplies downward velocity (until timeout).

## Limitations

- **Ground detection** uses a default downward ray from root (excluding the character’s parent model). Steep inward corners, thin triggers, or unusual `Humanoid`/hip height can cause false negatives → runs until `maxDuration`.
- Does not guarantee damage or hitbox events; this module only moves the rig.
- Ground ray length **`3.5`** and velocity threshold **`1.5`** are fixed in code.

## See also

- [`slide`](./slide.md) — ground-normal-aware horizontal slide.
- `sharedNormalIsland/Modules/RootMotion/PhysicsHelpers.luau` — `isGrounded`.
