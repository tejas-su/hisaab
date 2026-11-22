# Upcoming bills strip. Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home shows a "Next 7 days" strip listing the recurring bills and savings that go out tomorrow to 7 days from today, with one gentle line when those bills are the reason today's share is ₹0.

**Architecture:**
- A new use case `GetUpcomingBills` lists the occurrences from the recurring engine's own date maths (`RecurringSchedule.firstUnpostedAfter` and `datesFrom`).
- A pure `UpcomingWarning` decides the warning from the `CycleSummary` and the list, using `SafeToSpend.shareOfPool`.
- `HomeBloc` carries the list in `HomeReady` and a new `UpcomingBillsStrip` widget draws it.
- The strip **replaces** the due-soon row (see decision A below).

**Tech stack:** Flutter, `flutter_bloc`, `fpdart`, `material_ui`, Hugeicons. No new dependency.

**Spec:** to be written in Task 1 (new FR-HO-10 and a BR-9 edit). Today's rules it builds on: SPEC BR-3 (pool, `B`, `R`), BR-4 (share), BR-9 (engine, due-soon nudge), FR-HO-3 (nudge slot), FR-HO-8 (bill sheet); D118, D119, D120, D123. UI: UI_DESIGN §5 (Home), §9 (accessibility), §13 (test windows).

## Decisions I made (you asked me to pick defaults)

