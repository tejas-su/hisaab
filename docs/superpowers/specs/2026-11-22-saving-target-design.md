# Saving target: design

**Status:** proposal, 2026-11-22, revised after the owner's answers (section 12). Not yet in SPEC, UI_DESIGN, DECISIONS or code. One small new question remains (section 12, "Still open").
**Origin:** the owner was pitched a broad "Savings & Planning" module. Most of it is already covered; one small piece is built here.
**Research:** [case study 17, savings and RD](../../design-research/case-studies/17-savings-and-rd.md). Yearly costs: `docs/features/yearly-costs/01-ux-flow.md`.
**Next numbers (checked 2026-11-22):** D208 to D212 (D207 is the last), BR-23, E129 to E150, migration 007, backup schema 7, mockup 52. If parallel work takes any, renumber on merge.

## 1. Problem and job

**Job to be done.** "When I'm putting money into a saving for something (an RD for a phone, a chit, a year's insurance), I want to see how far along it is and roughly when it will be done, so I can keep going or change the monthly amount, without a second app or a goals screen."

**Who.** The same user as BR-19: someone with a monthly saving who thinks in "for what, how much, by when". Evidence it is real: the pitch itself; D120's rejected option C ("savings pots with targets") was deferred, not refused, and case study 17 shows Copilot, Monzo and Simplifi all pair a total with an optional goal. Evidence it is small: the app already answers "how much is set aside" (BR-19); only "how much more, and when" is missing.

**Already covered, so not rebuilt:**

| Pitched | Where it already is |
|---|---|
| Savings goals | A saving has a free name and a monthly amount (D120). |
| Emergency fund | Name a saving "Emergency". No preset: D120's name pills stay RD, SIP, Gold scheme, Chit, then three yearly ones (AC-Y1), and the owner chose no suggested names. |
| Purchase planning | A saving with a name, plus Ask AI's *Can I afford…* own question. |
| Yearly costs | D174 (a twelfth a month), D175 (*Used*), BR-19. |
| Goal completion estimate | **Built here**, as a line on the saving, not a screen. |
| What-if simulations | **Rejected** (section 10). |
| A Goals screen or dashboard | **Rejected** (section 10). |

**Riskiest assumption.** That "Saving up to" and "done by May 2027" read at once to someone who never opened the sheet (section 11).

## 2. The proposal in one paragraph

A saving gets one optional number, *Saving up to*, set from a row in the saving's sheet after it exists. It touches no BR-3 symbol, so the hero, Day Blocks and the Add flow are untouched. The Savings list's third line (AC-Y3) says how far along it is and when it will be done, in words, and "reached" in words when set aside meets it. Reaching it never stops the saving. **Home says "reached" once, in the existing nudge slot (FR-HO-3), on one day, with no new Home element.** The Ask AI export carries the target and the estimate.

## 3. The journey

Money apps cause anxiety, so each step names the feeling we want.

1. **Discover.** Nothing changes on Home or in Add. A user opens Settings > Savings, taps a saving. The sheet (AC-Y5) shows a new row at the end of its rows: *Saving up to · Not set*. Feeling: curious, no pressure; it is a row like the others.
2. **Set.** Tap the row. The question "How much are you saving up to?" opens inside the sheet on the shared keypad (AC-3 pattern), empty. As digits are typed the slot says "At ₹5,000 a month, done by May 2027." The line under it is the existing "Your daily number doesn't change." Save. Back at the sheet the row flashes and the footer reads "Changed." Feeling: a plain answer, not a promise.
3. **See.** The saving's list row third line reads "₹18,000 set aside · done by May 2027". Nothing else on the app changes.
4. **Daily loop.** Untouched while a target is being worked toward: the estimate is not on Home.
5. **Payday and put-in days.** The engine posts the put-in (BR-9); set aside rises; the estimate shortens by a month when a full amount went in. The list is current the next time Settings opens.
6. **Reached.** When set aside is at least the target, the list line reads "₹50,000 set aside · reached ₹50,000". The first time Home is opened with that true, the nudge slot says "Insurance reached ₹12,000." for the rest of that day (section 4a); tapping it opens the saving's sheet. It is only words: the saving keeps putting in and today's share does not change (D209, D210). Feeling: quiet satisfaction; no confetti, no animation, no notification, no colour.
7. **Used some of it.** Set aside falls (BR-19). If it falls below the target the line returns to an estimate without comment. For a yearly cost this is exactly right: pay the premium, and the line starts counting the next year.
8. **Change the monthly amount.** The estimate is recomputed from the next put-in. Set aside is unchanged.
9. **Clear it.** *Clear*, a 48dp chip beside the amount in the question, removes the target. The row goes back to *Not set*.
10. **Delete the saving.** The target goes with the rule; Undo (4 s) restores it, because it lives on the rule's row (section 6).
11. **Ask AI.** *Where can I save?* sees the target and estimate (section 8).

