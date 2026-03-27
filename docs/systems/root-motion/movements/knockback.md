# `knockback`

Displacement **away from an `origin` point** in the horizontal plane, combined with an **upward tilt** to form a 3D knockback direction. Can run as **constant speed** for the full duration, or with an **eased decay** so speed falls toward zero (similar shaping idea to `dash`).

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `origin` | `Vector3` | Yes | — | Horizontal push from `(root.Position - origin)` flattened to XZ; degenerate → look / `-Z` fallback. |
| `distance` | `number` | Yes | — | Baseline speed `distance / duration` (or decay curve). |
| `duration` | `number` | Yes | — | Seconds. |
| `arcAngleDegrees` | `number?` | No | **35** | Tilt above horizontal (degrees). |
| `decay` | `boolean?` | No | **false** | **true** → per-frame decay (like `dash`); else constant velocity for full duration. |
| `easing` | `EasingId?` | No | **linear** | Only when `decay == true`. |
| `accelerationMultiplier` | `number?` | No | **1000** | `MaxForce = AssemblyMass ×` this value. |

When `decay == true`, implementation uses **`SPEED_SHARPNESS = 2`** (same as `dash`).

## Behavior

- Knockback direction: horizontal unit away from origin, rotated up by `arcAngleDegrees`, then normalized (`knockDir`).
- **`decay` not true**: single `acquireLinearVelocity` with `knockDir * base`, completes after `task.delay(duration)`.
- **`decay == true`**: frame updates reapply velocity with shrinking magnitude until time elapsed.

## Limitations

- No collision sweeps; strong forces can clip through thin geometry.
- When flattened horizontal direction is degenerate, fallback direction is heuristic—not always “camera relative” or “attacker relative” unless you choose `origin` carefully.

## See also

- [`dash`](./dash.md) — decayed speed profile details.
