# Hit Detection System Architecture

Our hit detection system is built around finding the right tool for each unique type of attack. We balance the need for responsive, lag-free action on the client with the requirement for secure, exploit-resistant verification on the server.

For most melee and sweeping attacks, we utilize the **ShapecastHitbox** library. For simpler or instant abilities, we rely on native Roblox engine API calls to avoid unnecessary overhead.

---

## Prerequisites & Installation

To support this architecture, please ensure you have the following packages and plugins:

### Wally Packages
Add the following to your `wally.toml` under `[dependencies]` to install the hit detection library:
```toml
ShapecastHitbox = "teamswordphin/shapecasthitbox@^0.2.9"
```

### Roblox Studio Plugins
- **Tag Editor** (by Sweetheartichoke): Highly recommended for easily tagging Roblox `Attachment` or `Bone` objects with the necessary `DmgPoint` tags used by ShapecastHitbox.

---

## The Core Philosophy: Client-Predicted, Server-Verified

In a multiplayer environment like Roblox, waiting for the server to detect a hit creates unacceptable lag for the attacking player. Our architecture follows this pipeline:

1. **Client Prediction (Responsive):** The client casts the ability, plays the animation, and runs the local hit detection algorithm (whether that's `ShapecastHitbox` or a direct raycast). Upon detecting a hit, it immediately shows visual and audio feedback (e.g., sparks, hit markers) and fires a `RemoteEvent` to the server claiming: *"I hit Enemy X at Position Y with Ability Z."*
2. **Server Verification (Secure):** The server receives the claim. It does **not** rely on Roblox's `.Touched` event nor does it run the hitbox sweep itself. Instead, it runs instantaneous "Sanity Checks" to verify if the client's claim is physically possible. If validated, the server applies the damage and replicates the impact to other clients.

---

## Hit Detection Strategies by Ability Type

### 1. Melee Attacks, Dashes, & Complex Sweeps
**Tool:** `ShapecastHitbox` (Client-Side)
**Use Cases:** Sword swings, chained melee combos, spinning attacks (whirlwinds), or dashes that damage enemies on contact.

**How it works:**
ShapecastHitbox is a robust tool that tracks the frame-by-frame positional data of `Attachment` or `Bone` objects hidden within the weapon model. By tracing the path between the weapon's position in the *previous* frame and the *current* frame, it ensures even incredibly fast swings won't "skip over" or clip through thin enemies.

**Implementation Details:**
- **Setup:** Add `Attachment` or `Bone` instances along the blade or impact area. Give them the `Tag` or `Name` of `DmgPoint`.
- **Cast Types:** ShapecastHitbox supports three algorithms. 
  - `Raycast`: Thin, performant line traces. Good for precise weapons like rapiers.
  - `Blockcast`: Traces a rectangular prism through the air. Excellent for flat weapons like greatswords.
  - `Spherecast`: Traces a thick tube. Perfect for blunt weapons (hammers) or wide, sweeping spin attacks.
- **Attributes:** Individual attachments can have varying sizes by applying Roblox configuration attributes like `CastType` (String), `CastSize` (Vector3), or `CastRadius` (Number) directly to the attached `DmgPoint`.
- **Execution:** When the swing starts, the Client calls `hitbox:HitStart(duration)` and listens to `hitbox:OnHit()`. When a target is found, it pauses the specific detection for that target to prevent hitting them 60 times a second, and fires the server.

### 2. Area of Effect (AoE) Attacks
**Tool:** Roblox Native Spatial Queries (`workspace:GetPartBoundsInRadius` / `GetPartsInPart`)
**Use Cases:** Giant asteroids dropping, fiery explosions, ground stomps.

**Why not ShapecastHitbox?**
ShapecastHitbox is designed to trace continuous motion. An explosion or landing asteroid does not need its trajectory mapped frame-by-frame for hit detection; it acts as an instantaneous event at a specified location.

**Implementation Details:**
- Because these are usually large and instantaneous, hit detection can often be run entirely on the **Server** for maximum security when the visual effect "detonates."
- Create an `OverlapParams` object filtering out the caster and their allies.
- Call the native Roblox spatial query at the epicenter coordinate to capture all viable targets within the radius or hit volume.

### 3. Hitscan & Linear Fast Projectiles
**Tool:** Roblox Native API (`workspace:Raycast`, `workspace:Blockcast`, `workspace:Spherecast`)
**Use Cases:** Magic laser beams, instantaneous gunshots.

**Why not ShapecastHitbox?**
While ShapecastHitbox *does* support Raycasts, it is fundamentally designed to track a physical `Instance` over consecutive frames. A hitscan happens instantaneously in exactly one frame. Initializing a Hitbox object, waiting for a heartbeat loop, and destroying it adds totally unnecessary performance overhead compared to firing a single, immediate `workspace:Raycast()` call.

**Implementation Details:**
- **Client-Side:** For a thin bullet, fire an instant `workspace:Raycast` from the origin point to the target direction (up to the maximum range). 
- If the attack is a massive thick laser beam, use a native `workspace:Spherecast` instead.
- If the beam hits, send the target data to the Server.

### 4. Slow / Seeking Projectiles
**Tool:** Custom Segmented Casting (Client-Side math + Native Casts)
**Use Cases:** Homing mage missiles, slow-moving fireballs, thick energy waves.

**How do you do thick projectiles without ShapecastHitbox?**
"Segmented Raycasting" is just a term for a broader technique. It refers to tracking a projectile frame-by-frame using *any* native casting method. Roblox natively supports `workspace:Spherecast()` and `workspace:Blockcast()`. You do not need the ShapecastHitbox library to use these shapes.

**Why not ShapecastHitbox?**
ShapecastHitbox requires the projectile to be a physical `Instance` in the `workspace` with `Attachment`s to track. For games with many projectiles, creating heavy physical parts and assigning individual Hitbox tracking loops for every single fireball consumes excessive memory. It is drastically more performant to handle projectile logic purely mathematically in a table (CFrame, Velocity, Radius) and use native casts.

**Implementation Details:**
- Projectiles should be purely visual and kinematic (driven by script math or CFrames, not Roblox engine physics).
- In a single `RunService.Heartbeat` cycle, loop through all active projectiles and manually calculate their new position for that frame.
- For thin projectiles (arrows), perform a native `workspace:Raycast` between its position last frame and its new position.
- For thick projectiles (fireballs, boulders), perform a native `workspace:Spherecast(lastPos, radius, newPos - lastPos)`.
- The client who fired the projectile tracks their own impact and tells the server.

### 5. Pure Mobility
**Tool:** State Management
**Use Cases:** High jump chains, teleportation, evasive rolls.
- If the ability deals absolutely no damage and just acts as a repositioning tool, it requires no hit detection logic. Simply apply the necessary state tags (e.g., `Invulnerable`, `Dashing`) to the player character during the animation window so other systems know how to interact with them.

---

## Server Sanity Checks (Anti-Exploit)

Whenever the server receives a hit request via `RemoteEvent` from a `ShapecastHitbox`, it MUST validate it. Malicious clients can easily spoof these events.

**The Server must verify:**
1. **Cooldown State:** Is the requested ability actually off cooldown? Is the character currently capable of attacking (e.g., not stunned, not dead)?
2. **Hit Distance Validity (The core check):** Is the mathematical distance between the Attacker's origin and the Target's position possible? For a dagger, anything over ~8 studs is likely a spoof. 
   > *Note:* Accommodate for player latency (Ping). A player moving backward rapidly might appear further away on the server than they did on the attacking client at the exact moment of the swing. Add a slight leniency buffer `(Weapon Range + Target Velocity * Attacker Ping)`.
3. **Line of Sight / Wall Checks:** Fire a direct ray between the Attacker to the Target. If a solid, non-passable wall is in the way and the ability does not permit wall-piercing, drop the hit claim.

Using this combination of robust client sweeping via **ShapecastHitbox** and strict logical boundaries on the **Server**, our combat will remain visibly fluid while maintaining its competitive integrity.
