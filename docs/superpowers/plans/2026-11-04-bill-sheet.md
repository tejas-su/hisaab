# Bill sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change a fixed bill in one sheet that looks like a paper bill. The sheet shows the whole bill with one row per answer (amount, day, name, icon), and each row saves on its own. Home's due-soon line opens the same sheet. Each bill gets an icon picked from its name, which the user can change.

**Architecture:**
- **Domain (`lib/ledger/`):** gains `BillIcon` with `forName`, an optional `icon` on rules (migration 002), and `GetBillStatus` for the stamp.
- **Sheet:** a new `BillSheetBloc` in `lib/settings/` drives a modal sheet opened with `BillSheet.show`, like `AddEntryTray.show`. It returns a `BillSheetOutcome` to the screen that opened it, and Bills and Home each handle delete with Undo themselves.
- **Wizard:** the three-question wizard becomes add-only.

**Tech Stack:** Flutter 3.47, flutter_bloc + bloc_concurrency, fpdart, sqflite (sqflite_common_ffi in tests), hugeicons, gen-l10n.

**Spec:** the design is [case study 16](../../design-research/case-studies/16-bill-edit-flow.md) and [mockup 27](../../design/mockups/27-bill-sheet.html). Task 1 writes the binding spec: SPEC FR-SE-1, FR-HO-3 and BR-9, plus UI_DESIGN and a new DECISIONS row.

## Global Constraints

- Money is `int` paise in `Money`, displayed only through `context.money` (`en_IN`), never with paise.
- "Today" comes only from the injected `Clock`; date maths goes through `RecurringSchedule`.
- Every user-facing string goes in `lib/l10n/app_en.arb`. Run `flutter gen-l10n` after editing it. Banned words: "transaction", "debit/credit", "budget period", "Oops".
- Colours come only from `HisaabColors`, and icons only through `AppIcon`, each with a label. No `Color(0x…)`, `Colors.*` or `Icons.*`. No red, no green, no category colours. Marigold appears only on the *Save* key (the `SignalKey`).
- Bloc with sealed events only, no Cubits. Use `droppable()` for saves and `restartable()` for loads.
- Tests use hand-written fakes from `test/helpers/fakes/`, `FakeClock` with today = **Mon 26 Oct 2026**, and real SQLite via `test/helpers/test_database.dart`.
- Read `context.layout`, never raw `MediaQuery` widths. Widget tests run at every `TestWindows` size.
- Done means: `flutter test` passes, `flutter analyze` is clean, and `scripts/changed_lines_coverage.sh master` reports ≥ 90%.
- The repo is local only: commit after each task and never push.

## Review Focus

1. **Amount-only edit of a day-31 bill in a 30-day month:** `nextDue` must not move. Covered by the test in Task 3.
2. **A bill posted today, opened from Fixed bills:** the stamp says "Counted today", not "Due…". Covered by the test in Task 4.
3. **Saving while the sheet is closing (double tap on Save or a day):** exactly one `EditBill` call. Covered by the droppable test in Task 6.
4. **A rule row with an icon value from a future version (unknown string):** the bill still loads, with the icon following the name. Covered by the mapper test in Task 2.
5. **Renaming a bill whose icon was picked by hand:** the icon stays. Covered by the test in Task 6.

---

### Task 1: Spec and docs

**Files:**
- Modify: `docs/SPEC.md`: FR-SE-1, FR-HO-3, BR-9 (due-soon nudge and stamp), and the Q5 row only if it mentions editing.
- Modify: `docs/UI_DESIGN.md` around line 390 (Fixed bills) and the Home due-soon section.
- Modify: `docs/DECISIONS.md`: append D116.
- Modify: `docs/design-research/case-studies/16-bill-edit-flow.md` and `docs/design-research/README.md`: outcome "Approved (D116)".

