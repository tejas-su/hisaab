# Can I afford it?: design

**Status:** proposal, 2026-11-22. Owner-approved direction and mockup; not yet in SPEC, UI_DESIGN, DECISIONS or code.
**Builds on:** [2026-11-22-saving-target-design.md](2026-11-22-saving-target-design.md) (the *Saving up to* target, its "done by" estimate, the Home reached line). This doc **amends** three of its decisions (section 7).
**Mockup:** [52-can-i-afford.html](../../design/mockups/52-can-i-afford.html). The saving-target spec reserved mockup 52 for itself; it was never drawn, so it takes the next free number when it is.
**Numbers:** BR, D and E ids are assigned at doc-sync time. D208 and D209 are already taken in the working tree, so the saving-target spec's D208 to D212 shifted as well: in DECISIONS they are D211 (what-if rejection), D212 (target), D213 (auto-stop), D214 (Home reached line) and D215 (export).

## 1. Intent

**Job.** "I want something big (a ₹1,27,000 Mac). Tell me straight: can I buy it now without a loan or a squeezed month? If not, how much do I put away each month, and by when is it mine?"

**Why.** The owner wanted a way to judge a big purchase against their own money, paying from salary savings, money saved earlier, or the credit card paid in full. They never take EMIs because the interest rates are high. Today the only route is Ask AI's own-question box ("Can I afford a new phone this month?", D73), which needs a round trip to ChatGPT and gives no saving plan inside the app.

**Who.** Anyone with income set up and some history; the owner first.

## 2. Goals, non-goals, anti-goals

**Goals**
- One answer, in one sentence, for one purchase: *Yes, you can* / *Yes, without a loan* / *Not yet*.
- The maths stays hidden; *Other ways* shows each path with its numbers for those who want them.
- *Not yet* leads, in one tap, to a saving with a target that stops itself when reached.

**Non-goals**
- A general what-if simulator (D211's rejection stands for that; this is one check for one purchase).
- Knowing the bank balance. The app only sees money moving through pay cycles; "already saved" is typed by the user for this one check.
- Ask AI changes. The saving-target spec already carries targets into the export.

**Anti-goals (a failure even if it works)**
- Offering, suggesting or modelling an EMI or any loan.
- An answer that plans the user down to their usual spend with no breathing space.
- Touching other savings pots (Insurance, school fees) to make a purchase "fit".
- A second number beside the Home hero, or any change to Home or to the Add flow.

## 3. Approaches considered

| Approach | Trade-off | Verdict |
|---|---|---|
| **A. Target on saving rules, plus a pure affordability function** | Reuses the saving-target spec's `recurring.target_minor` and BR-19's set-aside maths. The check itself stores nothing. One new sheet | **Picked by the owner** |
| B. A separate goals table and a Goals screen | A second place for money, a join for one value, harder Undo on delete. Already rejected in the saving-target spec (section 10) | Rejected |
| C. Ask AI only: surface "Can I afford…?" as a fifth goal | No in-app answer, no saving plan, needs the network round trip | Rejected; Ask AI's own question stays as it is |

## 4. The flow (mockup 52, sections 1 and 2)

1. **Entry.** Spends gets a second card beside the Ask AI card: *Can I afford it?* / *Check a big buy*. Plus an app-icon shortcut, *Can I afford it?*, next to the existing *Add a spend* shortcut (FR-WG). Home does not change.
2. **What and how much.** A full-height sheet over Spends: "What do you want to buy?", a name field, the price on the shared keypad (9-digit cap, no paise), *Next*.
3. **Saved for it already?** Chips *Nothing yet* / *Yes*; *Yes* shows the keypad for the amount `H`, with the hint "Money you've put away for this, in any account". *See the answer*.
4. **The answer** (section 5), with *Other ways* collapsed under it.
5. **Act.** *Not yet* has one marigold key, *Start saving ₹X a month*, which creates the saving (section 6). The other answers have a quiet *Okay* that closes the sheet. Nothing is recorded by the check itself.

Back steps back through the sheet; the draft is dropped on close; no "discard?" prompt.

## 5. The answer (proposed new BR)

### Inputs, all in integer paise, read when the answer opens

| Symbol | Meaning |
|---|---|
| `price` | Typed in step 2 |
| `H` | Typed in step 3, or 0 |
| `room` | For one full cycle after the current one: the income rule's amount − every *Same every month* and *Changes every month* bill at its estimate (card bills are excluded, D123) − every active saving rule's monthly amount. With *It changes* income, the last cycle's *Got* total stands in for the income amount |
| `days` | The length of the next cycle, from `PeriodCalculator` |
| `usual` | Average *Spent* a day over the last fully tracked, finished cycle, counted exactly as BR-7's `V_prev` (no rule-posted bills, no *Not logged*), floored to the rupee |
| `floor` | `usual × 1.2`, rounded **up** to ₹10. This is the breathing space the owner asked for |

### Rule

```
spare = max(0, roundDown500(room − floor × days))   // card room after payday, and the most asked to save a month
need  = max(0, price − H)

need = 0                → Yes, you can.        (from savings)
need ≤ spare            → Yes, without a loan. (H from savings, need on the card, paid in full)
spare > 0               → Not yet.             (save `spare` a month; n = ceil(need / spare) put-ins)
spare = 0               → Not yet.             ("your usual days already use your monthly money")
```

- **Card timing (owner, 2026-11-22).** hisaab counts a card purchase on the day it is made (D123), but this check plans the card part against the **next** cycle, because the bill is paid from that cycle's income. So the *Yes, without a loan* answer tells the user to log the card part on the day they pay the card bill: "Add ₹17,000 when you pay the card bill." This is a deliberate exception to D123 for this one purchase, and it needs its own DECISIONS row. Money typed as `H` sits outside the app, so nothing is recorded for it. Only money set aside in a hisaab saving is recorded, as *Used* (BR-19), on the day it is spent.
- The day amount after the card path is `floor((room − need) / days)`; while saving it is `floor((room − spare) / days)`. Both are always at least `floor` by construction.
- The "done by" month for *Not yet* uses the saving-target spec's BR (the calendar month of the n-th put-in from the new saving's first `next_due`), so the answer and the Savings row never disagree.
- **Not enough history** (no finished, fully tracked cycle): `usual` is unknown. The card path is not offered, and *Not yet* is not computed; the answer reads "Ask again after payday" (wording to `design-content`). *Yes, you can* still works, since it needs no history.
- **No income set up:** the Spends card is hidden, as Spends already gates on income.
- **Determinism:** a pure domain function of its inputs, so the same data gives the same answer. TDD with `FakeClock`: `need = 0`, `need = spare`, `need = spare + 1`, `spare = 0`, the 9-digit cap, 28 to 31-day and weekly cycles, *It changes* income.

