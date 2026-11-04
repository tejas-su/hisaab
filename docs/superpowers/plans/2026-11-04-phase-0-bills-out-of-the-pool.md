# Phase 0: Bills come out of the pool, not today. Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A bill posted (or later entered) on its own day is taken out of the cycle's pool, never out of today's share, so the hero no longer reads *Over today* on rent day.

**Architecture:** Add one input, `R_t` (`billsPostedToday`), to `CycleInputs`. Define `S_today` as today's *Spent* entries with no `recurring_id`, and add `− R_t` to the pool in `SafeToSpend._pool`. Everything that reads `spentToday` (hero, today's bar, week bars, *This week*, BR-8 note) then follows automatically. Home's bites and the Today-list total use the same split, and bill rows get a "Fixed bill" tag so the list still adds up visibly.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_bloc, fpdart, flutter_test, hand-written fakes.

**Spec:** [docs/superpowers/specs/2026-11-04-savings-and-changing-bills-design.md](../specs/2026-11-04-savings-and-changing-bills-design.md) §3 (formulas, worked examples 1 and 2), §9 phase 0. Research: [case study 18](../../design-research/case-studies/18-variable-bills-and-quick-entry.md), "What's wrong today" and "Formula impact".

## Global Constraints
- Money is `int` paise in `Money`; shares are floored to whole rupees (`SafeToSpend._floorShare`); never `double` for an amount.
- "Today" comes from the injected `Clock`; tests pin it with `FakeClock`.
- User-facing text only via `lib/l10n/app_en.arb` + `flutter gen-l10n`; banned words: "transaction", "debit/credit", "budget period", "Oops".
- Existing tests are the contract. Where this plan **changes** a documented rule (BR-3, BR-4, BR-6a, FR-HO-2), it says which test changes and why, citing D119. Any other test going red means stop and ask.
- **Commits:** CLAUDE.md says commit only when the owner asks. The checkpoint steps below stage nothing and commit nothing unless the owner has said to.
- **Done** means: `flutter analyze` is clean, `flutter test` is green, `scripts/changed_lines_coverage.sh` is ≥ 90% (any uncovered lines listed with a reason), and SPEC, DECISIONS and UI_DESIGN are updated in this change.

## Review Focus
1. **The Every-entry and Spends totals must not change.** `S_prev` still includes past bills, and *Where it went* reads entries directly. Only *today's* split changes. → Task 2, test "a bill posted on a past day still counts in spent before".
2. **A bill posted today when the pool is already short** (a bill bigger than everything left, E5) must still read *Over for the cycle*, not *On track*. → Task 1, test "a bill posted today that overdraws the pool is Over for the cycle".
3. **The Add keypad preview** (`previewSpend`) on rent day must preview against the new `A`, not say "over today" for the first ₹10. → Task 1, test "previewSpend on rent day fits within the new share".
4. **A *Got* entry with a `recurring_id`** (salary posted today) must stay in `I`, not leak into `R_t`. → Task 2, test "salary posted today is income, not a bill".
5. **A user who edits a posted bill's amount today** (the Add tray edit, FR-AD-8) recomputes `A` today. That's intended (BR-4 amendment) and must not crash or show a negative share. → Task 1, test "a bill today larger than the pool floors the share at ₹0".

---

### Task 1: `R_t` in the formula (`CycleInputs`, `SafeToSpend`) and its docs

**Files:**
- Modify: `lib/ledger/domain/entities/cycle_inputs.dart` (add a field)
- Modify: `lib/ledger/domain/safe_to_spend.dart:69` (`_pool`)
- Modify: `docs/SPEC.md` BR-3 (symbol table and the "Bills due today…" sentence), BR-4 (the "`A` does not change" bullet), §5 (edge case row)
- Modify: `docs/DECISIONS.md` (append D119)
- Test: `test/ledger/domain/safe_to_spend_test.dart`

**Interfaces:**
- Produces: `CycleInputs.billsPostedToday` (`Money`, required named constructor parameter, in `props`), documented as "`R_t`: *Spent* entries dated today that a recurring rule posted (bills). They come out of the pool, not today's share (BR-3, D119)."
- Changes the meaning of `CycleInputs.spentToday` to "`S_today`: *Spent* entries dated today that no recurring rule posted".