- [ ] **Step 1: Rewrite FR-SE-1 with acceptance criteria.** Keep the three-question flow for **adding** a bill. Changing a bill becomes the bill sheet:
  - **AC-1** Tapping a bill row, or Home's due-soon row, opens the sheet over the current screen. No page is pushed.
  - **AC-2** The bill shows its name, icon, amount, "Every month on day N", a stamp, then four rows (Amount, Day of the month, Name, Icon), then "Next goes out {date}".
  - **AC-3** A row opens its one question inside the sheet: the keypad prefilled (the first key replaces the old amount), the 1–31 grid with the current day picked, the name field with no pills, or the 16-icon grid.
  - **AC-4** Amount and name save with *Save*. A day or an icon saves on tap. Each save changes only that answer, returns to the bill, flashes the row, and the footer reads "Saved." for 2.4 s.
  - **AC-5** Back from a question returns to the bill. Back, a swipe down or the scrim closes the sheet, and unsaved typing is dropped.
  - **AC-6** *Delete bill*, a full-width `sunk` key, closes the sheet and deletes the bill with Undo (D35).
  - **AC-7** A failed save keeps the question open with "Couldn't save. Try again."
- [ ] **Step 2: Add the stamp and icon rules to BR-9.**
  - Stamp: when the next occurrence is 1–5 days away, show "Due in N days" or "Due tomorrow". Otherwise, if an entry from this rule is dated on or after the occurrence one month before `next_due`, show "Counted {d MMM}", or "Counted today" for today. Otherwise show no stamp.
  - Icon: a rule's icon is the one the user picked, or else `BillIcon.forName(label)`. Picking the icon the name suggests clears the pick.
- [ ] **Step 3: FR-HO-3.** The nudge becomes a tappable 56dp `sunk` row: the bill's icon well, the existing sentence, the date under it and a chevron. It opens the bill sheet. After a change, Home reloads. A delete from Home offers Undo.
- [ ] **Step 4: UI_DESIGN.** Replace the Fixed bills editing sentence, and describe the slip:
  - `display` paper, flat, 20dp top corners.
  - A 14dp × 8dp torn edge.
  - A dashed `hairline` perforation with 16dp notches.
  - Dotted-leader rows.
  - A straight `displayInk2` stamp with a 2dp edge on the amount line, right edge on the value column. It lands with a squash 260 ms after the sheet opens, or fades in 150 ms with reduced motion.
  - The day grid's picked state (D88 pick plus an `ink` dot).
  - Bill icons in `sunk` wells.
- [ ] **Step 5: D116 row.** Columns:
  - **Decision:** change a bill in a sheet, one answer at a time; Home's due-soon line opens it; bill icons from the name; the stamp says "Counted"; no "mark as paid".
  - **Why:** case study 16, and the owner's rounds 1–3.
  - **Not chosen:** the full wizard for edits; a keypad-first tray; a "Mark as paid" action; "Count it today" (held).
- [ ] **Step 6: Commit.** `git add docs && git commit -m "docs: spec the bill sheet (FR-SE-1, FR-HO-3, BR-9, D116)"`

### Task 2: `BillIcon` and the stored icon

**Files:**
- Create: `lib/ledger/domain/entities/bill_icon.dart`, `lib/core/db/migrations/migration_002_bill_icon.dart`
- Modify: `lib/core/db/migrations/migrations.dart`, `lib/core/db/db_schema.dart` (`RecurringColumns.icon = 'icon'`), `lib/ledger/domain/entities/recurring_rule.dart`, `recurring_draft.dart`, `bill_kind.dart`, `lib/ledger/data/model/recurring_model.dart`, `lib/ledger/data/mapper/recurring_mapper.dart`, `lib/ledger/ledger.dart` (export), `lib/core/design/app_icons.dart`
- Test: `test/ledger/domain/entities/bill_icon_test.dart`, `test/core/db/app_database_test.dart`, `test/ledger/data/mapper/recurring_mapper_test.dart`, `test/ledger/data/model/recurring_model_test.dart`

**Interfaces:**
- Produces: `enum BillIcon { bill, home, power, phone, internet, loan, card, tv, school, water, gas, insurance, help, milk, society, car }`. The order is the grid's display order. It also provides:
  - `static BillIcon forName(String name)`
  - `static Option<BillIcon> fromValue(String? value)`
  - `String get value` (the enum name)
- Produces: `BillKind.icon` (rent→home, emi→loan, phone→phone, internet→internet, schoolFees→school, subscriptions→tv).
- Produces: `RecurringRule.icon` and `RecurringDraft.icon`, both `Option<BillIcon>` with default `none`. Also `RecurringRule.shownIcon => icon.getOrElse(() => BillIcon.forName(label))`, and `copyWith(..., Option<BillIcon>? icon)`.
- Produces: `AppIcons.bill(BillIcon icon) → AppIconData`, a switch to the glyphs `Repeat, Home01, Flash, SmartPhone01, Wifi01, Bank, CreditCard, Tv01, School, Droplet, Fire, Shield01, User, MilkBottle, Building03, Car01` (stroke-rounded).

