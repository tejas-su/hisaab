# Design QA and sign-off pack: Fix my number, yearly costs (*Used*) and the missed-log line

> **Status: written into SPEC (D163–D189), 2026-11-13.** Signed off in section 8 and since written into SPEC (BR-18, BR-19, FR-KS, FR-FX, FR-HO-3, FR-HO-9, FR-SP-4a, FR-SE-1, E72 to E115, NFR-11 and NFR-12), UI_DESIGN (§5.2, §5.4, §5.6, §5.7, §6 to §10, §13), DECISIONS (D163 to D189) and PLAN (§2, §3, §8 schema v5, M8). Sections 1 to 6 are the review record and are not rewritten: where they disagree with SPEC, SPEC wins. The ARB, the code, the mockups and the other feature docs listed in section 7 were not touched by that change. One reconciled picture of three designs, longer than ~150 lines on purpose (the owner asked for one pack for all three); split by feature if it is reopened.
>
> **What was read:** case studies 33 and 34; `01` to `07` of this folder; `docs/features/yearly-costs/01-ux-flow.md`; `docs/features/habits/08-missed-log-line.md`; the copy deck `docs/design/mockups/41-fix-my-number-copy-deck.md`; mockups 41, 42 and 43 (frames, token tables and "problems found"). **Checked against the repo** (read only): SPEC (BR-3, BR-7, FR-AD-2 to 5, NFR-1, NFR-4), UI_DESIGN §13, `lib/home/presentation/pages/home_page.dart`, `due_soon_row.dart`, `lib/core/widgets/keypad.dart` and the `keyHeight` call sites. **Not done:** nothing was run on a device, no user was tested, and I did not re-measure the platform review's probe (its numbers are quoted as its own). Arithmetic was checked by hand.
>
> **Precedence used:** SPEC › UI_DESIGN › mockups › PLAN once written. Until then the later specialist review wins unless an owner answer in case study 33 says otherwise. Where a review's claim can be checked in code, I checked it and say so.
>
> **ID note:** the docs reuse labels. In this pack `02-F8` is edge case F8 of `02`, `05-F1` is motion flag F1 (the Home hold), `X5` is a row of section 1, `O3` an owner item, `P4` a build prerequisite, `T2` a test step.

## 0. The short version

| | Fix my number | Yearly costs and *Used* | Missed-log line |
|---|---|---|---|
| Verdict | **Blocked by the user test** for the question's wording and the one-number assumption; a design pass runs in parallel (section 6) | **Ready to write into SPEC after sign-off**, after a mechanical doc sync (section 7) | **Needs one more design pass** (small: the evaluation rule, late arrival, slot position; section 6) |
| Owner items (section 3) | O1 to O4, O11, O12, O17, O18 | O5 to O8, O21 | O14 to O16 |
| Biggest open risk | People type a total, not this month's money (study 34, riskiest assumption; `02` I-2, sev 4) | Users never find *Used* (`01` I-1, sev 3) | Reads as a Today row (mockup 43, problem 1) |

Three things the owner should know before reading further:
1. **The designs agree on the accounting and disagree on the screen.** The rule `E`, the hidden category, the `F_t` term and the *Used* kind survived every review. The contradictions are almost all about the sheet that holds the keypad (section 1, X1 to X12), and the platform review shows the existing bill-sheet body cannot host it yet (P2).
2. **One new risk found by this pack (X7):** when the guard appears, *Yes, add ₹30,000* lands on the exact spot where the thumb just pressed *Fix it*. A double tap would post a large *Got*.
3. **A symbol clash (X34):** `02` names the expected-money figure `E`, but SPEC BR-7 already uses `E` for days elapsed (`E = 22` in its worked example).

## 1. Cross-check: contradictions and resolutions

Each row: what disagrees, the resolution I recommend, and which doc it overrides. "Later review wins" means `05` to `07` and the copy deck over `01` to `04`. Rows marked **new** were not on the brief's list.

### A. The keypad sheet: size, shape, layout

