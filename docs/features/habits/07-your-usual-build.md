# Habits: what phase 1 built (your usual)

*Your usual* as it is in the code (D153, D154, D155). The rules are SPEC BR-17, BR-10, BR-16, FR-AD-1, FR-AD-10, FR-SE-2 AC-6 and E58–E71; the look is UI_DESIGN §5.3 and mockup 40. The missed-log question and the bill finder are not built.

## Source scope

- `lib/habits/**`
- `lib/core/db/migrations/migration_004_suggestion_state.dart`, `lib/core/db/migrations/migrations.dart`, `lib/core/db/db_schema.dart`
- `lib/add_entry/presentation/bloc/add_entry_{bloc,event,state}.dart`, `lib/add_entry/presentation/widgets/{usual_pill,usual_slot,amount_step}.dart`, `lib/add_entry/presentation/pages/add_entry_tray.dart`, `lib/add_entry/add_entry.dart`
- `lib/settings/presentation/pages/categories_page.dart`, `lib/settings/presentation/widgets/{category_sheet,category_sheet_summary}.dart`
- `lib/app/{routes,main_screen,app_services}.dart`, `lib/l10n/app_en.arb`

## Classes

| Class | File (under `lib/habits/` unless a path is given) | Layer | Responsibility |
|---|---|---|---|
| `HabitRules` | `domain/habit_rules.dart` | domain | Every threshold as a named constant (56 days, 14-day half-life, 5 hits, 3 of 5 days, 7 of 10 amounts, 30-day rest) |
| `TimeProfile`, `TimeWindow` | `domain/time_profile.dart`, `domain/entities/time_window.dart` | domain | 48 half-hour slots, recency weight, smoothing, the window around the busiest slot; the window may cross midnight |
| `UsualAmount` | `domain/usual_amount.dart` | domain | The one amount with at least 70% of the weighted hits |
| `HabitIndexBuilder` | `domain/habit_index_builder.dart` | domain | Entries, categories and states → `HabitIndex` for one day |
| `HabitIndex`, `UsualHabit`, `HabitInputs`, `DayType` | `domain/entities/` | domain | The Regular habits, the categories logged today, the stored states |
| `SuggestionGate`, `SuggestionState` | `domain/suggestion_gate.dart`, `domain/entities/suggestion_state.dart` | domain | Open, quiet today or resting; the state after an Undo and after *Forget* |
| `UsualSpendDetector`, `UsualSpend` | `domain/detectors/usual_spend_detector.dart`, `domain/entities/usual_spend.dart` | domain | `(HabitIndex, now, categories)` → `Option<UsualSpend>` |
| `GetHabitIndex`, `UndoUsualAdd`, `ForgetUsual`, `RestoreUsual` | `domain/usecase/` | domain | The four operations; `UsualAdd` and `ForgottenUsual` carry what an Undo needs |
| `SuggestionStateRepository` | `domain/repository/suggestion_state_repository.dart` | domain | `all`, `of`, `put`, `remove` |
| `SuggestionStateRepositoryImpl`, `SqfliteSuggestionStateLocalDataSource`, `SuggestionStateModel`, `SuggestionStateMapper` | `data/` | data | The `suggestion_state` table |
| `HabitsBloc` | `presentation/bloc/habits_bloc.dart` | presentation | Holds today's `HabitIndex` for the main screen; owns the Undo of a pill add |
| `UsualRowBloc` | `presentation/bloc/usual_row_bloc.dart` | presentation | One category sheet's *Your usual* row: the habit, *Forget*, its Undo |
| `UsualAddedNotice` | `presentation/widgets/usual_added_notice.dart` | presentation | "Added ₹20 to Chai" with *Undo* over Home or Spends |
| `YourUsualRow`, `UsualWords` | `presentation/widgets/your_usual_row.dart`, `presentation/usual_words.dart` | presentation | The Settings row and its words, "₹20, weekdays around 10 am" |
| `UsualPill`, `UsualSlot` | `lib/add_entry/presentation/widgets/` | presentation | The pill and the 48dp slot it shares with the spend preview |
| `registerHabitsServices` | `di/habits_module.dart` | DI | Registers the repository and the four use cases |

`habits.dart` exports the entities, the detector, the repository contract, the use cases, both blocs, the two widgets and the DI module. It does not export the data layer or `UsualWords`.

## Data

`suggestion_state` (migration 004, schema v4), one row per category:

| Column | Holds |
|---|---|
| `category_id` | Primary key; references `categories(id)` and is deleted with it |
| `quiet_on` | The day of the last Undo after a pill add (`YYYY-MM-DD`) |
| `rest_until` | The last day of a rest (`YYYY-MM-DD`) |
| `forgotten_at` | When *Forget* was tapped, a local ISO timestamp |

