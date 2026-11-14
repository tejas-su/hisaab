# Habits: the missed-log line (interaction design)

> **Status: signed off 2026-11-13 (`docs/features/fix-my-number/08-design-qa-and-signoff.md` §8; O14 to O16 and X18, X35, X36 applied below); built 2026-11-14 (see "As built" at the end).** SPEC BR-17, FR-HO-3 and D170 to D173 now carry the rules. It fills in `04-ux-and-copy.md` ("Missed-log question") and applies the owner's answer in case study 33 (P4′-1): the tap opens Add **at the keypad, step 1**. Where this file and `04-` disagree, this file wins for the missed-log line. Mockup 43 (`docs/design/mockups/43-missed-log-line.html`) is not redrawn; its banner lists where this file supersedes it. SPEC wins once written.

## Job

When I spent on something I usually spend on and forgot to log it, I want a quiet question on Home that gets me to the keypad, so the number stays honest. Ignoring it is free.

## Source scope

`lib/home/presentation/pages/home_page.dart` (`_nudge`), `lib/home/presentation/widgets/due_soon_row.dart` (the shape to copy), `lib/app/routes.dart` (`openAddTray`), `lib/habits/domain/detectors/usual_spend_detector.dart`, `lib/habits/domain/suggestion_gate.dart`, `lib/core/design/haptics.dart`. SPEC BR-17, FR-AD-1, FR-AD-10, FR-HO-3, FR-WG-4 to 7.

## 1. Trigger and rules

**The line shows** when all of these hold at an *evaluation point* (below):

1. Home is `HomeReady`, not *No income*, and not in an over state (`OverCard.appliesTo`). Reason: asking for more spending when the user is already over only deepens it.
2. The nudge slot is free: no waiting bill, no due-soon bill and no install line (FR-HO-3). The line is the **fourth and lowest** item of the slot (waiting, due-soon, install, missed-log; X35, `03-information-architecture.md` §1.2). In over states and in *No income* it waits (rule 1 and O14).
3. A Regular habit (BR-17) of today's day type, not fading, whose category is shown on Home and whose gate is open (no Undo-quiet today, no rest, not forgotten).
4. The category has **no entry dated today**, typed or posted.
5. Now is at least **90 minutes after the window's end** (kept from `04-`), on the same local date as the window. A window that crosses midnight never asks (its 90 minutes would fall in the small hours). Inside the window the *your usual* pill already covers the user, and asking early can be wrong because the spend may still be coming.
6. The habit has not been **asked today** (the stored `asked_on`, below).

With two qualifying habits the detector's tie-break applies (higher share of days, later hit, lower id). Only one line is ever shown, and only one question a day in total.

**Evaluation points (decided on load, never mid-view; O16, X36, 05-F7).** **Cold start and resume only.** A door that opens a tray over Home (widget, tile, shortcut) resumes the app, so that resume is the evaluation, and the line is drawn under the scrim in Home's first frame. **A tray closing can only remove the line, never add it.** Not rebuilds, not ledger ticks, not rotation or fold, not the clock passing the 90-minute mark while Home is open. A reload caused by the user's own act can make the line **leave**, never **appear** (so closing a bill sheet does not bring the line in behind it). Like the pill, it is in Home's first frame or waits for the next evaluation point; it never pops in late.

**Late habits (decided, O16).** If the habits load after Home's first frame on a cold start, the line is **missed for that open**: no pop-in, no 150 ms late arrival. It is evaluated again at the next cold start or resume. Device check D15 confirms it does not appear mid-view.

**The line clears when:**

| Cause | What happens |
|---|---|
| The user taps it | Marked asked; leaves when the tray has fully closed |
| An entry in that category is logged (any door, the pill included) | Rule 4 fails; leaves with the Home reflow |
| The user ignores it | Nothing happens on screen. Leaving the app counts as the user's act: the next resume does not show it again (asked) |
| The category goes quiet (Undo of a pill add) or is forgotten | Rule 3 fails at the reload; leaves |
| Midnight | The `MidnightListener` reload clears it with everything else |
| The window passing | Not a cause: the line exists only after the window |

