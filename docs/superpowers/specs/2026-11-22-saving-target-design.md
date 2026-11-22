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
- **Target set while already reached** (including edited down to or below `S`): no Home line. The save writes `target_reached_for = T` and `target_reached_on = t`, so only a genuine crossing by a later put-in shows the line; the user was just told "reached" in the sheet (owner, section 12 item 10; E147).
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
| E147 | A target is set or edited so that `S ≥ T` already | No Home line: the save writes `target_reached_for = T` and `target_reached_on = t`. The row and the export read "reached" (owner, section 12 item 10) |
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

10. **A target set or edited while already reached.** Decided by the owner: **no Home line.** Saving a target with `S ≥ T` writes `target_reached_for = T` (and `target_reached_on = t`) at save time, so only a genuine crossing by a later put-in shows the line. The Settings row and the export still say "reached" (E147).
11. **Two savings reaching targets together.** Accepted: one line a day, for the rule saved first; the other shows the next day (E144).

## 13. Doc changes needed (not made)

- `docs/SPEC.md`: new BR-23 (with the reached-line state), E129 to E150, AC-T1 to AC-T8 in FR-SE-1 Savings, **FR-HO-3** (slot order becomes five items; a new **Reached line** bullet with its ACs), BR-9 clause, BR-15 (lines and golden), BR-16 (schema 7 and the three columns), glossary, the status line.
- `docs/UI_DESIGN.md`: Settings saving sheet and list row, the Home nudge slot (order and the new row), copy table, the mockup link.
- `docs/DECISIONS.md`: D208 to D212 (section 10).
- `docs/PLAN.md`: data model (`recurring.target_minor`, `target_reached_for`, `target_reached_on`), schema v7, the milestone line.
- `docs/design/mockups/52-saving-target.html` (new, including the Home slot row) and the mockups README.
- `lib/l10n/app_en.arb`: keys for the row label, the question, the chip, the four row-line forms, the slot lines, the Home line and the export lines. Draft copy is in sections 3, 4, 4a and 9.
- `docs/features/yearly-costs/`: a one-line note that the target restarts after *Used*.
- `docs/features/` for the nudge slot, if one documents its order.

## 13a. Next agents

1. `design-content`: the copy (row label, question, slot lines, the four row-line forms, "over 10 years to go", the Home line "{name} reached ₹{target}.", the Ask AI sentences), banned-word check.
2. `design-interaction`: the row and the in-sheet question, the *Clear* chip, the live line, the flash and the footer; **the slot's new priority, its evaluation-point and written-when-seen rules (section 4a), and the tap**; reduced motion.
3. `design-ux`: the Home line's place in the journey, the same-session "set while reached" case and the one-line-a-day rule (questions 10 and 11).
4. `design-ui`: mockup 52 (the list row's wrap, the sheet's last row, the Home slot row) on the design tokens, no new colour.
5. `design-accessibility`: TalkBack sentences ("Insurance reached ₹12,000. Opens the saving."), the live region, wrap at 2.0× text and 320dp, tap targets.
6. `design-validation`: the blind read and the hallway test (section 11), and the design QA against the build.
7. `design-ia`: confirm the label, the row's position among the sheet's rows, and the slot order.
8. `design-ops`: the doc sync in section 13.