- [ ] **Step 1: Write the failing `forName` tests.**
```dart
test('picks the first matching group, top to bottom', () {
  expect(BillIcon.forName('Electricity'), BillIcon.power);
  expect(BillIcon.forName('Car EMI'), BillIcon.loan);         // loan before car
  expect(BillIcon.forName('Airtel fibre'), BillIcon.internet); // internet before phone
  expect(BillIcon.forName('light bill'), BillIcon.power);      // two-word key
  expect(BillIcon.forName('  RENT '), BillIcon.home);
  expect(BillIcon.forName('Gas cylinder'), BillIcon.gas);
  expect(BillIcon.forName('Bai'), BillIcon.help);
});
test('matches whole words only', () {
  expect(BillIcon.forName('Vitamins'), BillIcon.bill); // "vi" is a word key, not a prefix
  expect(BillIcon.forName('Actor class'), BillIcon.school);
});
test('falls back to bill', () => expect(BillIcon.forName('Gym'), BillIcon.bill));
test('fromValue reads a stored name, and none for null or unknown', () {
  expect(BillIcon.fromValue('power'), const Option<BillIcon>.of(BillIcon.power));
  expect(BillIcon.fromValue(null), const Option<BillIcon>.none());
  expect(BillIcon.fromValue('rocket'), const Option<BillIcon>.none());
});
```
- [ ] **Step 2: Run them.** `flutter test test/ledger/domain/entities/bill_icon_test.dart` should FAIL because `bill_icon.dart` doesn't exist yet.
- [ ] **Step 3: Implement `BillIcon`.** Lowercase the name, replace every run of characters outside `[a-z0-9-]` with one space, and pad with spaces. A key matches when `' $key '` is contained in that string. Check the groups in this order, using the word table in mockup 27 (`ICONS`): loan, card, power, internet, phone, tv, school, water, gas, insurance, help, milk, society, home, car. `// why:` comment: the order settles names that hit two groups.
- [ ] **Step 4: Run them.** They should PASS.
- [ ] **Step 5: Write the failing storage tests.**
  - Migration: open a v1 database, insert a rule, upgrade to v2, and expect the row with `icon` null. A fresh database has the `icon` column.
  - Mapper: a round trip keeps `Option.of(BillIcon.gas)`. A row with `icon: 'rocket'` maps to a rule with `icon: none`; it doesn't fail.
- [ ] **Step 6: Implement the storage.**
  - `migration002BillIcon`: `ALTER TABLE recurring ADD COLUMN icon TEXT`. Append it to `migrations`.
  - `RecurringModel.icon`: a `String?` read with `row[RecurringColumns.icon] as String?` and written in `toRow`.
  - The mapper uses `BillIcon.fromValue` and `icon.map((i) => i.value).toNullable()`.
  - `RecurringRule.props` includes `icon`.
- [ ] **Step 7: Run the suite.** `flutter test test/core/db test/ledger` should PASS, and the existing tests should still pass unchanged.
- [ ] **Step 8: Commit.** `feat(ledger): bill icons from the name, stored per rule`

### Task 3: Icons through add and edit

**Files:**
- Modify: `lib/ledger/domain/entities/bill_input.dart`, `lib/ledger/domain/bill_validator.dart`, `lib/ledger/domain/usecase/edit_bill.dart`, `add_bill.dart`
- Test: `test/ledger/domain/usecase/edit_bill_test.dart`, `add_bill_test.dart`

**Interfaces:**
- Produces: `BillInput({label, amount, dueDay, Option<BillIcon> icon = none})`. The validator keeps `icon`. `EditBill` writes `icon` and so does `AddBill`; the wizard always passes none.

- [ ] **Step 1: Write the failing tests in `edit_bill_test.dart`.**
  - `'changing only the amount keeps next_due for day 31 in a 30-day month'`: a rule with day 31 and `nextDue` 2026-11-30, today 2026-10-26, input of the same label and day with a new amount → `nextDue` is 2026-11-30.
  - `'saves a picked icon, and none clears it'`.
