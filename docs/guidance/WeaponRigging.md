# Advanced Weapon Rigging & Dynamic Animation Standards

This document defines the technical standards for weapon rigging using the **C0/C1 Offset Method** and **IKControls**. This architecture allows for shared animations across infinite models and handles complex scenarios like "hand-swapping," dual-holding, and weapon-disconnection—all manageable via **Moon Animator 2**.

---

## 1. The C0/C1 Offset Method (The "Grip" standard)

We do not use physical "Grip" parts. Instead, we use the mathematical properties of the **Motor6D** joint to define how a weapon sits in a player's hand.

### How C0 and C1 Work
A Motor6D works by snapping two invisible points together:
1.  **C0 (Offset from Part0/Hand):** This is where the "grip point" is relative to the center of the player's palm.
2.  **C1 (Offset from Part1/Weapon):** This is where the "grip point" is relative to the center of the weapon model.

**The Workflow:**
1.  Use **EasyWeld** (in Moon Animator 2) to create a Motor6D between `RightHand` and `Handle`.
2.  In the Moon Animator viewport, move the handle into the correct position.
3.  **To Permanentize:** Go to the `Handle` Motor6D properties in the Explorer. Copy the resulting `C0` and `C1` CFrame values into your weapon configuration logic.
4.  **At Runtime:** The script instantiates a new Motor6D and applies these exact `C0/C1` values. The weapon will appear exactly as it did in your dummy.

---

## 2. Motor6D vs. IKControls

It is critical to understand the mechanical difference between these two systems for two-handed weapons.

| Feature | Motor6D (Joint) | IKControl (Targeting) |
| :--- | :--- | :--- |
| **Connection** | Hard-welded link. | Dynamic "Reach" goal. |
| **Logic** | The Weapon stays *inside* the hand. | The Hand *reaches for* the Weapon. |
| **Flexibility** | Rigid. Better for the primary holding hand. | Fluid. Better for the secondary hand. |
| **Clipping** | None (it's a weld). | May clip if the target is out of physical reach. |

**Standard Two-Handed Setup:**
- **RightHand:** Connected via `Motor6D` (The Anchor). The weapon's base position is driven by this arm.
- **LeftHand:** Connected via `IKControl`. Animate an `Attachment` on the weapon model, and set the `IKControl.Target` to that attachment. The left arm will automatically track the weapon as it moves.

---

## 3. Disconnection & Independent Movement

Sometime a weapon (or prop) needs to leave the character's hand (e.g., throwing a knife, dropping a shield, or a floating magic staff).

### The Hand-off Process
1.  **In Studio:** Animate the weapon moving away from the hand. 
2.  **The Joint:** Moon Animator 2 allows you to keyframe the `Part0` of a joint. 
    - At the moment of release, set `Joint.Part0 = nil` or `Part0 = Workspace.Terrain`.
3.  **In Game:** Your animation will play, but the logical `Motor6D` still exists. You must use an **Animation Event** (Marker) at the release frame.
4.  **The Script:** When the marker hits, your controller script sets `motor.Enabled = false` or `motor.Part0 = nil`. At this point, you can hand off the physical model to a projectile system or simply drop it.

---

## 4. Multi-Location & Variable Attachment

Complex animations require the hand to move between different locations on the same weapon, or swap between multiple weapons (e.g., dual-wield swapping).

### Method A: Attachment Swapping (Visual)
In Moon Animator 2, you can have multiple `Motor6D` joints created via EasyWeld (e.g., `RightHand -> Handle1` and `RightHand -> Handle2`).
- You can keyframe the **"Enabled"** property of these joints in the timeline.
- **Example:** To swap which end of a staff you are holding, at Frame 30, turn `JointA.Enabled = false` and `JointB.Enabled = true`. The staff will instantly snap to the new grip.

### Method B: C0 Interpolation (Technical)
If the hand needs to *slide* smoothly along a long weapon (like a staff slide):
1.  In Moon Animator, animate the hand moving independently of the weapon.
2.  In your `WeaponController`, use `TweenService` during the animation playback to smoothly change the `Motor6D.C0` value. This "slides" the weapon through the player's palm.

---

## 5. Moon Animator "Joint Editing"
If the weapon is rotating around the wrong axis (e.g., rotating around the center of the staff instead of the hand's grip point):
1.  Open **Moon Animator 2**.
2.  Go to **Item > Joint Editor**.
3.  Select the joint connecting the staff.
4.  Move the **Joint Pivot** (the diamond icon) to the exact spot where the palm meets the staff.
5.  Now, the "Rotate" tool in the animator will pivot the weapon exactly where the hand holds it.

### Verifying in Studio
Before exporting, check that your **C0** and **C1** in the joint properties match the visual look. If you see high values in `Motor6D.Transform` in the Properties window, it means Moon Animator has applied an offset *for this frame*. To make it the "Default Power-On Position," those offsets should be transferred to `C0` in your code.