Not needed: `design-brand`, `design-motion` (no new motion beyond the existing flash and the slot's normal arrival), `design-system` (no new token or component), `design-platform` (no layout change beyond wrapping), `design-ux-research` (the study already exists).

## 14. Copy (design-content)

**Status:** proposed final copy, 2026-11-22. Not in `app_en.arb` yet. Where it differs from the draft copy in sections 3, 4 and 9, this section wins (differences in 14.7). Voice per UI_DESIGN section 8: plain, calm, no promise, no banned words. "Saved" is never used: money added is "put in", money held is "set aside".

### 14.1 The "done by" question (promise risk)

| Option | Row line | Verdict |
|---|---|---|
| A | "₹18,000 set aside · done by May 2027" | **Chosen.** Owner accepted it (section 12, items 1 and 3). "By" is accurate: the month named is the month of the put-in that reaches the amount, so it is the earliest, never later. Short, and a Hindi-first reader knows "by". |
| B | "... · about May 2027" | Hedged, but "about" is reserved for figures that really are approximate (section 8, D182), and the month is exact for the stated amount. Held as the fallback. |
| C | "... · at this pace, May 2027" | Honest, but 11 characters longer, for no gain at 320dp. |

The promise risk is handled by framing, not by hedging every line. The sheet's live line carries the condition ("At ₹5,000 a month, ..."), so a user sees once where the date comes from. The row has no room for it and uses "done by". Section 11's blind read decides: if 2 of 5 say "it will be done in May for sure", switch the row to option B by editing `savingTargetEstimate`, `savingTargetEstimateNone` and `savingTargetLive` only; no code change. The Ask AI export says "estimate" in plain words because the model needs it.

### 14.2 ARB entries (proposed, add at the end of `app_en.arb`)

Placeholders: `{amount}`, `{monthly}`, `{target}` are `String`, already formatted by `MoneyFormatter` (`₹18,000`). In the `...Spoken` keys the amounts are the spoken form ("18,000 rupees", as `entryUsedSpoken` does) and `{month}` is the **full** month name, with the year when it is not this year ("March", "May 2027"), because TalkBack reads "Mar" as a word. In the visual keys `{month}` is short ("Mar", "May 2027"), built in code with `DateFormat`, never by concatenation in a widget.

```json
  "savingTargetLabel": "Saving up to",
  "@savingTargetLabel": {"description": "Label of the last row on a saving's sheet: an optional amount the saving is working toward. Never 'goal', 'balance' or 'saved' (BR-23, AC-T1)."},
  "savingTargetNotSet": "Not set",
  "@savingTargetNotSet": {"description": "Value of the Saving up to row when the saving has no target (AC-T1). When set, the row shows the amount from MoneyFormatter instead."},
  "savingTargetRowSet": "Change saving up to, {amount}",
  "@savingTargetRowSet": {"description": "TalkBack label of the Saving up to row when a target is set (AC-T7). amount is spoken, e.g. 50,000 rupees.", "placeholders": {"amount": {"type": "String"}}},
  "savingTargetRowNotSet": "Set saving up to. Not set yet.",
  "@savingTargetRowNotSet": {"description": "TalkBack label of the Saving up to row when no target is set (AC-T7)"},
  "savingTargetQuestion": "How much are you saving up to?",
  "@savingTargetQuestion": {"description": "Title of the Saving up to keypad inside a saving's sheet (AC-T2). Same shape as savingAmountQuestion; the saving's name is already the sheet's eyebrow."},
  "savingTargetBlank": "Type the amount you want to reach.",
  "@savingTargetBlank": {"description": "Line 1 of the Saving up to slot before any digit is typed and no target is set (AC-T3). One action, no figures."},
  "savingTargetLive": "At {monthly} a month, done by {month}.",
  "@savingTargetLive": {"description": "Line 1 of the Saving up to slot while digits are typed, and when a target is already set: the estimate from the saving's own monthly amount (AC-T3, BR-23). monthly is the saving's amount per put-in; month is short, with the year when it is not this year, e.g. May 2027. Polite live region (FR-KS-4).", "placeholders": {"monthly": {"type": "String"}, "month": {"type": "String"}}},
  "savingTargetLiveFar": "At {monthly} a month, that is over 10 years to go.",
  "@savingTargetLiveFar": {"description": "Line 1 of the Saving up to slot when the typed amount needs more than 120 put-ins (E138)", "placeholders": {"monthly": {"type": "String"}}},
  "savingTargetLiveReached": "You've already set aside that much.",
  "@savingTargetLiveReached": {"description": "Line 1 of the Saving up to slot when the typed amount is at or below what is set aside (E129). A fact, not a refusal: the amount is still allowed."},
  "savingTargetClear": "Clear",
  "@savingTargetClear": {"description": "Chip beside the amount on the Saving up to keypad; removes the target. Shown only when a target is set (AC-T2). Visible label."},
  "savingTargetClearSpoken": "Clear saving up to",
  "@savingTargetClearSpoken": {"description": "TalkBack label of the Clear chip, so it makes sense alone (AC-T2)"},
  "savingTargetEstimate": "{amount} set aside · done by {month}",
  "@savingTargetEstimate": {"description": "Third line of a saving's row in the Savings list, and the sheet slip (AC-T6), when a target is set, something is set aside and it is not reached. amount is what is set aside; month is short, e.g. May 2027 (AC-T5).", "placeholders": {"amount": {"type": "String"}, "month": {"type": "String"}}},
  "savingTargetEstimateNone": "Saving up to {target} · done by {month}",
  "@savingTargetEstimateNone": {"description": "Third line of a saving's row when a target is set and nothing is set aside yet (AC-T5)", "placeholders": {"target": {"type": "String"}, "month": {"type": "String"}}},
  "savingTargetReached": "{amount} set aside · reached {target}",
  "@savingTargetReached": {"description": "Third line of a saving's row when what is set aside is at or above the target (AC-T5). Words only; the saving keeps putting in (D210).", "placeholders": {"amount": {"type": "String"}, "target": {"type": "String"}}},
  "savingTargetFar": "{amount} set aside · over 10 years to go",
  "@savingTargetFar": {"description": "Third line of a saving's row when the target needs more than 120 put-ins (E138) and something is set aside", "placeholders": {"amount": {"type": "String"}}},
  "savingTargetFarNone": "Saving up to {target} · over 10 years to go",
  "@savingTargetFarNone": {"description": "Same as savingTargetFar when nothing is set aside yet", "placeholders": {"target": {"type": "String"}}},
  "savingTargetEstimateSpoken": "{amount} set aside, done by {month}",
  "@savingTargetEstimateSpoken": {"description": "TalkBack sentence for savingTargetEstimate. amount is spoken (18,000 rupees); month is the full name. The visible middle dot is excluded from semantics.", "placeholders": {"amount": {"type": "String"}, "month": {"type": "String"}}},
  "savingTargetEstimateNoneSpoken": "Saving up to {target}, done by {month}",
  "@savingTargetEstimateNoneSpoken": {"description": "TalkBack sentence for savingTargetEstimateNone. target is spoken.", "placeholders": {"target": {"type": "String"}, "month": {"type": "String"}}},
  "savingTargetReachedSpoken": "{amount} set aside, reached {target}",
  "@savingTargetReachedSpoken": {"description": "TalkBack sentence for savingTargetReached. Both amounts are spoken.", "placeholders": {"amount": {"type": "String"}, "target": {"type": "String"}}},
  "savingTargetFarSpoken": "{amount} set aside, over 10 years to go",
  "@savingTargetFarSpoken": {"description": "TalkBack sentence for savingTargetFar. amount is spoken.", "placeholders": {"amount": {"type": "String"}}},
  "savingTargetFarNoneSpoken": "Saving up to {target}, over 10 years to go",
  "@savingTargetFarNoneSpoken": {"description": "TalkBack sentence for savingTargetFarNone. target is spoken.", "placeholders": {"target": {"type": "String"}}},
  "savingReachedLine": "{saving} reached {target}.",
  "@savingReachedLine": {"description": "Home's nudge-slot line, shown once when a saving's set-aside amount meets its target (FR-HO-3 reached line, D212). saving is the user's own name and is never cut; target is formatted by MoneyFormatter. One sentence, no second line, no exclamation mark.", "placeholders": {"saving": {"type": "String"}, "target": {"type": "String"}}},
  "savingReachedLineSpoken": "{saving} reached {target}.",
  "@savingReachedLineSpoken": {"description": "TalkBack label of the reached line (AC-R7); the hint is the existing dueSoonOpensSaving, 'Opens the saving.'. target is spoken, e.g. 12,000 rupees.", "placeholders": {"saving": {"type": "String"}, "target": {"type": "String"}}}
```

### 14.3 Copy table

Smallest `TestWindows` size is `smallPhone` (320 x 568). A row line has about 230 to 250dp, roughly 34 characters per line at 1.0x text. Lines over that wrap to two by design (section 4); none is cut.

| Key | Text | Chars | At 320dp | Notes |
|---|---|---|---|---|
| `savingTargetLabel` / `NotSet` | Saving up to / Not set | 12 / 7 | one line | The owner's own phrase |
| `savingTargetQuestion` | How much are you saving up to? | 30 | one line | Same shape as `savingAmountQuestion` |
| `savingTargetBlank` | Type the amount you want to reach. | 34 | one line | One action, no figure to misread |
| `savingTargetLive` | At ₹5,000 a month, done by May 2027. | 36 | 2 lines | The condition comes first, so it reads as a sum, not a promise |
| `savingTargetLiveReached` | You've already set aside that much. | 35 | 2 lines | A fact; the amount is still accepted (E129) |
| `savingTargetClear` | Clear | 5 | one line | Verb; 48dp chip |
| `savingTargetEstimate` | ₹18,000 set aside · done by May 2027 | 36 | 2 lines | |
| `savingTargetEstimateNone` | Saving up to ₹50,000 · done by May 2027 | 39 | 2 lines | |
| `savingTargetReached` | ₹50,000 set aside · reached ₹50,000 | 35 | 2 lines | |
| `savingTargetFar` / `FarNone` | ₹500 set aside · over 10 years to go | 36 | 2 lines | |
| `savingReachedLine` | Insurance reached ₹12,000. | 26 | one line | "School fees reached ₹1,00,000." is 30 and may wrap beside the glyph and chevron; the name is never cut |

Hindi runs 30 to 40% longer; every line already allows two lines, so no key needs a different container.

### 14.4 Validation messages: none new

- **₹0 refused:** the keypad shakes and Save stays off (FR-KS-2). No sentence is added; the shake plus the slot's "Type the amount you want to reach." says it. TalkBack gets the existing `typeAmountFirst` ("Type an amount first.") on the disabled Save key.
- **9-digit cap:** the existing `amountCap` ("That's the most you can type.").
- **Failed save:** the existing `couldntSave` ("Couldn't save. Try again.").
- **Save key and footer:** the existing `save` ("Save") and `billSaved` ("Changed."). "Saved" stays reserved for money put in.
- **Line 2 of the slot, always:** the existing `savingUsedSame` ("Your daily number doesn't change."), reused since the idea is the same (one word per idea, D132).
- **TalkBack hint on the Home line:** the existing `dueSoonOpensSaving` ("Opens the saving.").

### 14.5 Ask AI export (not ARB)

Export text is English-only constants and small builders in `lib/ask_ai/domain/prompt_builder.dart` (`_role`, `_notLoggedClause`, `_usedClause`), with amounts through `_money.format` and ISO dates. They do not go in the ARB. The prompt speaks as the user ("I save ₹6,000 a month (RD on the 10th)"), so the facts do too; the explaining clause says "the user", like `_usedClause`. Add a `// why:` citing BR-15 and D211.

Facts, one sentence per saving with a target, right after the "I save ..." clause, soonest first. Numbers are the list's own (D79):

- Estimate: `My RD saving has a target of ₹50,000 and ₹18,000 set aside. At ₹5,000 a month it would reach the target around 2027-05-10.`
- Estimate, nothing set aside: `My RD saving has a target of ₹50,000 and nothing set aside yet. At ₹5,000 a month it would reach the target around 2027-05-10.`
- Reached: `My Insurance saving has reached its target of ₹12,000, with ₹13,000 set aside. It still puts in ₹1,000 a month.`
- Far: `My RD saving has a target of ₹50,000 and ₹500 set aside. At ₹500 a month it is more than 10 years from the target.`

Explaining line, once, after the facts and D188's other clauses, only when a target exists:

`A saving with a target is something the user chose to save up to. The date is an estimate at the current monthly amount, and reaching the target does not stop the saving. Treat the target as a goal, not as spending.`

One new golden: an estimate, a reached one and the explaining line. Existing goldens do not change.

### 14.6 Checks

- **Banned words** (transaction, debit/credit, budget period, Oops, "You overspent!"): none. No exclamation marks. No sign or colour carries meaning.
- **Glossary:** "set aside" (BR-19) for money held, "put in" for adding, "saving" for the rule. "Saved" appears nowhere. "Goal" appears only in the export's explaining line, addressed to the AI, never in the UI. "Done by" is the estimate, "reached" the fact; they are not mixed.
- **Blame:** none. The already-set-aside case is a plain fact.
- **Plurals and gender:** none needed (amounts, and a fixed "10 years"). The "·" is inside each ARB string so a translator can reorder; no concatenation in code.
- **Reading level:** every UI string is under 40 characters in short words. "To go" and "reached" are the two mild idioms, both common in Hindi-first English.
- **TalkBack:** every visible line has a spoken twin; the middle dot is never read; months are spoken in full; amounts are spoken as rupees; the Clear chip has its own sentence.

### 14.7 Changes from the working copy, and why

1. **Added `savingTargetBlank`.** The slot had no line before the first digit; an empty slot breaks the empty-state rule (say what will appear, give one action).
2. **Added `savingTargetLiveFar`.** Typing a huge amount would otherwise show a date more than 10 years out in the sheet while the row says "over 10 years to go".
3. **TalkBack for no target** changed from "Set saving up to, not set" to "Set saving up to. Not set yet." (the original repeated "set" and ran two ideas together). AC-T7 should follow.
4. **Spoken keys are separate** from the visible ones: the middle dot and "Mar" read badly aloud.
5. **Export:** first person to match the "I save ..." clause beside it (the working copy was a third-person label, "Saving up to a target: RD has ..."); "around" marks the date as an estimate for the model; "reach the target" replaces "done", which a model could read as "stop"; the reached form states the real set-aside figure, which can exceed the target.
6. **Kept unchanged:** "done by" (weighed in 14.1), "over 10 years to go", "reached ₹X", "Saving up to", "Not set", "Clear", and "{name} reached ₹{target}." (an exact fact, names the saving, no promise).
7. **No new validation strings**; existing keys cover them (14.4).

### 14.8 Doc edits to carry out

- `docs/UI_DESIGN.md` section 8: add a bullet: "Saving target (BR-23): *Saving up to* is the row; *done by {month}* is an estimate at the saving's own monthly amount; *reached* is a fact. Never 'saved' or 'goal complete'; no 'goal' in the UI."
- `docs/SPEC.md` glossary: *Saving up to* (section 9) and *reached*. AC-T7's TalkBack text becomes "Set saving up to. Not set yet."
- The mockup 52 copy deck lists the keys above.

## 15. Interaction (design-interaction)

Written 2026-11-22 against the code as it is (`lib/home/presentation/`, `lib/settings/presentation/`), with section 12 treated as decided and section 14's copy keys used by name. Nothing here adds a tap to Add, moves a category, the keypad or the dock, or adds a Home element. Haptics are `Haptics.tick()` and `Haptics.reject()` only. `success()` is not used: in this app it marks a write that closes the sheet (*Used*), and this one returns to the sheet like the other row saves.

### 15.1 Findings that change the proposal (read first)

| # | Finding | Fix |
|---|---|---|
| F1 | **Section 4a and item 10 contradict each other.** Item 10 writes `target_reached_on = t` at save time when `S >= T`. But *Shown* is `target_reached_on = today and target_reached_for = T and S >= T`, so a target saved while reached would show the Home line at the next resume the same day, which is what decision 10 forbids. | At save time (set or edit) with `S >= T`, write **only `target_reached_for = T`** and leave `target_reached_on` NULL. *Shown* is then false (no date) and *Pending* is false (`for = T`). Amend section 4a "Day rules", E147 and section 9's BR-23 text. *Clear* still nulls both. |
| F2 | **Two savings, one day.** *Pending* excludes a saving once it is written, so after A is shown and written, B becomes the first pending saving at the next evaluation point the same day and would take the slot: a second line in one day, against decision 11 and AC-R4. | The slot candidate is: the saving that is **Shown today** first; else the first **Pending**. So A holds the slot all day, resumes included, and B waits for tomorrow. Add one sentence to AC-R4. |
| F3 | **E150 says the line leaves "at the next evaluation point" when `S` falls below `T`.** The usual cause is the user's own act in the sheet the line opened (*Used*, a new target, *Clear*). A "reached" line left on screen after that is a false statement. | The line leaves at the **next Home reload** (a user's own act may remove a line, FR-HO-3, D170). Focus then goes to the "Today" heading, as for the other lines. |
| F4 | **AC-T4 and E132 say "₹0 is refused with a shake", but the amount and *Used* questions keep *Save* off at ₹0** (`state.rupees > 0 && !state.saving`), so there is nothing to shake at. Section 14.4 already says "Save stays off". | Same here: *Save* is off at ₹0 with the existing "Type an amount first." hint. Reword AC-T4 and E132 to "*Save* stays off at ₹0". The shake and `reject()` remain for a refused 10th digit only. |

