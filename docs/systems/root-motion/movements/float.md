# `float`

**Counter-gravity** using `VectorForce`: applies an upward force that balances the character’s weight (`PhysicsHelpers.getCounterGravityVector`), optionally with a **P-style vertical correction** toward a target world height.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `duration` | `number` | Yes | How long the float lasts; clamped to a small minimum. |
| `targetY` | `number?` | No | If set **and** `hoverHeightGain > 0`, adds vertical “spring” toward this Y. |
| `hoverHeightGain` | `number?` | No | Default **`0`**. When `> 0` and `targetY` is set, each frame adds `Vector3.new(0, (targetY - pos.Y) * gain * mass, 0)` to the counter-gravity vector. |
| `accelerationMultiplier` | `number?` | No | Present on `Types.FloatParams` but **not read** by the current implementation (VectorForce magnitude does not use `Util.maxForceFor`). |

## Behavior

- **No `targetY` or `gain == 0`**: single `acquireVectorForce(token, counter)` for the duration (no per-frame updates except the timer).
- **`targetY` + `gain > 0`**: per-frame force = counter-gravity + proportional height error × mass × gain.
- Completes after `task.delay(duration)`.

## Limitations

- **Not true hover at arbitrary `targetY` without tuning**: large `gain` can oscillate; small `gain` sags. No derivative damping term in code.
- Horizontal drift is **not** canceled; wind and residual velocity still apply.
- `accelerationMultiplier` in the type bundle does not affect this mover path today—ignore it or extend the implementation if you need capped force.

## See also

- [`launch`](./launch.md) — upward velocity spike.
- [`slam`](./slam.md) — downward until grounded.
