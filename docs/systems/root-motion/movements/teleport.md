# `teleport`

**Instant** `CFrame` placement of `HumanoidRootPart`. Optionally **blockcasts** from current pose toward the target position and snaps to a **safe** location short of the first obstruction, preserving the target’s **orientation**.

## Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|--------|
| `target` | `CFrame` | Yes | Desired pose. |
| `validatePath` | `boolean?` | No | **`true`** or omitted: run `Validation.shapecastPath` along displacement with character excluded. Set explicitly to **`false`** to assign `target` with no cast. |
| `collisionGroup` | `string?` | No | If set, passed into cast `RaycastParams.CollisionGroup` (you must configure collision groups in Workspace for this to matter). |

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
