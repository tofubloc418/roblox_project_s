# `pull`

Steers the character toward a fixed **world target** at a constant **speed** until the root comes within an **arrival radius** or **max duration** is reached. Each frame sets `LinearVelocity` along the **full 3D** vector from root to target (not XZ-only).

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `target` | `Vector3` | Yes | — | World position to approach. |
| `speed` | `number` | Yes | — | Speed along `toTarget.Unit` (3D). |
| `maxDuration` | `number` | Yes | — | Hard cap on pull time; clamped to a small minimum. |
| `arrivalRadius` | `number?` | No | **1** | Finish when ‖target − position‖ ≤ this (studs). |
| `accelerationMultiplier` | `number?` | No | **1000** | `MaxForce = AssemblyMass ×` this value. |

## Behavior

- Each frame: if distance to `target` ≤ `arrivalRadius`, finish (success).
- Else if `elapsed >= maxDuration`, finish (may still be short of target).
- Else set velocity to `toTarget.Unit * speed`.

## Limitations

- **Overshoot**: constant speed toward a point does not slow near the target; with high speed and large `dt`, the root can pass the target between frames and oscillate or stop on timeout instead of “snapping.” Tune `speed`, `arrivalRadius`, or use [`springTo`](./spring-to.md) for gentle docking.
- Does not pathfind around obstacles; pulls straight through geometry unless physics blocks.

## See also

- [`springTo`](./spring-to.md) — `AlignPosition` chase to a point.
- [`orbit`](./orbit.md) — constrained circular motion.