**Empty, error and recovery states.**
- No savings: nothing to show; unchanged.
- A saving with no target: unchanged from today.
- Failed save: the question stays with "Couldn't save. Try again." (AC-7 pattern).
- Wrong number: *Clear*, or type a new one; the first key replaces the old value (FR-AD-8).
- First run: no target is ever asked for. *Add a saving* stays the three questions (name, amount, day).

## 4. Exact behaviour (proposed BR-23)

### Definitions

- `T`: the target in whole rupees, set per saving, or none. A saving is a *Saved* rule in `recurring` (BR-9).
- `S`: that saving's set aside (BR-19): `Σ Saved entries posted by its rule − Σ Used entries with its saving_id`, floored at ₹0, computed and never stored.
- `M`: the rule's amount per put-in, at least ₹1.
- `next_due`: the rule's next put-in date. After the engine's run on start and resume it is after today; if the list is read before that run, the first put-in counted is still `next_due`, and `S` does not hold it yet, so the figures agree.

### Formula

```
gap = T − S
if gap ≤ 0:            state = reached
else:
  n = ceil(gap / M)                       // put-ins still needed, integer paise arithmetic
  if n > 120:          state = far        // "over 10 years to go"
  else:                d_n = next_due + (n − 1) months, clamped (BR-1);  state = estimate(d_n)
```

`T` and `S` are never compared with the hero, `P`, `A`, `K`, `remaining` or any BR-4 to BR-8 symbol. **A target moves no number.**

### What "done by March" means against pay cycles

A saving's put-ins are the rule's own monthly dates (BR-9: "on the 5th", clamped to month end), not pay-cycle dates, so a pay cycle that starts on the 4th never enters the estimate. "Done by {Mon}" names the calendar month of the put-in that brings `S` to `T`, that is `d_n`. Display:

