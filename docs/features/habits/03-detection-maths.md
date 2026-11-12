# Habits: detection maths

> **Status: *your usual* is built (phase 1); the rest is planned.** SPEC BR-17 is the rule and `lib/habits/domain/habit_rules.dart` holds every threshold. The built maths, as the tests pin it, is the table M1–M19 in `docs/superpowers/plans/2026-11-13-your-usual.md`. Where this file differs, the notes marked **Built** say how.

## Inputs

**Built:** there is no grouped SQL read. `GetHabitIndex` reads `LedgerRepository.entriesBetween(today − 55, today)` and `HabitIndexBuilder` filters in Dart: *Spent*, no `recurringId`, `createdAt` on the entry's own date. A half-hour bucket would lose the minute, and the window is widened by 15 minutes, so hits are judged by minute. The query below is the first plan, kept for the record; it also names `tracked_item_id`, which does not exist (D138).

One grouped read over `transactions` (illustrative; real code uses `Tables` / `TransactionColumns`):

```sql
SELECT category_id, tracked_item_id, date,
       CAST(substr(created_at,12,2) AS INT)*2 + CAST(substr(created_at,15,2) AS INT)/30 AS bucket,
       amount_minor, COUNT(*) AS n
FROM transactions
WHERE kind = ? AND recurring_id IS NULL
  AND date >= ?                          -- today − 56 days
  AND substr(created_at,1,10) = date     -- logged the same day it was spent
GROUP BY category_id, tracked_item_id, date, bucket, amount_minor;
```

- `created_at` is a local ISO timestamp from `Clock` (`lib/ledger/data/mapper/entry_mapper.dart`). It records logging time, so back-dated entries are excluded.
- Recurring posts are excluded: they are bills, not habits.
- Uses the existing `ix_transactions_date` index.
- `tracked_item_id` exists only once tracked items ship (`05-tracked-items.md`).
- Why not all in SQL: `exp()`/`pow()` are not reliably available in Android's system SQLite, window functions need SQLite 3.25 (API 30+), and pure Dart is testable with `FakeClock` without a database.

## Habit key

`(category_id, dayType)` where `dayType` is weekday or weekend. Weekday and weekend profiles are learned separately. If a day type fails only on hits or daily share, the pooled profile (all days) is used when it passes every bar (D153). Tracked items are dropped (D138), so there is no `tracked_item_id`.

## Maths

| Quantity | Formula |
|---|---|
| Time slot | 48 half-hour buckets, circular (23:30 neighbours 00:00) |
| Smoothing | Kernel `[¼, ½, ¼]` over neighbouring buckets |
| Recency weight | `w = 0.5^(age_days / 14)` (14-day half-life) |
| Window | Contiguous buckets above half the peak weight, plus ±15 min hysteresis |
| Daily probability | `p = days with an entry in the window / active days` (last 28 days of that day type; days, not entries) |
| Usual amount | Weighted mode of amounts in the window |

## Thresholds

| Helper | Fires when |
|---|---|
| Warm-up (all helpers) | ≥ 14 days since first entry **and** ≥ 10 active days |
| Your usual | Habit is Regular; now is inside the window; mode share ≥ 70%; ≥ 5 hits; no entry for this key today |
| Missed-log question | Habit is Regular with `p ≥ 0.7`; window ended ≥ 90 min ago; no entry for this key today; Home note slot not taken by a higher item |
| Bill candidate | Same note text (case-folded) and same amount in ≥ 3 consecutive cycles; day spread ±3; no matching recurring rule; month not already logged |
| Tracked-item candidate | Same category and same amount ≥ 6 times in 14 days, or the same note text ≥ 5 times; no existing tracked item matches |

## FSM 1: habit lifecycle (derived each rebuild, never stored)

**Built:** not a class. A habit is in the `HabitIndex` only when it is Regular (BR-17 rules 1–4), and "missed 3 in a row" is `UsualHabit.fading`. *Maybe* and *Fading → None after 14 days* are not in SPEC and are not built.

```
None ─(2 hits / 21 d)─► Maybe ─(p ≥ 0.6, ≥ 5 hits)─► Regular
                                                       │ 3 expected windows missed
                                                       ▼
                                                    Fading ─(no hit 14 d)─► None
```

Only `Regular` drives any UI.

## FSM 2: suggestion lifecycle (persisted)

**Built:** the state is kept **per category**. Table `suggestion_state(category_id INTEGER PRIMARY KEY REFERENCES categories(id) ON DELETE CASCADE, quiet_on TEXT, rest_until TEXT, forgotten_at TEXT)`, added by migration 004 (schema v4). A key holding the day type or the bucket would lose a rest whenever the window drifted by one slot, and *Forget* is per category in BR-17. `SuggestionGate` (`lib/habits/domain/suggestion_gate.dart`) reads it: quiet when `quiet_on` is today, resting through `rest_until`. The states are worked out, not stored; the diagram below still describes them, for *your usual* only.

```
Waiting ─(window opens)─► Showing ─┬─(used)──────────────► Waiting
                                   ├─(Not today / Undo)──► NotToday (until midnight)
                                   │     2nd within 14 d ─► Resting (30 d)
                                   ├─(Not a bill / Not now)► Resting (permanent for bill; 30 d otherwise)
                                   └─(window ends)───────► Waiting
```

- **Freeze:** once shown, a suggestion's amount and window stay fixed for the day unless a new entry changes the counts.
- **No double log:** any entry for the same key today moves it straight to Waiting.

## Tests to write first (with `FakeClock`)

- Midnight and window wrap (23:30–00:30).
- Weekday versus weekend separation.
- Edit and undo-restore keep the original `created_at`.
- Back-dated and recurring entries are ignored.
- Warm-up boundary: day 13 silent, day 14 with 10 active days fires.
- Mode share 69% silent, 70% fires.
- Double-log guard; freeze across reopen; ±15 min hysteresis.
- FSM 2 transitions, including two hides inside versus outside 14 days.
