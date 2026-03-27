# Root motion module

Server-safe **physics-driven displacement** for a character: moves the `HumanoidRootPart` assembly using Roblox constraints (`LinearVelocity`, `VectorForce`, `AlignPosition`) instead of animation root motion alone. The public API lives under **`ReplicatedStorage.Modules.RootMotion`** (`sharedNormalIsland/Modules/RootMotion/`).

---

## Entry API

```lua
local RootMotion = require(ReplicatedStorage.Modules.RootMotion)

local mover = RootMotion.createMover(character)
-- Optional: keep default Humanoid walk/jump behavior while moving
local mover = RootMotion.createMover(character, { suppressDefaultLocomotion = false })
```

**Exports**

| Export | Role |
|--------|------|
| `createMover` | Builds a `Mover` for a `Model` that has `HumanoidRootPart`. |
| `Types` | Parameter types (`TranslateParams`, `DashParams`, …). |
| `Validation` | `shapecastPath` — blockcast along a displacement for safe teleports / path checks. |
| `Easing` | Named easing curves (`linear`, `quadOut`, `quadIn`, `cubicOut`, `cubicIn`) for moves that support `easing`. |
| `PhysicsHelpers` | Small shared helpers for movement implementations. |
| `ActiveMovement` | Factory for cancellable movement tokens. |
| `Util` | Miscellaneous helpers. |
| `DEFAULT_ACCEL_MULT` | Default `accelerationMultiplier` scale used inside `Mover` force derivation (see `Mover.luau`). |

---

## Mover

A `Mover` owns one attachment and constraint trio on the root part. **Only one** of `LinearVelocity`, `VectorForce`, or `AlignPosition` is “owned” at a time per mover; acquiring one for a new `ActiveMovement` **cancels** the previous owner’s movement if it still held that channel.

**Lifecycle**

- `mover:destroy()` — cancels active movements, restores locomotion suppression if any, removes heartbeat and destroys constraints.
- `mover:cancelAll()` — cancels every active `ActiveMovement` token.

**Queries**

- `getRoot()`, `getCharacter()`, `getCachedMass()` — root part, character model, refreshed assembly mass.

**Low-level hooks** (for custom movements or extensions)

- `acquireLinearVelocity` / `releaseLinearVelocity`
- `acquireVectorForce` / `releaseVectorForce`
- `acquireAlignPosition` / `releaseAlignPosition`
- `registerFrameUpdate` / `unregisterFrameUpdate` — per-frame logic tied to a token
- `trackActive` / `untrackActive` — refcount for **default locomotion suppression** (see below)

---

## ActiveMovement tokens

Each `mover:<movement>(params)` returns a token:

- **`token:Cancel()`** — aborts the move; `Completed` fires with `didComplete == false`.
- **`token:IsActive()`** — whether the token is still running.
- **`token.Completed:Connect(function(didComplete: boolean) end)`** — `true` when the move finished normally, `false` when cancelled.

---

## Built-in movement kinds

Parameter shapes are defined in `Types.luau`. Summaries and per-movement docs:

| Method | Behavior | Doc |
|--------|----------|-----|
| **`translate`** | Fixed direction, distance, duration; constant-velocity style displacement. | [translate](./movements/translate.md) |
| **`dash`** | Like translate with optional **easing** and accel multiplier. | [dash](./movements/dash.md) |
| **`lunge`** | Thin wrapper over translate with defaults (`distance` 6, `duration` 0.18 if omitted). | [lunge](./movements/lunge.md) |
| **`knockback`** | Push away from an **origin**; optional arc angle, optional **decay** + easing at end. | [knockback](./movements/knockback.md) |
| **`pull`** | Steer toward a **target** point at **speed** until within **arrivalRadius** or **maxDuration**. | [pull](./movements/pull.md) |
| **`launch`** | Upward impulse-style motion from **height** / force tuning. | [launch](./movements/launch.md) |
| **`slam`** | Downward **speed** until ground or **maxDuration**. | [slam](./movements/slam.md) |
| **`float`** | Held / reduced-gravity style motion for **duration**; optional **targetY** + **hoverHeightGain** for vertical hold. | [float](./movements/float.md) |
| **`slide`** | Ground-relative slide: **direction**, **speed**, **duration**, optional **friction** decay, **groundRayLength**. | [slide](./movements/slide.md) |
| **`teleport`** | Sets `CFrame` to **target**; optional **validatePath**, **collisionGroup** on cast params. | [teleport](./movements/teleport.md) |
| **`orbit`** | Circular path around **center** with **radius**, **angularSpeed**, **duration**; optional **axis**, **startAngle**. | [orbit](./movements/orbit.md) |
| **`springTo`** | `AlignPosition`-driven chase of **target** with frequency/damping caps, optional **maxDuration** / force limits. | [springTo](./movements/spring-to.md) |

Many params accept **`accelerationMultiplier`** to scale derived forces (default baseline is `DEFAULT_ACCEL_MULT` inside the mover). Exception: **`float`** does not use it in the current implementation (see [float](./movements/float.md)).

---

## Default locomotion suppression

When **`suppressDefaultLocomotion`** is not set to `false` (default **true**), the first tracked active movement runs **`LocomotionSuppress.begin(humanoid)`**, which:

- Sets **`RootMotion_LocomotionLock`** to `true` on the **character** and the **owning `Player`** (if any).
- Snapshots and zeros **WalkSpeed** and jump (JumpPower or JumpHeight depending on `UseJumpPower`), and disables selected **HumanoidStateType** entries used for core locomotion (`Running`, `Climbing`).

When the last tracked movement ends, suppression restores and clears the attributes.

**Client integration:** sprint / walk / jump scripts and **`MovementLockEnforcer`** treat `RootMotion_LocomotionLock` like an extra lock so replicated `WalkSpeed` and default **Animate** locomotion tracks do not fight scripted motion. See [Movement Lock](../movement-lock.md) for the broader lock system; root motion adds this attribute-based path on top.

---

## Validation and safety

- **`Validation.shapecastPath`** — oriented **blockcast** from a root-sized box along a world displacement; returns a **safe CFrame** short of the first hit (used to keep teleports and similar moves from intersecting geometry when configured).

---

## Dev tooling (Cmdr)

**`serverNormalIsland/Commands/RootMotionCmdrUtil.luau`** wraps `createMover`, default timeouts, and `ActiveMovement.Completed` waiting for smoke tests.

Per-move **Cmdr** commands live in **`serverNormalIsland/Commands/CmdrCommands/RootMotion/`** (e.g.-dash/slide/translate server pairs). Use **`rmhelp`** / help entries in that folder for argument shapes (including Cmdr `vector3` formatting).

---

## File map (conceptual)

| Component | Location |
|-----------|----------|
| Package exports | `RootMotion/init.luau` |
| Mover + constraints | `RootMotion/Mover.luau` |
| Movement implementations | `RootMotion/Movements/*.luau` |
| Suppression | `RootMotion/LocomotionSuppress.luau` |
| Token type | `RootMotion/ActiveMovement.luau` |
| Params | `RootMotion/Types.luau` |
