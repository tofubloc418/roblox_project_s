# Data System Test Scripts

This folder contains test scripts and utilities designed to test the item instantiation and data persistence system, without needing to setup complicated test beds or create actual visual assets for your items.

## Prerequisite: Setup a Play Test
All of these scripts rely on the Roblox game loop actively running and creating DataStore session locks. You must be in a Roblox Studio Server-Client Play session (usually F5).

**CRITICAL: You must switch to the Server context!**
By default when you test play, your console runs on the Client context and `ServerScriptService` will not exist. Click the "Client" button in the Home ribbon (or "Current: Client" button) to toggle to "Current: Server".

Once the game is running and you are on the **Server** context, open your **Command Bar** (`View -> Command Bar`) and paste the snippets below. 

Currently, all the test logic lives in `src/server/serverNormalIsland/Tests/DataSystemTest.luau`. 

---

## 1. Inject a Test Item
You can inject the fake test items defined in `TestItems.luau` directly into your player's inventory to see the HUD and equipment system react.

**Command:**
```lua
require(game.ServerScriptService.Tests.DataSystemTest).GiveTestItem("Player1", "TestSword", 1)
```
*(If you are the only one in the game, you can just omit the arguments like so `require(game.ServerScriptService.Tests.DataSystemTest).GiveTestItem()` to default to yourself and the `"TestSword"`)*

---

## 2. Inspect Raw Player Data State
You can print the exact DataStore representation of the player's save file at its current moment. This bypasses the object-oriented wrappers and lets you see exactly what the auto-save thread is persisting.

**Command:**
```lua
require(game.ServerScriptService.Tests.DataSystemTest).CheckData("Player1")
```

---

## 3. Force a Save
If you want to immediately trigger a sync to Roblox DataStores (usually done automatically every 60s or on player leave), you can run this command.

**Command:**
```lua
require(game.ServerScriptService.Tests.DataSystemTest).ForceSave("Player1")
```
*(Note: depending on the exact implementation of your `dataservice` package, this may just simulate a save or it might safely kick your player to trigger the `PlayerRemoving` save process.)*

---

## 4. List All Players
If you are unsure of the exact name details (e.g. DisplayName vs Name) for use in the other commands, this lists every player in the server with their UserId.

**Command:**
```lua
require(game.ServerScriptService.Tests.DataSystemTest).ListPlayers()
```

---

## 5. List Loaded Data
Inspects the DataService internal state to show exactly which players have successfully loaded their data profiles. This is useful for debugging if a player is in-game but their data interactions are failing.

**Command:**
```lua
require(game.ServerScriptService.Tests.DataSystemTest).ListLoadedData()
```

