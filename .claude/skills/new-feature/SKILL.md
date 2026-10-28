---
name: new-feature
description: Scaffold a complete new feature under lib/<feature_name>/ following Hisaab's clean architecture (domain/data/presentation, Bloc, barrel file, tests). Use when the user asks to create, add, or scaffold a new feature or module.
argument-hint: "Feature name (e.g. add_entry, ask_ai)"
---

Scaffold a complete new feature for Hisaab.

**Feature name**: $ARGUMENTS

Before generating anything, read the feature's section in `docs/UI_DESIGN.md` (screens, states, copy) and its milestone in `docs/PLAN.md`. The scaffold must match the spec, not a generic template.

## What to generate

Create only the layers the feature needs. A UI feature that reads money data usually has no `data/` of its own; it depends on `lib/ledger/` through `ledger.dart`.

```
lib/<feature_name>/
├── <feature_name>.dart                          ← barrel file, exports public API only
│
├── domain/                                      ← only if the feature owns business logic
│   ├── entities/<feature_name>_entity.dart      ← immutable, pure Dart, Equatable
│   ├── repository/<feature_name>_repository.dart← abstract interface only
│   └── usecase/<verb>_<noun>_usecase.dart       ← single call(), returns TaskEither<Failure, T>
│
├── data/                                        ← only if the feature owns tables
│   ├── datasource/<feature_name>_local_data_source.dart  ← interface + sqflite impl
│   ├── model/<feature_name>_model.dart          ← fromRow/toRow (and toJson for backup)
│   ├── mapper/<feature_name>_mapper.dart        ← toEntity(model), toModel(entity)
│   └── repository/<feature_name>_repository_impl.dart
│
└── presentation/
    ├── pages/<feature_name>_page.dart           ← page widget, receives its bloc from the route
    ├── widgets/                                 ← one widget per file
    └── bloc/
        ├── <feature_name>_bloc.dart
        ├── <feature_name>_event.dart            ← sealed events, past tense
        └── <feature_name>_state.dart            ← sealed states

test/<feature_name>/                             ← mirrors lib/<feature_name>/ (see .claude/rules/tests.md)
├── domain/usecase/<verb>_<noun>_usecase_test.dart
├── data/mapper/<feature_name>_mapper_test.dart
├── data/model/<feature_name>_model_test.dart    ← fromRow incl. null/missing/wrong-typed columns
├── data/repository/<feature_name>_repository_impl_test.dart
├── presentation/bloc/<feature_name>_bloc_test.dart
└── presentation/pages/<feature_name>_page_test.dart   ← each state renders; key taps add the right event
test/helpers/fakes/fake_<feature_name>_repository.dart
```

## Core layer — reuse, don't recreate

Check `lib/core/` first:

| Need | Where it lives |
|------|----------------|
| Base `Failure` sealed class | `core/errors/` — extend it; do not redefine it |
| Abstract `UseCase<T, Params>` | `core/usecases/` — implement it |
| Database | `core/db/AppDatabase` — inject it into data sources; add a migration for new tables |
| Money and formatting | `core/money/` — `Money`, `MoneyFormatter` |
| Today, cycles, paydays | `core/time/` — `Clock`, `PeriodCalculator` |
| Colours, type, motion, haptics, icons | `core/design/` — tokens only |
| Shared UI (Keypad, AmountText, DayBlocks, SignalKey, Tray, CategoryTile) | `core/widgets/` — import; do not duplicate |
| Logging | `core/logging/AppLogger` |

Create files in `core/` **only** when logic is genuinely shared across two or more features. If `lib/core/` or a required dependency (`fpdart`, `animations`) doesn't exist yet, say so and ask before creating or adding it.

## Rules for every generated file

- **Entity**: `const` constructor, immutable fields, extends `Equatable`; money as `Money`, days as calendar dates
- **Model**: `fromRow(Map<String, Object?>)` with `is`-narrowed columns, `toRow()`; typed fields (no `dynamic`)
- **Mapper**: pure static methods `toEntity` / `toModel`, no side effects
- **Repository interface**: one method per operation, returns `TaskEither<Failure, T>`
- **Repository impl**: constructor-injected data source; wrap calls with `TaskEither.tryCatch(..., (err, st) => DatabaseFailure(err))`; multi-row writes in one transaction
- **Use case**: single `call(Params)` returning `TaskEither<Failure, T>`; calls repositories and pure domain functions only; no `.run()`
- **State**: `sealed` class; variants named for the UI situation (e.g. `Initial`, `Loading`, `Ready`, `Failed`), `Equatable`
- **Event**: `sealed` class; one `final class` per user intent or trigger, past tense (`<Feature>LoadRequested`, `<Feature>SaveRequested`), `Equatable`
- **Bloc**: thin; one `on<Event>` handler per event, calling use cases; `restartable()` on loads, `droppable()` on saves, each with a test that fails without it (see `.claude/rules/bloc.md`)
- **Page**: receives its bloc/dependencies through its constructor from `lib/app/routes.dart`; provides the bloc via `BlocProvider.value`
- **Widgets**: tokens only (`HisaabColors`, theme `TextTheme`, motion/haptics wrappers, `AppIcon`); all copy from `AppLocalizations`, all amounts from `MoneyFormatter`
- **Strings**: add every new user-facing string to `lib/l10n/app_en.arb` (with `@` metadata for placeholders/plurals) and run `flutter gen-l10n`
- **DI**: register implementations in `lib/core/di/`; nothing below the route calls `GetIt.I`
- **Route**: register in `lib/app/routes.dart`
- **Barrel file**: exports only the page and public-facing entities; never internal data/mapper files

## After generating files

1. List every file created with its path, then run `flutter gen-l10n`, `flutter analyze` and `flutter test test/<feature_name>/`
2. Point out anything still stubbed (copy awaiting a decision, a migration not yet written)
3. Note further use cases the feature will need