- [ ] **Step 2: Run them.** Expect them to FAIL: `icon` isn't a parameter yet, so they don't compile.
- [ ] **Step 3: Implement.** Add `icon` to `BillInput` and its props. `_edited` passes `icon: Option.of(input.icon)` to `copyWith`, and `AddBill._draft` sets `icon: input.icon`.
- [ ] **Step 4: Run them.** `flutter test test/ledger` should PASS. If the day-31 test fails, `EditBill._nextDue` has a bug: fix it test-first and say so in the commit.
- [ ] **Step 5: Commit.** `feat(ledger): bills save their icon`

### Task 4: `GetBillStatus` for the stamp

**Files:**
- Create: `lib/ledger/domain/entities/bill_status.dart`, `lib/ledger/domain/usecase/get_bill_status.dart`
- Modify: `lib/ledger/di/ledger_module.dart`, `lib/ledger/ledger.dart`
- Test: `test/ledger/domain/usecase/get_bill_status_test.dart`

**Interfaces:**
- Produces: `sealed class BillStamp` with `BillStampDue(int days)`, `BillStampCounted(CalendarDate on)` and `BillStampNone()`.
- Produces: `BillStatus({required CalendarDate nextDate, required int daysAway, required BillStamp stamp})`.
- Produces: `GetBillStatus({required LedgerRepository ledger, required Clock clock}) implements UseCase<BillStatus, RecurringRule>`.

- [ ] **Step 1: Write the failing tests.** Use `FakeLedgerRepository` and today = 2026-10-26.
  - Electricity, day 29, `nextDue` 10-29 → `BillStampDue(3)`, `daysAway` 3.
  - Rent, day 5, `nextDue` 11-05, with an entry `recurringId` = rent dated 10-05 → `BillStampCounted(2026-10-05)`.
  - The same rent with no entry (added mid-cycle, D33) → `BillStampNone`.
  - A bill posted today (`nextDue` 11-26, entry dated 10-26) → `BillStampCounted(2026-10-26)`.
  - `nextDue` 11-01 (6 days away) with the October entry → `Counted`, not `Due`. The window is exactly `GetDueSoonBill.window`.
- [ ] **Step 2: Run them.** They should FAIL because the use case doesn't exist yet.
- [ ] **Step 3: Implement.**
  - `nextDate` = `RecurringSchedule.firstUnpostedAfter(rule.schedule, rule.nextDue, today: today)`.
  - Due when `1 ≤ daysAway ≤ GetDueSoonBill.window`.
  - Otherwise read `ledger.entriesBetween(previous, today)`. `previous` is the schedule's occurrence one period before `rule.nextDue`; add `RecurringSchedule.previous(Schedule, CalendarDate)`, test-first, if nothing provides it. Keep the latest entry with `recurringId == rule.id`.
  - Register the use case in `ledger_module.dart`.
- [ ] **Step 4: Run them.** They should PASS.
- [ ] **Step 5: Commit.** `feat(ledger): a bill's status for its stamp`

### Task 5: Due-soon carries its rule

**Files:**
- Modify: `lib/ledger/domain/entities/due_soon_bill.dart`, `lib/ledger/domain/usecase/get_due_soon_bill.dart`
- Test: `test/ledger/domain/usecase/get_due_soon_bill_test.dart`, plus every test that constructs `DueSoonBill` (`grep -rln "DueSoonBill(" test`)

**Interfaces:**
- Produces: `DueSoonBill({required RecurringRule rule, required CalendarDate dueDate, required int daysAway})`, with getters `label => rule.label` and `amount => rule.amount`.

- [ ] **Step 1: Write the failing test.** `'carries the rule it came from'`: `bill.rule == electricityRule`.
- [ ] **Step 2: Implement it, and update the callers that construct `DueSoonBill`.** The constructor change is the reason for those edits; their assertions stay.
- [ ] **Step 3: Run the suite.** `flutter test test/ledger test/home` should PASS.
- [ ] **Step 4: Commit.** `refactor(ledger): due-soon bill keeps its rule`

### Task 6: `BillSheetBloc`

