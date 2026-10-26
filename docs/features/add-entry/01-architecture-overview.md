# Add Entry Architecture Overview

**Status:** planned (milestone M1), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
The Add tray logs money out or in. The path is the Add key, then the digits, then Next, then a category tile. Speed is the feature: never add a tap or a field (CLAUDE.md non-negotiables).

## 2. Entry point
- The marigold **Add** key in the dock opens `AddEntryTray` as a two-step tray over Home or Spends (FR-HO-6).
- Tapping a Today row or a history row opens the same tray in edit mode (FR-AD-8).

## 3. Data flow
```
Add key → AddEntryTray (container transform from the key)
  Step 1 (amount)
    → AddEntryCubit.setKind(Spent|Got)                      FR-AD-1
    → AddEntryCubit.key(digit | '00' | backspace | clear) → AmountInput (core/money)    FR-AD-2
    → AddEntryCubit.quickAdd(₹10…₹500)                      FR-AD-1 (adds, never replaces)
    → preview: SafeToSpend.previewAfter(summary, amount)    FR-AD-3 (BR-4 with the typed amount)
    → AddEntryCubit.next()                                  FR-AD-4
  Step 2 (category)
    → AddEntryCubit.setDate / setNote                       BR-10
    → AddEntryCubit.pickCategory(id) → SaveEntry(NewEntry)  ledger use case
      → LedgerRepository.save → changes → HomeCubit reloads
  → emit AddEntrySaved → BlocListener: tile flash, tray closes, success haptic   FR-AD-5
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `AddEntryTray` | `lib/add_entry/presentation/pages/` | Hosts both steps; height change between steps; predictive-back aware |
| `AmountStep` | presentation/widgets | Spent/Got segment, `AmountText`, quick chips, `Keypad`, Next `SignalKey` |
| `CategoryStep` | presentation/widgets | 2×4 `CategoryTile` grid (fixed order, BR-11), date and note chips |
| `AddEntryCubit` | presentation/cubit | Owns amount digits, kind, date, note, step; ignores re-entrant saves (FR-AD-6) |
| `AmountInput` | `lib/core/money/amount_input.dart` | Pure rules: leading zeros, 9-digit cap, `00`, backspace, clear, quick add |
| `Keypad` | `lib/core/widgets/` | Phone layout 1-2-3 on top; `00 · 0 · ⌫`; long-press ⌫ clears |
| `SignalKey` | `lib/core/widgets/` | The marigold key with the ink lip (Next, Add) |
| `SaveEntry` | `lib/ledger/domain/usecase/` | Validates and saves or replaces (BR-10) |

## 5. State variants
| State | UI |
|---|---|
| `AddEntryAmount(kind, digits, preview?)` | Step 1; Next enabled when the amount is above 0 |
| `AddEntryCategory(kind, amount, date, note, categories)` | Step 2; tiles save on tap |
| `AddEntrySaving(...)` | Tiles disabled; further taps ignored |
| `AddEntrySaved(entry)` | One-shot: close the tray, haptic, Home drains |
| `AddEntryFailed(failure, previous)` | Stays on step 2 with "Couldn't save. Try again."; input kept |

## 6. Failure types
| Failure | Cause |
|---|---|
| `InvalidAmountFailure` | Amount is 0 or over 9 digits; normally blocked by the keypad (reject haptic + shake) |
| `FutureDateFailure` | The date picker allowed a future date (it should not; BR-10) |
| `DatabaseFailure` | Save failed; the tray stays open (FR-AD-6) |
| `EntryNotFoundFailure` | Editing an entry deleted elsewhere |

## 7. External dependencies
- **Ledger:** `SaveEntry`, `DeleteEntry` (edit mode), `CategoryRepository.all(kind)`, `GetCycleSummary` (for the preview).
- **Core:** `AmountInput`, `MoneyFormatter`, `Keypad`, `SignalKey`, `CategoryTile`, `Tray`, `Haptics`, motion tokens.
- **Package:** `animations` (container transform, M1).

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-AD-1 to FR-AD-8, BR-10, BR-11, E11.
- Visuals and feel:
  - `docs/UI_DESIGN.md` §5.3 (both steps).
  - §6 (`standard` and `flick` springs, tile flash 120 ms).
  - §7 (tick / success / reject haptics).
  - §9 (keypad labels).

## 9. Known limitations / TODOs
- No decimal key, by design. Paise are never entered (PLAN §2).
- "Make this repeat" via a long-press on Next appears in older notes. SPEC has no FR for it, so it stays out of v1 unless added.
- Edit mode replaces the entry in place. Undo for edits is not specified.
