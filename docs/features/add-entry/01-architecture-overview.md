# Add Entry Architecture Overview

**Status:** built in M1.

## 1. Purpose
The Add tray logs money out or in. The path is the Add key, the digits, Next, then a category tile. Speed is the feature: never add a tap or a field.

## 2. Entry point
`AppRoutes.openAddTray` builds an `AddEntryBloc` with Home's `CycleSummary` (for the preview and the earliest date) and categories, then `AddEntryTray.show`. Callers: the dock's Add key (`AddKey`), the Add key under the Home pane in two-pane layouts, *Add money* (on *Got*), and a Today row tap (edit mode).

## 3. Data flow
```
Step 1  KindChanged · KeyPressed · BackspacePressed · Cleared · QuickAdded   AmountInput; tick or reject haptic
        preview = SafeToSpend.previewSpend(summary, amount − edited amount if today)
        NextPressed                                         only when amount > 0
Step 2  DateChanged (clamped earliest..today) · NoteChanged
        CategoryPicked(id) (droppable) → AddEntrySaving (tile flashes) → SaveEntry
           Right → success haptic → AddEntryFinished → tray pops; Home reloads via changes
           once AddEntryTray.show completes (the exit has ended; HomeTrayClosed)
           Left  → reject haptic → AddEntryEditing(failed: true)
        DeleteRequested (edit mode, droppable) → DeleteEntry → AddEntryFinished
BackPressed: step 2 → step 1 (PopScope); step 1 → the sheet closes without saving
```

## 4. Key classes
| Class | File | Responsibility |
|---|---|---|
| `AddEntryTray` | `presentation/pages/` | The sheet, step switch, back handling |
| `AmountStep` | `presentation/widgets/` | `KindSwitch`, amount, `SpendPreviewLine`, `QuickAddChips`, `Keypad`, Next |
| `CategoryStep` | `presentation/widgets/` | Title, 4-column tile grid, `DateChip`, `NoteChip`, Delete in edit mode |
| `AddEntryBloc`, `AddEntryEvent`, `AddEntryState`, `EntryForm` | `presentation/bloc/` | Form, preview; tile save and Delete are `droppable()` |
| `Keypad`, `SignalKey`, `CategoryTile`, `HisaabChip`, `Shake` | `lib/core/widgets/` | Shared controls |

## 5. State variants
| State | UI |
|---|---|
| `AddEntryEditing(form, rejections, failed)` | The current step; amount shakes on a refused key; "Couldn't save. Try again." |
| `AddEntrySaving(form, categoryId)` | That tile is ink; taps ignored |
| `AddEntryFinished(form, categoryId)` | The tray pops |

## 6. Layout
- Phone: step 1 nearly full height, step 2 its natural height.
- Short windows (landscape, split-screen): amount beside the keypad.
- Tabletop: the sheet keeps to the half below the fold (Flutter sheets never straddle a fold), amount beside keypad (DECISIONS D28).
- Width capped at 560dp.

## 7. Failure types
`InvalidAmountFailure`, `FutureDateFailure`, `NoteTooLongFailure` (normally prevented by the UI), `DatabaseFailure`, `EntryNotFoundFailure`.

## 8. Design spec
`docs/SPEC.md` FR-AD-1 to FR-AD-8, BR-10, BR-11, E11; `docs/UI_DESIGN.md` §5.3, §6, §7, §9, §13.

## 9. Known limitations / TODOs
- No container transform from the Add key; the sheet slides up. The `animations` package isn't needed yet.
- The 120 ms tile flash shows while the sheet drops rather than delaying the save.