- [ ] **Step 1: Add `billsPostedToday` to the test helper and write the failing tests**

In `safe_to_spend_test.dart`, add `int billsPostedToday = 0` to `_inputs` and pass `billsPostedToday: _rupees(billsPostedToday)`. Add this group:

```dart
group('SafeToSpend — bills posted today come out of the pool (BR-3, D119)', () {
  test('rent day: ₹15,000 posted today, nothing spent, hero shows ₹316 and is not over', () {
    final CycleSummary s = _compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 15000));
    expect(s.pool, _rupees(2850));
    expect(s.todayShare, _rupees(316));
    expect(s.state, isNot(isA<OverToday>()));
  });

  test('a changing bill entered today: ₹1,460 with ₹420 spent leaves ₹1,401', () {
    final CycleSummary s = _compute(_inputs(billsDue: 0, billsPostedToday: 1460));
    expect(s.todayShare, _rupees(1821));
    expect(s.todayShare - s.spentToday, _rupees(1401));
  });

  test('the share is the same whether the bill is still due or posted today', () {
    expect(
      _compute(_inputs(billsDue: 1200, billsPostedToday: 0)).todayShare,
      _compute(_inputs(billsDue: 0, billsPostedToday: 1200)).todayShare,
    );
  });

  test('a bill posted today that overdraws the pool is Over for the cycle', () {
    final CycleSummary s = _compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 20000));
    expect(s.state, OverCycle(_rupees(2150)));
  });

  test('a bill today larger than the pool floors the share at ₹0', () {
    expect(_compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 20000)).todayShare, _rupees(0));
  });

  test('previewSpend on rent day fits within the new share', () {
    final CycleSummary s = _compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 15000));
    expect(SafeToSpend.previewSpend(s, _rupees(10)), FitsToday(_rupees(306)));
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/ledger/domain/safe_to_spend_test.dart`
Expected: compile error, "No named parameter with the name 'billsPostedToday'".

- [ ] **Step 3: Add the field and change `_pool`**

Add `required this.billsPostedToday` to `CycleInputs` (after `billsDue`), with the dartdoc from Interfaces, and include it in `props`. Update the `spentToday` dartdoc. In `SafeToSpend`, change `_pool` to `income − keepAside − billsDue − spentBefore − billsPostedToday`. Add `billsPostedToday: Money.zero` to every other `CycleInputs(...)` call site that `flutter analyze` reports (currently only `get_cycle_summary.dart`, which Task 2 rewires properly).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/ledger/domain/safe_to_spend_test.dart`
Expected: all pass, the existing worked-example tests included (they default `billsPostedToday` to 0).

- [ ] **Step 5: Update the docs**

- **SPEC BR-3:**
  - The formula becomes `P = I − K − B − S_prev − R_t`.
  - Add the row `R_t` = "*Spent* entries dated `t` that a recurring rule posted".
  - Change the `S_today` meaning in BR-4 to "*Spent* entries dated `t` with no recurring rule".
  - Replace "Bills due **today** are posted by the recurring engine (BR-9), so they count as spent today, not in `B`." with "A bill posted on its own day comes out of the pool (`R_t`), not today's share: yesterday it sat in `B`, so today's share was already sized for it (D119)."
  - Add the rent-day worked example from the spec, §3 example 1.
- **SPEC BR-4:** change the "`A` does not change" bullet to add "…or when a bill amount dated today is entered or changed".
- **DECISIONS:** append D119, dated 2026-11-04. **Decision:** "a bill posted or entered on its own day comes out of the pool (`R_t`), not today's share". **Why:** "Rent day read *Over today* with nothing spent; case study 18; the same rule will reserve savings (spec §3)". **Rejected:** "Keeping bills in `S_today`; excluding them from the day entirely".

- [ ] **Step 6: Checkpoint**

Run: `flutter analyze`
Expected: "No issues found!" Commit only if the owner asked.

---

### Task 2: `GetCycleSummary` splits today's spending (hero, week bars, *This week*, BR-8)

**Files:**
- Modify: `lib/ledger/domain/usecase/get_cycle_summary.dart` (`_DayTotals.inputs`, `_spentThisWeek`)
- Modify: `docs/SPEC.md` BR-6a and FR-HO-2 (the week counts typed spending; bills sit in the pool)
- Test: `test/ledger/domain/usecase/get_cycle_summary_test.dart`

**Interfaces:**
- Consumes: `CycleInputs.billsPostedToday` (Task 1).
- Produces: `CycleSummary.spentToday` now excludes rule-posted entries. `CycleSummary.spentThisWeek` also excludes rule-posted entries. `WeekDay.spent` follows `spentToday`.

- [ ] **Step 1: Write the failing tests**

Use the file's `addEntry`/`setToday` helpers and `WorkedExample.electricity` (due on the 29th). Add a group `'GetCycleSummary — bills on their day (D119)'`:

```dart
// Thu 29 Oct, electricity ₹1,200 posted today. S_prev = ₹27,570 (the BR-8 test above derives it:
// A_28 = floor((45,000 − 1,200 − 27,570) / 7) = ₹2,318 with nothing spent on the 28th).
// D119: P = 45,000 − 27,570 − 1,200 = 16,230 over 6 days → A = ₹2,705, spent today ₹0.
// Old rule: A = floor(17,430 / 6) = ₹2,905 with ₹1,200 "spent today", so the hero read ₹1,705.
test('a bill posted on its day comes out of the pool, not today (worked example, 29 Oct)', () async {
  setToday(const CalendarDate(2026, 10, 29));
  addEntry(1200, const CalendarDate(2026, 10, 29), recurringId: WorkedExample.electricity.id);
  recurring.rules = <RecurringRule>[WorkedExample.salary, WorkedExample.rent,
      WorkedExample.electricity.copyWith(nextDue: const CalendarDate(2026, 11, 29))];
  final CycleSummary s = await summary();
  expect(s.todayShare, Money.fromMajor(2705));
  expect(s.spentToday, Money.zero);
});

