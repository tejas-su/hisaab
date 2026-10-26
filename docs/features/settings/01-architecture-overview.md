# Settings Architecture Overview

**Status:** planned (milestone M3 for money, categories and look; M6 for backup, restore, export and reset), no code yet. Names below are the intended ones; update this doc when the code lands.

## 1. Purpose
Settings holds the few choices the app could not default away, all at most one level deep: money setup, categories, look, data and about.

## 2. Entry point
- The Settings button at the top right of Home (FR-HO-1) opens `SettingsPage`.
- Each group opens one sub-page; there are no nested menus.

## 3. Data flow
```
SettingsPage → SettingsCubit.load → read BudgetSettings, income rule, bills, categories, AppPreferences
  Money      → UpdateIncomeRule / SaveBill / DeleteBill → RecurringRepository        FR-SE-1 (future only, BR-9)
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
| `SettingsPage` + sub-pages (`MoneySettingsPage`, `BillsPage`, `CategoriesPage`, `DataPage`, `AboutPage`) | `lib/settings/presentation/pages/` | One group each |
| `SettingsCubit`, `BillsCubit`, `DataCubit` | presentation/cubit | One per independent concern (`.claude/rules/bloc.md`) |
| `UpdateIncomeRule`, `SaveBill`, `DeleteBill` | `lib/ledger/domain/usecase/` | Rule edits affect future posts only |
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
| `SettingsReady(values)` | Grouped list |
| `DataIdle` / `DataWorking(action)` / `DataDone(action, fileName?)` / `DataFailed(failure)` | Backup, restore and export progress, and the result toast |
| `ResetConfirming(typed)` | Reset enabled only when `typed == "RESET"` |

## 6. Failure types
| Failure | Cause |
|---|---|
| `DatabaseFailure` | Any write failed (rolled back) |
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