"Asked" (`asked_on`) is written **only when the line is visible**: on screen with Home visible and no tray or sheet over it (the install line's *seen* rule is the same, `03` §1.3 rule 4). A line drawn under a tray that opens straight away (a door-opened tray) is **not asked**, and returns at the next evaluation point. The line is hidden under a tray, so a user can never see it leave; the tray close removing it is silent.

## 2. The tap

Trigger: tap on the row. Rules, feedback and end state:

1. `Haptics.tick()`, once. The row shows its pressed fill.
2. `openAddTray` runs as for the Add key: Add tray, **step 1, ₹0, *Spent*, dated today**, nothing else added or reordered.
3. The tray is given **this habit** as `usual`, even though now is outside its window (kept from `04-`). So the *your usual* pill shows in the 48dp slot (FR-AD-10) with the same look, tap and Undo as ever. FR-AD-10 AC-1 gains one clause: "or the tray was opened from the missed-log line for that habit".
4. The pill is the **one-tap answer** ("Food ₹55 · your usual"). Typing digits crossfades it to the preview (AC-3) and the normal path follows: digits, Next, tile. The line's category is **not** pre-selected on step 2; the tiles stay untouched (no reorder, no tap added, nothing moved).
5. Tap count: line, pill = 2 taps for the usual; line, digits, Next, tile = the normal Add path after the first tap. The Add path itself gains and moves nothing: the line is another door into step 1, as the widget and tile are.
6. Double tap: the second tap is ignored until the tray has closed (the row stays on screen under the scrim, so without a guard two trays could open).

**Back without saving** (system back, drag down, scrim tap): the line **goes**. The tap answered the day's question, and a line that came back would be a repeat (owner: no repeat). No haptic. The row collapses after the tray has closed. The user can still add through the Add key. After a save the collapse joins the Home reflow and finishes no later than the drain (curve and spring: `design-motion`; reduced motion: 150ms crossfade).

## 3. Component states

The line is a sibling of `DueSoonRow` and `WaitingBillRow`: a `Pressable`, no new control kind.

| State | Look | Notes |
|---|---|---|
| Rest | `sunk` squircle (18), min 56dp, edges as the due-soon row | Words carry the meaning; nothing colour-only; no marigold (principle 6 of `04-`) |
| Pressed | `hairline` fill, as `DueSoonRow` | Tick fires on press-up with the open |
| Focused (keyboard, large screens) | The `Pressable` focus ring (`focusRadius` 18) | Enter and Space activate |
| Hovered (mouse) | 1dp `ink2` outline, no fill change | Distinct from pressed. `hairline` on `sunk` is 1.18:1 and invisible; `ink2` is 5.55 and 5.48 (`06` C2) |
| Selected | n/a | |
| Disabled | n/a | The line is hidden rather than disabled |
| Loading | n/a | The tray opens inside 100ms; no spinner |
| Error | n/a | A failed pill save is the tray's state (FR-AD-10 AC-4) |
| Gone | Not in the tree; the slot takes no height | Collapse as in section 2 |

**"Reads as an entry" (mockup 43 problem 1, T10): decided.** The well holds a **neutral question glyph** (one Hugeicons "help" or "question" mark through `AppIcon`, or a `HisaabGlyphs` drawing per D48; `design-system` picks, P14 style), **never the category glyph**. Why: a Today row is "category glyph + name + amount"; this row would carry the same glyph, the same squircle and the same height, so a first-time user reads it as a logged Food entry (and its chevron as a detail link). Only the glyph carries that wrong signal, and a question mark says "this asks something" without any word. The category is still named in line 1 ("Spent on Food today?"), so nothing is lost for a user who wants to know which habit. No amount is shown on the line (the pill holds it in the tray). T10 still tests this (pass: no more than 1 of 5 read it as an entry); if it fails, change the shape next, not the copy.

**Anatomy** (FR-HO-3 shape): a neutral question glyph (`AppIcon`, see above) in a `surface` icon well; line 1 "Spent on Food today?" (`bodyMedium`); line 2 "Usually around 1 pm." (`bodySmall`, in the date line's place); a 18dp `AppIcons.next` chevron in `ink2`. Start inset `HisaabSpacing.m`, so the well's glyph lines up with the hero and Today list. At 1.5x text the row grows and the lines wrap; the category name is never cut. In two-pane layouts the line lives in Home's pane. The `04-` rule "Spends insights wait while it shows" is **single-pane only**: in two-pane both panes are on screen, so the insight would blink with the line (`07` §7); there the insight does not wait (`design-ia` may overrule).

**No ×.** `04-` gave the row a 48dp × ("Not today"). Dropped: the owner's journey has ignoring clear the line, a chevron next to a × is two trailing targets in a row built for one, and the line shows once a day anyway. *Forget* in Settings stays the way to stop a habit for good. Open question 2.

## 4. Quiet rules

- No repeat, no count, no streak, no badge, no notification, no sound. Once a day, once.
- The line has no Undo of its own. A pill add from the tray has the usual snackbar and Undo (BR-10), and that Undo quiets the category until midnight (BR-17).
- *Forget* (FR-SE-2 AC-6) and a rest end the line for that category, with no sign. Undo of *Forget* brings the habit back and so, on a later day, the line.
- Tapping, ignoring and Back write only `asked_on`. They never count as an Undo, so they never rest a habit by themselves. A habit nobody follows loses its window through BR-17's "3 most recent days missed" rule.
- Copy describes the person's habit, hedged ("usually", "around"); "no" is a fine answer; no guilt, no urgency (voice rules in `04-`).

## 5. Semantics (TalkBack)

- One merged node, role button: "Spent on Food today? Usually around 1 pm." then the hint "Opens the keypad." (reuse the waiting row's hint if the key exists).
- It is not a live region and shows no announcement on appearing or leaving; the focus order is the hero, the other cards, the line, the Today list. **Focus return (X18, `06` T6):** when the tray closes and the line is still there (a save that left it, or a door tray), focus returns to the control that opened the tray. When the line itself was the opener and it is removed (Back without saving, or after a save), focus goes to **the node now in its place, the "Today" heading**, not to the page top. The install line follows the same rule.
- In the tray the pill reads "Add Food, 55 rupees, your usual" (FR-AD-10 AC-5). `{category}` and time come from `AppLocalizations` and `DateFormat.j` for `en_IN`.
- Target 56dp or more; no gesture-only path (no swipe on the row).

## 6. Other doors (D156)

The widget (FR-WG-4), the Quick Settings tile and the app shortcut **never show the line** (the widget's only tap targets are Add and Home; the tile never shows money or questions). They open the tray at step 1 with no habit carried, so the pill shows only inside the window (AC-1). If the door opens Home behind the tray, the line is not evaluated until the tray closes, and it is not shown at all if the door's save logged that category. A line shown on Home is the only door that carries a habit.

## 7. Edge cases

| Case | Result |
|---|---|
| Double tap on the row | One tray (section 2.6) |
| Fast entry: user types the moment the tray opens | Pill crossfades away; the line is already asked |
| Habit window crosses midnight | Never asks |
| Entry in the category deleted later today | Still asked, no second question |
| Category hidden after the habit formed | No line (E59) |
| Rotation, fold, window change while Home or tray is open | No evaluation; the tray keeps its state; nothing straddles a fold |
| Clock or time zone changes | Next evaluation point |
| Habits not yet loaded at Home's first frame (cold start) | Missed for that open (O16): no line, no pop-in, until the next cold start or resume |
| A door-opened tray over Home | The line is evaluated at the resume, drawn under the scrim, **not asked**; the tray close can only remove it |
| Reduced motion | Collapse is a 150ms crossfade; the system setting wins (SPEC Q9) |

## 8. Build notes

- A pure `MissedLogDetector` beside `UsualSpendDetector`: `(HabitIndex, now, categories, askedOn, day type)` to `Option<UsualSpend>`, tested with `FakeClock` for the 90-minute edge, midnight-crossing windows, ties and the quiet states.
- `home_page.dart`'s `_nudge` gains the fourth branch (after the install line); `openAddTray` takes the carried `Option<UsualSpend>` instead of calling the detector for this door.
- Memory of "asked today": the `suggestion_state` row has no fitting column (`quiet_on` feeds the 14-day Undo count, so reusing it would corrupt it). Needs a new `asked_on` column (migration 005) or a day-keyed preference. It holds category ids and dates only, so backup, restore and *Delete everything* (BR-16) stay right with a column.
- Widget tests per state (rest, pressed, focused, hovered, gone), at 1.5x text and the `TestWindows` sizes; a Home-plus-tray test for tap, Back and save.

## 9. Doc edits (not made)

| Doc | Edit |
|---|---|
| UI_DESIGN §5 (Home, Add step 1) | The line in the nudge slot as the fourth item; its anatomy (neutral question glyph) and states (hover `ink2`); the carried pill |
| UI_DESIGN §6 | Collapse uses `resize` + `easeOut` (a spring cannot drive an `AnimatedSize`, `05` §2 and §4); reduced motion: 150 ms fade, then height at once |
| UI_DESIGN §7 | Row tap: `tick`; the pill's success stays `success`; Back none |
| SPEC FR-HO-3 | Fourth line type, its rules (section 1), over-state and *No income* exclusions, evaluation at cold start and resume only |
| SPEC BR-17 | "Asked today" memory; the 90-minute rule; midnight-crossing windows excluded |
| SPEC FR-AD-10 AC-1 | The carried habit shows the pill outside its window |
| SPEC E-rows | Rows for Back, door-opened Home, no-late-appear |
| DECISIONS | Lift "stays proposed" (D153) for this line; record no ×, once-a-day, Back clears |
| `04-ux-and-copy.md` | Status line; priority table limited to the slot; replace the "Missed-log question" bullets; drop the `notToday` key |

## Open questions (answered by sign-off, 08 §8 O14 to O16)

1. **After the window plus 90 minutes**, not during it: accepted (O16).
2. **No ×:** accepted (O16).
3. **Late habits on a cold start:** missed for that open, no pop-in (O16).
4. **Saved yesterday silences the line?** No (O15).
5. **Where to store "asked today":** still open for the data agent: a new `asked_on` column (P10), not `quiet_on`.

Slot order across all proposals (waiting, due-soon, install line, then this line) and the rule that a lower line never appears mid-view: `docs/features/fix-my-number/03-information-architecture.md` (signed off 2026-11-13).

Motion for the line (how it arrives, collapses and clears; reduced motion; flags F2 and F7): `docs/features/fix-my-number/05-motion.md` section 4 (signed off 2026-11-13).

## As built (2026-11-14)

SPEC (BR-17, FR-HO-3, FR-AD-10 AC-1, E103 to E108) is now the source of truth; this file stays the interaction rationale. Plan: `docs/superpowers/plans/2026-11-13-missed-log-line.md`.

| Piece | File |
|---|---|
| `asked_on` on the entity, model, mapper, data source (`setAskedOn`, update-else-insert, never a replace), repository (`markAsked`) and the gate (`afterUndo` and `afterForget` copy it) | `lib/habits/domain/entities/suggestion_state.dart`, `lib/habits/data/...`, `lib/habits/domain/suggestion_gate.dart` |
| `MarkMissedLogAsked` (writes today from the `Clock`) | `lib/habits/domain/usecase/mark_missed_log_asked.dart` |
| `MissedLogDetector` and `MissedLog` (category, window, amount; `aroundHour`) | `lib/habits/domain/detectors/missed_log_detector.dart`, `lib/habits/domain/entities/missed_log.dart`; `UsualSpendDetector.rank` is now public |
| `HomeLinesBloc` (events: point, evaluated, shown, tapped, tray closed, entry logged, gate closed, slot taken, midnight) | `lib/home/presentation/bloc/home_lines_*.dart` |
| `HomeLinesDriver` (feeds the bloc from Home and the habits, owns the "Today" heading focus node), `MissedLogSlot`, `MissedLogRow`, `MissedLogProbe`, `HomeHeadingFocus` | `lib/home/presentation/widgets/` |
| Points, tap and the carried habit (`openAddTray(carry:)`) | `lib/app/routes.dart` |

Where the build differs from this file or the plan, and why:

- **A resume evaluates at once when Home is already ready.** A reload that yields an equal `HomeReady` emits nothing, so waiting for "the first `HomeReady` after the point" could leave the point latched and let an unrelated reload bring the line in mid-view. On a cold start Home is loading, so the evaluation waits for its first `HomeReady` as specified.
- **The bloc remembers `asked_on` itself (`HomeLinesState.askedOn`).** Writing `asked_on` does not reload the habit index, so a resume the same day would otherwise read a stale index and ask again (L3). It takes a `Clock`, as the plan listed.
- **A bill line that takes the slot removes the line (`HomeLinesSlotTaken`, not in the plan's list).** Without it a lower line would slide back in when the bill clears (E108).
- **`MissedLog` carries the habit's amount**, which the plan's shape lacked; the tap needs it to hand the Add tray the same `UsualSpend` as the pill. The row still shows none.
- **`HomeLinesTrayClosed` has no `saved` flag.** Saved or not, the line goes, so the flag would carry nothing.
- **`MissedLogSlot` is passed to `HomePage` and `MainScreen` as an optional builder (`missedLogSlot`)**, so their existing tests need no `HomeLinesBloc`. A bill line in the slot means the builder is not called.
- **Reduced motion:** the slot fades the line over 150 ms and drops its height at once (no `AnimatedSize`, which asserts with a zero duration); otherwise `AnimatedSize` runs over the `resize` token with `easeOut`.
- **The neutral glyph is `AppIcons.questionLine`** (`HugeIcons.strokeRoundedHelpCircle`); `design-system` may swap it.
- **Focus:** a tapped line that is removed returns focus to the "Today" heading through `HomeHeadingFocus`; when the tray closes and the line stays, Flutter's route focus restoration returns to the opener.
- **B6 (habit-derived Spends insights wait for the line, single pane)** is not built: BR-14 has no habit-derived insight yet. Add the hook with the first one.
- **Known narrow race, check on a device (08 §5 D15):** the covered check reads `HomeBloc.isCovered` in the line's first post-frame callback. A door-opened tray whose hold event has not been handled by then would let `asked_on` be written. The tray's own open path adds the hold in the same turn as the evaluation, so it is not expected, but only a device can confirm.