### Worked example (the owner's numbers, mockup 52)

`room = 45,000 − 13,000 = 32,000`, `usual = 750`, `floor = 900`, `days = 30` → `spare = roundDown500(32,000 − 27,000) = 5,000`. `price = 1,27,000`, `H = 60,000` → `need = 67,000 > 5,000` → **Not yet.** "Save ₹5,000 a month and it's yours by Dec 2027" (`n = 14`, put-ins from Nov 2026). "That's about ₹900 a day for now, instead of ₹1,066."

### Display

- Verdict (Anek, large), then one or two sentences (Mukta), then one or two bars: the day amount, outline for "usually" and filled for "with this", with a tick at `floor`, and the line "The line is your breathing space: usual ₹750 a day + 20%". Ink only; never marigold, never red or green.
- *Other ways*: three rows (*From savings*, *Savings, then the card*, *Save up*), each one line with its numbers; the suggested one marked "· suggested".
- Copy is draft; `design-content` owns it. "Next month" becomes "after payday" so it fits weekly and month-end cycles (D117).

## 6. "Start saving" and the goal it creates

- *Start saving ₹X a month* creates a saving rule: name = the item's name, monthly amount = `spare`, day = the day after payday (my call: money goes in right after it comes in), target `T = need` (the money still needed; `H` lives outside the app, so it is not put in). It reuses the saving-target spec's `target_minor` column; no new column.
- It returns to Spends with a snackbar, "Saving ₹5,000 a month for Mac", with Undo (4 s) that deletes the rule.
- Like any saving it lowers the daily number from its first put-in (D120). The saving-target spec's three-question *Add a saving* flow is unchanged; this is a second door that fills all fields at once.
- The Savings row shows progress **in words only**, using the saving-target copy: "₹5,000 set aside · done by Dec 2027". **No progress bar** (owner, 2026-11-22; mockup 52's bar is superseded).

## 7. Amendments to the saving-target spec

| Saving-target decision | Now | Why |
|---|---|---|
| The saving-target spec's never-stops proposal (its D210; superseded by D213): reaching the target never stops the saving | **The saving stops by itself when reached**: the put-in that would pass `T` posts only `T − S`, then the rule posts nothing more. Applies to every saving with a target, not only ones made here | Owner, 2026-11-22: a goal stops when reached. The daily number rises again only after the user was told (the reached line), and *Keep saving* restores the put-ins |
| D211 (the saving-target spec's D208): what-if simulations rejected | Narrowed: a general simulator stays rejected; one affordability check for one purchase is allowed, on Spends | Owner, 2026-11-22 |
| Section 10: no progress bar | **Unchanged**, reaffirmed by the owner | Words only |

**When reached** (owner-approved): Home's reached line (saving-target D214) still shows once and opens the saving's sheet. The sheet then offers three choices; doing nothing is also fine:

| Choice | Effect |
|---|---|
| **I bought it** | Records a *Used* entry for the whole set-aside amount (BR-19), then deletes the saving as *Delete saving* does (history kept, Undo 4 s). The hero does not move |
| **Keep saving** | Clears the target and resumes the put-ins from the next due date; it becomes a plain saving |
| **Leave it** | Nothing. The money stays set aside; the row reads "reached" for as long as the user likes |

Moving the money elsewhere (an FD, another account) is not spending, so nothing needs recording; *Delete saving* stops tracking it. Buying something cheaper: *Used some of it* takes any amount up to the set-aside amount.

**Engine change (BR-9).** A saving with a target where `S ≥ T` posts nothing. The capped last put-in keeps `S = T` exactly. A catch-up after days away also stops at `T`. *Keep saving* clears `T`, so posting resumes; no back-posting of skipped months (D33).

## 8. Screens touched

| Screen | Change |
|---|---|
| Spends | The *Can I afford it?* card beside Ask AI. Layout tested at the `TestWindows` sizes |
| New sheet | Steps 2 to 4, full height over Spends; tabletop and two-pane as other sheets (`AdaptiveSplit.readableWidth`) |
| App shortcut | *Can I afford it?* (FR-WG), opening Spends with the sheet up |
| Saving sheet | When reached: *I bought it*, *Keep saving* (with *Leave it* = close) |
| Engine | Stop at target (section 7) |
| Home, Add, Ask AI | **Unchanged** |

## 9. Constraints

- Money is `int` paise in `Money`; display through `MoneyFormatter`; no paise shown. Today comes from `Clock`; cycle maths in `PeriodCalculator`.
- All copy in `app_en.arb`; no banned words; "card", never "credit".
- No network, no analytics; nothing typed here is logged.
- Marigold only on the one act key (*Next*, *See the answer*, *Start saving*). No red, green or category colours.
- Hugeicons through `AppIcon`; a laptop glyph for the item (or the generic shopping glyph; builder's pick).

## 10. Left to the builder

- Which bloc owns the sheet (a new `AffordBloc` under `lib/spends/` is the expected shape) and where the pure function lives (`lib/spends/domain/`).
- How `room`, `usual` and `days` are read through existing use cases (`GetCycleSummary`, the recurring repository, `PeriodCalculator`).
- The item glyph.
- Test layout per `tests.md`; the coverage gate applies.

## 10a. Settled after the builder check (designer's calls, for the owner to check)

1. **`room` is counted by dates, not by "monthly".** It is the income for the next cycle minus every bill and saving occurrence whose due date falls inside that cycle's dates (`PeriodCalculator`). This holds for weekly, month-end and 28 to 31-day cycles alike. Savings that have reached their target post nothing, so they add nothing.
2. **Re-checking something already being saved for.** If an active saving has the same name as the item (case-insensitive), step 3 is prefilled with that saving's set-aside amount, that saving is left out of `room`, and *Start saving* changes that saving instead of making a second one. A new saving starts with `S = 0`; `H` is never put in.
3. **History gate.** "Not enough history" covers both `usual` and *It changes* income: it needs one finished, fully tracked cycle. A cycle with no *Spent* entries (`usual = 0`) counts as not enough history, so the floor is never ₹0.
4. **Order of work.** The saving-target spec ships first (migration 007, backup schema 7). This feature follows it, with no schema change of its own. Nothing with a target exists in the field yet, so auto-stop affects no existing data.
5. **After reaching.** *I bought it* uses the whole set-aside amount, even if it is more than the price. A *Used* entry that brings `S` below `T` on a *Leave it* saving resumes the put-ins until `T` is reached again: the target is still the goal. *Keep saving* or *Delete saving* change that.
6. **Shared helpers.** "Done by" uses the saving-target spec's estimate function, with the new saving's first `next_due` predicted by the same helper that *Add a saving* uses. With no income set up, the shortcut opens Spends as it does today, with no sheet.

## 11. Doc changes needed (not made)

SPEC: a new BR (the answer), an FR for the Spends card and sheet, FR-WG (shortcut), BR-9 (stop at target), FR-SE-1 (reached choices), edge cases, glossary. UI_DESIGN: the Spends card, the sheet, copy. DECISIONS: rows for the check, the auto-stop (D213, supersedes the saving-target spec's never-stops proposal), the narrowed D211, the reached choices. The saving-target spec: a note pointing here for the amended decisions.
