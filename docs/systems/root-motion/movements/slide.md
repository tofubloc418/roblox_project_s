# `slide`

Ground-aware **horizontal slide**: projects a flat **direction** onto the **ground plane** (using a downward ray for surface normal), applies `LinearVelocity` along the slide vector, and **exponentially decays** speed each frame (friction) until **duration** ends or speed falls below a small threshold.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `direction` | `Vector3` | Yes | XZ component must be non-zero after flattening; normalized on XZ. |
| `speed` | `number` | Yes | Initial slide speed magnitude along **slide direction** (updated each frame after decay). |
| `duration` | `number` | Yes | Max slide time; clamped to a small minimum. |
| `friction` | `number?` | No | Per-second decay base; default **`0.92`**. Each step: `speed *= friction ^ (dt * 60)` (frame-rate scaled exponential). |
| `groundRayLength` | `number?` | No | Downward ray for ground normal; default **`4`**. |
| `accelerationMultiplier` | `number?` | No | Scales `maxForce` for `LinearVelocity`. |

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
