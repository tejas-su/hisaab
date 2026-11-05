# Phase 2: Bills that change, and the card bill. Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A bill whose amount changes (electricity) or a credit card bill is set up once. On its day it isn't posted. It *waits*, and Home asks "How much?". One tap opens a keypad prefilled with last time's amount, and Save records it. A card bill is recorded but never counted, because the swipes already were.

**Architecture:**
- **Data.**
  - `RecurringRule` gains `AmountMode { fixed, varies, card }`, already a column since migration 003.
  - `EntryKind` gains `cardPaid` (stored `'card'`).
  - A skip is a row in `recurring_skips`.
  - **No migration.**
- **Waiting is derived, never stored.** A `varies`/`card` occurrence waits when all of these hold:
  - its date is in `[max(next_due, cycle.start), today]`;
  - no entry has its `(recurring_id, date)`;
  - no skip has its `(recurring_id, date)`.

  So deleting an entered bill makes it wait again, Undo needs no extra state, and a past cycle's unanswered bill drops out by itself (E-c, E-g).
- **The engine** posts only `fixed` rules (bills, savings, income). It never posts or moves `next_due` of a `varies`/`card` rule. For those rules `next_due` is only the lower bound "nothing before this may wait" (D33).
- **Formula.** `B` adds each waiting `varies` occurrence at its estimate (the rule's amount), and `card` rules are left out of `B` entirely. `SafeToSpend` is unchanged: an entered bill dated today is already `R_t` (D119).
- **Screens.**
  - A new **bill amount sheet**: the keypad in the bill sheet's route, the same pattern as *Put in extra*.
  - A Home **"How much?" line** that takes the nudge slot ahead of due-soon.
  - An **Amount changes?** row in the bill sheet.
  - Two new name pills in the wizard.

**Tech Stack:** Flutter 3.47 / Dart 3.13, sqflite (+ `sqflite_common_ffi` in tests), flutter_bloc + bloc_concurrency, fpdart, gen-l10n, hugeicons, hand-written fakes.

**Spec:** [docs/superpowers/specs/2026-11-04-savings-and-changing-bills-design.md](../specs/2026-11-04-savings-and-changing-bills-design.md): §9 phase 2, and the changing-bill and card parts of §2–§5, §7 and §8. Research: [case study 18](../../design-research/case-studies/18-variable-bills-and-quick-entry.md) and [case study 16](../../design-research/case-studies/16-bill-edit-flow.md). Phase 0 is in `dff4d34`, Phase 1 in `56d0576..03f90e1`, and the post-device fixes in `fbb04d4`.

## Where this plan departs from the spec (the code moved on)
- **No `GetWaitingBill` use case.** Waiting depends on the cycle, which only `GetCycleSummary` computes. So `CycleSummary.waitingBills` carries the list (oldest first, ties to the lower rule id, which is the rule saved first), and Home reads `waitingBills.first`.
- **`next_due` of a `varies`/`card` rule never moves.** The spec says the engine "advances next_due once entered or skipped". Deriving waiting from entries and skips gives the same answers, and Undo and delete then need no rule writes.
- **E-f (varies → fixed mid-cycle)** is met like this: `EditBill` moves `next_due` up to the **latest occurrence on or before today**, and only if that is later than `next_due`. The engine then posts that one occurrence at the estimate, unless it is already entered (the unique `(recurring_id, date)` index ignores it) or skipped (`post` now skips skipped dates). Older unanswered months are never back-posted (D34).
- **Onboarding keeps its 6 fixed pills.** Credit card and Electricity are offered only in Settings, because onboarding asks for an amount it treats as fixed.
- **The bill sheet already exists** (D118) and gains one row, *Amount changes?*. *Fixed bills* is renamed **Bills**, as Phase 1 deferred.
- **The "Remind you on the day?" ask** (spec §5, Adding) is Phase 3, with the notification.
- **Card bill line.** The spec writes "Card bill is due today". With a named card that loses *which* card, so the line uses the rule's label: "{bill} bill is due today. How much did you pay?". A rule named "Credit card" reads "Credit card bill is due today…". Settled in the copy deck (Task 1).

## Global Constraints
- Money is `int` paise in `Money`, and shares are floored to whole rupees. Never `double`; never show paise.
- "Today" comes from the injected `Clock`; tests pin it with `FakeClock` (`WorkedExample.now` = Mon 26 Oct 2026, 10:30).
- User-facing text lives only in `lib/l10n/app_en.arb`, followed by `flutter gen-l10n`. Banned words: "transaction", "debit/credit", "budget period", "Oops". "Card bill" and "Credit card" are allowed (spec §8). New words: *How much?*, *Didn't go out this month*, *Paid, not counted again*, *About how much?*.
- No red, no green, no new colour. A card bill is marked by its glyph and a word. Marigold only on the keypad's Save.
- The Add flow is untouched. A `cardPaid` entry is never editable in the tray.
- No new dependency (the notification package is Phase 3).
- Existing tests are the contract. A task that **changes** a documented rule names each test it changes and why, citing its DECISIONS row. Signature-only test edits (a new required argument, a props count) are listed in the task's report. Any other test going red means stop and ask.
- **Decision numbers.** Before writing a DECISIONS row, run `grep -o '^| D[0-9]*' docs/DECISIONS.md | sort -t D -k2 -n | tail -1` and use the next free number. This plan calls them D123 (changing bills wait; card bill not counted), D124 (E-f as built) and D125 (onboarding keeps 6 pills). Today's last row is D122.
- **Commits** are local only. Never `git push`, never add a remote. Commit once per task, staging only that task's files (`git status` first). Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Before Task 1:** run `git rev-parse HEAD` and keep the hash as `BASE`.
- **Pixel alignment:** every new row and sheet shares the page gutter (`HisaabSpacing.gutter`, D122). Each new widget gets an edge test.
- **Done** means:
  - `flutter analyze` is clean and `flutter test` is green;
  - `scripts/changed_lines_coverage.sh $BASE` is ≥ 90%, with gaps listed;
  - SPEC, UI_DESIGN and DECISIONS are updated;
  - mockup 29 covers the new screens;
  - new screens are tested at every `TestWindows` size;
  - the flows are checked on the Moto G45 (back up the DB first, as on 2026-11-05).

## Review Focus
1. **The engine must never post a `varies` or `card` rule.** If it did, the bill would count twice: once at the estimate and again when entered. → Task 2, test "the engine posts nothing for a changing bill or a card bill, and leaves next_due".
2. **Deleting an entered changing bill must make it wait again**, not vanish with its money back in the pool. → Task 3, test "deleting an entered bill puts it back in B and on the waiting list".
3. **A card bill never touches the pool**: not in `B`, not `R_t`, not spent (spec worked example 4). → Task 3, test "a card bill paid today leaves pool, share and hero unchanged".
4. **Ask AI must not crash on a `cardPaid` entry.** Its category is the hidden `card_paid`, which `_Names.of` (`_byId[id]!`) can't find, as with savings in Phase 1. → Task 8, test "a card bill is listed as kind card_bill_paid, category card bill".
5. **Switching a long-ignored changing bill to *Same every month* must not back-post old months** (`next_due` can be months stale). → Task 4, test "switching to fixed posts at most the latest unanswered occurrence".
6. **Tapping a card-bill row must not open the Add tray**, which would turn it into spending. → Task 7, test "a card bill row has no tap action but can be swiped away".

---

## File map
| File | Responsibility | Task |
|---|---|---|
| `docs/design/mockups/29-changing-bills-copy-deck.md`, `29-changing-bills.html` (new), `lib/l10n/app_en.arb` | Every Phase 2 string and the mockup | 1 |
| `lib/ledger/domain/entities/{amount_mode.dart (new), recurring_rule.dart, recurring_draft.dart, entry_kind.dart, bill_kind.dart, bill_skip.dart (new), category.dart}` | `AmountMode`, `cardPaid`, two pills, skip identity | 2 |
| `lib/ledger/data/{mapper/recurring_mapper.dart, mapper/entry_kind_mapper.dart, model/recurring_model.dart, datasource/recurring_local_data_source.dart, repository/recurring_repository_impl.dart, datasource/entries_local_data_source.dart, repository/ledger_repository_impl.dart}`, `domain/repository/{recurring,ledger}_repository.dart` | `amount_mode` column, skips, `post` skips skipped dates, `addForRule` | 2 |
| `lib/ledger/domain/usecase/post_due_recurring.dart` | Engine posts only `fixed` rules | 2 |
| `lib/onboarding/presentation/widgets/bills_step.dart` | Keeps the 6 fixed pills | 2 |
| `lib/ledger/domain/waiting_bills.dart` (new), `due_amounts.dart`, `entities/cycle_summary.dart`, `usecase/get_cycle_summary.dart`, `safe_to_spend.dart` (pass-through only) | Waiting list; `B` with estimates; card out of `B` | 3 |
| `lib/ledger/domain/usecase/{enter_bill_amount.dart, undo_bill_amount.dart, skip_bill_occurrence.dart, unskip_bill_occurrence.dart} (new)`, `add_bill.dart`, `edit_bill.dart`, `entities/bill_input.dart`, `core/di/ledger_module.dart` | Use cases | 4 |
| `lib/ledger/presentation/rule_words.dart`, `lib/settings/presentation/**` (bills page title, name step, amount step, bill sheet bloc/state/event, `bill_mode_question.dart` (new), `bill_summary.dart`) | Bills rename, pills, mode-aware amount question, *Amount changes?* | 5 |
| `lib/settings/presentation/bloc/bill_amount_{bloc,event,state}.dart`, `pages/bill_amount_sheet.dart` (new), `lib/app/routes.dart` | The bill amount sheet | 6 |
| `lib/home/presentation/{bloc/home_*.dart, pages/home_page.dart, widgets/waiting_bill_row.dart (new), widgets/due_soon_row.dart}`, `lib/ledger/presentation/widgets/entry_row.dart` | "How much?" line, "about" in due-soon, card row, snackbars | 7 |
| `lib/ask_ai/domain/{prompt_builder.dart, usecase/get_prompt_input.dart}`, `lib/spends/**` (verify only) | CSV kind, recurring marks; Spends exclusions | 8 |
| `docs/SPEC.md`, `docs/UI_DESIGN.md`, `docs/PLAN.md`, `docs/DECISIONS.md`, `docs/design-research/README.md` | Docs and the phase check | 9 |

---

### Task 1: The words and the mockup

**Files:**
- Create: `docs/design/mockups/29-changing-bills-copy-deck.md`, `docs/design/mockups/29-changing-bills.html`
- Modify: `lib/l10n/app_en.arb`, `docs/design/README.md` (index row)

**Interfaces:**
- Produces ARB keys that later tasks use. Placeholders are `String` unless marked.

  | Key | English | Used by |
  |---|---|---|
  | `bills` | Bills | Settings row, list title (replaces the *Fixed bills* text; keep the key `fixedBills` and change its value) |
  | `billName` select | add `creditCard`: Credit card, `electricity`: Electricity | pills |
  | `billAmountQuestionVaries` | About how much is {bill}? | wizard, sheet |
  | `billAmountQuestionCard` | About how much is the {bill} bill? | wizard, sheet |
  | `billCardHint` | Add card buys when you make them. This only reminds you to pay, so nothing counts twice. | wizard, sheet |
  | `billModeRow` | Amount changes? | sheet row label |
  | `billModeFixed` / `billModeVaries` / `billModeCard` | Same every month / Changes every month / Credit card | sheet row value and chips |
  | `waitingVariesToday` | {bill} went out today. How much? | Home line |
  | `waitingVariesOn` | {bill} went out on {date}. How much? | Home line |
  | `waitingCardToday` | {bill} bill is due today. How much did you pay? | Home line |
  | `waitingCardOn` | {bill} bill was due on {date}. How much did you pay? | Home line |
  | `waitingOpensHint` | Opens the keypad | TalkBack hint |
  | `billGoesOutAbout` | {bill} about {amount} goes out {when} | due-soon for `varies`/`card` (the `when` words are the existing due-soon day words) |
  | `billAmountTitle` | {bill} · {date} | amount sheet title |
  | `billAmountLastTime` | Last time {amount} | amount sheet caption |
  | `billDidntGoOut` | Didn't go out this month | amount sheet chip |
  | `billAmountAdded` | {bill} {amount} added | snackbar |
  | `billSkipped` | {bill} skipped this month | snackbar |
  | `entryCardPaid` | Paid, not counted again | card row line |

- [ ] **Step 1:** Dispatch the `design-content` agent with this table, spec §5 and §8, and copy deck 28 as the format. Ask it to confirm or improve each line against the voice rules and banned words. The card line above is a recorded departure, and the agent may only tighten it. Write the result to `29-changing-bills-copy-deck.md` in deck 28's table format (key, English, placeholder?, note).
- [ ] **Step 2:** Build `29-changing-bills.html` from `28-savings.html`'s frame. Show light and dark versions of:
  - (a) Home with the "How much?" line in the nudge slot;
  - (b) the bill amount sheet prefilled with ₹1,200, caption "Last time ₹1,200", the chip and a marigold Save;
  - (c) a Today list with a card-bill row "Credit card · Paid, not counted again · ₹8,000";
  - (d) the bill sheet with the *Amount changes?* row and its question.

  Use the spec's worked example numbers and the 20px sheet inset (D122). Add the index row to `docs/design/README.md`.
- [ ] **Step 3:** Add the keys to `app_en.arb` with `@` descriptions and placeholders, then run `flutter gen-l10n`.
- [ ] **Step 4:** Run `flutter analyze` and `flutter test test/l10n` (if present) or the full suite. Expected: clean, green. The `fixedBills` value change will turn the tests that find "Fixed bills" red. List each of them, and change its expectation to "Bills" only after confirming that the spec (§5 IA) renames it. That is a documented rule change; cite D123.
- [ ] **Step 5:** Commit `docs(changing-bills): copy deck, mockup and strings`.

---

### Task 2: Data: amount mode, the card kind, skips, and an engine that waits

**Files:**
- Create: `lib/ledger/domain/entities/amount_mode.dart`, `lib/ledger/domain/entities/bill_skip.dart`
- Modify: the entities, mappers, model, data sources, repositories and engine in the file map (Task 2 rows); `lib/onboarding/presentation/widgets/bills_step.dart`; `test/helpers/fakes/fake_recurring_repository.dart`, `fake_ledger_repository.dart`; `test/helpers/fixtures/ledger/categories.dart` (`SeedCategoryIds.cardPaid = 12`; check the id the migration seeds)
- Test: `test/ledger/data/**` (mapper, repository with `sqflite_common_ffi`), `test/ledger/domain/usecase/post_due_recurring_test.dart`, `test/onboarding/presentation/widgets/bills_step_test.dart`

**Interfaces:**
- Produces:
  - `enum AmountMode { fixed, varies, card }`
  - `RecurringRule.amountMode` (default `AmountMode.fixed`; in `props`, `draft` and `copyWith(amountMode:, categoryId:)`; `categoryId` is added to `copyWith` for Task 4). The same field goes on `RecurringDraft`.
  - `EntryKind.cardPaid`, documented as "a credit card bill paid; recorded, never counted (the swipes were)".
  - `CategoryKeys.cardPaid = 'card_paid'`.
  - `BillKind.creditCard` and `BillKind.electricity`, appended **after** `subscriptions`. Their mappings:

    | Getter | `creditCard` | `electricity` | Others |
    |---|---|---|---|
    | `amountMode` | `card` | `varies` | `fixed` |
    | `icon` | `BillIcon.card` | `BillIcon.power` | unchanged |
    | `categoryKey` | `CategoryKeys.cardPaid` | `bills` | unchanged |
  - `final class BillSkip extends Equatable { const BillSkip({required int ruleId, required CalendarDate date}); }`
  - `RecurringRepository`:
    - `TaskEither<Failure, Unit> skip(BillSkip skip)` and `TaskEither<Failure, Unit> unskip(BillSkip skip)`. Both emit on `changes`. `skip` ignores a duplicate.
    - `TaskEither<Failure, List<BillSkip>> skipsBetween(CalendarDate from, CalendarDate to)`, inclusive.
    - `post` now leaves out any occurrence whose `(recurring_id, date)` is in `recurring_skips`. That is checked inside the same transaction in the data source.
  - `LedgerRepository.addForRule(EntryDraft draft, {required int recurringId}) → TaskEither<Failure, Entry>`. It inserts with `recurring_id` set, emits `changes`, and returns `DatabaseFailure` on the unique-index clash.
  - The repository's posted note becomes `rule.label` for `saved` **and** card entries (`_validatedModel`). Bills keep `null`.

- [ ] **Step 1: Write the failing tests:**

  | Test | Asserts |
  |---|---|
  | Mapper round-trip | `'varies'` ↔ `AmountMode.varies`, `'card'` ↔ `EntryKind.cardPaid`. An unknown `amount_mode` string maps to `InvalidDataFailure`, as the existing kind mapper does. |
  | Repository (ffi) | `skip` then `skipsBetween` returns it; `unskip` removes it; `skip` twice keeps one row; `post` of an occurrence that is skipped inserts 0; `addForRule` sets `recurring_id` and a second `addForRule` for the same rule and date is `Left(DatabaseFailure)`. |
  | `post_due_recurring_test` | "the engine posts nothing for a changing bill or a card bill, and leaves next_due" (Review Focus 1): rules electricity `varies` and card `card`, both with `nextDue` 20 Oct and today 26 Oct. Expect 0 posted and `next_due` unchanged. A `fixed` rule alongside still posts. |
  | `bills_step_test` | Onboarding shows exactly the 6 fixed pills, with no "Credit card" or "Electricity" (D125). |

- [ ] **Step 2:** Run `flutter test test/ledger test/onboarding`. Expected: compile errors or FAIL on the new members.
- [ ] **Step 3:** Implement. The engine change is one filter in `PostDueRecurring._postingFor`: `rule.amountMode == AmountMode.fixed`. Onboarding filters `BillKind.values.where((BillKind k) => k.amountMode == AmountMode.fixed)` in `bills_step.dart`, and the onboarding mapper keeps `values` so stored drafts still parse. Every `switch` on `EntryKind` now fails to compile until it has a `cardPaid` arm:
  - mapper: `'card'`;
  - prompt CSV: Task 8 (here, `card_bill_paid`);
  - the rest: treat it like `saved` (not spending). Note each one in the report.
- [ ] **Step 4:** Run `flutter analyze && flutter test`. Expected: clean, all green. List any props-count test edits.
- [ ] **Step 5:** Commit `feat(ledger): amount mode, card kind and skips; the engine posts fixed rules only`.

---

### Task 3: The formula: waiting bills and `B` with estimates

**Files:**
- Create: `lib/ledger/domain/waiting_bills.dart`
- Modify: `lib/ledger/domain/due_amounts.dart`, `entities/cycle_summary.dart`, `usecase/get_cycle_summary.dart`, `safe_to_spend.dart` (only to pass `waitingBills` through to `CycleSummary`)
- Test: `test/ledger/domain/waiting_bills_test.dart` (new), `test/ledger/domain/usecase/get_cycle_summary_test.dart`

**Interfaces:**
- Consumes: Task 2's `AmountMode`, `BillSkip`, `skipsBetween`.
- Produces:
  - `abstract final class WaitingBills { static List<Occurrence> of(Iterable<RecurringRule> rules, {required List<Entry> entries, required List<BillSkip> skips, required CalendarDate today, required PayCycle cycle}); }`. It covers `varies` and `card` rules only. The dates come from `RecurringSchedule.datesFrom(schedule, firstOnOrAfter(schedule, later of nextDue and cycle.start), through: today)`, minus those with an entry `(recurringId, date)` and minus skips. The result is sorted by date, then rule id.
  - `CycleSummary.waitingBills: List<Occurrence>`, default `const []`.
  - The `bills` due in `GetCycleSummary` becomes `DueAmounts.after(spent rules whose amountMode != card) + Σ estimate of waiting varies occurrences`. Card rules are in neither part.

- [ ] **Step 1: Write the failing tests.** `waiting_bills_test` uses a `varies` electricity rule anchored on day 20 with `nextDue` 20 Oct, cycle 4 Oct–3 Nov, and today 26 Oct:

  | Test | Expect |
  |---|---|
  | waits from its day | `[Occurrence(rule, 20 Oct)]` |
  | an entry on that date answers it | `[]` |
  | a skip answers it | `[]` |
  | a fixed rule never waits | `[]` |
  | last cycle's unanswered one drops out (E-c, E-g) | `nextDue` 20 Sep, day 20, today 26 Oct → only 20 Oct |
  | not before next_due (D33) | `nextDue` 20 Nov → `[]` |
  | oldest first, ties to the lower id | two rules on the same day, ids 9 and 5 → 5 first |
  | day 31 in a 30-day month (E-a) | anchor 31, today 30 Nov, cycle covering it → waits on 30 Nov |

  `get_cycle_summary_test` uses the spec's worked example 2 and 4 fixture: rules = `WorkedExample.salary` plus one bill; entries give `I` = 45,000, `S_prev` = 27,150 and ₹420 typed today. Build it from `WorkedExample.entries`, or a minimal set that gives those totals; the existing BR-3 tests show how.

  | Test | Expect |
  |---|---|
  | "a changing bill due today waits at its estimate" | electricity `varies` ₹1,200 due 26 Oct, not entered → `pool` 16,650, `todayShare` 1,850, hero 1,430; `waitingBills.single.date` 26 Oct |
  | "entering it moves it from B to today's bills" | plus an entry ₹1,460 with `recurringId` and date 26 Oct → `pool` 16,390, `todayShare` 1,821, hero 1,401; `waitingBills` empty |
  | "deleting an entered bill puts it back in B and on the waiting list" (Review Focus 2) | load with the entry, remove it from the fake, load again → 16,650 / 1,850 and waiting again |
  | "a card bill paid today leaves pool, share and hero unchanged" (Review Focus 3, example 4) | a card rule ₹8,000 due 26 Oct: compare the summary waiting vs. with a `cardPaid` ₹8,000 entry. `pool`, `todayShare` and `spentToday` are equal in both. Card is never in `B`: the pool equals the no-card fixture's pool. |
  | "a skipped bill leaves B" | `skipsBetween` returns the skip → `pool` 17,850 (no `B`) |
  | "a future changing bill is in B at its estimate" | due 30 Oct, today 26 Oct → `pool` 16,650 and nothing waiting |

- [ ] **Step 2:** Run `flutter test test/ledger/domain`. Expected: FAIL (missing `WaitingBills`, wrong pool).
- [ ] **Step 3:** Implement. `GetCycleSummary._summarise` reads `skipsBetween(cycle.start, today)` after `entriesBetween`, adding one more `flatMap`. `_asItStood` keeps using `due.bills` plus `postedSince(spent)`. An entered varies bill is a `spent` entry with `recurringId`, so that already works; add a test "yesterday's share is unchanged by a bill entered today" that checks `savedYesterday` against the no-bill fixture.
- [ ] **Step 4:** Run `flutter test`. Expected: all green, and the existing BR-3…BR-8 tests are untouched.
- [ ] **Step 5:** Commit `feat(ledger): changing bills wait and are reserved at their estimate; card bills never count`.

---

### Task 4: Use cases: enter, undo, skip, unskip; add and edit by mode

**Files:**
- Create: `lib/ledger/domain/usecase/{enter_bill_amount,undo_bill_amount,skip_bill_occurrence,unskip_bill_occurrence}.dart`
- Modify: `add_bill.dart`, `edit_bill.dart`, `entities/bill_input.dart`, `lib/core/di/ledger_module.dart`, `lib/ledger/ledger.dart` (exports), `test/helpers/fake_services.dart`
- Test: one test file per use case under `test/ledger/domain/usecase/`

**Interfaces:**
- Consumes: Task 2's `addForRule`, `skip`, `unskip`, `AmountMode`, `CategoryKeys.cardPaid`; `CategoryRepository.idOf`.
- Produces:
  - `EnterBillAmount({required LedgerRepository ledger, required RecurringRepository recurring})`, with `call(EnterBillAmountParams(occurrence: Occurrence, amount: Money)) → TaskEither<Failure, BillAmountEntered>`.
    - It adds `EntryDraft(amount, kind: rule.amountMode == card ? cardPaid : spent, categoryId: rule.categoryId, date: occurrence.date, note: card ? rule.label : null)` via `addForRule`, then `recurring.update(rule.copyWith(amount: amount))` (the estimate becomes the last amount).
    - `final class BillAmountEntered { final Entry entry; final RecurringRule previous; }`, where `previous` is the rule as it was, for Undo.
    - A zero amount is `Left(InvalidAmountFailure)` (reuse `EntryValidator`'s failure) and nothing is written.
  - `UndoBillAmount({ledger, recurring})`, with `call(BillAmountEntered) → TaskEither<Failure, Unit>`. It deletes the entry and then updates the rule back to `previous` (E-e).
  - `SkipBillOccurrence({recurring})`, with `call(Occurrence) → TaskEither<Failure, BillSkip>`. `UnskipBillOccurrence({recurring})`, with `call(BillSkip) → TaskEither<Failure, Unit>`.
  - `BillInput.amountMode` (default `fixed`).
  - `AddBill` sets the rule's `amountMode` from `params.kind.map((k) => k.amountMode)`, defaulting to `fixed`. The card category comes through `kind.categoryKey` and `idOf` (hidden).
  - `EditBill` takes `CategoryRepository` too. When `input.amountMode != rule.amountMode`:
    - it sets `amountMode`;
    - on a change **to** or **from** `card`, it sets `categoryId` to `idOf(CategoryKeys.cardPaid)` or `idOf(CategoryKeys.bills)`;
    - on a change from `varies`/`card` **to** `fixed`, it sets `nextDue` to the later of `rule.nextDue` and `latest`, where `latest = RecurringSchedule.previous(schedule, RecurringSchedule.firstUnpostedAfter(schedule, rule.nextDue, today: today))`. This is D124, and the `// why:` cites D34.

- [ ] **Step 1: Write the failing tests:**

  | Test | Asserts |
  |---|---|
  | Enter, varies | posts a `spent` entry with `recurringId`, date 20 Oct, ₹1,460; the rule's amount becomes ₹1,460; `previous.amount` is ₹1,200 |
  | Enter, card | the kind is `cardPaid`, the note is the label, and the category is the rule's |
  | Enter, ₹0 | `Left`, and both fakes recorded nothing |
  | Enter, entry write fails | `Left(DatabaseFailure)` and the rule is unchanged |
  | Undo | the entry is gone and the rule equals `previous` |
  | Skip / unskip | the fake's skips contain, then lack, `BillSkip(ruleId, 20 Oct)` |
  | AddBill | `creditCard` → `amountMode: card`, category `SeedCategoryIds.cardPaid`; `electricity` → `varies`, category bills; a typed name → `fixed` |
  | EditBill | fixed → card switches the category to card_paid; card → varies switches it back to bills; a mode-only edit keeps the schedule |
  | "switching to fixed posts at most the latest unanswered occurrence" (Review Focus 5) | a varies rule anchored on day 20 with `nextDue` 20 Jul, today 26 Oct, edited to fixed: `nextDue` becomes 20 Oct. Then run `PostDueRecurring` on the fake and expect exactly 1 posted, dated 20 Oct, at the estimate. |
  | Already entered | with an entry already on 20 Oct, the engine inserts 0 (the ffi repository test from Task 2 covers the ignore; here assert that `nextDue` is still 20 Oct) |

- [ ] **Step 2:** Run the use-case tests. Expected: FAIL.
- [ ] **Step 3:** Implement, register in `ledger_module.dart` and `fake_services.dart`, and export from `ledger.dart`.
- [ ] **Step 4:** Run `flutter analyze && flutter test`. Expected: clean and green. `EditBill`'s new constructor argument is a signature-only change in its tests; list it.
- [ ] **Step 5:** Commit `feat(ledger): enter, undo and skip a changing bill; add and edit by amount mode`.

---

### Task 5: Settings: *Bills*, the two pills, and *Amount changes?*

**Files:**
- Create: `lib/settings/presentation/widgets/bill_sheet/bill_mode_question.dart`
- Modify: `lib/ledger/presentation/rule_words.dart`, `lib/settings/presentation/widgets/bill_name_step.dart`, `bill_amount_step.dart`, `bill_sheet/{bill_summary.dart, bill_amount_question.dart, bill_sheet_copy.dart}`, `bloc/bill_sheet_{bloc,event,state}.dart`, `bloc/bill_editor_{bloc,state}.dart`
- Test: the matching files under `test/settings/presentation/**` and `test/ledger/presentation/rule_words_test.dart`

**Interfaces:**
- Consumes: Task 1's keys; Task 4's `BillInput.amountMode` and `EditBill`.
- Produces:
  - `RuleWords.ruleAmountQuestion(EntryKind kind, String label, AmountMode mode)`. Saving words are unchanged; for a bill, `varies` and `card` pick the new keys. Every call site passes the mode.
  - `BillAnswer.mode`, a new value between `amount` and `day`. It is shown for `spent` rules only, never for savings.
  - `BillSheetModeChosen(AmountMode mode)`, an event with the `droppable()` transformer, like `BillSheetDayChosen`.
  - `BillModeQuestion({required AmountMode current, required ValueChanged<AmountMode> onChosen})`: three `HisaabChip.onSurface` chips in one column, with the picked one filled `ink` (UI_DESIGN chip rules).
  - The wizard's amount step shows `billCardHint` under the question when the picked pill is `creditCard`.

- [ ] **Step 1: Write the failing tests:**

  | Test | Asserts |
  |---|---|
  | Settings and the list title | read "Bills" |
  | The name step | shows 8 pills in two columns, with "Credit card" and "Electricity" last; at large text, one column (the existing rule) |
  | The amount question | picking Electricity gives "About how much is Electricity?"; picking Credit card gives "About how much is the Credit card bill?" plus the hint line; a typed name gives "How much is Water?" |
  | The bill sheet | shows the row "Amount changes? · Same every month" for a fixed bill and none for a saving; tapping it shows the 3 chips; choosing "Changes every month" calls `EditBill` with `amountMode: varies`, returns to the summary and says "Saved." |
  | Edges | the mode chips start on the sheet's gutter (edge test as in `bill_sheet_test` "page gutter"); the bill sheet fits at every `TestWindows` size (extend the existing size loop) |

- [ ] **Step 2:** Run `flutter test test/settings test/ledger/presentation`. Expected: FAIL.
- [ ] **Step 3:** Implement. `BillSummary` lists the rows Amount, **Amount changes?**, Day, Name, Icon (for bills). Its value text is `billModeFixed`/`billModeVaries`/`billModeCard`.
- [ ] **Step 4:** Run `flutter analyze && flutter test`. Expected: clean and green. Existing tests that count four rows change to five; cite D123 and list them.
- [ ] **Step 5:** Commit `feat(settings): Bills with Credit card and Electricity, and an Amount changes? row`.

---

### Task 6: The bill amount sheet

**Files:**
- Create: `lib/settings/presentation/bloc/bill_amount_{bloc,event,state}.dart`, `lib/settings/presentation/pages/bill_amount_sheet.dart`
- Modify: `lib/app/routes.dart`
- Test: `test/settings/presentation/bloc/bill_amount_bloc_test.dart`, `test/settings/presentation/pages/bill_amount_sheet_test.dart`

**Interfaces:**
- Consumes: Task 4's `EnterBillAmount`, `SkipBillOccurrence`, `BillAmountEntered`; `Haptics`; the keypad pieces `PutInExtraBloc` uses (`AmountInput.append`, `.backspace`).
- Produces:
  - `BillAmountBloc({required Occurrence occurrence, required EnterBillAmount enter, required SkipBillOccurrence skip, required Haptics haptics})`.
    - The state starts as `BillAmountEditing(rupees: estimate in rupees, fresh: true, saving: false)`. The first digit replaces the prefilled amount, as `BillSheetKeyPressed` does.
    - Events: `BillAmountKeyPressed(String key)`, `BillAmountBackspacePressed`, `BillAmountCleared`, `BillAmountSaved` (`droppable()`), `BillAmountSkipped` (`droppable()`).
    - Terminal states: `BillAmountDone(BillAmountOutcome)` and `BillAmountFailed` (it stays open).
  - `sealed class BillAmountOutcome`: `BillAmountWasEntered(BillAmountEntered)`, `BillAmountWasSkipped(BillSkip, String label)`.
  - `BillAmountSheet.show(BuildContext, BillAmountBloc) → Future<Option<BillAmountOutcome>>`. It uses `BillSheet.route` like `PutInSheet.show`, and returns none on Back.
  - Layout:
    - `billAmountTitle` ("Electricity · 20 Oct");
    - the amount in Anek;
    - `billAmountLastTime` in `ink2`;
    - for a card, `billCardHint` under it;
    - the keypad;
    - the marigold Save;
    - the text chip `billDidntGoOut` above the keypad.

    The content starts on the gutter (D122).
  - Haptics: `tick` on Save, as *Put in extra* does.

- [ ] **Step 1: Write the failing tests.**

  Bloc:

  | Test | Asserts |
  |---|---|
  | Prefill | the initial state is ₹1,200, fresh |
  | Typing | `4`,`6`,`0` → ₹460, so the first key replaced the estimate |
  | Save | `EnterBillAmount` is called with ₹460 and emits `Done(WasEntered)` |
  | Save untouched | saves ₹1,200 ("same as last time" in one tap) |
  | Save at ₹0 | nothing, and no write |
  | Skip | emits `Done(WasSkipped)` |
  | `droppable()` | a gated second Save writes once |
  | Failure | emits Failed, then editing again |
  | Close | closing mid-save completes |

  Page:

  | Test | Asserts |
  |---|---|
  | Opening | shows "Electricity · 20 Oct", "₹1,200" and "Last time ₹1,200" |
  | Save | closes and `show` completes with the outcome |
  | The chip | skips |
  | A card | shows the hint |
  | Fit | at every `TestWindows` size |
  | Edge | the title starts at `HisaabSpacing.gutter` from the sheet's left |
  | a11y | tap target, label and contrast guidelines pass |

- [ ] **Step 2:** Run the new tests. Expected: FAIL.
- [ ] **Step 3:** Implement. Mirror `put_in_extra_bloc.dart` and `put_in_sheet.dart` where the shape matches; there is no preview line. Add a route builder in `routes.dart` that builds the bloc from `GetIt` with the occurrence.
- [ ] **Step 4:** Run `flutter analyze && flutter test`. Expected: clean and green.
- [ ] **Step 5:** Commit `feat(settings): the bill amount sheet`.

---

### Task 7: Home: the "How much?" line, "about" in due-soon, and the card row

**Files:**
- Create: `lib/home/presentation/widgets/waiting_bill_row.dart`
- Modify: `lib/home/presentation/{bloc/home_bloc.dart, bloc/home_event.dart, bloc/home_state.dart, pages/home_page.dart, widgets/due_soon_row.dart}`, `lib/ledger/presentation/widgets/entry_row.dart`, `lib/ledger/presentation/rule_words.dart` (`ruleGoesOut` gains the `about` form), `lib/app/routes.dart`
- Test: `test/home/presentation/**`, `test/ledger/presentation/widgets/entry_row_test.dart`

**Interfaces:**
- Consumes:
  - Task 3's `CycleSummary.waitingBills`;
  - Task 6's `BillAmountSheet` and `BillAmountOutcome`;
  - Task 4's `UndoBillAmount` and `UnskipBillOccurrence`.
- Produces:
  - `HomePage.onEnterBill: Future<Option<BillAmountOutcome>> Function(Occurrence)`, wired in `routes.dart`.
  - The page handles the outcome:
    - it adds `HomeBillAmountDone(BillAmountOutcome)`;
    - `HomeReady.amountUndo: Option<BillAmountOutcome>` drives a snackbar, following the existing `billUndo` pattern: `billAmountAdded("Electricity", "₹1,460")` or `billSkipped("Electricity")`, each with Undo;
    - Undo adds `HomeBillAmountUndoRequested(outcome)`, which runs `UndoBillAmount` or `UnskipBillOccurrence`.
  - `WaitingBillRow({required Occurrence occurrence, required CalendarDate today, required VoidCallback onTap})` shows:
    - the rule glyph;
    - the line (`waitingCardToday`/`waitingCardOn` for card, `waitingVariesToday`/`waitingVariesOn` for varies);
    - a trailing chevron;
    - its TalkBack hint `waitingOpensHint`.

    It sits in the nudge slot where `DueSoonRow` sits, at the same edges.
  - Nudge priority: `waitingBills.first` if any, else the due-soon row, else nothing (spec §5 Home).
  - `DueSoonRow` for a `varies`/`card` rule reads `billGoesOutAbout` ("Electricity about ₹1,200 goes out tomorrow").
  - `EntryRow` for `cardPaid`:
    - the title is the note (the rule's label), falling back to `billName('creditCard')`;
    - the line is `entryCardPaid`;
    - the glyph is `BillIcon.card`'s;
    - the amount is plain;
    - `onTap: null`, extending the `_isSaved` guard to card entries.

- [ ] **Step 1: Write the failing tests:**

  | Test | Asserts |
  |---|---|
  | Varies, today | with electricity varies due 26 Oct waiting, Home shows "Electricity went out today. How much?" in place of the due-soon line; tapping it calls `onEnterBill` with the occurrence |
  | Card, earlier | a card rule due 24 Oct waiting shows "Credit card bill was due on 24 Oct. How much did you pay?" |
  | Priority | waiting beats a due-soon bill that is also present |
  | Due-soon "about" | for a varies bill due tomorrow and nothing waiting: "Electricity about ₹1,200 goes out tomorrow" |
  | Outcome entered | shows "Electricity ₹1,460 added" with Undo; Undo calls `UndoBillAmount` (assert on the fakes: entry gone, rule amount back) |
  | Outcome skipped | shows "Electricity skipped this month"; Undo unskips |
  | "a card bill row has no tap action but can be swiped away" (Review Focus 6) | `EntryRow` with a `cardPaid` entry shows "Paid, not counted again"; tapping calls nothing; a swipe calls `onDelete` |
  | Edge | `WaitingBillRow`'s glyph left equals `DueSoonRow`'s at `TestWindows.phone`; Home passes the a11y guideline test with the line shown |
  | Bar and hero | a card bill paid today is not a bite on today's bar, and the hero is unchanged (widget-level check of Task 3's numbers: hero 1,430) |

- [ ] **Step 2:** Run `flutter test test/home test/ledger/presentation`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `flutter analyze && flutter test`. Expected: clean and green.
- [ ] **Step 5:** Commit `feat(home): ask how much a changing bill was; card bills shown, never counted`.

---

### Task 8: Ask AI and Spends

**Files:**
- Modify: `lib/ask_ai/domain/prompt_builder.dart`, `lib/ask_ai/domain/usecase/get_prompt_input.dart` (only if the card rules need passing separately)
- Test: `test/ask_ai/domain/prompt_builder_test.dart`, `test/spends/domain/usecase/get_spends_overview_test.dart`, `test/spends/presentation/pages/entries_page_test.dart`

**Interfaces:**
- Produces:
  - The CSV `kind` for `cardPaid` is `card_bill_paid`, with category `card bill`. Mirror Phase 1's `_savingsCategory` constant so `_Names.of` is never called with the hidden id.
  - The recurring list row for a `varies` bill ends `(changes, about ₹1,200)`, and for a `card` bill `(credit card; purchases already listed)`.
  - The facts line's "Spent … got …" totals exclude `cardPaid`. They already do, since they sum by kind; pin that with a test.

- [ ] **Step 1: Write the failing tests:**

  | Test | Asserts |
  |---|---|
  | Ask AI CSV (Review Focus 4) | "a card bill is listed as kind card_bill_paid, category card bill": a `cardPaid` entry in category 12 builds without throwing, and the row contains `card_bill_paid,card bill` |
  | Ask AI recurring list | the expected marks appear for a varies and a card rule |
  | Spends overview | a `cardPaid` ₹8,000 entry changes neither `spent`, the rows, the percentages nor the pace; `saved` is unchanged |
  | Every entry | lists the card row with "Paid, not counted again", and the day total excludes it |

- [ ] **Step 2:** Run. Expected: FAIL for the CSV and the marks. The Spends tests may already pass; keep them as pins and say so.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `flutter analyze && flutter test`. Expected: clean and green.
- [ ] **Step 5:** Commit `feat(ask_ai): card bills and changing bills in the export`.

---

### Task 9: Docs and the phase check

**Files:** `docs/SPEC.md`, `docs/UI_DESIGN.md`, `docs/PLAN.md`, `docs/DECISIONS.md`, `docs/design-research/README.md` (mark case study 18 built)

- [ ] **Step 1: SPEC.**
  - BR-3: `B` now includes waiting `varies` occurrences at their estimate and never `card` rules.
  - BR-4: `A` recomputes when a bill amount is entered today.
  - BR-9: the engine posts `fixed` rules only; waiting is derived; skips.
  - BR-10: a card entry is never edited in the tray.
  - FR-HO-3: the nudge priority and the lines.
  - FR-SE-1: *Bills*, 8 pills and the *Amount changes?* row.
  - A new FR for the bill amount sheet, with ACs mirroring Task 6's tests.
  - §5: E-a…E-k from spec §7, with E-f as built (D124).
  - FR-AI: the CSV kind and the marks.

  Tests cite these IDs; update the citing comments in the new tests if any ID changed.
- [ ] **Step 2: UI_DESIGN.** Settings rows, the bill sheet row, the bill amount sheet, the Home line, the card row and mockup 29 links.
- [ ] **Step 3: DECISIONS.** Add D123 (changing bills wait and are reserved at their estimate; card bills recorded, not counted; the *Bills* rename), D124 (E-f as built, no back-post beyond the latest occurrence), and D125 (onboarding keeps 6 fixed pills). Check the next free number first.
- [ ] **Step 4: PLAN.** Update §2's defaults (a card bill's default: remind, never count) and the milestone line.
- [ ] **Step 5: Verify.** Run `flutter analyze`, `flutter test` and `scripts/changed_lines_coverage.sh $BASE`. Expected: clean, green and ≥ 90%. List the never-taken branches of each changed file (tests.md) and either test them or list them as gaps.
- [ ] **Step 6: Whole-branch review.** Dispatch one reviewer on `$BASE..HEAD` against the spec and this plan's Review Focus. Fix Important findings test-first.
- [ ] **Step 7: Device check on the Moto G45** (`live-app-inspection`):
  1. Back up the DB to the scratchpad.
  2. Add Electricity with its day set to today, and check that the Home line appears. Enter an amount and Undo it, then skip it and Undo that.
  3. Add a Credit card due today: the line reads "…bill is due today", entering it leaves the hero unchanged, and the row reads "Paid, not counted again".
  4. Check that Spends is unchanged by the card.
  5. Restore the DB and verify it with `cmp`.
- [ ] **Step 8:** Commit `docs: changing bills and card bill in SPEC, UI_DESIGN, PLAN and decisions`.

---

## Self-review (done while writing)
- **Spec coverage:**
  - §2's `cardPaid` row → Tasks 2, 3, 7, 8.
  - §3: `B` with estimates, BR-4 recompute, worked examples 2 and 4 → Task 3.
  - §4: `AmountMode`, `BillKind` pills, engine rule, enter/skip use cases → Tasks 2, 4. `GetWaitingBill` → `CycleSummary.waitingBills` (departure noted).
  - §5:
    - Bills rename, pills, amount questions, card hint, *Amount changes?* → Task 5;
    - bill amount sheet → Task 6;
    - Home nudge priority, "about", card row → Task 7;
    - Spends exclusions, Every entry → Task 8;
    - Ask AI → Task 8.
  - §7:
    - E-a → Task 3 (day 31);
    - E-c, E-g → Task 3;
    - E-d → the unique index, Task 2;
    - E-e → Task 4 Undo;
    - E-f → Task 4;
    - E-i is Phase 3;
    - E-j holds by construction (card never in the pool), pinned in Task 3;
    - E-k is unchanged from Phase 1.
  - §6 (the notification) and the "Remind you?" ask are Phase 3.
- **Types:**
  - `Occurrence` (existing) and `BillSkip` (Task 2) are used throughout.
  - `BillAmountEntered` (Task 4) is inside `BillAmountOutcome` (Task 6) and is consumed by Home (Task 7).
  - `ruleAmountQuestion` gains a mode parameter in Task 5, and every caller is updated there.
- **Proportion:** the plan pins names, numbers and tests. Bodies are left to the implementer, except the E-f `nextDue` rule, which the tests alone don't fully determine.
