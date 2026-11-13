# Accessibility review: Fix my number, yearly costs (*Used*) and the missed-log line

> **Status: proposed (2026-11-13).** A review of three unapproved designs against WCAG 2.2 AA and the house conventions. Nothing here is in SPEC, PLAN, UI_DESIGN, DECISIONS or the ARB, and no code was changed. Every "Fix" below is a proposal for the owning agent (`design-ui`, `design-interaction`, `design-content`, `design-motion`) to accept or reject. Longer than ~150 lines on purpose: the owner asked for all three features in one review; split by feature when approved.
>
> **Reviewed:** `01` to `05` of this folder, `docs/features/yearly-costs/01-ux-flow.md`, `docs/features/habits/08-missed-log-line.md`, copy deck `docs/design/mockups/41-fix-my-number-copy-deck.md`, mockups 41, 42, 43 (including their "problems found"), SPEC NFR-4, E12, E13, FR-HO-7, FR-WG-8, UI_DESIGN §9 and §13, D99, D105, `lib/core/design/hisaab_colors.dart`, `test/core/design/contrast_pairs_test.dart`, and (for facts the docs assume) `lib/core/widgets/shake.dart`, `keypad.dart`, `keypad_key.dart`, `lib/ledger/presentation/widgets/entry_row.dart`. Contrast was **computed by script** (WCAG 2.x relative luminance, same formula as the existing test), not estimated.

## 0. Findings at a glance

Severity: **blocker** (a TalkBack or large-text user cannot complete the task), **major** (a WCAG AA criterion or a house rule is missed, or a task is made hard), **minor** (polish, headroom, or a decision to record).

| ID | Where | SC | Sev | Finding | Fix (proposed) |
|---|---|---|---|---|---|
| T1 | Guard step | 2.4.3, 4.1.3 | **blocker** | The key pressed (*Fix it*) vanishes when the keypad is replaced, so TalkBack focus is lost, and "focus moves to the question" targets a static `Text` that cannot take focus | Wrap the question in a `Focus` + `Semantics` node (or make the answer panel the named scope) and verify on a device; fall back to a live region (section 2.1) |
| S1 | Fix sheet, 320x568 at 1.5x | 1.4.4, 1.4.10 | **blocker** | The typed amount scrolls out of view, so the user types blind | Pin the amount, end-anchor the scrolling slot, full-height sheet when tight (section 3.1) |
| S2 | *Used* sheet, 320x568 at 1.5x | 1.4.4 | **blocker** | Same defect; the refusal reason is also cut by the keypad | Same pattern plus the chip drops below the amount; the refusal replaces both slot lines (section 3.2) |
| T2 | Slot live region | 4.1.3 | major | A 400 ms debounce is shorter than a TalkBack user's key cadence (about 0.6 to 1.5 s), so a 3-clause sentence is queued after nearly every digit and cut by the next key | Longer debounce and a short sentence under `accessibleNavigation` (2.2) |
| T3 | Amount node | 1.3.1, 4.1.2 | major | "Empty" and "typed 0" are different states but both speak as 0; the "next key replaces the digits" mode after *No* is silent | Different spoken states; or remove the mode (C1) |
| T4 | 9-digit cap | 3.3.1 | major | Refusal is a haptic plus a shake, with no words. Under reduced motion `Shake` does nothing, and haptics may be off | Hold the ring until the next key and announce a short line (2.4, 6) |
| T5 | *Not logged* rows, Spends line | 1.3.1 | major | Direction is carried by one word, spoken as a list item ("Not logged, spent, 4,200 rupees"); the Spends part "Not logged 4,200 rupees" has no direction at all | Speak a sentence with the verb before the amount (2.6) |
| T6 | Missed-log and install lines | 2.4.3 | major | Focus returns "to where it was", but the opener (the line) is removed after Back | Return focus to the node that now sits where the line was (2.7) |
| C1 | After *No*: kept digits on a `sunk` highlight | 1.4.11 | major | `sunk` on `display` is 1.30:1 (light) and 1.17:1 (dark); the highlight is the only cue for a hidden "next key replaces" mode | Clear the digits after *No* (preferred), or style as selected (3.1) |
| K1 | *Try again* (S0c) | 2.5.8, house 48dp | major | A 48dp key overlapping the card padding by 8dp: Flutter does not hit-test outside a parent's bounds, so the real target is about 40dp | Make the slot own the full 48dp (4.1) |
| K2 | *Not logged* and *Used* rows | 2.5.1 | major | Swipe-to-delete is the only delete; needs the existing custom action to be kept | Reuse `entry_row.dart`'s `customSemanticsActions`; add a test (4.4) |
| G1 | Fix sheet | 3.3.2 | major | The only instruction that prevents the harmful error ("leave out money from before this month") is the helper, and it is replaced as soon as a digit is typed (and the title scrolls away at 1.5x) | Keep the helper visible under the title when there is room (5) |
| G2 | Vocabulary | cognitive | major | Seven new or near terms across three features (*Fix my number*, *Not logged*, *set aside*, *put in*, *Saved*, *Used some of it*, *Used from savings*) and four parts in the Spends line | At most two new terms per screen; keep *Used* out of the Spends line (5) |
| S3 | Keypad key labels | 1.4.4 | major | Keys use `minHeight` with 27sp digits, so at 2.0x the 4 rows grow to about 284dp and push the action key out | Clamp key labels at 1.5x (owner decision) or test at 2.0x on the tight layout (3.3) |
| S4 | Guard keys | 1.4.4 | major | Drawn at a fixed 56dp; `Yes, add ₹99,99,99,999` wraps at 2.0x | `minHeight` 56dp, never `height` |
| T7 | Hero plus snackbar | 4.1.3 | minor | Two announcements of the same number if the hero is also a live region | One of them speaks |
| T8 | Disabled *Fix it*, "Saving" | 4.1.2 | minor | Hint on a disabled key is device-dependent; "Saving" is announced even for a 80 ms write | Verify on a device; announce only after 1 s |
| T9 | *All of it* chip | 4.1.2 | minor | Tapping the selected chip does nothing ("every onTap must do something") | Tapping clears the amount, or announces "All of it, already" |
| C2 | Missed-log hover outline | 1.4.11 (not required, claim "distinct") | minor | `hairline` 1dp on `sunk` is 1.18:1 (light) and 1.17:1 (dark): invisible | `ink2` 1dp (5.55 and 5.48) |
| C3 | `ink2` on `hairline` | 1.4.3 | minor | 4.71 and 4.68: passes with 0.2 to spare; no AAA | No new text may sit on a fill farther from the page than `hairline`; keep the test pairs |
| C4 | Snackbar Undo focus | 1.4.11 | minor | No test pair for the ring on `inverse`; works only through the gap band (11.60 and 16.55) | Add the pair (7) |
| C5 | High contrast | 1.4.6 (AAA) | minor | No high-contrast palette exists; new screens use the standard tokens | List in 1.3 for the later pass |
| K3 | Long-press ⌫ | 2.1.1 | minor | No Enter-hold path for D-pad; repeated Backspace is the alternative (nine at most) | Accept; keep the `longPress` semantics action |
| K4 | Hardware keyboard | 2.1.1 | minor | 04 open question 6 leaves digits, Enter, Esc undecided; tablets and foldables are in scope | Decide now: digits type, Backspace, Enter = action key, Esc = Back (in the guard, Esc = *No*) |
| K5 | Undo 4 s | 2.2.1 | minor | Switch Access users are not covered by the TalkBack extension of the timer | Keep; the fallback is Every entry swipe/action delete (state it in SPEC) |
| S5 | Used slip step | 1.4.4 | minor | A pinned *Delete saving* shrinks the scroll window and is always under the thumb | Delete scrolls with the body at compact heights |
| S6 | Spends parts | 1.4.4 | minor | A trailing "·" pokes about 2dp past padding at 1.5x (mockup 42, section 6) | Use mockup option B (no dots) |
| G3 | The question | cognitive | minor | The page asks for a sum (bank plus cash, minus old money) | Accepted risk; hallway test with a first-time smartphone user (5) |
| M1 | Guard height | 2.3.3 (AAA), E13 | minor | Mockup option B shortens the sheet (a resize); 05 §2 says "no resize" | Define the reduced-motion form as instant (6) |

