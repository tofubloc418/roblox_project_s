# Movement Lock System

Client-side system that **temporarily blocks** selected movement behaviors (walk, sprint, jump, swim) while attacks, abilities, or other gameplay runs. Other modules register **named locks** with flags; a single enforcer applies the combined result to the local `Humanoid` and sprint intent.

**Scope:** Local player only (matches client-driven melee in `WeaponController`). Server authority for movement is unchanged; the enforcer reapplies lock state each frame while any lock is active so replicated `WalkSpeed` / stamina updates do not immediately undo the interruption.

---

## Pieces

| Piece | Path | Role |
|--------|------|------|
| Registry | `ReplicatedStorage.Modules.MovementLock` (`sharedNormalIsland/Modules/MovementLock.luau`) | Tag-based locks, optional timed auto-release, aggregate queries, signals |
| Enforcer | `clientNormalIsland/Init/MovementLockEnforcer.client.luau` | Subscribes to lock changes; sets `Humanoid` walk speed, jump, swimming state; sets `Player` attribute `SprintLocked` when sprint/walk is blocked |
| Sprint hook | `clientNormalIsland/Init/Sprint.client.luau` | Refuses sprint when locked; blocks jump remote / CAS when jump is locked |
| Weapons | `clientNormalIsland/Weapons/WeaponController.luau` | On each attack, if `attackEntry.movementLocks` is set, calls `MovementLock.Lock` for `hitDuration` and unlocks tags on destroy |

---

## Lock flags

- **`Walk`** — `WalkSpeed` forced to `0` while locked.
- **`Sprint`** — Cannot sprint; effective speed stays at walk (from `Player` `WalkSpeed` attribute or `PlayerConfig`).
- **`Jump`** — Jumping disabled (`JumpPower` 0, `Jumping` state disabled); sprint script also avoids firing jump stamina remote when locked.
- **`Swim`** — Swimming state disabled; if already swimming, humanoid is pushed to `Freefall`; while swimming and swim-locked, walk speed is treated as `0`.
- **`All`** — Shorthand for all four flags above.

Multiple systems can hold locks at once; if **any** lock blocks a flag, that flag is active.

---

## API (`MovementLock`)

Require: `local MovementLock = require(ReplicatedStorage.Modules.MovementLock)`

- **`MovementLock.Lock(tag: string, flags: { string }, duration: number?)`** — Register a lock. Same `tag` replaces the previous lock for that tag. If `duration > 0`, the lock auto-releases after that many seconds.
- **`MovementLock.Unlock(tag: string)`** — Remove a lock by tag.
- **`MovementLock.IsLocked(flag)`** — `flag` is `"Walk" | "Sprint" | "Jump" | "Swim"`.
- **`MovementLock.GetLockedFlags()`** — Snapshot `{ Walk, Sprint, Jump, Swim }` booleans.
- **`MovementLock.GetActiveLocks()`** — Debug: map of tag → list of movement types.
- **Signals:** `Changed` (fires cloned aggregate flags), `LockAdded`, `LockRemoved`.

Use **unique tags** per logical owner (e.g. `Weapon_Knife_1`, `Ability_PlaceholderSlash`, `Stun_<guid>`) so systems do not stomp each other unintentionally.

---

## Weapons: per-attack config

In any weapon template under `Configs/Items/Weapons/`, add optional **`movementLocks`** on an `attackSequence` entry:

```lua
attackSequence = {
	{
		animationId = "rbxassetid://...",
		hitDuration = 12 / 60,
		comboTimeLimit = 30 / 60,
		movementLocks = { "Walk", "Sprint", "Jump" },
	},
},
```

Omit `movementLocks` for no restriction on that swing. `WeaponController` uses tag `Weapon_<templateId>_<attackIndex>` and duration `hitDuration`.

---

## Abilities and other systems

From any **client** script (e.g. ability `OnStarted` in `clientNormalIsland/Abilities/Scripts/...`):

```lua
local MovementLock = require(game:GetService("ReplicatedStorage").Modules.MovementLock)

MovementLock.Lock("Ability_MyAbility", { "Walk", "Jump", "Sprint" }, 0.75)
-- Or manual release:
MovementLock.Unlock("Ability_MyAbility")
```

For open-ended actions, omit `duration` and call `Unlock` when the action ends (animation stopped, cast cancelled, etc.).

---

## Player attribute

- **`SprintLocked`** — Set on the local player by the enforcer when **Walk** or **Sprint** is locked. `Sprint.client.luau` treats this (and `MovementLock.IsLocked`) as “cannot sprint.”

---

## Extending later

- **Server enforcement** (anti-cheat / replication): mirror lock tags via attributes or a remote; run similar rules in `Stamina.server` or a dedicated server module. The registry API can stay the same on the client; server would own its own truth for competitive modes.
