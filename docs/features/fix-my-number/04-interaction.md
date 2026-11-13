# Fix my number: interaction design (and the Used keypad)

> **Status: signed off 2026-11-13 (`08-design-qa-and-signoff.md` §8; X1 to X19, X26, X45, X46 applied below).** Not in SPEC, PLAN, UI_DESIGN or DECISIONS yet; no code; SPEC wins once written. **Symbol note (X34):** the expected-money figure is `H` (formerly `E`), the typed figure `T` (formerly `X`). Builds on `01-ux-flow.md` (flow, wireframes W1 to W10, rule `H`, the guard) and `02-accounting-and-edge-cases.md` (F1 to F22). `03-` is reserved for the IA doc. Copy is a placeholder for `design-content`, values for `design-ui`/`design-system`, curves and springs for `design-motion`, window-class layout for `design-platform`, TalkBack depth for `design-accessibility`. This file is longer than ~150 lines because the owner asked for the whole interaction in one place; split it when approved. Sections 1 to 8 are Fix my number; section 9 is the *Used* keypad of `docs/features/yearly-costs/01-ux-flow.md` §4.3, kept consistent with it.

## 1. Container: decision

**A sheet in the bill-sheet route (a modal sheet over wherever it was opened), not a full page.** `01` §4 says "a full page or sheet"; this settles it.

| Criterion | Sheet in the bill-sheet route | Full page |
|---|---|---|
| Precedent | FR-HO-8 (bill amount), *Put in extra* (FR-SE-1 AC-1: "keypad in a sheet, in the bill sheet's route"), *Money coming in* AC-3 all open a keypad question in a sheet. Same close rules, same tests. **Correction (X4):** the route's body is one `SingleChildScrollView` with the keypad inside it, so it does **not** pin a keypad today; this change adds that (P2) | A new page type for one keypad; the only keypad that is a page is onboarding |
| Three doors | Home foot row, Settings row and the install line all land in the same sheet and close back to where they started, with no new route | Needs a route that returns to two different parents |
| Context | The user's Home stays under the scrim, so the hero reflow after *Fix it* is visible (D91: Home holds its numbers while covered, then rolls; the route must send the hold, P1) | Home is off-screen; the reflow is seen only after the page pops, the same moment but with no spatial link |
| Exits | Back, system back, Escape, swipe down, handle, scrim: all close with nothing saved on the keypad step (the FR-HO-8 AC-1 contract). The guard step differs: §4 | Back only |
| Weight | The task is one number and one confirm; a page implies a destination | Over-weights it |
| Short windows | The keypad, action key and typed amount are **pinned**; the title and slot scroll between them (X4). Keys are 56dp, 48dp when the window is short (X2) | More room, but the keypad is the same size |
| Cost | The guard step and a three-line slot must fit: see §3 and §4 (the sheet shortens for the guard, X8) | |

**Window classes (X5, X6, X46; `07-platform-review.md` §3 wins).** Stacked with the typed amount pinned at **every width under about 560dp**; side by side only for width of 560dp or more with a short height (landscape; 412×400 split-screen is borderline: test it). A 320dp window cannot hold a 220dp keypad pane beside a readable header. Nothing may straddle a fold: a sheet sits in **one sub-screen**, so **tabletop is the whole sheet in the lower half**, side by side (D29), and an expanded flat window keeps the 560dp centred stack. The earlier "title, amount and slot in the upper half" schematic is not buildable. The route is posture-agnostic for these sheets (`anchorPoint: Offset(0, height)` always, max width 560), so a fold during use does not strand the sheet. The drag handle is 48dp and stays (X3). Tests run at the `TestWindows` sizes.

**Used keypad (section 9) is not a separate sheet.** It is one question inside the saving's own sheet (as FR-SE-1 *Amount*, AC-3 of *Rows*), because the sheet is already open.

## 2. Keypad behaviour

