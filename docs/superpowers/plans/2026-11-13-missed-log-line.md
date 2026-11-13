# The missed-log line (D171 to D173). Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Build order:** plan **2 of 3** (M8 step 4). It needs **migration 005 from plan 1** (`2026-11-13-yearly-costs-and-used.md`, Task 1: the `suggestion_state.asked_on` column already exists). Plan 3 (`2026-11-13-fix-my-number.md`) adds the install line to the slot this plan builds. **SPEC wins over this plan.**

**Goal:** After a Regular habit's window has ended by at least 90 minutes and its category still has no entry today, Home's nudge slot may show one quiet line, "Spent on Food today?" over "Usually around 1 pm.". A tap opens the Add tray at step 1 carrying that habit, so the *your usual* pill shows outside its window. Ignoring is free; Back clears the line for the day. One question a day in total.

**Scope:** BR-17 (the asked column, the missed-log rules, "around"); FR-HO-3 (slot order, *When a line is decided*, *Order stays stable*, *Focus*, the missed-log AC-1 to AC-6); FR-AD-10 AC-1 (the carried-habit clause); E103 to E108; D170 to D173, D189 (the saved-yesterday note never silences a line); `docs/features/habits/08-missed-log-line.md`. **Not here:** the install line (plan 3 adds it as the slot's third item), the foot row, Fix my number.

**Architecture:**
- **`asked_on` is a nullable column on `suggestion_state`** (D172), already created by migration 005. `SuggestionState.askedOn` carries it. It is never `quiet_on` (that feeds the 14-day Undo count). Tap, ignore and Back write only `asked_on`.
- **`MissedLogDetector`** (pure, in `lib/habits/domain/detectors/`) beside `UsualSpendDetector`: `(HabitIndex, now, categories, dayType)` → `Option<MissedLog>`. `asked_on` arrives inside `index.states`, so the detector's signature is SPEC's "takes the habit index, now, the categories, the asked_on dates and the day type" without a fifth parameter that duplicates state. It shares the pill's tie-break (`UsualSpendDetector` makes its private `_byRank` a public static `rank`: one-word visibility change, the only edit to that class).
- **`HomeLinesBloc`** (new, `lib/home/presentation/bloc/`) owns the nudge slot's two lowest items. It is a separate Bloc from `HomeBloc` (one Bloc per independent concern; Blocs never reference each other): its inputs are *evaluation points*, not ledger ticks. The slot's order across Blocs is resolved in `HomePage._nudge`: a **bill line** (waiting, due-soon; `HomeBloc`) always outranks `HomeLinesBloc`'s line, and `HomeLinesBloc` never promotes a lower line mid-view.
- **Evaluation points** (D170): cold start, resume, and the resume a door-opened tray causes. Not rebuilds, ledger ticks, rotation, folds or the clock passing the 90-minute mark. The app root adds `HomeLinesPointReached` from `ResumeListener` and at first build; the bloc **latches** the point and resolves it at the **first `HomeReady` after the point**, reading `HabitsBloc.state` **synchronously** at that moment. If the habits are not ready then, the point is spent and the line is missed for that open (E106: no pop-in).
- **A user's own act can make the line leave, never appear** (D170): `HomeLinesBloc` has `HomeLinesEntryLogged`, `HomeLinesGateClosed`, `HomeLinesMidnight`, `HomeLinesTrayAnswered` as *removals* only; only `HomeLinesPointReached` evaluates.
- **"Visible" for `asked_on`** is "on screen, Home in view, no tray or sheet over it" (AC-4). The hold count that P1 built is exactly "a tray or sheet over Home": `HomeBloc` exposes `bool get isCovered => _holds > 0`. A `MissedLogProbe` widget reports `HomeLinesShown` once per point from a post-frame callback when `isCovered` is false, `ModalRoute.of(context)?.isCurrent` is true and the Home destination is in view (`TickerMode.of(context)`). Task 7 verifies how `AppShell` hides an inactive destination before relying on that.
- **The carried habit** is an optional `Option<UsualSpend> carry` on `AppRoutes.openAddTray`: when `Some`, it replaces the detector call; the tray's pill shows outside the window. No change to `AddEntryBloc`'s contract: `usual` is already its constructor input.

**Prerequisites:** plan 1 merged (migration 005, `TestWindows.book/splitScreenShort`, `PolitePreviewSlot`). P1 (the hold as a count, `holdingHome`) and the keypad prerequisites of plan 1.

**Tech stack:** as plan 1. No new dependency.

**Spec:** BR-17 (Asked, missed-log line), FR-HO-3, FR-AD-10 AC-1, E65, E103 to E108, NFR-1, NFR-3; UI_DESIGN §5.2, §6 to §10 (the line, its collapse, its focus return); D153, D154, D170 to D173, D189; copy deck 41 §7; mockup [43](../../design/mockups/43-missed-log-line.html) (banner: superseded by `habits/08`).

## Where this plan departs from the docs, and what is ambiguous

| # | Point | What the plan does |
|---|---|---|
| B1 | `SuggestionGate.afterUndo` and `afterForget` build a **new** `SuggestionState` from three fields. With a fourth, they would silently drop `askedOn`. | Both copy `askedOn`; a regression test per method (Task 1). `ForgottenUsual` and `UsualAdd` store the earlier state, so Undo-after-Forget restores `askedOn` too. |
| B2 | A row that exists only for `asked_on` (no quiet, no rest) is a new kind of `suggestion_state` row. `SuggestionStateRepository.put` replaces whole rows. | A new method `markAsked(categoryId, day)` does update-else-insert in one transaction and touches only `asked_on`. `restore(previous)` in `RestoreUsual` must not wipe it: tested. |
| B3 | FR-HO-3 AC-4 says a line under a **door-opened tray** is "not asked"; E105 says it is "evaluated at the resume and drawn under the scrim". | The line is built from the evaluation but `HomeLinesShown` is never sent while `isCovered` is true. After the tray closes the line may only be removed (a close never evaluates). Tested. |
| B4 | "Home is ready … and no waiting, due-soon or install line holds the slot" is evaluated at the point. A bill line arriving at a later reload **outranks** the line (the money guarantee), then clears. | `HomePage._nudge` shows the bill line first. When it clears mid-day the slot collapses to empty and the missed-log line does **not** slide in (E108): `HomeLinesBloc` marks the point *resolved* at evaluation and only ever holds what it decided then. A line decided while a bill line held the slot is **not shown** (it waits for the next point). |
| B5 | "Now is at least 90 minutes after the window's end, on the window's own local date." A window ending before midnight with `now` past it is fine; with `now` on another date the index is stale. | `index.builtOn == today` is required (as the pill). The end is `window.start + window.length` minutes; a window that wraps (end ≤ start in minutes of day, or end ≥ 1440) never asks (E103). |
| B6 | AC-6: habit-derived Spends insights wait while the line shows, single pane only. BR-14 has **no** habit-derived insight today. | Nothing to build. Flagged: add the hook when the first habit insight exists. A test is not possible without the insight; the plan lists it as a gap, not a task. |
| B7 | FR-HO-3 AC-3: "after a save the collapse finishes no later than the drain" and "no haptic" on Back. The slot collapse motion is UI_DESIGN §6. | Use the existing `resize` token and `easeOut` via `AnimatedSize`; reduced motion is a 150 ms fade then height at once (habits/08 §9). Motion values are not re-decided here. |
| B8 | The neutral question glyph (P14-style) is not in `AppIcons`. | Add `AppIcons.questionLine` as a Hugeicons glyph (`strokeRoundedHelpCircle`) **if** it exists in the free set; if not, draw one in `HisaabGlyphs` per D48. `design-system` may swap it; the test asserts "not the category glyph". |

## Global constraints

Same as plan 1's *Global constraints* (money in `Money`; ARB with `@description`; tokens only; Bloc everywhere with `restartable()`/`droppable()` and a `// why:`; adaptive layout; Add path untouched; existing tests are the contract; no new dependency; local repo, commit only if asked; `BASE` from `git rev-parse HEAD`), plus:
- **Nothing logs a category name, an amount or an hour** (NFR-3, BR-17): failures log `runtimeType`.
- Banned words in the line's copy: "missed", "forgot", "didn't log", "we noticed", "AI", "suggestion". Voice: "usually", "around"; a no is a fine answer.
- Marigold never appears on the line. State is fill, outline and words.
- The only existing edits: `SuggestionGate.afterUndo/afterForget` (new field copied), `UsualSpendDetector._byRank` → `rank`, `HabitsBloc` untouched.

## The rules, resolved (what the tests pin)

| # | Rule | Definition |
|---|---|---|
| L1 | Candidate habit | `habit.dayType == DayType.of(today)`, `!habit.fading`, category in `categories` and `!hidden`, gate `open` (`SuggestionGate.statusOf`), `!index.loggedToday.contains(categoryId)` |
| L2 | After the window | `end = start + length` (minutes of the day, `TimeWindow`); the window **never crosses midnight** (`start + length ≤ 1440`); `nowMinute ≥ end + 90` and `nowMinute < 1440` on the same date as `index.builtOn` |
| L3 | One a day | No category's `state.askedOn == today`. The check is **over all categories**, not only the candidate |
| L4 | Pick | Among candidates, `UsualSpendDetector.rank` (higher share, later hit, lower id) |
| L5 | Output | `MissedLog({Category category, TimeWindow window, int aroundHour})` with `aroundHour` from `window.aroundHour` (BR-17 "around"), formatted by `UsualWords` (`DateFormat.j`, U+202F replaced) |
| L6 | Example | Food's window ends 2:00 pm: first shows at **3:30 pm**; at 1:50 pm nothing; at 3:29 pm nothing; at 3:30 pm shown |
| L7 | Slot | When a line was decided at a point it is held until a removal; a removal is permanent for the day (E104) |
| L8 | Removals | tap (after the tray closes), Back without saving (same), an entry logged in the category by any door, the category going quiet or forgotten, midnight. Nothing else |

## Review focus

1. **The 90-minute edge, to the minute** (L6). → Task 2.
2. **`asked_on` survives Undo, Forget and a pill add.** → Task 1.
3. **No pop-in**: habits loading after Home's first frame never produce a line that open (E106). → Task 5.
4. **A tray closing can only remove the line** (E105, AC-4). → Task 6.
5. **A bill line outranks it and does not hand the slot back** (E108). → Task 5.
6. **Back and tap write `asked_on` and nothing else**, so they never rest a habit. → Tasks 1, 6.

---

## File map

| File | Responsibility | Task |
|---|---|---|
| `lib/habits/domain/entities/suggestion_state.dart`, `lib/habits/data/{model/suggestion_state_model,mapper/suggestion_state_mapper,datasource/suggestion_state_local_data_source,repository/suggestion_state_repository_impl}.dart`, `lib/habits/domain/repository/suggestion_state_repository.dart`, `lib/habits/domain/suggestion_gate.dart`, `lib/habits/domain/usecase/mark_missed_log_asked.dart` (new), `test/helpers/fakes/fake_suggestion_state_repository.dart` | `askedOn`, `markAsked` | 1 |
| `lib/habits/domain/detectors/{missed_log_detector,usual_spend_detector}.dart`, `lib/habits/domain/entities/missed_log.dart` (new) | The rules | 2 |
| `lib/home/presentation/bloc/home_lines_{bloc,event,state}.dart` (new) | The slot's lower items | 3, 5, 6 |
| `lib/home/presentation/bloc/home_bloc.dart` | `isCovered` | 3 |
| `lib/home/presentation/widgets/missed_log_row.dart`, `missed_log_probe.dart` (new), `pages/home_page.dart`, `lib/core/design/app_icons.dart` | The row and the slot | 4, 7 |
| `lib/app/routes.dart`, `lib/app/main_screen.dart` | Points, tap, tray, carry | 5, 6 |
| `lib/habits/presentation/usual_words.dart` | "around {time}" reused | 4 |
| `lib/l10n/app_en.arb` | `missedLogTitle`, `missedLogBody` | 4 |
| `docs/…` | Sync | 9 |

---

### Task 0: Preflight

- [ ] `git rev-parse HEAD` → `BASE`. Confirm plan 1's Task 1 is in: `grep -n "asked_on\|askedOn" lib/core/db/db_schema.dart` shows `SuggestionStateColumns.askedOn`; `flutter test test/core/db` green. If not, **stop**: this plan does not create the migration.
- [ ] Confirm `AppDatabase.schemaVersion == 5` and `HomeBloc._holds` exists.
- [ ] Read `lib/app/app_shell.dart` and `lib/app/widgets/resume_listener.dart`, and write down in the report how the shell hides the inactive destination (needed in Task 7).

### Task 1: `asked_on` end to end (domain, data, gate regression)

**Files:** Modify the habits files in the file map; Create `lib/habits/domain/usecase/mark_missed_log_asked.dart`. Test: mirrors under `test/habits/…`.

**Interfaces**
- `SuggestionState.askedOn` (`Option<CalendarDate>`, default none, in `props`).
- `SuggestionStateModel.askedOn`, `toRow` and `fromRow` use `SuggestionStateColumns.askedOn`; the mapper converts `YYYY-MM-DD` ⇄ `CalendarDate`.
- `SuggestionStateLocalDataSource.setAskedOn(int categoryId, String iso)`: in one transaction, `UPDATE … SET asked_on` and, when 0 rows changed, `INSERT` a row with only `category_id` and `asked_on`. **Never** `ConflictAlgorithm.replace` (it would wipe the other columns).
- `SuggestionStateRepository.markAsked(int categoryId, CalendarDate day)` → `TaskEither<Failure, Unit>`.
- `MarkMissedLogAsked implements UseCase<Unit, int>`: reads `Clock.today()`.

- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'a row stores and reads asked_on; a v4-shaped row (no asked_on) reads none'` | BR-17, D172 |
| `'setAskedOn on a category with no row inserts a row with only asked_on'` | B2 |
| `'setAskedOn on a category with quiet, rest and forgotten keeps all three'` | B2 |
| `'setAskedOn twice keeps one row'` | |
| `'a state with only asked_on is gate-open: no quiet, no rest'` | BR-17 "never rests a habit" |
| `'afterUndo keeps askedOn'`, `'afterForget keeps askedOn'` | B1 |
| `'a pill add Undo, then Forget Undo: askedOn is back as it was'` (`RestoreUsual` with the earlier state) | B1, FR-SE-2 AC-6 |
| `'asking never counts as an Undo: quiet_on is unchanged and the 14-day count is the same'` | D172 |
| `'MarkMissedLogAsked writes today's date from the clock'` | D172 |
| `'asked_on is in a backup dump and restores'`; `'Delete everything clears it'` | BR-16 |
| `'a bad asked_on string is InvalidDataFailure'` | data-domain.md pitfall |

- [ ] **Step 2: Run** `flutter test test/habits test/backup` → fails. **Step 3: Implement**; update `FakeSuggestionStateRepository` (it `implements` the interface, so it breaks at compile time). **Step 4: Verify** green + `flutter analyze lib/habits test/habits`.

### Task 2: `MissedLogDetector` (pure Dart, test-first)

**Files:** Create `lib/habits/domain/detectors/missed_log_detector.dart`, `lib/habits/domain/entities/missed_log.dart`; Modify `usual_spend_detector.dart` (`rank` public), `lib/habits/habits.dart` (exports). Test: `test/habits/domain/detectors/missed_log_detector_test.dart`, `usual_spend_detector_test.dart` (existing, must stay green).

**Interface:** `abstract final class MissedLogDetector { static Option<MissedLog> suggest(HabitIndex index, {required DateTime now, required List<Category> categories}); }` (the day type comes from `now`, as the pill does).

- [ ] **Step 1: Failing tests** (`Chai`/Food fixtures from `chai_habit.dart`; window 9:45–10:45 and a 12:15–14:00 Food window for L6)

| Test | Cites |
|---|---|
| `'Food's window ends 2:00 pm: nothing at 1:50 pm, 3:29 pm; shown at 3:30 pm'` | BR-17 example, L6 |
| `'inside the window it never asks (the pill covers it)'` | E103 |
| `'a window across midnight never asks, at any time'` (23:15–00:45) | E103, B5 |
| `'a window ending at 23:30 is never asked (end + 90 passes midnight)'` | L2 |
| `'an entry in the category today (typed or posted) silences it'` | BR-17 rule 2, E65 |
| `'a fading habit is not asked'` | L1 |
| `'a hidden category or one not shown has no line'` | E59 |
| `'a quiet-today category has no line; a resting one has none; day 31 after a rest does'` | BR-17 gate, M17 of the your-usual plan |
| `'one asked today (any category) means no line for any'` | L3 |
| `'asked yesterday does not silence'` | L3 |
| `'two qualify: higher share of days wins, then later hit, then lower id'` | L4, BR-17 |
| `'a weekend habit is not asked on a weekday and the reverse'` | BR-17 |
| `'a pooled habit is asked on the day type it is offered on'` | E64 |
| `'a stale index (built yesterday) returns none'` | M18 |
| `'the around hour is the window's middle rounded up on a half hour'` | BR-17 "around" |
| `'the saved-yesterday note does not matter'` (no input) | D189 |
| `'a hidden-category fix never forms or feeds a habit'` (index built with a `not logged` entry: no habit appears; covered fully in plan 3, one smoke case here) | BR-17 |
| `UsualSpendDetector` suite unchanged | regression |

- [ ] **Step 2–4:** run (fails), implement (≤ 20-line private helpers, dartdoc, `// why:` on the strict `+ 90` and the midnight rule), verify `flutter test test/habits && flutter analyze`.

### Task 3: `HomeLinesBloc` state machine (pure events → states)

**Files:** Create `lib/home/presentation/bloc/home_lines_{bloc,event,state}.dart`; Modify `home_bloc.dart` (`isCovered` getter only); Test `home_lines_bloc_test.dart`.

**Interfaces**
- `HomeLinesBloc({required MarkMissedLogAsked markAsked, required Clock clock, required Haptics haptics})`.
- Events (sealed, `Equatable`): `HomeLinesPointReached` (marks the next `HomeReady` as an evaluation), `HomeLinesEvaluated(HomeLinesFacts facts)` (sent by the page glue when the first `HomeReady` arrives after a point; `facts` = `{HabitIndex? index, List<Category> categories, bool homeReady, bool noIncome, bool overState, bool billLineShowing, DateTime now}`), `HomeLinesShown` (visible; `droppable()`), `HomeLinesTapped` (`droppable()`: guards a second tap, AC-2), `HomeLinesTrayClosed({required bool saved})`, `HomeLinesEntryLogged(int categoryId)`, `HomeLinesGateClosed(int categoryId)`, `HomeLinesMidnight`.
- State: `HomeLinesState({Option<MissedLog> missed, bool asked, bool tapped, bool pointPending, bool resolved})`.

- [ ] **Step 1: Failing tests** (FakeClock, FakeSuggestionStateRepository)

| Test | Cites |
|---|---|
| `'before a point, nothing is decided'` | FR-HO-3 |
| `'a point then an evaluation with a qualifying habit puts the line in state'` | AC-1 |
| `'an evaluation in No income or an over state decides nothing and spends the point'` | AC-1, E107 |
| `'an evaluation while a bill line holds the slot decides nothing'` | B4, AC-1 |
| `'habits null at the evaluation: spent, no line, and a later habits load does not produce one'` | E106 |
| `'evaluating twice for one point is ignored'` | FR-HO-3 "never mid-view" |
| `'HomeLinesShown writes asked_on once and sets asked'` | AC-4 |
| `'Shown without a line writes nothing'` | |
| `'a tap: asked is written (if not yet), tapped true, tick haptic once; a second tap is dropped'` | AC-2 |
| `'TrayClosed(saved: false) after a tap removes the line and writes nothing more'` | AC-3, E104 |
| `'TrayClosed(saved: true) removes the line'` | AC-3 |
| `'a tray closing never decides a line'` | E105, AC-4 |
| `'EntryLogged in the line's category removes it; in another category does not'` | L8 |
| `'GateClosed (quiet or forget) removes it'` | L8 |
| `'midnight removes it and clears the point'` | L8 |
| `'a removed line never returns the same day, even after a delete of the entry'` | E104 |
| `'only HomeLinesEvaluated can add a line'` (property over all other events) | D170 |
| `'a failed asked write keeps the line state and logs only runtimeType'` | NFR-3 |

- [ ] **Step 2–4:** run, implement (`on<HomeLinesShown>(…, transformer: droppable())`, `on<HomeLinesTapped>(…, droppable())` with `// why:`), verify.

### Task 4: The row widget

**Files:** Create `lib/home/presentation/widgets/missed_log_row.dart`; Modify `lib/core/design/app_icons.dart` (B8), `lib/l10n/app_en.arb` (`missedLogTitle` "Spent on {category} today?", `missedLogBody` "Usually around {time}.", each with `@description`; spoken variant none), `lib/habits/presentation/usual_words.dart` only if a helper is missing. Test: `missed_log_row_test.dart`.

**Spec:** a `Pressable` sibling of `DueSoonRow`: `sunk` squircle(18), min 56dp, neutral question glyph in a `surface` well (**never the category's glyph**), two lines (the category name never cut), a chevron; pressed `hairline`; hovered or focused a 1dp `ink2` outline plus the focus ring; never marigold; no ×; one merged node, role button, "Spent on Food today? Usually around 1 pm.", hint `waitingOpensHint`; not a live region.

- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'shows the two lines and the neutral glyph, not the category glyph'` | AC (rest), T10 |
| `'is at least 56dp tall; at 1.5× and 2.0× text the lines wrap and the category name is not cut'` | FR-HO-3 |
| `'pressed fills hairline; hovered shows the ink2 outline; focused shows the ring; Enter and Space activate'` | habits/08 §3 |
| `'semantics: one button node "Spent on Food today? Usually around 1 pm." with the hint; no liveRegion'` | AC-5 |
| `'has no × and no swipe'` | habits/08 §4 |
| `'no marigold and no colour literal'` (token assertion through `context.colors`) | UI rules |
| `'at TestWindows smallPhone, phone, splitScreen, foldableUnfolded, tabletop the row is inside its pane and never straddles the fold'` | E-rows, CLAUDE adaptive layout |
| `'a Hindi-length or long custom category name wraps'` | FR-HO-3 |

- [ ] **Step 2–4:** run, implement, `flutter gen-l10n`, verify.

### Task 5: Slot assembly, evaluation points, no pop-in

**Files:** Modify `lib/home/presentation/pages/home_page.dart` (`_nudge` fourth branch), `lib/app/routes.dart` (provide `HomeLinesBloc` in `AppRoutes.main`; points from first build and `ResumeListener.onResume`; the glue `BlocListener<HomeBloc,…>` that sends `HomeLinesEvaluated` at the first `HomeReady` after a point), `lib/app/main_screen.dart`, `lib/home/home.dart` (exports). Tests: `home_page_slot_test.dart`, `routes_home_lines_test.dart`.

**Behaviour:** slot order is waiting → due-soon → (plan 3: install) → missed-log. The glue reads `HabitsBloc.state` **at that instant**; `HabitsLoading` ⇒ `index: null`. `facts.overState` uses `OverCard.appliesTo(summary)`; `billLineShowing` is `waitingBills.isNotEmpty || dueSoon.isSome`.

- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'cold start with habits and Home ready by the first Home frame: the line is in that frame'` | AC-1, E106 |
| `'habits load one frame after Home: no line this open, none appears later'` | E106 |
| `'a resume is an evaluation; a ledger tick, a rotation and a fold are not'` | D170 |
| `'the resume a door-opened tray causes is an evaluation'` | E105, FR-WG |
| `'a bill line holds the slot: the missed-log line is not shown; the bill line clears mid-day: the slot collapses to empty and the line does not slide in'` | E108, B4 |
| `'a bill line arriving at a later reload outranks a showing missed-log line'` | FR-HO-3 "Order stays stable" |
| `'in an over state and in No income the line waits (not shown), the foot slot and over card are unchanged'` | E107 |
| `'the saved-yesterday note above the slot never silences the line'` | D189 |
| `'no count and no badge ever shows'` | FR-HO-3 |
| `'midnight clears it'` | L8 |
| `'two panes: the line is in Home's pane only'` | habits/08 §3 |

- [ ] **Step 2–4:** run, implement, verify `flutter test test/home test/app && flutter analyze`.

### Task 6: Tap, the carried habit, asked and Back

**Files:** Modify `lib/app/routes.dart` (`openAddTray(..., Option<UsualSpend> carry = const Option.none())`; the line's `onTap`), `lib/home/presentation/widgets/missed_log_probe.dart` (new), `home_page.dart`. Tests: `routes_open_add_tray_test.dart`, `missed_log_flow_test.dart`.

**Behaviour:** tap = `tick` (once), `HomeLinesTapped`, `openAddTray(carry: Some(UsualSpend(category, amount)))` where the amount is the habit's (the row shows none). The tray opens at step 1, ₹0, *Spent*, today; the category is **not** pre-selected on step 2. The pill shows outside the window because `usual` is in the bloc's initial state (FR-AD-10 AC-1 clause). After the tray closes, `HomeLinesTrayClosed(saved: …)` goes in `finally` next to `holdingHome`'s release. A pill save from this tray is an ordinary one-tap add (BR-10 Undo, BR-17 quiet): unchanged.

- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'tap opens the tray at step 1 with the pill showing outside its window'` | AC-2, FR-AD-10 AC-1 |
| `'the line's category is not pre-selected on step 2; the tiles are not reordered; no tap is added'` | AC-2, Entry speed |
| `'a second tap before the tray closes opens one tray'` | AC-2 |
| `'Back (system, drag down, scrim) removes the line after the tray closes; no haptic; nothing written but asked_on'` | AC-3, E104 |
| `'a save from the tray (digits, Next, tile) removes the line; the collapse finishes no later than the drain'` | AC-3 |
| `'the pill tap saves the habit's amount; Undo quiets the category until midnight; the line stays gone'` | BR-17, BR-10 |
| `'asked_on is written only when the line is on screen with Home visible and no tray or sheet over it'` | AC-4, B3 |
| `'a door-opened tray: the line is drawn under the scrim, not asked; the tray close can only remove it'` | E105 |
| `'the line leaves when an entry is logged in its category by any door'` | AC-3, L8 |
| `'a category forgotten or gone quiet removes it'` | L8 |
| `'an entry deleted later today does not bring it back and no second question is asked'` | E104 |
| `'the widget, tile and shortcut never show the line and carry no habit'` | habits/08 §6, FR-WG |
| `'openAddTray without carry still runs the detector (regression)'` | existing |

- [ ] **Step 2–4:** run, implement, verify.

### Task 7: Visible-only asked, focus and the slot's collapse

**Files:** `missed_log_probe.dart`, `home_page.dart`; Tests `missed_log_probe_test.dart`, `missed_log_focus_test.dart`.

- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'Shown is sent once, post-frame, when covered is false, the route is current and Home is the visible destination'` | AC-4 |
| `'not sent while Spends is the destination in a single pane; sent in two panes'` | AC-4, D173 (uses Task 0's finding) |
| `'not sent under a bill sheet, the Add tray or Settings'` | AC-4 |
| `'when the line is removed after the tray it opened, focus goes to the "Today" heading, never the page top'` | FR-HO-3 Focus, X18 |
| `'when the tray closes and the line is still there, focus returns to the control that opened the tray'` | habits/08 §5 |
| `'TalkBack: no announcement when it appears or leaves'` | AC-5 |
| `'the slot collapse is an AnimatedSize with the resize token; reduced motion is a 150 ms fade then height at once'` | B7 |
| `'at 320×568, 412×400, landscape, book, tabletop the slot adds no horizontal scroll'` | E111 spirit |

- [ ] **Step 2–4:** run, implement (a `FocusNode` on the "Today" heading in `TodayList`: check it exists first; if not add one with a `// why:`), verify.

### Task 8: Backup, privacy, and the pill's regression

- [ ] Tests: `'asked_on round-trips a backup and is cleared by Delete everything'` (also in Task 1; here at the app level with `FakeServices`); `'nothing logs a category, hour or amount'` (`AppLogger` spy over the whole flow); `'the existing your-usual widget and bloc suites are green'`; `'asked_on never reaches Ask AI or the CSV'` (BR-17 "Ask AI never reads it").
- [ ] Wire DI: `MarkMissedLogAsked` in `habits_module.dart`; `HomeLinesBloc` in `routes.dart`; `FakeServices`.

### Task 9: Docs and final verification

- [ ] **Docs:** `docs/features/habits/08-missed-log-line.md` (status: built; B1 to B8); `04-ux-and-copy.md` status line per habits/08 §9; `docs/PLAN.md` M8 step 4 done; report B6. Do not edit SPEC/UI_DESIGN/DECISIONS.
- [ ] **Commands:** `flutter gen-l10n` · `flutter analyze` (clean) · `flutter test` (green) · `scripts/changed_lines_coverage.sh $BASE` (≥ 90%, gaps reasoned) · the `BRDA` awk for each changed file.
- [ ] **Device checks (08 §5 D15):** the line never appears mid-view on a cold start; TalkBack focus on removal; a door-opened tray over Home.

## Open questions

1. **B6** (no habit-derived insight to wait). Needs a product answer only when one is designed.
2. **A user who never opens Home between two windows** gets the question at the next point; `asked_on` is a date, so a question skipped by leaving the app counts as asked (habits/08 §1): confirm that "leaving the app" means the line was on screen first, which AC-4 already requires.
3. **The category's amount is not shown** on the line (the pill shows it). If the pre-release test says the line is read as an entry (T10), change the shape next, not the copy (habits/08 §3).
