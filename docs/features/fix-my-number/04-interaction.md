# Fix my number: interaction design (and the Used keypad)

> **Status: proposed (2026-11-13).** Not in SPEC, PLAN, UI_DESIGN or DECISIONS; no code. Builds on `01-ux-flow.md` (flow, wireframes W1 to W10, rule `E`, the guard) and `02-accounting-and-edge-cases.md` (F1 to F22). `03-` is reserved for the IA doc. Copy is a placeholder for `design-content`, values for `design-ui`/`design-system`, curves and springs for `design-motion`, window-class layout for `design-platform`, TalkBack depth for `design-accessibility`. This file is longer than ~150 lines because the owner asked for the whole interaction in one place; split it when approved. Sections 1 to 8 are Fix my number; section 9 is the *Used* keypad of `docs/features/yearly-costs/01-ux-flow.md` §4.3, kept consistent with it.

## 1. Container: decision

**A sheet in the bill-sheet route (a modal sheet over wherever it was opened), not a full page.** `01` §4 says "a full page or sheet"; this settles it.

| Criterion | Sheet in the bill-sheet route | Full page |
|---|---|---|
| Precedent | FR-HO-8 (bill amount), *Put in extra* (FR-SE-1 AC-1: "keypad in a sheet, in the bill sheet's route"), *Money coming in* AC-3 all open a keypad question in a sheet. Same anatomy, same close rules, same tests | A new page type for one keypad; the only keypad that is a page is onboarding |
| Three doors | Home foot row, Settings row and the install line all land in the same sheet and close back to where they started, with no new route | Needs a route that returns to two different parents |
| Context | The user's Home stays under the scrim, so the hero reflow after *Fix it* is visible (D91: Home holds its numbers while covered, then rolls) | Home is off-screen; the reflow is seen only after the page pops, the same moment but with no spatial link |
| Exits | Back, swipe down, scrim: all close with nothing saved (the FR-HO-8 AC-1 contract). Nothing to learn | Back only |
| Weight | The task is one number and one confirm; a page implies a destination | Over-weights it |
| Short windows | Body above the keypad scrolls; the keypad is fixed with `keyHeight` shrinking (as the tray does) | More room, but the keypad is the same size |
| Cost | The guard step and a three-line slot must fit: see §3 and §4 (the guard replaces the keypad in place, so the height never grows) | |

**Window classes.** The sheet inherits whatever placement the bill-sheet route gives on medium and expanded windows. Nothing may straddle a fold. In a tabletop posture the amount and slot sit in the upper half and the keypad in the lower. In landscape or two-pane, the amount and slot are one pane and the keypad the other, as the Add tray arranges them. `design-platform` to confirm; tests run at the `TestWindows` sizes.

**Used keypad (section 9) is not a separate sheet.** It is one question inside the saving's own sheet (as FR-SE-1 *Amount*, AC-3 of *Rows*), because the sheet is already open.

## 2. Keypad behaviour

The keypad is the shared `Keypad` (`lib/core/widgets/keypad.dart`): `1-9`, then `00 · 0 · ⌫`, never reordered (D13). The action key is the keypad's bottom-right `SignalKey`, in the place *Next* sits.

| Topic | Rule |
|---|---|
| Open | The amount is **empty**: nothing is prefilled, so the user reads their bank, not hisaab's figure (principle 87). The display reads ₹0 at the "empty" state |
| First key | Appends (there is nothing to replace). A leading `0` is ignored for display **except** that a pressed `0` makes the amount "typed 0", which is a valid answer (F3 "I have none left"). So the bloc holds `digits: String` ("" is empty, "0" is typed zero); the display shows ₹0 for both, and only "typed 0" enables the compare |
| Digits | `1-9`, `0`, `00` (on empty it gives "0"). Live Indian grouping. Tick haptic per key, as Add |
| 9-digit cap | A key that would make a 10th digit is refused: reject haptic, the amount shakes (`Shake`), no words (as FR-AD-2 and BR-10). Under reduced motion the shake becomes a 150ms outline flash on the amount well (a visible change must accompany the haptic); verify `Shake`'s own reduced-motion branch |
| No paise | No decimal key. `X` is whole rupees |
| ⌫ | Tap removes the last digit (tick). Removing the last digit returns to **empty** (helper back, key off). Long-press clears (the existing `onClear`). The visible alternative to the long-press is repeated taps |
| Quick chips | **None.** +₹10/+₹50 add amounts; this is a total. A "same as hisaab" chip is rejected: it would show `E` before the user typed (anchoring) and make *Spot on* a one-tap lie |
| hisaab's own figure | Hidden while empty. After the **first key** the slot shows it as the first words of line 1 ("hisaab thought ₹17,430."). It appears with the slot's 150ms crossfade (helper out, preview in), not a slide, and is stable from then on. If the user ⌫ back to empty, it hides again |
| Hardware keyboard | Digit keys type, Backspace is ⌫, Enter is the action key when enabled, Escape is Back. Match the Add tray if it already maps them; otherwise open question 6 |

