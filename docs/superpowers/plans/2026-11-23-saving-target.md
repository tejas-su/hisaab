# Saving Target Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A saving can have an optional *Saving up to* target. Its Savings row shows progress in words with a "done by" month. The saving **stops putting in when the target is reached**, Home says "reached" once, the saving sheet offers *I bought it* / *Keep saving*, and the Ask AI export carries the target.

**Architecture:** Three nullable columns on `recurring` (migration 007) carried by `RecurringRule`. The estimate (`SavingTarget.progress`) and the stop-at-target rule (inside `PostDueRecurring`) are pure domain logic. The sheet reuses `BillSheetBloc` and `PinnedBillQuestion`. The Home line reuses `HomeLinesBloc`, `MissedLogProbe` and the due-soon row's shape.

**Tech Stack:** Flutter 3.47, Dart ^3.13, flutter_bloc + bloc_concurrency, fpdart, sqflite (sqflite_common_ffi in tests), gen-l10n.

**Spec:** [2026-11-22-saving-target-design.md](../specs/2026-11-22-saving-target-design.md), including sections 14 (copy) and 15 (interaction; its findings F1 to F4 win over sections 4a, 9 and E147/E150). **Amended by** [2026-11-22-can-i-afford-design.md](../specs/2026-11-22-can-i-afford-design.md) section 7: **auto-stop at the target replaces D210**, plus the reached choices. Where they conflict, the can-i-afford doc wins.

## Global Constraints

- Amounts are `Money` (int paise). Display only through `MoneyFormatter` / `context.money`. Never show paise.
- "Today" comes from the injected `Clock`. Tests pin it with `FakeClock`.
- Every user-facing string goes in `lib/l10n/app_en.arb`, using the keys and text in the saving-target spec §14.2, then `flutter gen-l10n`. No banned words. "Saved" is never used for money held.
- No new colour or token. No progress bar (owner, 2026-11-22). Marigold appears only on the question's *Save* key.
- Haptics: `tick()` on success, `reject()` on failure. Never `success()` here.
- Hand-written fakes only. Update `test/helpers/fakes/fake_recurring_repository.dart` whenever `RecurringRule` changes.
- Existing tests are the contract. The only test edits allowed are the schema-version bumps listed in Task 2.
- **Never commit unless the owner asks** (CLAUDE.md). Each task ends with a checkpoint instead: `flutter analyze` is clean and the named tests pass.
- Coverage: at least 90% of changed lines (`scripts/changed_lines_coverage.sh`). List any gaps.

## Review Focus

1. **A catch-up after weeks away crosses the target.** Only the capped last put-in posts. `next_due` still moves past today, so a later *Keep saving* never back-posts (Task 5).
2. **A *Used* entry drops set aside below the target on a stopped saving.** The next engine run resumes posting from `next_due` and does not back-post (Task 5).
3. **A target is set while already reached.** No Home line ever appears for it (F1: only `target_reached_for` is written). Task 7 tests this.
4. **A 31st-of-month saving whose estimate crosses February and a year** gives the clamped month and the year suffix (Task 4).
5. **Undo on *I bought it*** restores the saving and removes the *Used* entry, so the money is set aside again and the hero is unchanged (Task 6).

---

### Task 1: Doc sync

**Files:**
- Modify: `docs/SPEC.md`, `docs/UI_DESIGN.md`, `docs/DECISIONS.md`, `docs/PLAN.md`, `docs/superpowers/specs/2026-11-22-saving-target-design.md` (status line only)

- [ ] **Step 1: Pick ids.** Run `grep -n "^| D2" docs/DECISIONS.md | tail -3` and `grep -n "^### BR-2" docs/SPEC.md`, and use the next free D, BR and E numbers. The specs' "D208 to D212 / BR-23 / E129+" are stale.
- [ ] **Step 2: Write the SPEC text.** Use saving-target §9 with F1 to F4 applied. Replace D210's "never stops" with: "A saving with a target posts nothing once set aside reaches it. The put-in that would pass the target posts only the gap, `next_due` keeps moving, and a later *Used* below the target resumes posting from `next_due` with no back-posting." Add FR-SE-1 ACs for the reached choices (*I bought it* = *Used* for the whole set-aside amount, then delete with a 4 s Undo that restores both; *Keep saving* = clear the target; closing = leave it). Add FR-HO-3 with the reached line, BR-9, BR-15, BR-16 (schema 7) and the glossary entry.
- [ ] **Step 3: Write the DECISIONS rows.** Saving-target §10's rows, renumbered. D210 becomes the auto-stop row, citing the owner (2026-11-22) and "supersedes the never-stops proposal".
- [ ] **Step 4: Update UI_DESIGN and PLAN.** UI_DESIGN: the sheet row, question, *Clear*, list-line forms, reached choices, the Home slot order and the copy (§14.8). PLAN: the data model's three columns and schema v7. Mark the spec's status line "in SPEC".
- [ ] **Step 5: Checkpoint.** Run `grep -n "D210\|BR-23" docs/SPEC.md docs/DECISIONS.md`. Every reference must resolve to a real row.

