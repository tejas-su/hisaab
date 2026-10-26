---
name: debug-flutter
description: Systematically debug Hisaab Flutter issues — crashes, wrong amounts or state, wrong pay-cycle/date math, duplicate recurring entries, jank, memory leaks, and widget rebuild thrashing. Use when the user reports a bug, error, stack trace, crash, lag, leak, or a number that looks wrong.
argument-hint: "Describe the symptom or paste the error/log output"
---

Debug the following issue: **$ARGUMENTS**

## Step 1 — Triage (ask before proceeding)

Before touching code, ask the user which category fits (skip if it's already obvious from the report):

1. **Crash / exception** — throws, red screen, startup failure → [crash.md](crash.md)
2. **Wrong state / wrong number** — UI shows an unexpected amount, day count, block state or screen → [wrong-state.md](wrong-state.md)
3. **Jank / slow UI** — frame drops, keypad lag, stuttering animations → [performance.md](performance.md)
4. **Memory leak / OOM** — memory grows over time → [memory-leak.md](memory-leak.md)
5. **Build thrashing** — widgets rebuilding too often → [performance.md](performance.md)

Then read **only** the matching file and follow it. If you need to see what the running app is doing, use the `live-app-inspection` skill.

## Codebase map

Single Flutter app, Android only. Product and design specs: `docs/PLAN.md`, `docs/UI_DESIGN.md`.

| Area | Where |
|---|---|
| Entry, theme, routes | `lib/main.dart`, `lib/app/` |
| Database, migrations | `lib/core/db/` |
| Money and formatting | `lib/core/money/` (`Money`, `MoneyFormatter`, `en_IN`) |
| Today, cycles, paydays | `lib/core/time/` (`Clock`, `PeriodCalculator`) |
| Tokens, motion, haptics, icons | `lib/core/design/` |
| Shared widgets | `lib/core/widgets/` (`DayBlocks`, `AmountText`, `Keypad`, `Tray`) |
| Money data (transactions, categories, recurring) | `lib/ledger/` |
| Screens | `lib/home/`, `lib/add_entry/`, `lib/spends/`, `lib/ask_ai/`, `lib/onboarding/`, `lib/settings/` |
| Strings | `lib/l10n/app_en.arb` → generated `lib/l10n/gen/` |

## General rules for all categories

1. **Never guess the root cause** — read the actual file before proposing a fix
2. **One change at a time** — fix, confirm with the user, then continue
3. **Do not refactor** — fix only the specific problem
4. **Always check `dispose()` / `close()`** whenever you touch a StatefulWidget or Cubit/Bloc
5. **Use `AppLogger`** for debug logging (`AppLogger.log(tag: '...', data: {...})`), not `print()`. Never log notes or other personal text
6. **Ask before each phase** — present the diagnosis and confirm before applying the fix
7. **Add a regression test** — when the bug can be reproduced in a unit or widget test, write one that fails before the fix and passes after (see `.claude/rules/tests.md`). Date bugs get a `FakeClock` test pinned to the failing date. If it can't be tested as-is, say why
