# `slide`

Ground-aware **horizontal slide**: projects a flat **direction** onto the **ground plane** (using a downward ray for surface normal), applies `LinearVelocity` along the slide vector, and **exponentially decays** speed each frame (friction) until **duration** ends or speed falls below a small threshold.

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `direction` | `Vector3` | Yes | — | XZ must be non-zero after flattening; normalized on XZ. |
| `speed` | `number` | Yes | — | Initial slide speed along slide direction; decayed each step. |
| `duration` | `number` | Yes | — | Max slide time; clamped to a small minimum. |
| `friction` | `number?` | No | **0.92** | Per-step decay: `speed *= friction ^ (dt * 60)`. |
| `groundRayLength` | `number?` | No | **4** | Studs; downward ray for ground normal. |
| `accelerationMultiplier` | `number?` | No | **1000** | `MaxForce = AssemblyMass ×` this value. |

Also ends when **`speed < 0.35`** (hard-coded).

## Behavior

- Ground normal: `PhysicsHelpers.getGroundNormal(root, rayLen)` or **`Vector3.yAxis`** if no hit—then slide direction is `horiz` projected onto the plane perpendicular to `n`, normalized.
- Stops when `elapsed >= duration` **or** `speed < 0.35`.

## Limitations

- If the character **loses ground** (normal falls back to world up), the projection still runs but may not match a “true” slide down a slope in air.
- Friction model is a simple exponential on a scalar speed, not a full friction cone or material curve.
- Threshold **`0.35`** and decay formula are hard-coded.

## See also

- [`slam`](./slam.md) — uses `isGrounded` with different constants.
- [`dash`](./dash.md) / [`translate`](./translate.md) — non-ground-locked horizontal moves.