### Task 2: Migration 007

**Files:**
- Create: `lib/core/db/migrations/migration_007_saving_target.dart`
- Modify: `lib/core/db/migrations/migrations.dart`, `lib/core/db/db_schema.dart` (`RecurringColumns`)
- Modify (version bumps only, 6 → 7): `test/core/db/migration_006_test.dart:19-20,69`, `test/core/db/app_database_test.dart:65,216,388`, `test/core/db/migration_005_test.dart:129,187`, `test/backup/data/nudge_state_backup_test.dart:66`
- Test: `test/core/db/migration_007_test.dart`, `test/backup/data/saving_target_backup_test.dart`

**Interfaces:**
- Produces: `RecurringColumns.targetMinor = 'target_minor'`, `.targetReachedFor = 'target_reached_for'`, `.targetReachedOn = 'target_reached_on'`. `AppDatabase.schemaVersion == 7`.

- [ ] **Step 1: Write the failing tests.** Model them on `migration_006_test.dart`:
  - `expect(migrations, hasLength(7)); expect(AppDatabase.schemaVersion, 7);`
  - `PRAGMA table_info(recurring)` lists all three columns.
  - A v6 database with a saving row upgrades with the row kept and all three columns null.
  - Inserting `target_minor = 0` throws (the CHECK constraint).
  - The backup test, modelled on `nudge_state_backup_test.dart`, restores a schema-6 file with all three columns null.
- [ ] **Step 2: Run them and see them fail.** `flutter test test/core/db/migration_007_test.dart test/backup/data/saving_target_backup_test.dart`
- [ ] **Step 3: Implement `Future<void> migration007SavingTarget(DatabaseExecutor db)`.** Three `ALTER TABLE ${Tables.recurring} ADD COLUMN …` statements: `target_minor INTEGER CHECK (target_minor IS NULL OR target_minor > 0)`, `target_reached_for INTEGER`, `target_reached_on TEXT`. Append it to `migrations`. Dartdoc cites the BR id from Task 1.
- [ ] **Step 4: Bump the version-6 asserts** in the files listed above. Nothing else in them changes.
- [ ] **Step 5: Checkpoint.** `flutter test test/core/db test/backup` passes.

### Task 3: Target fields on `RecurringRule`

**Files:**
- Modify: `lib/ledger/domain/entities/recurring_rule.dart`, `recurring_draft.dart`, `lib/ledger/data/model/recurring_model.dart`, `lib/ledger/data/mapper/recurring_mapper.dart`, `lib/ledger/data/repository/recurring_repository_impl.dart` (`_ruleFrom`), `test/helpers/fakes/fake_recurring_repository.dart` (`_ruleFrom`)
- Test: `test/ledger/data/mapper/recurring_mapper_test.dart`, `test/ledger/data/repository/recurring_repository_impl_test.dart`

**Interfaces:**
- Produces on `RecurringRule` and `RecurringDraft`:
  - `Option<Money> target` (default none)
  - `Option<Money> targetReachedFor` (default none)
  - `Option<CalendarDate> targetReachedOn` (default none)
  - All three are in `props`.
  - `copyWith` gains `Option<Money>? target, Option<Money>? targetReachedFor, Option<CalendarDate>? targetReachedOn`.
  - `draft` carries all three.
  - Writes go through the existing `RecurringRepository.update(rule)`. No new repository method.

