# `lunge`

Thin wrapper around **`translate`**: same physics and completion rules, but supplies **defaults** for `distance` and `duration` when omitted.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `direction` | `Vector3` | Yes | Passed through to `translate` (must be non-zero). |
| `distance` | `number?` | No | Default **`6`** studs. |
| `duration` | `number?` | No | Default **`0.18`** seconds. |
| `accelerationMultiplier` | `number?` | No | Passed through to `translate`. |

## Behavior

Equivalent to:

```lua
mover:translate({
  direction = params.direction,
  distance = params.distance or 6,
  duration = params.duration or 0.18,
  accelerationMultiplier = params.accelerationMultiplier,
})
```

## Limitations

- Inherits all **translate** limitations (no path validation, constant speed over the window). See [`translate`](./translate.md).

## See also

- [`translate`](./translate.md)
