# Fix my number: accounting, edge cases, evaluation and spec edits

> **Status: signed off 2026-11-13 (`08-design-qa-and-signoff.md` §8; X33, X34 and the owner items applied).** Continues `01-ux-flow.md` (the comparison rule `H`, the guard, the sheet). Nothing here is in SPEC or DECISIONS yet; SPEC wins once written. **Symbols (X34):** `H` ("held") is the expected-money figure, formerly `E`; `T` is the typed figure, formerly `X`. SPEC BR-7's `E` (days elapsed) and BR-8's `X` are unchanged. Free letters to be checked by a grep of SPEC before the rename is written in.

## 1. Accounting

**The entry.** One entry per fix, dated **today**, no date picker, noted "Not logged", in a **hidden system category** (as `saved` and `card_paid`, D120, D123): a *Spent* row when money is missing, a *Got* row when it is extra. The Add tray never lists them. The category name `not logged` joins the reserved names in BR-11 (a user's own category may not use it). Amount is the gap rounded to whole rupees (BR-10: no paise); a gap under ₹1 is "equal". Weekly pay (D26) can leave paise in `H`, which is why.

**It behaves like a bill on its day, never like today's spending.** A *Spent* fix is pool-side, `R_t`-style (BR-3 "one rule for everything a rule posts"):

```
P = I − K − B − S_prev − R_t − F_t          F_t = Spent "Not logged" dated t
I includes the Got "Not logged" dated in the cycle
S_today = typed Spent dated t, not rule-posted, not "Not logged"
```

| Symbol / rule | Effect of a fix |
|---|---|
| `I` | Got fix is in `I` (it is a *Got* dated in the cycle) |
| `F_t` (new) | Spent fix dated today sits here, so `A` is recomputed (as when a bill is entered today, BR-4) and the hero corrects at once. Tomorrow it is in `S_prev`, which is arithmetically identical |
| `S_today`, `overToday` | **Never** includes it. No "₹X over today" because of a fix |
| `S_prev` | Includes it from tomorrow (all *Spent* entries before `t`) |
| `K`, `B`, `R`, `Sv_*`, `R_t` | Untouched |
| `remaining`, `tomorrow` | Move with `P`: `remaining' = T − B − R` (proof in 01 §1.2) |
| BR-5 | By `remaining`. A fix can reach *Over for the cycle* only if the user really holds less than the bills and savings still to come, and the existing calm card says it. Never state 3 |
| BR-6, BR-6a | Not a bite, not in a day's bar. Back-rebuilt `A_d` for the dated day and after includes it as pool |
| BR-7 | `V_prev` excludes it (pace counts typed *Spent* only), so one big fix does not read as a fast pace; `remaining` still falls, so "spare" falls honestly |
| BR-8 | `S_yesterday` excludes it. `A_yesterday` is rebuilt **with** a fix dated yesterday as pool, so "today's `A` = `A_yesterday` + X ÷ D" still holds and the note neither blames nor credits a fix |
| BR-12, BR-13, BR-14 | Excluded from limits, *Where it went* bars, percentages and insights |
| BR-17 | **Explicit exclusion needed**: hidden-category entries still count as "days with a learned entry" for other habits, so a fix must not (add "and not a *Not logged* entry" to *learned entries*). It never forms or feeds a habit and never triggers the missed-log line |
| BR-9 | Not a rule's entry; no `recurring_id` |
| FR-WG (widget, tile) | The snapshot refreshes after the write like any entry; the widget shows the new hero |

**Visible, as the owner requires.**
| Place | Shows |
|---|---|
| Home Today list | "Not logged · ₹4,200", glyph, no bite, no tap, not in the header total; swipe deletes with Undo |
| Every entry | Same row, two lines: "Not logged · Spent" / "Not logged · Got", then the second line "Added when you fixed your number." (X22; "Added to match" is the blind-read fallback) |
| Spends, FR-SP-4a | A part on the existing line ("Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200"), only in a cycle that has one. **Three parts at most (O5, X32):** *Spent · Saved · Not logged*; *Used from savings* is not on this line (it shows in Every entry and on the Savings list). **The *Spent* figure excludes *Not logged*, as it excludes *Saved* (X33): the part is its own number and is not inside "Spent".** Parts appear only above ₹0 and wrap between parts. The part is the *Spent* side only; a *Got* fix shows in Every entry and the export (O2). Say so in SPEC FR-SP-4a and in the Ask AI facts clause |
| Ask AI and CSV | `kind` stays `spent`/`got`; category `not logged`; note "Not logged". The facts clause says the amount is money the user did not log item by item, so the AI neither reads it as one habit nor as a purchase (BR-15) |
| Backup | Travels as an ordinary entry in a hidden category (BR-16). No new table, no new `kind`; one or two hidden category rows and a migration |

Unlike *Used* (a fourth kind that touches no symbol), a fix **does** move the pool: its job is to change `P`. The two proposals share the hidden-category pattern only.

**Edit, delete, back-date, day 1.**
| Action | Rule |
|---|---|
| **Edit** | Not in the Add tray (it knows only *Spent* and *Got* in visible categories, and editing could turn the fix into a real spend and trigger "over today"). Tapping the row does nothing, as for *Saved*. To change it: swipe to delete (Undo) and fix again, 2 taps. The owner's "visible and editable" is met by delete-and-redo (O3). The row also exposes the delete as a custom semantics action for TalkBack and Switch Access (P12) |
| **Delete** | At once with Undo 4 s (BR-10); the number reverts exactly (computed, never stored) |
| **Back-date** | Not possible on the page. Ordinary entries back-dated later are normal: they lower `H` further, so see F11 |
| **Day 1 of a cycle** | `t = start`: `S_prev = 0`, the pay is posted by the engine. A fix dated that day is valid. The user's account holds last cycle's leftover, so a *higher* figure there is the buffer case, guarded (F8). A fix is never dated in the previous cycle |
| **Past cycles** | Their fix rows stay in their cycle in Spends and exports |

## 2. Edge cases (E-row style)
| # | Case | Result |
|---|---|---|
| F1 | `T = H` | "That matches. Nothing to fix." Key off; Back closes; nothing saved |
| F2 | Rounded answer within 50 of `H` | "That's close enough." Nothing saved. Stops ₹30 entries (unchanged by sign-off) |
| F3 | `T = 0` | Allowed: "I have none of it left". `gap = H`; hero ₹0 and *Over for the cycle* only when `T < B + R`. Typed 0 and empty are different keypad states (P8) |
| F4 | Lower, leaving less than the bills still to come | Saves; hero ₹0; the existing calm over card (FR-HO-5); preview says "short of what's still due". Informs, never blocks |
| F5 | Higher, gap ≤ `I ÷ 10` | Saves with *Fix it* |
| F6 | Higher, gap > `I ÷ 10` | *Fix it* opens the second question (stacked keys, *No* first, 300 ms input lock on both, X7); *Yes* posts, *No* returns to the keypad with the digits **cleared** and "Count only this month's money." (X11); leaving posts nothing. System back, Escape and the scrim = *No*; swipe and handle close the whole sheet (X9) |
| F7 | `H ≤ 0` (the month was already overspent) | Gap uses the unclamped `H`; the preview omits "hisaab thought ₹X" and says only "₹{gap} more". Rare |
| F8 | Day 1 / payday | See §1. The leftover is guarded on a large figure. If the pay **has not arrived** (hisaab posted it at midnight), a user who answers truthfully "0 of this month's" posts a huge *Spent*. Not guarded (O4): the preview states it in words, Undo reverts |
| F9 | Mid-cycle installer | Natural fit: type what is left of this month's pay; the lower branch posts the pre-install spending (01 §1.4 last row) |
| F10 | Last day (`D = 1`) | `A = P`; the fix takes the whole gap off today's hero; the preview says so ("Today takes all of it."). **Illustrative worked example (recompute and pin in SPEC with its own inputs):** `D = 1`, `P = 1,850` (so `A = 1,850`), ₹420 spent today, hero ₹1,430. User types `T = H − 500` ⇒ gap 500, `P = 1,350`, `A = 1,350`, hero `1,350 − 420 = 930`: today's number falls by exactly the gap (₹500), and the per-day clause is replaced by "Today takes all of it." |
| F11 | The user fixes, then logs the item they forgot | Double count (pool falls twice). Row text "Added when you fixed your number." is the cue; recovery is deleting the *Not logged* row. No clever matching (rejected: guesswork). Risk I-3 |
| F12 | Two fixes the same day | Allowed (owner: no limit). Each compares with the ledger as it is, so the second after the first reads "That matches." |
| F13 | Midnight or a recurring post while the sheet is open | The preview follows the live ledger. The save re-computes the gap inside its write: if it changed from what was shown it saves nothing, refreshes the preview and says "Things changed. Check the new amount." |
| F14 | Double tap on *Fix it* | `droppable()`; one entry. A second tap on *Fix it* that lands on *Yes* after the guard swap is blocked by the 300 ms input lock (X7); *droppable* alone would not stop it (a different event) |
| F15 | Failed write | Sheet stays, digits kept: "Couldn't save. Try again." |
| F16 | 9-digit cap | Digit refused, reject haptic; a **ring held on the amount until the next accepted key plus a one-shot polite line "That's the most you can type."** (X14, O11; also in the Add tray, P5/P6). No visible words. Under reduced motion `Shake` is skipped, so the ring and the spoken line carry it |
| F17 | Credit card in use | Card buys are counted when made, so the account is higher than `H` until the bill is paid. The user's honest figure reads "higher". Guard catches large gaps; small ones inflate the hero. Needs the user test (study 34); possible helper "after any card bill you still owe" |
| F18 | Logged a *Saved* entry but the money is still in the bank | Reads "higher" by that amount. The helper says leave out older savings; same residual risk as F17 |
| F19 | Payday rule changed (bridge cycle, BR-1) or weekly/month-end cycle | `H` uses the current cycle; wording "this month's" becomes "this week's" for a weekly cycle (as FR-HO-5) |
| F20 | *No income* state | No page, no foot row (BR-5 #1) |
| F21 | Restore, *Delete everything* | A fix restores with the backup; *Delete everything* removes it; the install-line *seen* flag restores or clears with them (BR-16) |
| F22 | Reduced motion, TalkBack, 1.5x text, two-pane | Hero reflow uses the usual spring (150ms crossfade if reduced); preview is a polite live region (debounced 1.2 s under TalkBack, short live text, X13), amounts spoken in words; slot never resizes between states (the whole sheet shortens once, for the guard, X8); key labels stop growing at 1.5x (O20); the sheet works at the `TestWindows` sizes with the amount and *Fix it* pinned (X4, X5) |
| F23 | Combined: a user with a yearly saving and a fix (X42 and 08 §2) | Both examples need SPEC rows. With `K = 1,000`: `P = 15,650`, `A = 1,738`, hero ₹1,318, `remaining = 15,230`, so `H = 15,230 + 1,200 = 16,430`. A *Used* entry moves none of `H`'s terms |

## 3. Error prevention and recovery
| Risk | Prevention or recovery |
|---|---|
| Typing a total instead of this month's | Title and helper scope it; the guard asks before a large *higher*; the preview shows its effect before saving (Norman: constraint plus visibility) |
| Wrong amount saved | Undo 4 s, then swipe-delete and fix again. No "Are you sure?" (reversible over confirm) |
| Shame | "Not logged" is the entry's word, "hisaab thought" the preview's; hisaab is the one that thought wrong. No count of fixes, no streak, no red, no "over today" |
| Becoming a crutch for logging | Visible in Spends and Ask AI; no hiding; no limit (owner) |
| Slip on the key | *Fix it* is off until a digit is typed and for equal or close; the guard keys are stacked 56dp, *No* first, with a 300 ms input lock after the swap so a second tap on *Fix it* cannot land on *Yes* (X7) |
| Add path | Untouched: the page is not the tray; no tap, field or order change in Add, keypad or dock |
| New setting | None |

## 4. Cognitive walkthrough (first-time user)
| Step | Know what to do? | See the control? | Link to the goal? | See progress? |
|---|---|---|---|---|
| Notice the number is too high | Weak: nothing prompts a check | Foot row is quiet, below the fold on a busy day (I-1) | "Fix my number" reads as what they want (to confirm in the blind read) | n/a |
| Open and type | Yes | Yes | Title scopes the question | Preview after the first digit |
| Read the preview | Yes if "less/more" is read right | Yes | Yes | Hero value in the snackbar |
| *Fix it* / Undo | Yes | Full width under the keypad, as *Next* in the Add tray | Yes | Hero reflows |

## 5. Issues (severity 0 to 4)
| # | Step | Problem | Heuristic | Sev | Fix |
|---|---|---|---|---|---|
| I-1 | Finding the door | Foot row is below the fold; no trigger except the install line | Recognition over recall (#6) | 3 | Settings fallback; read in the hallway test; no nudge (principle 48) |
| I-2 | The question | Users may type a total (buffer, card, older savings) | Match the real world (#2), error prevention (#5) | 4 | Scoped title, helper, guard on large higher, preview; **test V6 before build** |
| I-3 | After a fix | Logging the forgotten item later double counts | Error prevention (#5) | 3 | Row text, delete-and-Undo; accepted |
| I-4 | The 10% guard | An invented threshold; a ₹4,000 buffer slips through | Error prevention (#5) | 2 | Accepted (O1); preview and Undo |
| I-5 | "Not logged" | May read as an error or a failed payment | Match the real world (#2) | 2 | Blind read; fallback "Added to match" (study 34) |
| I-6 | Three-part Spends line | Noise | Aesthetic and minimalist (#8) | 1 | Parts appear only when present; *Used* kept off the line (O5) |
| I-7 | Late salary on payday | A big wrong *Spent* | Error prevention (#5) | 2 | Preview in words, Undo; no guard on a lower gap (O4) |
| I-8 | No edit | Delete and redo is 2 taps | User control (#3) | 1 | Accept |

## 6. Spec and decision edits needed (listed, not written)
| Doc | Change |
|---|---|
| SPEC BR-3, BR-4 | `F_t` term; `I` includes the *Got* fix; `S_today` excludes it; `H = remaining + B + R` defined (not `E`, X34); worked example from 01 §1.4, plus a last-day example (F10) and a combined fix-and-yearly-saving example (F23) |
| SPEC BR-5, BR-6a, BR-7, BR-8 | One-line notes: a fix is pool-side; excluded from `S_today`, `V_prev`, `S_yesterday`; included in `A_d` and `A_yesterday` as pool |
| SPEC BR-10 | A fix is never edited in the tray; deleted with Undo; dated today only |
| SPEC BR-11 | Reserved name `not logged`; hidden category rows |
| SPEC BR-12/13/14, BR-15, BR-16 | Exclusions; Ask AI facts clause; backup carries it |
| SPEC BR-17 | *Learned entries* excludes *Not logged* |
| SPEC new FR (Fix my number) | Entries (foot row, Settings row, one-time line), page states, preview both ways, "about", close, guard, snackbar, failure; ACs for each wireframe state |
| SPEC FR-HO-3 | Install line and slot order (waiting, due-soon, install, missed-log); FR-HO-4 *Not logged* row; FR-SP-4a *Not logged* as the third part, with *Spent* excluding it (X33) |
| SPEC FR-AD-2, FR-AD-5, E13 | The 9-digit cap: held ring and spoken line (X14); `success` timing with the visible change (X15); the hold covers the bill-sheet route (P1) |
| SPEC Q6 | Keep the answer; add "a one-time Home line points to Fix my number" |
| SPEC §5 | E-rows F1 to F22 |
| UI_DESIGN §5, §6, §7 | Page, foot row, install line, Today row; hero reflow; `success` haptic on save, `tick` on the row |
| DECISIONS (next free IDs) | (a) Fix my number compares with `H` and asks about this month's money. (b) Large *higher* gap asks a second question (threshold). (c) A fix is a hidden-category entry that is pool-side like a bill, never today's spend. (d) Excluded from habits, pace, note, insights; visible in Spends and Ask AI. (e) No edit, delete and redo. (f) One-time install line, Q6 stays closed |
| Schema | Hidden category rows and a migration; install-day source and a *seen* flag |
| Study 34 | Add variant V6 (the scoped title) to the script, and a "card bill owed" probe |

## 7. Open questions for the owner (all answered by 08 §8)
1. **Guard threshold:** 10% of `I`; a small buffer slipping through is accepted (O1).
2. **Edit:** delete-and-redo is the edit (O3).
3. **Late pay on payday (F8):** no guard on a big *lower* gap (O4).
4. **Spends line:** a *Not logged* part on the line, *Spent* side only; *Spent* excludes it (O2, O5, X33).
5. **Title:** the scoped "this month's money" (V6) is the working copy; the pre-release test may change the ARB strings (08 §8.3).

## Source scope
`docs/design-research/case-studies/33-product-gap-analysis.md`, `34-fix-my-number-research.md`, principles 86 to 90, SPEC BR-3, BR-4, BR-5, BR-7, BR-8, BR-10, BR-17, FR-AD-3, FR-HO-3 to 5, Q6, DECISIONS D119, D120, D123, `docs/features/yearly-costs/01-ux-flow.md`, `docs/features/habits/08-missed-log-line.md`. No code was read.
