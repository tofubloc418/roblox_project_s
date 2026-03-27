# `teleport`

**Instant** `CFrame` placement of `HumanoidRootPart`. Optionally **blockcasts** from current pose toward the target position and snaps to a **safe** location short of the first obstruction, preserving the target’s **orientation**.

No `accelerationMultiplier` — this move does not use mover force constraints.

## Parameters

| Parameter | Type | Required | Default | Notes |
|-----------|------|----------|---------|--------|
| `target` | `CFrame` | Yes | — | Desired pose. |
| `validatePath` | `boolean?` | No | **on** (`~= false`) | Blockcast along displacement; pass **`false`** to skip and set `target` directly. |
| `collisionGroup` | `string?` | No | **nil** | If set, `RaycastParams.CollisionGroup` for the cast (configure groups in Workspace). |

## Behavior

- **`validatePath ~= false`** (default): `displacement = target.Position - root.Position`, cast with `root.Size` and `root.CFrame`, then `root.CFrame = CFrame.new(safePosition) * CFrame.fromOrientation(tx, ty, tz)` from **original** `target` rotation.
- **`validatePath == false`**: `root.CFrame = target`.
- Completes on next deferred step (`task.defer`).

## Limitations

- Validation is a **single** blockcast along straight-line displacement—**not** a full navigation corridor check.
- Narrow doorways or diagonal obstructions can still leave the character intersecting if the box fits through the cast but the full model does not.
- Does not use `LinearVelocity`; any previous velocity on the assembly remains unless you zero it elsewhere.

## See also

- `RootMotion.Validation.shapecastPath` — cast details (in `sharedNormalIsland/Modules/RootMotion/Validation.luau`).
