# `launch`

Brief **upward impulse** implemented as a single `LinearVelocity` with vertical component derived from **`Workspace.Gravity`** and desired **peak height** (kinematic relation \(v_y = \sqrt{2 g h}\)).

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `height` | `number` | Yes | — | Clamped **≥ 0**; peak height in the idealized rise formula. |
| `accelerationMultiplier` | `number?` | No | **1000** | `MaxForce = AssemblyMass ×` this value. |

If `Workspace.Gravity < 1e-5`, implementation uses **196.2** for \(v_y\) and timing. Token completes after **`riseTime * 0.985`** (`riseTime = vy / g`).

## Behavior

- Reads `Workspace.Gravity`; if \< `1e-5`, uses **`196.2`** as fallback.
- Sets upward velocity `vy = sqrt(2 * g * height)`.
- Finishes after `riseTime * 0.985` where `riseTime = vy / g` (slightly short of apex so the token completes near the top of the rise).

## Limitations

- **Horizontal motion** is not added; only **Y** velocity is set. Existing horizontal velocity from walking or other movers may still apply unless suppressed separately.
- Not a full ballistic simulation for the whole arc—completion is timer-based near peak, not “when landing.”
- Very large `height` / low constraint force may fail to reach the intended apex if `maxForce` cannot overcome gravity or collisions.

## See also

- [`slam`](./slam.md) — sustained downward `LinearVelocity`.
- [`float`](./float.md) — counter-gravity / hover.
