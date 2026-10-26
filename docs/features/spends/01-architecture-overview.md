# Spends Architecture Overview

**Status:** planned (milestone M4; the entries list may land earlier with M1 history), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
Spends shows where the money went in a cycle: a pace chart, a sorted category list, at most 3 plain insights, and the entry point to Ask AI. It replaces the separate History/Insights screens from early PLAN drafts.

## 2. Entry point
- The right tab of the floating dock opens `SpendsPage`.
- *See where it went* from Home's over card also opens it (FR-HO-5).
- *See every entry* opens `EntriesPage` (FR-SP-6).

## 3. Data flow
```
SpendsPage
  → SpendsCubit.load(cycleOffset: 0)                         FR-SP-1
    → GetSpendsOverview(today, cycleOffset)                  lib/spends/domain/usecase/
       → PeriodCalculator.cycleFor(...)                      BR-1
       → LedgerRepository.entriesBetween(start, end)
       → PaceSeries.from(entries, cycle, income)             FR-SP-3 (cumulative vs steady line)
       → CategoryShares.from(entries)                        BR-13 largest remainder
       → InsightRules.evaluate(current, previous)            BR-14 (ledger domain)
       → BudgetSuggester.suggest(previous)                   BR-12 (after first full cycle)
  → emit SpendsReady
  ← LedgerRepository.changes → reload
SpendsCubit.previousCycle / nextCycle
SpendsCubit.applySuggestedLimits → ApplySuggestedLimits → CategoryRepository.setLimits
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `SpendsPage` | `lib/spends/presentation/pages/` | Cycle switcher, Ask AI card, chart, list, insights |
| `SpendsCubit` | presentation/cubit | Loads a cycle by offset; disables Next on the current cycle |
| `AskAiCard` | presentation/widgets | Ink-outline card with the marigold well; opens Ask AI |
| `PaceChart` | presentation/widgets | `fl_chart` line chart styled to tokens; fixed labelled y-axis; marigold today marker |
| `CategoryRow` | presentation/widgets | Icon, name, %, ₹, bar with optional limit tick and hatched overspend |
| `InsightTile` | presentation/widgets | One sentence + one action |
| `EntriesPage`, `EntriesCubit` | presentation | Day-grouped history with filter chips; swipe delete, tap edit |
| `GetSpendsOverview` | `lib/spends/domain/usecase/` | Composes the cycle, series, shares and insights |
| `PaceSeries` | `lib/spends/domain/pace_series.dart` | Pure: cumulative daily totals and the steady-pace line to `I − K` |
| `CategoryShares` | `lib/spends/domain/category_shares.dart` | Pure: sorted rows and largest-remainder percentages |
| `InsightRules`, `BudgetSuggester` | `lib/ledger/domain/` | Pure BR-14 / BR-12 rules (PLAN §9) |
| `ApplySuggestedLimits` | `lib/ledger/domain/usecase/` | Saves all suggested limits in one write |

## 5. State variants
| State | UI |
|---|---|
| `SpendsLoading` | Card skeletons |
| `SpendsEmpty(cycle)` | "Nothing spent in {month} yet." Chart and list hidden; Ask AI card still shown |
| `SpendsReady(cycle, series, verdict, rows, insights, canGoNext)` | Full screen |
| `SpendsFailed(failure)` | Retry line |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | Load or limits write failed |
| `NoIncomeFailure` | No income, so no steady line. The chart is hidden; rows still show |

## 7. External dependencies
- **Ledger:** `LedgerRepository`, `CategoryRepository`, `InsightRules`, `BudgetSuggester`, `ApplySuggestedLimits`.
- **Core:** `PeriodCalculator`, `MoneyFormatter` (compact `en_IN` on axes), tokens, `AppIcon`, `Dock`.
- **Features:** `ask_ai` (navigation), `add_entry` (edit from history).
- **Package:** `fl_chart` (M4).

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-SP-1 to FR-SP-6, BR-12, BR-13, BR-14, E3, E6.
- Visuals: `docs/UI_DESIGN.md` §5.4 (layout; bars, not donuts) and §3.3 (hatch instead of red). No category colours (§3.5).

## 9. Known limitations / TODOs
- The insight "same day-of-cycle" comparison needs the previous cycle's length. Define how it works when the cycles have different lengths (31 vs 28 days).
- The chart y-axis uses round thirds of `I` (FR-SP-3). Check readability when `I` is not a round number.
- PLAN §3 still lists separate History and Insights screens; this doc follows SPEC/UI_DESIGN.
