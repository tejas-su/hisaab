# Settings Architecture Overview

**Status:** M1 built the preferences part: `AppPreferencesRepository` (onboarding flag and draft). M2 built `SettingsPage` with the Money group's **Fixed bills** (`BillsPage`, `BillEditorPage`, `BillsBloc`, `BillEditorBloc`; use cases in `lib/ledger/`). Salary and payday, keep aside, month start, categories and look come later; backup, restore, export and reset in M6. Names below that aren't in the code yet are the intended ones.

## 1. Purpose
Settings holds the few choices the app could not default away, all at most one level deep: money setup, categories, look, data and about.

## 2. Entry point
- The Settings button at the top right of Home (FR-HO-1) opens `SettingsPage`.
- Each group opens one sub-page; there are no nested menus.

## 3. Data flow
```
SettingsPage → Fixed bills (built, M2)
  BillsPage    → BillsLoadRequested → GetBills                 active Spent rules, soonest first
               → swipe/Delete → DeleteBill (active = 0) → Undo → RestoreBill        D35
  BillEditorPage → BillEditorBloc: name → amount → day (BillEditorDayChosen saves, droppable)
               → AddBill (category from chip; first post on/after today)            D33
               → EditBill (next date keeps the unposted month)                      D34
  RecurringRepository.changes → BillsBloc and HomeBloc reload
SettingsPage → SettingsBloc (SettingsLoadRequested) → read BudgetSettings, income rule, categories, AppPreferences   (planned)
  Money      → UpdateIncomeRule → RecurringRepository                               FR-SE-1 (future only, BR-9)
             → SetMonthStart / SetKeepAside → BudgetSettingsRepository             BR-1, BR-3
  Categories → RenameCategory / SetCategoryIcon → CategoryRepository               FR-SE-2, BR-11
  Look       → SetThemeMode → AppPreferencesRepository → app shell rebuilds theme   FR-SE-3
  Data       → CreateBackup → BackupRepository.dump → BackupCodec.encode → FileSaver.save        BR-16
             → RestoreBackup → FileSaver.pick → BackupCodec.decode+validate
                             → confirm dialog → BackupRepository.replaceAll (one transaction)
             → ExportCsv → EntriesCsv.encode → FileSaver.save
             → ResetApp (typed "RESET") → BackupRepository.wipe → route to onboarding  FR-SE-4
Every write → LedgerRepository.changes → Home/Spends recompute
```

## 4. Key classes
| Class | Layer | Responsibility |
|---|---|---|
| `SettingsPage` | `lib/settings/presentation/pages/settings_page.dart` | Groups of `SettingsRow`s; today only Money → Fixed bills |
| `BillsPage`, `BillsList`, `BillRow` | `lib/settings/presentation/` | The bills card; tap to edit, swipe or TalkBack action to delete, Undo snackbar |
| `BillEditorPage`, `BillNameStep`, `BillAmountStep`, `BillDayStep` | `lib/settings/presentation/` | One question per screen in `AdaptiveSplit`; `PopScope` steps back |
| `BillsBloc`, `BillEditorBloc` and their events | `lib/settings/presentation/bloc/` | List with delete/undo; the editor's three answers and the save |
| `GetBills`, `AddBill`, `EditBill`, `DeleteBill`, `RestoreBill`, `BillValidator` | `lib/ledger/domain/` | Rule edits affect future posts only (BR-9) |
| Planned: `MoneySettingsPage`, `CategoriesPage`, `DataPage`, `AboutPage`, `SettingsBloc`, `DataBloc`, `UpdateIncomeRule` | — | Later milestones |
| `SetMonthStart`, `SetKeepAside` | `lib/ledger/domain/usecase/` | Money settings feeding BR-1 and BR-3 |
| `RenameCategory`, `SetCategoryIcon` | `lib/ledger/domain/usecase/` | Order and count stay fixed |
| `SetThemeMode` | `lib/settings/domain/usecase/` | Light / Dark / Match phone |
| `BackupCodec` | `lib/settings/domain/backup_codec.dart` | Pure JSON encode/decode with schema version and validation |
| `EntriesCsv` | `lib/settings/domain/entries_csv.dart` | Pure CSV in the BR-15 column order |
| `CreateBackup`, `RestoreBackup`, `ExportCsv`, `ResetApp` | `lib/settings/domain/usecase/` | BR-16 and FR-SE-4 |
| `BackupRepository` / `Impl` | domain / data | Dump, replace-all and wipe via `AppDatabase`; migrates older backups |
| `FileSaver` | domain (interface) / data (`file_picker`) | System file picker seam |

## 5. State variants
| State | UI |
|---|---|
| `BillsLoading` / `BillsReady(bills, undo)` / `BillsFailed` | Hint only / the card or "No fixed bills yet" / "Couldn't load your money." with Try again |
| `BillEditorInProgress(stage, label, kind, rupees, saving, saveFailed)` / `BillEditorSaved` | The current question; "Couldn't save. Try again." on the day grid / page closes |
| `SettingsReady(values)` (planned) | Grouped list |
| `DataIdle` / `DataWorking(action)` / `DataDone(action, fileName?)` / `DataFailed(failure)` | Backup, restore and export progress, and the result toast |
| `ResetConfirming(typed)` | Reset enabled only when `typed == "RESET"` |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | Any write failed (rolled back) |
| `InvalidBillNameFailure`, `InvalidAmountFailure` | A bill name blank or over 40 characters, or an amount outside ₹1–₹99,99,99,999 |
| `RuleNotFoundFailure` | Editing, deleting or restoring a bill that is gone |
| `InvalidBackupFailure` | Wrong format, missing fields, or a newer schema version than the app (E14); nothing is changed |
| `FileAccessFailure` | The picker was cancelled or the file could not be read or written |

## 7. External dependencies
- **Ledger:** `RecurringRepository`, `CategoryRepository`, `BudgetSettingsRepository`, `LedgerRepository.changes`.
- **App shell:** theme mode and the route back to onboarding.
- **Core:** `AppDatabase`, migrations, tokens.
- **Package:** `file_picker` (M6).

## 8. Design spec
- Behaviour: `docs/SPEC.md` FR-SE-1 to FR-SE-5, BR-16, E14, NFR-5.
- Layout: `docs/UI_DESIGN.md` §5.6.
- Restore's dialog is the **only** confirmation dialog in the app (BR-16). Everything else uses undo.

## 9. Known limitations / TODOs
- `AppPreferencesRepository` lives in `lib/settings/` (domain + data) and is exported through `settings.dart` for onboarding and the app shell (DECISIONS D20).
- Keep-aside: confirm that the copy explains it is removed from every cycle's spendable money.
- About shows "Everything stays on this phone." Keep it true: no network, no analytics (NFR-2, NFR-3).
