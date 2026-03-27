# `springTo`

Drives the root toward a **target** world position using **`AlignPosition`** (one attachment on the mover): combines `maxForce`, **`Responsiveness`** (from `frequency`), and **`MaxVelocity`** cap (`maxVelocity` or legacy `damping` field). Auto-completes after **`maxDuration`**.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `target` | `Vector3` | Yes | World position for `AlignPosition.Position`. |
| `frequency` | `number?` | No | Mapped to `AlignPosition.Responsiveness`; default **`10`**. |
| `maxVelocity` | `number?` | No | `AlignPosition.MaxVelocity`; default **`40`**. |
| `damping` | `number?` | No | If **`maxVelocity`** is omitted, **`damping`** is used **as** `MaxVelocity` (naming quirk in `Types.SpringToParams`). |
| `maxDuration` | `number?` | No | Default **`4`** seconds, then token finishes even if not fully converged. |
| `maxForce` | `number?` | No | If omitted, uses `Util.maxForceFor(mover, accelerationMultiplier)` (mass × multiplier). |
| `accelerationMultiplier` | `number?` | No | Used only when **`maxForce`** is nil. |
| `applyAtCenterOfMass` | `boolean?` | No | `AlignPosition.ApplyAtCenterOfMass`; default **`true`**. |

## Behavior

- Single `acquireAlignPosition(token, target, maxForce, maxVel, responsiveness, applyCom)` then `task.delay(maxDuration)` → `finish`.

## Limitations

- **Timeout completion**: may stop before reaching `target` if `maxDuration` is short or `MaxVelocity` / force caps are low.
- Can conflict with other mover channels: only one align owner at a time; starting another align-based custom move would cancel this one via `stealAP`.
- Obstacles between root and target are **not** path-planned; the constraint will apply forces into walls until timeout or equilibrium.

## See also

- [`pull`](./pull.md) — velocity steering (no constraint spring).
- [`teleport`](./teleport.md) — instant placement.
