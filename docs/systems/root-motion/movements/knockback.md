# `knockback`

Displacement **away from an `origin` point** in the horizontal plane, combined with an **upward tilt** to form a 3D knockback direction. Can run as **constant speed** for the full duration, or with an **eased decay** so speed falls toward zero (similar shaping idea to `dash`).

## Parameters


| Parameter                | Type        | Required | Notes                                                                                                                                                                                 |
| ------------------------ | ----------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `origin`                 | `Vector3`   | Yes      | Horizontal push direction is `(root.Position - origin)` flattened to XZ. If that vector is ~zero, falls back to opposite of HRP look (XZ), then `-Z`.                                 |
| `distance`               | `number`    | Yes      | Used with duration for baseline speed `distance / duration` (or decay curve).                                                                                                         |
| `duration`               | `number`    | Yes      | Seconds.                                                                                                                                                                              |
| `arcAngleDegrees`        | `number?`   | No       | Tilt of knockback above horizontal; default `**35`**°. Larger = more vertical component.                                                                                              |
| `decay`                  | `boolean?`  | No       | If `**true**`, per-frame speed uses `1 - ease(elapsed/duration)` × `base * SPEED_SHARPNESS` (see `dash`). If **false/omitted**, **constant** `LinearVelocity` for the whole duration. |
| `easing`                 | `EasingId?` | No       | Used when `decay == true`; if omitted, **linear** via `Easing.byId`.                                                                                                                  |
| `accelerationMultiplier` | `number?`   | No       | Scales `maxForce`.                                                                                                                                                                    |


## Behavior

- Knockback direction: horizontal unit away from origin, rotated up by `arcAngleDegrees`, then normalized (`knockDir`).
- `**decay == false`**: single `acquireLinearVelocity` with `knockDir * base`, completes after `task.delay(duration)`.
- `**decay == true**`: frame updates reapply velocity with shrinking magnitude until time elapsed.

## Limitations

- No collision sweeps; strong forces can clip through thin geometry.
- When flattened horizontal direction is degenerate, fallback direction is heuristic—not always “camera relative” or “attacker relative” unless you choose `origin` carefully.

## See also

- `[dash](./dash.md)` — decayed speed profile details.