- [ ] **Step 1: Write the failing tests.**
  - `toModel` then `toEntity` round-trips `target: some(Money.fromMajor(50000))`, `targetReachedFor: some(...)` and `targetReachedOn: some(CalendarDate(2026, 11, 23))`.
  - A row with nulls maps to `none()`.
  - Repository: `update(rule.copyWith(target: some(...)))` then `activeRules()` returns the target. This uses real sqflite via `openTestDatabase()`.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement.** The model fields are `int? targetMinor`, `int? targetReachedFor` and `String? targetReachedOn`, read with `intOrNullAt` / `stringOrNullAt`. A bad date string returns a `Left` from `toEntity`, as other dates do.
- [ ] **Step 4: Checkpoint.** `flutter test test/ledger` passes. `flutter analyze` is clean, which also means every `RecurringRule(`/`RecurringDraft(` call site compiles; they use the defaults.

### Task 4: `SavingTarget.progress` (pure, TDD)

**Files:**
- Create: `lib/ledger/domain/saving_target.dart`, exported from `lib/ledger/ledger.dart`
- Test: `test/ledger/domain/saving_target_test.dart`

**Interfaces:**
- Produces:
  ```dart
  sealed class TargetProgress extends Equatable {}
  final class TargetReached extends TargetProgress {}
  final class TargetEstimate extends TargetProgress { const TargetEstimate(this.doneOn); final CalendarDate doneOn; }
  final class TargetFar extends TargetProgress {}            // more than 120 put-ins
  abstract final class SavingTarget {
    static const int maxPutIns = 120;
    static TargetProgress progress({required Money target, required Money setAside, required RecurringRule saving});
  }
  ```
  `doneOn` is the n-th put-in date counted from `saving.nextDue`, where `n = ceil((target − setAside) / saving.amount)`. Step forward with `RecurringSchedule.next`, which already applies the clamp.

- [ ] **Step 1: Write the failing tests** (values from saving-target §4):
  - Worked example B, an RD of ₹5,000 on the 10th with `nextDue` 10 Nov 2026, `S` ₹18,000 and `T` ₹50,000, gives `TargetEstimate(CalendarDate(2027, 5, 10))`. At an amount of ₹4,000 it gives `2027-06-10`.
  - Worked example A: ₹1,000 a month, `nextDue` 5 Nov 2026. `S` 12,000 / `T` 12,000 is `TargetReached`. `S` 7,000 gives `2027-03-05`. `S` 0 gives `2027-10-05`.
  - `T = S + 1` (one paisa over) gives `TargetEstimate(nextDue)`.
  - A saving on the 31st with `nextDue` 31 Jan 2027, needing 2 put-ins, gives `2027-02-28`. In 2028 (a leap year) it gives `2028-02-29`.
  - A saving with `nextDue` 10 Dec 2026 needing 2 put-ins gives `2027-01-10` (year crossing).
  - An amount of ₹1 with `T` ₹50,000 gives `TargetFar()`. A gap of exactly 120 put-ins is still an estimate.
- [ ] **Step 2: Run them and see them fail.** `flutter test test/ledger/domain/saving_target_test.dart`
- [ ] **Step 3: Implement.** Use integer paise maths only.
- [ ] **Step 4: Checkpoint.** The tests pass.

### Task 5: Stop at the target in `PostDueRecurring`

**Files:**
- Modify: `lib/ledger/domain/usecase/post_due_recurring.dart`, `lib/ledger/di/ledger_module.dart` (constructor wiring)
- Test: `test/ledger/domain/usecase/post_due_recurring_test.dart`

**Interfaces:**
- Consumes: `LedgerRepository.savingTotals()` and `SetAside.of(putIn, used)`.
- Produces: the constructor becomes `const PostDueRecurring({required RecurringRepository recurring, required LedgerRepository ledger, required Clock clock})`.

- [ ] **Step 1: Write the failing tests** with `FakeRecurringRepository`, `FakeLedgerRepository` and `FakeClock`:
  - `stops_at_target`: a ₹5,000 saving with `T` 50,000 and set aside 48,000, one date due. The posting has one occurrence of **₹2,000**.
  - `catch_up_caps_then_stops`: set aside 40,000 and three dates due. The posting is ₹5,000, then ₹5,000; the third date posts nothing. `nextDueByRuleId[id]` is the date after the third.
  - `reached_posts_nothing_but_moves_next_due`: set aside 50,000 and one date due. There are no occurrences, and `nextDueByRuleId` still advances.
  - `used_below_target_resumes`: set aside 45,000 after a *Used* entry. The next due date posts ₹5,000.
  - `no_target_unchanged`: every existing test in the file still passes unchanged.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement.** Read `savingTotals()` alongside `activeRules()`. In `_postingFor`, for a `saved` rule with `target` some, walk its due dates while keeping a running set-aside. Each date posts `min(amount, gap)` while the gap is greater than 0, as an `Occurrence(rule: rule.copyWith(amount: capped), date: d)`; otherwise it posts nothing. `nextDueByRuleId` always uses `RecurringSchedule.next(schedule, dates.last)`. Add a `// why:` citing the auto-stop decision and D33.
