# Home Architecture Overview

**Status:** built in M1 (hero, all BR-5 states, range line, Today list, delete with Undo, edit); M2 added the due-soon nudge (FR-HO-3) and the midnight reload (BR-8); M3 added the *This week* toggle (FR-HO-2) and the "you saved yesterday" note (BR-8). Still to come: the over card's *See where it went* and *See all* (FR-HO-5, FR-HO-4, M4 with Spends).

## 1. Purpose
Answers "how much can I safely spend today?" in under 2 seconds: one number, one picture (Day Blocks), one forecast sentence, today's entries.

## 2. Entry point
`AppRoutes.main` provides `HomeCubit` (loaded) and builds `MainScreen`: `AppShell` with `HomePage` and the dock. `ResumeListener` reloads Home on resume and `MidnightListener` just after local midnight.

## 3. Data flow
```
HomeCubit.load()
  → PostDueRecurring            failure logged; load continues
  → GetDueSoonBill              FR-HO-3; failure logged, no nudge
  → GetCycleSummary             BR-1..BR-7
  → CategoryRepository.all
  → LedgerRepository.entriesBetween(today, today)  newest first, first 5
  → HomeReady | HomeFailed
LedgerRepository.changes → load()   after any save, delete or restore
RecurringRepository.changes → load()  after a bill is added, edited, deleted or restored
HomeCubit.delete(entry)   emits the list without it at once (Dismissible), then HomeReady.undo
HomeCubit.toggleWeek()    hero tap: flips HomeReady.showWeek (kept across reloads, not saved), tick haptic
HomePage BlocConsumer: undo → SnackBar 6 s → HomeCubit.undo → RestoreEntry
HeroCard: HeroCopy.of(summary, week:) words + DayBlocksMapper.of(summary) picture
SavedYesterdayNote: summary.savedYesterday, under the hero and above the due-soon nudge
```

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `HomePage` | `presentation/pages/` | Header, hero by state, Today list, Undo snackbar |
| `HomeCubit`, `HomeState` | `presentation/cubit/` | Loads, reloads on `changes`, delete/undo, swipe haptic |
| `HeroCopy`, `RangeWords` | `presentation/hero_copy.dart` | Every hero word and the one spoken sentence (FR-HO-7); *Today* or *This week* title, number and overspend |
| `DayBlocksMapper` | `presentation/day_blocks_mapper.dart` | BR-6: fill, later-block height (0.4–1), style |
| `HeroCard`, `RangeLine`, `HeroSkeleton`, `NoIncomeCard` | `presentation/widgets/` | The display card variants |
| `TodayList`, `TodayRow` | `presentation/widgets/` | Rows; swipe to delete, tap to edit, TalkBack Delete action |
| `HomeHeader` | `presentation/widgets/` | Wordmark, "Mon, 26 Oct", Settings |
| `DueSoonNote` | `presentation/widgets/due_soon_note.dart` | "Electricity ₹1,200 goes out in 3 days" under the hero or the no-income card |
| `SavedYesterdayNote` | `presentation/widgets/saved_yesterday_note.dart` | "You saved ₹1,665 yesterday, so every day got ₹185 more." (BR-8) |
| `DayBlocks` + painter/layout | `lib/core/widgets/day_blocks/` | Springs, assemble entrance, "+N" collapse |

## 5. State variants
| State | UI |
|---|---|
| `HomeLoading` | `HeroSkeleton`: the label, no number |
| `HomeReady` with `NoIncome` | `NoIncomeCard`: "Add money you got this month" → Add on *Got* |
| `HomeReady` | `HeroCard` by `CycleState`; `undo` triggers the snackbar once; `showWeek` puts the hero on *This week* |
| `HomeFailed` | "Couldn't load your money." and Try again |

## 6. Design spec
`docs/SPEC.md` FR-HO-1, -2, -4, -6, -7; BR-4 to BR-8; E2, E4, E5, E12, E13. `docs/UI_DESIGN.md` §3.3, §5.2, §6, §9.

## 7. Known limitations / TODOs
- The Today list shows at most 5 rows and has no *See all* yet.
