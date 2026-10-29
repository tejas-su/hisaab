# Home Architecture Overview

**Status:** built in M1 (hero, all BR-5 states, range line, Today list, delete with Undo, edit); M2 added the due-soon nudge (FR-HO-3) and the midnight reload (BR-8); M3 added the *This week* toggle (FR-HO-2) and the "you saved yesterday" note (BR-8). M4 added *See all* (FR-HO-4) and the over card with *See where it went* (FR-HO-5).

## 1. Purpose
Answers "how much can I safely spend today?" in under 2 seconds: one number, one picture (Day Blocks), one forecast sentence, today's entries.

## 2. Entry point
`AppRoutes.main` provides `HomeBloc` (`HomeLoadRequested` added) and builds `MainScreen`: `AppShell` with `HomePage` and the dock. `ResumeListener` reloads Home on resume and `MidnightListener` just after local midnight.

## 3. Data flow
```
HomeLoadRequested (restartable: a newer load cancels an older one)
  → PostDueRecurring            failure logged; load continues
  → GetDueSoonBill              FR-HO-3; failure logged, no nudge
  → GetCycleSummary             BR-1..BR-7
  → CategoryRepository.all
  → LedgerRepository.entriesBetween(today, today)  newest first, first 5
  → HomeReady | HomeFailed
LedgerRepository.changes → HomeLoadRequested   after any save, delete or restore
RecurringRepository.changes → HomeLoadRequested  after a bill is added, edited, deleted or restored
HomeTrayOpened … HomeTrayClosed  AppRoutes.openAddTray wraps the Add tray; a HomeLoadRequested in between
                             is held and runs once when the tray's exit ends, so the drain plays in view (D91)
HomeDeleteRequested(entry)   emits the list without it first (Dismissible), then HomeReady.undo
HomeWeekToggled              hero tap: flips HomeReady.showWeek (kept across reloads, not saved), tick haptic
HomePage BlocConsumer: undo → SnackBar 6 s → HomeUndoRequested → RestoreEntry
HeroCard: HeroCopy.of(summary, week:) words + DayBlocksMapper.of(summary) picture;
          DayBlocks(fillIn: true) keyed by today: fills in on appear and on a new day, trail after a spend
SavedYesterdayNote: summary.savedYesterday, under the hero and above the due-soon nudge
```

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `HomePage` | `presentation/pages/` | Header, hero by state, Today list, Undo snackbar |
| `HomeBloc`, `HomeEvent`, `HomeState` | `presentation/bloc/` | Loads, reloads on `changes`, delete/undo, swipe haptic |
| `HeroCopy`, `RangeWords` | `presentation/hero_copy.dart` | Every hero word and the one spoken sentence (FR-HO-7); *Today* or *This week* title, number and overspend |
| `DayBlocksMapper` | `presentation/day_blocks_mapper.dart` | BR-6: fill (at most 0.9 once anything is spent), later-block height (0.4–1), style |
| `HeroCard`, `RangeLine`, `HeroSkeleton`, `NoIncomeCard` | `presentation/widgets/` | The display card variants |
| `TodayList` | `presentation/widgets/` | Header with the day's total and *See all*; rows are the ledger's shared `EntryRow` (swipe to delete, tap to edit, TalkBack Delete action) |
| `OverCard` | `presentation/widgets/over_card.dart` | Over states: what happens next, and *See where it went* unless Spends is already beside Home (FR-HO-5) |
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
- The Today list shows at most 5 rows; *See all* opens the cycle's *Every entry* (FR-SP-6).