## 3. The preview slot

The slot sits directly under the amount, as in the Add tray (FR-AD-1, FR-AD-3). **Fixed height by construction:** every state is a child of one `IndexedStack`, so the slot is as tall as the tallest state at the current text scale and never changes between states; only one child is visible and only that one is in semantics. No layout jump at any text scale, and no per-state height maths. The slot is `design-ui`'s to style (no red or green: direction is in words "less", "more").

**Structure:** line 1 anchors ("hisaab thought ₹17,430."), line 2 says the gap and its effect ("That's ₹4,200 less. Each day gets about ₹467 less."). This splits `01` §5's single sentence so that `E` is visible, as `01` §1.5 asks. Either line may wrap. Copy to `design-content`.

### 3.1 States and what *Fix it* does

| # | State | Slot | *Fix it* (marigold on `ink`, bottom-right) |
|---|---|---|---|
| S0 | **Empty** (nothing typed) | Helper: "Bank and cash together. Leave out older savings." | Off |
| S0b | **Loading** `E` (typed before it arrived) | Helper stays; the preview appears when `E` lands | Off |
| S0c | **`E` failed to load** | "Couldn't check your number." with a 48dp text key *Try again* (a visible retry, not a gesture) | Off |
| S1 | **Lower** (`X < E`, beyond 50 rule) | L1 anchor; L2 "That's ₹4,200 less. Each day gets about ₹467 less." (variants in `01` §5: "about", short of the bills, last day) | **On** |
| S2 | **Higher, small** (`gap` ≤ `I ÷ 10`) | L1 anchor; L2 "That's ₹1,000 more. Each day gets about ₹111 more." | **On** |
| S3 | **Higher, large** (`gap` > `I ÷ 10`) | L1 anchor; L2 "That's ₹30,000 more. Fix it will check with you first." (no per-day effect: the answer decides it) | **On.** Press opens the guard step (section 4); it posts nothing |
| S4 | **Equal** (`gap` under ₹1) | "Spot on. Nothing to fix." (one line) | **Off** |
| S5 | **Close** (rounded `X`, within 50, F2) | "Close enough. Nothing to fix." | **Off** |
| S6 | **Notice after a refused save** (F13) | "Things changed. Check the new amount." replaces L1 until the next key; the preview then follows the live ledger | On if a gap still exists |
| S7 | **Notice after *No*** | "Count only this month's money." until the next key | On or off as the live compare says |
| S8 | **Save failed** (F15) | "Couldn't save. Try again." until the next key | **On** again; digits kept |
| S9 | **Saving** | The current preview stays | Pressed fill, then disabled; label unchanged for the first second; after 1s "Saving…" |

**Disabled when nothing would post:** yes (S0, S0b, S0c, S4, S5, S9). A disabled key must not be silent. The slot already says why in S4 and S5; S0 has the helper; for TalkBack the disabled key carries a hint ("Type an amount first" or "Nothing to fix"). Disabled is shown by the `SignalKey` disabled treatment (hatch/outline and the words), never colour alone.

**Why *Fix it* stays enabled for large *higher* and the guard appears on press, not live:** swapping the keypad under the thumb while the user is still typing (a 6-digit total crosses the threshold mid-entry) is a hidden mode change that fast typists would trip over. The slot warns early (S3) so the user can correct digits first; the keypad changes only on a deliberate press.

### 3.2 Transitions

| From to | Motion |
|---|---|
| S0 to any preview (first digit) | 150ms crossfade of the slot children, helper out |
| Any preview to another class (S1 to S2, S2 to S4, and so on) | 150ms crossfade |
| Digit changes inside a state (numbers change only) | **Instant text swap**, no animation (per-digit fades flicker) |
| Back to S0 (⌫ to empty) | 150ms crossfade |
| *Fix it* label or enabled change | Fill/outline change, no movement; `design-motion` sets durations |

