# Normal Island — Source Tree

```
src/shared/sharedNormalIsland/
├── Configs/
│   ├── IslandConfig.luau
│   ├── MinimapConfig.luau
│   ├── OccupancyMap.luau
│   ├── PlayerConfig.luau
│   ├── Med/
│   │   └── MedConfigs.luau
│   ├── Weapons/
│   │   ├── GunConfigs.luau
│   │   └── MeleeConfigs.luau
│   └── LootSystem/
│       ├── LootConfig.luau
│       ├── ItemDefinitions.luau
│       ├── LootPools.luau
│       └── DropRules.luau
├── Modules/
│   ├── MapMath.luau
│   ├── RoundState.luau
│   └── FastCastRedux.luau
├── Weapons/
│   └── BulletVisuals.luau
└── Inventory/
    └── InventoryTypes.luau

src/server/serverNormalIsland/
├── Initializer.server.luau      # Bootstraps all services
├── PlayerSpawner.server.luau
├── PingService.server.luau
├── Combat/
│   └── DamageService.luau
├── Weapons/
│   ├── GunService.luau
│   ├── GunToolScript.server.luau
│   ├── MeleeService.luau
├── Med/
│   └── MedService.luau
├── Inventory/
│   └── InventoryService.luau
├── LootSystem/
│   ├── LootBoxService.luau
│   ├── DropFactory.luau
│   └── BreakableCrate.luau
└── Environment/
    ├── Stamina.server.luau
    └── FallDamage.server.luau

src/client/clientNormalIsland/
├── MinimapController.client.luau   # Entry point → Map/MinimapController
├── Init/
│   ├── Crosshair.client.luau
│   └── Sprint.client.luau
├── Map/
│   ├── MinimapController.luau       # Main HUD controller (minimap, full map, top-right HUD)
│   ├── MinimapView.luau
│   ├── FullMapView.luau
│   └── PingIcons.luau
├── Hud/
│   ├── HudBuilder.luau              # buildMinimap, buildInventory, buildTopRightHud
│   └── CursorManager.luau           # UI cursor toggle (FullMap, Inventory)
├── Inventory/
│   ├── InventoryController.client.luau
│   └── InventoryUI.luau
├── Med/
│   └── MedController.client.luau
└── Weapons/
    ├── GunController.client.luau
    ├── MeleeController.client.luau
    └── BulletRenderer.client.luau
```
