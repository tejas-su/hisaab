# Your usual (D153, phase 1). Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Status after D154 (second review, 2026-11-13):** the owner's answers to OQ-1 to OQ-7 and OQ-9 to OQ-16 are now in SPEC (BR-17, BR-10, BR-16, FR-AD-1, FR-AD-10, FR-SE-2 AC-6, E58–E71). SPEC wins over this plan wherever they differ. Still open: **OQ-17 (ask before Task 4)**, OQ-8 (measured in Task 9, reported, not blocking) and the three wording points in *Open questions for the owner*. Tasks 1–3 can start now.

**Goal:** When the user opens the Add tray at the time they habitually log a spend, a 40dp outlined pill "Chai ₹20 · your usual" sits in a 48dp slot under the amount. One tap saves the entry and closes the tray, with "Added ₹20 to Chai" and *Undo*. Settings › Categories › a category shows *Your usual* with *Forget*.

**Scope:** phase 1 only: the pill, its Undo, and *Forget*. Home's missed-log question and the bill finder (phases 2 and 3) are out. Tracked items are dropped (D138).

**Architecture:**
- **New feature `lib/habits/`**, imported by other features only through `habits.dart`. It reads entries and categories only through `ledger.dart`. The barrel is created in Task 3 and each later task adds its own exports to it, because Task 7 (`add_entry`) already imports it.
- **Maths is pure Dart.** `HabitIndexBuilder` turns 56 days of entries into a `HabitIndex` (the Regular habits, who is logged today, the quiet states). `UsualSpendDetector` maps `(HabitIndex, now, categories)` to `Option<UsualSpend>`. `SuggestionGate` is the quiet / rest state machine. None of them import Flutter, sqflite or a clock.
- **One new table**, `suggestion_state` (migration 004), behind `SuggestionStateRepository`.
- **First frame.** `HabitsBloc` (app level, in `AppRoutes.main`) keeps the latest `HabitIndex` in its state and rebuilds it on every ledger change, resume, midnight and return from Settings. `AppRoutes.openAddTray` reads that state **synchronously**, runs the detector with `Clock.now()` and passes the result to `AddEntryBloc`'s constructor. So the pill is in the bloc's initial state, hence in the tray's first frame, or it is not shown at all (FR-AD-10 AC-1, NFR-1). The provider is `lazy: false`, so the first load starts with the main screen. A lazy `BlocProvider` builds its bloc on the first read; today that would be the Undo notice's listener, but if that wiring ever changed the first read would be the first Add tap, and that tray would have no pill.
- **Cost (NFR-1).** Opening the tray adds no I/O: one synchronous pass over at most a handful of habits. A rebuild is one `entriesBetween` over 56 days (a few hundred rows on the existing date index), `categories.all()`, `states.all()` and a pure pass of 48 slots × 3 profiles per category; it runs beside the Home and Spends reloads every ledger write already triggers, and never on the tray's open path.
- **One-tap save.** A new sealed event `AddEntryUsualPicked` with `droppable()` saves through the existing `SaveEntry`. `AddEntryFinished` carries the saved entry; the route hands it to `HabitsBloc`, whose state drives the Undo snackbar.
- **Settings.** A sheet-scoped `UsualRowBloc` shows the row and owns *Forget* and its Undo. Settings gets it through an optional builder, so no settings class imports habits internals.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_bloc + bloc_concurrency, fpdart, sqflite (+ `sqflite_common_ffi` in tests), gen-l10n, hugeicons, hand-written fakes. No new dependency.

**Spec:** SPEC [BR-10](../../SPEC.md) (Undo bullet), BR-17, BR-16, FR-AD-1, FR-AD-3, FR-AD-10, FR-SE-2 AC-6, E58–E71; UI_DESIGN §5.3 *The slot*; [habits/03](../../features/habits/03-detection-maths.md); [mockup 40](../../design/mockups/40-your-usual.html); D153, D154.

## Where this plan departs from the docs (the code and the review moved on)

- **No grouped SQL read.** habits/01 and habits/03 plan a `habit_rows_data_source` that queries `transactions` grouped by half-hour bucket. This plan reads `LedgerRepository.entriesBetween(today − 55, today)` instead, for three reasons:
  1. habits/01 line 51 itself says entries are read only through `ledger.dart`; a second data source on the ledger's table breaks that and data-domain.md ("one data source per table group").
  2. BR-17's window is widened by 15 minutes, so "inside the window" needs the entry's minute, which a half-hour bucket loses. A pill tap at 9:50 would otherwise never count as a hit.
  3. `Entry` already carries `createdAt`, `recurringId`, `kind` and `date`, validated by `EntryMapper`.
