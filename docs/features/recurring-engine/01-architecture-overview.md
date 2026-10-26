# Recurring Engine Architecture Overview

**Status:** built in M1 (start and resume triggers). The midnight timer (BR-8) and the due-soon nudge (FR-HO-3) are M2.

## 1. Purpose
Posts salary and fixed bills on their due dates, including every occurrence missed while the app was closed. A repeat run, a crash mid-run or two racing runs never double-post. The code lives in `lib/ledger/`.

## 2. Entry point
`PostDueRecurring` runs:
- at the start of every `HomeCubit.load()`: app start, every ledger write, and resume (`ResumeListener` in `lib/app/main_screen.dart`);
- once when onboarding finishes (`CompleteOnboarding`).

## 3. Data flow
```
PostDueRecurring(NoParams)                         lib/ledger/domain/usecase/post_due_recurring.dart
  → RecurringRepository.activeRules()
  → RecurringSchedule.datesFrom(rule.schedule, rule.nextDue, through: today)   pure
  → RecurringPosting(occurrences, nextDueByRuleId)  nothing due → returns 0, no write
  → RecurringRepositoryImpl.post
      EntryValidator.validate each occurrence       OR IGNORE would hide a CHECK failure
      SqfliteRecurringLocalDataSource.post          one transaction:
        INSERT … OR IGNORE per entry                 unique (recurring_id, date)
        count real inserts with total_changes()
        UPDATE recurring.next_due per rule
  ← TaskEither<Failure, int>                        entries actually inserted
```

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `PostDueRecurring` | `domain/usecase/post_due_recurring.dart` | BR-9 for `clock.today()` |
| `RecurringSchedule` | `domain/recurring_schedule.dart` | Weekly, every 2 weeks, monthly (clamped, returns to the anchor day), yearly (29 Feb clamps) |
| `RecurringPosting`, `Occurrence` | `domain/entities/` | What one run writes |
| `RecurringRepositoryImpl` | `data/repository/` | Validates, then posts; also `startFresh` for onboarding |
| `SqfliteRecurringLocalDataSource` | `data/datasource/` | The transaction |

## 5. State variants
None. Home logs a failed run and still loads; the next load retries.

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | The transaction failed and rolled back |
| `InvalidAmountFailure` | A rule would post an invalid entry; nothing is written |

## 7. Design spec
`docs/SPEC.md` BR-8, BR-9, E7 (6-week catch-up), E8 (racing runs), E9 (clock moved back).

## 8. Known limitations / TODOs
- Posts are dated on their due date, so a catch-up can change `S_prev` and today's `A` (intended by BR-3).
- No midnight re-run while the app stays open (M2).
- Editing a rule's anchor (Settings, later) must recompute `next_due` without re-posting.
