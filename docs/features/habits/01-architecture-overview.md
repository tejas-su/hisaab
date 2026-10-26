# Habits: architecture overview

> **Status: planned, not built.** Nothing here exists in `lib/` yet. This folder records the design agreed so far; open items are marked **Proposed**. SPEC, UI_DESIGN and DECISIONS are updated only once the design is approved (see `02-ideation-log.md`).

## Purpose

Learn the user's own spending routine on the device and use it to make entry faster and more complete, without AI, network, settings or nagging. Three helpers, plus user-named tracked items:

| Helper | Screen | What it does |
|---|---|---|
| Your usual | Add step 1 | A one-tap pill, "Food ₹55 · your usual", in the line under the amount |
| Missed-log question | Home | "Spent on Food today? Usually around 1 pm." in Home's single note line |
| Bill finder | Spends | "Gym ₹1,500 every month, around day 5" insight that opens the bill editor prefilled |
| Tracked items | Add step 2, Spends | Up to 4 named items (e.g. Cigarettes) inside a category, as a third row of identical tiles set slightly apart; see `05-tracked-items.md` |

North-star metric: **days logged per pay cycle** (a day counts with at least one entry). Supporting measures: taps per entry, spare at payday. They are design and test targets only; nothing is collected (NFR-3).

## Planned layout

```
lib/habits/
├── habits.dart                      barrel; other features import only this
├── domain/
│   ├── habit_index.dart             immutable aggregate built from entries
│   ├── habit_index_builder.dart     rows + Clock → HabitIndex (decay, smoothing)
│   ├── habit_lifecycle.dart         FSM 1, derived, never stored
│   ├── detectors/                   one pure class per helper
│   │   ├── usual_spend_detector.dart
│   │   ├── missed_log_detector.dart
│   │   ├── bill_candidate_detector.dart
│   │   └── tracked_item_candidate_detector.dart
│   ├── suggestion.dart              sealed: UsualSpend, MissedLog, BillCandidate, TrackedItemCandidate
│   └── suggestion_gate.dart         FSM 2: shown / not today / resting
├── data/
│   ├── habit_rows_data_source.dart  the grouped SQL read
│   └── suggestion_state_*           sqflite table for FSM 2
└── di/habits_module.dart
```

## Data flow

1. Any ledger write (BR-10 "ledger notifies listeners") or app resume (BR-8) triggers a background rebuild.
2. `habit_rows_data_source` runs one grouped query over the last 56 days (see `03-detection-maths.md`).
3. `HabitIndexBuilder` turns rows into a `HabitIndex` using the injected `Clock`.
4. Each detector maps `(HabitIndex, now)` to `Option<Suggestion>`. Detectors never import each other or Flutter.
5. `SuggestionGate` drops anything that is resting or already dismissed today, and freezes the day's suggestion.
6. The result is cached. `AddEntryBloc` and `HomeBloc` read it **synchronously**, so a suggestion is in the first frame or not shown that session (NFR-1: tray opens ≤ 150 ms).

## Dependencies

- Reads entries only through `lib/ledger/ledger.dart`.
- No new packages. Pure Dart for the maths; sqflite for one read query and one small state table.
- `fpdart` `Option` for "maybe a suggestion".

## Prerequisite fix

`lib/ledger/data/repository/ledger_repository_impl.dart` re-stamps `createdAt: _clock.now()` in `replace` and `restore`. Editing or undo-restoring an entry therefore moves its time of day, which would teach wrong habits. Fix first: keep the original `created_at` on edit and restore.

## Files in this folder

| File | Topic |
|---|---|
| `02-ideation-log.md` | How the idea evolved, approaches weighed, deviations, open questions |
| `03-detection-maths.md` | Query, weights, thresholds, both FSMs |
| `04-ux-and-copy.md` | Surfaces, slot priority, every string, voice rules |
| `05-tracked-items.md` | User-named tracked items and two-tap entry |
| `06-research-and-guardrails.md` | Research summary, dark-pattern line, sources |

Plain-language overview with mockups (local draft): `/tmp/claude-1001/-home-tejassu-Desktop-expense-tracker/22244bc3-465e-4f06-8eac-377b966297e6/scratchpad/smart-habits-plan.html`.
