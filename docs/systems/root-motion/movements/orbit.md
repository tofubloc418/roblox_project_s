# `orbit`

**Circular motion** around a **center** point at fixed **radius** and **angular speed** for a fixed **duration**. Uses rigid-body-style tangential `LinearVelocity` each frame in the plane orthogonal to **axis**.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `center` | `Vector3` | Yes | World-space orbit center. |
| `radius` | `number` | Yes | Clamped **> 0** (minimum `1e-3`). |
| `angularSpeed` | `number` | Yes | Radians per second; sign sets direction around **axis** (right-hand rule). |
| `duration` | `number` | Yes | Seconds; clamped to a small minimum. |
| `axis` | `Vector3?` | No | Orbit normal; default **`Vector3.yAxis`** (horizontal orbit). If non-zero, normalized. |
| `startAngle` | `number?` | No | Initial phase in radians; default **`0`**. |
| `accelerationMultiplier` | `number?` | No | Scales `maxForce` for `LinearVelocity`. |

## Behavior

- Builds an orthonormal basis `(axisU, u, v)` in the orbit plane. Each step: `angle += angularSpeed * dt`, `velocity = angularSpeed * radius * (-sin(angle)*u + cos(angle)*v)`.
- Completes when `elapsed >= duration`.

## Limitations

- Orbit is **kinematic in velocity space**—does not rope the character to exact radius if external forces push inward/outward; high `maxForce` helps track the path.
- **Center** is fixed in world space; moving platforms require updating a custom mover or different approach.
- Collisions with scenery can disrupt the circular path or cause jitter.

## See also

- [`pull`](./pull.md) — straight-line steering toward a point.
- [`springTo`](./spring-to.md) — constraint-based move to a point.