```

And four more, in the same group (today is the fixture's Mon 26 Oct unless set):

| Test | Arrange | Assert |
|---|---|---|
| `'salary posted today is income, not a bill'` | `addEntry(5000, today, kind: EntryKind.got, recurringId: WorkedExample.salary.id)` | `spentToday == ₹420` and `pool` is ₹5,000 higher than without the entry |
| `'a bill posted on a past day still counts in spent before'` | `addEntry(1200, 20 Oct, recurringId: WorkedExample.electricity.id)` vs the same with `recurringId: null` | both runs give the same `pool` and `todayShare` |
| `'this week leaves out bills posted this week'` | `addEntry(1200, 26 Oct, recurringId: WorkedExample.electricity.id)` | `spentThisWeek == ₹420` |
| `'a past week day with a bill posted on it shows only typed spending'` | `setToday(28 Oct)`; `addEntry(1200, 27 Oct, recurringId: …electricity.id)` | `week[1].spent` is the typed spending on 27 Oct only (₹0 in the fixture) |

If the fixture's entries differ from the derivation in the first test's comment, recompute ₹2,705 by hand from `worked_example.dart` and use that value. Note the derivation in the test comment.

**Leave the existing BR-8 test** "a bill posted today was still due yesterday" **unchanged**. D119 changes today's pool, not yesterday's, so its `YesterdaySaving(₹2,318, ₹386)` must still hold. If it fails, stop and ask.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/ledger/domain/usecase/get_cycle_summary_test.dart`
Expected: "a bill posted on its day comes out of the pool…" fails, with `todayShare` ₹2,905 ≠ ₹2,705. The week tests fail too.

- [ ] **Step 3: Split today's spending in `_DayTotals.inputs` and `_spentThisWeek`**

In `_DayTotals.inputs`:
- `spentToday` sums *Spent* entries dated `today` with `recurringId == null`.
- `billsPostedToday` sums *Spent* entries dated `today` with `recurringId != null`.
- `spentBefore` and `paceSpentBefore` are unchanged.

In `_spentThisWeek`, add `e.recurringId == null`. Add a `// why:` comment: "bills sit in the pool on their day (D119), so the week counts only typed spending, as each day's `S_today` does".