The keypad is the shared `Keypad` (`lib/core/widgets/keypad.dart`): `1-9`, then `00 · 0 · ⌫`, never reordered (D13). **There is no action cell in it** (X1): *Fix it* is a **full-width `SignalKey` under the keypad**, as *Next* is in the Add tray. Keys are **56dp** (48dp in a short window); the action key 56dp (48 short): re-measure it in the build (X2). Key labels stop growing at 1.5x text (O20, X44): at 2.0x the keypad is 4×56 + 24 = 248dp; check that a 48dp tight key does not grow at 1.5x (D13).

| Topic | Rule |
|---|---|
| Open | The amount is **empty**: nothing is prefilled, so the user reads their bank, not hisaab's figure (principle 87). The display reads ₹0 at the "empty" state |
| First key | Appends (there is nothing to replace). A leading `0` is ignored for display **except** that a pressed `0` makes the amount "typed 0", which is a valid answer (F3 "I have none left"). So the bloc holds `digits: String` ("" is empty, "0" is typed zero); the display shows ₹0 for both, and only "typed 0" enables the compare |
| Digits | `1-9`, `0`, `00` (on empty it gives "0"). Live Indian grouping. Tick haptic per key, as Add |
| 9-digit cap | A key that would make a 10th digit is refused (X14, O11): reject haptic, the amount shakes (`Shake`), **a 2dp ring is held on the amount until the next accepted key**, and a one-shot polite announcement "That's the most you can type." (a new ARB key). No visible words. `Shake` is skipped under reduced motion and haptics may be off, so the held ring and the spoken line are the signals that always work; a 150 ms flash is not used. The same change goes into the Add tray (P5, P6) |
| No paise | No decimal key. `T` is whole rupees |
| ⌫ | Tap removes the last digit (tick). Removing the last digit returns to **empty** (helper back, key off). Long-press clears (the existing `onClear`). The visible alternative to the long-press is repeated taps |
| Quick chips | **None.** +₹10/+₹50 add amounts; this is a total. A "same as hisaab" chip is rejected: it would show `H` before the user typed (anchoring) and make "That matches" a one-tap lie |
| hisaab's own figure | Hidden while empty. After the **first key** the slot shows it as the first words of line 1 ("hisaab thought ₹17,430."). It appears with the slot's 150ms crossfade (helper out, preview in), not a slide, and is stable from then on. If the user ⌫ back to empty, it hides again |
| Hardware keyboard | **Not mapped, here or now** (X45, O9). The Add tray maps none and a digit key does nothing today (`07` §8). If wanted later, one wrapper in `Keypad` serves every keypad page in a separate change. Escape and system back already go through `maybePop` |

## 3. The preview slot

The slot sits directly under the amount, as in the Add tray (FR-AD-1, FR-AD-3). **Fixed height by construction:** every state is a child of one `IndexedStack`, so the slot is as tall as the tallest state at the current text scale and never changes between states; only one child is visible and only that one is in semantics. No layout jump at any text scale, and no per-state height maths. The slot is `design-ui`'s to style (no red or green: direction is in words "less", "more").

**Structure:** line 1 anchors ("hisaab thought ₹17,430."), line 2 says the gap and its effect ("That's ₹4,200 less. Each day gets about ₹467 less."). This splits `01` §5's single sentence so that `H` is visible (X21: hearing line 1 is the only way to check `H`, principle 86). Either line may wrap. Copy is the deck's (`41-fix-my-number-copy-deck.md`): "about" only on the per-day figure; no idiom (D121).

### 3.1 States and what *Fix it* does

