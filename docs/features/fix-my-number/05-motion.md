# Motion for Fix my number, yearly costs (Used) and the missed-log line

> **Status: signed off 2026-11-13 (`08-design-qa-and-signoff.md` §8; X8, X10, X14 to X16, X20 and P1 applied below; flags F1 to F7 are settled in section 7).** Not in SPEC, UI_DESIGN or DECISIONS yet, and no code; SPEC wins once written. Covers three features in one place because they share one reflow: `01`, `02`, `03`, `04` of this folder, `docs/features/yearly-costs/01-ux-flow.md` and `docs/features/habits/08-missed-log-line.md`. **No new token is proposed** (section 8 lists the two naming notes). Longer than ~150 lines on purpose; split by feature when approved.

## 0. Read this first

**Tokens that exist** (`lib/core/design/hisaab_motion.dart`): springs `snap` (0.25 s), `standard` (0.35 s), `flick`, `calm` (0.55 s), all damping 1 except `flick`; durations `press` 120 ms, `numberRoll` 300 ms, `reducedCrossfade` 150 ms, `resize` 350 ms, `trailHold` 500 ms, `sheen`; curves `easeOut`, `sweep`. M3 split used for naming: *spatial* = a spring (`standard`, or `resize` + `easeOut` where a framework widget such as `AnimatedSize` cannot take a spring); *effects* (opacity) = a 150 ms `easeOut` fade (the value of `reducedCrossfade`, already used as the normal-mode crossfade by `usual_slot.dart` and `amount_text.dart`).

**What the code does today** (read, so the spec fits it):
- `TodayBar` animates `from -> to` on `standard` for any data change and jumps under reduced motion. It was built for a bite; a change of today's *share* (total) must be checked in `TodayBarPainter` (flag F5).
- `AmountText` rolls on `numberRoll` and crossfades 150 ms under reduced motion.
- `HomeBloc` holds numbers between `HomeTrayOpened` and `HomeTrayClosed` and reloads at the close (D91). Nothing yet tells it about the bill-sheet route (flag F1).
- Bill sheet swaps its question with `AnimatedSwitcher` on `numberRoll` (150 ms under reduced motion). The Add tray changes height with `AnimatedSize` on `numberRoll` + `easeOut`.
- `Shake` is **skipped** under reduced motion (no flash exists yet).
- The Today list inserts rows **at once** (case study 24), so every row motion below depends on pattern F being built.

**Rules applied.** One focal point at a time (principle 20). No bounce (22). Hold while covered (D91). Every change visible (21). Same path out and back. Duration never scales with the size of the change: a big drop is not slower or louder than a small one.

## 1. Fix my number: the save

