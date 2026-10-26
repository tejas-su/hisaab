# Recurring Engine Architecture Overview

**Status:** planned (milestone M2), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
The recurring engine posts salary and fixed bills automatically on their due dates, including every occurrence missed while the app was closed. A double run, a crash mid-run or two racing launches never double-posts. The code lives in `lib/ledger/`; this doc covers it separately because it is a behaviour of its own (`.claude/rules/feature-docs.md`).

## 2. Entry point
- `RecurringTrigger` in `lib/app/` calls `PostDueRecurring` at these moments:
  - **App start**, before Home's first load.
  - **Resume**, via `AppLifecycleListener.onResume`.
  - **Local midnight** while the app is open, via a timer re-armed each day (BR-8).
- Onboarding also calls it once when it finishes (FR-ON-5).

## 3. Data flow
```
RecurringTrigger.run()
  → PostDueRecurring(today: clock.today())                  lib/ledger/domain/usecase/post_due_recurring_usecase.dart
    → RecurringRepository.activeRules()
    → for each rule: NextDue.occurrencesUpTo(rule, today)    pure; clamps monthly dates like BR-1
    → RecurringRepository.postDue(occurrences)
      → RecurringLocalDataSource.postDue                    one db.transaction:
          insert each entry with ConflictAlgorithm.ignore   unique (recurring_id, date)
          update recurring.next_due = last + 1 period
  → TaskEither<Failure, PostResult(postedCount)>
  → LedgerRepository.changes emits when postedCount > 0 → Home and Spends recompute
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `PostDueRecurring` | `lib/ledger/domain/usecase/` | Runs BR-9 for `today`; returns how many entries were posted |
| `NextDue` | `lib/ledger/domain/next_due.dart` | Pure: lists the occurrence dates in `[nextDue, today]` and the next `nextDue`; weekly / every 2 weeks / monthly (clamped) / yearly |
| `Occurrence` | domain/entities | `(ruleId, date, Money, kind, categoryId)` to be posted |
| `PostResult` | domain/entities | `postedCount`, used to decide whether to notify |
| `GetNextDueBill` | domain/usecase | The soonest unposted *Spent* occurrence within 5 days, for the Home nudge (BR-9) |
| `RecurringRepository` / `Impl` | domain / data | `activeRules`, `postDue`, CRUD for Settings |
| `RecurringLocalDataSource` | data/datasource | The transaction with insert-ignore and the `next_due` update |
| `RecurringTrigger` | `lib/app/recurring_trigger.dart` | Lifecycle and midnight wiring; the only place that schedules runs |

## 5. State variants
- No UI state.
- `PostResult` is the only output.
- Errors surface through the next `GetCycleSummary` load. Home still renders the last good summary.

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | The posting transaction failed; it rolls back as a whole, so a later run retries cleanly |

## 7. External dependencies
- **Ledger:** `RecurringRepository`, `LedgerRepository.changes`.
- **Core:** `Clock`, `PeriodCalculator` (date clamping helpers), `AppDatabase`.
- **Flutter:** `AppLifecycleListener` (in `lib/app/` only).

## 8. Design spec
- Behaviour: `docs/SPEC.md` BR-8, BR-9, plus E7, E8 and E9 (date moved backwards: `next_due` never moves back and nothing is un-posted).
- Nudge copy: `docs/UI_DESIGN.md` §5.2 and §8.

## 9. Known limitations / TODOs
- Posts are dated on their due date, not on the day the app opened, so a catch-up can change past `S_prev` and therefore today's `A` (intended by BR-3).
- No notification reminders in v1. The nudge appears only inside the app.
- Edit semantics: changing a rule's amount affects only future posts (BR-9). Changing the anchor date must recompute `next_due` without re-posting past dates; this needs a test.