| # | Disagreement | Recommended resolution | Overrides |
|---|---|---|---|
| X1 | **The action key.** `04` §2, §3.1, §7 and copy deck §0 treat *Fix it* as the keypad's bottom-right cell, about 88dp wide (so "7 characters at 1.5×", and R12 drops "Saving…"). Mockup 41 (problem 1), `06` §4 and `07` §3 treat it as a full-width key under the keypad. **Code check:** `Keypad` is 4 rows of 3 ending in `00 · 0 · ⌫`; there is no action cell. | **Full-width action key under the shared keypad**, as *Next* is in the Add tray. Same for *Save* on the *Used* keypad. Keep the label *Fix it* (calm); TalkBack says "Saving" only if the write passes 1 s (`06` T8). Marigold fill, `onSignal` label, 1.5dp edge (mockup 41 problem 3). | `04` §2, §3.1, §7, §9 (the *Used* wireframe has no `00`); copy deck §0 budget and R12; `01` W3 to W6 wireframes |
| X2 | **Key height.** `04` and mockup 41 say 64dp. Mockups 27, 28, 40, 42 and **code** use 56dp in every sheet (`bill_amount_question`, `put_in_sheet`, `income_amount_question`: 56; Add tray 64, 48 when short; onboarding 60). The action key is 56 (41), 60 (`07` probe) and "68 incl. gap" (42). | **56dp keys, 48dp when the window is short, 56dp action key (48 short).** Re-measure the action key in the build; do not argue about 56 versus 60 on paper. | `04` §2, §7; mockup 41 anatomy and redline |
| X3 | **The drag handle is 48dp** (measured by `07`), but mockup 41 budgets "handle area 20" and 42 budgets 16. Every 320×568 budget in 41, 42 and `06` §3 is 28 to 32dp too generous. `06` §3.1 also drops the handle row ("sheet fills"); `07` §3 keeps it. | Recount every tight budget with 48dp. The handle is route-level (`showDragHandle`, read once), so **keep it** unless a measured test shows a drop is needed. If it is dropped, say so in one place. | Mockups 41, 42 (budgets and problem 1's "fits at 1×", which is false); `06` §3.1 |
| X4 | **Does the sheet pin its keypad?** `04` §1 says the sheet "scrolls above a fixed keypad, as the tray does" and cites the bill-sheet route as precedent. **Code (`07` §1):** the bill-sheet body is one `SingleChildScrollView` with the keypad inside it; the *Save* key is already below the window at 320×568. | Pin `controls` (keypad and action key) and the typed amount; scroll the title and slot between them (agreed by 41, `06` §3.1, `07` §3). This is a **shared change** to every bill-sheet keypad question (P2). | `04` §1 (the precedent claim is wrong) |
| X5 | **Stacked or side by side at 320×568 and 1.5×.** `07` §3 says side by side from the rule "scroll region under 96dp" and "always at 2×". `06` §3.1 stays stacked with a pinned header. **A 320dp window cannot hold a 220dp keypad pane beside a readable header pane** (about 60dp left). | **Stacked with the pinned amount at every width under about 560dp**; side by side only for width of 560dp or more with short height (landscape, 412×400 split-screen is borderline: test it). The 96dp rule stays, but as "what the slot scrolls inside", not as a trigger for panes below 560dp. | `07` §3 table rows "Compact, small" |
| X6 | **Tabletop and two-pane.** `04` §1 and mockup 41 §8 put title, amount and slot in the upper half and the keypad below, and split an expanded window into two panes. `07` (verified in framework source): a sheet sits in one sub-screen, so tabletop is the lower half, side by side (D29), and an expanded flat window keeps the 560dp centred stack. | **`07` wins.** Mockup 41 §8's schematics are not buildable as drawn. | `04` §1, §8, Open Q8; mockup 41 §8 |
| X7 | **Guard step: keys and tap-through (new).** `01` W6 draws *Yes* and *No* side by side; `04` §4, mockup 41 and `06` stack them, *No* first, 56dp, and `04` puts the swap at the same place as the keypad. The stack ends where *Fix it* was. **A quick second tap on *Fix it* (or a late finger lift) lands on *Yes, add ₹30,000*, which posts a large *Got*.** `droppable()` does not help: it is a different event. Mockup 41 (problem 6) saw only the thumb-zone half of this. | Stacked, *No* first (keeps visual and focus order equal). **Add a short input lock on both guard keys (about 300 ms after the swap; the 150 ms crossfade already runs inside it)**: no visible mode, one line in `04` §4. Check on a device (D1). Revisit if B6 shows mistakes. | `01` W6 (side by side); `04` §4 and §5 (add the lock) |
| X8 | **Guard height.** `04` §4 and `05` §2 say the panel has the same height and the sheet "does not resize". Mockup 41 (problem 2) found a 232dp hole under two keys; `06` §3.4 and `07` §3 rule 7 both recommend a shorter sheet. | **The sheet shortens for the guard (mockup 41 option B).** Motion: `resize` + `easeOut`; instant under reduced motion. At tight sizes the guard fits (`06`: about 350dp of 568). | `04` §4 ("same height", `IndexedStack`); `05` §2 and E13 (add the exception) |
| X9 | **Guard exits.** `04` §4 says the scrim closes the sheet; `07` §4 (read in `material_ui` source): the scrim goes through `maybePop` and respects `PopScope`, so it acts as Back (= *No*); the handle and swipe-down call `onClosing` and bypass `PopScope`, closing the whole sheet. | **`07` wins:** system back, Escape and the scrim = *No*; swipe and handle = close, nothing posted. `PopScope.canPop = step is keypad || saving`. | `04` §4, §8 |
| X10 | **Predictive back.** `04` §4 ("previews the keypad step"), `05` §2 and 05-F6, and UI_DESIGN §10 ("a back swipe scales the tray down") assume a preview. `07` §4: `ModalBottomSheetRoute` has no back-gesture hook. | **Back commits; then the normal exit or the 150 ms crossfade plays.** Drop every "preview" promise. UI_DESIGN §10's sentence is about pages only: confirm on a device (D10), then correct it. | `04` §4; `05` §2, 05-F6; UI_DESIGN §10 |
| X11 | **After *No*: clear or keep the digits.** `01` §1.2, `04` §4 (keep, next key replaces) and mockup 41 (a `sunk` highlight) versus `06` C1 (clear). The highlight is 1.30:1 (light) and 1.17:1 (dark) on the card, the only cue for a hidden mode, and invisible to TalkBack. No owner answer. | **Clear the digits.** "No, some is older" means the typed total was wrong, so there is nothing to keep; the hidden "next key replaces" mode disappears. Line 1 shows "Count only this month's money." over ₹0, and focus goes to that notice (`06` §2.1). This also removes mockup 41 problem 10 (the stale "One question first" under the notice). The FR-AD-8 replace rule is not needed here. | `01` §1.2, W6, §1.4 table rows 3 and 3c wording; `04` §4, §8, Open Q2; copy deck S7 and the "No" frame; mockup 41 state `no` |
| X12 | **Back on the sheet.** Mockup 41 (problem 7) suggests dropping the Back button on a one-step sheet; `04` §7, `06` and `07` all list it. | Keep Back: it is the visible step-back in the guard, and the scrim and swipe are not discoverable to everyone. | Mockup 41 problem 7 |

### B. Accessibility, motion, haptics

| # | Disagreement | Recommended resolution | Overrides |
|---|---|---|---|
| X13 | **Live-region debounce: 400 ms vs 1.2 s.** `04` §3, §6, §7, `01` §4 say 400 ms. `06` T2: a TalkBack user types a key every 0.6 to 1.5 s, so 400 ms queues a 5 s sentence after nearly every digit. | **1.2 s under `accessibleNavigationOf`, at once on a state-class change, and the live text is short** ("4,200 rupees less."; the full sentence is the slot's focusable text). The debounce only matters to a screen reader, so 400 ms has no remaining use. Same for the *Used* slot. | `04` §3.1, §6, §7; `01` §4 |
| X14 | **The 9-digit cap.** `04` §2 and mockup 42: reject haptic and shake, "no words"; under reduced motion a 150 ms flash (`05` §2). `06` T4/M1: `Shake` is skipped under reduced motion (`shake.dart`), haptics may be off, and a flash is gone before the eye arrives. SPEC FR-AD-2 also says "head-shake and reject haptic" only. | **A held 2dp ring on the amount until the next accepted key, plus a one-shot polite announcement ("That's the most you can type.", a new ARB key).** No visible words (the calm stays). This also closes the same gap in today's Add tray (a pre-existing defect: P5). | `04` §2; `05` §2 and §6 (flash); mockup 42 decision "outline flash"; SPEC FR-AD-2 and E13 on approval |
| X15 | **When `success` fires.** `04` §5 step 3: as the sheet starts closing. `05` 05-F2: SPEC FR-AD-5 pairs it with the visible change after the drain starts. | **`05`.** With Home under the sheet, `success` fires at t = 0 with the roll; from the Settings door (no hero) at the exit start. | `04` §5 step 3 |
| X16 | **Reduced motion and the 150 ms crossfade.** `04` §3.2 says "do not force 150 ms; the system setting scales controllers." `05` 05-F4 and E13: crossfades are 150 ms in both modes. | **`05`.** Opacity is allowed under reduced motion; anything that moves jumps. | `04` §3.2 |
| X17 | **Guard focus.** `04` §4: "focus moves to the question". `06` T1 (**blocker**): the key that was pressed disappears and static text cannot take focus, so TalkBack loses its place. | Make the question a `Focus` + `Semantics` node and request focus in the frame the panel is built; if a device shows TalkBack does not follow, use a live region and focus *No*. **Device check D1 is mandatory before build is called done.** | `04` §4, §7 |
| X18 | **Focus after a line leaves.** `08` §5: "the line's leaving does not take focus". `06` T6: after Back the line is the opener and is removed, so focus falls to the page top. | When the missed-log line or the install line leaves, focus goes to the node now in its place (the "Today" heading). | `08` §5; `04` §7 ("Home's top") |
| X19 | **Tapping *All of it* when selected.** `04` Open Q10: a no-op. `06` T9: every `onTap` must do something. | **Tapping again clears the amount** (a filter chip toggles). | `04` §9, Q10 |
| X20 | **New-row insert timing.** `05` puts the *Not logged* row 300 ms after the hero roll. Case study 24 pattern F (built for Add) starts the row with the pull-back. `05` 05-F3 flagged it. | Keep `05` for these rows (a figure must be read before the list shifts). Decide **once** for Add too, so the two saves do not differ; not an owner question. | Case study 24 pattern F, if Add is aligned |

### C. Copy

| # | Disagreement | Recommended resolution | Overrides |
|---|---|---|---|
| X21 | **Preview sentence.** `01` §5: one sentence "That's ₹4,200 less than hisaab thought…", "about" on the gap, "Spot on". `04` §3: two lines with `E` as line 1. Copy deck R3, R4, R10: two lines, no "about" on the gap (it is exact and posted exactly), "That matches". | **Copy deck** (two lines; "about" only on the per-day figure; no idiom, D121). Hearing line 1 is the only way to check `E` (principle 86). | `01` §5, W4 to W7; `04` §3 wording |
| X22 | **Row second line:** "Added to match your money" (`01` W10, `02` §1, `03` §4.2) vs "Added when you fixed your number." (deck R6). | **Deck R6:** it names the user's own act and answers "who put this here?". "Added to match" stays the blind-read fallback (B2). | `01`, `02`, `03` |
| X23 | **Snackbar:** "Fixed. Today you can spend ₹963." (`01`, `04`) vs "Fixed. Safe to spend today: ₹963." (R5). | **Deck R5**; it repeats the hero's own title, and ₹0 needs no softening. | `01` W8; `04` §5 |
| X24 | **Page title and the question.** Study 34 starts from V1 "How much money do you have right now?" plus the helper "We'll take out your bills and savings." `01` §1.5 and deck R1 use V6 "How much of this month's money is left?" and say the page must **never** promise the take-out. | **V6 is the working copy; the test decides** (study 34's own pass lines still apply; V2 is the fall-back). The test script must carry V6 and the card-bill probe (`01` §6, `02` §6 asked for it; deck B3 has it). | Study 34 §Recommendation 1 |
| X25 | **Settings row detail:** "Say how much of this month's money is left." (`03` §2.3) vs "When the number on Home looks wrong." (deck). | Deck (says when, in the user's words). | `03` §2.3 |
| X26 | **Four *Used* strings, four versions** (mockup 42 problem 4): caption "a twelfth" (`01`, `03`) vs "divided by 12" (R11); "₹4,000 set aside so far" vs "{amount} set aside"; "₹{left} will be left" vs "{amount} will still be set aside" (with the zero form "Nothing will be set aside."); the cap "That's all that's set aside. Add anything more as a spend." vs "That's all you have set aside. Add the rest as a spend."; the snackbar "₹4,000 used from Insurance" vs "Insurance: ₹4,000 used" (name first, D132). | **Deck for all five.** "So far" is dropped: it implies a total still growing, and the balance line already shows the number. The owner may prefer "so far" (it is a word choice, `B11`). | `yearly-costs/01` §3.3, §4.3; `03` §3 |
| X27 | **The *Used* row.** `yearly-costs/01` §4.7 and `03` §4.2: "Insurance · Used · ₹4,000", kind word *Used*. Deck R7 and §4: kind word "Used from savings", one string "Insurance · Used from savings". Mockup 42 (problem 3): the one-string title does not fit a 176dp column; drawn as **name over kind word**, like the *Saved* row. `06` T5 asks for a spoken sentence with the verb first. | **Two lines: the saving's name, then "Used from savings", amount at the end.** `entryUsed` is the kind word only; the saving name is a separate placeholder. Spoken: "Insurance. Used from savings 4,000 rupees." The same two-line shape for *Not logged · Spent / Got* (see X22). | `yearly-costs/01` §4.7; `03` §4.2; deck §4 `entryUsed` and `entryUsedSpoken` |
| X28 | **Spoken form of the new rows.** Deck `notLoggedRowSpoken` "Not logged, spent, 4,200 rupees" and the Spends part "Not logged 4,200 rupees" (no direction). `06` T5: the ear hears a list; the direction word is lost. | "Not logged. Spent 4,200 rupees." / "Not logged. Got 1,000 rupees."; the Spends part reads "Not logged, spent 4,200 rupees." Same words, different ICU template. | Deck §4, §5 TalkBack |

### D. Placement, order and what the screens say

| # | Disagreement | Recommended resolution | Overrides |
|---|---|---|---|
| X29 | **Settings group.** `01` §3 and case study 33: *Your hisaab*. `03` §2.3: end of *Money* (recommended, "medium confidence", tree test first). Mockup 41 §2 and the deck follow `03`. | **End of *Money*, pending tree test T6.** Both candidates go in the test; the pass mark decides, and a tie keeps `03`. | `01` §3 row 2 |
| X30 | **The foot row's look.** `01` W1: a `sunk` 56dp row with icon and text. `03` §2.1 and mockup 41: a quiet text row, no fill, no icon well, 48dp+. `06` §4 agrees with the text row. Both `03` and mockup 41 claim a fact about the nudge slot; they contradict each other (see X31). | **Text row, 48dp+ target, no second line, no count.** The reasons that hold: it must not look like the permanent version of a nudge (`03` guard-rail 1) and the UI_DESIGN §3 layer rule. | `01` §3 row 1, W1 |
| X31 | **What the nudge slot is made of.** `03` §2.1, `01` W1 and `08`/mockup 43: a `sunk` 56dp row with a `surface` icon well. Mockup 41 (problem 4, flagged "DOC ERROR"): a `surface` card with a `sunk` well, quoting "`DueSoonNote`". **Code (`due_soon_row.dart`):** `DueSoonRow` is a `sunk` squircle (radius 18, min 56dp), pressed `hairline`, with a `surface` well. | **`03`, `08` and mockup 43 are right; mockup 41's "DOC ERROR" is wrong** (there is no `DueSoonNote` in `lib/`). Delete problem 4 from mockup 41. The foot-row decision (X30) stands without it. | Mockup 41 problem 4 and the wording in §1 |
| X32 | **How many parts the Spends line may have.** `03` §4.3, `02`, `yearly-costs/01` Q3, the deck §5 and mockup 41 §6: up to four (*Spent*, *Saved*, *Used from savings*, *Not logged*), wrapping between parts. `06` G2 (and mockup 42 option B): keep *Used from savings* off the line; three parts at most. Owner answer P1-3 requires *Not logged* in Spends; no owner answer requires *Used* there. | **Three parts: *Spent · Saved · Not logged*.** *Used from savings* shows in Every entry and on the Savings list, where "set aside" lives. Parts appear only when above ₹0 and wrap between parts; mockup 42 option B (no trailing dots) fixes the 2dp overhang. This is an owner confirmation (O5). | `03` §4.3; `02` §1 table; deck §5 `spendsPartUsed`; mockup 41 §6 |
| X33 | **Is *Not logged* inside "Spent"? (new)** The worked line "Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200" (and mockup 41 §6, headline ₹27,570) implies *Spent* **excludes** it, as the line excludes *Saved*. No doc says it, and `06` T5 notices the ear cannot tell. BR-12 to BR-14 exclude it from bars and *Where it went*. | State it: **the Spends "Spent" figure excludes *Not logged*, as it excludes *Saved*; the part is its own number.** Put it in the SPEC FR-SP-4a text and in the Ask AI facts clause. | `02` §1 table (add the sentence) |
| X34 | **Symbol clash (new).** `01` §1.2 and `02` call the expected-money figure `E`. SPEC BR-7 already defines `E = t − start`, whole days elapsed (worked example `E = 22`). Also `X` (typed figure) is BR-8's `X`. | **Rename before it enters SPEC.** Suggest `H` ("held") for expected money and `T` for the typed figure, after a grep of SPEC for the free letters. The formula `H = remaining + B + R` is unchanged. | `01` §1.2, §1.4; `02`; mockup 41 and deck prose |
| X35 | **Nudge-slot order text.** `08` §1 rule 2 and §9 say the line is "the **third and lowest** item"; `03` §1.2 and `01` §3 make it fourth (waiting, due-soon, install, missed-log). | Fourth. Edit `08`. | `08` §1, §8, §9 |
| X36 | **When the missed-log line is evaluated, and the tray over it.** `08` §1 lists "a door-opened tray closing" as an evaluation point that can **add** the line, and says a line drawn behind a tray is "not yet asked". `05` 05-F7: that is a late arrival; evaluate once when the door resumes (drawn under the scrim in Home's first frame), and let the tray close only **remove** it. `07` §7 adopts F7. The line is also hidden under the tray while it is open, so a user can never see it leave. | **F7:** evaluate at cold start, resume and door-resume; the tray close can only remove the line; write *asked* when the line was on screen with Home visible and no tray (the install line's *seen* rule is the same, `03` §1.3 rule 4). If the line is drawn under a tray that opens straight away it is not asked, and returns at the next evaluation point. | `08` §1 "evaluation points" |
| X37 | **Savings list row.** Deck §6 and `03` §5: "{amount} set aside" is the row's **second** line. The row's second line is already "Every month on the 5th"; mockup 42 (problem 2) draws it as a **third** line (row 64 to 84dp; six lines at 320dp and 1.5×). | **Third line** (the schedule stays), only above ₹0. | Deck §6 `savingSetAside`; `03` §5 |
| X38 | **Discovering *Used*.** `03` §3 wants cues (the hint "Paid the cost from this? Tap Used some of it." and the setup caption's second sentence) because discovery is the weak point (`yearly-costs/01` I-1, sev 3). `06` G2 and mockup 42 (problem 5) want the hint dropped: it sits directly above a key with the same words. | **Keep the setup caption's second sentence (free); keep the sheet hint until hallway test T7 shows the key alone is understood (4 of 5), then drop it.** Rung 2 (a tappable *Saved* row) is pre-approved only if T7 fails (O21). | `yearly-costs/01` §3.3; `03` §3 |

### E. Accounting and the owner's own words

| # | Disagreement | Recommended resolution | Overrides |
|---|---|---|---|
| X39 | **"In Other" and "editable".** Case study 33 §4.1 (the review, before the owner answered) says the fix is a *Spent* entry "in *Other*" and "editable in Spends like any other". `02` makes it a hidden category (`not logged`), excluded from limits and *Where it went*, never edited in the tray (delete and redo). The owner's binding answer P1-3 is only "visible in Spends and the Ask AI export". | Hidden category is right (the pool must move, not a category's total). **Confirm with the owner that "visible" is met by the Spends line part, Every entry and the export** (not *Where it went*), and that delete-and-redo is "editable" (O2, O3). | Case study 33 §4.1 wording |
| X40 | **A *Got* fix on the Spends line.** `03` §4.3: the part is the *Spent* side only; a *Got* fix shows in Every entry and the export. Owner P1-3 and P1-2 together imply a *Got* fix should be visible in Spends too. | Owner decision (O2). Default: leave the *Got* side in Every entry; add it to the line only if the owner reads "visible in Spends" strictly. | `03` §4.3 |
| X41 | **Large *Got* guard versus owner answer P1-2.** The owner said a higher figure posts a *Got*. `01`/`02` add a question before a *Got* larger than `I ÷ 10`. | Not a contradiction (the *Got* still posts on *Yes*) but it narrows the answer. Say so to the owner when asking for the threshold (O1). | `01` §1.2 note |
| X42 | **Used example numbers.** `yearly-costs/01` uses ₹4,000 in its wireframes and ₹12,000 in its worked example; mockup 42 frame 8 shows "Used from savings ₹4,000" on the Spends line under a lede that says ₹12,000. | Use ₹12,000 everywhere in SPEC (it is the worked example); redraw the frame. | Mockup 42 frame 8 |

### F. Drift inherited from earlier mockups, and standards

| # | Disagreement | Recommended resolution | Overrides |
|---|---|---|---|
| X43 | **The dock.** Mockups 40, 41 and 42's frames draw a five-item dock (*Home, Spends, Add, Ask AI, Settings*) beside a Settings gear in the top bar. UI_DESIGN §5 and §13: a dock of Home, Add, Spends; Settings top right; Ask AI is a card on Spends. | Redraw the dock as Home, Add, Spends in 41, 42 and 43. The error began in mockup 40; not caused by these three. | Mockups 40 to 43 |
| X44 | **Text scale.** NFR-4 says 1.5×; UI_DESIGN §13 says layouts are tested at 2× on 320dp; `06` tests 1.0, 1.5 and 2.0 and asks for key labels to stop at 1.5× (**owner answered yes**, case study 33). | Record the clamp (shared keypad, so the Add tray too) as a deliberate WCAG 1.4.4 exception in UI_DESIGN §9 and NFR-4, with a DECISIONS row. At 2.0× the keypad is then 4×56 + 24 = 248dp (not the 284 `06` computed). **Check that a 48dp tight key does not grow at 1.5× (27sp × 1.5 × about 1.2 line height is about 49dp)** (D13). | `06` S3 arithmetic; NFR-4 |
| X45 | **Hardware keyboard.** `04` Open Q6 and `06` K4 want digits, Backspace, Enter and Esc. `07` §8 (probed): the Add tray maps none; a digit does nothing. | **Leave it out of these features.** If the owner wants it, one wrapper in `Keypad` serves every keypad page (O9). | `04` §2 row, `06` K4 |
| X46 | **Posture changes while a sheet is open.** `07` §3: the route reads `tabletop` and `anchorPoint` once. `04` §8 says the sheet re-lays out live. | Make the route posture-agnostic for the sheets in this change (`anchorPoint: Offset(0, height)` always, max width 560). The same flaw in the Add tray (D29) is separate. | `04` §8 |
| X47 | **ID collisions in the docs.** `02` edge cases F1 to F22; `05` flags F1 to F9; `02` issues I-1 to I-8, `yearly-costs/01` I-1 to I-7, `08` open questions; SPEC uses E-numbers. | When written into SPEC use the next free E-numbers and do not keep F or U labels in SPEC. Cross-references in this pack use the prefixes above. | n/a |

## 2. Spec fidelity: numbers and mockups

Hand-checked against SPEC's worked example (BR-3: `I` 45,000, `B` 1,200, `S_prev` 27,150, today ₹420, `D` = 9, SPEC lines 141 to 146).

| Claim | Check | Result |
|---|---|---|
| Base: `P` 16,650, `A` 1,850, hero ₹1,430, `remaining` 16,230 | 45,000 − 1,200 − 27,150 = 16,650; 16,650 ÷ 9 = 1,850; 1,850 − 420; 16,650 − 420 | Pass (SPEC agrees) |
| `E` (the expected money) = ₹17,430 | 16,230 + 1,200; or 45,000 − 27,150 − 420 | Pass. Both forms agree |
| Lower, type 13,230: gap 4,200, `P` 12,450, `A` 1,383, hero **₹963**, per day ₹467 less | 12,450 ÷ 9 = 1,383.3 (floor 1,383); 1,383 − 420 = 963; 1,850 − 1,383 = 467; `remaining` 12,030 = 13,230 − 1,200 | Pass |
| Higher, type 18,430: gap 1,000, `A` 1,961, hero ₹1,541, ₹111 more, `remaining` 17,230 | 17,650 ÷ 9 = 1,961.1; 1,961 − 420; 1,961 − 1,850; 18,430 − 1,200 | Pass |
| Guard line `I ÷ 10` = 4,500; 47,430 − 17,430 = 30,000 | | Pass |
| After *Yes*: `P` 46,650, `A` 5,183, hero ₹4,763, `remaining` 46,230; "wrong model ₹3,333 more a day" | 46,650 ÷ 9 = 5,183.3; 5,183 − 420; 30,000 ÷ 9 = 3,333 | Pass |
| Case 3c (type 43,230): gap 25,800 | 43,230 − 17,430 | Pass |
| Mid-cycle install: `A` 4,866; type 9,000: gap 36,000; `P` 7,800; `A` 866 | (45,000 − 1,200) ÷ 9 = 4,866.7; 43,800 − 36,000; 7,800 ÷ 9 = 866.7 | Pass (this row has `S_today` 0, unlike the SPEC example) |
| Bar after the fix (`05`, mockup 41): yellow 77% to 70%, bite 23% to 30%; rise 78.6% and 21.4% | 1,430 ÷ 1,850 = 77.3%; 963 ÷ 1,383 = 69.6%; 420 ÷ 1,850 = 22.7%; 420 ÷ 1,383 = 30.4%; 1,541 ÷ 1,961 = 78.6% | Pass. Mockup 41: 963 + 300 + 120 = 1,383 |
| "Close enough" frame (type 17,400): inside the 50 rule | |17,430 − 17,400| = 30 | Pass |
| Yearly: `K` 1,000, `P` 15,650, `A` 1,738, hero **₹1,318 before and after**, `remaining` 15,230, tomorrow 1,903 | 45,000 − 1,000 − 1,200 − 27,150; ÷ 9 = 1,738.9; 1,738 − 420; 15,650 − 420; 15,230 ÷ 8 = 1,903.75 | Pass |
| Yearly: 12 put-ins of ₹1,000 from 5 Nov 2025 to 5 Oct 2026 = ₹12,000 | Nov to Oct inclusive | Pass |
| Yearly: Spends "Spent ₹27,570" | 27,150 + 420 | Pass |
| Over the balance: ₹3,000 extra spend: `S_today` 3,420, hero ₹0 and ₹1,682 over today, `remaining` 12,230, tomorrow 1,528 | 3,420 − 1,738; 15,650 − 3,420; 12,230 ÷ 8 = 1,528.75 | Pass |
| Wrong models: as *Spent* hero 0 and ₹10,682 over, `remaining` 3,230; as negative *Saved* `K` −11,000, `P` 27,650, `A` 3,072, hero ₹2,652 | 12,420 − 1,738; 15,650 − 12,420; 45,000 + 11,000 − 1,200 − 27,150; ÷ 9 = 3,072.2 | Pass |
| Missed-log (mockup 43): ₹420 spent (300 + 120), hero ₹1,430; 2:00 pm + 90 min = 3:30, now 4:10; after a ₹120 pill add hero ₹1,310 | 1,850 − 420; 1,850 − 540 | Pass |

**Findings from the spot-check**
- **Arithmetic is sound in every doc and mockup read.** No figure had to be corrected.
- **Two examples share one number base, but not one story.** The Fix my number example has `K` = 0 and the yearly one has `K` = 1,000 (hero ₹1,318, not ₹1,430). SPEC needs both written with their own inputs, and one combined row (a user with both: `E` = 15,230 + 1,200 = 16,430) so the interaction is tested.
- **The rule `E` is correct but its name collides** (X34).
- **Per-day effect on the last day** (`D` = 1): the copy is "Today gets ₹X less"; no number was checked there, and `02-F10` has no worked example. Add one to SPEC.
- **Mockup 43's Food amount (₹120)** differs from the SPEC pill example (₹55, FR-AD-10 AC-5). Not a contradiction: both are samples, but SPEC's example should be the one used in a golden test.
- **Mockups carry the wrong dock** (X43) and the **wrong handle height** (X3). Neither changes a number.

**The owner's binding answers**

| Answer | Honoured? |
|---|---|
| P1-1 Q6 stays closed; one-time Home line | Yes (`01` §3 row 3). The line's life is the install cycle (`03` §1.3 rule 4) |
| P1-2 Higher figure posts a *Got* | Yes, with a question first above `I ÷ 10` (X41) |
| P1-3 *Not logged* visible in Spends and Ask AI | Partly: Spends line (*Spent* side), Every entry, export. Not in *Where it went* by design. Needs O2 |
| P2′-1 A *Used* action | Yes. The Spends-line placement is open (X32) |
| P4′-1 Tap lands on the keypad (step 1) | Yes (`08` §2) |
| A11y-S3 Key labels stop at 1.5× | Accepted; needs a DECISIONS row and the check in X44 |
| P1-4 no limit on fixes; P2′-2 no reminder | Still "open", designers took the recommendation (no limit, no reminder). Listed in O13 as confirmations |

## 3. One consolidated list for the owner

### 3.1 Decisions only the owner can make

| # | Question | Designers' recommendation | Source |
|---|---|---|---|
| O1 | **Guard threshold:** ask a second question when a *higher* gap exceeds 10% of income? Or a fixed ₹5,000? A buffer under the line slips through (it is previewed and undoable). | **10% of `I`** (nothing to set, scales with weekly or small incomes). Accept that small buffers pass. Say that this narrows P1-2 (X41). | `02` Q1, I-4 |
| O2 | **What "visible in Spends" means for *Not logged*:** the line part (*Spent* side only), Every entry and the export; not *Where it went*; a *Got* fix only in Every entry and the export. Or also a *Got* part on the line? | The first. A strict reading adds a fifth part and re-opens X32. | `03` Q3; X39, X40 |
| O3 | **Edit:** is delete-and-redo (swipe, then fix again) enough for "editable"? | **Yes** (2 taps; edit in the tray could turn a fix into a real spend and trigger "over today"). | `02` Q2 |
| O4 | **Late pay on payday (`02-F8`):** if the salary has not arrived and the user truthfully says "none of this month's left", a huge *Spent* posts. Guard a big *lower* gap too? | **No guard**: the preview states it, Undo reverts. Revisit if the test shows it. | `02` Q3, I-7 |
| O5 | **Spends line:** three parts (*Spent · Saved · Not logged*), *Used from savings* only in Every entry and the Savings list. | **Yes, three** (X32), and *Spent* excludes *Not logged* (X33). | `06` G2; `yearly-costs/01` Q3 |
| O6 | **Does *Used* exist on every saving (RD too) or only on the three yearly chips?** The sheet hint says "the cost", which reads oddly on an RD. | **Every saving**, shown only when something is set aside; the hint **only** on the yearly chips. | `yearly-costs/01` Q5; deck open Q4 |
| O7 | **Over the balance (U1):** refuse the extra digits and add the rest as a spend (recommended), or accept it and post the excess as *Spent*? | **Refuse.** The excess path needs a rule so it does not read "over today". | `yearly-costs/01` Q1 |
| O8 | **A saving deleted with something set aside (U5):** it leaves "still set aside"; its history stays; *Used* is no longer reachable. Offer a final *Used* step? | **No extra step**; the delete's Undo says what stays. | `yearly-costs/01` Q2 |
| O9 | **Hardware keyboard:** leave out of these features (recommended), or one shared `Keypad` change for every keypad page, done once? | Leave out now; a later, separate change if wanted. | `04` Q6; `07` §8 |
| O10 | **Undo length for the two corrective saves** (*Fix it*, *Used*): keep 4 s (extended under TalkBack) or longer for Switch Access users? | Keep 4 s; the fallback is deleting the row in Every entry (a custom action exists). State it in SPEC. | `06` K5 |
| O11 | **The 9-digit cap gets a spoken line** ("That's the most you can type.") and a held ring, which also changes today's Add tray. | **Yes**; it is a pre-existing a11y gap, and the change is small. | `06` T4; SPEC FR-AD-2 |
| O12 | **Use the owner's own buffer as a test case:** does the owner have money outside this month's pay that they would count? (A single data point; it frames the test.) | n/a | `02` I-2 |

### 3.2 Defaults the designers took; one yes or no each

| # | Default | Source |
|---|---|---|
| O13 | No limit on fixes per day (P1-4); no reminder on a yearly saving (P2′-2). | Case study 33 |
| O14 | The install line waits in over states and in *No income* (one next step). | `03` Q4 |
| O15 | The saved-yesterday note does **not** silence the missed-log line (they say different things in different places). | `03` Q5; `08` Q4 |
| O16 | Missed-log line: after the window plus 90 minutes, no ×, once a day, Back clears it, and a cold start with late habits simply misses it. | `08` Q1 to Q3 |
| O17 | Amounts on the Fix sheet use full Indian grouping (₹1,25,000), not compact (₹1.25L). | Deck Q3; mockup 41 problem 13 |
| O18 | "hisaab" in lower case at the start of a sentence ("hisaab thought ₹17,430."). `design-brand` rules. | Deck Q1 |
| O19 | A saved-yesterday and *Not logged* interplay: a fix dated yesterday is pool-side in `A_yesterday` and never "credited" in the morning note. | `02` §1 |
| O20 | Key labels stop growing at 1.5× on the shared keypad (answered); needs a DECISIONS row and the check in X44. | Case study 33 |
| O21 | If the *Used* hallway test fails, a *Saved* row becomes tappable (rung 2). Pre-approve or not. | `03` §3 |

### 3.3 Build prerequisites (not owner decisions, but nothing ships without them)

| # | Item | Why | Owner agent |
|---|---|---|---|
| P1 | **Hold Home under every sheet opened from Home** (05-F1, confirmed in `07` §5): send `HomeTrayOpened` before and `HomeTrayClosed` after `route.completed`, in a `finally`, for the foot row, install line, due-soon row (*Used*) and the waiting-bill sheet. **Not** from the Settings door. `HomeBloc._trayOpen` becomes a counter. **This already breaks FR-HO-8 today** (a bill entered from Home drains under the scrim). | The exact bug D91 fixed for Add | Flutter/bloc agent; `design-platform` to review |
| P2 | **A pinned keypad body in the bill-sheet route** (X4, X5): keypad, action key and the typed amount stay on screen; title and slot scroll. It changes **every** keypad sheet in that route: *Put in extra*, *Money coming in*, *Bill amount*, and the bill sheet. Needs a way for `AdaptiveSplit` to pin the amount; posture-agnostic anchoring (X46). | The sheet needs it at 320×568, 412×400, landscape and tabletop (measured by `07`) | UI/platform |
| P3 | **Bottom inset** in the bill-sheet body: `MediaQuery.paddingOf(context).bottom`. *Save* ends at 895 of 915 today; a 3-button bar covers 28dp of it. | Pre-existing | UI/platform |
| P4 | **A home for the Settings-door snackbar and its Undo** (`07` §5): Home's host is under Settings and `SettingsPage` has no ledger Undo path. Recommended: a bloc inside the Settings route that owns the Undo (the `IncomeBloc` scope is the nearest). **Blocks the Settings door, not the Home door.** | `04` §5 step 3 assumes a snackbar that cannot appear | Bloc agent |
| P5 | **`Shake` under reduced motion:** the held ring and the spoken cap line (X14). Same fix for the Add tray. | `shake.dart` skips itself; haptic is the only signal | UI/a11y |
| P6 | **The 9-digit-cap message gap** in today's Add tray (SPEC FR-AD-2 says "head-shake and reject haptic" only). Report; fix with P5 if O11 is yes. | Pre-existing | UI |
| P7 | **`show` methods** for the Fix and *Used* sheets must copy `BillAmountSheet.show` (wait for a settled state, `BlocProvider.value`, close after), **not** `BillSheet.show`, which reads state once and loses the Undo when the user backs out during a write. | `07` §4 item 3 | Bloc agent |
| P8 | **Keypad state:** "empty" and "typed 0" are different (`02-F3`); the Add tray treats 0 as nothing. Spoken separately (`06` T3). | `04` §2, Q4 | Bloc agent |
| P9 | **`TodayBarPainter`** was built for a bite; a change of total (1,850 to 1,383) must interpolate segment boundaries (05-F5). Widget tests at both. | `05` §7 | UI |
| P10 | **Schema and backup:** hidden `not logged` category rows (BR-11 reserved name); `kind = used` plus a link column (not `recurring_id`, which is unique per date); `asked_on` for the missed-log line (not `quiet_on`); the install line's *seen* flag, reusing the income rule's `created_at` for the install day; backup version bump; restore and *Delete everything* (BR-16). | `02` §6, `yearly-costs/01` §8, `08` §8 | Data agent |
| P11 | **SPEC exclusions:** BR-17 *learned entries* must skip *Not logged* (a hidden-category entry would otherwise count as a learned day); BR-7, BR-8, BR-12 to BR-15 as listed in `02` §6; BR-15 gets two new goldens (the two facts clauses); FR-HO-4 *Not logged* and *Used* rows. | | Spec/data |
| P12 | **Rows:** reuse `entry_row.dart`'s `customSemanticsActions` so *Not logged* and *Used* can be deleted without a swipe (`06` K2); assert it in a test. | WCAG 2.5.1 | UI |
| P13 | **Chips:** check whether a Savings chip exists in Every entry today (`03` Q6); system categories (`saved`, `card_paid`, `not logged`) get none. | | UI |
| P14 | **Glyph:** a neutral glyph for the *Not logged* well and the Settings row (the sliders stand-in is a placeholder, mockup 41 problem 5), in Hugeicons or `HisaabGlyphs`. | | `design-system` |
| P15 | **Keypad label clamp at 1.5×** on the shared keypad, with tests at 2.0× on the tight layout. | O20 | UI |
| P16 | **`TestWindows`:** add split-screen (412×400, 412×300), book (673×841 with a vertical fold and a 40dp hinge variant) and tabletop (701×841); move `_tabletopFold` out of the Add tray test. | `07` §9 | Test agent |
| P17 | **Two-pane tab order:** a `FocusTraversalGroup` per pane (none exists in `lib/`). | `07` §7 | UI |
| P18 | **Install line source:** reuse the income rule's `created_at`; no new column. | `01` §3 | Data |
| P19 | **ARB:** every key in the deck with a `@description`; the spoken sentence forms (X28); the cap line (X14); keep `spentAndSaved` until the parts replace it. | Deck §2 to §7 | `design-content` + code |
| P20 | **Habits:** the carried habit shows the pill outside its window (FR-AD-10 AC-1 gains one clause); a pure `MissedLogDetector` with `FakeClock` tests. | `08` §8 | Habits agent |

### 3.4 Things that need the user test first

| # | Item | Test | What it changes |
|---|---|---|---|
| U1 | The page title and helper: V6 versus V1, V2 and the others | T3, T4 | The scope of the question (X24); if a buffer is common, the anchor or a cap on the *higher* branch (`01` §1.3) |
| U2 | Whether people count one number across accounts and cash | T3, T5 (private check) | One number or *Bank* and *Cash* fields (V5, a second round) |
| U3 | "Fix my number" and "Not logged" read cold | T2 (B1, B2) | Fallbacks "Correct today's number" and "Added to match" |
| U4 | Whether the preview is read in the right direction and without blame | T6 (B5, B7) | "about", the wording of line 2, the last-day copy |
| U5 | The guard question | T6 (B6) | Key order and the lock (X7); the threshold's usefulness |
| U6 | Settings group: *Money* versus *Your hisaab* | T8 tree test | X29 |
| U7 | Does the foot row get seen and is it read as a message? | T9 | A second door, or the install line only |
| U8 | The *Used* word and row meaning, and "set aside" | T2 (B8, B9, B11), T7 | `Used from savings` versus fallbacks; whether the sheet hint can go; rung 2 |
| U9 | "Divided by 12" | T2 (B10) | The caption |
| U10 | The missed-log line: tone, and whether it reads as an entry | T2 (B12), T10 | Line shape, the Food glyph in the well |
| U11 | The install line's meaning | T2 (B13) | Its words |
| U12 | The first-time smartphone user can do the sum | T3 with the right recruit (`06` G3) | Whether the 5-year-old bar is met |

## 4. Validation plan: one session per person

**Who runs it:** the owner, by hand, paper or phone cards (frames from mockups 41 to 43 and the copy deck). No build. The Mom Test: ask about the past; never explain a word before it is read; do not rank on opinions; write what people **did** apart from what they **said**; participant letter only; no real balances written; never ask for a screenshot of a banking app. All of study 34's consent and privacy rules apply.

**Sample:** 5 people (study 34's recruit: 3 to 4 UPI-first people with cash; at least one with two or more accounts; one on irregular income or mostly cash; one who prefers Hindi or does not know "budget"; one on a low-end Android; none who have seen the app). Add to the recruit: **at least two who have had a yearly cost** (insurance, fees), **at least one first-time smartphone user** (`06` G3) and **at least one who keeps money outside this month's pay** (a buffer). Three extra bystanders do **only T8** (the tree test, 2 minutes) so each tree variant gets 3 or 4. Five is low-to-medium confidence: it finds problems, it does not size them. A TalkBack run is separate (section 5).

**Order matters:** cold reads come before anything is explained; the interactive tasks come after. About **40 minutes** a person. If a session runs long, break after T5 and do T6 onwards within the same day.

| Step | Min | What | Source | Record | Pass mark |
|---|---|---|---|---|---|
| T0 Intro | 2 | "I'm testing an idea, not you." Consent; skip any question. | 34 | Consent | n/a |
| T1 Past behaviour | 6 | Last time they wanted to know how much they had; which app; any adding; cash; money not "theirs to spend"; **the last big once-a-year cost and how they paid** (moved here from 34 step 6, so the yearly cards are not primed). | 34 steps 1 and 6a | Accounts, cash, buffer, set-aside; yearly cost behaviour; whether an RD has left their account | Used to read T3 and T7 |
| T2 Blind read of words | 9 | Cards, one at a time, rotated across people. **B1** Home row *Fix my number* (and the Settings row). **B2** *Not logged · Spent ₹4,200*, alone, then with "Added when you fixed your number." **B8** the *Car insurance* saving with the key as each of *Used some of it / Paid from this / Spent from savings / I paid from it*, then the rows *Insurance · Used* and *Used from savings*. **B9** the over card's "used up" beside the *Used* row. **B10** "divided by 12" versus "a twelfth". **B11** *set aside*. **B12** the missed-log line A and B. **B13** the install line. | Deck §9 | Their own words, verbatim; right, partly right, wrong; any alarm or blame | **B1:** 4 of 5 read it as correcting the figure, not editing income or deleting; **B2:** 4 of 5 "not recorded", no blame, no failed payment; **B8:** *Used* not read as new spending or a claim; **B9:** not confused; **B10:** 4 of 5 divide; **B11:** read as money waiting; **B12:** no pressure felt, a "no" feels free; **B13:** read as an offer |
| T3 The read | 6 | Card 3 cold: "Say a number." Then "Tell me what you included." V1 first for everyone, then **two of V2 to V6** (V6 = `fixTitle` + `fixHelper`; V2 = V1 + "We'll take out your bills and savings"). Assign so **V6 and V2 are each seen by at least 3 people**, V3 to V5 by at least 2 (10 slots over 5 people). Add the probe for a card bill still owed. | 34 step 3; deck B3, B4 | Seconds to a number; asked "which one?"; what they counted; round or exact | **One number in under 20 s: 4 of 5. What they counted matches (no buffer, no older savings): 4 of 5.** |
| T4 The helper | 2 | "Leave out money from before this month" against "Leave out older savings": "What would you leave out?" | Deck B4 | The money they name | 4 of 5 name the right money |
| T5 Private check | 3 (optional) | They open their own banking app **privately** and tell only how far off they were (under ₹100, ₹100 to ₹1,000, over ₹1,000) and the direction. | 34 step 4 | Gap bucket; what was missed | **Within ₹1,000 or 5%: 4 of 5.** Mostly understated cash: add "about" and rerun with cash-heavy people |
| T6 Preview, guard, snackbar | 6 | **B5** the preview (less, more, "That matches"): "Say this back. Who is this telling off?" **B6** the guard with *No, some is older* and *Yes, add ₹30,000*: "What would each key do?" **B7** the snackbar and the ₹0 version. SEQ after T3 and after T6. | 34 step 5; deck B5 to B7 | Direction read right; blame; which key goes back | **4 of 5 right direction, none blamed; 4 of 5 know *No* goes back to typing; B7 read as the Home number changing; SEQ median 6 or more** |
| T7 *Used* task | 3 | Frame of the Savings list with "₹4,000 set aside": "You paid the insurer from the bank. Tell hisaab." (paper walk from mockup 42; start on the Home frame, not on the sheet.) | `03` study C | Where they tap; time | **4 of 5 reach *Used some of it* unaided in 60 s** |
| T8 Tree test | 2 | A text tree of Settings with the new row at the end of *Money* or under *Your hisaab* (between subjects). "The number on Home looks too high. Where would you go to fix it?" | `03` study A | First click, backtracks | **Variant wins at 80% first-click and 70% direct, or the higher variant if both fail; a tie keeps *Money* (`03`).** With 5 + 3 people each variant has 3 or 4: direction, not proof |
| T9 Foot row | 2 | Home frame with the row below the fold: "How would you correct a wrong number?" then "What is that row?" | `03` study D | Found it; what they call it | **3 of 5 find it; none call it a message** |
| T10 Missed-log recognition | 2 | Mockup 43 Home frame: "What is this? Is it one of your entries?" | Mockup 43 problem 1 | Misread as an entry or a bill | **No more than 1 of 5 read it as an entry or a bill** |
| T11 Close | 1 | "Anything you expected me to ask?" | 34 | Unprompted | n/a |

**What each outcome decides** (study 34's table, merged)

| Outcome | Decision |
|---|---|
| T3 passes for V6, nobody counts a buffer | Keep V6 and the guard; one number |
| V6 loses and V2 wins | Fall back to V2's title and helper; the scope sentence moves into the preview; re-read `02-F17` and `F18` (cards, savings) |
| Some say "which account?" or sum slowly, only bank and cash | Keep one number with a hint; round two with V5 (*Bank* and *Cash*, one *Fix it*) |
| Two or more would include a buffer or set-aside | The question must be scoped harder or the first fix sets an anchor; **do not post a *Got* for a buffer**; route to `design-ux` before anything else (study 34) |
| Step T5: mostly understated cash | "about" on every preview; rerun with cash-heavy people |
| B1 fails | Try "Correct today's number", or name the row by its question |
| B2 fails | "Added to match" |
| B8 picks "Spent from savings" | Add a line under the key saying it is not counted again |
| T7 under 4 of 5 | Rung 2: a tappable *Saved* row (O21) |
| T8 splits | Use the winner; tie keeps *Money* |
| T9 under 3 of 5 | Do not add a nudge (principle 48); keep the install line and Settings |
| T10 fails | Change the line's well (no category glyph) or its shape; re-test |
| Fewer than 3 of 5 manage T3 at all | Stop Fix my number as designed and return to the owner (study 34) |

## 5. Device checks (moto g45 with TalkBack, Switch Access, font and display size Largest)

Collected from `05` §5 and §9, `06` §8, `07` §10. None has been run. Each is a pass or fail; a failure is logged to the owner agent in brackets.

| # | Check | Pass | Source |
|---|---|---|---|
| D1 | **Guard focus (X7, X17):** after *Fix it* in S3, does TalkBack land on the question and say it once? No lost focus; *No* is first; a second tap within 300 ms does not post | Audible once; focus kept; the lock holds [UI/a11y] | `06` T1 |
| D2 | Slot cadence: type a 6-digit amount by touch with TalkBack | One short sentence per pause, not queued per digit [UI] | `06` T2 |
| D3 | Disabled *Fix it* hint; cap announcement; the *Not logged* sentence; focus after the line leaves | Heard as specified [UI] | `06` T4 to T6, T8 |
| D4 | 48dp hit area of the slot's *Try again* (a tap on the bottom 4dp) | Registers [UI] | `06` K1 |
| D5 | Switch Access can reach *Undo* in the 4 s, or delete from Every entry | Reachable [UI] | `06` K5 |
| D6 | **Sheet exit time against NFR-1's 400 ms** (drain begins at most 400 ms after the save) | At most 400 ms; otherwise release the hold at 90% of the exit (needs a DECISIONS row because D91 says "ends") [motion] | `05` §5 |
| D7 | Frame chart: a fix from the foot row (list shifting) and an Undo mid-roll | No dropped frames [UI] | `05` §9 |
| D8 | At 1280×800 the 650dp sheet over the hero's lower right | Hero figure not covered; else anchor over the secondary pane [platform] | `07` §5 |
| D9 | Tabletop and book placement; real nav-bar heights (3-button and gesture) against the inset fix | Sheet in the lower half and left sub-screen; *Save* clear of the bar [platform] | `07` §10 |
| D10 | A started-then-abandoned back gesture; and whether UI_DESIGN §10's "back swipe scales the tray down" is true for the Add tray | No change and no callback; correct the doc if false [platform] | `07` §4 |
| D11 | Hero off screen when a fix comes from the foot row | The snackbar carries the number; nothing scrolls [UI] | `05` §1 |
| D12 | **Remove animations** and reduced motion: the held ring, crossfades 150 ms, instant guard resize, no stamp replay | As `05` §6 and `06` §6 [motion] | `06` §6 |
| D13 | Font size and Display size at Largest (about 280dp wide): the pinned amount stays visible, keys clamp at 1.5×, a 48dp key does not grow | No overflow; amount visible above the keypad in every state [UI] | `06` §3; X44 |
| D14 | **A visible check of the hold (P1):** the sheet over Home, the ledger changes underneath | Home does not drain under the scrim; two overlapping holds keep it held until both close [bloc] | `07` §5 |
| D15 | The missed-log line on a cold start with habits loading late (`08` Q3) | Shows on the next evaluation point; no pop-in [habits] | `08` §7 |
| D16 | Dark theme: the guard keys, *All of it*, the held ring | Contrast per `06` §1 [UI] | `07` §9 |
| D17 | Low-end device (Android Go, 2 to 3 GB): the `IndexedStack` slot with nine states | No jank; use fades, not an `Opacity` over the stack [UI] | `07` §6 |
| D18 | Two-pane tab order | Home then Spends [UI] | `07` §7 |

## 6. Readiness verdict per feature

### Fix my number: **blocked by the user test**
- **Why blocked:** the one assumption that can break the feature, that people can state "this month's money" as one number, has no evidence (study 34 §C and `02` I-2, sev 4). The page's title, helper, the guard and the threshold all depend on T3, T4 and T5.
- **What can be written into SPEC now, after sign-off:** the accounting (BR-3 and BR-4 `F_t`; the *Not logged* hidden category; the exclusions in BR-5 to BR-8, BR-12 to BR-17), the edge cases, the entry points and the row shapes. The rule `H = remaining + B + R` stays unless the test says to anchor.
- **Design pass to run in parallel (not blocked):**
  1. Fold X1 to X12 into one revised `04`: full-width key; guard keys stacked with the input lock; shorter guard; clear after *No*; scrim = Back; no predictive-back promise; held ring for the cap.
  2. Redraw mockup 41 for X2, X3, X5, X11 and X43, and delete problem 4 (X31).
  3. Rename `E` (X34) and state that *Spent* excludes *Not logged* (X33).
  4. Add V6 and the card-bill probe to study 34's script (they are in the deck, not in the study).
- **Open owner items:** O1 to O4, O11, O12, O17, O18.

### Yearly costs with *Used*: **ready to write into SPEC after sign-off**, after a mechanical doc sync
- The accounting (a fourth kind that touches no BR-3 symbol), the worked example (arithmetic passes) and the edge cases U1 to U12 survived `03`, `05`, `06` and `07` unchanged.
- **Doc sync before writing** (no new design): the four strings (X26), the *Used* row shape (X27, X28), the Savings-list third line (X37), the pinned *Used* keypad with `00` and a full-width *Save* (X1, X5), the refusal ring (X14), *All of it* toggles (X19), and the Spends line (X32).
- **Not blocking, but test-gated:** the word *Used from savings* and the hint (T2 B8, T7). A change there changes ARB keys, not behaviour.
- **Open owner items:** O5 to O8, O21.
- **One condition:** P2 and P7 apply to its keypad too; the *Used* question lives in the saving's own sheet, so the pinned layout is a build prerequisite, not a design question.

### Missed-log line: **needs one more design pass** (small)
1. **Settle the evaluation rule** (X36): adopt 05-F7 in `08` §1 (evaluate at door-resume, the tray close only removes it, write *asked* only when visible).
2. **Decide late arrival** (`08` Q3, O16): measure how often habits load after Home's first frame; if often, either accept the miss or allow one 150 ms arrival in the first second.
3. **Fix the slot position** to fourth and the focus return (X35, X18), the hover outline to `ink2` (`06` C2), and the collapse token (`08` §9 says `standard`; a spring cannot drive an `AnimatedSize`: `05` §2 and §4).
4. **Look at the "reads as an entry" risk** (mockup 43 problem 1, T10) and whether two-pane Spends insights waiting while the line shows (`08` §3) is wanted (`07` §7).
- **Open owner items:** O14 to O16.

## 7. Fixes to other docs and mockups (listed, not made)

| Doc | Fix |
|---|---|
| `01-ux-flow.md` | W1 foot row is a text row (X30); W3 to W6 and §1.2 full-width key and clear after *No* (X1, X11); W6 keys stacked (X7); §5 copy per the deck (X21 to X23); §3 row 2 Settings group pending T8; rename `E` (X34) |
| `02-accounting-and-edge-cases.md` | Rename `E` (X34); add "*Spent* excludes *Not logged*" (X33); §1 table second line "Added when you fixed your number." (X22); add a worked example for the last day and for a user with both a fix and a yearly saving; edge cases F2 and F13 unchanged |
| `03-information-architecture.md` | §2.1 the nudge slot description (X31); §4.2 rows two lines (X27); §4.3 three parts (X32); §5 the saving row third line (X37); §1.2 slot order stays |
| `04-interaction.md` | §2 no 88dp cell; keys 56 and 48 (X1, X2); §3.2 no "do not force 150 ms" (X16); §4 guard: shorter sheet, input lock, scrim and swipe, clear digits, focus method (X7 to X11, X17); §5 step 3 haptic (X15); §7 debounce and spoken forms (X13); §9 full-width *Save*, `00`, *All of it* toggle and strings (X1, X19, X26); Q6 answered (X45); §1 and §8 tabletop and re-layout (X6, X46) |
| `05-motion.md` | §2 guard resize and "no resize" row (X8); §2 and §6 cap flash becomes the held ring (X14); 05-F6 settled (X10); §1 hold needs P1; F3 decided once (X20) |
| `06-accessibility-review.md` | S3 arithmetic after the owner's clamp (X44); §3.1 handle (X3); add X7 (the tap-through) to the guard section |
| `07-platform-review.md` | §3 "Compact, small" row at 320dp (X5); add the unmeasured key heights 56 and action 56 versus 60 (X2); nothing else |
| `yearly-costs/01-ux-flow.md` | §3.3 and §4.3 strings (X26); §4.7 *Used* row (X27); §4.6 Q3 decided (X32); wireframes use ₹12,000 (X42); Save in the shared keypad (X1) |
| `habits/08-missed-log-line.md` | §1 rule 2 "fourth" and evaluation points (X35, X36); §5 focus return and hover (X18); §9 collapse token |
| Copy deck `41-…-copy-deck.md` | §2 the key detail; §4 `entryUsed`, `notLoggedRowSpoken`, `entryUsedSpoken` (X27, X28); §5 `spendsPartUsed` dropped from the line (X32), spoken form; §3 `fixAction` budget text and R12 (X1); §3 the focus and cap keys (X14, X17); add a keyed cap line; §9 add T3 assignments; a `notLoggedRow` second line |
| Mockup 41 | Keys 56 / 48 and handle 48 recount (X2, X3); remove the kept-digit highlight and problem 10 (X11); guard option B (X8); delete problem 4 (X31); §8 two-pane and tabletop schematics (X6); §7 pinned amount at 320 (X4, X5); dock (X43); §6 three parts (X32) |
| Mockup 42 | Handle and the 534dp budget (X3); problem 1 ("fits at 1×" is false); frame 8's ₹4,000 (X42); Spends line without *Used* (X32); the refusal ring as a held state (X14); dock (X43) |
| Mockup 43 | "third" to fourth (X35); hover outline `ink2` (`06` C2); dock (X43); add the Back-collapses frame's token note |
| SPEC (after sign-off) | BR-3, BR-4, BR-5 to BR-8, BR-10 to BR-17; new FR for Fix my number; FR-HO-3, FR-HO-4, FR-SP-4a (three parts), FR-SP-6, FR-SE-1, FR-AD-2 (the cap), FR-AD-5 and E13 (the hold covers the bill-sheet route), FR-AD-10 AC-1; E-rows from `02` and `yearly-costs/01`; NFR-4, NFR-8 and E16 to E18 (a keypad sheet keeps the typed amount and its action key on screen at 320×568 and 412×400); glossary (*Fix my number*, *Not logged*, *Set aside*, *Used from savings*) |
| UI_DESIGN (after sign-off) | §5 sheets and rows; §6 motion paragraph; §7 haptics; §9 debounced live region, the key-label clamp and the held ring; §10 predictive-back sentence; §13 sheets sit in one sub-screen, pinned controls, bottom inset |
| DECISIONS (after sign-off, next free IDs) | Each owner-accepted item: the rule `H`; the hidden category; the guard and threshold; the container, pinned controls and the hold (D91 widened); full-width key and 56dp keys; clear after *No*; the shorter guard and the input lock; slot order and the "later lines never appear mid-view" rule; foot row and Settings group; yearly costs as a saving, *Used* as a fourth kind, three-part Spends line; key labels clamp at 1.5×; "later specialist wins" is not a decision, it is process |

## 8. Sign-off (2026-11-13): product decisions, delegated by the owner

The owner handed the product decisions to Claude acting as product manager ("be the product manager, think of it from the user's perspective, do what's best"). These calls are made from the user's side, and they resolve section 3. Section 1's resolutions (X1 to X47) are accepted as written.

### 8.1 Owner items

| # | Decision | Why, from the user's side |
|---|---|---|
| O1 | **Guard at 10% of `I`.** | It scales with any income and needs no setting. A small buffer that slips through is previewed and has Undo |
| O2 | **As recommended:** the *Not logged* part on the Spends line (Spent side only), plus Every entry and the export. A *Got* fix shows only in Every entry and the export | Keeps the line short. The fix stays findable |
| O3 | **Delete-and-redo is the edit.** | Two taps. Editing in the tray could turn a fix into "over today" |
| O4 | **No guard on a big *lower* gap.** | The preview says "₹45,000 less" in words before saving, and Undo reverts. A second question on every honest big correction punishes the person who forgot most |
| O5 | **Three parts on the Spends line** (*Spent · Saved · Not logged*). *Spent* excludes *Not logged* | Three parts fit one line on most phones, and *Used* is not spending |
| O6 | ***Used* on every saving** once something is set aside; the hint only on the three yearly chips | An RD can be broken early too. The hint only makes sense where a cost is expected |
| O7 | **Refuse digits past what is set aside.** The rest is added as a normal spend | One rule: you can't use money that isn't there |
| O8 | **No extra step when deleting a saving.** Its Undo says what stays | Deleting is rare. A step there is friction for nothing |
| O9 | **No hardware-keyboard mapping now.** | Out of scope. A later, separate keypad change |
| O10 | **Undo stays 4 s** (kept open under TalkBack, D105). Deleting from Every entry is the fallback | Consistent with every other Undo |
| O11 | **Yes:** the 9-digit cap gets a spoken line and a held ring, in the Add tray too | A silent reject fails users who can't feel the haptic |
| O12 | Not answered (needs the owner's own money). It doesn't block anything | — |

### 8.2 Defaults O13 to O21

| # | Decision |
|---|---|
| O13 | Accepted: no daily limit on fixes, no reminder on a yearly saving |
| O14 | Accepted: the install line waits in over states and in *No income* |
| O15 | Accepted: the saved-yesterday note doesn't silence the missed-log line |
| O16 | Accepted, with 05-F7: the line is evaluated at cold start and resume only, shows 90 minutes after the window, has no ×, shows once a day, and Back clears it. A cold start whose habits load late misses it for that open, with no pop-in |
| O17 | Accepted: full Indian grouping on the Fix sheet |
| O18 | Accepted: "hisaab thought ₹17,430." The ARB already starts sentences with lower-case "hisaab" ("hisaab adds most bills…") and never says "We" |
| O19 | Accepted: a fix dated yesterday is pool-side, never credited in the morning note |
| O20 | Accepted (owner): keypad key labels stop growing at 1.5× |
| O21 | **Not pre-approved.** Decide only if the *Used* hallway test fails |

### 8.3 The user test does not block the build

The owner can't spend time running five sessions before anything ships, and the app has no users yet. So:
- **All three features go into SPEC and get built**, with the copy deck's recommended wording (V6 title and helper).
- **The guard and Undo are the safety net** against the riskiest assumption (people typing a total that includes a buffer).
- **The section 4 session stays the plan to run before the Play release.** Its outcomes change ARB strings and, at most, the guard. Both are cheap after the build.

### 8.4 Build order

1. **Existing bugs first.** They hurt users today and are prerequisites for everything after:
   - P1, the hold on the bill-sheet route, with a counter;
   - P2, the pinned keypad body;
   - P3, the bottom inset;
   - P5, P6 and P15: the cap line, the held ring and the label clamp.
2. **Yearly costs with *Used*:** ready, and it removes the biggest predictable shock.
3. **The missed-log line,** after its small design pass (section 6).
4. **Fix my number,** the largest of the three.

## Source scope
`docs/design-research/case-studies/33-product-gap-analysis.md`, `34-fix-my-number-research.md`; `01` to `07` of this folder; `docs/features/yearly-costs/01-ux-flow.md`; `docs/features/habits/08-missed-log-line.md`; `docs/design/mockups/41-fix-my-number-copy-deck.md`, `41-fix-my-number.html`, `42-yearly-costs.html`, `43-missed-log-line.html`; SPEC BR-3, BR-7, FR-AD-2 to FR-AD-5, FR-AD-10, NFR-1, NFR-4; UI_DESIGN §3, §5, §13; `lib/home/presentation/pages/home_page.dart`, `lib/home/presentation/widgets/due_soon_row.dart`, `lib/core/widgets/keypad.dart` and the `keyHeight` call sites. No code was changed and nothing was run.