Blocking: **T1, S1, S2.** Everything else can ship with the build if scheduled.

## 1. Contrast (measured)

Method: sRGB relative luminance per WCAG 2.2; tokens from `lib/core/design/hisaab_colors.dart`. Script: `C:/Users/tejas/AppData/Local/Temp/claude/607a9a694070e6fd/c1775108-ae40-4fff-98c8-fbe515ef4dbb/scratchpad/contrast.py` (scratch, not committed). Floors: text 4.5:1 (1.4.3), UI parts and graphics 3:1 (1.4.11). "Text" rows also say whether they would pass 7:1 (AAA, relevant to bright outdoor light and to a future high-contrast palette).

### 1.1 Text pairs

| Pair (where) | Light | Dark | AA 4.5 | 7:1 |
|---|---|---|---|---|
| `ink2` on `hairline` (pressed row or key, chip on a card, the hatch stripe worst case) | **4.71** | **4.68** | pass, thinnest margin | no |
| `ink2` on `sunk` (disabled key label, missed-log line 2, read-only amount) | 5.55 | 5.48 | pass | no |
| `ink2` on `surface` and `display` (slot line 1, row second lines, hero secondary) | 7.20 | 6.42 | pass | light yes, dark no |
| `ink2` on `bg` (foot row, helper, Spends line) | 6.23 | 7.31 | pass | light no, dark yes |
| `ink2` on `control` | 7.20 | 4.68 | pass | no (dark) |
| `ink` on `sunk` (digit keys, guard keys, missed-log line 1) | 13.84 | 12.41 | pass | yes |
| `ink` on `hairline` (*All of it* at rest) | 11.75 | 10.59 | pass | yes |
| `surface` on `ink2` (*All of it* selected, mockup 42) | 7.20 | 6.42 | pass | light yes |
| `onSignal` on `signal` (*Fix it*, *Save*) | 9.90 | 9.90 | pass | yes |
| `bg` on `inverse` (snackbar and Undo) | 11.60 | 16.55 | pass | yes |
| `ink` on `sunk` (typed amount on the kept-digit highlight) | 13.84 | 12.41 | pass | yes |

All text pairs the mockups use pass. The mockups' hand figures (6.2, 7.2, 7.3, 6.4) match; the "5.4:1" for the disabled label is slightly low (measured 5.55 and 5.48). **The disabled key with hatch:** the label is `ink2` on `sunk` (5.55 and 5.48), and on a `hairline` hatch stripe (1dp in 7) still 4.71 and 4.68, so a label crossing a stripe passes. Disabled controls are exempt from 1.4.3 anyway; the point is that none of this is relied on. The disabled state is carried by the words in the slot ("Nothing to fix.", "Type an amount first.") and by the semantics hint.

### 1.2 Non-text pairs

