# Can I Afford It? Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Prerequisite:** [2026-11-23-saving-target.md](2026-11-23-saving-target.md) is fully built. This plan uses `RecurringRule.target`, `SavingTarget.progress` and the auto-stop engine.

**Goal:** A *Can I afford it?* card on Spends, plus an app-icon shortcut, opens a sheet that takes an item, its price and what's already saved. It answers in one sentence (*Yes, you can* / *Yes, without a loan* / *Not yet*), with *Other ways* underneath, and can start a saving with a target in one tap.

**Architecture:** `Affordability.answer` is a pure function in `lib/spends/domain/`. `GetAffordInputs` gathers its inputs from existing repositories and helpers. `StartSavingFor` creates or changes the saving. `AffordBloc` drives a `BillSheet.route` sheet launched from Spends. The shortcut adds `LaunchAction.afford`.

**Tech Stack:** Flutter 3.47, Dart ^3.13, flutter_bloc + bloc_concurrency, fpdart, sqflite_common_ffi in tests, gen-l10n.

**Spec:** [2026-11-22-can-i-afford-design.md](../specs/2026-11-22-can-i-afford-design.md), sections 5, 6, 10a. The mockup is [52-can-i-afford.html](../../design/mockups/52-can-i-afford.html). The progress bar shown in mockup frame 4 is **dropped**.

## Global Constraints

- Amounts are `Money` (int paise), shown only through `MoneyFormatter`. Never show paise. Use integer maths only.
- Today comes from `Clock`. Cycles come from `PeriodCalculator.cycleFor`. The next cycle is `cycleFor(today: current.end.addDays(1), …)`.
- Floor = `usual × 1.2` rounded **up** to ₹10. Spare = `room − floor × days`, rounded **down** to ₹500 and never negative.
- No EMI or loan, anywhere in copy or logic. Copy says "card", never "credit". Next-cycle wording is "after payday" (D117).
- All copy goes in `app_en.arb`; `design-content` may refine it. Draft copy comes from the mockup with "next month" changed to "after payday". Banned words are checked.
- Marigold only on *Next*, *See the answer* and *Start saving*. Bars are ink only. Home and the Add flow do not change.
- Never log the item name or amounts.
- Hand-written fakes only. **Never commit unless the owner asks.** Each task ends with a checkpoint: analyze is clean and the named tests pass.
- New screens are tested at the `TestWindows` sizes, including `smallPhone` at 1.5× text, `tabletop` and `book`.

## Review Focus

1. **A weekly or *It changes* cycle.** `room` counts the occurrences inside the next cycle's dates. Monthly bills are never scaled (Task 3).
2. **No finished, tracked cycle, or a finished cycle with ₹0 typed spend.** The answer is "Ask again after payday", except that `need = 0` still gives *Yes, you can* (Tasks 2 and 3).
3. **Re-checking an item that already has a saving with the same name** (any case). `H` is prefilled with its set-aside amount, that saving is left out of `room`, and *Start saving* changes it instead of adding a second one (Tasks 3 and 4).
4. **Price ≤ `H`, `need == spare`, and `need == spare + 1` paisa** land on the right side of each boundary (Task 2).
5. **The shortcut fires with no income set up, or during onboarding.** Spends opens without the sheet, and onboarding ignores it (Task 7).

---

### Task 1: Doc sync