- Month as `MMM` (the footer's "since Nov" style); with the year when `d_n`'s year differs from today's year (`Clock`): "done by Mar" in 2027 if today is in 2027, "done by Mar 2027" if today is in 2026.
- A saving on the 31st lands on the last day of shorter months (BR-1 clamp, `PeriodCalculator`); the month named is unchanged by the clamp.
- A put-in on today's date that the engine has posted is already in `S`.

### Display states (the third line of the list row, extends AC-Y3)

| State | Line |
|---|---|
| No target | unchanged: "{amount} set aside" only above ₹0 |
| `S > 0`, estimate | "₹18,000 set aside · done by May 2027" |
| `S = 0`, estimate | "Saving up to ₹50,000 · done by May 2027" |
| reached | "₹50,000 set aside · reached ₹50,000" |
| far | "₹500 set aside · over 10 years to go" ("Saving up to ₹X · over 10 years to go" when `S = 0`) |

The line wraps to two lines at large text (never ellipsised); the row grows from about 84dp as needed.

### Worked examples

**A. SPEC's *Insurance* (BR-19):** `I = 45,000`, `B = 1,200`, `S_prev = 27,150`, cycle 4 Oct to 3 Nov, `t` = 26 Oct, `D = 9`, ₹420 spent today. ₹1,000 on the 5th, put in 12 times; `M = 1,000`; `next_due` 5 Nov 2026. The owner sets `T = 12,000`.

| Step | `S` | Row line | Hero | `P` | `remaining` |
|---|---|---|---|---|---|
| Target set | 12,000 | "₹12,000 set aside · reached ₹12,000" | ₹1,318 | 15,650 | 15,230 |
| *Used* ₹5,000 | 7,000 | `gap = 5,000`, `n = 5`, `d_5` = 5 Mar 2027: "₹7,000 set aside · done by Mar 2027" | ₹1,318 | 15,650 | 15,230 |
| *Used* the rest (₹7,000) | 0 | `gap = 12,000`, `n = 12`, `d_12` = 5 Oct 2027: "Saving up to ₹12,000 · done by Oct 2027" | ₹1,318 | 15,650 | 15,230 |

The hero is ₹1,318 and `remaining` ₹15,230 at every step: neither the target nor the *Used* entry moves a BR-3 symbol (BR-19). (Reached, then falling below on *Used*, then restarting is the yearly-cost cycle working as designed.)

**B. SPEC's RD (BR-15 sample): ₹5,000 on the 10th, same date and cycle.** `next_due` 10 Nov 2026, `S = 18,000`, `T = 50,000`: `gap = 32,000`, `n = ceil(6.4) = 7`, `d_7` = 10 May 2027. Row "₹18,000 set aside · done by May 2027"; the sheet slot "At ₹5,000 a month, done by May 2027." Change `M` to ₹4,000: `n = 8`, `d_8` = 10 Jun 2027. Change the day to the 20th (D34): the month stays May 2027 if `next_due` is now 20 Nov. Hero ₹1,318 throughout.

## 4a. The reached line on Home (owner decision 4; amends D174)

The one place Home mentions a target. It reuses the nudge slot (FR-HO-3): no new Home element, no new tap, no second line.

**Slot order** becomes: a bill waiting for its amount, the due-soon nudge, **the reached line**, the install line, the missed-log line. Waiting and due-soon are act lines, so they stay first; the reached line is news, so it outranks the one-time install pointer and the missed-log question.

**The line.** "{name} reached ₹{target}." ("Insurance reached ₹12,000."). Working copy; `design-content` refines it (no banned words). A `sunk` row at least 56dp tall in the due-soon row's shape: the saving's piggy-bank glyph in a `surface` well, the sentence (the name is never cut), a chevron. No amount other than the target, no second line, no ×, no marigold, no green, no animation beyond the slot's normal arrival, no haptic, no notification (D174 still holds for notifications).

**Tap.** Opens that saving's sheet over Home, exactly as the due-soon row does for a saving ("Opens the saving."). Why: it is the simplest consistent option, it reuses an existing door, and the sheet is where the target lives, so a user who wants to raise it or clear it is one tap away. Tapping neither dismisses the line nor writes anything.

**When it shows.** The whole of one day, decided at an *evaluation point* only (D170: a cold start, a resume, or the resume a door-opened tray causes), so it is in Home's first frame or waits, with no pop-in. A user's own act can make it leave, never appear, so closing a sheet never brings it in behind it. It waits (not lost) in an over state and in *No income*, as the missed-log line does, so "reached" never lands next to "over today".

**Stored state, so once survives restarts.** Two nullable columns on the saving's `recurring` row (section 6):
- `target_reached_for`: the target value (paise) the line was last shown for.
- `target_reached_on`: the local date `YYYY-MM-DD` it was shown.

**Pending** means: the saving is active, has a target `T`, `S ≥ T`, and `target_reached_for ≠ T`. At an evaluation point the first pending saving (ordered as the due-soon row's tie-break: the rule saved first) holds the line when no waiting or due-soon line does. **It is written the moment the line is on screen with Home visible and no tray or sheet over it** (as the install line's *seen* flag, FR-HO-3 AC-2, and `asked_on`): `target_reached_for = T`, `target_reached_on = today`. Until then it stays pending, so a day when a bill line holds the slot loses nothing: the line comes the next day instead.

**Shown** means `target_reached_on = today` and `target_reached_for = T` and `S ≥ T`. So the line stays the whole day through resumes, goes at midnight (its date is no longer today), and also goes if `S` drops below `T` the same day (a *Used* entry), since "reached" would no longer be true. It never returns for the same `T`.

**Day rules.**
- The day it "first reaches": the first evaluation point at which `S ≥ T` is seen, not the put-in's date. After days away, a catch-up put-in (BR-9) that reaches it shows on the first open, which is when the user learns it.
- **Target set while already reached** (including edited down to or below `S`): it is pending, so the line shows at the next evaluation point that day (a return from Settings to Home is not one, so a same-session set shows after the next resume, or the next day). Owner's lean was yes; shown. It may feel odd to be told what you just typed, which is why it is plain text and gone tomorrow (section 12, still open).
- **Raising the target** and reaching it again: `T` differs from `target_reached_for`, so it is pending again and shows once more.
- ***Used* drops `S` below `T`, then it reaches the same `T` again:** no repeat (`target_reached_for = T`).
- ***Clear*** removes the target and both columns' values, so setting a target later, even the same number, is a new target.
- **Two savings pending on the same day:** one line only, the first (rule saved first). The other stays pending and shows the next day it is not held back. Never a combined line: it needs more copy and a longer row, and one line a day matches the slot's one-line rule.
- **The saving is deleted on the day:** the rule is inactive, so the line leaves at once (Home reloads on the next evaluation point or change); Undo (4 s) restores it with its columns, so the line is as it was.
- **Backup and restore** carry both columns; a restored file shows a line again only when it is pending by the rules above.

## 5. Edge cases (proposed E129 onward)

| ID | Situation | Behaviour |
|---|---|---|
| E129 | `T ≤ S` when set (including `T` below what is already set aside) | Allowed and saved. Row reads "reached"; the sheet slot while typing says "You've already set aside that much." Never refused: the user may only want to say "this one is done" |
| E130 | `T` edited below `S` later | Same as E129: reached |
| E131 | `T` edited above `S` after reached | The line returns to an estimate |
| E132 | `T` = ₹0, blank, or only a clear | ₹0 is refused with a shake (the keypad's rule, FR-KS-2); blank does nothing; *Clear* removes the target |
| E133 | `T` over the keypad's 9-digit cap | The keypad refuses the digit (FR-KS-2, D184) |
| E134 | Monthly amount changed | Estimate recomputed from the next put-in; `S` unchanged; past put-ins are not rewritten (BR-9) |
| E135 | Put-in day changed (D34) | `next_due` moves, so the month named may move; no put-in is posted twice |
| E136 | *Used* lowers `S` after reaching `T` | The line goes back to an estimate; no message. For a yearly cost this restarts the count |
| E137 | `S` floored at ₹0 (a used amount above put-ins by an edited-away entry) | `gap = T`; as `S = 0` |
| E138 | `n` over 120 | "over 10 years to go"; no date is computed, so no overflow |
| E139 | Saving deleted | The target goes with it; Undo (4 s) brings it back; past entries stay (BR-19). A deleted saving is out of the list and the export |
| E140 | Backup and restore | The column is carried. An older file (schema 6) restores with no targets |
| E141 | *Put in extra* | Belongs to no saving (BR-19), so it never moves `S` and never counts toward `T` |
| E142 | Month change and `Clock` | A line saying "done by Dec" in December reads "done by Jan 2027" next month only after `S` and `next_due` change; the year suffix follows today's year |
| E143 | A saving started today with no put-in | `S = 0`; the line reads "Saving up to ₹X · done by {Mon}" counted from `next_due` |
| E144 | Two savings reach their targets before the same evaluation point | One Home line, for the rule saved first; the other stays pending and shows the next day it is not held back (section 4a) |
| E145 | *Used* drops `S` below `T` after the line was shown, then `S` reaches the same `T` | No second line (`target_reached_for = T`) |
| E146 | A target is raised and reached again | `T` differs from `target_reached_for`, so the line shows once more |
| E147 | A target is set or edited so that `S ≥ T` already | Pending: the line shows at the next evaluation point (same day if the user resumes, else the next day), once |
| E148 | The saving is deleted on the day the line shows | The line leaves; Undo restores it and its state |
| E149 | A waiting bill, the due-soon nudge, an over state or *No income* holds the slot | The reached line waits unwritten and shows on the first later day it can; nothing is lost |
| E150 | `S` drops below `T` (a *Used* entry) while the line shows the same day | The line leaves at the next evaluation point, because "reached" is no longer true |

## 6. Schema impact

- Three nullable columns on `recurring`, all for `kind = saved` only (the domain never writes them on other kinds):
  - `target_minor INTEGER`: `NULL` means no target. Paise like `amount_minor`, whole rupees only in practice. `CHECK (target_minor IS NULL OR target_minor > 0)`.
  - `target_reached_for INTEGER`: the target value the Home reached line was last shown for (section 4a); `NULL` when never.
  - `target_reached_on TEXT`: the local date `YYYY-MM-DD` that line was shown; `NULL` when never.
- **Migration 007**, `lib/core/db/migrations/migration_007_saving_target.dart`: three additive `ALTER TABLE recurring ADD COLUMN` statements (no rebuild needed; `CHECK` with a `NULL` default is allowed). `AppDatabase.schemaVersion` becomes 7 (it counts `migrations`). Add `RecurringColumns.targetMinor`, `.targetReachedFor` and `.targetReachedOn`, each with a dartdoc citing BR-23.
- **Backup schema version 7** (BR-16 today says 6, `nudge_state`). A schema-6 file restores with all three null. Dates and amounts only, no personal text, so the privacy rules hold.
- Never stored: `S`, the estimate, the "reached" state itself (it is `S ≥ T`); only the fact that the Home line was shown for a target is stored.
- Rejected alternatives: a `saving_targets` table (a join for one nullable value, and harder to Undo-delete with the rule); a `suggestion_state`-style table keyed by saving (a new table, a new backup clause and a new delete path for two values that belong to one rule's row).

## 7. Screens touched

| Screen | Change |
|---|---|
| Settings > Savings list | Third line forms in section 4; footer unchanged |
| Saving's sheet | One new row *Saving up to*, last of the rows; a question inside the sheet; *Clear* chip. The slip's "{amount} set aside" line gains the estimate |
| Add a saving (three questions) | **Unchanged.** The target is set afterwards, from the sheet, so adding a saving stays three questions |
| Home, nudge slot (FR-HO-3) | One new slot line, "{name} reached ₹{target}.", once per target (section 4a). Reuses the due-soon row's shape; no new Home element |
| Add tray, hero, Day Blocks, Spends | **Unchanged** |
| Ask AI | The export gains one sentence and one explaining line when a target exists |

## 8. Ask AI export (amends BR-15; D211)

Both lines are added only when at least one active saving has a target, so every other export stays byte-identical, as D188 did. The numbers are the list's own, never recomputed in `PromptBuilder` (D79).

- **Facts**, a sentence right after the savings clause. Dates are ISO as elsewhere in the export:
  - estimate: `Saving up to a target: RD has ₹18,000 set aside of ₹50,000 and, at ₹5,000 a month, would be done by 2027-05-10.`
  - reached: `Saving up to a target: Insurance has ₹12,000 set aside, which reaches its ₹12,000 target, and still puts in ₹1,000 a month.`
  - far: `... at ₹500 a month, is more than 10 years away.`
  - several: one sentence each, in the savings clause's order (soonest first).
- **Explaining line**, after the facts, with D188's other lines: `A saving with a target is something the user chose to save up to. The date is an estimate at the current monthly amount, and reaching it does not stop the saving. Treat it as a goal, not as spending.`
- Saving names are names the user typed; they are listed as today, and "Leave out my notes" does not hide them (unchanged).
- One new golden: a target estimate, a reached one, and the explaining line. Existing goldens must not change.

## 9. Proposed doc text

**BR-23 Saving target (D208 to D212)** (new; place after BR-22)
- An optional `T` on a saving (a *Saved* rule). It touches no BR-3 symbol and appears only in the saving's sheet, the Savings list, the Ask AI export and, once, Home's nudge slot (FR-HO-3).
- **Reached line (D212):** a saving is *pending* when it is active, has `T`, `S ≥ T` and `target_reached_for ≠ T`. The first pending saving (rule saved first) holds the Home slot line when no higher line does; the moment it is on screen with Home visible and no tray or sheet over it, `target_reached_for = T` and `target_reached_on = today` are written. It shows while `target_reached_on = today` and `S ≥ T`, goes at midnight, never returns for the same `T`, and is cleared with the target (section 4a).
- `gap = T − S`; `reached` when `gap ≤ 0`; otherwise `n = ceil(gap / M)` and the estimate is the calendar month of the n-th put-in from `next_due` (BR-9), shown `MMM` with the year when it is not this year; `n > 120` reads "over 10 years to go".
- Reaching `T` only says so in words. It does not stop, pause or change the saving, and moves no number.
- Set aside follows BR-19, so a *Used* entry that lowers it brings the estimate back.
- Worked examples A and B of section 4.

**FR-SE-1, Savings, new acceptance criteria**
- **AC-T1** The saving's sheet has a last row *Saving up to*, answered "Not set" or "₹50,000". The Add flow for a saving stays three questions.
- **AC-T2** The row opens a question inside the sheet, "How much are you saving up to?", the shared pinned keypad with `00`, the amount empty or prefilled with the current target (the first key replaces it, FR-AD-8), and *Save*. *Clear* is a 48dp chip beside the amount (below it at large text), shown only when a target is set.
- **AC-T3** The slot has two fixed lines: the estimate "At ₹5,000 a month, done by May 2027." updating as digits are typed ("You've already set aside that much." when `T ≤ S`), and always "Your daily number doesn't change.". A polite live region (FR-KS-4).
- **AC-T4** ₹0 is refused with a shake; the 9-digit cap applies; a failed save keeps the question with "Couldn't save. Try again."; saving an unchanged target writes nothing. *Save* and *Clear* return to the sheet, flash the row, and the footer reads "Changed." for 2.4 s.
- **AC-T5** The list's third line follows the section 4 table, on every saving with a target. A saving with no target is unchanged. The line wraps at large text.
- **AC-T6** The sheet slip's "{amount} set aside" line takes the same text as the list row.
- **AC-T7** TalkBack reads the row as "Change saving up to, ₹50,000" ("Set saving up to, not set"), and the list row's line as one sentence.
- **AC-T8** The footer's two lines (AC-Y4) are unchanged.

**FR-HO-3, the nudge slot (amended, D212)**
- The lead sentence becomes "the first that applies of **five**: a bill **waiting**, the due-soon nudge, the **reached line**, the install line, the missed-log line, else nothing". The install line's and the missed-log line's AC-1 "no waiting, due-soon or install line holds the slot" gains "or reached" where it applies (the missed-log line yields to it; the install line yields to it).
- **Reached line** (D212): "{name} reached ₹{target}." in the due-soon row's shape, a `sunk` row at least 56dp tall: the saving's glyph in a `surface` well, the sentence, a chevron.
  - **AC-R1** It shows when a saving is pending (BR-23) at an evaluation point (D170), Home is ready, not *No income* and not in an over state, and no waiting or due-soon line holds the slot. In an over state and in *No income* it waits.
  - **AC-R2** *Shown* is written (`target_reached_for`, `target_reached_on`) only when the line is on screen with Home visible and no tray or sheet over it. A line drawn under a door-opened tray is not written.
  - **AC-R3** It stays the whole day through resumes, leaves at midnight, leaves at the next evaluation point if the saving's set aside falls below its target, and never returns for the same target. Raising the target and reaching it again shows it once more.
  - **AC-R4** With two pending savings, one line: the rule saved first. The other shows the next day it is not held back.
  - **AC-R5** A tap fires `tick` and opens that saving's sheet over Home (FR-SE-1), as the due-soon row does for a saving. A tap does not remove the line or write anything.
  - **AC-R6** No amount other than the target, no ×, no haptic, no notification, no marigold, no animation beyond the slot's normal arrival.
  - **AC-R7** TalkBack reads one button, "Insurance reached ₹12,000.", then "Opens the saving." It is not a live region and announces nothing on appearing or leaving.

**BR-9**: add one clause to "Editing a rule": a saving's target is a rule attribute, kept on delete's Undo and never posted.
**BR-15**: sections 8's two lines in 3. and the golden.
**BR-16**: schema version 7; an older file restores with no targets.
**Glossary**: *Saving up to*: an optional amount a saving is working toward; never a balance (BR-23).

**UI_DESIGN**: the Settings saving sheet and list row sections: the row, the question, *Clear*, and the third-line forms; copy table; mockup 52.

## 10. What we are not doing, and why

- **What-if simulations.** A second hypothetical number beside the hero competes with the one answer the app gives (UI_DESIGN §2: less but better). Ask AI already answers what-ifs, which is why it exists. The one live line in the question (AC-T3) only echoes what Save will record; it has no second input and no comparison.
- **A Goals screen or dashboard.** A new screen and a second place for money, against "no new screen" and one-thing-per-screen. The Savings list is the goals list.
- **An Emergency (or any) preset or suggested names.** The owner's decision 2; users can already name a saving anything.
- **Auto-stop at the target.** The owner's decision 1: stopping a saving changes today's share and the days after it without being asked. The user stops it themselves by deleting the saving.
- **A target in the three-question Add flow.** It would add a fourth question to a path that must stay three taps; the target is set once the saving exists.
- **A "set aside of target" progress bar or percentage.** A bar needs a colour or a fill to mean progress; "one colour one meaning" and "no red or green". The words carry it.
- **A notification on reaching it.** D174 stands for notifications. Engagement nags are out; the only nudge is "spend less / save".
- **A Home banner, card or celebration on reaching it.** The owner allows only one quiet line in the existing nudge slot, once (D212). No new Home element, no animation, no colour, no repeat.
- **A "paid for the year" state for yearly costs.** There is no flag distinguishing a yearly saving from any other (the pills only fill the name), so a special case would need new stored state. The uniform rule gives the right answer anyway (E136).

### Decisions to log (proposed DECISIONS rows)

| ID | Date | Decision | Why | Alternatives |
|---|---|---|---|---|
| D208 | 2026-11-22 | **What-if simulations, a separate Goals screen or dashboard, and an *Emergency* preset are rejected** (owner, from a "Savings & Planning" pitch). Savings goals, emergency fund and purchase planning are covered by D120, D174, D175 and BR-19; completion estimates are built as a line on the saving (D209) | A second hypothetical number competes with the hero, a Goals screen is a second place for money, and Ask AI already covers what-ifs. No suggested names, so no preset | A Goals tab; a simulator; a preset *Emergency* saving |
| D209 | 2026-11-22 | **A saving may have an optional *Saving up to* amount, with a done-by estimate** (new BR-23; FR-SE-1 AC-T1 to AC-T8; amends BR-9, BR-15, BR-16; schema v7, migration 007, `recurring.target_minor`; the Home line is D212). `n = ceil((T − S) / M)`; "done by" is the calendar month of the n-th put-in from `next_due`, never a pay-cycle date; beyond 120 put-ins it reads "over 10 years to go". Set from the saving's sheet only, so adding a saving stays three questions. Offered on every saving, yearly costs included: *Used* lowers set aside, so the estimate restarts by itself. Never stored: set aside, the estimate, "reached" | Answers "how far and when" without a screen and moves no BR-3 symbol. One uniform rule avoids a stored yearly flag. The put-in dates are the saving's own, so pay cycles never matter | A target in the Add questions; a `saving_targets` table; a target only for the three yearly pills; a progress bar; D120's option C (pots with targets) |
| D210 | 2026-11-22 | **Reaching the target only says so in words; it never stops or pauses the saving** (owner decision 1; BR-23). The list line reads "reached ₹50,000"; Home says it once (D212). No notification | Stopping would change today's share without being asked; the user remains in charge by deleting the saving | Auto-stop; a "Stop saving?" sheet on reaching it |
| D212 | 2026-11-22 | **Reaching a target shows one quiet line in Home's nudge slot, once per target** (owner decision 4; amends D174's "never a Home banner or notification for savings": the notification half stands; new BR-23 reached line, FR-HO-3, FR-HO-3 AC-R1 to AC-R7; schema v7 `target_reached_for`, `target_reached_on`). "{name} reached ₹{target}." for the rest of the day it is first on screen; slot order is waiting, due-soon, **reached**, install, missed-log; decided at evaluation points (D170), written when seen; tap opens the saving's sheet (as the due-soon row does); waits in an over state and in *No income*; one line a day, the rule saved first; raising the target shows it again, a *Used* dip and re-reach of the same target does not | The owner wants Home to say it. Using the existing slot adds no Home element, and "once" with stored state is not a nag. The columns sit on the rule's row so delete's Undo, backup and restore carry them with no new table | A new Home card or banner; a notification; showing on every open; a combined line for two savings; a `suggestion_state`-style table |
| D211 | 2026-11-22 | **The target and its estimate are in the Ask AI export** (BR-15; owner decision 3): one facts sentence per saving with a target, plus one fixed explaining line, only when one exists, with one new golden | *Where can I save?* can reason about what the user is already saving toward and not suggest cutting it blindly. The export stays the only data that leaves, user-triggered and previewed | Leaving the target out; hiding it under *Leave out my notes* |

## 11. Risks and validation

| Risk | Cheapest test |
|---|---|
| "Saving up to" and "done by May 2027" are not understood without teaching | **Blind read** of mockup 52 with 5 people: show the list row alone and ask "what does this say?" Pass at 4 of 5 (the yearly-costs bar, D174). Then the sheet's question |
| The estimate is read as a promise ("it will be done by May") | The question's slot says "At ₹5,000 a month"; the row's phrase is "done by". Include "will it be done in May for sure?" in the blind read. If 2 of 5 say yes, soften to "about May" |
| The row wraps to a mess at 2.0× text or 320dp | Device check at the `TestWindows` sizes and 2.0× text (UI_DESIGN §13); no ellipsis |
| The Home "reached" line is noise, or reads as a prompt to act | Blind read of the Home slot alone: "what does this tell you? is anything asked of you?" Pass at 4 of 5 saying it is news and nothing is asked. Also ask whether it is odd when they just typed that target (question 10) |
| The line is missed because a higher line holds the slot, or the app isn't opened that day | By design it stays pending until it has been on screen once, so it shows on the first later day it can. Ask AI and the Settings row carry it too |
| Slot order or written-when-seen rules regress the existing lines | Widget tests at the `TestWindows` sizes for each pair in the slot order, as FR-HO-3's AC tests do, with `FakeClock` for midnight and a restart between "shown" and the next day |
| Date arithmetic: clamp on the 29th to 31st, leap years, year crossing, `n = 1`, `n` beyond the cap | TDD with `FakeClock`: next_due on 31 Jan, 29 Feb, year crossing (Dec to Jan), `T = S`, `T = S + 1`, `gap` just below a multiple of `M`, `M = 1`, `T` at the 9-digit cap |
| Golden drift | Only the two new lines may change an export; run every existing golden |

North-star check: the feature adds no nag and no prompt; it neither raises nor lowers logged days per week, and it is not measured (no analytics).

## 12. Resolved (owner answers, 2026-11-22)

1. **Row wording.** Accepted: keep "₹18,000 set aside · done by May 2027", no "of ₹X". The target shows in the sheet and as "reached ₹X".
2. **Month format.** Accepted: short month, with the year only when it is not this year.
3. **Live line while typing.** Accepted: keep "At ₹5,000 a month, done by May 2027."
4. **Where "reached" shows.** **Changed by the owner:** also on Home, in the existing nudge slot (FR-HO-3), once per target, as a plain-text line with no new Home element, no notification and no celebration. Specified in section 4a; amends D174 (D212).
5. **A target at or below what is already set aside.** Decided: allowed; the list row reads "reached" immediately (E129).
6. **Yearly costs.** Accepted: offered on every saving with no flag; the estimate restarts after *Used* (E136).
7. **Far-off estimates.** Accepted: "over 10 years to go" beyond 120 put-ins.
8. **Clearing.** Accepted: a *Clear* chip in the question; ₹0 stays refused.
9. **Put in extra** never counts toward a target (E141).

### Still open (new, small)

10. **A target set or edited while already reached.** The Home line shows for it at the next evaluation point (my lean, as the owner's: yes). It may feel odd to be told what you just typed. Cheapest alternative: write `target_reached_for = T` at save time, so only a genuine crossing ever shows the line. Recommended: keep yes as decided, and check it in the hallway test; the change is one write.
11. **Two savings reaching targets together** show one line a day (the rule saved first), the other the next day. Recommended. Alternative: a combined line ("Insurance and RD reached their targets."), which needs extra copy and a longer row.

## 13. Doc changes needed (not made)

- `docs/SPEC.md`: new BR-23 (with the reached-line state), E129 to E150, AC-T1 to AC-T8 in FR-SE-1 Savings, **FR-HO-3** (slot order becomes five items; a new **Reached line** bullet with its ACs), BR-9 clause, BR-15 (lines and golden), BR-16 (schema 7 and the three columns), glossary, the status line.
- `docs/UI_DESIGN.md`: Settings saving sheet and list row, the Home nudge slot (order and the new row), copy table, the mockup link.
- `docs/DECISIONS.md`: D208 to D212 (section 10).
- `docs/PLAN.md`: data model (`recurring.target_minor`, `target_reached_for`, `target_reached_on`), schema v7, the milestone line.
- `docs/design/mockups/52-saving-target.html` (new, including the Home slot row) and the mockups README.
- `lib/l10n/app_en.arb`: keys for the row label, the question, the chip, the four row-line forms, the slot lines, the Home line and the export lines. Draft copy is in sections 3, 4, 4a and 9.
- `docs/features/yearly-costs/`: a one-line note that the target restarts after *Used*.
- `docs/features/` for the nudge slot, if one documents its order.

## 14. Next agents

1. `design-content`: the copy (row label, question, slot lines, the four row-line forms, "over 10 years to go", the Home line "{name} reached ₹{target}.", the Ask AI sentences), banned-word check.
2. `design-interaction`: the row and the in-sheet question, the *Clear* chip, the live line, the flash and the footer; **the slot's new priority, its evaluation-point and written-when-seen rules (section 4a), and the tap**; reduced motion.
3. `design-ux`: the Home line's place in the journey, the same-session "set while reached" case and the one-line-a-day rule (questions 10 and 11).
4. `design-ui`: mockup 52 (the list row's wrap, the sheet's last row, the Home slot row) on the design tokens, no new colour.
5. `design-accessibility`: TalkBack sentences ("Insurance reached ₹12,000. Opens the saving."), the live region, wrap at 2.0× text and 320dp, tap targets.
6. `design-validation`: the blind read and the hallway test (section 11), and the design QA against the build.
7. `design-ia`: confirm the label, the row's position among the sheet's rows, and the slot order.
8. `design-ops`: the doc sync in section 13.

Not needed: `design-brand`, `design-motion` (no new motion beyond the existing flash and the slot's normal arrival), `design-system` (no new token or component), `design-platform` (no layout change beyond wrapping), `design-ux-research` (the study already exists).
