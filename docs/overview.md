# Normal Island — Overview

NormalIsland1, NormalIsland2, and NormalIsland3 are three Roblox places that share the same Luau codebase. They differ only in:

- **Island layout** — Terrain and environment are built per-place in Roblox Studio
- **Minimap asset** — Each place uses a different static map image (configured in `MinimapConfig.minimapAssets`)

All three Rojo projects map to the same source paths:

| Roblox Instance | Source Path |
|-----------------|-------------|
| ReplicatedStorage | `src/shared/sharedNormalIsland` |
| ServerScriptService | `src/server/serverNormalIsland` |
| StarterPlayer.StarterPlayerScripts | `src/client/clientNormalIsland` |

The correct minimap image is chosen at runtime via `game.Name` (e.g. `"NormalIsland1"`, `"NormalIsland2"`, `"NormalIsland3"`).

## Game Systems

- **Map & Ping** — Minimap, full-screen map (M), ping system (right-click + C)
- **Inventory** — Grid inventory, hotbar, equip/swap (Tab to toggle)
- **Loot** — Breakable crates, procedural spawns, rarity tiers
- **Weapons** — Guns (FastCast), melee
- **Med** — Bandage, Medkit, Soda, Pill (heal/adrenaline)
- **Combat** — DamageService, fall damage
- **Environment** — Stamina (sprint, swim, jump), fall damage
- **HUD** — Health/stamina bars, player count, crosshair, match timer

---

**Note:** Battleground-related code is deprecated and not documented here.