**Files:** `docs/SPEC.md`, `docs/UI_DESIGN.md`, `docs/DECISIONS.md`, `docs/design/README.md` (52's row: note the bar is dropped)

- [ ] **Step 1: Pick the next free BR, FR, E and D ids** (`grep` as in Plan 1, Task 1).
- [ ] **Step 2: SPEC.**
  - A new BR covering the spec §5 inputs, rule, worked example, card timing, history gate and §10a.
  - FR-SP: the card and the sheet, with ACs for each step, the answers, *Other ways*, *Start saving* with Undo, and Back behaviour.
  - FR-WG: the *Can I afford it?* shortcut.
  - Edge cases from Review Focus.
- [ ] **Step 3: DECISIONS rows:**
  - The check itself.
  - D208 narrowed (one purchase, not a simulator).
  - The card-timing exception to D123 (the card part is logged on bill day).
  - *Start saving* uses `target = need`, and the put-in day is the day after payday.
  - Re-checking by name.
- [ ] **Step 4: UI_DESIGN.** The Spends card, the sheet's steps and answer, and the copy table.
- [ ] **Step 5: Checkpoint.** Every new id is referenced from SPEC and resolves.

### Task 2: `Affordability.answer` (pure, TDD)

**Files:**
- Create: `lib/spends/domain/affordability.dart`, `lib/spends/domain/entities/afford_answer.dart`
- Test: `test/spends/domain/affordability_test.dart`

**Interfaces:**
- Produces:
  ```dart
  final class AffordInputs extends Equatable {
    const AffordInputs({required this.price, required this.have, required this.room, required this.days, required this.usual});
    final Money price, have, room;   // room: next cycle, see Task 3
    final int days;                  // next cycle length
    final Option<Money> usual;       // none = not enough history
  }
  enum AffordVerdict { fromSavings, withCard, saveUp, daysFull, tooEarly }
  final class AffordAnswer extends Equatable {
    final AffordVerdict verdict;
    final Money need, floor, spare;          // floor and spare are Money.zero when tooEarly
    final Money normalPerDay;                // floor((room) / days)
    final Option<Money> cardPerDay;          // floor((room − need) / days); some for every verdict when usual is some and need > 0
    final Option<Money> savingPerDay;        // floor((room − spare) / days) when spare > 0
    final Option<int> putIns;                // ceil(need / spare) for saveUp
  }
  abstract final class Affordability { static AffordAnswer answer(AffordInputs inputs); }
  ```
  `cardPerDay` is filled even when the card path is not suggested, so *Other ways* can show "would leave about ₹X a day".

- [ ] **Step 1: Write the failing tests.** Values come from the spec and the mockup. Use `days` 30 unless a test says otherwise.
  - `owner_example`: room 32,000, usual 750, price 1,27,000, have 60,000 → `saveUp`, floor 900, spare 5,000, need 67,000, putIns 14, savingPerDay 900, normalPerDay 1,066.
  - `with_card`: room 95,000, usual 2,000, price 1,27,000, have 1,10,000 → `withCard`, floor 2,400, spare 23,000, cardPerDay 2,600.
  - `from_savings`: have 1,30,000 → `fromSavings`, need 0.
  - `days_full`: room 32,000, usual 1,000 (floor 1,200) → `daysFull`, spare 0.
  - `need_equals_spare` → `withCard`. `need_one_paisa_over_spare` → `saveUp`.
  - `too_early`: usual none, need > 0 → `tooEarly`. `too_early_but_covered`: usual none, need 0 → `fromSavings`.
  - `floor_rounds_up_to_10`: usual 751 → floor 910. `spare_rounds_down_to_500`: room − floor×days = 5,499 → spare 5,000.
  - `weekly_days`: days 7, room 10,000, usual 1,000 → spare 1,500 (10,000 − 8,400 = 1,600 → 1,500).
  - `nine_digit_cap`: price 99,99,99,999 does not overflow.
- [ ] **Step 2: Run them and see them fail.** `flutter test test/spends/domain/affordability_test.dart`
- [ ] **Step 3: Implement.** Paise arithmetic only. Rounding helpers are private in the same file.
- [ ] **Step 4: Checkpoint.** The tests pass.

### Task 3: `GetAffordInputs`

**Files:**
- Create: `lib/spends/domain/usecase/get_afford_inputs.dart`, `lib/spends/domain/entities/afford_context.dart`
- Modify: `lib/spends/di/spends_module.dart`
- Test: `test/spends/domain/usecase/get_afford_inputs_test.dart`

**Interfaces:**
- Consumes:
  - `RecurringRepository.activeRules()`, `BudgetSettingsRepository` (monthStart, paySwitches), `LedgerRepository.entriesBetween`, `firstLoggedOn()`, `GetSetAside`
  - `PayRuleSchedule.payRuleOf`, `PeriodCalculator.cycleFor`, `RecurringSchedule.firstOnOrAfter` / `datesFrom`, `Clock`
- Produces:
  ```dart
  final class AffordContext extends Equatable {
    final Money room; final int days; final Option<Money> usual;
    final PayCycle nextCycle;
    final Option<RecurringRule> existingSaving;   // same label, case-insensitive, kind saved
    final Money existingSetAside;                 // Money.zero when none
  }
  final class GetAffordInputs implements UseCase<AffordContext, String> // params: the item's name (may be '')
  ```

- [ ] **Step 1: Write the failing tests** with fakes and `FakeClock` at 26 Oct 2026, a pay rule on the 4th and a next cycle of 4 Nov to 3 Dec (30 days):
  - `room_counts_occurrences_in_next_cycle`: income 45,000; rent 11,800 on the 5th; electricity `varies` with an estimate of 1,200 on the 20th; a card bill of 8,000, which must be **excluded**; a saving of 1,000 on the 5th → room 31,000. Days is 30.
  - `reached_saving_adds_nothing`: a saving with target ≤ set aside is not subtracted.
  - `weekly_cycle`: a `WeeklyOn` income of 10,000 and a monthly bill not due within the next 7 days → room 10,000, days 7.
  - `irregular_income_uses_last_got`: there is no income rule, so room uses the last finished cycle's *Got* total. No finished cycle → usual none.
  - `usual_from_last_finished_tracked_cycle`: typed *Spent* of 22,500 over a 30-day cycle (rule-posted and *Not logged* entries excluded) → usual 750. A cycle not tracked from its start (`firstLoggedOn` after its start) → none. A typed total of 0 → none.
  - `existing_saving_by_name`: "mac" matches the saving "Mac". It is returned with its set-aside amount and is **not** subtracted from room.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement.** Keep functions to about 20 lines. Each occurrence in `[next.start, next.end]` comes from `RecurringSchedule.firstOnOrAfter(schedule, next.start)` then `datesFrom(..., through: next.end)`. "Typed spend" matches `GetCycleSummary._isTyped`: kind spent, `recurringId == null`, `!isNotLogged`. Register it in `registerSpendsServices`.
- [ ] **Step 4: Checkpoint.** `flutter test test/spends` passes.

### Task 4: `StartSavingFor`

**Files:**
- Create: `lib/spends/domain/usecase/start_saving_for.dart`
- Modify: `lib/spends/di/spends_module.dart`
- Test: `test/spends/domain/usecase/start_saving_for_test.dart`

**Interfaces:**
- Consumes: `AddBill` (`AddBillParams(input: BillInput(...), entryKind: EntryKind.saved)`), `EditBill`, `RecurringRepository.update`, `DeleteBill`.
- Produces:
  ```dart
  final class StartSavingParams extends Equatable { final String name; final Money monthly; final Money target; final PayCycle nextCycle; final Option<RecurringRule> existing; }
  final class StartSavingFor implements UseCase<RecurringRule, StartSavingParams>
  ```

- [ ] **Step 1: Write the failing tests:**
  - A new saving gets the label "Mac", an amount of 5,000, `dueDay = nextCycle.start.addDays(1).day` (5 for a 4 Nov start) and `target: some(67,000)`.
  - An existing saving keeps its id and day, and its amount and target are updated.
  - A next cycle starting on the 31st gives due day 1.
  - A failure from `AddBill` returns `Left`.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement.** For a new saving: `AddBill`, then `update(rule.copyWith(target: some(target)))`. For an existing one: `EditBill` for the amount, then `update` for the target.
- [ ] **Step 4: Checkpoint.** The tests pass.

### Task 5: `AffordBloc` and the sheet

**Files:**
- Create:
  - `lib/spends/presentation/bloc/afford_bloc.dart`, `afford_event.dart`, `afford_state.dart`
  - `lib/spends/presentation/pages/afford_sheet.dart` (`static Future<void> show(BuildContext, AffordBloc)`, using `BillSheet.route` exactly as `PutInSheet.show` does)
  - `lib/spends/presentation/widgets/afford/afford_item_step.dart`, `afford_have_step.dart`, `afford_answer_view.dart`, `afford_other_ways.dart`, `afford_day_bar.dart`
  - `lib/spends/presentation/afford_copy.dart` (verdict and sentence strings from `AffordAnswer`, like `insight_copy.dart`)
- Test: `test/spends/presentation/bloc/afford_bloc_test.dart`, `test/spends/presentation/pages/afford_sheet_test.dart`

**Interfaces:**
- Consumes: Tasks 2, 3 and 4; `SavingTarget.progress` (for the "done by" month, using the predicted first `next_due` = `RecurringSchedule.firstOnOrAfter` of the new schedule from today); `Haptics`; `Keypad`, `AmountDisplay`, `AmountInput`, `PinnedKeypadBody`, `SignalKey`, `HisaabChip`, `HisaabSnackbarHost`.
- Produces:
  - Events (sealed): `AffordNameChanged(String)`, `AffordKeyPressed(String)`, `AffordBackspacePressed()`, `AffordNextPressed()`, `AffordHaveChosen(bool)`, `AffordAnswerRequested()` (restartable), `AffordWaysToggled()`, `AffordStartSavingPressed()` (droppable), `AffordBackPressed()`.
  - States: `AffordItemStep`, `AffordHaveStep`, `AffordLoading`, `AffordAnswered(AffordAnswer answer, Option<CalendarDate> doneBy, bool waysOpen)`, `AffordFailed`, `AffordSavingStarted(RecurringRule rule)`.

- [ ] **Step 1: Write the failing bloc tests:**
  - Digits respect the 9-digit cap (`AmountInput.append`); a refused digit calls `reject()`.
  - *Next* is ignored at ₹0.
  - The have-step is prefilled from `existingSetAside` when the name matches.
  - `AffordAnswerRequested` emits `AffordAnswered` with the owner's example and `doneBy` 2027-12-05.
  - `AffordStartSavingPressed` calls `StartSavingFor` once (droppable) with monthly = spare and target = need, then emits `AffordSavingStarted`.
  - Back on the answer goes to the have-step, Back on the have-step goes to the item step, and Back on the item step closes.
- [ ] **Step 2: Write the failing widget tests:**
  - Each verdict's copy appears.
  - `withCard` includes the card-timing line "Add ₹17,000 when you pay the card bill." (spec §5).
  - *Other ways* toggles three rows and marks the suggested one.
  - Only the *Start saving* key is marigold.
  - The bars carry the floor tick and the line "usual ₹750 a day + 20%".
  - The "Ask again after payday" view appears for `tooEarly`.
  - The Undo snackbar after *Start saving* calls `DeleteBill` for a new saving. For an existing one it restores the old amount and target through `update`.
  - The layout fits at `smallPhone` 1.5×, `tabletop` and `book`.
  - TalkBack reads the verdict and sentence as one node.
- [ ] **Step 3: Run them and see them fail.**
- [ ] **Step 4: Implement.** Add the ARB keys with `@` descriptions, then run `flutter gen-l10n`. The item glyph is `AppIcons.byKey['shopping']`; no new glyph.
- [ ] **Step 5: Checkpoint.** `flutter test test/spends` passes and analyze is clean.

### Task 6: The Spends card

**Files:**
- Create: `lib/spends/presentation/widgets/afford_card.dart` (`const AffordCard({super.key, required this.onPressed})`, styled like `AskAiCard`: a `sunk` well, no signal fill, `AppIcons.info` or a question glyph)
- Modify: `lib/spends/presentation/pages/spends_page.dart` (a new `onAfford` callback; the card sits beside `AskAiCard` in a row at `context.layout` widths that fit, stacked otherwise; shown only when `overview.isCurrent && overview.split.hasIncome`, and also when `overview.isEmpty`), `lib/app/main_screen.dart`, `lib/app/routes.dart` (`onAfford` builds `AffordBloc` from `getIt` and calls `AffordSheet.show`)
- Test: `test/spends/presentation/widgets/afford_card_test.dart`, `test/spends/presentation/pages/spends_page_afford_test.dart`

- [ ] **Step 1: Write the failing tests:**
  - The card is shown on the current cycle with income, and on the empty current cycle.
  - It is hidden on a past cycle and with no income.
  - The tap calls `onAfford`.
  - Side by side at `TestWindows.phone`, stacked at `smallPhone` 1.5×. No overflow at any `TestWindows` size.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Checkpoint.** `flutter test test/spends test/app` passes.

### Task 7: App shortcut

**Files:**
- Modify: `android/app/src/main/res/xml/shortcuts.xml` (a second shortcut, `afford`, with data `hisaab://afford`), `android/app/src/main/res/values/strings.xml` (`shortcut_afford` = "Can I afford it?"), `android/app/src/main/kotlin/.../widget/LaunchIntents.kt` (`AFFORD`), `lib/shortcuts/domain/entities/launch_action.dart` (`afford`, host `'afford'`), `lib/app/routes.dart` (`followLaunch`: for `afford`, pop to the first route, switch the dock to Spends and, if income is set up, open the sheet)
- Create: `android/app/src/main/res/drawable/ic_shortcut_afford.xml` (a Hugeicons-style vector, matching `ic_shortcut_add_spend`)
- Test: `test/shortcuts/domain/entities/launch_action_test.dart`, `test/app/follow_launch_afford_test.dart`

- [ ] **Step 1: Write the failing tests:**
  - `LaunchAction.parse('hisaab://afford')` gives `some(afford)`, and `'hisaab://afford/x'` gives none.
  - `followLaunch(afford)` with income shows Spends with the sheet up.
  - With no income it shows Spends with no sheet.
  - During onboarding it is ignored.
- [ ] **Step 2: Run them and see them fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Final checkpoint.**
  - `flutter analyze`, `flutter test` and `scripts/changed_lines_coverage.sh main` pass; report any gaps.
  - `flutter build apk --debug` succeeds.
  - Use the `live-app-inspection` skill on a device: long-press the icon, run the owner's example, and check the answer reads "Not yet. Save ₹5,000 a month…".