- [ ] **Step 4: Checkpoint.** `flutter test test/ledger` passes, and so does `flutter test test/app` (DI construction).

### Task 6: Saving sheet — *Saving up to* row, question, *Clear* and the reached choices

**Files:**
- Modify: `lib/settings/presentation/bloc/bill_sheet_state.dart` (`BillAnswer.target`, the `BillSheetBought` outcome), `bill_sheet_event.dart`, `bill_sheet_bloc.dart`, `lib/settings/presentation/pages/bill_sheet.dart` (`_view`, `_body`), `lib/settings/presentation/widgets/bill_sheet/bill_summary.dart` (`_rows`, set-aside line), `lib/app/routes.dart` (`openBillSheet` callers: handle `BillSheetBought` with an Undo snackbar)
- Create: `lib/settings/presentation/widgets/bill_sheet/target_question.dart`, `target_slot.dart`, `bill_reached_section.dart`
- Test: `test/settings/presentation/bloc/bill_sheet_bloc_target_test.dart`, `test/settings/presentation/widgets/bill_sheet/target_question_test.dart`, `bill_reached_section_test.dart`

**Interfaces:**
- Consumes: `SavingTarget.progress` (Task 4), `EditBill`, `UseFromSavings`, `DeleteBill`, `RestoreBill`, `LedgerRepository.delete(int id)` (for Undo).
- Produces:
  - Events: `BillSheetTargetSaved()`, `BillSheetTargetCleared()`, `BillSheetBoughtRequested()` (all `droppable()`), `BillSheetKeepSavingRequested()`.
  - Outcome: `BillSheetBought(UsedOutcome outcome)`.
  - `BillSheetBloc` also takes `UseFromSavings` and `DeleteBill`, both required for savings.

- [ ] **Step 1: Write the failing bloc tests:**
  - Opening `BillAnswer.target` prefills `rupees` from the target, or 0, with `fresh: true`. It must not use `rule.amount`.
  - Saving `T` ≤ set aside writes `targetReachedFor: some(T)` and leaves `targetReachedOn` none (F1).
  - Saving an unchanged target writes nothing.
  - `BillSheetTargetCleared` writes all three as none.
  - *Save* at 0 does nothing (F4). A failed write sets `saveFailed`.
  - `BillSheetBoughtRequested` calls `UseFromSavings(amount: setAside)`, then `DeleteBill`, and closes with `BillSheetBought`.
  - `BillSheetKeepSavingRequested` writes `target: none` and emits `justSaved`.
- [ ] **Step 2: Write the failing widget tests:**
  - The row is keyed `bill-row-target` and reads `Not set` / `₹50,000`.
  - The slot's four classes (`blank`, `reached`, `estimate`, `far`) use the §14.2 strings.
  - *Clear* appears only when a target is set.
  - `bill_reached_section` shows *I bought it* and *Keep saving* only when the target is some and set aside ≥ target.
  - The question fits at `TestWindows.smallPhone` with 1.3× and 2.0× text.
- [ ] **Step 3: Run them and see them fail.**
- [ ] **Step 4: Implement**, following saving-target §15.2:
  - Widen `_editAmount`'s guard to `amount || target`.
  - `TargetQuestion` reuses `PinnedBillQuestion` with `slot: TargetSlot(...)`, whose line 2 is `savingUsedSame`.
  - `BillReachedSection` sits where `BillUsedSection` does, above it. Its copy goes to new ARB keys: `savingBoughtIt` ("I bought it"), `savingKeepSaving` ("Keep saving") and `savingBoughtSnack` ("Used {amount} from {saving}"). Add their `@` descriptions.
  - In `routes.dart`, `BillSheetBought` shows `HisaabSnackbar` with Undo. Undo calls `RestoreBill(rule.id)` then `LedgerRepository.delete(outcome.entry.id)`.