| # | State | Slot | *Fix it* (marigold on `ink`, full width under the keypad) |
|---|---|---|---|
| S0 | **Empty** (nothing typed) | Helper: "Bank and cash together. Leave out money from before this month." | Off |
| S0b | **Loading** `H` (typed before it arrived) | Helper stays; the preview appears when `H` lands | Off |
| S0c | **`H` failed to load** | "Couldn't check your number." with a 48dp text key *Try again* (a visible retry, not a gesture; the slot owns the full 48dp, K1) | Off |
| S1 | **Lower** (`T < H`, beyond 50 rule) | L1 anchor; L2 "That's ₹4,200 less. Each day gets about ₹467 less." (variants in the deck: short of what's still due, last day) | **On** |
| S2 | **Higher, small** (`gap` ≤ `I ÷ 10`) | L1 anchor; L2 "That's ₹1,000 more. Each day gets about ₹111 more." | **On** |
| S3 | **Higher, large** (`gap` > `I ÷ 10`) | L1 anchor; L2 "That's ₹30,000 more. One question first." (no per-day effect: the answer decides it) | **On.** Press opens the guard step (section 4); it posts nothing |
| S4 | **Equal** (`gap` under ₹1) | "That matches. Nothing to fix." | **Off** |
| S5 | **Close** (rounded `T`, within 50, F2) | "That's close enough. Nothing to fix." | **Off** |
| S6 | **Notice after a refused save** (F13) | "Things changed. Check the new amount." replaces L1 until the next key; the preview then follows the live ledger | On if a gap still exists |
| S7 | **Notice after *No*** | "Count only this month's money." over **cleared digits** (₹0) until the first key; focus goes to this notice, which is not also a live region (X11, `06` §2.1) | Off (nothing typed) |
| S8 | **Save failed** (F15) | "Couldn't save. Try again." until the next key | **On** again; digits kept |
| S9 | **Saving** | The current preview stays | Pressed fill, then disabled; **the label stays "Fix it"** (deck R12); TalkBack says "Saving" only if the write passes 1 s |

**Disabled when nothing would post:** yes (S0, S0b, S0c, S4, S5, S7, S9). A disabled key must not be silent. The slot already says why in S4 and S5; S0 has the helper; for TalkBack the disabled key carries a hint ("Type an amount first" or "Nothing to fix"; device-dependent, check D3). Disabled is shown by the `SignalKey` disabled treatment (hatch/outline and the words), never colour alone.

**Why *Fix it* stays enabled for large *higher* and the guard appears on press, not live:** swapping the keypad under the thumb while the user is still typing (a 6-digit total crosses the threshold mid-entry) is a hidden mode change that fast typists would trip over. The slot warns early (S3) so the user can correct digits first; the keypad changes only on a deliberate press.

### 3.2 Transitions

| From to | Motion |
|---|---|
| S0 to any preview (first digit) | 150ms crossfade of the slot children, helper out |
| Any preview to another class (S1 to S2, S2 to S4, and so on) | 150ms crossfade |
| Digit changes inside a state (numbers change only) | **Instant text swap**, no animation (per-digit fades flicker) |
| Back to S0 (⌫ to empty) | 150ms crossfade |
| *Fix it* label or enabled change | Fill/outline change, no movement; `design-motion` sets durations |

Reduced motion (X16, 05-F4): the crossfade is 150 ms in **both** modes, as `usual_slot.dart` does; opacity is allowed under reduced motion, anything that moves jumps. Under 100ms: every digit updates amount and slot in the same frame (the compare is a pure sum over a value the bloc holds; no await per digit).

## 4. The guard step (higher by more than `I ÷ 10`)

**Where:** a second step **in the same sheet**. The amount display and the slot stay; **the keypad area is replaced** by an answer panel, and **the sheet shortens** to fit it (X8, mockup 41 option B; the earlier "same height" idea left a 232dp hole under two keys). The resize uses `resize` + `easeOut`, and is instant under reduced motion (05 §2). The keypad's own keys never change meaning, so D13 holds.

```
 <  How much of this month's money is left?
          ₹ 47,430                              (read only, no keypad)
 hisaab thought ₹17,430.
 That's ₹30,000 more. Is all of it from this month?
 [      No, some is older       ]   56dp, full width, first
 [      Yes, add ₹30,000        ]   56dp, full width, second
```

| Item | Rule |
|---|---|
| Trigger | *Fix it* in S3 |
| Keys | Two **equal-weight** 56dp full-width keys stacked, same style, neither marigold (`design-ui` to style); `minHeight` 56dp, never `height` (S4). *No* first: it is the safe answer for a typed total, so it is first in reading and focus order |
| **Input lock (X7)** | Both guard keys ignore input for **about 300 ms after the swap** (the 150 ms crossfade runs inside it). The stack ends where *Fix it* was, so a quick second tap or a late finger lift would land on *Yes, add ₹30,000* and post a large *Got*; `droppable()` does not help (a different event). No visible mode. Check on a device (D1); revisit if the pre-release test (B6) shows mistakes |
| *Yes, add ₹30,000* | Posts the *Got* (section 5). Success path as below |
| *No, some is older* | Back to the keypad step with the digits **cleared** (X11): "some is older" means the typed total was wrong, so there is nothing to keep, and the hidden "next key replaces" mode disappears (the FR-AD-8 replace rule is not needed here). The slot shows S7 "Count only this month's money." over ₹0, and **focus goes to that notice** (a `Focus`-wrapped line, not also a live region) |
| Back, system back, Escape, the scrim | **A step back = *No*** (X9; verified in `material_ui` source: the scrim goes through `maybePop` and respects `PopScope`). `PopScope.canPop = (step is keypad) \|\| saving`; while saving, Back closes the sheet and the save still lands. A second Back (on the keypad step) closes it. **No predictive-back preview (X10):** `ModalBottomSheetRoute` has no back-gesture hook, so Back commits, then the 150 ms crossfade plays. Never flip `canPop` mid-gesture |
| Swipe down, drag handle | **Closes the whole sheet**, nothing posted; digits dropped (these call `onClosing` and bypass `PopScope`) |
| Gesture alternatives | Both answers are plain keys; nothing is gesture-only |
| Digits | Not editable in the guard step (no keypad). The amount well shows its read-only look, and TalkBack reads "47,430 rupees" |
| Focus (X17) | The question is a `Focus` + `Semantics` node and focus is requested in the frame the panel is built, so TalkBack does not lose its place when the pressed key disappears. If a device shows TalkBack does not follow, use a live region and focus *No*. **Device check D1 is mandatory before the build is called done** |
| Live change underneath | If `H` changes while the guard is open (midnight, a bill posts) the answer panel stays; the save re-checks the gap in its write (F13) and, if it differs, saves nothing, returns to the keypad step and shows S6 |
| Not live | The guard never appears while typing; only after *Fix it* |
| Mode | Visible (the keypad is gone, the question is on screen) and one Back leaves it |

Considered and rejected: the two answers in the keypad's bottom row (breaks D13 and cannot hold two 56dp keys); side-by-side guard keys (the stack is the thumb-zone layout, and the lock handles the tap-through); an `AlertDialog` (a second layer, banned feel: reversible over confirm); live swap (mode under the thumb).

## 5. Save

**Event:** `FixMyNumberSubmitted(typedRupees, expectedGap, confirmedLarge)`, on `droppable()` (BR-10, `.claude/rules/bloc.md`). The event carries the typed figure and what the user saw, **not** just the gap, so the write recomputes `H` and refuses a stale gap (F13). Double taps on *Fix it* or *Yes, add ₹30,000* produce one entry (F14); the key also goes to its disabled state on the first press. The `show` method copies `BillAmountSheet.show` (wait for a settled state, `BlocProvider.value`, close after), **not** `BillSheet.show`, so Back while writing keeps the Undo (P7).

| Step | What the user sees, hears, feels |
|---|---|
| 1. Press | Key pressed fill (under 100ms), no haptic on press. The key disables |
| 2. Write | Normally under 100ms: no spinner. The label stays "Fix it"; TalkBack says "Saving" only if the write passes 1 s (deck R12) |
| 3. Success | The sheet closes (spring close per `design-motion`). **After it has fully closed** Home reloads and its hero rolls to the new value (D91; `design-motion`: one roll, today's block and the hero reflow together, "calm, no praise"). **`Haptics.success()` fires at t = 0 with the roll** when Home is under the sheet, as SPEC FR-AD-5 pairs it with the visible change (X15); from the Settings door (no hero under it) it fires as the exit starts. The Settings door needs its own snackbar and Undo home (P4) |
| 4. Snackbar | Through the snackbar host: **"Fixed. Safe to spend today: ₹963."** (X23, deck R5; it repeats the hero's title, and ₹0 needs no softening) with *Undo*. 4s (O10), or until dismissed when TalkBack runs (D105). If Home cannot show it yet (loading or a failed reload), the Undo waits for Home's next good load (D127) |
| 5. Undo | Removes the entry; the number goes back; `Haptics.tick()`; polite announcement "Undone." |
| Back while writing | Closes the sheet; the save still ends with its Undo on the parent (FR-HO-8 AC-6) |
| Failure | The sheet stays, digits kept, S8 "Couldn't save. Try again."; `Haptics.reject()`; *Fix it* re-enabled. A failure after *Yes* returns to the keypad step (a second *Fix it* asks again; accepted, rare) |
| Refused as stale (F13) | Nothing saved; the preview refreshes; S6; `Haptics.reject()` |

Haptic vocabulary stays `tick`, `success`, `reject`, `threshold` through `Haptics` only; no new effect, and one per event.

## 6. Saffer table (the three micro-interactions)

| | Typing a figure | *Fix it* | Guard |
|---|---|---|---|
| Trigger | A keypad key (or ⌫) | Press of the action key | *Fix it* in S3 |
| Rules | Section 2 caps and zero rule; compare with `H` each key; pure | Section 5: re-check in the write, save once | Two answers; Back, scrim = *No*; 300 ms input lock |
| Feedback | Amount, slot text and *Fix it* state in the same frame; tick; reject, shake and held ring at the cap, with a spoken line; polite spoken summary after a 1.2 s pause under TalkBack (at once on a state-class change) | Pressed fill, close, hero roll, `success`, snackbar | Keypad swaps for the answers and the sheet shortens; focus moves to the question; no haptic on entry |
| Loops and modes | None; no repeat timers. Long-press ⌫ clears once | None | The guard is the only mode; visible; one Back leaves it; *No* clears the digits |

## 7. Component states

State is fill, outline, hatch and words, never colour alone, no red or green; marigold only on *Fix it* (act). "Hover" applies to a mouse or keyboard on large screens.

| Component | Rest | Pressed | Focused | Hovered | Selected | Disabled | Loading | Error |
|---|---|---|---|---|---|---|---|---|
| Digit, `00`, `0`, ⌫ keys (`KeypadKey`) | As the app's keypad | Pressed fill, tick | `FocusRing` | Hover fill | n/a | Never disabled (the cap refuses a digit with reject and shake) | n/a | n/a |
| Amount well | ₹0 or the typed figure | n/a | Not focusable; read by TalkBack | n/a | n/a | Read-only look in the guard step | n/a | Cap: shake plus a 2dp ring held until the next accepted key |
| *Fix it* (`SignalKey`, full width) | Marigold on `ink` with a 1.5dp edge, S1/S2/S3/S8 | Pressed fill | `FocusRing` | Hover fill | n/a | S0, S0b, S0c, S4, S5, S7, S9 (hatch/outline and hint) | S9: label unchanged; "Saving" spoken after 1s | Stays on; S8 line |
| Guard keys | Equal outlined keys, stacked, `minHeight` 56dp | Pressed fill | `FocusRing`; first focus on the question, then *No* | Hover fill | n/a | Ignore input for 300 ms after the swap; disabled while the save runs | "Saving" spoken only after 1s | Back to keypad step with S8 |
| *Try again* (S0c) | Text key 48dp | Pressed fill | `FocusRing` | Hover fill | n/a | n/a | Pressed, then helper | S0c line while it fails |
| Back (`HisaabBackButton`) | Top-left | Pressed fill | `FocusRing` | Hover fill | n/a | n/a | n/a | n/a |
| Slot | Helper or preview | n/a | Not focusable | n/a | n/a | n/a | S0b | S0c, S6, S8 |
| Snackbar *Undo* | Text action | Pressed fill | `FocusRing` | Hover fill | n/a | After it is used | n/a | n/a |

**Focus order** (keyboard, D-pad, TalkBack swipe): Back, title, amount, slot, keys `1` to `9`, `00`, `0`, ⌫, *Fix it*. Arrow keys move within the keypad grid. Guard step: Back, title, amount, slot (the question, focused first), *No*, *Yes*. After *No*, focus to the "Count only this month's money." notice. The sheet traps focus while open and returns it to the control that opened it (foot row, Settings row). **When the opener is the install line, which is gone once seen, or the missed-log line, focus goes to the node now in its place, the "Today" heading (X18, `06` T6), not Home's top.**

**TalkBack.**
- The title is a heading. The amount reads as "13,230 rupees" (spoken amounts as `.claude/rules/accessibility.md`); empty reads "No amount yet" and typed zero "0 rupees" (P8); it is **not** a live region, so digits are not announced one by one (the key you pressed is spoken by the key).
- The slot is one **polite live region**. **Under `accessibleNavigationOf` its label updates 1.2 s after the last key, or at once when the state class changes** (X13: a TalkBack user types a key every 0.6 to 1.5 s, so 400 ms queued a 5 s sentence after nearly every digit; 400 ms has no remaining use). The **live text is short** ("4,200 rupees less."); the full sentence ("hisaab thought 17,430 rupees. 4,200 rupees less. Each day gets about 467 rupees less.") is the slot's focusable text, read on demand. The visible text is excluded from semantics and a separate `Semantics(liveRegion: true)` carries the live text. Same rule for the *Used* slot.
- *Fix it*: "Fix it, button" plus the disabled hints in 3.1. TalkBack double-tap is the only activation needed; there are no gesture-only actions (WCAG 2.5.1). The long-press clear has taps on ⌫ as its alternative.
- Guard: focus moves to the question (read once), then *No*, *Yes* (X17; check D1).
- Snackbar: the existing host announces it and is the one announcer (the hero stays a plain merged node), and it holds until dismissed.
- All targets are at least 48dp (keys are 56dp, 48 when short; the guard keys 56dp); at 1.5x text key labels stop growing and the slot grows (via the `IndexedStack`), the title and slot scrolling above the pinned keypad, with the typed amount pinned.

## 8. Edge cases

| Case | Behaviour |
|---|---|
| Double tap on *Fix it* or *Yes* | One entry (`droppable()` plus the disabled key) |
| Fast entry, then *Fix it* inside the announcement window (1.2 s under TalkBack) | Compares what was typed at the press; the spoken sentence may lag, it is never wrong for the write because the write recomputes |
| Typed 0 versus empty | Different states (section 2); *Fix it* works for typed 0 (F3) |
| ⌫ to empty after a preview | Helper returns, key off, no leftover notice |
| `H` unchanged and digits `H` (F1) or within 50 (F2) | S4, S5; *Fix it* off |
| Rotation, fold, window resize | Digits, step (keypad or guard) and notice live in the bloc and survive; the sheet re-lays out live (the route is posture-agnostic, X46); the guard stays on the guard |
| Tabletop and two-pane | Section 1 (`07` §3 wins): tabletop is the whole sheet in the lower half, side by side; an expanded flat window keeps the 560dp centred stack; the guard answers replace the keypad |
| Midnight or a recurring post while open | Preview follows the live ledger; the save re-checks (F13, S6) |
| Android system back, Escape, scrim | Keypad step: closes, nothing saved. Guard: a step back to the keypad (= *No*, digits cleared). While writing: closes, the save still ends with Undo. Swipe down and the handle close the whole sheet. No predictive-back preview (X10) |
| Quick second tap on *Fix it* | Lands on a guard key during the first 300 ms: ignored (X7) |
| App backgrounded with digits | Digits kept for the process life; killed, dropped (nothing saved, like every sheet) |
| Gesture nav insets | The pinned controls add the bottom inset (`MediaQuery.paddingOf(context).bottom`, P3); the sheet runs edge-to-edge behind the bar |
| Reduced motion | Crossfade only (150 ms, opacity); the guard resize is instant; the held ring and the spoken line replace the shake; the hero reflow falls back per `design-motion` |
| TalkBack | Section 7; polite, debounced 1.2 s, short live text, no per-digit speech |
| 9-digit total with `H` huge | Compare is on `int` paise; no overflow; the cap is on digits |

Component tests to write with the build (one per state): empty, loading, load error, lower, higher small, higher large, equal, close, notice after *No* (digits cleared, focus on the notice), notice after a refused save, saving, failed save, cap refusal (held ring and spoken line), typed 0, ⌫ to empty, the guard's *No* and *Yes*, the 300 ms lock, Back and the scrim in the guard, swipe closing the sheet, double tap, TalkBack label after the 1.2 s debounce, reduced motion, and `TestWindows` sizes including a fold.

## 9. Used keypad (yearly costs)

Source: `docs/features/yearly-costs/01-ux-flow.md` §4.3 (S5, S5b, S5c). Same pattern as Fix my number; the differences are what the cap is and where it lives.

| Topic | Rule |
|---|---|
| Container | **Not its own sheet.** It is one question inside the saving's sheet (the *Amount* row pattern, FR-SE-1): Back returns to the slip, the scrim and swipe close the whole sheet. Opened from Home's due-soon row it closes back to Home |
| Keypad | The **pinned** shared `Keypad` **with `00`**, keys 56dp (48 when short), and a **full-width *Save*** under it (X1, X5; the earlier wireframe's bottom-right *Save* cell with no `00` is dropped). The amount starts **empty** (₹0 means "typed nothing"; ₹0 is refused, *Save* off). No quick chips; the one shortcut is *All of it*. The typed amount is pinned above the keypad; the title and slot scroll |
| *All of it* | A 48dp chip right of the amount (below it at large text): rests `hairline`, fills `ink2` while the amount equals the balance (D89), `selected` in semantics. It **prefills** the whole balance; the first key afterwards **replaces** it (FR-AD-8), so a partial amount is one tap plus digits. **Tapping it again clears the amount (X19)**: a filter chip toggles, and every `onTap` must do something. It is deselected by any digit or ⌫ that changes the amount |
| Cap | A digit that would pass the balance is **refused** like the 9-digit cap (X14): reject haptic, the amount shakes, a 2dp ring is **held** until the next valid key, plus a line because the cause is not obvious: "That's all you have set aside. Add the rest as a spend." (the deck's string, X26). No red. At compact heights the refusal replaces both slot lines (`06` §3.2) |
| Slot (fixed height, `IndexedStack` as section 3) | L1 "₹4,000 is set aside." becomes "₹{left} will still be set aside." as digits are typed ("Nothing will be set aside." at the balance); L2 always "Your daily number doesn't change."; the refusal line replaces L1 until the next valid key. Per-digit text swaps instantly; changes of state crossfade 150ms. "So far" is dropped (X26) |
| Action key | *Save*, marigold on `ink`, full width under the keypad. Off when empty or ₹0 (hint "Type an amount first") and in S5c "Nothing is set aside to use." |
| Save | `droppable()`; on success `Haptics.success()` and the sheet closes to the list (nothing on Home moves: no hero reflow); snackbar "Insurance: ₹4,000 used" with *Undo* (4s, D105; name first, D132); Undo `tick`. Failure keeps the keypad: "Couldn't save. Try again." with `reject`. Back while writing closes and the Undo still shows |
| TalkBack | The slot is the same polite live region (1.2 s debounce under TalkBack, short live text, X13); the refusal is read once. *All of it* reads "All of it, button, selected" when it applies |
| States | Same matrix as section 7 with *Save* for *Fix it*, plus the *All of it* chip: rest, pressed, focused, hovered, selected (amount equals balance; tap clears), disabled (balance ₹0) |
| *Used* on which savings | **Every saving**, shown only when something is set aside (O6); the sheet hint "Paid the cost from this? Tap Used some of it." only on the three yearly chips |
| Over the balance | Refused (O7); the rest is added as a normal spend. A saving deleted with something set aside: no extra step, the delete's Undo says what stays (O8) |

Consistency kept between the two: empty start; shared `Keypad` (with `00`) and no quick chips; first key replaces a prefill; refusal by reject plus shake plus held ring with a reason line; fixed-height slot; marigold full-width action key under the keypad; `droppable()` save; `success` then Undo snackbar; same failure line; same Back rules. Different on purpose: the cap source (balance versus 9 digits), no compare and no guard, and no hero reflow.

## 10. Doc edits needed (listed, not written)

| Doc | Change |
|---|---|
| UI_DESIGN §5 | The Fix my number sheet: slot states S0 to S9, the guard step, the sheet in the bill-sheet route with pinned controls; the Used keypad question |
| UI_DESIGN §6 motion | Slot crossfade (150ms) only on state-class change, instant text on digit change; guard swap and shorter sheet (instant under reduced motion); hero reflow after close (to `design-motion`) |
| UI_DESIGN §7 haptics | `success` on a fix and on *Used*; `reject` at the cap, on a refused or failed save; `tick` on keys and on Undo; none on entering the guard |
| UI_DESIGN §9 accessibility | Debounced polite live region (1.2 s under TalkBack, short live text) for a preview slot; spoken amounts; key-label clamp at 1.5x as a deliberate WCAG 1.4.4 exception; held ring plus a spoken line at the cap |
| UI_DESIGN §10, §13 | Predictive-back sentence is about pages only (D10); sheets sit in one sub-screen, controls pinned, bottom inset |
| SPEC | New FR for Fix my number with ACs per state (as listed in `02` §6), and ACs for the *Used* keypad in FR-SE-1 |
| DECISIONS | Container: sheet in the bill-sheet route with pinned controls. Guard on press, not live, replaces the keypad in place and shortens the sheet; stacked keys with a 300 ms lock; scrim and system back = *No*. No quick chips on a "total" keypad. Digits cleared after *No*. Full-width action key, 56dp keys |

## 11. Open questions (all answered by 08 §8 and §1)

1. **`H` as line 1** ("hisaab thought ₹17,430."): yes (X21, deck R3).
2. **After *No*:** the digits are cleared; nothing to replace or append (X11).
3. **Guard on the press of *Fix it*, not live**, and *Fix it* enabled in S3: kept. Same taps as `01` (digits, *Fix it*, *Yes*).
4. **"Typed 0" as a valid state:** kept; a small keypad-state difference for the build (P8).
5. **`H` fails to load** (S0c, *Try again*): kept as drawn.
6. **Hardware keyboard:** left out of these features (X45, O9).
7. **Guard keys' order and style:** *No* first, stacked, neither filled by marigold; `design-ui` to style; focus starts on the question (X17).
8. **Tabletop and two-pane arrangement:** `07` §3 wins (X6).
9. **Soft copy for hero ₹0:** none; the snackbar states "Safe to spend today: ₹0." (X23).
10. **Used keypad:** tapping *All of it* again clears the amount (X19).
11. Owner questions from `02` §7: answered (O1 to O4, O5).

## Source scope
`docs/features/fix-my-number/01-ux-flow.md`, `02-accounting-and-edge-cases.md`, `docs/features/yearly-costs/01-ux-flow.md`, `docs/design-research/case-studies/33-product-gap-analysis.md` (Owner answers), SPEC FR-AD-1 to FR-AD-3, FR-AD-8, FR-HO-8, FR-SE-1 (*Money coming in* AC-3 and AC-4, *Put in extra* AC-1 to AC-4), BR-10, `lib/core/design/haptics.dart` (`tick`, `success`, `reject`, `threshold`), the `lib/core/widgets/` file list and `keypad.dart` header. `signal_key.dart`, `shake.dart`, the snackbar host and `hisaab_motion.dart` were not read; their states and reduced-motion branches are to be verified in the build. Case study 34 was not re-read for this pass (its decisions arrive via `01` and `02`).