**Files:**
- Create: `lib/settings/presentation/bloc/bill_sheet_bloc.dart`, `bill_sheet_event.dart`, `bill_sheet_state.dart`
- Test: `test/settings/presentation/bloc/bill_sheet_bloc_test.dart`

**Interfaces:**
- Consumes: `EditBill`, `GetBillStatus` (Task 4), `Haptics`, `RecurringRule.shownIcon` (Task 2).
- Produces:
  - Constructor: `BillSheetBloc({required RecurringRule rule, required EditBill editBill, required GetBillStatus getStatus, required Haptics haptics})`.
  - `enum BillAnswer { amount, day, name, icon }`.
  - States:
    - `BillSheetReady({rule, Option<BillStatus> status, Option<BillAnswer> open, int rupees, bool fresh, String draftName, Option<BillAnswer> justSaved, bool saving, bool saveFailed, int rejections})`
    - `BillSheetClosed(BillSheetOutcome outcome)`
  - Outcome: `sealed BillSheetOutcome` with `BillSheetUnchanged`, `BillSheetChanged(RecurringRule rule)` and `BillSheetDeleted(RecurringRule rule)`.
  - Events: `BillSheetStatusRequested`, `BillSheetAnswerOpened(BillAnswer)`, `BillSheetBackPressed`, `BillSheetKeyPressed(String key)`, `BillSheetBackspacePressed`, `BillSheetCleared`, `BillSheetAmountSaved`, `BillSheetDayChosen(int day)`, `BillSheetNameChanged(String name)`, `BillSheetNameSaved`, `BillSheetIconChosen(BillIcon icon)`, `BillSheetDeleteRequested`, `BillSheetCloseRequested`, `BillSheetSavedNoteExpired`.

- [ ] **Step 1: Write the failing tests.** Use the `bloc_dispatch.dart` helper, and `FakeRecurringRepository` behind a real `EditBill`.
  - Opening Amount sets `rupees` to the rule's rupees with `fresh: true`. The first `KeyPressed('5')` gives `rupees == 5`.
  - `AmountSaved` with 1350 → one `update` carrying the same day, label and icon. State returns to the bill with `justSaved == amount` and `rule.amount` ₹1,350. Status is reloaded.
  - `AmountSaved` with an unchanged amount → no `update`, back to the bill, `justSaved` none.
  - `DayChosen(20)` → D34 next date 2026-11-20. With the day unchanged → no save.
  - `NameSaved` with "  Airtel fibre " → saved trimmed. A blank name → ignored.
  - Picked icon kept: `rule.icon == Option.of(BillIcon.car)`, then `NameSaved("Gas")` → the icon is still car.
  - `IconChosen(BillIcon.power)` on "Electricity" (its `forName`) → saved as `icon: none`. `IconChosen(card)` → `Option.of(card)`.
  - Two `AmountSaved` events back to back → exactly one `update`. Use `droppable()` on every save event.
  - A failed save → `saveFailed: true`, the question stays open and `haptics.reject` is called.
  - `BackPressed` on a question → `open: none`. On the bill → `BillSheetClosed(BillSheetChanged(rule))` if anything was saved, else `BillSheetUnchanged`.
  - `DeleteRequested` → `BillSheetClosed(BillSheetDeleted(rule))`. The bloc doesn't delete; the screen that opened the sheet does (Undo lives there).
- [ ] **Step 2: Run them.** They should FAIL because the bloc doesn't exist yet.
- [ ] **Step 3: Implement.**
  - The amount keys reuse `AmountInput.append` and `AmountInput.backspace`.
  - Every save builds the full `BillInput` from `state.rule` with one field replaced, and calls `EditBill`.
  - Haptics: `tick` on a key and on a save, `reject` on a refused key or a failure.
  - `StatusRequested` uses `restartable()`, and is added at construction and after each save.
  - The page dispatches `SavedNoteExpired` 2.4 s after a save.
- [ ] **Step 4: Run them.** They should PASS.
- [ ] **Step 5: Commit.** `feat(settings): bill sheet bloc, one answer per save`

### Task 7: The sheet UI