Habits are never stored. The backup dumps every table, so the states travel with a backup and are wiped by *Delete everything* (BR-16) with no backup code changed.

## Flow: loading the habits

1. `AppRoutes.main` provides `HabitsBloc` with `lazy: false` and adds `HabitsLoadRequested`.
2. The same event is added on every `LedgerRepository.changes` tick (inside the bloc), on resume, at midnight (`MidnightListener` in the route) and when Settings closes.
3. `GetHabitIndex` reads `entriesBetween(today − 55, today)`, `CategoryRepository.all()` and `SuggestionStateRepository.all()`, then calls `HabitIndexBuilder.build`.
4. The bloc emits `HabitsReady(index)`. A failed load logs the failure's type and keeps the state it had.

## Flow: the pill

1. `AppRoutes.openAddTray` reads `HabitsBloc.state`. When it is `HabitsReady`, the tray is new and on *Spent*, it runs `UsualSpendDetector.suggest` with `Clock.now()` and Home's categories.
2. The detector returns a habit only when the index was built today, the habit is of today's day type and not fading, now is inside its window, its category is shown, nothing is logged in it today and its gate is open. With two, the higher share of days wins, then the later hit, then the lower id.
3. The `Option<UsualSpend>` goes into `AddEntryBloc(usual: …)`, so it is in the bloc's first state. No event ever adds one.
4. `UsualSlot` shows `UsualPill` while `form.usual` is some, else `SpendPreviewLine`. Any digit, chip, ⌫ or kind switch clears `usual`.
5. A tap adds `AddEntryUsualPicked` (`droppable()`). The bloc saves through `SaveEntry` and emits `AddEntrySaving`, then `AddEntryFinished(added: some(entry))`; the tray closes.
6. Back in `openAddTray`, the saved entry is handed to `HabitsBloc` as `HabitsUsualAdded(UsualAdd(entry, category))`.
7. `UsualAddedNotice` shows the snackbar. *Undo* adds `HabitsUsualUndoRequested`; `UndoUsualAdd` stores the quiet state **first**, then deletes the entry, so the reload the delete starts already sees the category quiet.

## Flow: Settings › Categories › a category

1. `AppRoutes.categories` gives `CategoriesPage` a `usualRow` builder. The page passes it to `CategorySheet.show` for *Spent* categories only.
2. The sheet's summary builds the row under the Name and Icon card. The builder makes a `UsualRowBloc` for that category and adds `UsualRowLoadRequested`.
3. The bloc shows `index.habitFor(categoryId, preferring: today's day type)`. A fading or resting habit is still shown, so it can be forgotten.
4. *Forget* runs `ForgetUsual` (`forgotten_at = now`, a 30-day rest) and emits `UsualRowForgotten`. `YourUsualRow` shows "Forgotten" with *Undo* in the sheet's own `HisaabSnackbarHost`.
5. *Undo* runs `RestoreUsual` (the earlier row is put back, or removed when there was none) and reloads.
6. Opening the name or icon question closes "Forgotten": the row and its bloc are gone with the summary.

## States

| Bloc | State | Means |
|---|---|---|
| `HabitsBloc` | `HabitsLoading` | No index yet; a tray opened now has no pill, then or later |
| | `HabitsReady(index, added)` | Today's habits; `added` is some only in the one state that offers the Undo |
| `UsualRowBloc` | `UsualRowEmpty` | No Regular habit, not loaded yet, or the load failed: no row |
| | `UsualRowShown(habit)` | The row with *Forget* |
| | `UsualRowForgotten(forgotten)` | Row gone; "Forgotten" with *Undo* is showing |
| `AddEntryBloc` | `AddEntryEditing(failed: true)` with `form.usual` | The pill save failed; the pill reads "Couldn't save. Try again." and a tap tries again |

## Failures

| Where | What happens |
|---|---|
| Habits load | Type logged (`habits.load_failed`); the last index stays. A first load that fails leaves no pill |
| Pill save | The tray stays open on step 1, reject haptic, the pill shows the retry line (when it fits; SPEC Q8) |
| Undo of a pill add | A state write that fails deletes nothing. An entry already gone still leaves its category quiet |
| *Forget* | A failed write keeps the row |
| Undo of *Forget* | A failed write leaves the habit forgotten; the row stays away |

Nothing about a habit is logged except a failure's type (NFR-3).

## Known limits

- Short phones, the failed-save line at large text, and the crossfade under reduced motion: SPEC §7 Q7 to Q9.
- A tray opened before the first habits load (a cold start from the app shortcut or tile) has no pill; FR-WG-6/7 decide that later.
- A pre-existing `AnimatedSize` assertion under reduced motion in `add_entry_tray.dart` is recorded in D155 and not fixed here.
