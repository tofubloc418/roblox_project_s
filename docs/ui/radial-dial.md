# Radial Dial — Technical Reference

Arc Raiders-style donut-segment item selector, built as a standalone reusable module. The quick-slot system is one consumer; any future system that needs a radial picker can plug in the same way.

---

## Table of Contents

1. [Module layout](#1-module-layout)
2. [Segment rendering — how the arc shape is faked](#2-segment-rendering--how-the-arc-shape-is-faked)
3. [Hover effect — white-opaque segment highlight](#3-hover-effect--white-opaque-segment-highlight)
4. [Icon placement and clipping](#4-icon-placement-and-clipping)
5. [Center label](#5-center-label)
6. [All configuration values (RadialDialConfig)](#6-all-configuration-values-radialdialconfig)
7. [Viewport scaling](#7-viewport-scaling)
8. [Controller — Q tap vs hold, virtual cursor, camera lock](#8-controller--q-tap-vs-hold-virtual-cursor-camera-lock)
9. [Slot selection logic — 8 fixed sectors](#9-slot-selection-logic--8-fixed-sectors)
10. [Empty slot guard](#10-empty-slot-guard)
11. [Data flow from quick-slots to RadialDial](#11-data-flow-from-quick-slots-to-radialdial)
12. [How to wire a new use-case to RadialDial](#12-how-to-wire-a-new-use-case-to-radialdial)
13. [Z-index stack](#13-z-index-stack)

---

## 1. Module layout

```
src/client/clientNormalIsland/GUI/
├── RadialDial/
│   ├── RadialDialTypes.luau       -- exported types (RadialSlotData, RadialDialProps)
│   ├── RadialDialConfig.luau      -- every tunable constant lives here
│   ├── RadialDialSegment.luau     -- renders one slot (annular sector + icon square)
│   └── RadialDial.luau            -- root component (circles, all 8 segments, center label)
└── HudLoadout/
    ├── HudRadialDial.luau         -- thin adapter: ItemStack[] → RadialSlotData[] → RadialDial
    └── HudLoadoutController.client.luau  -- owns Q input, virtual cursor, camera freeze
```

`RadialDial` knows **nothing** about quick slots, weapons, or inventory. It receives pre-resolved `RadialSlotData` and renders it. `HudRadialDial` is the only file that knows about items.

---

## 2. Segment rendering — how the arc shape is faked

Roblox UI has no native donut-sector shape. The approach:

### Image asset

A **512×512 PNG** of a single 45° annular sector (donut slice):

- White fill on a transparent background.
- The donut center is the **image center** (256, 256).
- The gap between adjacent slots is baked into the image — the segment subtends slightly less than 45° so a ~8 px equivalent gap is visible between neighbours.
- The gap between the segment's outer curved edge and the outer circle, and the segment's inner curved edge and the inner circle, is also baked in (`SlotGap = 8` px at reference size).
- Asset ID: **`rbxassetid://84415060524194`** (see `RadialDialConfig.SegmentImageId`).

### Per-slot rendering

All 8 `ImageLabel`s are the **same image**, all centered at `(cx, cy)`, each with a different `Rotation`:

```
slot 1: Rotation = 0°      (top-center)
slot 2: Rotation = 45°
slot 3: Rotation = 90°
...
slot 8: Rotation = 315°
```

`ImageColor3` tints the image to the slot fill color. Because the PNG is white, setting `ImageColor3` directly controls the tint without a separate mask.

Normal (idle) fill:

```
ImageColor3        = RadialDialConfig.RingBackgroundColor  -- RGB(35,35,42)
ImageTransparency  = RadialDialConfig.RingBackgroundTransparency  -- 0.5
```

This makes every idle slot match the translucency of the rest of the HUD loadout slots.

Hovered fill: see section 3.

### Why size = `2 × OuterRadius`?

The image is drawn as a large square centered at the dial center. Its size in pixels is `2 × OuterRadius` — large enough to contain the full donut. Only the white region of the PNG becomes visible as a tinted shape; the transparent region shows the background through. No masking or clipping is needed at the `ImageLabel` level.

---

## 3. Hover effect — white-opaque segment highlight

On hover, the segment's `ImageLabel` switches to:

```
ImageColor3        = RadialDialConfig.HoveredSegmentColor        -- RGB(255,255,255)
ImageTransparency  = RadialDialConfig.HoveredSegmentTransparency -- 0.0
```

The segment flashes white and fully opaque; the rest of the time it uses `RingBackgroundColor` and `RingBackgroundTransparency` (section 2).

---

## 4. Icon placement and clipping

### Position

The icon is placed at the **arc midpoint** of its segment:

```lua
local midRadius      = (OuterRadius + InnerRadius) / 2  -- RC.MidRadius
local centerAngleRad = math.rad(-90 + (slotIndex - 1) * 45)
local midX = cx + midRadius × cos(centerAngleRad)
local midY = cy + midRadius × sin(centerAngleRad)
```

`-90°` shifts the origin from "right" (math convention) to "top" (visual slot 1 position).

### Orientation

The `IconSquareLayer` frame has `Rotation = 0` always. It never inherits the segment's rotation. All icons are **upright**, regardless of where around the dial the slot sits.

### Size

Fixed square, `IconSquareSize = 110` px (before viewport scaling). This value is deliberately larger than the radial depth of the segment (`OuterRadius − InnerRadius − 2×SlotGap ≈ 99 px`) so the icon fills the slot area well.

### Clipping

`ClipsDescendants = true` on `IconSquareLayer`. Any part of the icon that would spill beyond the square is cut off by the frame boundary. This gives rectangular clipping — the icon is contained within its square hitbox, which itself sits centered in the arc. This is not pixel-perfect arc clipping, but the overlap is small enough that it is visually acceptable.

---

## 5. Center label

A `TextLabel` absolutely positioned at `(cx − width/2, cy − height/2)`:

- Width = `(2 × InnerRadius − 20) × scale`
- Height = `34 × scale`
- Font: `ThemeConfig.Font.FamilySecondary` (Gotham)
- Color: white

**What it shows:**

| State | Text |
|---|---|
| No slot hovered (mouse in dead zone) | `"Cancel"` (`RadialDialConfig.CancelLabelText`) |
| Slot hovered, item present | The item's `displayName` (resolved by `ItemIconResolver`) |
| Slot hovered, slot is empty | `"Empty Slot"` |

The dial does not hide the center label when nothing is hovered — it shows "Cancel" to signal that moving the mouse back to center and releasing Q will abort the selection.

---

## 6. All configuration values (RadialDialConfig)

All numbers are at the **reference viewport size** (`ReferenceViewportSize = 1080`). At runtime they are multiplied by the viewport scale factor (see section 7).

| Constant | Value | Purpose |
|---|---|---|
| `ReferenceViewportSize` | `1080` | Short edge of screen used as design baseline |
| `OuterRadius` | `300` | px, center to outer circle stroke |
| `InnerRadius` | `185` | px, center to inner circle stroke |
| `SlotCount` | `8` | Always 8 slots; never changes at runtime |
| `SlotGap` | `8` | px gap on every edge of every segment (baked into image) |
| `IconSize` | `48` | px, fixed icon image inside `IconSquareLayer` |
| `IconSquareSize` | `110` | px, the upright frame that clips the icon |
| `CenterLabelFontSize` | `22` | pt |
| `CancelLabelText` | `"Cancel"` | Shown when mouse is in dead zone |
| `SegmentImageId` | `"rbxassetid://84415060524194"` | 45° donut-slice PNG |
| `RingBackgroundColor` | `RGB(35,35,42)` | Idle segment tint — matches HUD slot color |
| `RingBackgroundTransparency` | `0.5` | Idle transparency — matches HUD `SlotTransparency` |
| `HoveredSegmentColor` | `RGB(255,255,255)` | White flash on hover |
| `HoveredSegmentTransparency` | `0.0` | Fully opaque on hover |
| `CircleStrokeColor` | `RGB(180,180,190)` | Inner/outer circle outline color |
| `CircleStrokeTransparency` | `0.3` | |
| `CircleStrokeThickness` | `1.5` | px |
| `OverlayColor` | `RGB(0,0,0)` | Full-screen dimming overlay |
| `OverlayTransparency` | `0.6` | |
| `MidRadius` | `(300+185)/2 = 242.5` | Computed at require-time; center of segment ring |
| `SegmentArcWidth` | `~172` | Computed; arc length at mid-radius minus lateral gaps |
| `SegmentRadialDepth` | `99` | Computed; `OuterRadius − InnerRadius − 2×SlotGap` |
| `SegmentOuterEdge` | `292` | `OuterRadius − SlotGap` |
| `SegmentInnerEdge` | `193` | `InnerRadius + SlotGap` |

**Debug flags** (set `UseDebugColors = false` before shipping):

| Constant | Default | Purpose |
|---|---|---|
| `UseDebugColors` | `true` | When true, draws sector/icon in debug colors |
| `AnnularSectorColor` | `RGB(255,0,0)` | Debug red for sector frame |
| `AnnularSectorTransparency` | `1` | Transparent (ring uses RingBackground instead) |
| `IconSquareColor` | `RGB(0,0,255)` | Debug blue for icon frame |
| `IconSquareTransparency` | `1` | Transparent in production |

---

## 7. Viewport scaling

The dial was designed at `1080` px short edge. At runtime:

```lua
local scale = math.min(viewportSize.X, viewportSize.Y) / RC.ReferenceViewportSize
```

Every pixel dimension (`outerRadius`, `innerRadius`, `iconSquareSize`, font size, stroke thickness, label dimensions) is multiplied by `scale` before use. This means the dial shrinks proportionally on smaller screens and grows on larger ones, always centering itself at `(viewportSize.X/2, viewportSize.Y/2)`.

---

## 8. Controller — Q tap vs hold, virtual cursor, camera lock

File: `HudLoadoutController.client.luau`

### Q tap vs hold

```
Q Begin → record qPressTime = os.clock()

Heartbeat (each frame):
  if qPressTime and not radialVisible:
    held = clock() − qPressTime
    if held ≥ 0.2s → open radial, setRadialDialOpen(true)

Q End:
  held = clock() − qPressTime
  if held < 0.2s  → TAP:  equip current quick slot item (setActiveSlot("QuickUse"))
  if held ≥ 0.2s  → HOLD: apply highlighted selection if any, close radial
```

### Virtual cursor

When the radial opens, the real mouse is **center-locked** (`MouseBehavior.LockCurrentPosition`) and the OS cursor icon is hidden. A `virtualCursorOffset: Vector2` accumulates raw mouse delta each `Heartbeat` frame:

```lua
local delta = UserInputService:GetMouseDelta()
virtualCursorOffset += Vector2.new(delta.X, delta.Y)
```

`virtualCursorOffset` is clamped to `VIRTUAL_CURSOR_MAX_RADIUS = 400` px so the vector never grows unboundedly. The sector under the virtual cursor is derived from this offset (see section 9).

**Why a virtual cursor?** Center-locking prevents the mouse from leaving the screen and avoids the cursor snapping back, which would break the rotation feel. The delta approach means the "cursor" starts at dead center every time the dial opens — the player always begins in "Cancel" state and must nudge the mouse to select a slot.

### Camera freeze

When the radial opens the camera is switched to `Scriptable` and its current `CFrame` is captured. Each `RenderStepped` frame, the camera follows the character's position but keeps the frozen look direction, so the world view does not spin while the player is using the dial.

```
radialCameraLookVector       = cam.CFrame.LookVector   (saved at open)
radialCameraOffsetFromRoot   = cam.CFrame.Position − root.Position
```

Each `RenderStepped`:
```lua
cam.CFrame = CFrame.lookAt(root.Position + offset, root.Position + offset + lookVector)
```

When the radial closes the camera type is restored to whatever it was before.

### Hidden GUIs

Any `ScreenGui` named `"CrosshairGui"`, `"ShiftLockGui"`, or `"CursorGui"` that was enabled at the time the dial opens is disabled for the duration and re-enabled on close.

---

## 9. Slot selection logic — 8 fixed sectors

```lua
local DEAD_ZONE_RADIUS = 70   -- virtual px; inside this = Cancel (nil)
local MAX_RADIUS       = 400  -- virtual px; clamp to prevent overflow

local function getHighlightedSlotFromOffset(offset: Vector2): number?
    local distSq = offset.X^2 + offset.Y^2
    if distSq < DEAD_ZONE_RADIUS^2 then
        return nil   -- Cancel
    end

    -- Normalize so 0 = top, clockwise
    local angle      = math.atan2(offset.Y, offset.X)          -- [-π, π], 0 = right
    local normalized = (angle + math.pi/2) % (2*math.pi)       -- [0, 2π], 0 = top

    local sectorSize = 2*math.pi / 8                            -- 45°
    local idx        = math.floor((normalized + sectorSize/2) / sectorSize) % 8 + 1
    return idx
end
```

The `+ sectorSize/2` before `floor` centers each 45° bucket on its slot's center angle, so the boundary between slot 1 and slot 2 falls exactly between them (at 22.5° from top), not at the slot center.

The slot count is always 8. The controller never filters by occupied slots — any of the 8 sectors is selectable whether or not it has an item (the empty-slot guard is at the selection commit step, not here).

---

## 10. Empty slot guard

At Q release, before committing a selection:

```lua
if highlightedIndex then
    local state = HudLoadoutDataAdapter.getState()
    if state.quickUseItems[highlightedIndex] ~= nil then
        HudLoadoutDataAdapter.setCurrentQuickSlotIndex(highlightedIndex)
        HudLoadoutDataAdapter.setActiveSlot("QuickUse")
    end
    -- If item is nil: do nothing — current slot is unchanged
end
```

The segment still highlights (white) on empty slots during hover (so the player can see what they are pointing at), and the center label still says "Empty Slot". But releasing Q on an empty slot is a no-op: the previously equipped quick-slot item stays equipped.

---

## 11. Data flow from quick-slots to RadialDial

```
HudLoadoutDataAdapter.getState()
        │
        │  quickUseItems: { [1..8]: ItemStack? }
        │  highlightedIndex: number? (from virtual cursor)
        ▼
HudRadialDial (adapter)
        │
        │  for i = 1..8:
        │    if item exists: ItemIconResolver → { iconId, displayName, isEmpty=false }
        │    else:           { iconId=nil, displayName="Empty Slot", isEmpty=true }
        │
        │  RadialSlotData[8]
        ▼
RadialDial (generic component)
        │
        ├── OuterCircle, InnerCircle
        ├── for i = 1..8: RadialDialSegment(slotData[i], isHovered=(i==highlightedIndex))
        └── CenterLabel (text = slotData[highlightedIndex].displayName or "Cancel")
```

`RadialDial` is a **pure renderer** — it receives props and produces UI. It never reads from any adapter or service.

---

## 12. How to wire a new use-case to RadialDial

1. Create an adapter component (like `HudRadialDial`) that converts your data into `{ [number]: RadialSlotData }` (8 entries, `isEmpty = true` for empty slots).
2. Create or reuse a controller that:
   - Manages the `visible` boolean and a `highlightedIndex: number?`.
   - Tracks mouse input (or virtual cursor) and computes `highlightedIndex` via `getHighlightedSlotFromOffset`.
   - On selection commit, reads the chosen index and acts on it (with your own empty-slot guard if needed).
3. Mount a `ReactRoblox.createRoot` on a dedicated `ScreenGui`, render your adapter component into it, and toggle `ScreenGui.Enabled` to show/hide.

Nothing in `RadialDial.luau`, `RadialDialSegment.luau`, `RadialDialTypes.luau`, or `RadialDialConfig.luau` needs to change.

---

## 13. Z-index stack

`RadialDialConfig.ZIndex` defines the dial's internal draw order. The ScreenGui uses `ZIndexBehavior = Global`, so these values are compared across the entire hierarchy.

| Layer | ZIndex | What renders there |
|---|---|---|
| `Annulus` | `10` | Outer and inner circle strokes |
| `AnnularSector` | `11` | Segment `ImageLabel`s (donut slices) |
| `IconSquare` | `12` | Upright icon frames and icon `ImageLabel`s |
| `CenterLabel` | `13` | Item name / "Cancel" TextLabel |

The full-screen black overlay is a sibling `Frame` on `HudRadialScreen` at ZIndex `0` (below `Annulus`), rendered by `HudRadialDial` wrapping `RadialDial`.