**Files:**
- Create: `lib/settings/presentation/pages/bill_sheet.dart` (`BillSheet` with a static `show`). Under `lib/settings/presentation/widgets/bill_sheet/`, create:
  - `bill_slip.dart`: the full and compact slip, torn edge and perforation, drawn by a `CustomPainter`.
  - `bill_stamp.dart`
  - `bill_answer_row.dart`
  - `bill_amount_question.dart`
  - `bill_day_question.dart`
  - `bill_name_question.dart`
  - `bill_icon_question.dart`
- Modify: `lib/core/widgets/day_of_month_grid.dart` (`Option<int> selected = none`), `lib/l10n/app_en.arb`
- Test: matching files under `test/settings/presentation/`, plus `test/core/widgets/day_of_month_grid_test.dart`

**Interfaces:**
- Consumes: `BillSheetBloc` (Task 6), `BillStatus` and `BillStamp` (Task 4), `AppIcons.bill` (Task 2).
- Produces: `static Future<BillSheetOutcome> BillSheet.show(BuildContext context, BillSheetBloc bloc)`, which copies `AddEntryTray.show`'s route set-up and returns `BillSheetUnchanged` if the sheet is dismissed.

- [ ] **Step 1: Add the strings** (draft copy, mockup 27), then run `flutter gen-l10n`. Ask the `design-content` agent to review them before Step 5.
  - `billSheetEyebrow` "Fixed bill"
  - `billStampDue` "{days, plural, =1{Due tomorrow} other{Due in {days} days}}"
  - `billStampCounted` "Counted {date}"
  - `billStampCountedToday` "Counted today"
  - `billAnswerAmount` "Amount", `billAnswerDay` "Day of the month", `billAnswerName` "Name", `billAnswerIcon` "Icon"
  - `billChangeSpoken` "Change {answer}, {value}"
  - `billNextGoesOut` "Next goes out {date}"
  - `billSaved` "Saved."
  - `deleteBill` "Delete bill"
  - `save` "Save" (if missing)
  - `billWas` "Was {amount}"
  - `billIconQuestion` "Pick an icon for {bill}"
  - `billIconFromName` "From the name: {icon}"
  - `billIconNoMatch` "No icon matches the name"
  - `billNameIconFollows` "Icon from the name: {icon}"
  - `billNameIconKept` "Icon stays {icon}. Change it on the bill."
  - `billIconName` as a `select` over the 16 values: Bill, Home, Power, Phone, Internet, Loan, Card, TV & apps, School, Water, Gas, Insurance, House help, Milk, Society, Car
  - `billSlipSpoken` "{bill}, {icon}, {amount}, every month on day {day}"
- [ ] **Step 2: Write the failing widget tests.**
  - The bill shows four rows labelled `billChangeSpoken`.
  - The stamp text for each `BillStamp`.
  - Tapping Amount shows the keypad and *Save*.
  - Tapping a day dispatches `DayChosen`.
  - The icon grid shows 16 labelled tiles with the current one marked "picked".
  - *Delete bill* is a full-width key.
  - `saveFailed` shows `couldntSave`.
  - With `disableAnimations`, the stamp has no scale animation.
  - The slip's semantics read `billSlipSpoken`.
  - No overflow at each `TestWindows` size.
  - In `day_of_month_grid_test.dart`: `selected: Option.of(29)` marks day 29 as selected in semantics.
- [ ] **Step 3: Implement it** to mockup 27, with tokens only. The question views reuse `Keypad`, `AmountDisplay`, `SignalKey` and `DayOfMonthGrid`. The name field uses the theme's text field. Icon tiles follow `CategoryTile`'s shape. The stamp's squash uses the spring tokens.
- [ ] **Step 4: Run them.** `flutter test test/settings test/core/widgets` should PASS.
- [ ] **Step 5: Commit.** `feat(settings): the bill sheet`

### Task 8: Wire Fixed bills, and make the wizard add-only