- **`suggestion_state` is keyed by category**, not by `usual:<category>:<tracked?>:<dayType>:<bucket>` (habits/03 line 64). A key holding the bucket loses the rest state whenever the window drifts by one slot, and *Forget* is per category in BR-17.
- **FSM 1 is not a class.** Only *Regular* and "missed 3 in a row" drive anything in SPEC, so they are two booleans worked out by the builder (`UsualHabit` exists only when Regular; `UsualHabit.fading`). habits/03's *Maybe*, *Fading → None after 14 days* and *Freeze* are not in SPEC and are not built. The freeze holds anyway: the index is a pure function of the entries and the date.
- **No sealed `Suggestion`** with one subtype, and no `detectors/` for helpers that are not approved. One detector, one entity (`UsualSpend`).
- **The keypad does not move** (now also UI_DESIGN §5.3 and D154; only D153's row still says 8dp lower). In the built tray the keypad is pinned to the bottom by `AdaptiveSplit` and the tray's height is fixed (`AddEntryTray._step`), so only the header changes: the amount sits 10dp higher and the chips about 8dp lower. See OQ-8 for short windows.
- **"Around 10 am" is `DateFormat.j`, as BR-17 says,** with one normalisation. `intl` 0.20.3's `en_IN` pattern for `j` is `h\u202Fa`, a narrow no-break space, which the bundled Mukta font may not carry and which a test can't type. `UsualWords` replaces U+202F with a plain space, so the text is exactly SPEC's "10 am". The sentence around it stays in ARB.

## Global Constraints

- Money is `int` paise in `Money`. The suggested amount is an amount the user logged, compared by `Money` equality. Recency weights are `double` (they are not amounts); every threshold is compared by cross-multiplication (`10 * a >= 7 * b`), never by dividing.
- "Now" and "today" come from the injected `Clock`. Domain classes take `today` or `now` as a parameter. Tests pin them with `FakeClock`.
- User-facing text lives only in `lib/l10n/app_en.arb`, followed by `flutter gen-l10n`. Banned words: "transaction", "debit/credit", "budget period", "Oops". Voice (habits/04): "your usual", "usually", "around"; never "we noticed", "learned", "smart", "AI", "suggestion".
- No marigold, red, green or new colour in this feature. Colours through `context.colors`; icons through `AppIcon`; no `Colors.*`, `Color(0x…)`, `Icons.*`.
- Bloc everywhere, sealed events, no Cubit. Blocs never reference each other.
- Nothing is logged with an amount, a category name or a note: failures log `runtimeType` only (NFR-3, BR-17).
- The Add path Add → digits → Next → tile is untouched. Nothing is reordered.
- No new dependency. No `mocktail`, no `bloc_test`, no golden tests.
- **Existing tests are the contract.** The only existing assertions this plan changes are the two schema-version ones in Task 4, and only after the owner approves (OQ-17). Every new constructor parameter on an existing class is optional, so no existing test is edited for a signature. Any other existing test going red means stop and ask.
- **Commits:** the repo is local only; never push. Commit only if the owner asks (CLAUDE.md); then one commit per task, staging only that task's files.
- **Before Task 1:** run `git rev-parse HEAD` and keep the hash as `BASE` for the coverage script.
- **Done** means `flutter analyze` is clean, `flutter test` is green, `scripts/changed_lines_coverage.sh $BASE` is ≥ 90% with every uncovered line listed with a reason, and the docs in Task 13 are updated in the same change.

## The maths, resolved (what the tests pin)

SPEC BR-17 (as amended by D154) is the source. Where it is silent this section fixes a reading and says **PLAN READING**; those are listed for the owner at the end.

| # | Quantity | Definition |
|---|---|---|
| M1 | **Learned entries** `L` | Entries with `kind == spent`, `recurringId == null`, `CalendarDate.fromDateTime(createdAt) == date`, `today − 55 ≤ date ≤ today`. **Every category counts**, hidden or forgotten too: `L` is what rules 1 and 3 and M14 mean by "a day with a learned entry in any category" |
| M1b | **A habit's entries** | The entries of `L` in one category that can have a habit: a *Spent* category in `CategoryRepository.all()` with `!hidden` (the `saved` and `card_paid` rows are never in `all()`), keeping only entries whose `createdAt` is not before that category's `forgottenAt`. Profiles, hits and amounts (M4–M7, M9, M11) use only these. **PLAN READING:** hiding or forgetting one category never changes another habit's active days or the warm-up |
| M2 | Age, weight | `age = date.daysUntil(today)` (whole days); `w = pow(0.5, age / 14)` |
| M3 | Slot, minute | `slot = hour * 2 + minute ~/ 30` and `minute = hour * 60 + minute`, from `createdAt`'s own wall-clock fields (E62) |
| M4 | Day type | `weekday` for Mon–Fri, `weekend` for Sat–Sun, from `date.weekday`. A profile is the category's learned entries of one day type, or all of them (*pooled*) |
| M5 | Smoothed profile | `U[s]` = sum of `w` in slot `s`; `P[s] = U[s−1] + 2·U[s] + U[s+1]`, indexes modulo 48 (the ¼·½·¼ kernel times 4) |
| M6 | **Window** | Peak = the slot with the largest `P`; on a tie the lowest slot index (BR-17 "the earlier one on a tie"). The run = the contiguous slots around the peak, modulo 48, with `2·P[s] > P[peak]` (strictly above half). **A run that takes in all 48 slots is a flat profile and has no window (E71).** Otherwise window = run start − 15 min to run end + 15 min, start inclusive, end exclusive, circular, never longer than 1440 minutes (a 47-slot run widens to the whole day). No profile entries → no window |
| M7 | Hits | The profile's entries whose **minute** is inside the widened window |
| M8 | Rule 1 (warm-up) | App-wide, over all of `L`: its earliest `date` is ≥ 14 days before today, and `L` has ≥ 10 distinct dates (today may be one of them) |
| M9 | Rule 2 | ≥ 5 hits (entries, unweighted) anywhere in the 56 days |
| M10 | Rule 3 | *Active days* = dates in `today − 28 … today − 1` of the profile's day type (all dates for pooled) holding ≥ 1 entry of `L`, any category. *Hit days* = active days holding a hit. Passes when active days > 0 and `5 · hitDays ≥ 3 · activeDays`. **Today is never counted** (BR-17 "the 28 days before today") |
| M11 | Rule 4 | One amount `a` with `10 · Σw(hits of a) ≥ 7 · Σw(hits)`. No tie is possible at 70% |
| M12 | Regular | Rules 1–4 all hold |
| M13 | Pooled fallback | For a day type whose own profile is not Regular: it failed only rule 2 or 3 (rule 4 with no hits counts as not failed), the pooled profile is Regular, **and that day type has ≥ 2 entries of its own inside the pooled window dated in `today − 28 … today − 1`** (BR-17, E64). Then the pooled habit is used on that day type |
| M14 | Missed 3 in a row (`fading`) | *Expected days* = the dates before today, in the 56 days, **of the day type the habit is offered on** (for a pooled habit too: BR-17 "days of that day type") holding ≥ 1 entry of `L`, newest first. `fading` when there are ≥ 3 and the newest 3 hold no hit. Days with no entry are never misses |
| M15 | Offered | Habit of today's day type, not `fading`, `window.contains(now's minute)`, its category visible in the tray's categories, no entry dated today in that category (any kind, any amount, E65), gate `open` |
| M16 | Two qualify | Higher `hitDays / activeDays` (cross-multiplied), then later `lastHit`, then lower category id (**PLAN READING** for the last step, so the pick is never arbitrary) |
| M17 | Gate | Per category. Day 0 is the day of the Undo or Forget. *Quiet today*: `quietOn == today`. *Resting*: `today` is **not after** `restUntil` (BR-17 "ending at the end of day 30": day 30 still rests, day 31 is open). Undo: `quietOn = today`; when the previous `quietOn` is 0–14 days before today (day 14 counts), also `restUntil = today + 30`. Forget: `forgottenAt = now`, `restUntil = today + 30`, `quietOn` kept |
| M18 | Stale index | The detector returns none when `index.builtOn != today` |
| M19 | "Around {time}" | The hour nearest the window's middle minute; a middle on the half hour rounds up (**PLAN READING**). Formatted by `DateFormat.j(locale)` with U+202F replaced by a space: "10 am", "12 pm", "12 am" |

## Review Focus

1. **A weekday habit must not leak into weekends** through the pooled profile (review finding B1). → Task 2, test "a strong weekday habit with no weekend hits is silent on Saturday".
2. **Today must not lower the day share before the window opens.** → Task 2, test "another entry today does not change the share".
3. **A pill tap at the widened edge counts as a hit.** → Task 2, test "an entry 10 minutes before the first slot is a hit".
4. **The pill is in the first frame and never arrives late.** → Task 9, test "the pill is there after one pump"; Task 7, "no event adds a usual".
5. **Undo writes the quiet state before it deletes**, so the reload the delete triggers already sees it. → Task 5, test "the quiet state is stored before the entry is deleted".
6. **A stale index never suggests** (app left open across midnight). → Task 3, test "an index built yesterday suggests nothing".
7. **The 48dp slot never changes height** when the pill comes or goes. → Task 9, tests on the chips' top edge before and after the first key.
8. **`suggestion_state` travels with a backup and is wiped by Delete everything.** → Task 4.

---

## File map

| File | Responsibility | Task |
|---|---|---|
| `lib/habits/domain/habit_rules.dart` (new) | Every threshold as a named constant | 1 |
| `lib/habits/domain/entities/{day_type,time_window}.dart` (new) | `DayType`, `TimeWindow` | 1 |
| `lib/habits/domain/time_profile.dart`, `usual_amount.dart` (new) | Slots, weights, window; the ≥ 70% amount | 1 |
| `lib/habits/domain/entities/{usual_habit,habit_index,habit_inputs,suggestion_state}.dart` (new) | Value objects | 2 |
| `lib/habits/domain/habit_index_builder.dart` (new) | Entries → `HabitIndex` | 2 |
| `lib/habits/domain/suggestion_gate.dart` (new) | FSM 2 | 3 |
| `lib/habits/domain/entities/usual_spend.dart`, `lib/habits/domain/detectors/usual_spend_detector.dart` (new) | The suggestion | 3 |
| `lib/core/db/migrations/migration_004_suggestion_state.dart` (new), `migrations.dart`, `db_schema.dart` | Schema v4 | 4 |
| `lib/habits/data/**` (new) | Data source, model, mapper, repository | 4 |
| `lib/habits/domain/repository/suggestion_state_repository.dart`, `lib/habits/domain/usecase/*.dart`, `entities/{usual_add,forgotten_usual}.dart` (new) | Contract and use cases | 5 |
| `lib/habits/presentation/bloc/habits_{bloc,event,state}.dart` (new) | The cached index; the add's Undo | 6 |
| `lib/add_entry/presentation/bloc/add_entry_{bloc,event,state}.dart` | `usual`, `AddEntryUsualPicked`, `AddEntryFinished.added` | 7 |
| `lib/add_entry/presentation/widgets/usual_pill.dart`, `usual_slot.dart` (new), `amount_step.dart` | Pill, slot, layout B | 8, 9 |
| `lib/habits/presentation/widgets/usual_added_notice.dart` (new), `lib/app/main_screen.dart` | "Added ₹20 to Chai · Undo" | 10 |
| `lib/habits/presentation/bloc/usual_row_*.dart`, `widgets/your_usual_row.dart`, `usual_words.dart` (new); `lib/settings/presentation/{pages/categories_page.dart,widgets/category_sheet.dart,widgets/category_sheet_summary.dart}` | *Your usual* row and *Forget* | 11 |
| `lib/l10n/app_en.arb` | Strings (added in the task that first needs them; listed in Task 8) | 8, 10, 11 |
| `lib/habits/di/habits_module.dart`, `lib/habits/habits.dart` (new), `lib/app/app_services.dart`, `lib/app/routes.dart` | DI and wiring | 12 |
| `test/helpers/fakes/fake_suggestion_state_repository.dart`, `test/helpers/fixtures/habits/chai_habit.dart` (new), `test/helpers/fake_services.dart`, `test/helpers/fakes/fake_ledger_repository.dart` (`nextAddGate`) | Test support | 2, 5, 7, 12 |

`test/` mirrors `lib/`: each new source file gets `test/<same path>_test.dart`.

---

### Task 1: Time profile, window and the usual amount (pure Dart)

**Files**
- Create: `lib/habits/domain/habit_rules.dart`, `lib/habits/domain/entities/day_type.dart`, `lib/habits/domain/entities/time_window.dart`, `lib/habits/domain/time_profile.dart`, `lib/habits/domain/usual_amount.dart`
- Test: `test/habits/domain/entities/day_type_test.dart`, `test/habits/domain/entities/time_window_test.dart`, `test/habits/domain/time_profile_test.dart`, `test/habits/domain/usual_amount_test.dart`

**Interfaces**
- `abstract final class HabitRules`: `horizonDays = 56`, `shareDays = 28`, `halfLifeDays = 14`, `slotsPerDay = 48`, `slotMinutes = 30`, `widenMinutes = 15`, `minutesPerDay = 1440`, `warmUpDays = 14`, `minActiveDays = 10`, `minHits = 5`, `dayShareNum = 3`, `dayShareDen = 5`, `amountShareNum = 7`, `amountShareDen = 10`, `missedRun = 3`, `pooledMinOwnHits = 2`, `undoWindowDays = 14`, `restDays = 30`.
- `enum DayType { weekday, weekend; static DayType of(CalendarDate date) }`.
- `final class TimeWindow extends Equatable { const TimeWindow({required int startMinute, required int lengthMinutes}); bool contains(int minuteOfDay); int get middleMinute; int get aroundHour; }` (`aroundHour` is 0–23, M19).
- `abstract final class TimeProfile { static int slotOf(DateTime at); static int minuteOf(DateTime at); static double weightOf(int ageDays); static Option<TimeWindow> windowOf(List<double> slotWeights); }` (`slotWeights` has 48 unsmoothed sums, M5–M6).
- `abstract final class UsualAmount { static Option<Money> pick(List<({Money amount, double weight})> hits); }` (M11).

- [ ] **Step 1: Write the failing tests**

| File | Test | Asserts |
|---|---|---|
| `day_type_test` | `'Monday to Friday are weekdays, Saturday and Sunday the weekend'` (table over 26 Oct – 1 Nov 2026) | BR-17 "A habit" |
| `time_window_test` | `'contains its start and not its end'` | 9:45–10:45: 585 in, 644 in, 645 out, 584 out |
| | `'a window across midnight holds both sides (E58)'` | start 1395 (23:15), length 90: 1400 in, 0 in, 44 in, 45 out, 1394 out |
| | `'a whole-day window holds every minute'` | length 1440 (what a 47-slot run widens to) |
| | `'aroundHour is the hour nearest the middle; a half hour rounds up'` | 9:45–10:45 → 10; 9:45–11:15 → 11; 23:15–00:45 → 0; 11:15–12:15 → 12 |
| `time_profile_test` | `'slotOf and minuteOf read the wall clock'` | 10:05 → 20 and 605; 23:59 → 47; 00:00 → 0; a UTC and a local `DateTime` with the same fields agree (E62) |
| | `'weightOf halves every 14 days'` | 0 → 1.0, 14 → 0.5, 28 → 0.25 exactly; 7 → `closeTo(0.7071, 1e-4)` |
| | `'one busy slot gives a 60-minute window'` | weight only in slot 20 → 9:45–10:45 (the mockup's chai window) |
| | `'two busy neighbours give a 90-minute window'` | slots 20 and 21 equal → 9:45–11:15 |
| | `'the run stops at a slot at exactly half the peak'` | the single-slot case again, asserting slot 19 and 21 are out (strict `>`, M6) |
| | `'a run across midnight wraps'` | slots 47 and 0 → start 1395, length 90 |
| | `'two separate peaks: the window is the higher one's run'` | slot 20 = 4.0, slot 32 = 3.0 → 9:45–10:45 |
| | `'two equal peaks: the earlier slot wins'` (BR-17, E71) | slot 20 = slot 32 → 9:45–10:45 |
| | `'an even spread has no window'` (E71) | all 48 equal → `none()` |
| | `'a run of 47 slots is the whole day, never more'` | 47 equal slots and one empty → length 1440 |
| | `'no weight, no window'` | 48 zeros → `none()` |
| `usual_amount_test` | `'7 of 10 equal weights is the usual amount'` | weight 1.0 each → `some(₹20)` |
| | `'69 of 100 is not'` | `none()` |
| | `'recent entries weigh more'` | ₹20 ×2 at weight 1.0, ₹30 ×3 at weight 0.25 → `some(₹20)` |
| | `'a 50/50 split has no usual amount'`, `'no hits, none'`, `'one hit is its own amount'` | |
| | `'the amount at the 9-digit cap is returned unchanged'` | ₹99,99,99,999 → the same `Money` (BR-17 "never rounded") |

- [ ] **Step 2: Run and see them fail** — `flutter test test/habits/domain`. Expected: compile errors (nothing exists).
- [ ] **Step 3: Implement** the five files. `windowOf` builds `P`, finds the peak, walks left and right while `2 * P[s] > P[peak]`; a run that reaches all 48 slots returns `none()` (E71); the widened length is capped at 1440. Dartdoc every public member (code-docs.md); a `// why:` on the strict comparison and on the tie-break.
- [ ] **Step 4: Verify** — `flutter test test/habits/domain` green; `flutter analyze lib/habits test/habits` clean.

---

### Task 2: `HabitIndexBuilder` (pure Dart)

**Files**
- Create: `lib/habits/domain/entities/usual_habit.dart`, `habit_index.dart`, `habit_inputs.dart`, `suggestion_state.dart`, `lib/habits/domain/habit_index_builder.dart`
- Create (test support): `test/helpers/fixtures/habits/chai_habit.dart`
- Test: `test/habits/domain/habit_index_builder_test.dart`, `test/habits/domain/entities/habit_index_test.dart`

**Interfaces**
- `final class SuggestionState extends Equatable { const SuggestionState({required int categoryId, Option<CalendarDate> quietOn, Option<CalendarDate> restUntil, Option<DateTime> forgottenAt}); }` (all three default to none).
- `final class UsualHabit extends Equatable { const UsualHabit({required int categoryId, required DayType dayType, required bool pooled, required TimeWindow window, required Money amount, required int hitDays, required int activeDays, required DateTime lastHit, required bool fading}); }`. `dayType` is the day type it is offered on; `pooled` says it was learned from all days.
- `final class HabitIndex extends Equatable { const HabitIndex({required CalendarDate builtOn, required List<UsualHabit> habits, required Set<int> loggedToday, required Map<int, SuggestionState> states}); factory HabitIndex.empty(CalendarDate today); Option<UsualHabit> habitFor(int categoryId, {required DayType preferring}); }` (`habitFor` returns the habit of `preferring`, else the other; FR-SE-2 AC-6 "with both, today's day type").
- `final class HabitInputs extends Equatable { const HabitInputs({required List<Entry> entries, required List<Category> categories, required Map<int, SuggestionState> states}); }`.
- `abstract final class HabitIndexBuilder { static HabitIndex build(HabitInputs inputs, {required CalendarDate today}); }`. Private helpers, each ≤ ~20 lines: `_learned`, `_warmedUp`, `_profile`, `_evaluate`, `_withFallback`, `_fading`.
- Fixture `chai_habit.dart`: `const Category chai = Category(id: 13, key: 'own_13', iconKey: 'chai', kind: EntryKind.spent, sort: 8, customName: 'Chai');` (`'chai'` is in `AppIcons.byKey`) and `List<Entry> chaiWeekdays({required CalendarDate today, int misses = 2, int otherAmounts = 1})`: the mockup's worked example for `today = 26 Oct 2026`: one Food entry on each of 26 dates from 25 Sep, **among them all 20 weekdays of 28 Sep – 25 Oct** (so the two chai misses are still active days and the share is 18 of 20), one ₹20 Chai entry at 10:05 on 18 of those 20 weekdays (one of them ₹30), `createdAt` on the entry's own date. Helpers `entryAt(int id, Category category, int rupees, DateTime createdAt, {CalendarDate? date, int? recurringId, EntryKind kind = EntryKind.spent})`.

- [ ] **Step 1: Write the failing tests** (`today = WorkedExample.today`, Mon 26 Oct 2026, unless stated)

| Group | Test | Cites |
|---|---|---|
| Learns from | `'the worked example makes one weekday habit: Chai ₹20, 9:45–10:45, 18 of 20'` | BR-17, mockup 40 |
| | `'an entry posted by a rule is ignored'` (`recurringId` set) | BR-17 learns from |
| | `'a back-dated entry is ignored'` (`createdAt` 26 Oct, `date` 25 Oct) | BR-17, E60 |
| | `'Got and Saved entries are ignored'` | BR-17 |
| | `'an entry 56 days old is ignored and one 55 days old counts'` | BR-17 "today − 55 … today" |
| | `'an entry dated after today is ignored'` (clock set back) | E66 |
| | `'an edit to another category counts in the new category'` (stored `categoryId`) | E60 |
| | `'an edit to another amount counts with the new amount'` | E60 |
| | `'a hidden category has no habit; shown again, it has'` | BR-17, E59 |
| | `'a hidden category's entries still make their days active for other habits'` (hiding Food leaves Chai at 18 of 20) | M1 / M1b |
| | `'a hidden category keeps its quiet state when it is shown again'` (`states` passed through to the index unchanged) | E69 |
| | `'the saved and card_paid rows have none'` (category ids 11, 12 absent from `categories`) | BR-17 |
| | `'entries before Forget are ignored; later ones count'` | BR-17 quiet |
| | `'forgotten entries still make their days active for other habits, and the warm-up holds'` | M1 / M1b |
| | `'an empty ledger is an empty index'` | E67 |
| Rule 1 | `'13 days after the first entry: nothing'`, `'14 days with 10 active days: a habit'`, `'14 days with 9 active days: nothing'` | BR-17 rule 1, E67 |
| | `'the warm-up is app-wide: a category first used 13 days ago can be Regular'` (Food on 25 Sep – 4 Oct only, so 5 active weekdays in the 28; Chai at 10:05 on the 9 weekdays of 13–23 Oct: 9 of 14 active weekdays, 9 hits) | BR-17 rule 1, D154 |
| Rule 2 | `'4 entries in the window: nothing'`, `'5: a habit'` | rule 2 |
| | `'an entry 10 minutes before the first slot is a hit'` (9:50) | M7, Review Focus 3 |
| Rule 3 | `'12 of 20 active weekdays: a habit'`, `'11 of 20: nothing'` | rule 3 |
| | `'a day with no entry at all is not in the share'` | rule 3 "that have any entry" |
| | `'another entry today does not change the share'` | M10, Review Focus 2 |
| | `'two hits on one day are one hit day'` | habits/03 "days, not entries" |
| Rule 4 | `'the suggested amount is the one logged, to the paise'` | BR-17 suggestion |
| | `'two amounts at 60/40: nothing'` | rule 4 |
| Day types | `'weekdays and weekends are learned apart'` (chai 10:05 weekdays, 16:00 weekends → two habits, two windows) | BR-17 habit |
| | `'weekdays Regular, weekends with 3 entries, 2 of them in the pooled window: weekends use the pooled habit'` (`pooled: true`, `dayType: weekend`) | E64 |
| | `'with 1 weekend entry in the pooled window: nothing on weekends'` | E64, M13 boundary |
| | `'2 weekend entries in the pooled window but older than 28 days: nothing on weekends'` | BR-17 "in the 28 days before today" |
| | `'a strong weekday habit with no weekend hits is silent on Saturday'` | M13, Review Focus 1 |
| | `'a weekend that fails rule 4 gets no pooled habit'` | BR-17 "fails only rule 2 or 3" |
| | `'pooled passes only when it passes all four'` | BR-17 |
| Missed | `'missed on the last 3 active weekdays: fading'`, `'missed on 2: not fading'`, `'a hit after 3 misses: not fading'` | BR-17 missed 3 |
| | `'days with no entry are not misses'` | BR-17, M14 |
| | `'a pooled habit on weekends fades on 3 missed weekend days, whatever the weekdays did'` | BR-17 "days of that day type", M14 |
| Dates | `'a window across midnight'` (entries 23:40–00:20 on weekdays → start 1395, length 90) | E58 |
| | `'a horizon across 29 February 2028'` (`today` 10 Mar 2028) and `'across New Year'` (`today` 10 Jan 2027): ages, day types and the 18-of-20 share come out the same as the October fixture shifted | E70 |
| Index | `'loggedToday holds every category with an entry dated today, typed or posted'` | E65 |
| | `'habitFor prefers today's day type, then the other, then none'` | FR-SE-2 AC-6 |

- [ ] **Step 2: Run and see them fail** — `flutter test test/habits/domain/habit_index_builder_test.dart`.
- [ ] **Step 3: Implement** per M1–M14. Use `map` / `where` / `fold`; no in-place mutation. `// why:` on M1b (active days come from every category), on M10's exclusion of today and on M13's own-hits bar.
- [ ] **Step 4: Verify** — `flutter test test/habits`; analyze clean.

---

### Task 3: `SuggestionGate` and `UsualSpendDetector` (pure Dart)

**Files**
- Create: `lib/habits/domain/suggestion_gate.dart`, `lib/habits/domain/entities/usual_spend.dart`, `lib/habits/domain/detectors/usual_spend_detector.dart`, **`lib/habits/habits.dart`** (the barrel, with a `library;` doc comment as `ledger.dart` has; for now it exports the Task 1–3 entities and `usual_spend_detector.dart`. Tasks 5, 6, 10, 11 and 12 each add their own public files to it)
- Test: `test/habits/domain/suggestion_gate_test.dart`, `test/habits/domain/detectors/usual_spend_detector_test.dart`

**Interfaces**
- `enum GateStatus { open, quietToday, resting }`
- `abstract final class SuggestionGate { static GateStatus statusOf(Option<SuggestionState> state, {required CalendarDate today}); static SuggestionState afterUndo(Option<SuggestionState> state, {required int categoryId, required CalendarDate today}); static SuggestionState afterForget(Option<SuggestionState> state, {required int categoryId, required DateTime now}); }`
- `final class UsualSpend extends Equatable { const UsualSpend({required Category category, required Money amount}); }`
- `abstract final class UsualSpendDetector { static Option<UsualSpend> suggest(HabitIndex index, {required DateTime now, required List<Category> categories}); }`

- [ ] **Step 1: Write the failing tests**

| File | Test | Cites |
|---|---|---|
| gate | `'no state is open'` | |
| | `'after an Undo: quiet today, open tomorrow'` | BR-17 quiet, E63 |
| | `'a second Undo 14 days later rests for 30 days'`, `'15 days later only quiets'`, `'a second Undo on the same day rests too'` | BR-17 "counting day 14", E63 |
| | `'resting on day 30, open on day 31'` (day 0 is the Undo) | BR-17 "ending at the end of day 30" |
| | `'Forget rests through day 30 and is open on day 31'` | BR-17 Forget |
| | `'an Undo after a rest ended counts as a first'` | M17 |
| | `'Forget sets forgottenAt to now and rests 30 days, keeping quietOn'` | BR-17 Forget |
| | `'a rest across New Year and across 29 February'` | date edge cases |
| detector | `'inside the window on a weekday: Chai ₹20'` (10:05) | BR-17 suggestion |
| | `'at the window's first minute: yes; at its end minute: no'` (9:45, 10:45) | M6 |
| | `'outside the window: none'` (15:30), `'on Saturday: none'` | mockup 40 |
| | `'the category already has an entry today: none'` | E65 |
| | `'a fading habit: none'` | BR-17 missed 3 |
| | `'quiet today: none'`, `'resting: none'` | E63 |
| | `'quiet for Chai still offers another category's habit in the same window'` | BR-17 "kept per category" |
| | `'the category is hidden in the tray's list: none'`, `'the category is missing: none'` | E59 |
| | `'an index built yesterday suggests nothing'` | M18, Review Focus 6 |
| | `'both sides of midnight'` (23:20 with Monday's index; 00:10 with Tuesday's) | E58 |
| | `'two qualify: the higher share of days wins'`, `'equal share: the more recent hit'`, `'still equal: the lower category id'` | E61 |
| | `'the label follows a rename'` (the returned `category.customName`) | new edge case |
| | `'an empty index: none'` | |

- [ ] **Step 2: Run and see them fail.** — `flutter test test/habits/domain`
- [ ] **Step 3: Implement.** The detector is one filter chain and one sort; no `DateTime.now()`.
- [ ] **Step 4: Verify** — `flutter test test/habits/domain`; analyze clean.

---

### Task 4: Migration 004 and the `suggestion_state` data layer

**Files**
- Create: `lib/core/db/migrations/migration_004_suggestion_state.dart`, `lib/habits/data/datasource/suggestion_state_local_data_source.dart`, `lib/habits/data/model/suggestion_state_model.dart`, `lib/habits/data/mapper/suggestion_state_mapper.dart`
- Modify: `lib/core/db/migrations/migrations.dart` (append `migration004SuggestionState`), `lib/core/db/db_schema.dart` (`Tables.suggestionState = 'suggestion_state'`; `SuggestionStateColumns { categoryId = 'category_id', quietOn = 'quiet_on', restUntil = 'rest_until', forgottenAt = 'forgotten_at' }`)
- Test: `test/core/db/app_database_test.dart` (new group `'Schema v4 (D153)'`), `test/habits/data/datasource/suggestion_state_local_data_source_test.dart`, `test/habits/data/model/suggestion_state_model_test.dart`, `test/habits/data/mapper/suggestion_state_mapper_test.dart`, `test/backup/data/datasource/backup_local_data_source_test.dart` (new cases), `test/backup/data/repository/backup_repository_impl_test.dart` (new case)

**Interfaces**
- Schema (BR-17 "kept per category in a `suggestion_state` table"):
  ```sql
  CREATE TABLE suggestion_state (
    category_id INTEGER PRIMARY KEY REFERENCES categories(id) ON DELETE CASCADE,
    quiet_on TEXT, rest_until TEXT, forgotten_at TEXT
  )
  ```
  Dates are `YYYY-MM-DD`; `forgotten_at` is `DateTime.toIso8601String()` of the local `Clock.now()`, the same form as `transactions.created_at`.
  - Categories are never deleted in the app (hiding is an `UPDATE` of `archived`, and no category write uses `ConflictAlgorithm.replace`), so the cascade fires only when a restore or *Delete everything* empties `categories`. Keep it that way: an `INSERT OR REPLACE` on `categories` would silently drop the row (E69).
  - The backup needs no code change: `SqfliteBackupLocalDataSource` reads the table names from `sqlite_master`, `BackupJsonMapper` only requires the four v1 tables, and a v3 file is migrated in the scratch database.
- `abstract interface class SuggestionStateLocalDataSource { Future<List<SuggestionStateModel>> all(); Future<SuggestionStateModel?> byCategory(int categoryId); Future<void> upsert(SuggestionStateModel model); Future<int> delete(int categoryId); }` and `final class SqfliteSuggestionStateLocalDataSource` over `AppDatabase` (`ConflictAlgorithm.replace` for `upsert`).
- `final class SuggestionStateModel extends Equatable { …; static Either<Failure, SuggestionStateModel> fromRow(Map<String, Object?> row); Map<String, Object?> toRow(); }` using `readRow`, `intAt`, `stringOrNullAt` (`lib/core/db/db_row.dart`).
- `abstract final class SuggestionStateMapper { static Either<Failure, SuggestionState> toEntity(SuggestionStateModel model); static SuggestionStateModel toModel(SuggestionState state); }` (`CalendarDate.parse`; `DateTime.tryParse` → `InvalidDataFailure('Bad forgotten_at …')`).

- [ ] **Step 1: Write the failing tests**

| File | Test | Asserts |
|---|---|---|
| `app_database_test` | `'a new database has an empty suggestion_state'` | table exists, 0 rows |
| | `'upgrading a v3 database keeps every row and adds suggestion_state'` | v3 file built with `runMigrations(db, from: 0, to: 3)` plus one rule and two entries; after `AppDatabase.open`: `user_version` 4, the rows unchanged (ids, `recurring_id`, `created_at`), table empty, `PRAGMA foreign_key_check` empty |
| | `'suggestion_state holds one row per category and goes with its category'` | a second insert for the same id throws; deleting the category removes the row |
| | `'a failed upgrade leaves the v3 database as it was'` | v3 file with a stray table named `suggestion_state`; `open` is `Left(DatabaseFailure)`; reopened raw at version 3 the rows are unchanged |
| data source | `'upsert then all returns the row'`, `'upsert replaces'`, `'byCategory of an unknown id is null'`, `'delete removes it and returns 1'`, `'an unreadable row throws RowFailureException'` (insert `quiet_on` as a BLOB, `X'00'`, by raw SQL: a TEXT column turns an int into text, so an int would read back as a string), `'hiding a category and bringing it back keeps its row'` (through `SqfliteCategoriesLocalDataSource.setArchived`, E69) | real SQLite through `openTestDatabase()`; rows use a seeded category id (1–10), since the foreign key is on |
| model | `'round-trips a full row'`, `'null columns are none'`, `'a missing or wrong-typed category_id is InvalidDataFailure'` | |
| mapper | `'round-trips every field'`, `'a bad date is InvalidDataFailure'`, `'a bad forgotten_at is InvalidDataFailure'`, `'forgotten_at keeps its wall-clock fields'` (E62) | |
| backup data source | `'dump carries suggestion_state'`, `'a v3 backup upgrades to an empty suggestion_state'`, `'fresh has no suggestion_state rows'`, `'replace puts suggestion_state rows back, whichever table comes first in the file'` | BR-16, BR-17, NFR-5 |
| backup repository | `'Delete everything empties suggestion_state'`, `'a backup made with a quiet state restores it'` (make, change, restore, read) | BR-16, BR-17 |

**Existing assertions that change (D153) — get the owner's yes first (OQ-17):**
- `test/core/db/app_database_test.dart:64`, `'is at the latest schema version'`: `expect(AppDatabase.schemaVersion, 3)` becomes `4`.
- `test/core/db/app_database_test.dart:215`, `'upgrading a v1 database keeps ids, links and indexes'`: `PRAGMA user_version` `3` becomes `4`.

Both pin the version number, and there is precedent: commit `7bdb0af` (schema v3, D120) changed the same first line from `2` to `3`. A schema bump cannot leave them green, so this is unavoidable; it still needs the owner's yes. Nothing else in either test changes.

Checked and unaffected by v4 (do not edit): `test/backup/data/repository/backup_repository_impl_test.dart:238` passes its `schemaVersion: 3` file straight to `restore`, which never upgrades, so it still fails on the unknown `mystery` table inside `replace`; `test/backup/data/mapper/backup_json_mapper_test.dart` uses its own `const int current = 3`; `test/helpers/fakes/fake_backup_repository.dart` is a fake. If any goes red, stop and ask.

- [ ] **Step 2: Run and see them fail** — `flutter test test/core/db test/habits/data test/backup`. Expected: `user_version` 3 ≠ 4, missing table.
- [ ] **Step 3: Implement.** The migration is one `db.execute`. Never edit migrations 001–003.
- [ ] **Step 4: Verify** — the same command green; `flutter test test/backup` fully green.

---

### Task 5: Repository and use cases

**Files**
- Create: `lib/habits/domain/repository/suggestion_state_repository.dart`, `lib/habits/data/repository/suggestion_state_repository_impl.dart`, `lib/habits/domain/entities/usual_add.dart`, `lib/habits/domain/entities/forgotten_usual.dart`, `lib/habits/domain/usecase/get_habit_index.dart`, `undo_usual_add.dart`, `forget_usual.dart`, `restore_usual.dart`
- Create (test support): `test/helpers/fakes/fake_suggestion_state_repository.dart` (`implements SuggestionStateRepository`; in-memory map; `Failure? failure`; `final List<String> calls`; `Completer<void>? nextReadGate` on `all()`, as `FakeLedgerRepository.nextReadGate`. Only habits code reads this repository, so gating it holds back a habits load without touching Home's or Spends' reads of the ledger)
- Modify: `lib/habits/habits.dart` (export the repository contract, the two entities and the four use cases)
- Test: `test/habits/data/repository/suggestion_state_repository_impl_test.dart`, `test/habits/domain/usecase/{get_habit_index,undo_usual_add,forget_usual,restore_usual}_test.dart`

**Interfaces**
- `abstract interface class SuggestionStateRepository { TaskEither<Failure, Map<int, SuggestionState>> all(); TaskEither<Failure, Option<SuggestionState>> of(int categoryId); TaskEither<Failure, Unit> put(SuggestionState state); TaskEither<Failure, Unit> remove(int categoryId); }`. The impl wraps the data source in `dbTask` and maps with `SuggestionStateMapper`.
- `final class UsualAdd extends Equatable { const UsualAdd({required Entry entry, required Category category}); }`
- `final class ForgottenUsual extends Equatable { const ForgottenUsual({required int categoryId, required Option<SuggestionState> previous}); }`
- `final class GetHabitIndex implements UseCase<HabitIndex, NoParams>` — `{required LedgerRepository ledger, required CategoryRepository categories, required SuggestionStateRepository states, required Clock clock}`. Reads `ledger.entriesBetween(today.addDays(-(HabitRules.horizonDays - 1)), today)`, `categories.all()`, `states.all()`, then `HabitIndexBuilder.build`.
- `final class UndoUsualAdd implements UseCase<Unit, Entry>` — `{states, ledger, clock}`. `states.of(id)` → `states.put(SuggestionGate.afterUndo(…))` → `ledger.delete(entry.id)`.
- `final class ForgetUsual implements UseCase<ForgottenUsual, int>` — `{states, clock}`. Returns the state it replaced.
- `final class RestoreUsual implements UseCase<Unit, ForgottenUsual>` — `{states}`. `previous` some → `put`; none → `remove`.

- [ ] **Step 1: Write the failing tests**

| File | Test |
|---|---|
| repository impl (real SQLite) | `'put then of returns it'`, `'of an unknown category is none'`, `'all is keyed by category'`, `'remove deletes'`, `'a thrown read is DatabaseFailure'`, `'an unreadable row is InvalidDataFailure'` |
| `get_habit_index` | `'builds the worked example's index for today'`; `'asks the ledger for exactly today − 55 … today'`; `'a ledger, category or state failure is returned'` (three cases); `'an empty ledger gives an empty index'` |
| `undo_usual_add` | `'deletes the entry and quiets its category today'` (BR-10, E63); `'a second Undo within 14 days rests it 30 days'`; `'the quiet state is stored before the entry is deleted'` (Review Focus 5: a ledger `changes` listener reads the fake repository and sees `quietOn`); `'an entry already gone: EntryNotFoundFailure, and the category is still quiet'`; `'a state failure deletes nothing'` |
| `forget_usual` | `'stores forgottenAt = now and a 30-day rest, and returns none as the previous state'`; `'returns the state it replaced'`; `'a failure is returned'` |
| `restore_usual` | `'puts the previous state back'`; `'with no previous state the row is removed'` |

- [ ] **Step 2: Run and see them fail** — `flutter test test/habits`.
- [ ] **Step 3: Implement.** Chain with `flatMap` / `map`; no `.run()` outside tests; no `try/catch`.
- [ ] **Step 4: Verify** — `flutter test test/habits`; analyze clean.

---

### Task 6: `HabitsBloc`

**Files**
- Create: `lib/habits/presentation/bloc/habits_bloc.dart`, `habits_event.dart`, `habits_state.dart`
- Test: `test/habits/presentation/bloc/habits_bloc_test.dart`, `habits_state_test.dart`

**Interfaces**
- Events (sealed `HabitsEvent extends Equatable`): `HabitsLoadRequested()`; `HabitsUsualAdded(UsualAdd added)`; `HabitsUsualUndoRequested(UsualAdd added)`.
- States (sealed `HabitsState extends Equatable`): `HabitsLoading()`; `HabitsReady(HabitIndex index, {Option<UsualAdd> added = none})`.
- `class HabitsBloc extends Bloc<HabitsEvent, HabitsState>` — `{required GetHabitIndex getIndex, required UndoUsualAdd undoAdd, required LedgerRepository ledger}` (no `Clock`: the use cases own "today").
  - `on<HabitsLoadRequested>(…, transformer: restartable())` — `// why:` the newest read wins.
  - `on<HabitsUsualUndoRequested>(…, transformer: droppable())` — `// why:` a second Undo must not delete or quiet twice.
  - `_changes = ledger.changes.listen((_) => add(const HabitsLoadRequested()))`, cancelled in `close()`.
  - A failed load logs `habits.load_failed` with the type only and keeps the current state.
  - `HabitsUsualAdded` emits `HabitsReady(<current index>, added: some)` and does nothing while `HabitsLoading` (a pill exists only when the state is `HabitsReady`, so there is nothing to offer an Undo for); every other emit has `added` none.
- Modify: `lib/habits/habits.dart` (export the bloc, its events and states).
  - The Undo handler awaits `undoAdd`, logs a failure's type, then calls the shared `_load(emit)`.

- [ ] **Step 1: Write the failing tests** (`bloc.dispatch`, fakes; `expectLater` before acting)

| Test | Cites |
|---|---|
| `'starts loading'` | |
| `'a load emits the index'` | |
| `'a failed first load stays loading'`; `'a failed reload keeps the last index'` | |
| `'a ledger change reloads'` | BR-10 "notifies listeners" |
| `'a slower, older load never lands last'` (`ledger.nextReadGate`) | bloc.md restartable |
| `'a usual add is offered once, then cleared by the next emit'` | BR-10 Undo |
| `'a usual add while loading emits nothing'` | |
| `'Undo deletes the entry, quiets the category and reloads'` | BR-10, E63 |
| `'a second Undo while the first is in flight is dropped'` (`ledger.nextDeleteGate`; the fake states repository records one `put`) | bloc.md droppable |
| `'closing mid-load and mid-undo does not throw'` | |
| `'events and states compare by their fields'` | |

`AppLogger` writes straight to `dart:developer` and has no test seam (`lib/core/logging/app_logger.dart`), so what a failed load logs is not asserted here; NFR-3 is checked by the grep in Task 13 and by review. Do not add a seam for it.

- [ ] **Step 2: Run and see them fail.** — `flutter test test/habits/presentation/bloc`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Verify** — green; analyze clean.

---

### Task 7: `AddEntryBloc`: the usual, the one-tap save

**Files**
- Modify: `lib/add_entry/presentation/bloc/add_entry_bloc.dart`, `add_entry_event.dart`, `add_entry_state.dart`
- Modify (test support, additive): `test/helpers/fakes/fake_ledger_repository.dart` — `Completer<void>? nextAddGate`, used by `add` exactly as `nextDeleteGate` is by `delete`
- Test: `test/add_entry/presentation/bloc/add_entry_bloc_test.dart` (new group `'AddEntryBloc your usual (FR-AD-10, D153)'`), `add_entry_state_test.dart` (new cases)

**Interfaces**
- `AddEntryBloc({…, Option<UsualSpend> usual = const Option<UsualSpend>.none()})`. Optional, so every existing construction compiles unchanged. Import `'../../../habits/habits.dart'` (the barrel exists since Task 3; never a file inside `lib/habits/`).
- `EntryForm.usual: Option<UsualSpend>` (default none; in `props`; `copyWith({Option<UsualSpend>? usual})`).
- `_initialForm` keeps `usual` only when `editing.isNone() && startKind == EntryKind.spent` (AC-1; ₹0 and today hold by construction).
- `final class AddEntryUsualPicked extends AddEntryEvent { const AddEntryUsualPicked(); }` — "The user tapped the *your usual* pill; the tap is the save (FR-AD-10 AC-4)". Registered `on<AddEntryUsualPicked>(_onUsualPicked, transformer: droppable())`, sharing the existing `// why:` on saves.
- `_onUsualPicked`: returns unless `state is AddEntryEditing` and `form.usual` is some; emits `AddEntrySaving(form, categoryId: usual.category.id)`; saves `SaveEntryParams(EntryDraft(amount: usual.amount, kind: EntryKind.spent, categoryId: usual.category.id, date: form.today))` through `_saveEntry` (no `replacing`, no note); a failure → reject haptic, `AddEntryEditing(form, failed: true)` (the form still holds `usual`); success → success haptic, `AddEntryFinished(form, categoryId: …, added: Option.of(entry))`.
- `AddEntryFinished(super.form, {this.categoryId, this.added = const Option<Entry>.none()})`, `added` in `props`.
- `_editAmount` (both branches) and `_onKindChanged` clear `usual` (AC-3). Do this inside the `change` passed to `_update`, and in the rejection branch's `AddEntryEditing`.

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| `'a new Spent tray opens with the usual it was given'` | AC-1 |
| `'edit mode drops it'`, `'a tray opened on Got drops it'` | AC-1 |
| `'no event adds a usual'` (built with none; after every keypad, chip, kind and back event the form's `usual` is still none) | AC-1 "never appears late" |
| One test each: `'a digit hides it'`, `'a quick chip hides it'`, `'⌫ hides it'`, `'a long-press clear hides it'`, `'switching to Got hides it'`, `'a leading zero hides it though the amount stays ₹0'` | AC-3 |
| `'switching back to Spent does not bring it back'`, `'clearing the amount to ₹0 does not bring it back'` | AC-3 |
| `'a pill tap saves that amount in that category, today, with no note'` (`ledger.saved.single` equals the draft) | AC-4, BR-17 |
| `'it emits Saving with the category, then Finished carrying the saved entry, with the success haptic'` | AC-4, FR-AD-5 |
| `'the saved amount is the suggestion's, to the paise, at the 9-digit cap too'` | BR-17, BR-10 |
| `'a second tap while the first save is gated writes once'` (`ledger.nextAddGate`) | AC-4, bloc.md |
| `'a failed save keeps the tray open, says so and keeps the pill'` (`failed: true`, `form.usual` some, reject haptic) | AC-4 |
| `'a pill tap with no usual does nothing'`; `'a pill tap while saving does nothing'` | |
| `'a normal tile save finishes with no added entry'` | BR-10 "Save has no Undo" |
| `'closing mid-save does not throw'` | |
| state test: `'EntryForm and AddEntryFinished compare by usual and added'`; `'AddEntryUsualPicked compares equal'` | |

- [ ] **Step 2: Run and see them fail** — `flutter test test/add_entry/presentation/bloc`. Every existing test in the two files must still pass untouched.
- [ ] **Step 3: Implement.** Note for the report: as with `AddEntryCategoryPicked`, the `Saving` state already guards a second tap, so the gated test passes with or without `droppable()`; say so rather than claim it proves the transformer.
- [ ] **Step 4: Verify** — `flutter test test/add_entry`; analyze clean.

---

### Task 8: Strings and the pill widget

**Files**
- Modify: `lib/l10n/app_en.arb`, then `flutter gen-l10n`
- Create: `lib/add_entry/presentation/widgets/usual_pill.dart`
- Test: `test/add_entry/presentation/widgets/usual_pill_test.dart`

**ARB keys** (each with `@key` description and placeholders, as the file does; used across Tasks 8–11)

| Key | Text | Used |
|---|---|---|
| `usualTag` | `your usual` | pill, after the existing `separator` |
| `usualSuggestionSpoken` | `Add {category}, {amount}, your usual` | AC-5; `amount` is `spokenAmount(...)` |
| `usualAdded` | `Added {amount} to {category}` | BR-10 snackbar; spoken form passes `spokenAmount` |
| `usualRowTitle` | `Your usual` | FR-SE-2 AC-6 |
| `usualRowDetail` | `{amount}, {days, select, weekdays{weekdays around} weekends{weekends around} other{around}} {time}` | AC-6; `time` is `DateFormat.j` text from `UsualWords` (M19), so there is no ARB key for the hour |
| `usualForget` | `Forget` | AC-6 |
| `usualForgetSpoken` | `Forget your usual {category}` | mockup 40 copy table |
| `usualForgotten` | `Forgotten` | AC-6 |
| `usualHow` | `Worked out on this phone from what you add.` | AC-6 |

**Interface**
- `class UsualPill extends StatelessWidget { const UsualPill({super.key, required this.usual, required this.onPressed, this.filled = false, this.failed = false}); }`
  - A `Pressable` (`semanticLabel: strings.usualSuggestionSpoken(name, strings.spokenAmount(context.money.digits(amount)))`, `focusRadius` 20, `focusInset` 4dp top and bottom) whose tap area is the slot's 48dp; inside it the visible pill, at least 40dp tall, a `StadiumBorder` with a 1dp `context.colors.ink2` side on `context.colors.surface`; `filled` paints it `ink` with `surface` text (the 120ms flash; `HisaabMotion.press`, `Duration.zero` under reduced motion).
  - Content, one line: `AppIcon(AppIcons.forKey(category.iconKey), size: 20)`, 8dp, the name (`titleMedium`), the amount (`context.money.format`, an amount style with tabular figures), then `'${strings.separator}${strings.usualTag}'` in `ink2`.
  - **Fit (FR-AD-10 AC-2):** a `LayoutBuilder` measures with `TextPainter` and the ambient `TextScaler`: the full line if it fits the width; else without the tag; else `SizedBox.shrink()`. Never ellipsis, never two lines. The pill grows from 40dp with the text but **never past the slot's 48dp**: a line that would need more counts as not fitting, so showing or hiding the pill can't change the slot's height (FR-AD-1).
  - **`failed` (FR-AD-10 AC-4):** the label reads `strings.couldntSave` in place of name, amount and tag; a tap tries again. The same fit rule applies; the spoken label becomes `strings.couldntSave`.
  - `key: const ValueKey<String>('usual-pill')` is set by the caller.

- [ ] **Step 1: Write the failing widget tests** (`pumpApp`)

| Test | Cites |
|---|---|
| `'shows the icon, name, amount and tag: Chai ₹20 · your usual'` | AC-2 |
| `'is 40dp tall with a 48dp tap area'` (`getSize` of the visible pill and of the `Pressable`) | AC-2, NFR-4 |
| `'has a 1dp ink2 edge on surface, in light and dark'` (read the `ShapeDecoration` against `HisaabColors.light` / `.dark`) | AC-2 |
| `'never uses the signal colour'` (no decoration equals `colors.signal`) | AC-2, CLAUDE.md one signal colour |
| `'reads one button: Add Chai, 20 rupees, your usual'` (`tester.getSemantics`; `isButton`; one node) | AC-5 |
| `'a renamed category shows its new name'`; `'a built-in category shows its localised name'` | BR-11 |
| `'at 1.5× text on a 320dp phone the tag drops'`; `'at 2× with a 16-letter name and ₹99,99,99,999 nothing is shown'`; `'at 1× the cap amount drops the tag before it disappears'` | AC-2, BR-10 cap |
| `'is never taller than 48dp'` at text scale 1, 1.5 and 2 (shown at ≤ 48dp, or not shown) | AC-2, FR-AD-1 |
| `'never overflows'` at `TestWindows.{smallPhone, phone, phoneLandscape, foldableUnfolded, tablet}` × text scale 1, 1.5, 2 (`tester.takeException()` is null) | NFR-4, NFR-8 |
| `'filled paints ink'`; `'under reduced motion the fill has no animation'` | AC-4 |
| `'failed reads Couldn't save. Try again. and still takes a tap'` | AC-4 |
| `'a tap calls onPressed once'`; `'Enter activates it'` (`test/helpers/focus_helpers.dart`) | UI_DESIGN §9 |
| `'meets tap-target, label and contrast guidelines'` in light and dark | accessibility.md |

- [ ] **Step 2: Run and see them fail.** — `flutter test test/add_entry/presentation/widgets/usual_pill_test.dart`
- [ ] **Step 3: Implement**; `flutter gen-l10n`.
- [ ] **Step 4: Verify** — green; `test/core/design/hard_coded_colours_test.dart` still green; analyze clean.

---

### Task 9: The slot and layout B

**Files**
- Create: `lib/add_entry/presentation/widgets/usual_slot.dart`
- Modify: `lib/add_entry/presentation/widgets/amount_step.dart`
- Test: `test/add_entry/presentation/widgets/usual_slot_test.dart`, `test/add_entry/presentation/pages/add_entry_tray_test.dart` (new group `'AddEntryTray your usual (FR-AD-10)'`; the `bloc()` helper there gains nothing: the new tests build their own bloc with `usual:`)

**Interface**
- `class UsualSlot extends StatelessWidget { const UsualSlot({super.key, required this.state}); static const double height = HisaabSizes.minTouchTarget; }` — a `ConstrainedBox(minHeight: height)` (FR-AD-1 "at least 48dp") centring an `AnimatedSwitcher` (`HisaabMotion.reducedCrossfade`, 150ms, the same under reduced motion; `// why:` AC-3 names 150ms) between `UsualPill` (when `state.form.usual` is some; `filled` when the state is `AddEntrySaving` / `AddEntryFinished`; `failed` from `AddEntryEditing.failed`; `onPressed` adds `AddEntryUsualPicked`) and the unchanged `SpendPreviewLine(preview: state.form.preview)`.
- `AmountStep`: `SizedBox(height: short ? HisaabSpacing.m : _aboveAmount)` with `static const double _aboveAmount = 20`; `SizedBox(height: HisaabSpacing.xs)` (4) before the slot; `UsualSlot` in place of `SpendPreviewLine`; `SizedBox(height: HisaabSpacing.s)` (8) before the chips. `AmountStep.state` stays `AddEntryEditing`, so `AddEntryTray._step` must keep step 1 on screen while saving from the pill: today a `Saving` or `Finished` state on the amount step falls through to `CategoryStep`. Widen its first branch to `state.form.step == AddEntryStep.amount` and pass the state through (`AmountStep.state` becomes `AddEntryState`; `rejections` read with a pattern, 0 otherwise). This is safe for the existing flows: a tile save, Delete (`category_step.dart`) and the new-category save all leave from steps other than `amount`. Keep `SpendPreviewLine` and its test untouched.

- [ ] **Step 1: Write the layout guard first** (it passes on today's layout and must stay green after layout B): `'the header fits without scrolling on a 412×915 phone'` at text scale 1 (the header's `Scrollable` has `maxScrollExtent == 0`, and the chips' bottom is above the keypad's top). Then, once the slot exists, add `'on 360×640 and 320×568 the pill can be scrolled into view and nothing overflows'` (`tester.ensureVisible`, `takeException()` is null). For OQ-8, put the header's measured `maxScrollExtent` at those two sizes in the task report. If the pill starts below the header's viewport there, tell the owner before going on; do not change the layout to hide it.
- [ ] **Step 2: Write the failing tests**

| Test | Cites |
|---|---|
| slot: `'is 48dp with the pill, with the preview and with nothing'` | FR-AD-1 |
| slot: `'shows the pill or the preview, never both'` | FR-AD-1 |
| slot: `'at 2× text a three-line preview grows the slot and nothing overflows'` | NFR-4, FR-AD-1 "at least" |
| slot: `'at ₹0 the slot is the same height with and without the pill'` at text scale 1, 1.5 and 2 | FR-AD-1 "never changes its height" |
| tray: `'the pill is there after one pump'` (`tap(open)`, one `tester.pump()`, `find.byKey('usual-pill')`) | AC-1, NFR-1, Review Focus 4 |
| tray: `'no usual: the slot is empty and nothing else moved'` (chips' top edge equals the with-pill run) | FR-AD-1, D153 |
| tray: `'layout B: 20dp switch to amount, 4dp to the slot, 8dp to the chips'` (`getRect` differences on `phone`) | UI_DESIGN §5.3 |
| tray: `'the short tray keeps 12dp above the amount'` (`phoneLandscape`) | UI_DESIGN §5.3 |
| tray: `'the first key crossfades the pill to the preview in 150ms and the chips do not move'` (pump 0, 75, 150ms; chips' `dy` constant; pill gone after) | AC-3 |
| tray: `'under reduced motion it still crossfades in 150ms'` | AC-3, NFR-4 |
| tray: one each, `'a chip'`, `'⌫'`, `'long-press ⌫'`, `'Got'` hide it; `'Spent again does not bring it back'` | AC-3 |
| tray: `'reopening the tray shows it again'` | AC-3 |
| tray: `'a tap saves ₹20 in Chai and closes the tray'` (`services.ledger.saved`) | AC-4 |
| tray: `'the pill is ink while it saves'` (gate the fake's `add`) | AC-4 |
| tray: `'a failed save keeps the tray open with Couldn't save. Try again. on the pill'` | AC-4 |
| tray: `'edit mode and a tray opened on Got show no pill'` | AC-1 |
| tray: `'both steps lay out without overflow with a usual'` on the four windows of the existing table, plus `tablet` and `foldableUnfolded` | NFR-8 |
| tray: `'tabletop: the pill sits beside the keypad, below the fold'` | UI_DESIGN §13 |
| tray: `'TalkBack order: Spent/Got, amount, the pill, the chips'` (semantics traversal) | AC-5 |
| tray: `'with a usual, step 1 meets tap-target, label and contrast guidelines'` in light and dark | NFR-4 |

- [ ] **Step 3: Run and see them fail** — `flutter test test/add_entry`.
- [ ] **Step 4: Implement.**
- [ ] **Step 5: Verify** — `flutter test test/add_entry test/app` green with **no existing test edited**. No existing test asserts the old 30 / 6 / 16 gaps or a keypad position, and there are no golden files (`grep -rn matchesGoldenFile test` is empty), so none should need a change. If one goes red, stop and ask.

---

### Task 10: "Added ₹20 to Chai" with Undo

**Files**
- Create: `lib/habits/presentation/widgets/usual_added_notice.dart`
- Modify: `lib/app/main_screen.dart` — optional `final Widget Function(Widget page)? wrapPrimary;`. Applied to `HomePage` always, and to `SpendsPage` only when Spends is not beside Home (`!spendsBeside`), so exactly one notice is mounted in every arrangement (BR-10 "over whichever of Home or Spends is in view"; `AppShell` mounts only the selected page in one pane and on a tabletop). `MainScreen` itself never reads `HabitsBloc`, so `test/app/main_screen_test.dart` keeps building it without one. `HomePage` already has its own `HisaabSnackbarHost(bottom: 0)` inside; the notice's host sits outside it, so Home's own Undo bars are untouched
- Modify: `lib/habits/habits.dart` (export `usual_added_notice.dart`)
- Test: `test/habits/presentation/widgets/usual_added_notice_test.dart`, `test/app/main_screen_test.dart` (new cases)

**Interface**
- `class UsualAddedNotice extends StatelessWidget { const UsualAddedNotice({super.key, required this.child}); }` — `HisaabSnackbarHost(bottom: 0, child: BlocListener<HabitsBloc, HabitsState>(listenWhen: current is HabitsReady && current.added.isSome(), listener: _offerUndo, child: child))`. `_offerUndo` shows `HisaabSnackbar(message: strings.usualAdded(money.format(amount), name), semanticsLabel: strings.usualAdded(strings.spokenAmount(money.digits(amount)), name), action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(HabitsUsualUndoRequested(added))))`.

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| `'shows Added ₹20 to Chai with Undo when a usual is added'` | BR-10 |
| `'TalkBack hears Added 20 rupees to Chai'` | habits/04 strings |
| `'Undo sends HabitsUsualUndoRequested once'` | BR-10 |
| `'it leaves after 4 s; with TalkBack it stays'` (`accessibleNavigation`) | BR-10, D105 |
| `'a reload does not show it twice'` | |
| `'a renamed category's name is used'` | BR-11 |
| `'fits a 320dp phone at 2× text'` | NFR-4 |
| main screen: `'without wrapPrimary nothing changes'`; `'on a phone the page in view is wrapped'`; `'in two panes only Home is wrapped'`; `'on the Spends tab the wrapper is around Spends'`; `'on a tabletop the page above the fold is wrapped'` | BR-10 |

- [ ] **Step 2: Run and see them fail.** — `flutter test test/habits/presentation/widgets test/app/main_screen_test.dart`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Verify** — green; `flutter test test/app` green untouched.

---

### Task 11: Settings: *Your usual* with *Forget*

**Files**
- Create: `lib/habits/presentation/bloc/usual_row_bloc.dart`, `usual_row_event.dart`, `usual_row_state.dart`, `lib/habits/presentation/usual_words.dart`, `lib/habits/presentation/widgets/your_usual_row.dart`
- Modify: `lib/settings/presentation/pages/categories_page.dart` (`const CategoriesPage({super.key, this.usualRow})`, `final Widget Function(Category category)? usualRow;`, passed on by `_row` as `CategorySheet.show(context, bloc, id: category.id, usualRow: …)` for *Spent* categories only; the *Add a category* call passes none), `lib/settings/presentation/widgets/category_sheet.dart` (`show(..., {int? id, Widget Function(Category category)? usualRow})` and a matching field; the sheet's `SingleChildScrollView` wrapped in a `HisaabSnackbarHost`, so "Forgotten · Undo" sits 24dp above the sheet's bottom edge as in mockup 40; FR-SE-2 AC-6), `lib/settings/presentation/widgets/category_sheet_summary.dart` (`this.usual`, a `Widget?` the sheet builds as `usualRow(category)`, placed after the Name / Icon card and before *Hide* or the built-in note, as mockup 40 §6). The builder takes the `Category`, not its id, so the row gets the shown name (`category.labelIn(strings)`) and follows a rename made in the same sheet
- Modify: `lib/habits/habits.dart` (export `UsualRowBloc` with its events and states, and `your_usual_row.dart`; `usual_words.dart` stays internal)
- Test: `test/habits/presentation/bloc/usual_row_bloc_test.dart`, `test/habits/presentation/usual_words_test.dart`, `test/habits/presentation/widgets/your_usual_row_test.dart`, `test/settings/presentation/pages/categories_page_test.dart` (new cases)

**Interfaces**
- Events: `UsualRowLoadRequested()` (restartable), `UsualRowForgetRequested()` (droppable), `UsualRowForgetUndone()` (droppable).
- States: `UsualRowEmpty()`, `UsualRowShown(UsualHabit habit)`, `UsualRowForgotten(ForgottenUsual forgotten)`.
- `class UsualRowBloc extends Bloc<UsualRowEvent, UsualRowState>` — `{required int categoryId, required GetHabitIndex getIndex, required ForgetUsual forget, required RestoreUsual restore, required Clock clock}`. Load: `index.habitFor(categoryId, preferring: DayType.of(clock.today()))` → `Shown` or `Empty`; a failure → `Empty`, type logged. Forget: `Forgotten(previous)`; a failure keeps `Shown`. Undo: `restore`, then the shared `_load(emit)`.
- `abstract final class UsualWords { static String detail(AppLocalizations strings, UsualHabit habit, {required String amount, required String locale}); }` — picks `days` (`'weekdays'`, `'weekends'`, `'all'` for pooled) and the time as `DateFormat.j(locale).format(DateTime(2000, 1, 1, habit.window.aroundHour)).replaceAll('\u202F', ' ')` (BR-17, M19; `// why:` on the replace). The row passes `context.money.locale`, as `over_card.dart` does for its dates.
- `class YourUsualRow extends StatelessWidget` — reads `UsualRowBloc`; `Shown` → a `surface` card row at least 56dp tall: "Your usual" (`bodyLarge`), the detail under it (`bodySmall`, `ink2`), and a *Forget* text button (48dp target, `semanticsLabel: usualForgetSpoken(name)`), then `usualHow` under the card in `bodyMedium` `ink2`; other states → `SizedBox.shrink()`. On `Forgotten` a listener shows `HisaabSnackbar(message: strings.usualForgotten, action: Undo)` in the sheet's host. Takes the category's shown name through its constructor.

- [ ] **Step 1: Write the failing tests**

| File | Test | Cites |
|---|---|---|
| words | `'₹20, weekdays around 10 am'`, `'₹120, weekends around 1 pm'`, `'₹20, around 10 am'` (pooled), `'midnight is 12 am, noon is 12 pm'`, all for `en_IN` and compared as exact strings with a plain space; `'the time has no narrow no-break space'` | AC-6, BR-17 "Around {time}" |
| bloc | `'starts empty'`; `'a Regular habit is shown'`; `'no habit stays empty'`; `'a failed load stays empty'` | AC-6 |
| | `'on a weekend with only a weekday habit, the weekday habit is shown'`; `'with both, today's day type is shown'` | AC-6 |
| | `'a hidden category shows nothing'`; `'under 14 days of use: nothing'` | E59, E67 |
| | `'a habit that missed 3 days is still shown'` (fading is still Regular) | AC-6, BR-17 |
| | `'a habit resting after two Undos is still shown, so it can be forgotten'` | BR-17 |
| | `'Forget hides the row and stores forgottenAt and a 30-day rest'` | AC-6, BR-17 |
| | `'a failed Forget keeps the row'` | |
| | `'Undo puts the previous state back and the row returns'`; `'Undo after forgetting a resting habit leaves it resting as before'` | AC-6, E68 |
| | `'a second Forget tap is dropped'`; `'closing mid-load does not throw'`; `'a slower, older load never lands last'` | bloc.md |
| row | `'shows Your usual, the detail, Forget and the note'` | AC-6 |
| | `'Forget reads Forget your usual Chai'`; `'Forget has a 48dp target'` | NFR-4 |
| | `'nothing is built without a habit'` | AC-6 |
| | `'fits 320dp at 2× text'`; `'meets the guidelines in light and dark'` | NFR-4 |
| page | `'without usualRow the sheet is as before'` | contract |
| | `'the row sits under Name and Icon and above Hide'` | mockup 40 §6 |
| | `'a Got category's sheet never gets the row'` | BR-17 |
| | `'Forget removes the row and shows Forgotten with Undo inside the sheet; Undo brings it back'` | AC-6, E68 |
| | `'renaming in the sheet changes what Forget reads out'` | AC-6 |
| | `'the sheet with the row fits 320dp at 2× text and the Forgotten bar never covers Forget's place'` (no overflow; the sheet scrolls) | NFR-4 |

- [ ] **Step 2: Run and see them fail.** — `flutter test test/habits/presentation test/settings/presentation/pages/categories_page_test.dart`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Verify** — `flutter test test/settings test/habits` green with no existing test edited.

---

### Task 12: Barrel, DI and routes

**Files**
- Create: `lib/habits/di/habits_module.dart`
- Modify: `lib/habits/habits.dart` (add `di/habits_module.dart`; check the list below is complete), `lib/app/app_services.dart` (call `registerHabitsServices(getIt)` after `registerLedgerServices`), `lib/app/routes.dart`
- Modify (test support, additive): `test/helpers/fake_services.dart` — a `FakeSuggestionStateRepository states` field, and `register` adds `SuggestionStateRepository`, `GetHabitIndex`, `UndoUsualAdd`, `ForgetUsual`, `RestoreUsual` over the fakes, so the existing app tests can build `AppRoutes.main`
- Test: `test/app/app_services_test.dart` (new case `'wires habits over the ledger'`), `test/app/app_root_test.dart` (new cases)

**Interfaces**
- `habits.dart` exports: the entities (`UsualSpend`, `UsualAdd`, `UsualHabit`, `HabitIndex`, `DayType`, `TimeWindow`, `SuggestionState`, `ForgottenUsual`), `detectors/usual_spend_detector.dart`, `repository/suggestion_state_repository.dart`, the four use cases, both blocs with their events and states, `usual_added_notice.dart`, `your_usual_row.dart`, `di/habits_module.dart`. It never exports the data source, model, mapper or repository impl.
- `void registerHabitsServices(GetIt getIt)` registers `SuggestionStateRepository` (impl over `SqfliteSuggestionStateLocalDataSource(getIt<AppDatabase>())`) and the four use cases.
- `routes.dart`:
  - `main`: add `BlocProvider<HabitsBloc>(lazy: false, create: … ..add(const HabitsLoadRequested()))` with a `// why:` (the first load must start with the screen, not with whatever happens to read the bloc first; left to the first Add tap it is too late for that tray's first frame); the existing `ResumeListener` also adds `HabitsLoadRequested`; wrap `MainScreen` in a `MidnightListener(clock: getIt<Clock>(), onNewDay: …)` that adds it too; pass `wrapPrimary: (Widget page) => UsualAddedNotice(child: page)`; after Settings pops, add it beside the existing `HomeLoadRequested`.
  - `openAddTray`: after `categories` is known and before the bloc is built,
    ```dart
    final HabitsState habits = context.read<HabitsBloc>().state;
    final Option<UsualSpend> usual = habits is HabitsReady && editing.isNone() && kind == EntryKind.spent
        ? UsualSpendDetector.suggest(habits.index, now: getIt<Clock>().now(), categories: categories)
        : const Option<UsualSpend>.none();
    ```
    pass `usual: usual`; capture `final HabitsBloc habitsBloc = context.read<HabitsBloc>();` before the `await`; after `homeBloc.add(const HomeTrayClosed())`:
    ```dart
    if (bloc.state case AddEntryFinished(added: Some<Entry>(value: final Entry entry))) {
      usual.map((UsualSpend spend) => habitsBloc.add(HabitsUsualAdded(UsualAdd(entry: entry, category: spend.category))));
    }
    ```
  - `categories`: `CategoriesPage(usualRow: (Category category) => BlocProvider<UsualRowBloc>(key: ValueKey<int>(category.id), create: (BuildContext _) => UsualRowBloc(categoryId: category.id, …)..add(const UsualRowLoadRequested()), child: Builder(builder: (BuildContext context) => YourUsualRow(name: category.labelIn(AppLocalizations.of(context))))))`. `CategoriesPage` is no longer `const` here.
  - The `HabitsBloc` reads happen on `context`, the `Builder` context under `MultiBlocProvider` that `openAddTray` already receives (also when called from the entries page's `onEdit`), and after the existing `context.mounted` check.

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| services: `'wires habits over the ledger'` (`GetHabitIndex` on a fresh database returns an empty index) | |
| app root, seeded with `chaiWeekdays` and `FakeClock` at Mon 26 Oct 2026 10:05: `'Add shows Chai ₹20 · your usual in the first frame'` | AC-1, NFR-1 |
| `'at 3:30 pm the slot is empty'`; `'on Saturday the slot is empty'` | mockup 40 |
| `'one tap saves, closes the tray and offers Undo on Home'` | AC-4, BR-10 |
| `'Undo removes the entry; reopening Add the same day shows no pill'` | E63 |
| `'after the tap, reopening Add shows no pill: Chai is logged today'` | E65 |
| `'from the Spends tab the Undo shows over Spends'` | BR-10 |
| `'opening Add before the habits have loaded shows no pill, then or later'` (gate `services.states.nextReadGate`, which only the habits load reads; open Add, complete the gate, settle: still no pill) | AC-1 |
| `'editing an entry shows no pill'` | AC-1 |
| `'Settings › Categories › Chai shows the row; Forget, back, Add: no pill'` | AC-6, BR-17 |

- [ ] **Step 2: Run and see them fail.** — `flutter test test/app`. Every existing test in `test/app` must stay green untouched: `FakeServices`' default worked-example entries form no habit, so no existing tray gains a pill.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Verify** — `flutter test` (everything) green; `flutter analyze` clean.

---

### Task 13: Docs and the phase check

- [ ] **Docs, in this change** (CLAUDE.md "update the doc in the same change"; apply the owner's answers to the open questions here):
  - `docs/SPEC.md` and `docs/UI_DESIGN.md` §5.3 already carry D154. Change them only for what the owner decides on the three wording points under *Open questions* (E71's reason, the day-0 anchor of the rest, hidden and forgotten entries as active days), or where the build had to depart; say so in the report.
  - `docs/features/habits/01`, `03`, `04`: rewrite to what was built with the document-feature skill (no tracked items, no grouped SQL, the `suggestion_state` columns, the maths table above); status "built".
  - `docs/PLAN.md` §8 (data model: `suggestion_state`, schema v4) and §9 (tree: `lib/habits/`).
  - `CLAUDE.md` architecture list: add `habits` to the feature folders.
  - `docs/DECISIONS.md`: one row per answered open question that changed a rule (next free number: `grep -o '^| D[0-9]*' docs/DECISIONS.md | sort -t D -k2 -n | tail -1`).
- [ ] **Privacy checks**
  - `grep -rn "habits" lib/ask_ai lib/backup` prints nothing: Ask AI and the backup code never import habits (the backup carries the table only through its all-tables dump, Task 4).
  - `grep -rn "AppLogger" lib/habits` shows only type names in `data:`.
  - `grep -rn "DateTime.now()" lib/habits lib/add_entry` prints nothing.
- [ ] **Final gate**
  - `flutter analyze` → no issues.
  - `flutter test` → all green.
  - `scripts/changed_lines_coverage.sh $BASE` → ≥ 90%; report in the tests.md format. Expected gaps: none in `lib/habits/domain`; `lib/app/routes.dart` and `lib/core/di/` are excluded by the script.
  - For each changed file list the never-taken branches (the `awk` in tests.md) and give each a test or a reason.
  - Run the app once on a device (live-app-inspection skill): the pill at 1× and 1.5× text, light and dark, TalkBack reading it, the tray opening without a visible delay.

---

## Traceability (requirement → test)

| Requirement | Test (task) |
|---|---|
| BR-10 Save has no Undo except the pill | `'a normal tile save finishes with no added entry'` (7); `'shows Added ₹20 to Chai with Undo …'` (10) |
| BR-10 Undo deletes and quiets; 4 s; TalkBack | `'deletes the entry and quiets its category today'` (5); `'it leaves after 4 s; with TalkBack it stays'` (10) |
| BR-17 learns from: Spent, 56 days, same-day, not a rule's | `'Got and Saved entries are ignored'`, `'an entry 56 days old …'`, `'a back-dated entry is ignored'`, `'an entry posted by a rule is ignored'` (2) |
| BR-17 edit and Undo keep `created_at` | existing `test/ledger/data/repository/ledger_repository_impl_test.dart` (prerequisite, done); `'an edit to another amount counts …'` (2) |
| BR-17 habit = category + day type | `'Monday to Friday are weekdays …'` (1); `'weekdays and weekends are learned apart'` (2) |
| BR-17 hidden and system-hidden have none | `'a hidden category has no habit …'`, `'the saved and card_paid rows have none'` (2) |
| BR-17 48 slots that wrap; weight; smoothing | `'slotOf and minuteOf …'`, `'weightOf halves every 14 days'`, `'a run across midnight wraps'` (1) |
| BR-17 window: strictly above half the highest slot, earlier on a tie, ± 15 min | `'one busy slot gives a 60-minute window'`, `'the run stops at … exactly half'`, `'two separate peaks …'`, `'two equal peaks: the earlier slot wins'`, `'an even spread has no window'` (1) |
| BR-17 inside by the logged minute | `'contains its start and not its end'` (1); `'an entry 10 minutes before the first slot is a hit'` (2); `'at the window's first minute: yes; at its end minute: no'` (3) |
| BR-17 rule 1 (app-wide) | `'13 days …'`, `'14 days with 10 …'`, `'14 days with 9 …'`, `'the warm-up is app-wide …'`, `'forgotten entries still make their days active …'` (2) |
| BR-17 rule 2 | `'4 entries …'`, `'5: a habit'`, `'an entry 10 minutes before the first slot is a hit'` (2) |
| BR-17 rule 3 | `'12 of 20 …'`, `'11 of 20 …'`, `'a day with no entry at all …'`, `'another entry today …'` (2) |
| BR-17 rule 4 | `'7 of 10 …'`, `'69 of 100 …'`, `'recent entries weigh more'` (1); `'two amounts at 60/40'` (2) |
| BR-17 pooled fallback, ≥ 2 own hits in 28 days | `'… 2 of them in the pooled window: weekends use the pooled habit'`, `'with 1 weekend entry in the pooled window …'`, `'2 weekend entries … older than 28 days …'`, `'a weekend that fails rule 4 …'`, `'pooled passes only when it passes all four'`, `'a strong weekday habit … silent on Saturday'` (2) |
| BR-17 missed 3 in a row, until hit again | `'missed on the last 3 …'`, `'missed on 2 …'`, `'a hit after 3 misses …'`, `'days with no entry are not misses'`, `'a pooled habit on weekends fades on 3 missed weekend days …'` (2); `'a fading habit: none'` (3) |
| BR-17 suggestion: exact amount, never rounded | `'the suggested amount is the one logged, to the paise'` (2); `'the saved amount is the suggestion's …'` (7); `'the amount at the 9-digit cap …'` (1) |
| BR-17 offered inside the window, no entry today | `'inside the window …'`, `'at the window's first minute …'`, `'outside the window'`, `'the category already has an entry today'` (3) |
| BR-17 two qualify | `'two qualify …'`, `'equal share …'`, `'still equal …'` (3) |
| BR-17 quiet until midnight; second within 14 days (day 14 counts); rest through day 30 | `'after an Undo: quiet today, open tomorrow'`, `'a second Undo 14 days later …'`, `'15 days later only quiets'`, `'resting on day 30, open on day 31'` (3); `'a second Undo within 14 days rests it 30 days'` (5) |
| BR-17 quiet is per category | `'quiet for Chai still offers another category's habit …'` (3) |
| BR-17 Forget, and Undo after it | `'entries before Forget are ignored …'` (2); `'Forget sets forgottenAt …'`, `'Forget rests through day 30 …'` (3); forget and restore use-case tests (5); `'Undo after forgetting a resting habit leaves it resting as before'` (11) |
| BR-17 `suggestion_state` table, new migration | `'Schema v4 (D153)'` group (4) |
| BR-17, BR-16 state backed up, restored, wiped | backup data source and repository tests (4) |
| BR-17 "Around {time}" | `'aroundHour is the hour nearest the middle …'` (1); words tests (11) |
| BR-17 on the device; nothing logged with amounts or names | privacy checks (13). Not asserted by a test: `AppLogger` has no seam |
| FR-AD-1 slot at least 48dp, pill or preview, never both, same height with or without the pill | slot tests (9); `'is never taller than 48dp'` (8) |
| FR-AD-3 preview in the slot | `'shows the pill or the preview, never both'` (9); existing `'shows the overspend preview from the mockup'` |
| FR-AD-10 AC-1 | `'a new Spent tray opens with the usual …'`, `'edit mode drops it'`, `'a tray opened on Got drops it'`, `'no event adds a usual'` (7); `'the pill is there after one pump'` (9); `'opening Add before the habits have loaded …'` (12). Shortcut and tile: not built (M7), OQ-15 |
| FR-AD-10 AC-2 | pill tests (8) |
| FR-AD-10 AC-3 | hide tests (7, 9); `'the first key crossfades … in 150ms and the chips do not move'`, `'reopening the tray shows it again'` (9) |
| FR-AD-10 AC-4 | save, double-tap and failure tests (7, 9); `'one tap saves, closes the tray and offers Undo on Home'` (12) |
| FR-AD-10 AC-5 | `'reads one button: Add Chai, 20 rupees, your usual'` (8) |
| FR-SE-2 AC-6 | words, bloc, row and page tests (11) |
| E58 | `'a window across midnight holds both sides'` (1); `'a window across midnight'` (2); `'both sides of midnight'` (3) |
| E59 | `'a hidden category has no habit; shown again, it has'` (2); `'the category is hidden in the tray's list: none'` (3); `'a hidden category shows nothing'` (11) |
| E60 | `'an edit to another category …'`, `'… another amount …'`, `'a back-dated entry is ignored'` (2) |
| E61 | the three "two qualify" tests (3) |
| E62 | `'slotOf and minuteOf read the wall clock'` (1); `'forgotten_at keeps its wall-clock fields'` (4) |
| E63 | gate tests (3); undo use case (5); `'Undo removes the entry; reopening Add the same day shows no pill'` (12) |
| E64 | `'… weekends with 3 entries, 2 of them in the pooled window …'`, `'with 1 weekend entry in the pooled window: nothing on weekends'`, `'pooled passes only when it passes all four'` (2) |
| E65 | `'loggedToday holds every category …'` (2); `'the category already has an entry today: none'` (3); `'after the tap, reopening Add shows no pill'` (12) |
| E66 | `'an entry dated after today is ignored'` (2) |
| E67 | `'an empty ledger is an empty index'`, `'13 days after the first entry: nothing'` (2); `'an empty index: none'` (3); `'under 14 days of use: nothing'` (11) |
| E68 | `'puts the previous state back'`, `'with no previous state the row is removed'` (5); `'Undo puts the previous state back and the row returns'`, `'Forget removes the row …; Undo brings it back'` (11) |
| E69 | `'hiding a category and bringing it back keeps its row'` (4); `'a hidden category keeps its quiet state when it is shown again'` (2) |
| E70 | `'a horizon across 29 February 2028'`, `'across New Year'` (2); `'a rest across New Year and across 29 February'` (3) |
| E71 | `'two separate peaks …'`, `'two equal peaks: the earlier slot wins'`, `'an even spread has no window'` (1) |
| NFR-1 | `'the pill is there after one pump'` (9); the detector is synchronous and `O(habits)` |
| NFR-3 | privacy checks (13) |
| NFR-4 | pill, slot, notice and row tests at 1.5× and 2×, reduced motion, tap targets, contrast (8–11) |
| NFR-5 | migration and backup tests (4) |
| NFR-8 | `TestWindows` tables (8, 9) |

## Open questions for the owner

**Still open.**

- **OQ-17 (before Task 4).** May Task 4 change the two schema-version assertions (3 → 4) in `test/core/db/app_database_test.dart`? A schema bump can't leave them green, and commit `7bdb0af` did the same for v3.
- **OQ-8 (reported from Task 9, not blocking).** Short windows: on a phone under about 676dp tall the slot can sit below the fold of the header's scroll area. Default: left as is (reachable by scrolling and by TalkBack); Task 9 step 1 measures it.
- **OQ-18. E71's reason is wrong as written.** In a flat profile every slot equals the highest, so every slot *is* strictly above half of it. The plan builds E71's outcome (M6: a run that takes in all 48 slots has no window). Proposed SPEC wording: "a flat profile's run would take in the whole day, so it has no window".
- **OQ-19. Which day is "day 30" of a rest?** The plan reads BR-17 as: day 0 is the day of the Undo or Forget, the category rests through day 30 and is open again on day 31 (M17), the same day count as "a second within 14 days (counting day 14)". Proposed SPEC wording: "rests it until the end of the 30th day after it".
- **OQ-20. Do a hidden or forgotten category's entries still count as days of use?** BR-17 defines learned entries without the category, so the plan says yes (M1 / M1b): they keep counting for rule 1, rule 3's active days and the 3-miss rule of *other* habits, and only stop feeding their own category's habit. Otherwise *Forget* on a daily chai would shrink every other habit's active days and could make one Regular by itself. Proposed SPEC wording, in the *Forget* bullet: "…ignores that category's entries logged before that moment when working out its own habit; they still count as days with a learned entry."
- **OQ-21. A window's middle on the half hour** (a run of an even number of slots) rounds up: 9:45–11:15 reads "around 11 am" (M19). BR-17 only says "the hour nearest".
- **OQ-4 (extra rule, not built).** No cap on a window's length; a run of 47 slots is the whole day. Recommended later: a window longer than 3 hours is not a habit.

**Answered by D154; SPEC now says it (kept for the record).**

- **OQ-1.** The pooled fallback needs ≥ 2 of the day type's own entries in the pooled window in the last 28 days (BR-17, E64).
- **OQ-2.** Rule 3 and the 3-miss rule count only days before today that have any learned entry; days with no entry are never misses (BR-17).
- **OQ-3.** Rule 1 is app-wide (BR-17).
- **OQ-4.** Strictly above half around the highest slot, the earlier one on a tie (BR-17, E71).
- **OQ-5.** "Couldn't save. Try again." is the pill's label; a tap tries again (FR-AD-10 AC-4).
- **OQ-6.** The Undo shows over whichever of Home or Spends is in view (BR-10).
- **OQ-7.** *Forget* keeps the sheet open with "Forgotten" and *Undo* inside it; Undo puts the earlier state back (FR-SE-2 AC-6, E68).
- **OQ-9.** The pill's fit rule is by what one line holds: full → without "· your usual" → nothing; 40dp growing to the slot's 48dp (FR-AD-10 AC-2).
- **OQ-10.** The slot is at least 48dp (FR-AD-1).
- **OQ-11.** With both a weekday and a weekend habit, the row shows today's day type (FR-SE-2 AC-6).
- **OQ-12.** `suggestion_state` is backed up, restored and wiped with everything else (BR-16, BR-17).
- **OQ-13.** The quiet state is per category (BR-17).
- **OQ-14.** 56 days is today − 55 … today; "within 14 days" counts day 14; a rest ends at the end of day 30 (BR-17; see OQ-19 for the anchor).
- **OQ-15.** The app shortcut and Quick Settings tile on a cold start are decided with FR-WG-6/7 (FR-AD-10 AC-1). Until then a tray opened before the first habits load has no pill, then or later (Task 12).
- **OQ-16.** `suggestion_state` is kept per category (BR-17).

## Self-review (done while writing)

- **Every BR-17 clause and E58–E71** has at least one named test in the traceability table.
- **Names were read from the source,** not guessed: `AddEntryBloc`'s private-named constructor parameters, `EntryForm`, `AddEntryEditing` / `Saving` / `Finished`, `AppRoutes.openAddTray`, `HisaabSnackbarHost` / `HisaabSnackbar` / `HisaabSnackbarAction`, `Pressable`, `AdaptiveSplit`, `dbTask` / `readRow` / `intAt` / `stringOrNullAt`, `openTestDatabase`, `FakeClock`, `FakeLedgerRepository.nextReadGate` / `nextDeleteGate`, `bloc.dispatch`, `tester.settle`, `TestWindows`, `WorkedExample.today` (Mon 26 Oct 2026).
- **No existing test is edited** except the two version pins (OQ-17). Test helpers change only by addition (`nextAddGate`, `FakeServices` registrations).
- **Not verified by running:** the header heights behind OQ-8 are read from the source (`AdaptiveSplit`, `Keypad`, `SignalKey`, the type scale), not measured; Task 9 step 1 measures them. That `test/backup/.../backup_repository_impl_test.dart:238` stays green at schema v4 is read from the code (`restore` → `replace`), not run.
- **Rules checked:** domain is pure Dart; use cases implement `UseCase<T, Params>` with one `call`; repositories return `TaskEither`; one widget per file; no `Colors.*`, no literal strings; sealed events, `restartable()` for loads and `droppable()` for saves, each with a gated test; every I/O boundary has an interface and a hand-written fake.

## Review log (second review, 2026-11-13)

An independent review against the amended SPEC (D154) and the code at `2909518`. Nothing was run; every name below was read from the source.

**Brought in line with SPEC**

1. **E71, flat profile (M6, Task 1).** The plan gave an even spread a whole-day window; E71 says it has none. A run that takes in all 48 slots now returns `none()`; the test is `'an even spread has no window'`. A 47-slot run still widens to 1440 minutes and is capped there.
2. **Rest length (M17, Task 3).** "Ending at the end of day 30": the rest now holds through `today + 30` and opens on day 31 (was open on day 30). Tests renamed; a Forget bound test added.
3. **Second Undo "within 14 days" (M17).** 0–14 days, not 1–14.
4. **"Around {time}" (M19, Tasks 8 and 11).** BR-17 names `DateFormat.j`; the plan used its own ARB key. `UsualWords` now formats with `DateFormat.j(locale)` and swaps `intl`'s U+202F for a plain space; `usualTime` is dropped from the ARB table.
5. **3-miss rule for a pooled habit (M14).** Counted on days of the day type the habit is offered on, as BR-17 says, not on the pooled profile's days. Test added.
6. **Learned entries (M1 split into M1 / M1b).** The plan dropped hidden and forgotten categories' entries from `L`, which also removed their days from rule 1, rule 3 and the 3-miss rule of other habits. BR-17 defines learned entries without the category. Three tests added; raised as OQ-20.
7. **Pooled fallback boundaries (Task 2).** E64's exact cases added: 2 own hits → pooled, 1 → nothing, 2 hits older than 28 days → nothing.
8. **New edge cases E66–E71** given tests and traceability rows; `'an entry dated after today'` now cites E66, not E62. E69 gets a real-SQLite test (hide and show keeps the row) and a builder test.
9. **Slot height (Tasks 8 and 9).** The pill never exceeds the slot's 48dp, and the slot's height at ₹0 is tested with and without the pill at 1×, 1.5× and 2× text (FR-AD-1 "never changes its height").
10. **Header, spec line, self-review, open questions** updated for D154; the "do not start until OQ-1 to OQ-3" gate is lifted. `ASSUMED (OQ-n)` tags that SPEC now settles cite SPEC instead.

**Brought in line with the code**

11. **Task order (blocker).** Task 7 imports `lib/habits/habits.dart`, which Task 12 created. The barrel is now created in Task 3 and grown by Tasks 5, 6, 10, 11 and 12.
12. **Lazy `BlocProvider` (major).** `HabitsBloc` is provided with `lazy: false`, so its first load starts with the main screen and not with whatever first reads it.
13. **`AppLogger` has no test seam.** The "logs the type only" test is dropped from Task 6; NFR-3 stays a grep and review check.
14. **Unreadable-row test (Task 4).** An int written to a TEXT column reads back as text, so it would not throw; the test writes a BLOB. Rows use a seeded category id because the foreign key is on.
15. **`backup_repository_impl_test.dart:238`.** The plan's reason was wrong (`restore` never upgrades); it stays green because `replace` still fails on the unknown table. Also checked: `backup_json_mapper_test.dart` pins its own `current = 3`, and the backup code needs no change for a new table.
16. **Version pins (OQ-17).** Precedent found (`7bdb0af`); unavoidable, still the owner's call.
17. **Settings row builder (Tasks 11 and 12).** `usualRow` takes the `Category`, not an id, so the row has the shown name and follows a rename; `CategorySheet.show` gains `usualRow`; the host wraps the sheet's scroll view.
18. **`HabitsBloc` loses its `Clock`** and the unreachable "add while loading" branch (CLAUDE.md: no handling for impossible cases).
19. **Gated app test (Task 12).** `FakeLedgerRepository.nextReadGate` is taken by whichever bloc reads first (Home, Spends or habits). `FakeSuggestionStateRepository` gets its own gate, which only the habits load reads.
20. **Smaller fixes.** `SaveEntryParams` named in Task 7; the fixture's icon key is `'chai'` and its Food entries cover all 20 weekdays (or the share is not 18 of 20); the rule-1 app-wide test has numbers that pass rule 3; `_step` widening explained and shown safe for Delete and the new-category save; Task 9's "measuring test" made into two real assertions; a tabletop case for `wrapPrimary`; NFR-1 cost stated under *Architecture*.

**Left for the owner:** OQ-17, OQ-8, OQ-18 to OQ-21 above.