`_asItStood` needs no change. For a past day `d`, its bills dated `d` become that day's `R_t`, and bills after `d` are still added to `B`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/ledger`
Expected: all pass. If an existing *This week* or week-day test changes value, it is one whose fixture posts a bill inside the week. Check that its new value matches D119 by hand, update it, and record the test name in the checkpoint note. Any other failure: stop and ask.

- [ ] **Step 5: Update SPEC BR-6a and FR-HO-2**

The week's spent figure and each day's bar count typed spending only. Bills posted that day are in the day's pool (D119).

- [ ] **Step 6: Checkpoint**

Run: `flutter analyze && flutter test test/ledger`
Expected: clean and green.

---

### Task 3: Home shows bills without biting today's bar

**Files:**
- Modify: `lib/home/presentation/bloc/home_bloc.dart:101` (`todaySpends`)
- Modify: `lib/ledger/presentation/widgets/entry_row.dart` (bill tag)
- Modify: `lib/l10n/app_en.arb` (+ `flutter gen-l10n`)
- Modify: `docs/UI_DESIGN.md` (Today list row: the bill tag), SPEC FR-HO-4 (one sentence)
- Test: `test/home/presentation/bloc/home_bloc_test.dart`, `test/ledger/presentation/widgets/entry_row_test.dart` (create if absent, mirroring `lib/`)

**Interfaces:**
- Consumes: `CycleSummary.spentToday` without bills (Task 2).
- Produces: `HomeReady.todaySpends` = today's *Spent* entries with `recurringId == null`, oldest first. New ARB key `entryFixedBill`: `"Fixed bill"`.

- [ ] **Step 1: Write the failing tests**

- **`home_bloc_test.dart`**, test `'todaySpends leaves out a bill posted today (D119)'`:
  - Arrange: the ledger fake has a ₹420 typed spend and a ₹1,200 entry with `recurringId` set, both dated today.
  - Assert: `todaySpends` has exactly the ₹420 entry, and `todayEntries` still has both.
- **`entry_row_test.dart`:**
  - `'a rule-posted Spent entry with no note shows "Fixed bill"'`: `find.text('Fixed bill')` finds one widget.
  - `'a typed entry shows no bill tag'`: finds nothing.
  - `'a rule-posted entry with a note shows the note, not the tag'`.
  - Pump with `pumpApp` from `test/helpers/pump_app.dart`.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/home/presentation/bloc/home_bloc_test.dart test/ledger/presentation/widgets/entry_row_test.dart`
Expected: the bloc test finds 2 spends, and "Fixed bill" isn't found.

- [ ] **Step 3: Implement**

- `home_bloc.dart:101`: add `&& e.recurringId == null` to the `todaySpends` filter.
- ARB: add `"entryFixedBill": "Fixed bill"` with `@entryFixedBill` description "Second line of a list row for a bill the app posted on its day; shown when the row has no note". Run `flutter gen-l10n`.
- `EntryRow`: where the note line renders (`entry_row.dart:100`), show `note ?? (entry.recurringId != null && entry.kind == EntryKind.spent ? strings.entryFixedBill : null)` in the same style.
- The Today list header total (`today_list.dart`, `spentToday`) needs no code change: it already reads `summary.spentToday`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/home test/ledger`
Expected: green.

- [ ] **Step 5: Update the docs and check widget sizes**

- UI_DESIGN, Today list row: "a bill the app posted shows *Fixed bill* as its second line when it has no note; the list's total counts typed spending only (D119)".
- SPEC FR-HO-4: the same sentence.

Run: `flutter test test/home/presentation/pages/home_page_test.dart`. It already pumps at the `TestWindows` sizes. Expected: green.

- [ ] **Step 6: Final verification (phase done)**

Run: `flutter analyze && flutter test && scripts/changed_lines_coverage.sh`
Expected:
- "No issues found!"
- all tests pass
- coverage ≥ 90% of changed lines (list any uncovered line with a reason)

Then install on the device (`live-app-inspection` skill). Set the clock-independent check: add a fixed bill due today in Settings, open Home, and confirm the hero isn't ₹0/*Over today*, the bar has no bill bite, and the Today row reads "Fixed bill". Commit only if the owner asked.
