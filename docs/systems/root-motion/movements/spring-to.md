# `springTo`

Drives the root toward a **target** world position using **`AlignPosition`** (one attachment on the mover): combines `maxForce`, **`Responsiveness`** (from `frequency`), and **`MaxVelocity`** cap (`maxVelocity` or legacy `damping` field). Auto-completes after **`maxDuration`**.

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `target` | `Vector3` | Yes | — | `AlignPosition.Position`. |
| `frequency` | `number?` | No | **10** | `AlignPosition.Responsiveness`. |
| `maxVelocity` | `number?` | No | **40*** | `AlignPosition.MaxVelocity`. |
| `damping` | `number?` | No | — | If **`maxVelocity`** is omitted, **`damping`** is used **as** `MaxVelocity` (types quirk). |
| `maxDuration` | `number?` | No | **4** (s) | Then token finishes even if not converged. |
| `maxForce` | `number?` | No | **derived** | If omitted: `AssemblyMass × accelerationMultiplier`. |
| `accelerationMultiplier` | `number?` | No | **1000** | Used **only when `maxForce` is nil** (`mass ×` this). |
| `applyAtCenterOfMass` | `boolean?` | No | **true** | `AlignPosition.ApplyAtCenterOfMass`; pass **false** to disable. |

\*Effective `MaxVelocity` = `params.maxVelocity or params.damping or 40`.

## Behavior

- Single `acquireAlignPosition(token, target, maxForce, maxVel, responsiveness, applyCom)` then `task.delay(maxDuration)` → `finish`.

## Limitations

- **Timeout completion**: may stop before reaching `target` if `maxDuration` is short or `MaxVelocity` / force caps are low.
- Can conflict with other mover channels: only one align owner at a time; starting another align-based custom move would cancel this one via `stealAP`.
- Obstacles between root and target are **not** path-planned; the constraint will apply forces into walls until timeout or equilibrium.

## See also

- [`pull`](./pull.md) — velocity steering (no constraint spring).
- [`teleport`](./teleport.md) — instant placement.
