# Spends Architecture Overview

**Status:** built in M4: cycle switcher, pace chart, *Where it went* with limits, insights with their actions, and *Every entry*. The Ask AI card (FR-SP-2) lands with Ask AI in M5 (DECISIONS D53).

## 1. Purpose
Spends shows where the money went in a cycle: a pace chart, a sorted category list with optional limits, at most 3 plain insights, and every entry by day.

## 2. Entry point
- The right tab of the floating dock shows `SpendsPage`; in two panes it sits beside Home.
- *See where it went* on Home's over card switches to it (FR-HO-5).
- *See every entry*, an insight's *See entries* and Home's *See all* push `EntriesPage` (`AppRoutes.entries`).

## 3. Data flow
```
AppRoutes.main provides SpendsBloc (SpendsLoadRequested added) beside HomeBloc
SpendsLoadRequested / EarlierPressed / LaterPressed       FR-SP-1 (one restartable group)
  → GetSpendsOverview(cyclesBack)                          lib/spends/domain/usecase/
     → BudgetSettingsRepository.read, RecurringRepository.activeRules → PeriodCalculator.cycleFor (stepped back)
     → CategoryRepository.all
     → LedgerRepository.entriesBetween(previous.start, cycle.end), firstLoggedOn
     → GetSuggestedLimits (current cycle only)             BR-12
     → PaceSeries.of, CategoryShares.of, InsightRules.evaluate, + LimitOffer, take 3
  → SpendsReady | SpendsFailed
LedgerRepository.changes → SpendsLoadRequested     stays on the cycle being shown
MainScreen resume / midnight → SpendsLoadRequested
SpendsLimitsAccepted(offer) (droppable) → ApplySuggestedLimits → reload

EntriesBloc(cycle, filter) ← EntriesLoadRequested (restartable) → CategoryRepository.all + LedgerRepository.entriesBetween
EntriesFilterChanged / DeleteRequested / UndoRequested (same Undo flow as Home)
```

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `SpendsPage` | `presentation/pages/spends_page.dart` | Title, switcher, pace card, *Where it went*, insights, *See every entry* |
| `SpendsBloc`, `SpendsEvent`, `SpendsState` | `presentation/bloc/` | Which cycle is shown; newest request wins (`restartable()`); limits save is `droppable()` |
| `CycleSwitcher` | `presentation/widgets/cycle_switcher.dart` | `‹ October ›`; a null callback disables an arrow |
| `CycleLabel` | `presentation/cycle_label.dart` | Month holding most of the cycle's days; weekly cycles by dates (D52) |
| `PaceCard`, `PaceChartPainter` | `presentation/widgets/` | Total, painted chart (gridlines, dotted steady line, ink line, marigold today dot), legend and verdict; one TalkBack sentence (D49) |
| `WhereItWentCard`, `CategorySpendRow`, `LimitBarPainter` | `presentation/widgets/` | Rows by amount; bar against the biggest; limit tick, hatch past it, "₹840 past limit" |
| `InsightsCard`, `InsightTile`, `InsightCopy` | `presentation/` | *Worth knowing*: sentence plus *See entries* or *Use these limits* (D51) |
| `EntriesPage`, `EntriesBloc`, `EntriesDay` | `presentation/` | One cycle by day, category chips, swipe delete with Undo, tap to edit |
| `GetSpendsOverview` | `domain/usecase/get_spends_overview.dart` | Composes one cycle's `SpendsOverview` |
| `CategoryShares` | `domain/category_shares.dart` | BR-13 largest-remainder percentages |
| `PaceSeries` | `domain/entities/pace_series.dart` | Cumulative spending, steady line, verdict, axis step |
| `InsightRules`, `Insight` | `domain/` | BR-14 #1–#3, one insight each (D50) |
| `registerSpendsServices` | `di/spends_module.dart` | Registers `GetSpendsOverview` |

## 5. State variants
| State | UI |
|---|---|
| `SpendsLoading` | Title only |
| `SpendsReady` with an empty overview | "Nothing spent in October yet." and *See every entry* |
| `SpendsReady` | Full screen; `limitsFailed` adds "Couldn't save. Try again." under the offer |
| `SpendsFailed` | "Couldn't load your money." and Try again |
| `EntriesReady` with nothing in the filter | "Nothing here yet." under the chips |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | A read, or the limits write, failed |
| `InvalidDataFailure` | A stored row or created time can't be read |

## 7. External dependencies
- **Ledger:** repositories, `GetSuggestedLimits`, `ApplySuggestedLimits`, `DeleteEntry`, `RestoreEntry`, `EntryRow`.
- **Core:** `PeriodCalculator`, `MoneyFormatter` (compact `en_IN` axis labels), tokens, `HisaabChip`, `Pressable`.
- No chart package (D49).

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-SP-1 to FR-SP-6, BR-12, BR-13, BR-14, E3, E6.
- Visuals: `docs/UI_DESIGN.md` §5.4 and §3.3 (hatch instead of red); `docs/design/mockups/06-spends.html`.

## 9. Known limitations / TODOs
- *Set a limit* for one category has no design yet; insights offer *See entries* instead (D51).
- Insight wording says "last month" even for weekly pay cycles.
- The Ask AI card arrives with M5.
