# `dash`

**Eased** horizontal-style dash: applies `LinearVelocity` updated every frame so apparent **speed ramps down** over the duration (stronger at the start, weaker at the end), using a configurable easing curve.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `direction` | `Vector3` | Yes | Must be non-zero; normalized internally. |
| `distance` | `number` | Yes | Used with duration to derive a baseline speed (`distance / duration`). |
| `duration` | `number` | Yes | Seconds; clamped to a small minimum. |
| `easing` | `EasingId?` | No | `linear` \| `quadOut` \| `quadIn` \| `cubicOut` \| `cubicIn`. If omitted, **linear**. |
| `accelerationMultiplier` | `number?` | No | Scales `maxForce` for `LinearVelocity`. |

`EasingId` is defined on `RootMotion.Types`.

## Behavior

- Each frame: `u = clamp(elapsed / duration, 0, 1)`, then `factor = 1 - ease(u)`, then `speed = base * SPEED_SHARPNESS * factor` where `base = distance / duration` and `SPEED_SHARPNESS` is `2` in code.
- So at **end** of the dash, `factor` → `0` and speed → `0` (finish fires when `elapsed >= duration`).
- Uses `registerFrameUpdate` + `acquireLinearVelocity` every step (unlike `translate`, which sets velocity once).

## Limitations

- Same path/collision caveats as `translate`: no swept collision along the dash.
- The **actual** spatial integral under the curve is **not** guaranteed to equal `distance`; `distance` seeds `base` but the curve and `SPEED_SHARPNESS` shape the motion. Tune duration / multiplier empirically if you need a precise endpoint.

## See also

- [`translate`](./translate.md) — constant speed over distance.
- `RootMotion.Easing` (`sharedNormalIsland/Modules/RootMotion/Easing.luau`).
