# 05. Day Block motion: teaching "today's money drains"

## Job of the screen
Home's hero answers "how much can I safely spend today?". Today's Day Block is meant to be a tank of today's money: full in the morning, draining with each spend. If people read it as a tank, the block says "how much is left" before they read the number.

## What was wrong
- **Blind read (2026-10-28):** five simulated first-time users (aged 19 to 61, from a fintech designer to a pensioner) saw the live Home with an almost-full block, then a part-drained mockup, then an overspent one. They had no docs or code. Average score for "understood the yellow without help": 2.4 / 5.
  - All five read a full block as "today, selected", like a highlighted tab or the Add button. None read it as full. Four also felt "caution" from the amber.
  - All five understood "money left, like a glass or battery" as soon as they saw a part-drained block.
  - The hatch and the shorter future blocks were understood only through the words.
- **Small spends were invisible:** BR-6 fill is `safeToday / A`. ₹700 out of ₹11,218 leaves 94% filled. On the 40dp block that is a 2.4dp gap, hidden under the 1.5dp edge and the rounded corners.
- **The drain played under the scrim:** a device recording of a ₹1,000 save (Pixel-class phone, 720×1600) showed this timeline:

  | Time | Event |
  |---|---|
  | 0ms | Tile tapped |
  | +30ms | Tray starts closing |
  | +120ms | Fill starts to fall |
  | +200ms | Scrim gone |
  | +290ms | Fill settles |

  About two thirds of the drain ran behind the dimmed scrim. Home reloads from `LedgerRepository.changes` at save time, while the tray is still on screen.

So people learn the idea from seeing a block part-empty, and the app hid exactly that moment.

## Research
- **Apple, WWDC18 *Designing Fluid Interfaces*:** describe springs by response and damping, and start at 100% damping with no overshoot. Bounce is only for motion a gesture threw. Motion must be interruptible and keep its velocity. The talk itself wasn't fetched; the points come from [Nathan Gitter's write-up](https://medium.com/@nathangitter/building-fluid-interfaces-ios-swift-9732bb934bf5) and [reimplementation](https://github.com/nathangitter/fluid-interfaces).
- **Apple, WWDC23 *Animate with springs*:** springs are set by duration and bounce (-1 to 1). The presets are smooth, snappy and bouncy ([session](https://developer.apple.com/videos/play/wwdc2023/10158/), [WWDC Notes](https://wwdcnotes.com/notes/wwdc23/10158)).
- **Apple HIG Motion:** motion should support the experience, not decorate it. It is never the only channel for meaning, and Reduce Motion minimises or removes it ([Motion](https://developer-mdn.apple.com/design/human-interface-guidelines/foundations/motion), [Reduced Motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)).
- **Material choreography:** motion guides focus. Keep one focal point at a time, and stagger elements rather than moving everything at once ([M1 choreography](https://m1.material.io/motion/choreography.html)). eBay's playbook warns against showing elements out of order ([eBay motion](https://playbook.ebay.com/foundations/motion/using-motion-in-product)).
- **Material 3 Expressive motion tokens:** two families. *Spatial* springs (position, size) run at damping 0.9 (standard) or 0.6–0.8 (expressive). *Effects* springs (opacity, colour) run at damping 1 and are stiffer. These values come from third-party packages, not Google's spec, which didn't fetch ([`motor`](https://pub.dev/packages/motor), [material_expressive](https://pub.dev/documentation/material_expressive/0.8.0/)).
- **Spring physics on the web:** springs keep velocity when interrupted, while keyframes restart from zero ([Josh Comeau](https://joshwcomeau.com/animation/a-friendly-introduction-to-spring-physics/), [Maxime Heckel](https://blog.maximeheckel.com/posts/the-physics-behind-spring-animations/)). Keep UI motion short, ease out, and use little or no bounce. These are secondhand summaries of Emil Kowalski's guidance ([skills.cat](https://skills.cat/skills/mrmps/smry/emilkowal-animations)).
- **Games' delayed damage bar:** the chunk just lost stays visible in a lighter shade, then catches up, so the size of the hit can be read. The 19-year-old persona reached for this "HP bar" model unprompted. No primary source was fetched; it's a common game UI convention.
- **Not found:** how Apple's Activity rings animate a fill (no primary source), and official m3.material.io motion pages (they render with JavaScript).

## Patterns compared
| Pattern | Teaches "tank" | Cost | Fit |
|---|---|---|---|
| A. Drain at save time (before) | Barely: plays under the scrim | — | Drop |
| B. Drain once the tray has gone | Yes, every save | Defer Home's reload until the tray's exit ends | Build |
| C. B plus a lighter trail of the spent slice | Yes, and shows how big this spend was | A second fill value and one painter band | Build |
| D. Today's block fills in when Home appears | Yes: shows it's a container | Each time Home appears, `calm` spring | Build |
| E. Caption "₹X left" under the block | Yes, with words | Repeats the hero number | Drop |
| F. Recolour (not marigold) | Removes the caution read | Breaks the one-signal rule; all five tied yellow to "today" | Drop |
| G. Shake or bounce when over | No; reads as an error | Contradicts "It happens" | Drop |

## Recommendation
- **Visible minimum:** once anything is spent today, today's fill is at most 0.9. That is a 4dp band on the 40dp block (BR-6).
- **Choreography after a save**, one focal point at a time:
  1. The tile flashes.
  2. The tray closes completely.
  3. Home reloads, the level falls on `standard` and the number rolls in the same frame.
  4. A marigold trail at 35% opacity holds the spent slice for 250ms, then follows on `calm`.
- **Fill in:** each time Home's blocks appear (launch, back from Spends, a new day), today's block fills from empty to its level on `calm`. Once a day would need a stored "last filled" date; every appearance is simpler and still teaches.
- **Overspend:** the level falls away, uncovering the hatch, and the future blocks shrink together. A 30ms stagger was considered and left out to keep one controller.
- **No bounce anywhere:** the drain isn't thrown by a finger, so damping stays 1.
- **Reduced motion:** a 150ms crossfade to the end state, with no trail and no fill in.
- **Timing:** NFR-1's 400ms is read as "the drain begins within 400ms of the save". The Doherty threshold is about feedback starting.

## Risks
- The personas were simulated, not people. Re-run the panel with frame strips of the new motion. Test with real people when possible.
- Deferring Home's reload means the Today list also updates after the tray closes. That is intended: it's the same moment.
- The 0.9 cap overstates spending for tiny spends (₹10 of ₹11,218 shows a 10% gap). The hero number stays exact; the block only says "something was spent".
