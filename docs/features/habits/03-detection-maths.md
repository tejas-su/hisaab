# Habits: detection maths

> **Status: planned.** Thresholds are starting values to be tuned against tests and real use.

## Inputs

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

`(category_id, tracked_item_id?, dayType)` where `dayType` is weekday or weekend. Weekday and weekend profiles are learned separately.

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

```
None ─(2 hits / 21 d)─► Maybe ─(p ≥ 0.6, ≥ 5 hits)─► Regular
                                                       │ 3 expected windows missed
                                                       ▼
                                                    Fading ─(no hit 14 d)─► None
```

Only `Regular` drives any UI.

## FSM 2: suggestion lifecycle (persisted)

Table `suggestion_state(key TEXT PRIMARY KEY, state TEXT, until TEXT, hides TEXT)`, added by a new migration. `key` is e.g. `usual:<category>:<tracked?>:<dayType>:<bucket>`.

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