**Order of focal points** (t = 0 is the frame the sheet's exit has ended, as the Add drain; before it Home holds its numbers):

| # | When | Element | Property: from to | Token | Reduced motion | Haptic |
|---|---|---|---|---|---|---|
| 0 | Press of *Fix it* / *Yes, add it* | The key | Pressed fill | `press` 120 ms | Same (a fill, not movement) | none |
| 0b | Write returns (normally under 100 ms; the key waits on it because a failure keeps the sheet open) | The sheet | Exit: slides down, scrim fades | the bill-sheet route's own exit | Route exit as today | none yet (see 5) |
| 1 | t = 0 | Hero number (and every figure in the hero card that changes: "tomorrow", spare) | Rolls old to new, ₹1,430 to ₹963 | `numberRoll`, `easeOut` | 150 ms crossfade, values still update | `Haptics.success()` in the **same frame** |
| 1 | t = 0, same frame, one motion | Today's bar | The share changes (A 1,850 to 1,383), so every boundary is re-spanned: the yellow's end moves 77% to 70% of the bar, the ₹420 bite widens 23% to 30%. One progress value, all segments together | `standard` | Jumps to the new picture (as `TodayBar` does now) | |
| 1 | t = 0 | Snackbar "Fixed. Safe to spend today: ₹963." | Rises 16dp, fades in | `standard` (the host's own) | 150 ms fade | |
| 2 | t = `numberRoll` (300 ms), so the hero is read first (X20: kept; a figure must be read before the list shifts; decide once for Add too, so the two saves do not differ) | New *Not logged* row, top of the Today list | Height 0 to row, opacity 0 to 1; at the 5-row cap the oldest row collapses at the same time on `snap`, so the list height and everything below it stay put | `resize` + `easeOut` (an `AnimatedSize`-style size change), fade 150 ms | No delay: height set at once, 150 ms fade | |

Lower and higher use the **same** rows, tokens and haptic. A rise is the mirror: yellow end 78.6%, bite 21.4% (hero ₹1,541 of 1,961).

**Must not punish a drop, must not celebrate a rise.** Same everything both ways, plus:
- Fixed duration. A ₹4,200 drop and a ₹40 drop take the same 300 ms; the digits roll, nothing else.
- No hatch (unless the new share really leaves today over, in which case the existing D114 over state applies, no shake), no marigold flash, no emphasis on the *Not logged* row, no extra haptic variant. `success` fires for both because the user's own act succeeded.
- No `sheen`, and no fill-in from empty: both belong to "Home appeared" (D106, D91) and would read as a reward on a rise. The bar moves from where it is.
- The *Not logged* row has no bite and no colour; its words do the explaining ("Added when you fixed your number.").
- Over/normal state change (hero reaches ₹0 and the over card shows, or leaves it): use whatever path the Add overspend uses (FR-HO-5, D114 step 3). I did not read it; if there is none, a 150 ms crossfade of the card contents.

**Doors.**

| Door | What plays |
|---|---|
| Home foot row, install line (Home is under the sheet) | The table above. The foot row sits at the end of Home's scroll, so the hero is probably **off screen**: the roll and bar still run (cheap, `RepaintBoundary`), the visible focal point is the snackbar then the row. Nothing scrolls Home for the user ("nothing moves unless you move it") |
| Settings row (hero not under it) | Sheet exit, then snackbar only. `success` fires as the exit **starts**, since there is no drain to pair with (X15). The Settings door needs its own snackbar and Undo home (P4), and **sends no hold** (P1) |

**Undo** (snackbar action). Reverses the values along the same path, **without** mirroring the order: the finger acted, so the answer starts at once (no added latency).

| When | Element | Motion | Reduced motion | Haptic |
|---|---|---|---|---|
| Tap, t = 0 | Snackbar leaves | `snap` | 150 ms fade | `Haptics.tick()` |
| t = 0 | Hero number rolls back; bar re-spans back (retargets from the current value and velocity if tapped mid-animation) | `numberRoll`; `standard` | crossfade; jump | |
| t = 0 | *Not logged* row collapses | `snap` (a removal the user asked for, as case study 24 pattern G) | 150 ms fade, then height at once | |

If Home cannot show it yet (D127), Undo waits for the next good load and plays then. Interruptible at every frame: a second fix or Undo mid-roll restarts the roll from the displayed value, never from the old target.

## 2. The sheet's own transitions

| Trigger | Element | Property | Token | Duration | Reduced motion | Haptic |
|---|---|---|---|---|---|---|
| Slot changes class (S0 to S1, S1 to S4, back to S0, S6 to S8 notices) | The slot's children in one `IndexedStack` | Opacity: out 1 to 0 and in 0 to 1 together, no slide, no height change | `easeOut` fade | 150 ms | **Same** (a fade is the permitted fallback, E13) | none |
| A digit changes, same class | Amount, slot figures | Instant swap, no roll, no fade (per-digit fades flicker) | none | 0 | same | `tick` per key |
| *Fix it* enabled, disabled, pressed | Key fill and outline | Fill change, no movement | `snap` | ~250 ms | same | none |
| After 1 s of saving | *Fix it* label | Crossfade to "Saving..." | fade | 150 ms | same | none |
| *Fix it* in S3: the guard | Keypad area to answer panel and the slot line to the question, **one event**; **the sheet shortens** to fit the panel (X8: the earlier "same height, no resize" is replaced; mockup 41 option B) | Opacity crossfade, no slide; the height change is `resize` + `easeOut` | fade; `resize` + `easeOut` | 150 ms crossfade, height over `resize` | Crossfade 150 ms; **the height change is instant** | none (04 §4) |
| *No, some is older* or Back or scrim in the guard | Panel to keypad, the slot to S7 over cleared digits | The same crossfade reversed, the sheet grows back; focus to the notice | fade; `resize` + `easeOut` | 150 ms | same, height instant | none |
| Cap reached (9 digits) | Amount well | Shake: sideways, 8dp, 3 swings, decaying; **plus a 2dp ring held on the well until the next accepted key** (X14) | `Shake` (`numberRoll`); the ring is a state, not an animation | 300 ms shake; ring held | **`Shake` is skipped under reduced motion; the held ring and the spoken line "That's the most you can type." carry it** (no 150 ms flash: it is gone before the eye arrives). Haptic stays | `reject` |
| Save failed (S8) or refused as stale (S6) | The slot line | Crossfade to the notice | fade | 150 ms | same | `reject`. **No shake**: the digits were valid |

Notes. The guard content is a crossfade, not a slide: the spatial change is "same place, other content"; only the sheet's height changes (X8). **Predictive back cannot preview it** (X10: the guard is not a route, `PopScope` holds, and `ModalBottomSheetRoute` has no back-gesture hook): Back commits, then the 150 ms crossfade plays. No "preview" promise anywhere. F6 is settled; D10 checks a started-then-abandoned back gesture and whether UI_DESIGN §10's sentence is about pages only.

## 3. Used (yearly costs)

| Trigger | Element | Property | Token | Reduced motion | Haptic |
|---|---|---|---|---|---|
| *Used some of it* | Slip body to the keypad question, **inside the saving's sheet** | Content swap, the sheet height follows | The bill sheet's existing `AnimatedSwitcher` + height change: `numberRoll`, `easeOut` | 150 ms crossfade, height at once | none |
| Back | Keypad question to slip | The same, reversed. The stamp must **not** replay: it lands once, at the sheet's first frame only (`bill_stamp_badge.dart` starts it in `initState`; keep the slip alive or hoist the stamp state) | same | same | none |
| *All of it* (a second tap clears the amount, X19) | Chip fill hairline to `ink2`; the amount fills | Chip fill on `snap`; digits swap instantly | `snap` | same (a fill) | `tick` |
| Digit past the balance | Amount well, then the refusal line | Shake plus a held ring and the line crossfade | as section 2 | held ring (no flash) | `reject` |
| Slot "will be left" | L1 figure | Instant per digit; 150 ms fade on a state change | as section 2 | same | none |
| *Save*, success | The sheet | Exit as any save. `success` fires as the exit starts **if nothing visible follows** (below), else at t = 0 | route exit | same | `success` |

**What moves instead of the hero.** Nothing in the hero: no roll, no bar change, no sheen (it must not look like a missed update; the keypad already said "Your daily number doesn't change"). After the exit ends (hold, as D91), at t = 0:

| What | Where | Motion | Reduced motion |
|---|---|---|---|
| "₹4,000 set aside" figure on the saving's list row, and the footer "₹5,000 still set aside" | Savings list (Settings door) | Both digits roll to the new value in the same frame, **one** motion | 150 ms crossfade |
| *Used* row in the Today list | Home (due-soon door) | Grows in as the *Not logged* row does. With no hero change to read first it starts at t = 0, not t + 300 ms | height at once, 150 ms fade |
| Snackbar "Insurance: ₹4,000 used" (X26, name first) | Host | `standard` rise (as above) | 150 ms fade |

`success` is paired with the first of these (the roll or the row). From the Settings door the figures roll under the closing sheet only after it has gone, so the haptic follows the exit end.

**Undo** reverses: figures roll back (`numberRoll`), the row collapses (`snap`), `tick`. The sheet does not reopen.

## 4. The missed-log line

| Moment | Element | Motion | Token | Reduced motion | Haptic |
|---|---|---|---|---|---|
| **Appears**: only in Home's first frame, at cold start or resume | The row in the nudge slot | **No motion of its own.** It is one of the cards under the hero and arrives with them (the group fade of case study 24: 250 ms `easeOut`, 120 ms hold, if built; otherwise it is simply there) | `easeOut` | Group 150 ms fade, no delay | none |
| Never appears mid-view | | Not rebuilds, ledger ticks, rotation, the clock passing 90 minutes | | | |
| Tap | The row | Pressed fill, then `tick` on press-up with the open | `press` 120 ms | same | `tick` once |
| Tray opens from it | Home under the scrim | The row **stays** under the scrim (nothing animates behind it) | | | |
| Leaves after the tray closed without a save (Back, drag, scrim) | The slot | Height collapses to 0 (the slot takes no height), contents fade 1 to 0 over the first 150 ms | `resize` + `easeOut`; fade 150 ms | Fade 150 ms, then height at once | none |
| Leaves after a save | The slot | Same collapse, starting at t = 0 with the drain/roll, so it ends together with it (same 350 ms, as 08 §2 asks "no later than the drain") | same | 150 ms fade, no delay | the save's `success` only |
| Leaves because rule 4 fails (an entry logged by another door, Undo of a pill add, forgotten) | The slot | Same collapse at the reload | same | same | none |
| Midnight | | Nothing separate: `MidnightListener` reloads and Home's first-frame arrival replays for everything | | | |

**Choreography when a save and the collapse share a reflow** (top to bottom, one thing at a time): hero roll and bar at t = 0; slot collapse at t = 0 (it is below the hero, so it moves nothing the eye is on); receipt row grows at t + 300 ms, after the collapse has mostly finished, so the list never moves up and down at once. The slot collapses only because the line was the **lowest** item; a bill row above it never moves.

**The nudge slot collapsing** has nothing under it that jumps: the Today list moves up once, smoothly, by the line's height and no more.

## 5. Timing against NFR-1 (drain begins at most 400 ms after the save)

| Step | Budget |
|---|---|
| Press fill (parallel, not on the path) | 0 to 120 ms |
| Write | 100 ms or less (typical) |
| Sheet exit | the route's exit, about 300 ms; the `standard` response is 0.35 s and a spring is within 2% of rest at about 0.32 s |
| Drain begins (t = 0) | about 400 ms: **tight**, the same as Add |

Fix my number adds no step and no wait before t = 0. The receipt row is deliberately 300 ms **after** t = 0, so it never delays the drain; the 400 ms limit is untouched. Measure the bill-sheet route's exit on the moto g45 (D56 device). If it is slower than the Add tray's, the fallback is to release the hold when the exit is 90% done (the scrim is then nearly clear); this needs a DECISIONS row because D91 says "ends".

Reduced motion cannot lengthen anything: every fallback is 150 ms or instant.

## 6. Reduced motion in one table (E13: all motion becomes a 150 ms crossfade, values still update)

| Item | Normal | Reduced |
|---|---|---|
| Hero number | `numberRoll` | 150 ms crossfade |
| Today's bar | `standard` re-span | Jumps to the new picture |
| Receipt row, *Used* row | `resize` + fade, delayed 300 ms | Height at once, 150 ms fade, no delay |
| Line collapse | `resize`, fade | 150 ms fade, then height at once |
| Snackbar | 16dp rise + fade | 150 ms fade |
| Slot and guard crossfade | 150 ms | the same (opacity is not "motion" under WCAG 2.3.3) |
| Guard sheet height change | `resize` + `easeOut` | Instant |
| Cap shake | 300 ms shake, then the held ring | Held 2dp ring until the next accepted key plus the spoken line (no flash; X14) |
| Used swap | `numberRoll` | 150 ms crossfade |
| Haptics | unchanged | unchanged (the setting is about motion) |

Information is never lost: every change that animates also updates the text, and the snackbar states the new number.

## 7. Conflicts and flags

| # | Flag |
|---|---|
| F1 | **Settled (P1, confirmed in `07` §5).** D91's hold is wired to `HomeTrayOpened`/`HomeTrayClosed` (the Add tray) only. The Fix sheet, the *Used* sheet (from the due-soon row), the install line's door and the waiting-bill sheet open in the bill-sheet route, which sends neither, so the drain plays under the scrim. Build: send `Opened` before and `Closed` after `route.completed`, in a `finally`, from those Home doors; **not** from the Settings door; `HomeBloc._trayOpen` becomes a counter. This already breaks FR-HO-8 today. A wider rule, not a new one |
| F2 | **Settled (X15):** `success` fires at t = 0 with the roll when Home is under the sheet (SPEC FR-AD-5), and at the exit start from the Settings door. `04` §5 carries this |
| F3 | **Settled (X20):** keep +300 ms after the roll for these rows (a fix changes a figure the user must read first, and a row insert moves the list). Decide **once** for Add too, so the two saves do not differ; not an owner question |
| F4 | **Settled (X16):** crossfades play at 150 ms in **both** modes (as `usual_slot.dart` does); opacity is allowed under reduced motion, anything that moves jumps. `04` §3.2 now says so |
| F5 | **`TodayBarPainter` was built for a bite** (same total, new bite). A change of total (A) must interpolate segment boundaries from old to new fractions. Verify, and add a widget test at 1,850 to 1,383 and 1,850 to 1,961. BR-6's 0.9 cap on the yellow still applies to the target |
| F6 | **Settled (X10):** no predictive-back preview is possible in a sheet route; Back commits, then the 150 ms crossfade plays. Every "preview" promise is dropped |
| F7 | **Settled (X36, O16):** the missed-log line is evaluated at cold start and resume (a door-opened tray resumes the app, so the line is drawn under the scrim in Home's first frame, no motion); the tray close can only **remove** it; *asked* is written only when the line was visible. `habits/08-missed-log-line.md` §1 carries this |
| F8 | The Add drain and the 50% trail (D91) are untouched. Fix my number does not use `trailHold`: nothing was spent today, so there is nothing for a trail to follow |
| F9 | `reducedCrossfade` is named for the fallback but is the normal crossfade too. No rename proposed; `design-system` may add a `crossfade` alias with the same 150 ms if the name misleads |

## 8. New tokens

None. Reused: `standard`, `snap`, `numberRoll`, `press`, `resize`, `easeOut`, `reducedCrossfade`, `Haptics.tick/success/reject`. The 300 ms receipt-row delay **is** `numberRoll` (the roll's own length), not a new duration. The cap flash under reduced motion is a build item for `Shake`, not a token.

## 9. Jank risk

- **Low.** Everything animates opacity, a transform, or one painter's progress inside the existing `RepaintBoundary` on the bar.
- **Medium: the receipt row and the line collapse animate height** (layout, not transform), on a list of 5 rows plus cards; use one `AnimatedSize`-style widget around the slot and one around the new row; never rebuild Home per tick. At the 5-row cap two rows animate at once.
- **Low: hero off screen.** The roll and bar still run; skip painting off-screen via the normal sliver culling, add no listener.
- **Check:** DevTools frame chart on the moto g45 for a Fix from the foot row (list shifting) and an Undo mid-roll.
- **Tests (injected time, `tester.pump` with durations):** end states for lower, higher and equal-share (no change); the order (bar and number at t = 0, row at +300 ms); Undo mid-animation retargets; reduced motion path for each row of section 6; stamp does not replay after Back; slot crossfade leaves only one child in semantics; the line never appears after the first frame.

## 10. Doc edits (listed, not made)

| Doc | Edit |
|---|---|
| UI_DESIGN §6 | A "Fix, Used, line" paragraph: share change re-spans the bar on `standard`, no sheen or fill-in; receipt row after the roll; slot and guard crossfades; the line's collapse; the table of section 6 |
| UI_DESIGN §7 | `success` on a fix and on *Used* with the first visible change; `reject` at the cap, on a refused or failed save |
| SPEC FR-AD-5 / FR-HO | The hold covers the bill-sheet route (F1) |
| SPEC E13 | Add the cap flash |
| `04-interaction.md` | §3.2 line (F4), §5 step 3 (F2), §4 predictive back (F6): done |
| `habits/08-missed-log-line.md` | §1 evaluation points (F7); collapse `resize` + `easeOut` (`standard` is a spring and cannot drive an `AnimatedSize`; X36 and this file's §2 and §4): done |
| DECISIONS | One row if approved: fixes and *Used* reuse the drain's tokens, receipt row after the roll, no sheen or fill-in on a correction |

## Source scope

`lib/core/design/hisaab_motion.dart`, `lib/core/widgets/today_bar/today_bar.dart`, `lib/core/widgets/shake.dart`, `lib/home/presentation/bloc/home_bloc.dart` (tray hold, lines 19 to 95), `lib/settings/presentation/pages/bill_sheet.dart`, `lib/add_entry/presentation/pages/add_entry_tray.dart`, UI_DESIGN §6 and §7, SPEC FR-AD-5 and E13 and NFR-1, DECISIONS D91 and D114, case study 24, principles 20 to 22 and 43, and `01` to `04` of this folder, `yearly-costs/01-ux-flow.md`, `habits/08-missed-log-line.md`. Not read: `TodayBarPainter`, `routes.dart`, the over-card swap (FR-HO-5), `amount_text.dart` beyond its durations, case study 05. Nothing was run on a device.
