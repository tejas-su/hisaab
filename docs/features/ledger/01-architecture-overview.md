# Ledger Architecture Overview

**Status:** built in M1; M2 added bill rules (`GetBills`, `AddBill`, `EditBill`, `DeleteBill`, `RestoreBill`) and the due-soon nudge (`GetDueSoonBill`). Category limits, insights and budget suggestions (BR-12, BR-14) land with Spends in M4.

## 1. Purpose
The ledger is the shared money feature. It owns entries, categories and recurring rules, and the pure maths that turns them into today's share. Every UI feature reads money data through `lib/ledger/ledger.dart` and nothing else.

## 2. Entry point
- No page of its own. Other features import the barrel `lib/ledger/ledger.dart`.
- `registerLedgerServices` (`lib/ledger/di/ledger_module.dart`) registers the repositories and use cases; `lib/app/app_services.dart` calls it at start-up.

## 3. Data flow
```
HomeCubit / AddEntryCubit / CompleteOnboarding
  → SaveEntry / DeleteEntry / RestoreEntry / GetCycleSummary / PostDueRecurring   (domain/usecase/)
    → LedgerRepository / CategoryRepository / RecurringRepository / BudgetSettingsRepository
      → Sqflite*LocalDataSource (rows) → *Model.fromRow → *Mapper.toEntity
  ← TaskEither<Failure, T>
GetCycleSummary
  → PayRuleSchedule.payRuleOf(salary rule)        BR-1 (no salary rule → calendar month)
  → PeriodCalculator.cycleFor(today, rule, monthStart)
  → SafeToSpend.compute(CycleInputs)              BR-3..BR-7 → CycleSummary
Every write → LedgerRepository.changes (Stream<void>) → HomeCubit reloads   BR-10
Rule edits  → RecurringRepository.changes → HomeCubit, BillsCubit reload
```

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `Entry`, `EntryDraft`, `EntryKind` | `domain/entities/` | A saved entry (with `createdAt`, set once on add and kept by edit and Undo), an unsaved one, *Spent*/*Got* |
| `Category`, `CategoryKeys` | `domain/entities/category.dart` | Fixed seed buckets (BR-11) |
| `RecurringRule`, `RecurringDraft`, `Schedule`, `Frequency` | `domain/entities/` | Rules and their schedule (BR-9) |
| `CycleSummary`, `CycleState`, `RangeForecast`, `SpendPreview` | `domain/entities/` | Today's answer, BR-5 states, BR-7 forecast, FR-AD-3 preview |
| `SafeToSpend` | `domain/safe_to_spend.dart` | Pure BR-3..BR-7 and the Add preview; shares floor to whole rupees |
| `RecurringSchedule` | `domain/recurring_schedule.dart` | Next date, first date on/after a day, dates in a range; clamps like BR-1 |
| `PayRuleSchedule` | `domain/pay_rule_schedule.dart` | `PayRule` ↔ salary `Schedule` (DECISIONS D20) |
| `EntryValidator` | `domain/entry_validator.dart` | BR-10: ₹1..₹99,99,99,999, no future date, trimmed note ≤ 80 |
| `SaveEntry`, `DeleteEntry`, `RestoreEntry` | `domain/usecase/` | Add or replace, delete (returns the entry), undo |
| `GetCycleSummary` | `domain/usecase/get_cycle_summary.dart` | Loads settings, rules and the cycle's entries; computes `B` from rules |
| `PostDueRecurring` | `domain/usecase/post_due_recurring.dart` | The recurring engine (see `recurring-engine`) |
| `GetDueSoonBill` | `domain/usecase/get_due_soon_bill.dart` | FR-HO-3 nudge |
| `GetBills`, `AddBill`, `EditBill`, `DeleteBill`, `RestoreBill` | `domain/usecase/` | Settings' fixed bills (FR-SE-1, DECISIONS D33–D35) |
| `BillInput`, `BillKind`, `BillValidator` | `domain/` | A typed bill; the common-bill chips and their category; name 1–40, amount as BR-10, day 1–31 |
| `*RepositoryImpl` | `data/repository/` | `dbTask` wraps data sources; `LedgerRepositoryImpl` and `RecurringRepositoryImpl` own `changes` |
| `Sqflite*LocalDataSource` | `data/datasource/` | The only code touching `AppDatabase` |
| `*Model`, `*Mapper`, `EntryKindMapper` | `data/model/`, `data/mapper/` | `is`-narrowed rows (`core/db/db_row.dart`) ↔ entities |
| `CategoryExtensions.labelIn` | `presentation/category_extensions.dart` | Rename or localised seed name |

## 5. State variants
No UI state. Consumers switch on `CycleState` (`NoIncome`, `OverCycle`, `OverToday`, `SlowDown`, `OnTrack`) and `RangeForecast` (`TooEarlyToForecast`, `LastsTillPayday`, `RunsOut`).

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` (core) | sqflite threw |
| `InvalidDataFailure` (core) | A stored row, currency, kind, frequency, date or setting can't be read |
| `InvalidAmountFailure` | Amount under ₹1 or over 9 digits |
| `FutureDateFailure` | Entry dated after today |
| `NoteTooLongFailure` | Note over 80 characters after trimming |
| `EntryNotFoundFailure` | Edit or delete of a missing id |
| `RuleNotFoundFailure` | Edit, delete or restore of a missing or stopped rule |
| `InvalidBillNameFailure` | Bill name blank or over 40 characters |

## 7. External dependencies
- **Core:** `Money`, `CurrencySpec.fromCode`, `AmountInput`, `CalendarDate`, `Clock`, `PeriodCalculator`, `PayRule`, `AppDatabase`, `db_row.dart`, `Failure`, `UseCase`.
- **Packages:** `sqflite`, `fpdart`, `equatable`, `get_it` (module only).

## 8. Design spec
`docs/SPEC.md` BR-1 to BR-11, E1–E9, E11; `docs/UI_DESIGN.md` §3.3 and §8.

## 9. Known limitations / TODOs
- One currency only; `currency` is stored per row.
- Restoring an entry whose id was reused is a `DatabaseFailure` (ids are AUTOINCREMENT, so this can't happen in normal use).
- `B` is computed from rules on every load; fine for a handful of rules.
