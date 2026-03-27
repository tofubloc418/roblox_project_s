# `float`

**Counter-gravity** using `VectorForce`: applies an upward force that balances the character’s weight (`PhysicsHelpers.getCounterGravityVector`), optionally with a **P-style vertical correction** toward a target world height.

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `duration` | `number` | Yes | — | Float length; clamped to a small minimum. |
| `targetY` | `number?` | No | **nil** | With `hoverHeightGain > 0`, steers toward this world Y. |
| `hoverHeightGain` | `number?` | No | **0** | `> 0` and `targetY` set → per-frame `(targetY - pos.Y) * gain * mass` added to counter-gravity. |
| `accelerationMultiplier` | `number?` | No | *(unused)* | On `Types.FloatParams` only; **not read** — no `maxForce`-style cap in current implementation. |

## Behavior

- **No `targetY` or `gain == 0`**: single `acquireVectorForce(token, counter)` for the duration (no per-frame updates except the timer).
- **`targetY` + `gain > 0`**: per-frame force = counter-gravity + proportional height error × mass × gain.
- Completes after `task.delay(duration)`.

## Limitations

- **Not true hover at arbitrary `targetY` without tuning**: large `gain` can oscillate; small `gain` sags. No derivative damping term in code.
- Horizontal drift is **not** canceled; wind and residual velocity still apply.
- `accelerationMultiplier` does not affect this mover path today—ignore it or extend the implementation if you need capped force.

## See also

- [`launch`](./launch.md) — upward velocity spike.
- [`slam`](./slam.md) — downward until grounded.