- [ ] **Step 5: Checkpoint.** `flutter gen-l10n && flutter test test/settings` passes, and analyze is clean.

### Task 7: Savings list line and Home reached line

**Files:**
- Modify: `lib/settings/presentation/widgets/bill_row.dart` (third line and spoken label), `lib/home/presentation/bloc/home_lines_state.dart` (`Option<ReachedLine> reached`, `bool reachedMarked`), `home_lines_event.dart` (`HomeLinesFacts.reached`, `HomeLinesReachedShown`, `HomeLinesReachedTapped`), `home_lines_bloc.dart` (`_onEvaluated`, `_installFits`, `_decide`, `_remove`, `_onMidnight`), `lib/home/presentation/bloc/home_bloc.dart` + `home_state.dart` (`HomeReady.reachedLine`), `lib/home/presentation/widgets/home_lines_driver.dart` (facts, focus, removal), `lib/home/presentation/pages/home_page.dart` (`_nudge`: the `reachedLineSlot` builder before `installLineSlot`), `lib/app/main_screen.dart`, `lib/app/routes.dart`
- Create: `lib/home/presentation/widgets/reached_line_slot.dart`, `reached_line_row.dart`, `lib/home/domain/entities/reached_line.dart` (`ReachedLine({required RecurringRule saving, required Money target, required bool pending})`)
- Test: `test/settings/presentation/widgets/bill_row_target_test.dart`, `test/home/presentation/bloc/home_lines_bloc_reached_test.dart`, `test/home/presentation/widgets/reached_line_slot_test.dart`

**Interfaces:**
- Consumes: `SavingTarget.progress`, `GetSetAside`, `RecurringRepository.update`, `MissedLogProbe(event:)`, `DueSoonRow`'s `onOpenBill`.

- [ ] **Step 1: Write the failing tests:**
  - `BillRow` uses each §4 table form (`savingTargetEstimate`, `…None`, `…Reached`, `…Far`, `…FarNone`) and the spoken twins. A saving with no target is unchanged.
  - Bloc (§15.3): reached outranks install and missed-log; it waits behind waiting/due-soon, over and *No income*; it is written only on `HomeLinesReachedShown`; *Shown today* beats a second *Pending* (F2); it leaves at `HomeLinesMidnight`.
  - Driver: the line leaves on the next Home reload when set aside drops below `T` (F3).
  - Slot: tapping calls `onOpenBill(saving)`. It shows once in two panes (`TestWindows.book`). A line drawn under a covering tray is not written.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement**, following §15.3. The candidate comes from `HomeBloc` via `GetSetAside`. Marking writes `targetReachedFor: some(T)` and `targetReachedOn: some(today)` through `RecurringRepository.update`. The row reuses the due-soon row's shape with `AppIcons.saving`. The copy is `savingReachedLine` and `savingReachedLineSpoken`, with the hint `dueSoonOpensSaving`.
- [ ] **Step 4: Checkpoint.** `flutter test test/home test/settings test/app` passes.

### Task 8: Ask AI export

**Files:**
- Modify: `lib/ask_ai/domain/prompt_builder.dart`, `lib/ask_ai/domain/entities/prompt_input.dart` (`Map<int, Money> setAsideBySaving`), `lib/ask_ai/domain/usecase/get_prompt_input.dart`
- Test: `test/ask_ai/domain/prompt_builder_target_test.dart`, `test/ask_ai/domain/usecase/get_prompt_input_test.dart`

- [ ] **Step 1: Write the failing tests.**
  - One new inline golden holds an estimate sentence, a reached sentence and the explaining line, with the exact texts from §14.5. Dates are ISO.
  - Every existing golden in `prompt_builder_test.dart`, `prompt_builder_not_logged_test.dart`, `prompt_builder_size_test.dart` and `ask_ai_bloc_test.dart` passes **unchanged**.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement.** Add `_targetSentences` right after `_savings`, and `_targetClause` (a const) after `_usedClause`, only when a saving has a target. Add a `// why:` citing BR-15 and the export decision. The numbers come from `SavingTarget.progress`, never recomputed.
- [ ] **Step 4: Final checkpoint.** `flutter analyze`, `flutter test` and `scripts/changed_lines_coverage.sh main` all pass. Report any uncovered lines with a reason.
