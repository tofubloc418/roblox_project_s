# `translate`

Constant-speed **linear** displacement along a world-space direction for a fixed **distance** and **duration**. Implemented with `LinearVelocity` on the mover’s root attachment.

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `direction` | `Vector3` | Yes | — | Must be non-zero; normalized internally. |
| `distance` | `number` | Yes | — | Studs to travel over the window. |
| `duration` | `number` | Yes | — | Seconds; clamped to a small minimum (~`1e-3`). |
| `accelerationMultiplier` | `number?` | No | **1000** | `LinearVelocity.MaxForce = AssemblyMass ×` this value (`RootMotion.DEFAULT_ACCEL_MULT`). |

## Behavior

- Computes `speed = distance / duration` and drives `LinearVelocity` at `direction.Unit * speed` for the whole duration.
- Completes automatically after `duration` via `task.delay`; **no** per-frame speed curve (unlike `dash`).

## Limitations

- Does not collide-check the path; the rig can be blocked or pushed by physics unless forces are high enough to penetrate obstacles (usually undesirable—tune `accelerationMultiplier` or use shorter segments).
- Vertical component is allowed; combined with gravity, arcs are not “ballistic” unless you separately account for gravity (unlike `launch`).

## See also

- [`dash`](./dash.md) — eased / front-loaded speed profile.
- [`lunge`](./lunge.md) — translate with default distance/duration.