**Files:**
- Modify: `lib/app/routes.dart` (`bills`, `billEditor`, and a new `openBillSheet`), `lib/settings/presentation/widgets/bill_row.dart` (the bill's icon), `lib/settings/presentation/bloc/bill_editor_bloc.dart`, `bill_editor_state.dart`, `lib/settings/presentation/pages/bill_editor_page.dart`, `lib/settings/presentation/widgets/bill_name_step.dart`
- Test: `test/settings/presentation/pages/bills_page_test.dart`, `test/settings/presentation/widgets/bill_row_test.dart`, `test/settings/presentation/bloc/bill_editor_bloc_test.dart`, `test/settings/presentation/pages/bill_editor_page_test.dart`

**Interfaces:**
- Produces: `static Future<BillSheetOutcome> Routes.openBillSheet(BuildContext context, GetIt getIt, RecurringRule rule)`.
- Changes: `BillEditorBloc` loses its `editing` parameter, `BillEditorInProgress` loses `isEditing`, and `BillNameStep` loses `onDelete`.

- [ ] **Step 1: Write the failing tests.**
  - Tapping a bill row opens the sheet (find `BillSheet`), not the editor.
  - Outcome `BillSheetDeleted(rule)` → the list dispatches `BillsDeleteRequested(rule)` and Undo is offered.
  - Outcome `BillSheetChanged` → `BillsLoadRequested`.
  - `BillRow` shows `AppIcons.bill(rule.shownIcon)`.
- [ ] **Step 2: Remove the editing path.** Delete the edit-mode tests in `bill_editor_bloc_test.dart` and `bill_editor_page_test.dart`: FR-SE-1 (Task 1) removed that behaviour. List each deleted test name in the commit message. Leave the add-mode tests unchanged.
- [ ] **Step 3: Implement it, then run.** `flutter test test/settings` should PASS.
- [ ] **Step 4: Commit.** `feat(settings): Fixed bills opens the bill sheet; the wizard only adds`

### Task 9: Home's due-soon row opens the bill

**Files:**
- Create: `lib/home/presentation/widgets/due_soon_row.dart`, which replaces `due_soon_note.dart`. Delete the note and its test.
- Modify: `lib/home/presentation/pages/home_page.dart` (`onOpenBill: ValueChanged<RecurringRule>`), `lib/home/presentation/bloc/home_bloc.dart`, `home_event.dart`, `home_state.dart`, `lib/app/routes.dart`, `lib/l10n/app_en.arb` (`dueSoonOpensBill` "Opens the bill.")
- Test: `test/home/presentation/widgets/due_soon_row_test.dart`, `test/home/presentation/bloc/home_bloc_test.dart`, `test/home/presentation/pages/home_page_test.dart`

**Interfaces:**
- Consumes: `DueSoonBill.rule` (Task 5) and `Routes.openBillSheet` (Task 8).
- Produces: `HomeBillDeleteRequested(RecurringRule rule)`, `HomeBillUndoRequested(RecurringRule rule)` and `HomeReady.billUndo: Option<RecurringRule>`. `HomeBloc` gains `DeleteBill` and `RestoreBill`.

- [ ] **Step 1: Write the failing tests.**
  - The row is a button at least 56dp tall, with the bill's icon, the `billGoesOut` sentence, the date and a chevron. Its semantics read `billGoesOut` plus `dueSoonOpensBill`.
  - A tap calls `onOpenBill(rule)`.
  - `HomeBillDeleteRequested` → `DeleteBill` is called, `billUndo` is some, and the data reloads.
  - `HomeBillUndoRequested` → `RestoreBill` is called and the data reloads.
- [ ] **Step 2: Implement it.** The routes callback opens the sheet, then on `Changed` dispatches `HomeLoadRequested` and on `Deleted` dispatches `HomeBillDeleteRequested`. The page shows the `billDeleted` snackbar with Undo, as the Bills page does.
- [ ] **Step 3: Run them.** `flutter test test/home` should PASS.
- [ ] **Step 4: Commit.** `feat(home): due-soon row opens the bill`

### Task 10: Verify

- [ ] **Step 1:** `flutter analyze`. Expected: no issues.
- [ ] **Step 2:** `flutter test`. Expected: all pass.
- [ ] **Step 3:** `scripts/changed_lines_coverage.sh master`. Expected: ≥ 90%; list every uncovered line with a reason.
- [ ] **Step 4:** Check on a device with the `live-app-inspection` skill. Open a bill from Home and from Fixed bills, change each answer, and use Back, predictive back and the scrim. Check the keyboard over the name question, large text, landscape, and dark mode. Compare against mockup 27.
- [ ] **Step 5:** Commit any fixes. `fix(bills): device pass`

## Not in this plan

- **The add wizard's name step showing the icon live:** held, the wizard is unchanged apart from becoming add-only.
- **"Paid already? Count it today":** held (D116).
