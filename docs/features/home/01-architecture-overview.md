# Home Architecture Overview

**Status:** planned (milestone M1 for hero + Today list; M3 for states, range line, full Day Blocks), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
Home answers "how much can I safely spend today?" in under 2 seconds. It shows one number, one picture (Day Blocks), one forecast sentence and today's entries.

## 2. Entry point
- `lib/app/routes.dart` shows `HomePage` when onboarding is done.
- It is the left tab of the floating dock, and the destination after onboarding and after every save.

## 3. Data flow
```
HomePage (BlocProvider.value)
  → HomeCubit.load()
    → GetCycleSummary(clock.today())         ledger: BR-1..BR-7 → CycleSummary
    → LedgerRepository.entriesBetween(today) Today list (FR-HO-4)
    → GetNextDueBill(today)                  recurring-engine: due-soon nudge (FR-HO-3)
  → emit HomeReady
  ← LedgerRepository.changes                 re-load after any save, delete or recurring post
  ← RecurringTrigger (resume / midnight)     BR-8; sets savedYesterday when applicable
HomeCubit.toggleWeekView()                   FR-HO-2 (session-only)
HomeCubit.delete(entry) → DeleteEntry → snackbar Undo → HomeCubit.undo() → SaveEntry
HeroCard → DayBlocks(DayBlocksGeometry.from(summary))     BR-6, pure geometry
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `HomePage` | `lib/home/presentation/pages/` | Layout, dock, `BlocListener` for undo snackbar and navigation |
| `HomeCubit` | presentation/cubit | Loads and recomputes; owns the week toggle; subscribes to `changes` and cancels in `close()` |
| `HeroCard` | presentation/widgets | Label, hero `AmountText`, `DayBlocks`, captions, `RangeLine`; one merged semantics node (FR-HO-7) |
| `RangeLine` | presentation/widgets | Renders `RangeForecast` with glyph and words (BR-7) |
| `DueSoonBanner` | presentation/widgets | "{Label} ₹{amount} goes out in {n} days" |
| `OverCard` | presentation/widgets | Calm message + *See where it went* (FR-HO-5) |
| `TodayList`, `TodayRow` | presentation/widgets | At most 5 rows, swipe to delete, tap to edit (FR-HO-4) |
| `DayBlocks` | `lib/core/widgets/day_blocks/` | `CustomPainter` drawing blocks, fill, hatch, ghost outline, payday flag |
| `DayBlocksGeometry` | `lib/core/widgets/day_blocks/` | Pure BR-6 mapping from `CycleSummary` to block heights, fill and collapse to "+N" |
| `AmountText` | `lib/core/widgets/` | Rolling tabular digits; spoken rupee label |
| `Dock` | `lib/core/widgets/` | Home · Add · Spends; shared with Spends |

## 5. State variants
| State | UI |
|---|---|
| `HomeLoading` | Hero skeleton in the display card; no spinner over amounts |
| `HomeNeedsIncome` | BR-5 #1 / E10: "Add money you got this month" with the Add key preset to *Got* |
| `HomeReady(summary, todayEntries, dueSoon?, view, savedYesterday?)` | Hero per `summary.state` (BR-5): On track, Slow down, Over today, Over cycle |
| `HomeFailed(failure, lastSummary?)` | Keeps the last good summary if any; quiet retry line |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | Load failed; shown via `HomeFailed` |
| `NoIncomeFailure` | Mapped to `HomeNeedsIncome`, not an error |
| `EntryNotFoundFailure` | Delete or undo of an entry already gone; refresh silently |

## 7. External dependencies
- **Ledger:** `GetCycleSummary`, `GetNextDueBill`, `DeleteEntry`, `SaveEntry`, `LedgerRepository.changes`.
- **Add entry:** opening the tray, and edit mode (FR-AD-8).
- **Core:** `Clock`, `MoneyFormatter`, `DayBlocks`, `AmountText`, `Dock`, tokens, motion, `Haptics`, `AppIcon`.

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-HO-1 to FR-HO-7, BR-4 to BR-8, E2, E4, E5, E12, E13.
- Visuals:
  - `docs/UI_DESIGN.md` §5.2 (layout, hierarchy).
  - §3.3 (state visuals).
  - §3.2 (display-card tokens).
  - §6 (`standard` spring for block drain, number roll).
  - §9 (hero announcement).

## 9. Known limitations / TODOs
- *This week* (FR-HO-2) assumes a Monday week start until SPEC Q2 is resolved.
- `UI_DESIGN.md` §5.2 mentions long-press on a block to show that day's share. SPEC has no FR for it yet, so it is out of scope until added.
- The midnight recompute depends on `RecurringTrigger`'s timer. Test it with `FakeClock` across a day boundary.