### 15.2 The saving sheet: *Saving up to*

**Where it sits.** For a saving, `BillSummary._rows` is Amount, Day, Name. The new row is the fourth and **last**, above the *Used some of it* section, the perforation and the footer. A bill never shows it. Reading and focus order is top to bottom, so TalkBack meets it after *Name* and before *Used some of it*. Add `BillAnswer.target` to the enum; `justSaved` already carries a `BillAnswer`, so the flash and "Changed." need nothing new.

**The row** (`BillAnswerRow`, key `bill-row-target`): label `savingTargetLabel`, value `savingTargetNotSet` or the amount (`₹50,000`). The value does not carry "reached" or the estimate: the slip's set-aside line already does (AC-T6) and a second place would drift. Semantics: `savingTargetRowSet` / `savingTargetRowNotSet` (14.2).

#### Row state matrix (fill, outline, words; never colour)

| State | Look | Words / semantics |
|---|---|---|
| Rest, not set | the sheet's answer-row fill (`display`), value `Not set` in `displayInk2` | "Set saving up to. Not set yet." |
| Rest, set (estimate or far) | same fill, value `₹50,000` in `displayInk` | "Change saving up to, 50,000 rupees" |
| Rest, reached | identical to *set*; "reached" is in the slip line, read first | same |
| Pressed | fills `sunk` (the row's existing pressed fill) | - |
| Focused / hovered (keyboard, large screen) | 1dp `ink2` outline and the existing focus ring | - |
| Just saved | one `sunk` flash, 1400ms (150ms crossfade under reduced motion); footer "Changed." for 2.4s | the footer is already a polite live region |
| Disabled / loading / error | none. The row is always enabled, needs no read, and a failed write stays in the question | - |

**Micro-interaction: open the question (Saffer).**
- *Trigger:* tap the row, or activate it by keyboard or Switch Access. It is a plain button, so no gesture alternative is needed.
- *Rules:* `BillSheetAnswerOpened(BillAnswer.target)`. The question is **empty** when no target is set, **prefilled** with the target when set, with `fresh: true` so the first key replaces it (FR-AD-8). Note `_onAnswerOpened` prefills `rupees` from `rule.amount`; for this answer it must prefill from the target (or 0).
- *Feedback:* the sheet's `AnimatedSwitcher` crossfade (`numberRoll`; 150ms under reduced motion). No haptic on open, as for the other rows.
- *Loops and modes:* none. Back (system, the Back well, predictive back through the sheet's `PopScope`, already `canPop: open.isNone()`) returns to the summary and drops the draft. A second Back closes the sheet. No "discard?" prompt: only a number is lost.

**The question** reuses the *Used* layout, not a new component: `PinnedBillQuestion` with `savingTargetQuestion`, the saving's name and glyph, the "Every month on the 5th" caption, the shared `Keypad` with `00`, `AmountDisplay`, a full-width marigold `SignalKey` *Save*, and the slot. The 9-digit cap and "no paise" are the keypad's own: a refused 10th digit gives `reject()`, the shake and the held ring (FR-KS-2). Each accepted digit gives the existing `tick()`. At 1.3x text the chip drops below the amount, as *All of it* does (`_stackChipFrom`).

*Where the logic lives (suggestion):* widen `BillSheetBloc._editAmount`'s guard from `amount` to `amount || target` and add `BillSheetTargetSaved` and `BillSheetTargetCleared`, droppable like the other saves, writing through one small use case. A separate `UsedBloc`-style bloc plus a link widget would be a third bloc for one number; `BillSheetBloc` already owns `rupees`, `fresh`, `rejections`, `saving` and `saveFailed`. The estimate is a pure domain function (BR-23) read from state, never computed in the widget.

**Focus order in the question:** Back well, amount, *Clear* (when shown), the slot (a polite live region, not focusable), keypad keys in their fixed order, *Save*. On return to the summary, focus goes to the row that opened the question only if the sheet already does that for the other rows; I did not verify that, so parity is the rule: do not add a new focus behaviour here.

#### The *Clear* chip

- *Trigger:* tap. A 48dp `HisaabChip` beside the amount (below it from 1.3x text), label `savingTargetClear`, spoken `savingTargetClearSpoken`.
- *Shown:* only when the saving **has** a target. It is absent, not disabled, when none is set, so an empty question has no dead control. It cannot appear or vanish while the question is open (the target can't change meanwhile).
- *Rules:* **an immediate write**, not a fill. It sets the target to none and nulls both reached columns, then behaves like any saved answer: back to the summary, the row flashes, the footer reads "Changed.", the row reads `Not set`. Reason: *Save* is off at ₹0, so "empty the amount, then Save" cannot work, and a chip that only emptied the amount would need a second step to explain. No Undo snackbar: the old number was on the row a tap ago and is cheap to retype (the first key replaces).
- *Feedback:* `tick()` on success, then the flash and footer. On failure: `reject()`, the question stays, `couldntSave`.
- *Guard:* droppable, so a double tap writes once; the chip is off while a write is in flight.

| Clear chip state | Look |
|---|---|
| Rest | `hairline` fill, `ink` label (chips rest `hairline`, D89) |
| Pressed | fills `ink2` with `surface` text (the pick fill, D89) |
| Focused / hovered | focus ring / 1dp `ink2` outline |
| Selected | n/a (an action, not a choice) |
| Disabled | write in flight: `hairline` fill, disabled ink, `enabled: false` in semantics |
| Loading / error | none on the chip; a failure shows as the slot's retry line |

#### The live estimate line (the slot)

Two lines in a `PolitePreviewSlot`, as `UsedSlot` does: line 1 is the estimate, line 2 is always `savingUsedSame` ("Your daily number doesn't change.").

| What is typed (`T'` in whole rupees) | Line 1 | `stateClass` |
|---|---|---|
| nothing, or backspaced back to ₹0 | `savingTargetBlank` ("Type the amount you want to reach.") | `blank` |
| `T' <= S` | `savingTargetLiveReached` | `reached` |
| `n <= 120` | `savingTargetLive` | `estimate` |
| `n > 120` | `savingTargetLiveFar` | `far` |

A prefilled target shows its own estimate (or reached or far) on the first frame, not the blank line.

- *Update timing:* the digit's Bloc handler emits the new rupees and the estimate derives from the same state, so line 1 changes in the **same frame as the digit** (far under 100ms). No debounce, no animation, the text swaps. Nothing is "calculating".
- *Spoken:* `PolitePreviewSlot` speaks the final text once after 1.2s of stability and at once when `stateClass` changes, so fast typing is not narrated digit by digit. Line 2 is spoken with it (`spokenPair`).

**Micro-interaction: Save (Saffer).**
- *Trigger:* tap the `SignalKey` (key `target-save`), the one marigold key on the screen. Off while `rupees == 0` or a write is in flight, with the `typeAmountFirst` hint, exactly as *Amount* and *Used*.
- *Rules:* `rupees == current target` writes nothing and returns to the summary (no flash, no haptic: the existing "unchanged answer" path of `_save`). Otherwise it writes; when `S >= T'` the same write also stores `target_reached_for = T'` (F1). A target not above `S` is allowed (E129).
- *Feedback:* `tick()`, back to the summary, the row flashes, "Changed." for 2.4s, the slip's set-aside line takes the new text (AC-T6).
- *Failure:* `reject()`; the question stays with its digits and shows `couldntSave` in the `saveFailed` place `PinnedBillQuestion` already has. A retry is another tap.
- *Double tap:* the event is droppable; the second tap is dropped.

#### Question state matrix

| Control | Rest | Pressed | Focused | Hovered | Selected | Disabled | Loading | Error |
|---|---|---|---|---|---|---|---|---|
| Amount figure | digits, ₹0 muted when empty | n/a | n/a (not a control) | n/a | n/a | n/a | n/a | shake and held ring on a refused 10th digit |
| Keypad key | existing key states | existing | existing | existing | n/a | ignored while saving | n/a | refused digit: `reject()` |
| *Clear* | `hairline` chip | `ink2` fill | ring | 1dp `ink2` outline | n/a | write in flight | n/a | slot retry line |
| *Save* | marigold | existing pressed | ring | outline | n/a | off at ₹0 or while saving (hint: type an amount first) | the key is off; the write is far under 1s, so no spinner | `couldntSave` |

**Edge cases for the sheet.**

| Case | Behaviour |
|---|---|
| Fast entry | Every key is a synchronous emit and the estimate follows each. The live region speaks the last value once. |
| Rotation, fold, tabletop | The draft (`rupees`, `fresh`) lives in `BillSheetBloc`, so a rebuild keeps it. The pinned layout and the stacked chip are the *Used* question's; nothing straddles a fold. |
| A put-in posts while the question is open | `S` and `next_due` are read when the question opens, so the estimate is for that moment. Saving still works. Same trade-off as *Used*'s set-aside read; not worth a live update. |
| Back mid-typing | Summary, draft dropped, no write. |
| Delete saving from the summary | Unchanged; the target goes with the rule and Undo restores it (E139). |
| TalkBack | The row reads one sentence. Opening the question: title, amount, *Clear*, keypad, *Save*; the slot is a polite live region; a disabled *Save* reads the "type an amount first" hint. |

### 15.3 Home: the reached line in the nudge slot

#### Slot priority, checked against the code

`HomePage._nudge` renders a waiting bill first; if `dueSoon` is some it renders the due-soon row; otherwise it renders the install slot and the missed-log slot. `HomeLinesBloc` decides between those two at an evaluation point: `_installFits` and `_decide` both require no bill line (waiting or due-soon), not *No income* and not an over state, and install wins over missed-log. **The order in the code is therefore waiting, due-soon, install, missed-log.** The proposed order (waiting, due-soon, **reached**, install, missed-log) fits as one more item:

1. `HomePage._nudge`: in the `dueSoon` none branch, add a `reachedLineSlot` builder **before** `installLineSlot` (wired in `lib/app/routes.dart` beside `installLineSlot`).
2. `HomeLinesBloc`: add `reached: Option<ReachedLine>` to its state. `_onEvaluated` decides it first, with the same gates; `_installFits` and `_decide` gain `&& reached.isNone`, so install and missed-log yield. `HomeLinesSlotTaken`, `HomeLinesMidnight` and `_remove` clear it as they clear the others.
3. `HomeLinesFacts` gains the candidate, read from `HomeReady`.

**Order stable (FR-HO-3) is unchanged.** A bill line may arrive at any reload and takes the slot. When a higher item clears mid-day, reached does not slide in; it waits for the next evaluation point. No count, no badge.

#### What Home loads

`HomeBloc`, with the due-soon read it already does, computes one `Option<ReachedLine>` (the saving rule, `T`, and a `pending` flag):
- the saving that is **Shown today** (F2): active, has `T`, `S >= T`, `target_reached_for = T`, `target_reached_on = today`; else
- the first **Pending** saving (rule saved first): active, has `T`, `S >= T`, `target_reached_for != T`.

`S` comes from `GetSetAside`, which the sheet already uses. No stored state beyond the three columns.

#### "Written when seen": the install line's mechanism is reusable, no simpler rule needed

Today the install line is marked seen by `MissedLogProbe(event: HomeLinesInstallShown)`. After its first frame the probe sends the event only if the route is current, tickers are on and `HomeBloc.isCovered` is false, so a line drawn under a door-opened tray is never written. The bloc then calls `markInstallLineSeen` and sets `installMarked`. A tap also writes if not yet written. The reached line is the same shape:

- `HomeLinesReachedShown`, sent through `MissedLogProbe(event: ...)` with a key that changes per `serial`: if the line is `pending` and not yet marked, write `target_reached_for = T` and `target_reached_on = today` through one new repository method; on success set `reachedMarked`. A line that is *Shown today* (already written, for instance after a resume) is not written again.
- `HomeLinesReachedTapped`: droppable; `tick()`; writes if still unwritten.
- A failed write is logged by type only (as `_logFailure`) and the line stays pending, so it shows again at the next point. The worst case is a repeat, never a loss.
- **The simpler rule** (write on first build at an evaluation point, ignoring tray or sheet cover) is **not recommended**: it would burn the line when a widget, tile or shortcut opens the Add tray over Home at that very resume, which is the case the probe exists for. The probe already exists, so the exact rule costs one event and one write method.

One real difference from install: after install is written its flag removes it for ever, so it cannot return. The reached line must stay **all day**, so it is decided again at later evaluation points as *Shown today* (F2) and simply not written a second time.

#### The row

A new widget in the due-soon row's shape: `sunk`, at least 56dp, 18dp squircle, a `surface` well with the saving's piggy-bank glyph, one sentence `savingReachedLine` (the name is never cut; it wraps at large text), a chevron in `ink2`, built from the same `Pressable`. No date line, no amount other than the target. It is not a live region and announces nothing when it arrives or leaves (AC-R7); it is read as `savingReachedLineSpoken` then `dueSoonOpensSaving`.

| State | Look |
|---|---|
| Rest | `sunk` fill |
| Pressed | `hairline` fill (as the due-soon row) |
| Focused / hovered (keyboard, large screen) | 1dp `ink2` outline and the focus ring |
| Selected, disabled, loading, error | not applicable: it never loads, is never disabled and never errors (a failed write just leaves it pending) |

**Tap opens the saving's sheet: verified reusable.** `DueSoonRow` calls `onOpenBill(bill.rule)` (a `ValueChanged<RecurringRule>`) and SPEC FR-HO-3 says a saving opens "the saving" over Home (D120). The reached row takes the same `onOpenBill` and the rule from its candidate: no new route and no new sheet code. After a change Home reloads, and *Delete saving* from there deletes with Undo as for the due-soon row.

- **No `tapped` guard in the state**, unlike the missed-log and install lines. This line stays when the sheet closes, so a guard would block the second tap for the rest of the day. The due-soon row has no guard either; the sheet's barrier takes the second tap once it is up. Parity accepted.
- **Focus:** if the sheet's change removes the line (F3), focus goes to the "Today" heading. `HomeLinesDriver`'s focus listener names only `missed` and `install` today, so it must cover `reached` too, and its `_onHomeReady` must also remove a reached line that no longer qualifies (F3) or that a bill line has displaced.
- **Undo after a delete from Home the same day:** the line leaves on the delete's reload and, since Undo restores the columns, returns at the next evaluation point rather than instantly. A little less than "as it was" in section 4a; acceptable and free of pop-in.
- **Arrival and reduced motion:** no new token. The slot collapses over `HisaabMotion.resize`; under reduced motion a 150ms fade and the height at once, copied from `InstallLineSlot`. No haptic on arrival (AC-R6), no marigold; the tap gives `tick()` through the bloc, as the other lines do.

#### Two-pane layouts (D173)

`app_shell.dart` puts a single `HomePage` beside Spends in two panes, so there is **one slot instance**. The line shows once, in the Home pane, in single and two-pane layouts, and its tap opens the sheet through the same route (`BillSheet.route`, width capped at `AdaptiveSplit.readableWidth`, tabletop anchored). D173 concerns Spends *insights* waiting for the **missed-log** line in a single pane only. The reached line does **not** make insights wait: it is news, not a question, and AC-6 names the missed-log line only. No change to D173.

### 15.4 Ambiguities left by the proposal, and the simplest consistent answer

| # | Ambiguity | Answer |
|---|---|---|
| A1 | Line 1 before anything is typed | `savingTargetBlank` (section 14), class `blank`. A prefilled target shows its own estimate from the first frame. |
| A2 | Two savings in one day | *Shown today* beats *Pending*: one line a day, even across resumes (F2). |
| A3 | The save-while-reached write | `target_reached_for = T` only; `target_reached_on` stays NULL (F1). |
| A4 | *Clear*: fill or write? | An immediate write that returns to the summary. |
| A5 | *Save* at ₹0 | Off, with the existing hint (F4). |
| A6 | The user changes the target in the sheet the line opened | The line leaves at the next Home reload if `T` changed, was cleared or `S < T`; it stays if still true (F3). |
| A7 | A write fails | In the sheet: question stays, `reject()`, `couldntSave`. On Home: the line stays pending. |
| A8 | The saving is renamed on the day | The line reads the current name at its next build; no text is stored. |
| A9 | *Clear*, then the same number again while reached | *Clear* nulled both columns, so this is a target saved while reached: `for = T`, no Home line. |
| A10 | A yearly-cost saving | Identical to any saving (no flag, section 10). |

### 15.5 Doc edits implied (for design-ops; not made here)

- **SPEC FR-SE-1:** AC-T2 add "*Clear* writes at once and returns to the sheet"; AC-T3 add "line 1 reads `savingTargetBlank` until a number is typed or a target exists"; AC-T4 reword "₹0 is refused with a shake" to "*Save* stays off at ₹0" and keep the shake for a refused 10th digit; add Back (summary, draft dropped, no prompt).
- **SPEC FR-HO-3:** AC-R2 name the mechanism ("as the install line's seen flag"); AC-R3 "leaves at the next Home reload if the saving no longer qualifies" (was next evaluation point, F3); AC-R4 add "a saving already shown today keeps the slot" (F2); AC-R5 add "no `tapped` guard: the line stays when the sheet closes"; the order sentence gains reached; D173 and AC-6 unchanged.
- **SPEC BR-23, section 4a, E147, E150:** F1 (`target_reached_for` only at save-while-reached) and F3.
- **UI_DESIGN section 5:** the row, the question, *Clear*, the slot table of 15.2 and the reached row. **Section 6:** no new motion; the row flash and slot arrival reuse tokens, with the reduced-motion notes. **Section 7:** row save and *Clear* `tick()`, failure `reject()`, no `success()`, reached-line tap `tick()`, no arrival haptic.
- **Tests to name** (widget, at the `TestWindows` sizes): the row in each state; the question empty and prefilled; *Clear* absent, present and immediate; *Save* off at ₹0, no write when unchanged, failure keeps the question; the slot's four classes; 1.3x and 2.0x text; slot order against waiting, due-soon, install and missed-log; written only when uncovered; shown all day across resumes with `FakeClock`; leaves at midnight and on reload when `S < T`; a second pending saving does not take the slot the same day; tap opens the saving's sheet; two panes show it once.
