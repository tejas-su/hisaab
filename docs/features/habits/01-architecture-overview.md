# Habits: architecture overview

> **Status: phase 1 built.** *Your usual* (D153, D154, D155; SPEC BR-17, BR-10, FR-AD-10, FR-SE-2 AC-6) is in `lib/habits/`; what was built is in `07-your-usual-build.md`. The missed-log question and the bill finder are still **Proposed** and not built. Tracked items are dropped (D138). Where this file or `02`–`06` differ from `07`, SPEC or the code, those win: the sections below marked *planned* record the design as first agreed.

## Purpose

Learn the user's own spending routine on the device and use it to make entry faster and more complete, without AI, network, settings or nagging. Three helpers:

| Helper | Screen | What it does | Status |
|---|---|---|---|
| Your usual | Add step 1 | A one-tap pill, "Chai ₹20 · your usual", in the slot under the amount | Built (phase 1) |
| Missed-log question | Home | "Spent on Food today? Usually around 1 pm." in Home's single note line | Proposed |
| Bill finder | Spends | "Gym ₹1,500 every month, around day 5" insight that opens the bill editor prefilled | Proposed |

Tracked items (`05-tracked-items.md`) were a fourth idea; they are dropped (D138) and nothing of them is built.

North-star metric: **days logged per pay cycle** (a day counts with at least one entry). Supporting measures: taps per entry, spare at payday. They are design and test targets only; nothing is collected (NFR-3).

## Layout

The built tree, with every file's job, is in `07-your-usual-build.md`. In short:

```
lib/habits/
├── habits.dart                      barrel; other features import only this
├── domain/
│   ├── habit_rules.dart             every threshold as a named constant
│   ├── time_profile.dart, usual_amount.dart, habit_index_builder.dart
│   ├── suggestion_gate.dart         quiet today / resting
│   ├── detectors/usual_spend_detector.dart
│   ├── entities/  repository/  usecase/
├── data/                            suggestion_state: data source, model, mapper, repository
├── presentation/                    HabitsBloc, UsualRowBloc, UsualAddedNotice, YourUsualRow, UsualWords
└── di/habits_module.dart
```

Not built, and different from the first plan: there is no `habit_rows_data_source` (entries are read through `LedgerRepository.entriesBetween`), no `habit_lifecycle.dart` (a habit is Regular or it is not in the index), no sealed `Suggestion`, and no detectors for the missed log, the bill finder or tracked items.

## Data flow

1. `HabitsBloc` loads when the main screen opens, on every ledger write (`LedgerRepository.changes`), on resume, at midnight and on the way back from Settings.
2. `GetHabitIndex` reads the last 56 days of entries, the categories and the `suggestion_state` rows, and `HabitIndexBuilder` turns them into a `HabitIndex` for today.
3. `AppRoutes.openAddTray` reads the bloc's state **synchronously** and runs `UsualSpendDetector.suggest(index, now, categories)`. `SuggestionGate` is applied inside the detector.
4. The result is handed to `AddEntryBloc`'s constructor, so the pill is in the tray's first frame or not shown at all (FR-AD-10 AC-1, NFR-1).

The full flows, with the Undo and *Forget*, are in `07-your-usual-build.md`.

## Dependencies

- Reads entries only through `lib/ledger/ledger.dart`.
- No new packages. Pure Dart for the maths; sqflite for one small state table (`suggestion_state`, schema v4).
- `fpdart` `Option` for "maybe a suggestion".

## Prerequisite fix (done)

`lib/ledger/data/repository/ledger_repository_impl.dart` keeps the original `created_at` in `replace` and `restore`, so editing or undo-restoring an entry no longer moves its time of day.

## Files in this folder

| File | Topic |
|---|---|
| `02-ideation-log.md` | How the idea evolved, approaches weighed, deviations, open questions |
| `03-detection-maths.md` | Query, weights, thresholds, both FSMs |
| `04-ux-and-copy.md` | Surfaces, slot priority, every string, voice rules |
| `05-tracked-items.md` | User-named tracked items and two-tap entry (dropped, D138; kept for the record) |
| `06-research-and-guardrails.md` | Research summary, dark-pattern line, sources |
| `07-your-usual-build.md` | What phase 1 built: files, data flow, states, failures |

The interactive mockup is `docs/design/mockups/40-your-usual.html`; the research behind it is `docs/design-research/case-studies/32-your-usual.md`.