| Pair (where) | Light | Dark | 3:1 | Verdict |
|---|---|---|---|---|
| `displayInk` on `display`: the outlined *Used some of it* ring and the 2dp refusal ring | 17.97 | 14.54 | pass | Pass. The ring is strong; the problem with it is how long it shows (T4, M1) |
| `ink2` on `display` (guard key focus ring in mockup 41) | 7.20 | 6.42 | pass | Pass |
| `sunk` on `display` (kept-digit highlight, the only cue) | **1.30** | **1.17** | fail | **Fail (C1)** |
| `ink2` fill vs `hairline` fill (*All of it* selected vs rest) | 4.71 | 4.68 | pass | Pass, and a dot plus `selected` semantics also carry it |
| `sunk` on `bg` (digit key, guard key boundary) | 1.12 | 1.33 | fail | Inherited from the shipped keypad; the label identifies the control, so 1.4.11 does not need the boundary. No change |
| `hairline` 1.5dp disabled outline on `bg` | 1.32 | 1.56 | fail | Disabled is exempt; words carry the state |
| `hairline` on `display` (*All of it* chip edge) | 1.53 | 1.37 | fail | Label identifies it; no change. The fill step in the selected state passes |
| `hairline` 1dp hover outline on `sunk` (missed-log line) | **1.18** | **1.17** | fail | Invisible (C2): `ink2` would be 5.55 and 5.48 |
| `signal` on `bg` | 1.57 | 10.24 | fail (light) | Never bare in light: the key carries a 1.5dp `displayEdge` (`ink` on `signal` 9.90, `ink` on `bg` 15.54). Existing tests cover it |
| `signal` on `sunk` / `display` | 1.40 / 1.81 | 7.68 / 8.99 | fail (light) | Same rule; the key's edge |
| `focus` on `sunk` / `hairline` / `signal` | 13.84 / 11.75 / 9.90 | 12.41 / 10.59 / **1.62** | pass | Dark ring beside marigold fails, covered by the gap (`focusGap` on `signal` 10.24, already tested) |
| `focusGap` on `inverse` (Undo's focus band) | 11.60 | 16.55 | pass | Works only through the gap: `focus` on `inverse` is 1.34 and 1.00. **No test pair exists (C4)** |

### 1.3 High contrast

The app has no high-contrast palette: `MediaQuery.highContrastOf` is read only in `top_bar_scroll_view.dart` to drop the list fade. The new screens therefore look and measure the same in high contrast as in 1.1 and 1.2. If a palette is built, the pairs that would need raising to meet a 7:1 text floor are the `ink2` ones: on `bg` (light 6.23), on `sunk` (5.55 and 5.48), on `hairline` (4.71 and 4.68), and on `surface`/`display`/`control` in dark (6.42, 4.68). The existing test already says a future theme "raises the floors and reuses `_pairs`"; section 7 adds the new pairs to that list so they come along.

### 1.4 Colour is never the only signal (1.4.1)

Checked each new state: *less/more*, *Spot on* replacement ("That matches"), *Close enough*, the guard, notices, *Not logged · Spent/Got*, *Used from savings*, the disabled key (hatch plus words plus hint), *All of it* selected (fill, dot, `selected`). All have words. **Two do not:** the 9-digit cap (a shake and a haptic, no words: T4) and the kept-digit highlight (C1).

### 1.5 Findings

- **C1 (major, 1.4.11).** After *No*, "digits kept and shown on a `sunk` highlight" tells sighted users the next key replaces them; the highlight is 1.30:1 (light) and 1.17:1 (dark) on the card, so it fails as the sole cue, and it is invisible to TalkBack. **Fix (proposed), preferred:** clear the digits after *No* (04 §4 and open question 2 change). A "No, some is older" answer means the typed figure was a wrong total, so keeping it has no use, and clearing removes the hidden mode for everyone (the retype rule of FR-AD-8 needs no new cue; "nine backspaces" is moot). The notice "Count only this month's money." then sits over an empty ₹0. **Alternative:** keep digits and draw the highlight as the *All of it* selected style (`ink2` fill, `surface` text: 7.20 and 6.42, and `hairline` to `ink2` fill step 4.71 and 4.68), plus a spoken hint (T3). Either way the existing 04 §8 test list gains the case.
- **C2 (minor).** Replace the missed-log line's hover outline `hairline` with `ink2` 1dp. Hover is not a WCAG requirement, but the doc claims it is "distinct from pressed" and today it is not visible.
- **C3 (minor).** `ink2` on `hairline` has 0.18 to 0.21 of headroom. Pressed rows (13sp second lines) and chips on cards live there. No change; the rule to record: no text token other than `ink` may sit on a fill farther from the page than `hairline`, and `ink2` must not be used for 13sp text on any new fill.
- **C4 (minor).** Add `focusGap` on `inverse` as a `nonText` pair (section 7).
- **C5 (minor).** High contrast: see 1.3.

## 2. TalkBack

### 2.1 Fix my number sheet: order, nodes, and the guard

Order proposed (matches visual order, 1.3.2 and 2.4.3): sheet name, Back, heading, amount, slot, keys 1 to 9, 00, 0, ⌫, *Fix it*. This agrees with 04 §7. Notes:

- **Sheet name (T10, minor).** Give the sheet route `namesRoute`/`scopesRoute` semantics with the question as its label, so TalkBack announces it once on open. The in-flow heading stays (for heading navigation), but the open announcement must not read the same sentence twice.
- **Amount.** One node: "13,230 rupees", not a live region (agreed with 04). See T3.
- **Slot.** One node per state in the `IndexedStack`, only the visible one in semantics (agreed). Merge the two lines with `MergeSemantics` so a swipe reads one sentence: "hisaab thought 17,430 rupees. 4,200 rupees less. Each day gets about 467 rupees less." The visible text must be `ExcludeSemantics` and a separate `Semantics(liveRegion: true, label: spoken)` carry the delayed text, or the debounce (T2) cannot differ from the visible update.
- **Keys.** Digits are real buttons labelled with the digit (shipped). ⌫ keeps "Delete last digit. Long-press to clear" and the `longPress` action (shipped in `keypad.dart`).

**T1 (blocker, 2.4.3, 4.1.3): the guard.** Pressing *Fix it* in S3 removes the keypad and the key under TalkBack focus. 04 §4 says "focus moves to the question (read once), then *No*, *Yes*", but the question is plain text and `FocusNode.requestFocus` needs a focusable node; on Android Flutter's input focus does not always carry TalkBack's accessibility focus. If this is not solved, the user loses their place, hears the sheet from the top, and the only thing that changed is silent. **Fix (proposed):**
1. Wrap the guard question in `Focus` (`skipTraversal: false`) plus `Semantics(label:, focusable: true)` so `requestFocus` can land on it; on the same frame the answer panel is built, request it.
2. If a device test shows TalkBack does not follow, make the question a `liveRegion` instead and request focus on *No*. Then the order is: question announced, then "No, some is older, button". Accept that a flush may cut the announcement and re-test.
3. Either way, test on a device (section 8): swipe order, no lost focus, the question audible once.

**Notice after *No* (S7).** If the digits are cleared (C1 preferred), put accessibility focus on the notice node (a `Focus`-wrapped line) and do **not** also make it a live region, so it is read once by focus, not twice. If digits are kept, 04 sends focus to ⌫, which speaks a different sentence while the live notice is queued; the user hears the key and misses the reason. Prefer focus on the notice.

**T3 (major).** (a) 04 §2 makes "empty" and "typed 0" different, but both show ₹0. Speak empty as "No amount yet" and typed zero as "0 rupees", so F3 ("I have none left") is audible and the disabled *Fix it* hint makes sense. (b) If the replace mode stays (C1 alternative), the amount node carries `hint: "Next digit starts again"`.

**T2 (major).** Reading the existing code: `put_in_sheet.dart`, `bill_summary.dart` and `income_effect.dart` already use an undebounced `liveRegion` for their live lines, so TalkBack users already hear a line per change there. A 400 ms debounce is better but still shorter than a TalkBack user's cadence (explore by touch, lift, move to the next key: about 0.6 to 1.5 s), so the three-clause sentence (about 5 s of speech) is queued after almost every digit and is cut by the next key's own speech. **Fix (proposed):**
- Under `MediaQuery.accessibleNavigationOf(context)`, debounce the live label to 1.2 s after the last key, or until the state class changes (at once), as 04 already says for class changes.
- Make the **live** text short: the gap and the direction only ("4,200 rupees less."). The full sentence (with "hisaab thought") is the slot's focusable text, read on demand.
- Do not use `SemanticsService.announce` for this (the existing hosts use `liveRegion`; the announce API is being replaced on newer Flutter, check the pinned SDK before using it).
- The same rule applies to the *Used* slot ("will still be set aside").

**T4 (major, 3.3.1): the 9-digit cap.** FR-AD-2 and 04 §2 refuse the tenth digit with a haptic and a shake, "no words". Under reduced motion `Shake` skips itself (`shake.dart:10` and line 33), and the reject haptic is silent if the user turned touch feedback off. A blind user presses a key, hears the digit name, and nothing else. The *Used* cap has a line (`savingUsedCap`); the 9-digit cap has none. **Fix (proposed):** keep "no words" visually (calm), but (1) hold the 2dp `displayInk` ring (17.97 and 14.54) on the amount until the next accepted key, not a 150 ms flash, and (2) give the amount node a one-shot polite announcement "That's the most you can type." (a new key, `design-content`). This also closes the same gap in the shipped Add tray (pre-existing; report it, don't fix it in this change set).

### 2.2 Snackbar

"Fixed. Safe to spend today: 963 rupees." through `HisaabSnackbarHost` (a live region, held until dismissed under TalkBack, D105): good. Two points:
- **T7 (minor).** If the hero is also a live region, closing the sheet from the foot row, install line or *Used* announces the hero change and the snackbar, about 10 s of speech. The foot row is below the hero, so the hero is usually off screen and out of the semantics tree; but it is on screen in a short list or a tablet pane. **Fix:** the hero stays a plain merged node (FR-HO-7); the snackbar is the one announcer.
- "Undone." after Undo is a polite announcement (good); focus stays on the page, not on the removed snackbar.

### 2.3 Rows: direction by ear (T5)

- **`notLoggedRowSpoken` = "Not logged, spent, 4,200 rupees" / "Not logged, got, 1,000 rupees".** The one word that carries direction is a comma-separated item between a label and a number, so the ear hears a list ("Not logged / spent / 4,200"), and "got" at the start of a clause is easy to lose. **Fix:** a sentence with the verb before the amount: "Not logged. Spent 4,200 rupees." and "Not logged. Got 1,000 rupees." This is the same words, so no new ARB shape, only a different ICU template. Merge the second line ("Added when you fixed your number.") into the same node in Every entry, so one swipe reads it.
- **`entryUsedSpoken` = "Insurance, used from savings, 4,000 rupees":** acceptable; keep the saving name first. Same sentence form for consistency: "Insurance. Used from savings 4,000 rupees."
- **Spends line.** "Spent 27,570 rupees. Saved 1,000 rupees. Used from savings 12,000 rupees. Not logged 4,200 rupees." The last part has no direction and the ear cannot tell whether the 4,200 is inside the 27,570. **Fix:** "Not logged, spent 4,200 rupees." (the part is the Spent side only, 03 §4.3). Mark the `·` separators `ExcludeSemantics`.
- Row labels in a list must be unique (accessibility rules): each row keeps its time or position in the existing row label, as shipped rows do.

### 2.4 *Used* keypad and its refusal

- Slot rules as 2.1. The refusal "That's all you have set aside. Add the rest as a spend." is read once: it is an immediate state-class change, so it is not debounced (04 §3.2 already says so). The ring (2dp, 17.97 and 14.54) is held until the next valid key (T4 fix).
- *All of it*: `Semantics(button: true, selected: <amount == balance>, label: "All of it")`, spoken "All of it, button, selected" (the deck says "chip"; Flutter has no chip role, so "button, selected" is what TalkBack says).
- **T9 (minor).** Tapping the selected chip "changes nothing" (04 open question 10): a silent no-op. **Fix:** a tap on the selected chip clears the amount (a filter chip toggles), or at least announces "All of it already."

### 2.5 *Fix it* and *Save* (T8, minor)

Disabled: `Semantics(enabled: false, hint: ...)`. TalkBack reads "Fix it, disabled, button" and normally the hint, but this differs by Android version; **verify on the moto g45**. The slot's words ("Nothing to fix.") are the dependable cue and come earlier in the order. "Saving" (`fixSavingSpoken`) should be announced only if the write passes 1 s, not on every press (a 80 ms write that closes the sheet would speak "Saving" over the focus-return speech).

### 2.6 Missed-log line (T6, major) and install line

- One merged node, `button`, "Spent on Food today? Usually around 1 pm. Opens the keypad." Not a live region, no announcement on appearing (agreed, 08 §5). It sits in the first frame only, so TalkBack users find it in order after the hero and cards.
- **T6:** 08 §5 says focus returns to where it was and "the line's leaving does not take it", but after *Back* without saving, the line **is** the control that opened the tray and it collapses. Focus on a removed node falls to the top of the page. **Fix:** when the line leaves, request focus on the node that now occupies its place (the "Today" heading), and say so in the tray-close behaviour. The install line (04 §7: "then to Home's top") should use the same rule for consistency.
- In the tray, the pill reads "Add Food, 55 rupees, your usual" (FR-AD-10 AC-5): fine; keep it after the amount and before the keys.

## 3. Text scaling

Facts used: the mockup's budget for 320x568 at 1.5x (status 28, keypad 4x48 + 3x8 = 216, action 48 + 16, bottom 20, handle about 20: about 350dp fixed, about 170dp left for title, amount and slot, which need about 370dp). Slot lines at 1.5x are about 30dp each (15sp, 1.333), so a 5-line slot is about 150dp. At 2.0x each line is about 40dp. Amount type scales to 1.25x (60sp), so the amount block is about 70dp. These are the mockup's own numbers; the arithmetic below is mine and **must be confirmed by the layout tests in section 7**.

### 3.1 Fix my number: the layout (S1, S3, proposed)

Trigger: not a text-scale check alone; use the measured available height (`context.layout` height class, or a `LayoutBuilder` on the sheet body) so a 1.2x user on a 568dp window gets it too.

```
 [Back]  ₹ 13,230              <- pinned header: Back well and the amount, one row, never scrolls
 -------------------------------
 heading (the question)         <- scrolling region, end-anchored:
 hisaab thought ₹17,430.           line 2 stays in view, line 1 and the heading
 That's ₹4,200 less. Each day...   scroll up and are reachable by scroll or TalkBack
 -------------------------------
 [1][2][3] ... [<][0][  Fix it  ]   <- fixed (48dp keys when tight)
```

- **Pinned header (S1 fix).** Back and the typed amount in one row, outside the scroll. The user always sees what they type. This is the mockup's own recommendation ("pin the amount"); it is correct.
- **End-anchored slot.** The scroll region starts scrolled to its end after the first digit (so the gap line, the part that decides, is visible); a 150 ms animated jump normally, instant under reduced motion (M1). The slot stays one semantics node; TalkBack reads the whole of it regardless of scroll, and the region exposes a scroll action.
- **Sheet fills the height** when tight (drop the handle row and the top gap, the mockup's `sheet.fill`).
- **Arithmetic at 320x568 at 1.5x:** 28 (status) + 72 (pinned row) + 8 + [region] + 12 + 216 + 12 + 48 + 16 = 412 + region, so **the region has about 156dp**, which holds the whole 150dp slot; the heading scrolls out of view above it. At 2.0x the slot is about 280dp and scrolls inside the same 156dp window (about 4 lines in view, end-anchored). Nothing is removed; content is reachable by scroll and by TalkBack (1.4.4 "no loss of content").
- **Reading order unchanged**: Back, amount, heading, slot, keys. The heading is read by the sheet name on open (T10), so having the amount before it in the tree does not hide the question. If the team prefers the heading first, give it a lower sort key.
- **Do not** cut the slot copy to three lines (mockup problem 8): the copy deck's longest lines cannot.
- The S0 helper (3 lines at 1.5x) stays visible (G1); with the pinned header it sits in the same scrolling region.

### 3.2 *Used* sheet (S2, proposed)

The mockup (42, problem 1) shows about 534dp needed at 1x, so the sheet already has no spare room at 320x568 and does not fit at 1.5x.

- Same pattern as 3.1: pinned header = Back, amount, and (large text) the *All of it* chip **below** the amount as a full 48dp row (about 140dp wide at 1.5x, so it cannot sit beside a 6-digit amount). Header about 128dp.
- Scrolling region = heading and slot. Region height at 320x568 at 1.5x: 568 - 28 - 128 - 8 - 12 - 216 - 12 - 48 - 16 = **about 100dp**. The slot is 4 or 5 lines (L1 `savingUsedLeft` 2 lines, L2 `savingUsedSame` 2 lines, 120dp; the refusal is 3 lines + 2 = 150dp). So the region cannot show both.
- **Refusal at compact and large text:** the refusal line replaces L1 **and** L2 in the visible slot (3 lines = 90dp, fits the 100dp), and L2 returns on the next valid key. TalkBack reads the refusal once either way. This is a deviation from "L2 always" (04 §9), needed only when there is no room; record it.
- Keep the shared keypad with 00 and a **wide** *Save* (what mockup 42 drew). 04's wireframe has *Save* in the keypad's bottom-right cell with no `00` key; that conflicts with "shared `Keypad`" and with D13. For accessibility both are fine (a wide key is easier at large text); choose the shared keypad.
- **Slip step (the saving's sheet):** the body scrolls; **S5 (minor):** at compact heights *Delete saving* scrolls at the end of the body instead of pinning, so a pinned destructive key is never adjacent to the thumb and the scroll window is not 56dp smaller.
- **Add-a-saving amount step (caption plus hint, 5 lines at 1.5x):** the same pinned header and scrolling region. Do not hide the hint at large text: hiding content at large text is itself a 1.4.4 loss.

### 3.3 Keys and buttons that grow

- **S3 (major).** `KeypadKey` uses `minHeight: keyHeight` (`keypad_key.dart:32`) with digits at 27sp (`keypad.dart:70`). At 2.0x a digit is 54sp, so a key is about 65dp and the 4-row keypad about 284dp (not the 216 the tight layout assumes). **Decision for the owner:** clamp the key label scale at 1.5x (a digit key is already "large text" at 27sp, 40sp at 1.5x, so the loss is small and the key size stays predictable), and say so in UI_DESIGN §9 as a deliberate exception to 1.4.4. If the owner prefers full scaling, the tight layout in 3.1 needs the keypad to scroll or move to a side pane (in landscape and `foldableUnfolded` it already does). Either way test at 2.0x.
- **S4 (major).** Guard keys: `minHeight` 56dp, `height` never; at 2.0x "Yes, add ₹99,99,99,999" (22 characters at about 34sp) wraps to two lines.
- **S6 (minor).** Spends parts: at 1.5x on 320dp the trailing "·" pokes about 2dp past the padding. Use mockup 42's option B (no dots, 16dp between parts, amount in `ink` 600, label in `ink2`).
- Display size (Android "Display size" at Largest) also shrinks the dp width; add a manual check at about 280dp wide (not in `TestWindows`).

### 3.4 Guard step height (mockup 41 problem 2, M1)

Mockup 41's "hole" (232dp of bare `bg`) is a defect for low-vision users (a large empty gap above two keys reads as a broken screen). **Recommend option B, the sheet shortens:** at 1.5x the guard fits (28 + 72 pinned row + 8 + question 90 + 16 + two keys 120 + 16 = 350dp of 568). The change of height is a resize: under reduced motion it is instant (M1). 05 §2 says "no resize" and must change if B is chosen. Do not scroll the guard keys; two keys fit at every size tested.

## 4. Targets, focus, keyboard, switch access

| Control | Target | Verdict |
|---|---|---|
| Digit keys, ⌫ | 64dp, 48dp when tight (the tray rule); grows with text | Pass (S3 for 2.0x) |
| *Fix it*, *Save* | 56dp wide key (48 tight) | Pass; full width, so 88dp is not a constraint (mockup problem 1) |
| Guard keys | 56dp min, full width, 8dp apart | Pass; `minHeight` (S4) |
| *All of it* chip | 48dp | Pass |
| *Used some of it* | 56dp | Pass |
| Foot row | 48dp, the text row on the page layer | Pass at the floor; make the whole row width the target; verify the ring has 4dp clear on both sides (the page gutter gives 20dp) |
| Missed-log line | 56dp min, whole row | Pass; no ×, so one trailing target (agreed) |
| Install line | 56dp min with a 48dp chevron | Pass |
| Back, Undo | 48dp | Pass |
| *Try again* (S0c) | 48dp **drawn**, about 40dp **hit** | **Fail (K1)** |

- **K1 (major, house 48dp; 2.5.8 AA's 24dp still passes).** Mockup 41 puts the 48dp *Try again* in the line-2 position with `margin-bottom: -8px`, so it overlaps the card's 14dp padding by 8dp. In Flutter a child outside its parent's bounds does not receive pointer hits (the parent's hit test checks its own size first), and the semantics rect may or may not report the overflow. **Fix (proposed):** size the slot's `minHeight` to include the full 48dp key in S0c (the `IndexedStack` already takes the tallest child, so make that child 48dp tall instead of overflowing), and delete the negative margin. Test by tapping the bottom 4dp of the key.
- **Guard.** First focus on *No*; Tab order = visual order; the sheet traps focus (agreed) and returns it to the opener (see T6 for the removed-opener case). *Yes* sits in the easiest thumb spot (mockup problem 6); keeping *No* first in both focus and visual order (2.4.3) is right, and `Yes, add ₹30,000` names the money. Keep.
- **D99 focus ring.** Ring 2dp plus 2dp gap needs 4dp clear around each control: keys have 8dp gaps; guard keys 8dp; *All of it* sits inside the card's 20dp padding; the missed-log line has 20dp side gutters and 16dp above and below; the foot row has the page gutter. Pass on paper; assert with a widget test (section 7). Snackbar Undo works through the gap band (C4).
- **K2 (major, 2.5.1).** *Not logged* and *Used* rows are "no tap, swipe deletes with Undo". `entry_row.dart:72` already exposes a custom "delete" semantics action, so TalkBack and Switch Access have a non-gesture path. The new rows must be built through that widget (or copy it) and a test must assert the action exists on both new row types. Without it a TalkBack user cannot undo a wrong *Got* fix after the 4 s snackbar.
- **K3 (minor).** Long-press ⌫ to clear has `longPress` semantics (TalkBack actions menu, Switch Access menu: shipped). For D-pad there is no Enter-hold; repeated Backspace is the alternative (at most nine). Accept.
- **K4 (minor).** Hardware keyboard: decide, do not leave open (04 open question 6). Digits type, Backspace is ⌫, Enter is the action key when enabled, Esc is Back; in the guard, Esc is *No* (one step back, as Back is). Arrow keys move in the keypad grid. Tablets and foldables are in scope.
- **K5 (minor, 2.2.1).** The 4 s Undo extends under TalkBack and restarts on touch or focus (D105, D128). Switch Access users do not enable touch exploration and scanning can take longer than 4 s to reach *Undo*. The documented fallback is deleting the row in Every entry via the action (K2). State this fallback in SPEC next to D105; an owner decision on a longer Undo for the two corrective saves (*Fix it*, *Used*) is open.
- **Switch Access cost.** 12 keys plus the action is inherent to a keypad; the Settings row is the shorter door when the foot row is far down a long Today list at 2.0x. No change.

## 5. Cognitive load and the 5-year-old bar

- **G1 (major, 3.3.2).** The title says "this month's money"; the helper says "Bank and cash together. Leave out money from before this month." The helper is the instruction that stops the harmful error (a buffer posted as a *Got*), and it is replaced by the preview after the first digit, and at 1.5x the title scrolls away. After the first key the user has **no** instruction on screen. **Fix (proposed):** show the helper permanently as the second line of the title block when the window is tall enough (about 40dp at 1x; the 1x budget at 360x760 has about 110dp spare: 622 of 732dp used); in the tight layout it scrolls with the heading (section 3.1) and is still in the semantics tree. The guard remains the second line of defence.
- **G2 (major).** Vocabulary. Across the three features a user meets *Fix my number*, *Not logged*, *Saved*, *put in*, *set aside*, *Used some of it* and *Used from savings*. One screen should carry at most two new terms. The Spends line proposes four parts (*Spent*, *Saved*, *Used from savings*, *Not logged*) on a screen whose job is calm; and the saving's sheet puts "Used some of it" in a hint directly above a key that says the same words (mockup 42 problem 5). **Fix (proposed, for `design-ia` and `design-content`):** (1) keep *Used from savings* **out** of the Spends line (the "recommended" Q3 in the yearly doc); *Used* shows in Every entry and on the Savings list, where "set aside" lives; (2) the Spends line then has at most three parts (*Spent*, *Saved*, *Not logged*); (3) drop the saving-sheet hint when the key is clear in blind read B8. The blind-read plan (copy deck §9) is the right test; add a pass line for "which of these is money going out?".
- **Guard question (G-guard).** "That's ₹30,000 more. Is all of it from this month?" is two ideas (an amount, and a test of origin) and the user must know where their money came from. It is the hardest sentence in the three features. Mitigations already in the design are good: *No* is first, the safe answer; *Yes, add ₹30,000* names the effect; one Back leaves; Undo remains. **Add:** keep B6 in the blind read with an extra probe ("What happens if you press Yes?"), and keep the guard **only** for large *higher* gaps (as designed). With C1's fix (clear after *No*) the guard has no second, hidden mode.
- **"hisaab thought ₹17,430." (pass).** Plain words of one or two syllables, past tense, no blame (the app guessed), shown only after the first digit so the user reads their bank first (anchoring). The one risk is that the sentence has no unit; it is acceptable because the helper and the heading name "this month's money". The brand in lowercase at the start of a sentence is spoken as a name; fine.
- **"Used from savings" (see G2).** The phrase is long (17 characters) but the row second line "Paid from what you set aside." explains it. Keep the second line; do not shorten the kind word.
- **G3 (minor).** The page asks the user to sum bank and cash and leave out older money. It is a sum, so it is not a 5-year-old task by itself. The design is the best available (no calculator, no second field; Tesler), but it must be tested with a first-time smartphone user, not only the blind read of strings. Keep "Spot on" out (idiom, D121; "That matches." is right).
- **Nothing reorders (pass).** Keys, dock and categories are untouched; the guard replaces the keypad in place, which is a visible, one-Back mode; the foot row and the install line use the same label.
- **No time pressure (pass with a note).** The only timer is the 4 s Undo (K5). **Undo over confirm (pass):** the guard is a question with a safe default, not a "Are you sure?".
- **Errors suggest a correction (pass):** "Couldn't save. Try again." (shipped), "Things changed. Check the new amount." (vague; the preview below it is the new amount, so acceptable), "Couldn't check your number." with a visible *Try again*.
- **Missed-log line (pass):** no ×, no counts, no "forgot"; "no" is free. The glyph can look like a Today row (mockup 43 problem 1); in TalkBack it is a button with "Opens the keypad", so no role confusion. Visual confusion is for the hallway test.

## 6. Reduced motion (05, E13)

Checked every row of `05-motion.md` §6. Opacity crossfades at 150 ms (slot, guard swap, notices) are allowed under reduced motion (not movement); values still update; haptics unchanged. Specific points:

- **M1 (major, ties to T4).** Confirmed: `Shake` is skipped under reduced motion (`shake.dart:10`, `shake.dart:33`) and no flash exists, so the haptic is the only signal. 05 proposes a 150 ms outline flash. **Refine:** a flash of one frame to 150 ms is easy to miss for low vision and gone by the time the eye arrives; make the ring a **state** held until the next accepted key (it is 17.97 and 14.54 against the card), and add the spoken line (T4). A single small-area flash is safe for 2.3.1, but a state needs no flash at all.
- **Guard height (M1 minor).** If option B is chosen (3.4), the sheet resizes; under reduced motion it must be instant, and 05 §2's "no resize" line and E13 need the exception.
- **Auto-scroll of the slot (3.1)** is instant under reduced motion.
- **05 F4 (150 ms in both modes).** Agreed for opacity. Any property that moves (height, position, scale) must jump under reduced motion; 05 lists the receipt row, line collapse, bar and snackbar correctly.
- **Android "Remove animations"** sets `disableAnimations` (animator scale 0); the 150 ms crossfades still run, which is fine because they are opacity.
- **Information not lost:** every animated change also updates text; the snackbar states the number. Pass.

## 7. Required accessibility tests

All new or extended; none edits an existing assertion. Files: `test/a11y_test.dart` (guideline tests, per `.claude/rules/accessibility.md`) and the per-widget files named in the feature docs. Pump through `pumpApp` at `TestWindows.smallPhone`, `phone`, `foldableUnfolded` and `tablet`, each at `textScale` 1, 1.5 and 2.0, plus `reduceMotion: true`.

1. **Contrast pairs** (`test/core/design/contrast_pairs_test.dart`, add cases, same floors): `focusGap` on `inverse` (`nonText`); `displayInk` on `display` and `ink2` on `display` (`nonText`: rings); `surface` on `ink2` (`text`: *All of it* selected); `displayInk` on `hairline` (`text`: chip at rest); `ink2` on `sunk` for 13sp lines is already covered by the `sunk` loop. If the highlight is kept (C1 alternative) it must be drawn as selected, so a `sunk` on `display` pair is **not** added (it would fail by design).
2. **Guidelines** per screen and state: `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`, and `tester.takeException()` is null (no overflow). Screens and states: the Fix sheet in S0, S0c, S1, S2, S3, S4, S5, S6, S7, S8, S9 and the guard; the *Used* keypad in empty, typed, at balance, refused, nothing-set-aside; the saving sheet; the Add-a-saving amount step with the caption; the foot row, install line and missed-log line on Home; Every entry and Spends with the new rows and the four-part line.
3. **Layout** (the blockers): at `smallPhone` and 1.5x and 2.0x, in every Fix and *Used* state, the amount's rect is fully inside the viewport and above the keypad; the slot's last line is inside the visible scroll region after the first digit; the keypad and action key are fully visible and 48dp or more; the guard keys' height is at least 56dp and grows with text (`Yes, add ₹99,99,99,999` at 2.0x); the *Try again* hit test succeeds at the bottom 4dp of its 48dp box.
4. **Semantics:** the slot is one live region and only one `IndexedStack` child is in the tree; the debounced label timing with `tester.pump(Duration)` (400 ms normal; 1.2 s with `accessibleNavigation`; at once on a state-class change); the sentence equals the copy deck (spoken amounts); empty versus typed zero; the disabled *Fix it* hint; the guard question is announced or focused and *No* is first; the notice after *No* is read once; sheet name; `selected` on *All of it* and the toggle/no-op rule; the missed-log line is one merged button that is not a live region; focus returns to the Today heading when the line is removed; *Not logged* and *Used* rows read the sentence form and expose the delete custom action; the Spends line reads one sentence with no `·`.
5. **Reduced motion:** the cap shows a held ring (no `Transform` from `Shake`) and the announcement; crossfades are 150 ms; the guard resize and slot auto-scroll are instant; receipt row and collapse jump (as 05 §9 lists).
6. **Keyboard and focus:** Tab and arrow order in the keypad and guard; Enter activates *Fix it*; Esc closes (or is *No* in the guard); `FocusRing` present with 4dp clear space on the keys, guard keys, chip, foot row, lines and Undo; the ⌫ node exposes the `longPress` action.
7. **Static greps to run at review** (from the audit process): no `GestureDetector` without semantics in the new widgets, no raw `Color(` or `Icons.`, no fixed `height:` on text-bearing keys, no `textScaler` override.

## 8. Not verified, and device checks needed

Nothing was run on a device. Needed on the moto g45 with TalkBack and Switch Access, at font size Largest and display size Largest, before the build is called done:
- The guard (T1): does TalkBack follow `requestFocus` to a `Focus`-wrapped question; is the question audible once; is focus lost.
- The slot cadence (T2): type a 6-digit amount by touch and listen.
- The disabled-key hint (T8), the cap announcement (T4), the *Not logged* sentence (T5), focus return after the missed-log line leaves (T6).
- The hit area of the 48dp *Try again* (K1), Undo reachability with Switch Access (K5).

Assumptions in this review that I did not confirm: the semantics rect for an overflowing child (K1); that `HisaabSnackbarHost` clears the 4 s timer for TalkBack as D105 says (read in docs, not tested); `bill_summary.dart`/`income_effect.dart` live regions are undebounced (grep only); the Add tray's behaviour at 2.0x.

## 9. Doc edits that follow (listed, not made)

| Doc | Edit |
|---|---|
| UI_DESIGN §9 | Debounced live region and its `accessibleNavigation` form; the key-label scale clamp if accepted (S3); the tight layout (pinned amount, end-anchored slot); a refusal is a held ring plus words |
| SPEC NFR-4, E12, E13 | 2.0x on the new sheets; the cap ring is a held state under reduced motion; the guard resize is instant |
| `04-interaction.md` | §2 (empty vs typed 0 spoken; cap announcement), §4 (guard focus, *No* clears digits, notice is read by focus), §7 TalkBack bullets, hardware keyboard decision, open question 10 |
| `05-motion.md` | §2 guard "no resize" vs option B; auto-scroll; ring as a state |
| Copy deck 41 | `notLoggedRowSpoken` and `entryUsedSpoken` sentence forms; `spendsPartNotLogged` spoken form; a cap line key; `fixSavingSpoken` only after 1 s |
| `habits/08-missed-log-line.md` §5 | Focus return when the line itself is removed; hover `ink2` |
| DECISIONS | One row each if accepted: *No* clears the digits; guard focus method; keypad label clamp; Used stays out of the Spends line |