| # | Decision | Why | The other way |
|---|---|---|---|
| A | **The strip replaces `DueSoonRow`** and the 1–5 day window grows to 7 days, several bills. `GetDueSoonBill`, `DueSoonBill` and `DueSoonRow` stay in the tree, unused by Home, until you say delete (CLAUDE.md: mention dead code, don't delete it) | The strip's first row *is* the soonest bill. Keeping both shows the same bill twice in one slot | Keep the row and add the strip below it. No spec edit needed, but the soonest bill appears twice. **This needs your OK: it edits FR-HO-3 and BR-9, and the due-soon tests under `test/home/` change with them** |
| B | **"Next 7 days" means 1 to 7 days after today.** Today's bills are the engine's (BR-9) and already out of the pool (D119) | Matches the due-soon rule "occurrences due today are never shown" | Include today |
| C | **The strip lists *Spent* and *Saved* rules** (fixed, changing, card). Not *Got* | The old nudge covered bills and savings (D120). A saving is in `R`, so it shrinks the share the same way a bill does | Bills only |
| D | **The warning fires when the bills are the cause.** Today's share is ₹0 now, and it would be above ₹0 if the listed counted bills in this cycle were added back to the pool: `todayShare == 0` and `shareOfPool(pool + addBack, daysLeft) > 0` | The share is already net of bills (BR-3), so "a bill pushes the share to zero" can only mean "bills already counted are why it is ₹0". If it is ₹0 without them, the over card (FR-HO-5) owns that, and blaming bills would be wrong | Warn on any ₹0 share, or warn on a low share |
| E | **Only bills in the pool maths go in `addBack`:** *Spent* fixed and changing (at the estimate, as `B` does) and *Saved* rules, dated on or before the cycle's last day. **Card bills are listed but never counted** (D123), and a bill dated after payday is listed but not counted (it belongs to the next cycle) | Keeps the warning's arithmetic identical to BR-3's `B` and `R` | List-only totals |
| F | **The strip is not a nudge-slot item.** The waiting line still outranks it. The install and missed-log lines are held back only when a bill is within the old 5 days (what `dueSoon.isSome()` did) | Keeps FR-HO-3's order and the install and missed-log timing. A 7-day hold would hide them 7 days in 30 | Hold them for the full 7 days |
| G | **Copy is calm, no verdict colour.** The warning is words plus a glyph on a `sunk` surface: "Bills coming up use all of today's share." Content design reviews it before it ships | No red, no green (CLAUDE.md). Banned words checked: none used | |
| H | **Tapping a row opens that bill's or saving's sheet** (the existing `onOpenBill`). No new screen, no new setting | PLAN §2 zero-config | |

## Global constraints

- Money is `Money` in paise; show amounts only through `MoneyFormatter` (`context.money.format`). Never paise.
- "Today" comes from the injected `Clock`. Dates are `CalendarDate`. Date maths stays in `RecurringSchedule`, never a second copy.
- All text is in `lib/l10n/app_en.arb` with `@description`s; run `flutter gen-l10n`. Banned words: "transaction", "debit/credit", "budget period", "Oops".
- Tokens only (`HisaabColors`, `TextTheme`, `HisaabSpacing`). No `Color(0xFF…)`, `Colors.*`, `Icons.*`. Icons through `AppIcon` with a label. Marigold is not used on the strip.
- Import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
- Bloc everywhere, sealed events, `restartable()` for loads. No Cubits. No `GetIt` below the composition root.
- Hand-written fakes in `test/helpers/`. No `mocktail` or `bloc_test` without asking. Pin "today" with `FakeClock`.
- Existing tests are the contract. The only tests that may change are the due-soon ones named in decision A, and only after you approve it.
- The Add flow is untouched. The git repo is local only: no remote, no push, commit only when asked.
- Layout reads `context.layout`, never raw `MediaQuery` widths. New widgets are pumped at the `TestWindows` sizes.
- Work on a branch cut from `main` once `feature/daily-nudge` is merged. The working tree on `feature/daily-nudge` has uncommitted edits (backup, notifications, nudge tests) that this plan must not touch.

## Review focus

| # | Input or condition | What a reasonable person expects | Pinned in |
|---|---|---|---|
| 1 | Payday is tomorrow, or `daysLeft == 1` | Bills dated after payday are listed but not counted. The warning compares against the whole remaining pool | Task 3 |
| 2 | Share is ₹0 and would still be ₹0 without the bills (already over) | No warning. The over card speaks, not the strip | Task 3 |
| 3 | A bill on the 29th–31st, across February or a leap year | The date lands on the clamped day, once | Task 2 |
| 4 | Six bills in one week, a 1.5× text scale and a narrow window | Nothing overflows; rows stay tappable at 48dp or more; the page scrolls | Task 5 |
| 5 | A card bill and a changing bill in the window | Card bill shows "pay by" and is not in the total; changing bill says "about" | Tasks 2, 5 |

---

### Task 1: Spec and decision first

**Files:**
- Modify: `docs/SPEC.md` (BR-9 due-soon paragraph; FR-HO-3 due-soon item; new FR-HO-10; edge cases after the last `E` row)
- Modify: `docs/DECISIONS.md` (append rows, next free D numbers)
- Modify: `docs/UI_DESIGN.md` §5 (Home): the strip's place, rows, warning line, states
- Modify: `docs/PLAN.md` (milestone or roadmap line, if item 6 is tracked there)
- Create: `docs/design/mockups/NN-upcoming-bills-strip.html` (next free number; light and dark, a 1-bill, a 4-bill and a warning state), via the `design-ui` agent
- Review: `design-content` agent on the copy; `design-accessibility` agent on semantics

**Interfaces:**
- Produces: the BR/FR/E IDs later tasks cite in test names.

- [ ] **Step 1: Get your OK on decision A.** If you choose "keep the row and add the strip", stop and revise Tasks 4 and 5.
- [ ] **Step 2: Edit SPEC.** BR-9's due-soon paragraph becomes the strip's rules (decisions B to E, with a worked example). FR-HO-3 drops the due-soon item and keeps order *waiting → (strip is below the slot) → install → missed-log*. Add FR-HO-10 with acceptance criteria AC-1 to AC-6: list, order, rows, warning, tap, hidden when empty.
- [ ] **Step 3: Worked example in SPEC.** Pool ₹2,800 over 4 days left gives ₹700. Rent ₹3,000 on day 3 is already in `B`, so `P` is already net of it. Use a case where today's share reads ₹0 and adding ₹1,200 back lifts it above ₹0. Write the numbers so Task 3's tests copy them.
- [ ] **Step 4: Append DECISIONS rows** for A to H, citing D118, D119, D120, D123.
- [ ] **Step 5: Mockup and copy review.** Commit nothing yet.

---

### Task 2: `GetUpcomingBills` (TDD)

**Files:**
- Create: `lib/ledger/domain/entities/upcoming_bill.dart`
- Create: `lib/ledger/domain/usecase/get_upcoming_bills.dart`
- Modify: `lib/ledger/ledger.dart` (export both), `lib/ledger/di/ledger_module.dart` (register next to `GetDueSoonBill`, line ~71)
- Test: `test/ledger/domain/usecase/get_upcoming_bills_test.dart`

**Interfaces:**
- Consumes: `RecurringRepository.activeRules() → TaskEither<Failure, List<RecurringRule>>`, `Clock.today()`, `RecurringSchedule.firstUnpostedAfter(schedule, nextDue, today:)`, `RecurringSchedule.datesFrom(schedule, first, through:)`, `AmountMode` (read `lib/ledger/domain/entities/` for its values), `RecurringRule.kind`, `.amount`, `.amountMode`.
- Produces:
  - `final class UpcomingBill extends Equatable { const UpcomingBill({required RecurringRule rule, required CalendarDate dueDate, required int daysAway}); String get label; Money get amount; bool get isApproximate; bool get isCard; }`. `isApproximate` is true for a changing bill. `isCard` is true for a card bill. Both read `rule.amountMode`.
  - `final class GetUpcomingBills implements UseCase<List<UpcomingBill>, NoParams> { static const int window = 7; }`. `call` returns `Right` with bills ordered by `dueDate`, then rule id, or `Left` with the repository failure.

- [ ] **Step 1: Write failing tests** with `FakeClock` and a fake repository. Names and assertions:
  - `lists_nothing_with_no_rules`: `Right(<UpcomingBill>[])`.
  - `skips_today_and_includes_day_7_but_not_day_8`: due at +0 and +8 absent, +1 and +7 present (`daysAway` 1 and 7).
  - `ignores_got_and_inactive_rules`: income rule absent; inactive rule absent (fake returns only active, assert `.kind == got` filtered).
  - `skips_a_stale_next_due_but_lists_the_next_date`: `nextDue` three days ago lists the first date after today.
  - `clamps_the_31st_in_february` and `clamps_the_29th_on_a_leap_year`: the 31st rule lists 28 Feb (29 Feb in a leap year), once, in a window that crosses the month end.
  - `lists_a_weekly_rule_once_in_the_window`.
  - `orders_by_date_then_rule_id`.
  - `flags_changing_and_card_bills`.
  - `maps_a_repository_failure_to_left`.
- [ ] **Step 2: Run them.** `flutter test test/ledger/domain/usecase/get_upcoming_bills_test.dart`. Expected: FAIL, `GetUpcomingBills` undefined.
- [ ] **Step 3: Implement.** Filter to `spent` and `saved`, then `firstUnpostedAfter` → `datesFrom(through: today.addDays(window))` → one `UpcomingBill` per date. Dartdoc says what Left and Right mean. Add a `// why:` that the window starts tomorrow because today is the engine's.
- [ ] **Step 4: Run the tests.** Expected: PASS. Run `flutter analyze` too.
- [ ] **Step 5: Commit** (only if you ask): `feat: add GetUpcomingBills for the next 7 days`.

---

### Task 3: `UpcomingWarning` (TDD)

**Files:**
- Create: `lib/ledger/domain/upcoming_warning.dart`
- Modify: `lib/ledger/ledger.dart`
- Test: `test/ledger/domain/upcoming_warning_test.dart`

**Interfaces:**
- Consumes: `CycleSummary` (`pool`, `todayShare`, `daysLeft`, `cycle`), `SafeToSpend.shareOfPool(Money pool, int daysLeft)`, `UpcomingBill`.
- Produces:
  - `abstract final class UpcomingWarning { static Money addBack(CycleSummary summary, List<UpcomingBill> bills); static bool applies(CycleSummary summary, List<UpcomingBill> bills); }`.
  - `addBack` sums `amount` of bills that are not card bills and whose `dueDate` is on or before `summary.cycle.end`. The strip's "₹X goes out" line also uses it, so the total and the warning always agree.

- [ ] **Step 1: Write failing tests** using the numbers from Task 1's worked example:
  - `warns_when_bills_are_why_the_share_is_zero`: share 0; adding back lifts it above 0 → `true`.
  - `does_not_warn_when_the_share_is_zero_without_the_bills` (review 2): pool ≤ 0 even after the add-back → `false`.
  - `does_not_warn_when_the_share_is_above_zero`.
  - `ignores_card_bills_in_the_add_back`: card bill alone cannot cause a warning.
  - `ignores_bills_dated_after_payday` (review 1): a bill past `cycle.end` is not added back.
  - `warns_with_one_day_left_when_the_whole_pool_is_taken` (`daysLeft == 1`).
  - `handles_zero_and_the_nine_digit_cap`: ₹0 amounts; a ₹99,99,99,999 bill does not overflow `Money`.
  - `add_back_matches_the_listed_total`.
- [ ] **Step 2: Run to verify FAIL**, then **Step 3: implement** as pure functions, then **Step 4: run to PASS** and `flutter analyze`.
- [ ] **Step 5: Commit** (only if asked): `feat: add UpcomingWarning`.

---

### Task 4: Bloc wiring

**Files:**
- Modify: `lib/home/presentation/bloc/home_state.dart` (replace `Option<DueSoonBill> dueSoon` with `List<UpcomingBill> upcoming`, update `copyWith` and `props`), `home_bloc.dart` (constructor takes `GetUpcomingBills`; `_load` reads it where `_getDueSoonBill` is read, lines ~128–134, logging `home.upcoming_failed` with `runtimeType` only), `lib/home/presentation/widgets/home_lines_driver.dart:134` (`_billLineShowing` becomes "waiting bills not empty or any upcoming bill has `daysAway <= GetDueSoonBill.window`"), `lib/ledger/di/ledger_module.dart`, wherever `HomeBloc` is constructed (route builder, `test/helpers/`)
- Test: `test/home/presentation/bloc/home_bloc_test.dart`, `test/home/presentation/widgets/home_lines_driver_test.dart`, plus a fake `GetUpcomingBills` in `test/helpers/fake_services.dart` if that file's pattern fits

**Interfaces:**
- Consumes: `GetUpcomingBills` (Task 2).
- Produces: `HomeReady.upcoming: List<UpcomingBill>`; the driver's rule in decision F.

- [ ] **Step 1: Write failing bloc tests:** `load_carries_the_upcoming_bills`; `a_failed_upcoming_read_leaves_the_list_empty_and_home_still_loads` (mirrors the due-soon failure case); `a_reload_after_a_bill_edit_refreshes_the_list`. Driver test: `install_and_missed_log_wait_only_for_a_bill_within_five_days`; `a_bill_on_day_six_or_seven_does_not_hold_the_slot`.
- [ ] **Step 2: Run to verify FAIL.** `flutter test test/home`.
- [ ] **Step 3: Implement** the swap. This is where the due-soon tests change (decision A); do not edit any other existing test.
- [ ] **Step 4: Run `flutter test test/home test/ledger`** to verify PASS.
- [ ] **Step 5: Commit** (only if asked): `feat: load upcoming bills on Home`.

---

### Task 5: The strip widget

**Files:**
- Create: `lib/home/presentation/widgets/upcoming_bills_strip.dart` (the card: title, total, warning, rows), `upcoming_bill_row.dart` (one tappable row, reusing the `DueSoonRow` look: icon well, label, date, chevron), `upcoming_warning_line.dart`
- Modify: `lib/home/presentation/pages/home_page.dart` (`_nudge` at line ~153: drop the `DueSoonRow` branch; render the strip below the slot when `state.upcoming` is not empty), `lib/l10n/app_en.arb`
- Test: `test/home/presentation/widgets/upcoming_bills_strip_test.dart`, `test/home/presentation/pages/home_page_test.dart`, `test/a11y_test.dart` (add a case)

**Interfaces:**
- Consumes: `HomeReady.upcoming`, `UpcomingWarning.applies` and `addBack` (Task 3), `RecurringRule.shownIcon` (icon via `rule_glyph.dart`), `rule_words.dart`, `Pressable`, `onOpenBill: ValueChanged<RecurringRule>`.
- Produces: `UpcomingBillsStrip({required List<UpcomingBill> bills, required CycleSummary summary, required ValueChanged<RecurringRule> onOpenBill})`. It builds nothing for an empty list.

- [ ] **Step 1: Write failing widget tests** (pumped through `pumpApp` at each `TestWindows` size):
  - `shows_nothing_for_no_bills`.
  - `shows_one_row_per_bill_with_label_amount_and_weekday`; "tomorrow" for `daysAway == 1`.
  - `a_changing_bill_says_about_and_a_card_bill_says_pay_by_and_is_not_in_the_total` (review 5).
  - `shows_the_warning_only_when_UpcomingWarning_applies`, and the warning's words are present (state is never colour alone).
  - `tapping_a_row_calls_onOpenBill_with_its_rule`.
  - `six_bills_at_1_5x_text_scale_do_not_overflow_and_keep_targets_48dp` (review 4), plus `rows_share_the_hero_cards_edges` (the alignment test the presentation rules ask for).
  - Semantics: each row is one node reading "{Label}, about {n} rupees, {weekday}. Opens the bill." (spoken amount via `spokenAmount`, labels unique); the warning is read after the title; `meetsGuideline` for tap target, labelled target and contrast.
  - Page test: waiting line shown → strip still shown below it; strip hidden in *No income* and in the over state's layout stays unbroken.
- [ ] **Step 2: Run to verify FAIL.**
- [ ] **Step 3: Implement.** ARB keys (final copy comes from `design-content`): `upcomingTitle` "Next 7 days", `upcomingTotal` "{amount} goes out", `upcomingTomorrow`, `upcomingAbout`, `upcomingCardPayBy`, `upcomingWarning` "Bills coming up use all of today's share.". Surface is `sunk`; warning has a Hugeicons glyph from `AppIcons` (add one if none fits, per D48) and words. A strip row's tap and Undo path reuse what `DueSoonRow` hooks already do in `HomePage`, so nothing new is wired.
- [ ] **Step 4: `flutter gen-l10n`, then `flutter test test/home test/a11y_test.dart`.** Expected: PASS.
- [ ] **Step 5: Commit** (only if asked): `feat: add the upcoming bills strip to Home`.

---

### Task 6: Docs in sync and the done check

**Files:**
- Modify: `docs/features/` (the Home or recurring doc that describes the due-soon row, if one exists; otherwise mention it, don't create one), `docs/UI_DESIGN.md`, mockup README index

- [ ] **Step 1:** Update any feature doc that names the due-soon row. Note the unused `GetDueSoonBill`, `DueSoonBill` and `DueSoonRow` for you to approve deleting.
- [ ] **Step 2: Run the gates:** `flutter analyze` (expect no issues), `flutter test` (expect all pass), `scripts/changed_lines_coverage.sh main` (expect ≥ 90% of changed lines; list any gaps with reasons).
- [ ] **Step 3: Run the app** on a device or emulator: seed a rent bill 3 days out, a changing bill, a card bill and a saving; check light and dark, TalkBack reading, a 1.5× text scale, split-screen and landscape. Say what you checked and what you could not.
- [ ] **Step 4:** Ask `design-ops` for a doc-sync pass and `design-validation` for a design QA pass against the mockup.

---

## Self-review

- **Spec coverage:** the 7-day list (Tasks 2, 5), the warning (Task 3, decision D), the existing engine data (Task 2), tap to open (Task 5), docs (Tasks 1, 6).
- **Types:** `UpcomingBill`, `GetUpcomingBills.window`, `UpcomingWarning.applies/addBack` and `HomeReady.upcoming` keep one name throughout.
- **Open risks I could not settle from the code:**
  - The strip adds height to Home, and I did not read UI_DESIGN §5 or the two-pane layout. Task 1's mockup and Task 5's `TestWindows` tests settle it.
  - I did not read `rule_words.dart` or `AmountMode`'s values. Task 2 and Task 5 read them first.
  - Decision A edits a shipped spec line and its tests, so it needs your OK before Task 1 starts.