Reduced motion: the crossfade is the fallback anyway; the system setting scales controllers (as built for *your usual*, SPEC Q9), so do not force 150ms. Under 100ms: every digit updates amount and slot in the same frame (the compare is a pure sum over a value the bloc holds; no await per digit).

## 4. The guard step (higher by more than `I ÷ 10`)

**Where:** a second step **in the same sheet**. The amount display and the slot stay; **the keypad area is replaced** by an answer panel of the same height (both live in one `IndexedStack`, so the sheet does not resize). The keypad's own keys never change meaning, so D13 holds.

```
 <  How much of this month's money is left?
          ₹ 47,430                              (read only, no keypad)
 hisaab thought ₹17,430.
 That's ₹30,000 more. Is all of it from this month?
 [      No, some is older       ]   56dp, full width
 [        Yes, add it           ]   56dp, full width
```

| Item | Rule |
|---|---|
| Trigger | *Fix it* in S3 |
| Keys | Two **equal-weight** 56dp full-width keys stacked, same style, neither marigold (`design-ui` to style). *No* first: it is the safe answer for a typed total, so it is first in reading and focus order. They sit apart from each other's edge (`01` §3) |
| *Yes, add it* | Posts the *Got* (section 5). Success path as below |
| *No, some is older* | Back to the keypad step. The typed digits are **kept and shown**; the next key **replaces** them (the FR-AD-8 prefill rule, so retyping a total as this month's is not nine backspaces); ⌫ edits them in place. The slot shows S7 "Count only this month's money." until the next key. Focus returns to ⌫ so one press edits |
| Back, system back, predictive back | A step back, not a close: from the guard Back = *No*. `PopScope` holds the sheet while the guard is shown; a second Back (on the keypad step) closes it. Predictive back previews the keypad step |
| Scrim, swipe down | Closes the sheet, nothing posted (the same exit every sheet has); the digits are dropped |
| Gesture alternatives | Both answers are plain keys; nothing is gesture-only |
| Digits | Not editable in the guard step (no keypad). The amount well shows its read-only look, and TalkBack reads "47,430 rupees" |
| Live change underneath | If `E` changes while the guard is open (midnight, a bill posts) the answer panel stays; the save re-checks the gap in its write (F13) and, if it differs, saves nothing, returns to the keypad step and shows S6 |
| Not live | The guard never appears while typing; only after *Fix it* |
| Mode | Visible (the keypad is gone, the question is on screen) and one Back leaves it |

Considered and rejected: the two answers in the keypad's bottom row (breaks D13 and cannot hold two 56dp keys); an `AlertDialog` (a second layer, banned feel: reversible over confirm); live swap (mode under the thumb).

## 5. Save

**Event:** `FixMyNumberSubmitted(typedRupees, expectedGap, confirmedLarge)`, on `droppable()` (BR-10, `.claude/rules/bloc.md`). The event carries the typed figure and what the user saw, **not** just the gap, so the write recomputes `E` and refuses a stale gap (F13). Double taps on *Fix it* or *Yes, add it* produce one entry (F14); the key also goes to its disabled state on the first press.

| Step | What the user sees, hears, feels |
|---|---|
| 1. Press | Key pressed fill (under 100ms), no haptic on press. The key disables |
| 2. Write | Normally under 100ms: no spinner. Over 1s: label "Saving…" (Nielsen) |
| 3. Success | The sheet closes (spring close per `design-motion`). **After it has fully closed** Home reloads and its hero rolls to the new value (D91; details to `design-motion`: one roll, today's block and the hero reflow together, "calm, no praise"). `Haptics.success()` fires as the sheet starts closing, paired with that visible change. From Settings the same close; the hero is not under it, so the snackbar carries the value |
| 4. Snackbar | Through the snackbar host: **"Fixed. Today you can spend ₹963."** with *Undo*. 4s, or until dismissed when TalkBack runs (D105). Hero ₹0 variant "Fixed. Today you can spend ₹0." is `design-content`'s to soften. If Home cannot show it yet (loading or a failed reload), the Undo waits for Home's next good load (D127) |
| 5. Undo | Removes the entry; the number goes back; `Haptics.tick()`; polite announcement "Undone." |
| Back while writing | Closes the sheet; the save still ends with its Undo on the parent (FR-HO-8 AC-6) |
| Failure | The sheet stays, digits kept, S8 "Couldn't save. Try again."; `Haptics.reject()`; *Fix it* re-enabled. A failure after *Yes* returns to the keypad step (a second *Fix it* asks again; accepted, rare) |
| Refused as stale (F13) | Nothing saved; the preview refreshes; S6; `Haptics.reject()` |

Haptic vocabulary stays `tick`, `success`, `reject`, `threshold` through `Haptics` only; no new effect, and one per event.

## 6. Saffer table (the three micro-interactions)

| | Typing a figure | *Fix it* | Guard |
|---|---|---|---|
| Trigger | A keypad key (or ⌫) | Press of the action key | *Fix it* in S3 |
| Rules | Section 2 caps and zero rule; compare with `E` each key; pure | Section 5: re-check in the write, save once | Two answers; Back = *No* |
| Feedback | Amount, slot text and *Fix it* state in the same frame; tick; reject + shake at the cap; polite spoken summary after a 400ms pause | Pressed fill, close, hero roll, `success`, snackbar | Keypad swaps for the answers; focus moves to the question; no haptic on entry |
| Loops and modes | None; no repeat timers. Long-press ⌫ clears once | None | The guard is the only mode; visible; one Back leaves it; *No* keeps digits |

## 7. Component states

State is fill, outline, hatch and words, never colour alone, no red or green; marigold only on *Fix it* (act). "Hover" applies to a mouse or keyboard on large screens.

| Component | Rest | Pressed | Focused | Hovered | Selected | Disabled | Loading | Error |
|---|---|---|---|---|---|---|---|---|
| Digit, `00`, `0`, ⌫ keys (`KeypadKey`) | As the app's keypad | Pressed fill, tick | `FocusRing` | Hover fill | n/a | Never disabled (the cap refuses a digit with reject and shake) | n/a | n/a |
| Amount well | ₹0 or the typed figure | n/a | Not focusable; read by TalkBack | n/a | n/a | Read-only look in the guard step | n/a | Cap: shake or outline flash |
| *Fix it* (`SignalKey`) | Marigold on `ink`, S1/S2/S3/S8 | Pressed fill | `FocusRing` | Hover fill | n/a | S0, S0b, S0c, S4, S5, S9 (hatch/outline and hint) | S9: "Saving…" after 1s | Stays on; S8 line |
| Guard keys | Equal outlined keys | Pressed fill | `FocusRing`; first focus on *No* | Hover fill | n/a | Disabled while the save runs | "Saving…" on the one pressed after 1s | Back to keypad step with S8 |
| *Try again* (S0c) | Text key 48dp | Pressed fill | `FocusRing` | Hover fill | n/a | n/a | Pressed, then helper | S0c line while it fails |
| Back (`HisaabBackButton`) | Top-left | Pressed fill | `FocusRing` | Hover fill | n/a | n/a | n/a | n/a |
| Slot | Helper or preview | n/a | Not focusable | n/a | n/a | n/a | S0b | S0c, S6, S8 |
| Snackbar *Undo* | Text action | Pressed fill | `FocusRing` | Hover fill | n/a | After it is used | n/a | n/a |

**Focus order** (keyboard, D-pad, TalkBack swipe): Back, title, amount, slot, keys `1` to `9`, `00`, `0`, ⌫, *Fix it*. Arrow keys move within the keypad grid. Guard step: Back, title, amount, slot (the question), *No*, *Yes*. After *No*, focus to ⌫. The sheet traps focus while open and returns it to the control that opened it (foot row, Settings row, or the install line, which is gone once seen: then to Home's top).

**TalkBack.**
- The title is a heading. The amount reads as "13,230 rupees" (spoken amounts as `.claude/rules/accessibility.md`); it is **not** a live region, so digits are not announced one by one (the key you pressed is spoken by the key).
- The slot is one **polite live region** whose label updates **400ms after the last key**, or at once when the state class changes. So fast typing says one sentence, not twelve. The sentence is: "hisaab thought 17,430 rupees. 4,200 rupees less. Each day gets about 467 rupees less." Order matches the wireframe.
- *Fix it*: "Fix it, button" plus the disabled hints in 3.1. TalkBack double-tap is the only activation needed; there are no gesture-only actions (WCAG 2.5.1). The long-press clear has taps on ⌫ as its alternative.
- Guard: focus moves to the question (read once), then *No*, *Yes*.
- Snackbar: the existing host announces it, and it holds until dismissed.
- All targets are at least 48dp (keys are 64dp, the guard keys 56dp); at 1.5x text, the slot grows (via the `IndexedStack`) and the body scrolls above the fixed keypad.

## 8. Edge cases

| Case | Behaviour |
|---|---|
| Double tap on *Fix it* or *Yes* | One entry (`droppable()` plus the disabled key) |
| Fast entry, then *Fix it* inside the 400ms announcement window | Compares what was typed at the press; the spoken sentence may lag, it is never wrong for the write because the write recomputes |
| Typed 0 versus empty | Different states (section 2); *Fix it* works for typed 0 (F3) |
| ⌫ to empty after a preview | Helper returns, key off, no leftover notice |
| `E` unchanged and digits `E` (F1) or within 50 (F2) | S4, S5; *Fix it* off |
| Rotation, fold, window resize | Digits, step (keypad or guard) and notice live in the bloc and survive; the sheet re-lays out; the guard stays on the guard |
| Tabletop and two-pane | Section 1: amount and slot upper or one pane, keypad lower or other; the guard answers replace the keypad pane |
| Midnight or a recurring post while open | Preview follows the live ledger; the save re-checks (F13, S6) |
| Android system back, predictive back | Keypad step: closes, nothing saved. Guard: a step back to the keypad. While writing: closes, the save still ends with Undo |
| App backgrounded with digits | Digits kept for the process life; killed, dropped (nothing saved, like every sheet) |
| Gesture nav insets | The keypad sits above the bottom inset (edge-to-edge); the sheet respects it |
| Reduced motion | Crossfade only; the cap flash replaces the shake; the hero reflow falls back per `design-motion` |
| TalkBack | Section 7; polite, debounced, no per-digit speech |
| 9-digit total with `E` huge | Compare is on `int` paise; no overflow; the cap is on digits |

Component tests to write with the build (one per state): empty, loading, load error, lower, higher small, higher large, equal, close, notice after *No*, notice after a refused save, saving, failed save, cap refusal, typed 0, ⌫ to empty, the guard's *No* (digits kept, first key replaces) and *Yes*, Back in the guard, double tap, TalkBack label after the debounce, reduced motion, and `TestWindows` sizes including a fold.

## 9. Used keypad (yearly costs)

Source: `docs/features/yearly-costs/01-ux-flow.md` §4.3 (S5, S5b, S5c). Same pattern as Fix my number; the differences are what the cap is and where it lives.

| Topic | Rule |
|---|---|
| Container | **Not its own sheet.** It is one question inside the saving's sheet (the *Amount* row pattern, FR-SE-1): Back returns to the slip, the scrim and swipe close the whole sheet. Opened from Home's due-soon row it closes back to Home |
| Keypad | The shared `Keypad`; the amount starts **empty** (₹0 means "typed nothing"; ₹0 is refused, *Save* off). No quick chips; the one shortcut is *All of it* |
| *All of it* | A 48dp chip right of the amount: rests `hairline`, fills `ink2` while the amount equals the balance (D89), `selected` in semantics. It **prefills** the whole balance; the first key afterwards **replaces** it (FR-AD-8), so a partial amount is one tap plus digits. Tapping it again changes nothing. It is deselected by any digit or ⌫ that changes the amount |
| Cap | A digit that would pass the balance is **refused** like the 9-digit cap: reject haptic, the amount shakes (flash under reduced motion), plus a line because the cause is not obvious: "That's all that's set aside. Add anything more as a spend." No red |
| Slot (fixed height, `IndexedStack` as section 3) | L1 "₹4,000 is set aside." becomes "₹{left} will be left." as digits are typed ("₹0 will be left." at the balance); L2 always "Your daily number doesn't change."; the refusal line replaces L1 until the next valid key. Per-digit text swaps instantly; changes of state crossfade 150ms |
| Action key | *Save*, marigold on `ink`, bottom-right. Off when empty or ₹0 (hint "Type an amount first") and in S5c "Nothing to set aside to use." |
| Save | `droppable()`; on success `Haptics.success()` and the sheet closes to the list (nothing on Home moves: no hero reflow); snackbar "₹4,000 used from Insurance" with *Undo* (4s, D105); Undo `tick`. Failure keeps the keypad: "Couldn't save. Try again." with `reject`. Back while writing closes and the Undo still shows |
| TalkBack | The slot is the same polite live region (400ms debounce); the refusal is read once. *All of it* reads "All of it, chip, selected" when it applies |
| States | Same matrix as section 7 with *Save* for *Fix it*, plus the *All of it* chip: rest, pressed, focused, hovered, selected (amount equals balance), disabled (balance ₹0) |

Consistency kept between the two: empty start; shared `Keypad` and no quick chips; first key replaces a prefill; refusal by reject plus shake with reason line; fixed-height slot; marigold pinned action key bottom-right; `droppable()` save; `success` then Undo snackbar; same failure line; same Back rules. Different on purpose: the cap source (balance versus 9 digits), no compare and no guard, and no hero reflow.

## 10. Doc edits needed (listed, not written)

| Doc | Change |
|---|---|
| UI_DESIGN §5 | The Fix my number sheet: slot states S0 to S9, the guard step, the sheet in the bill-sheet route; the Used keypad question |
| UI_DESIGN §6 motion | Slot crossfade (150ms) only on state-class change, instant text on digit change; guard swap; hero reflow after close (to `design-motion`) |
| UI_DESIGN §7 haptics | `success` on a fix and on *Used*; `reject` at the cap, on a refused or failed save; `tick` on keys and on Undo; none on entering the guard |
| UI_DESIGN §accessibility | Debounced polite live region (400ms) for a preview slot; spoken amounts |
| SPEC | New FR for Fix my number with ACs per state (as listed in `02` §6), and ACs for the *Used* keypad in FR-SE-1 |
| DECISIONS | Container: sheet in the bill-sheet route. Guard on press, not live, and replaces the keypad in place. No quick chips on a "total" keypad. Digits kept, first key replaces after *No* |

## 11. Open questions

1. **`E` shown as line 1** ("hisaab thought ₹17,430.") departs from W4's wording (which shows only the gap). Principle 86 favours showing it; the owner or `design-content` to confirm.
2. **First key after *No* replaces** the kept digits (my choice, consistent with FR-AD-8) rather than appending. Say if the owner meant append.
3. **Guard on the press of *Fix it*, not live**, and *Fix it* enabled in S3. Costs the same taps as `01` (digits, *Fix it*, *Yes*).
4. **"Typed 0" as a valid state** needs the keypad's digit string to distinguish empty from "0" (the Add tray treats 0 as nothing). A small keypad-state difference to confirm in the build.
5. **`E` fails to load** (S0c, *Try again*): worth the extra state, or open the sheet only once `E` is loaded and fail to open with the snackbar "Couldn't open. Try again."?
6. **Hardware keyboard mapping** (digits, Enter, Escape): does the tray have it? If not, leave it out of scope for both pages.
7. **Guard keys' order and style:** *No* first is my call (safe answer); both unfilled by marigold. `design-ui` to style, `design-accessibility` to confirm the focus start.
8. **Tabletop and two-pane arrangement** of a sheet in the bill-sheet route: `design-platform` to confirm; I have not verified how the route lays out today.
9. **Soft copy for hero ₹0** in the snackbar, and "about" prefix rules: `design-content`.
10. **Used keypad:** is *All of it* tapping-again a no-op acceptable, versus clearing the amount?
11. Open owner questions from `02` §7 (guard threshold, edit, late pay, Spends line, title) still stand.

## Source scope
`docs/features/fix-my-number/01-ux-flow.md`, `02-accounting-and-edge-cases.md`, `docs/features/yearly-costs/01-ux-flow.md`, `docs/design-research/case-studies/33-product-gap-analysis.md` (Owner answers), SPEC FR-AD-1 to FR-AD-3, FR-AD-8, FR-HO-8, FR-SE-1 (*Money coming in* AC-3 and AC-4, *Put in extra* AC-1 to AC-4), BR-10, `lib/core/design/haptics.dart` (`tick`, `success`, `reject`, `threshold`), the `lib/core/widgets/` file list and `keypad.dart` header. `signal_key.dart`, `shake.dart`, the snackbar host and `hisaab_motion.dart` were not read; their states and reduced-motion branches are to be verified in the build. Case study 34 was not re-read for this pass (its decisions arrive via `01` and `02`).
