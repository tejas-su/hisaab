# Ledger Architecture Overview

**Status:** planned (milestone M0–M2), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
The ledger is the shared money feature. It owns entries, categories and recurring rules, and the pure maths that turns them into today's share. Every UI feature reads money data through `lib/ledger/ledger.dart` and nothing else.

## 2. Entry point
- There is no page of its own.
- Other features import the barrel `lib/ledger/ledger.dart`.
- Repositories and use cases are registered in `lib/core/di/` and handed to pages by `lib/app/routes.dart`.

## 3. Data flow
```
Feature cubit (HomeCubit, AddEntryCubit, SpendsCubit…)
  → SaveEntry / DeleteEntry / GetCycleSummary            (lib/ledger/domain/usecase/)
    → LedgerRepository / CategoryRepository / RecurringRepository / BudgetSettingsRepository
      → EntriesLocalDataSource, CategoriesLocalDataSource,
        RecurringLocalDataSource, SettingsLocalDataSource  (sqflite via AppDatabase)
        → *Model.fromRow → *Mapper.toEntity → entity
  ← TaskEither<Failure, T>
GetCycleSummary
  → PeriodCalculator.cycleFor(today, payRule, monthStart)  (lib/core/time/)   BR-1, BR-2
  → SafeToSpend.compute(inputs)                             (lib/ledger/domain/)  BR-3..BR-7
  → CycleSummary
Writes → LedgerRepository.changes (Stream<void>) → listening cubits re-run GetCycleSummary   BR-10
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `TransactionEntity` | `lib/ledger/domain/entities/` | One *Spent*/*Got* entry: `Money`, kind, category id, calendar date, note, optional recurring id |
| `CategoryEntity` | domain/entities | Name, icon key, kind, fixed sort order, optional limit (BR-11, BR-12) |
| `RecurringRuleEntity` | domain/entities | Amount, kind, category, frequency, anchor date, `nextDue`, active (BR-9) |
| `CycleSummary` | domain/entities | Cycle dates, `D`, `P`, `A`, `safeToday`, `overToday`, `tomorrow`, state, forecast |
| `SafeToSpend` | `lib/ledger/domain/safe_to_spend.dart` | Pure computation of BR-3 to BR-7; no I/O, takes `today` as a parameter |
| `CycleState` | domain | Sealed: `NoIncome`, `OverCycle`, `OverToday`, `SlowDown`, `OnTrack` (BR-5) |
| `RangeForecast` | domain | Sealed: `Hidden`, `LastsTillPayday(spare)`, `RunsOut(date)` (BR-7) |
| `LedgerRepository` | domain/repository | `save`, `delete`, `entriesBetween`, `changes` stream |
| `CategoryRepository` | domain/repository | `all(kind)`, `rename`, `setIcon`, `setLimits` |
| `RecurringRepository` | domain/repository | Rules CRUD, `dueOn(today)`, `postDue(occurrences)` (see `recurring-engine`) |
| `BudgetSettingsRepository` | domain/repository | Month start, keep aside |
| `SaveEntry` | domain/usecase | Validates BR-10 (amount range, no future date, note ≤ 80) and saves or replaces |
| `DeleteEntry` | domain/usecase | Deletes and returns the entity so Undo can re-save it |
| `GetCycleSummary` | domain/usecase | Loads the inputs for the cycle containing `today`, then runs `SafeToSpend` |
| `InsightRules`, `BudgetSuggester` | domain | Pure rules for BR-14 and BR-12, consumed by `spends` |
| `LedgerRepositoryImpl` (+ others) | `lib/ledger/data/repository/` | Wraps data sources in `TaskEither.tryCatch`; emits on `changes` after each write |
| `*LocalDataSource` | data/datasource | Only classes touching `AppDatabase`; raw rows in and out |
| `*Model`, `*Mapper` | data/model, data/mapper | `fromRow`/`toRow` with `is`-narrowed columns; model ↔ entity |
| `AppDatabase` | `lib/core/db/` | Opens sqflite, runs versioned migrations in `core/db/migrations/` |

**Tables** (PLAN §8): `categories`, `transactions`, `recurring`, `settings`.
- Indexes: `transactions(date)`, `transactions(category_id, date)`.
- **Unique** index: `transactions(recurring_id, date)`.

## 5. State variants
The ledger has no UI state. It hands consumers the following sealed results:

| Type | Variants | Maps to |
|---|---|---|
| `CycleState` | `NoIncome`, `OverCycle`, `OverToday`, `SlowDown`, `OnTrack` | Home hero and Day Blocks (BR-5) |
| `RangeForecast` | `Hidden`, `LastsTillPayday`, `RunsOut` | Home range line (BR-7) |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` (core) | A sqflite read or write threw |
| `NoIncomeFailure` | No *Got* entry and no recurring income, so no cycle can be computed (BR-5 #1, E10) |
| `InvalidAmountFailure` | Amount ≤ 0 or more than 9 digits (BR-10) |
| `FutureDateFailure` | Entry dated after today (BR-10) |
| `EntryNotFoundFailure` | Edit or delete of an id that no longer exists |

## 7. External dependencies
- **Core:** `Money`, `CurrencySpec` (`core/money`), `Clock`, `PeriodCalculator`, `PayRule` (`core/time`), `AppDatabase` (`core/db`), `Failure`, `UseCase`, `AppLogger`.
- **Packages:** `sqflite`, `path`, `fpdart` (M0), `equatable`.

## 8. Design spec
- Behaviour: `docs/SPEC.md` BR-1 to BR-14, plus edge cases E1–E9.
- Copy that the ledger's results feed: `docs/UI_DESIGN.md` §3.3 (states) and §8 (voice, amounts).

## 9. Known limitations / TODOs
- One currency only. `currency` is stored per row so multi-currency needs no migration (PLAN §5).
- Category order and count are fixed in v1 (BR-11).
- Undo after delete re-saves the returned entity with the same id. Confirm that this keeps `recurring_id` and the unique index intact.
- Decided (DECISIONS D20): one `settings` key-value table. `BudgetSettingsRepository` (ledger) owns `currency`, `month_start` and `keep_aside_minor`; `AppPreferencesRepository` (settings feature) owns the theme and onboarding keys.
