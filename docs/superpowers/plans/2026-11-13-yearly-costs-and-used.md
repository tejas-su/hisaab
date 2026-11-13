# Yearly costs and *Used from savings* (D174, D175). Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Build order:** this is plan **1 of 3** (M8 step 3, PLAN §12). It also lands the **one schema v5 migration** that plans 2 and 3 use. Plan 2 is `2026-11-13-missed-log-line.md`, plan 3 is `2026-11-13-fix-my-number.md`. **SPEC wins over this plan** wherever they differ; every place this plan departs from SPEC or from the code is in *Where this plan departs* and *Open questions*.

**Goal:** A saving can be a yearly cost (Insurance, School fees, Festival): the user puts in a twelfth a month, and when the cost is due taps *Used some of it* on the saving's sheet, types how much, and saves. The entry is a fourth kind, `used`. It moves no number: the hero is ₹1,318 before and after (BR-19). The Savings list shows "₹12,000 set aside" per saving and "₹12,000 put in since Nov / Nothing is set aside now." in the footer.

**Scope:** BR-19; FR-SE-1 AC-Y1 to AC-Y11; FR-KS-2/3/4 as they apply to the *Used* keypad; the *Used* row in Today and Every entry (FR-HO-4, FR-SP-6, D187); the *Used* Ask AI clause and CSV `used` (BR-15, D188); schema v5 and backup v5 (BR-16, PLAN §8, D188); NFR-11 for *Used* rows; E94 to E101; D174, D175, D177, D187, D188. **Not here:** *Not logged* rows, the Spends line's three parts, the *Not logged* Ask AI clause (plan 3); the missed-log line (plan 2).

**Architecture:**
- **One migration for all three features, landed here (decision).** Migration `005` does everything PLAN §8 lists in one step: the two hidden `not logged` category rows, the `used` kind plus `saving_id` (a rebuild of `transactions`, because SQLite cannot widen a `CHECK`, as migration 003 did), and `suggestion_state.asked_on`. Why one, and why first:
  1. SPEC BR-16 and PLAN §8 say the backup `schemaVersion` becomes **5**. One migration per feature would make v5, v6 and v7, and every shipped build between them would write a backup version SPEC does not describe.
  2. `AppDatabase.schemaVersion` is `migrations.length`, so the backup version moves with it. One bump means one backup-compat test set (a v4 file restores, a v5 file round-trips).
  3. The `used` kind needs the `transactions` rebuild, which is the only costly step. The other two parts are additive (two archived rows and a nullable column), cost nothing when unused, and plans 2 and 3 then start from a settled schema.
  4. The cost is two dormant pieces shipped before their feature. Neither is visible: the rows are archived and `asked_on` stays null.
- **`Entry` gains `savingId`** (the saving's `recurring.id`, null except on `used`), kept apart from `recurringId` because `(recurring_id, date)` is unique (BR-9, D175). `EntryKind.used` is the fourth kind. `LedgerRepository` gets `addForSaving` and `savingTotals`.
- **Set aside is computed, never stored** (D120): `SetAside` is pure Dart: `Σ Saved posted by that rule − Σ Used with its saving_id`, floored at ₹0 per saving. `still set aside` sums **active** savings; `put in since` stays gross (`savedTotal`).
- **Every BR-3 sum already filters by kind**, so a `used` entry reaches none of them. Task 3 pins that with a golden test (hero ₹1,318 before and after); no change to `SafeToSpend` or `GetCycleSummary` is planned, and none should be needed.
- **The *Used* question is a step of the saving's sheet** (`BillAnswer.used`), as *Amount* is (AC-Y6). Its state is a separate `UsedBloc`, because `BillSheetBloc` (239 lines) already owns five answers and a write. `BillSheet.show` gains an optional `UsedBloc`, waits for it to settle after the route completes (P7: copy `BillAmountSheet.show`, not the existing `BillSheet.show`, which reads state once and would lose the Undo when the user backs out during a write), and returns a new `BillSheetUsed` outcome. The caller shows the Undo: `BillsBloc` on the Settings door, `HomeBloc` on the due-soon door. Blocs never reference each other: the page connects `BillSheetBloc.open == used` to `UsedBloc` with a `BlocListener`.
- **The preview slot is a shared widget** (`PolitePreviewSlot`, FR-KS-4 AC-4: a polite live region that speaks 1.2 s after the last key, or at once when the state class changes). Plan 3 reuses it, so it lives in `lib/core/widgets/`.

**Prerequisites (built by another agent; verify in Task 0, do not rebuild):** P1 the Home hold as a count (`HomeBloc` `_holds`, `AppRoutes.holdingHome`); P2 `PinnedKeypadBody` with a bottom inset and the posture-agnostic route anchor; P3 bottom inset; P5/P6 the held cap ring and the spoken `amountCapReached` line (`AmountDisplay(rejections:)`, `AmountCapRing`); P15 the 1.5× key-label clamp (FR-KS-1 to FR-KS-4). This plan depends on `PinnedKeypadBody`, `AmountDisplay`, `Keypad` and `holdingHome` behaving as SPEC FR-KS says.

**Tech stack:** Flutter 3.47 / Dart 3.13, flutter_bloc + bloc_concurrency, fpdart, sqflite (+ `sqflite_common_ffi` in tests), gen-l10n, hugeicons, hand-written fakes. No new dependency.

**Spec:** SPEC BR-19, BR-9 (Yearly bullet), BR-10 (Four kinds), BR-11 (system-hidden rows), BR-15, BR-16; FR-SE-1 (Savings, AC-Y1 to AC-Y11); FR-HO-4 (*Used* row); FR-SP-6; FR-KS-1 to FR-KS-4; E94 to E101, E110, E111, E113, E115; NFR-5, NFR-11, NFR-12; UI_DESIGN §5.6, §6 to §10, §13; D174, D175, D177, D186, D187, D188; mockup [42](../../design/mockups/42-yearly-costs.html); `docs/features/yearly-costs/01-ux-flow.md`; copy deck [41](../../design/mockups/41-fix-my-number-copy-deck.md) §4 to §6.

## Where this plan departs from the docs, and what is ambiguous

| # | Point | What the plan does |
|---|---|---|
| A1 | PLAN §8 says "Allow `transactions.kind = used` (a value only, **unless a constraint on `kind` has to be widened**)". It has to be: migration 003 created `CHECK (kind IN ('out','in','save','card'))`. | Rebuild `transactions` exactly as migration 003 did (child table first; recreate the three indexes), adding `saving_id INTEGER REFERENCES recurring(id) ON DELETE SET NULL` and an index. Rules are soft-deleted (`setActive`), so the `SET NULL` never fires in the app; it keeps `PRAGMA foreign_key_check` clean. |
| A2 | SPEC says `saving_id` "links to its saving". It says nothing about an FK. | FK with `ON DELETE SET NULL`, as `recurring_id`. Flagged in *Open questions*. |
| A3 | `CategoryRepository.all()` excludes archived rows that are not the user's own, so the `saved` category is not in the Home or Entries `categories` map. A *Used* row therefore has no `Category` to label it. | `EntryRow` titles a `used` entry by its note (the saving's name) and never reads its category, as it already does for `saved` and `cardPaid`. |
| A4 | AC-Y3 puts "{amount} set aside" on "every saving" above ₹0, and AC-Y5 shows the *Used some of it* key "when something is set aside". A saving deleted after a *Used* leaves *still set aside* (E98). | `SetAside` is computed from **active** rules for the footer total and from rule id for each row. A deleted rule has no row, so nothing reaches it; Undo of the delete restores the rule with its id, so its set-aside returns. |
| A5 | AC-Y4: "only when a saving has something set aside **or a use exists**". "A use exists" is any `used` entry in the ledger, ever. | `SavingTotals.anyUse` is computed over all `used` rows, including ones whose saving is deleted. |
| A6 | FR-SE-1 AC-Y9 says `success` "fires with the first visible change: the list's figures rolling (Settings door)". The list's figures do not roll today (`savedSince` is plain text). | Fire `success` when the `UsedBloc` emits `UsedDone`, as `PutInExtraBloc` does, and say so in the report. Rolling figures are UI_DESIGN motion work, not a behaviour; flagged. |
| A7 | AC-Y6 "*All of it* ... a second tap on it clears the amount. `selected` while the amount equals the set-aside amount." | State: `UsedReady.allSelected` is derived (`rupees == setAsideRupees && rupees > 0`); the event `UsedAllPressed` toggles: fill when not selected, clear when selected. |
| A8 | AC-Y2 caption shows "for the three new pills only". The pill is a name chip; the user can also type a custom name. | The caption keys off the **chosen chip**, held in `BillEditorBloc` state (`yearlyPill`), not off the typed text; typing a name by hand never shows it. Flagged. |
| A9 | The `savingName` ARB select has no `insurance`, `schoolFees`, `festival` cases. `RuleWords`/`BillIcon.forName` may already map "insurance" to an icon. | Add the three cases. Savings have no Icon row (AC piggy-bank), so no icon change. |

## Global constraints

- Money is `int` paise in `Money`; amounts shown only through `MoneyFormatter` (`context.money.format`, `₹1,25,000`; never paise; never compact on these screens). "Today" comes from the injected `Clock`.
- All user text in `lib/l10n/app_en.arb` with a `@description` each, then `flutter gen-l10n`. Banned: "transaction", "debit/credit", "budget period", "Oops"; "Saved" means only money put into a saving; **never "balance" or "worth"** (BR-19, D120). The *Used* copy says "set aside" and "used".
- Design tokens only (`context.colors`, `Theme.of(context).textTheme`, `HisaabSpacing`); no `Color(0x…)`, `Colors.*`, `Icons.*`; icons through `AppIcon`; haptics through `Haptics`. No red, no green. Marigold only on *Save* (an act).
- Bloc everywhere, sealed events with `Equatable`, `restartable()` for loads and `droppable()` for saves, with a `// why:`. Blocs never reference each other. Nothing logs an amount, a note or a saving name (NFR-3): failures log `runtimeType` only.
- Adaptive layout: `context.layout`, never raw `MediaQuery` widths. New screens are tested at the `TestWindows` sizes (UI_DESIGN §13).
- The Add path (Add, digits, Next, tile) gains nothing and moves nothing. *Used* is not in Add.
- **Existing tests are the contract.** The only existing assertions this plan edits are the three `user_version == 4` / `schemaVersion, 4` ones in `test/core/db/app_database_test.dart` (lines 65, 216, 388), because SPEC BR-16 and PLAN §8 fix the schema version at 5. Every new constructor parameter on an existing class is optional. Any other existing test going red: stop and ask.
- No new dependency. No `mocktail`, no `bloc_test`, no golden image tests. The two Ask AI "goldens" are string goldens.
- **Commits:** local repo only, never push; commit only if the owner asks, then one commit per task, staging only that task's files.
- **Before Task 0:** `git rev-parse HEAD` → keep as `BASE`.
- **Done** means `flutter gen-l10n`, `flutter analyze` clean, `flutter test` green, `scripts/changed_lines_coverage.sh $BASE` ≥ 90% with every uncovered line listed and reasoned (target 100%), and Task 12's docs updated in the same change.

## The maths, resolved (what the tests pin)

| # | Quantity | Definition |
|---|---|---|
| U1 | Put in, per saving `s` | `Σ amount` of entries with `kind = saved` and `recurring_id = s.id`, all time (not cycle-bound) |
| U2 | Used, per saving | `Σ amount` of entries with `kind = used` and `saving_id = s.id`, all time |
| U3 | Set aside, per saving | `max(0, U1 − U2)` (E99: a put-in deleted after a use floors at ₹0, never negative) |
| U4 | Still set aside | `Σ U3` over **active** savings. *Put in extra* (a `saved` entry with no `recurring_id`) is in no `U1` (E100) |
| U5 | Put in since | Existing `savedTotal`: gross, never reduced by a use |
| U6 | Used cap | A `used` entry is `1 ≤ rupees ≤ floorMajor(U3)` for its saving, in **whole rupees** (BR-19). A saving whose `U3` is under ₹1 has nothing to use |
| U7 | Hero | Unchanged by a `used` entry: `A`, `safeToday`, `remaining`, `tomorrow` are equal before and after (BR-19 table; E92) |
| U8 | Slot line 1 | Before a digit: "{set aside} is set aside." With digits `r`: left `= floorMajor(U3) − r`; `left = 0` → "Nothing will be set aside."; else "{left} will still be set aside." A refused digit replaces it with `savingUsedCap` until the next accepted key |

## Review focus

1. **The hero does not move** (U7). → Task 3, `'a used entry changes none of BR-3's terms'`.
2. **Over-balance is refused at the keypad, not after Save** (E94, AC-Y8). → Task 5.
3. **Back while a *Used* save is writing keeps its Undo** (AC-Y9, P7). → Task 6.
4. **Home holds under the due-soon door's sheet** (E110, NFR-12). → Task 8.
5. **Migration 005 passes from v4 and from a v4 backup**, and a fresh install already has the rows. → Task 1.
6. **Every non-exhaustive `switch (kind)` the new enum case breaks is decided, not defaulted.** → Task 2.

---

## File map

| File | Responsibility | Task |
|---|---|---|
| `lib/core/db/migrations/migration_005_fix_used_and_asked.dart` (new), `migrations.dart`, `lib/core/db/db_schema.dart` | Schema v5: hidden `not logged` rows, `used` + `saving_id`, `asked_on` | 1 |
| `lib/ledger/domain/entities/{entry_kind,entry,entry_draft}.dart`, `lib/ledger/data/{model/entry_model,mapper/entry_mapper,mapper/entry_kind_mapper,datasource/entries_local_data_source,repository/ledger_repository_impl}.dart`, `lib/ledger/domain/repository/ledger_repository.dart` | `used` kind, `savingId`, `addForSaving`, `savingTotals` | 2 |
| `lib/ledger/domain/set_aside.dart`, `entities/{saving_totals,set_aside_summary}.dart`, `usecase/{get_set_aside,use_from_savings}.dart`, `failures/ledger_failures.dart` | Pure maths, the two use cases | 3 |
| `lib/settings/presentation/bloc/bills_{bloc,event,state}.dart`, `widgets/{bills_list,bill_row}.dart`, `pages/bills_page.dart` | Third row line, footer line 2, the Used Undo | 4, 8 |
| `lib/core/widgets/polite_preview_slot.dart` (new) | Shared polite live region (FR-KS-4) | 5 |
| `lib/settings/presentation/bloc/used_{bloc,event,state}.dart` (new) | The *Used* keypad's state | 5 |
| `lib/settings/presentation/widgets/bill_sheet/{used_question,used_all_chip}.dart` (new), `bill_summary.dart`, `pages/bill_sheet.dart`, `bloc/bill_sheet_{state,bloc}.dart` | The key, the question, the outcome, `show` | 6 |
| `lib/settings/presentation/widgets/{bill_name_step,bill_sheet/bill_name_question,bill_amount_step,bill_sheet/bill_amount_question}.dart`, `bloc/bill_editor_{bloc,state}.dart`, `lib/ledger/presentation/rule_words.dart` | Name pills, yearly caption | 7 |
| `lib/home/presentation/bloc/home_{bloc,event,state}.dart`, `pages/home_page.dart`, `lib/app/routes.dart` | Home door: Undo, hold | 8 |
| `lib/ledger/presentation/widgets/entry_row.dart`, `lib/spends/presentation/pages/entries_page.dart`, `bloc/entries_bloc.dart` | *Used* rows, chips, custom action | 9 |
| `lib/ask_ai/domain/prompt_builder.dart` | `used` kind, clause, CSV | 10 |
| `lib/l10n/app_en.arb` | Strings (added by the task that first needs them) | 4–10 |
| `lib/ledger/di/ledger_module.dart`, `lib/settings/...`, `test/helpers/{pump_app,fake_services}.dart`, `test/helpers/fakes/fake_ledger_repository.dart`, `test/helpers/fixtures/ledger/worked_example.dart` | DI and test support | 0, 3, 11 |

`test/` mirrors `lib/`: each new source file gets `test/<same path>_test.dart`.

---

### Task 0: Preflight and test support

**Files:** `test/helpers/pump_app.dart`, `test/helpers/fixtures/ledger/worked_example.dart`; Test: `test/helpers/test_windows_test.dart` (new)

- [ ] **Step 1: Record the base.** `git rev-parse HEAD` → `BASE`. `git status` must show no unrelated edits to `lib/ledger`, `lib/settings`, `lib/core/db`.
- [ ] **Step 2: Verify the prerequisites are really there** (stop and report if any fails; do not build them):

| Check | Command | Expected |
|---|---|---|
| P1 hold is a count | `grep -n "_holds" lib/home/presentation/bloc/home_bloc.dart` and `grep -n "holdingHome" lib/app/routes.dart` | both present; every Home-opened sheet (`onOpenBill`, `enterBill`) goes through `holdingHome` |
| P2/P3 pinned body | `grep -n "paddingOf(context).bottom" lib/core/widgets/pinned_keypad_body.dart` | present |
| P5/P6 cap ring | `grep -n "amountCapReached" lib/l10n/app_en.arb lib/core/widgets/amount_cap_ring.dart` | key exists, ring uses it |
| P15 key clamp | `flutter test test/core/widgets/keypad_test.dart` | green, includes a 2.0× test |

- [ ] **Step 3: Failing test for `TestWindows` (P16).** `test_windows_test.dart` asserts `TestWindows.book` (673×841), `bookHinge` (the same with a 40dp vertical hinge `DisplayFeature`), `tabletop`, `tabletopFold`, `splitScreen` (412×400), `splitScreenShort` (412×300) exist with those sizes. Run `flutter test test/helpers/test_windows_test.dart`. Expected: compile error on `book`, `bookHinge`, `splitScreenShort` (the others exist).
- [ ] **Step 4: Implement** the missing constants in `TestWindows`. `foldableUnfolded` (673×841) already exists: `book` is an alias, do not duplicate the number. Move any private `_tabletopFold` out of `add_entry_tray_test.dart` only if that file still defines one (grep; otherwise skip; do not edit the Add tray test beyond that).
- [ ] **Step 5: Fixture.** In `worked_example.dart` add `insurance` (a `RecurringRule`: ₹1,000, `EntryKind.saved`, id 5, category `SeedCategoryIds.saved`, anchor 5 Oct 2026, `nextDue` 5 Nov 2026) and `insurancePutIns` (12 `Entry` rows of ₹1,000, `recurringId: 5`, dated 5 Nov 2025 to 5 Oct 2026, ids 100 to 111, `createdAt` each on its own date). Do **not** add them to `rules` or `entries` (existing tests rely on those): tests add them.
- [ ] **Step 6: Verify.** `flutter test test/helpers` green; `flutter analyze test/helpers` clean.

---

### Task 1: Migration 005, `db_schema`, backup v5

**Files**
- Create: `lib/core/db/migrations/migration_005_fix_used_and_asked.dart`
- Modify: `lib/core/db/migrations/migrations.dart` (append), `lib/core/db/db_schema.dart`
- Test: `test/core/db/app_database_test.dart` (3 assertions 4 → 5; new group), `test/core/db/migration_005_test.dart` (new), `test/backup/data/datasource/backup_local_data_source_test.dart` (new cases)

**Interfaces**
- `db_schema.dart`: `TransactionColumns.savingId = 'saving_id'`; `SuggestionStateColumns.askedOn = 'asked_on'`; `EntryKindValues.used = 'used'`; `SettingKeys.installLineSeen = 'install_line_seen'` (used by plan 3; declared here so the schema file changes once); `CategoryKeys`-mirroring string constants for the two hidden keys live in the migration file, not in `core` (core cannot import ledger): `_notLoggedKey = 'not_logged'`, `_notLoggedInKey = 'not_logged_in'`. A test pins both to `CategoryKeys.notLogged` and `CategoryKeys.notLoggedIn`, which Task 2 adds.
- `migration005…(DatabaseExecutor db)`: (1) insert the two archived categories (`kind` `out` and `in`, `icon_key` = key, `sort` = next free index within its kind, `archived = 1`), skipping a key that already exists; (2) rebuild `transactions` as `transactions_v5` with `CHECK (kind IN ('out','in','save','card','used'))` and `saving_id INTEGER REFERENCES recurring(id) ON DELETE SET NULL`, copy every row, drop the old child table first (the same *why* comment as migration 003), rename, recreate `ix_transactions_date`, `ix_transactions_category_date`, `ux_transactions_recurring_date`, and add `ix_transactions_saving` on `saving_id`; (3) `ALTER TABLE suggestion_state ADD COLUMN asked_on TEXT`.

- [ ] **Step 1: Write the failing tests**

| File | Test | Asserts / cites |
|---|---|---|
| `migration_005_test` | `'a new database has the two hidden not logged rows, archived, out and in'` | BR-11, D166; names `not_logged` / `not_logged_in`; `archived = 1`; unique keys |
| | `'the not logged rows are not in CategoriesLocalDataSource.all()'` | they must never reach the Add tray (D166) |
| | `'upgrading a v4 database keeps every entry, id, link, created time and index'` | NFR-5; ids 2 and 3 as the v3 test; `ix_transactions_*`, `ux_transactions_recurring_date` present; `PRAGMA foreign_key_list(transactions)` lists `recurring` and `categories` |
| | `'a v4 database gains the rows with ids after its own'` | a v4 file with 12 categories gets ids 13 and 14 |
| | `'upgrading from v1 and from v3 files still works'` | the existing v1/v3 tests, now ending at v5 |
| | `'a kind of used with a saving_id is accepted; an unknown kind is refused'` | CHECK widened, not removed |
| | `'a used entry and a saved entry may share a date and a rule id'` | the unique index is on `recurring_id`, not `saving_id` (BR-9, D175) |
| | `'suggestion_state gains a nullable asked_on and keeps its rows'` | BR-17; a v4 row's three columns intact |
| | `'foreign_key_check is empty after the upgrade'` | |
| | `'a v4 backup file restores: its rows load, migrate to 5 and gain the hidden rows'` | BR-16, E101, NFR-5; through `SqfliteBackupLocalDataSource.upgrade(4, rows)` |
| | `'a v5 backup round-trips used, saving_id and asked_on'` | `dump` → `replace` → `dump` equal |
| `app_database_test` | the three version assertions now expect 5 | SPEC BR-16 |

- [ ] **Step 2: Run** `flutter test test/core/db test/backup/data/datasource` → fails (no migration, no constants).
- [ ] **Step 3: Implement** the four `db_schema` constants, the migration and the `migrations` entry. The three version assertions change `4` to `5` and `AppDatabase.schemaVersion` stays derived. Dartdoc the migration; a `// why:` on the table-order drop (copied from 003) and on `SET NULL`.
- [ ] **Step 4: Backup steps (nothing to code, everything to prove).** `BackupLocalDataSource.dump` already dumps every table and `fresh()` runs the migrations, so v5 data travels and *Delete everything* (`wipe` → `fresh`) clears `used` entries, `asked_on` and the (not yet used) `install_line_seen` key. Add to `backup_local_data_source_test.dart`: `'Delete everything leaves only the fresh hidden rows'` (a database with a `used` entry and `install_line_seen = 1` wipes to a fresh v5 state), and `'install_line_seen is not a local setting, so a backup carries it'` (`SqfliteBackupLocalDataSource.localSettings` does not contain it). Also `BackupJsonMapper` accepts `schemaVersion: 5` and refuses 6 (`NewerBackupFailure`).
- [ ] **Step 5: Verify.** `flutter test test/core/db test/backup` green. `flutter analyze lib/core test/core test/backup` clean.

---

### Task 2: The `used` kind, `savingId`, and the exhaustive switches

**Files**
- Modify: `lib/ledger/domain/entities/entry_kind.dart`, `entry.dart`, `lib/ledger/domain/repository/ledger_repository.dart`, `lib/ledger/domain/entities/category.dart` (add `CategoryKeys.notLogged = 'not_logged'`, `notLoggedIn = 'not_logged_in'`), `lib/ledger/data/model/entry_model.dart`, `mapper/entry_mapper.dart`, `mapper/entry_kind_mapper.dart`, `datasource/entries_local_data_source.dart`, `repository/ledger_repository_impl.dart`
- Create: `lib/ledger/domain/entities/saving_totals.dart`
- Modify (test support): `test/helpers/fakes/fake_ledger_repository.dart`
- Test: the mirrors of each modified file

**Interfaces**
- `EntryKind.used` (dartdoc: BR-19, touches no BR-3 symbol).
- `Entry.savingId` (`int?`, optional named, in `props`); `EntryDraft` is **not** changed (it is the Add tray's).
- `EntryModel.savingId` (`row.intOrNullAt(TransactionColumns.savingId)`, in `toRow`).
- `EntryMapper.toModel(draft, {createdAt, id, recurringId, savingId})`; `toEntity` reads `savingId`; `EntryKindMapper` maps `used` ⇄ `'used'`.
- `LedgerRepository.addForSaving(EntryDraft draft, {required int savingId})` (emits on `changes`; `TaskEither<Failure, Entry>`), mirroring `addForRule`. `restore(entry)` and `replace` carry `savingId`.
- `LedgerRepository.savingTotals()` → `TaskEither<Failure, SavingTotals>`; `SavingTotals extends Equatable { Map<int, ({Money putIn, Money used})> bySaving; bool anyUse; }`. Data source: one `GROUP BY` for `saved` rows by `recurring_id` (where not null) and one for `used` rows by `saving_id`, plus `EXISTS(SELECT 1 FROM transactions WHERE kind = 'used')`.

- [ ] **Step 1: Write the failing tests**

| File | Test | Cites |
|---|---|---|
| `entry_kind_mapper_test` | `'used maps to "used" and back; an unknown value is InvalidDataFailure'` | BR-19 |
| `entry_mapper_test` | `'savingId round-trips through toModel and toEntity'`; `'a null savingId stays null'` | D175 |
| `entry_model_test` | `'fromRow reads saving_id, an int or null; a string is InvalidDataFailure'` | data-domain.md pitfall |
| `entries_local_data_source_test` | `'insert and byId keep saving_id'`; `'savingTotals sums saved rows by rule and used rows by saving'` (₹12,000 put in, ₹4,000 used → `putIn 12,000`, `used 4,000`); `'a saved entry with no rule (Put in extra) is in no saving'` (E100); `'anyUse is true for a used entry whose saving is gone'` (E98); `'a used entry on a put-in date is accepted'` | BR-9, BR-19, E98, E100 |
| `ledger_repository_impl_test` | `'addForSaving saves a used entry with its saving_id and notifies'`; `'restore puts a used entry back with its saving_id'` (Undo, E96); `'replace keeps a used entry's saving_id'` | BR-10, BR-19 |
| `entry_test` | equality includes `savingId` | |

- [ ] **Step 2: Run** `flutter test test/ledger` → fails.
- [ ] **Step 3: Implement.** The fake gets `addForSaving` (records the draft in `saved`, stores the entry with `savingId`) and `savingTotals` computed from its own `entries`.
- [ ] **Step 4: Decide every switch the new case breaks.** Run `flutter analyze`. For each non-exhaustive `switch` or `EntryKind.values` use it reports, make a recorded decision, **never a `default`**:

| Site | Decision |
|---|---|
| `lib/ledger/presentation/widgets/entry_row.dart` (`_glyph`, `title`, `note`) | Task 9 (stub with `EntryKind.used => …` returning the saving glyph / note now so it compiles) |
| `lib/ask_ai/domain/prompt_builder.dart` `_entrySection` category `switch` | Task 10 (compile stub: `used => _savingsCategory`) |
| `lib/ledger/presentation/rule_words.dart`, `rule_glyph.dart` (`switch (kind)` on a **rule's** kind) | Rules are never `used`: `EntryKind.used` is unreachable there; `throw StateError` is banned, so group it with `cardPaid` and add a `// why:` |
| `lib/add_entry/**`, `lib/onboarding/**`, `lib/settings/presentation/bloc/bills_bloc.dart` | Same: Add and rules never produce `used`; group with the existing unreachable arm and `// why:` |

  Each decision gets a one-line test only where behaviour is reachable (the first two rows have their own tasks).
- [ ] **Step 5: Verify.** `flutter test` (whole suite) green apart from stubs' tests in later tasks; `flutter analyze` clean.

---

### Task 3: Set aside, `UseFromSavings`, and the BR-19 golden (pure Dart, test-first)

**Files**
- Create: `lib/ledger/domain/set_aside.dart`, `lib/ledger/domain/entities/set_aside_summary.dart`, `lib/ledger/domain/usecase/get_set_aside.dart`, `lib/ledger/domain/usecase/use_from_savings.dart`
- Modify: `lib/ledger/domain/failures/ledger_failures.dart` (`UsedTooMuchFailure`), `lib/ledger/ledger.dart` (exports), `lib/ledger/di/ledger_module.dart`
- Test: `test/ledger/domain/set_aside_test.dart`, `usecase/get_set_aside_test.dart`, `usecase/use_from_savings_test.dart`, `usecase/get_cycle_summary_used_test.dart`

**Interfaces**
- `abstract final class SetAside { static Money of(Money putIn, Money used); static SetAsideSummary summarise(List<RecurringRule> activeSavings, SavingTotals totals); }` (U1 to U5).
- `SetAsideSummary { Map<int, Money> perSaving; Money stillSetAside; bool anyUse; }`.
- `GetSetAside implements UseCase<SetAsideSummary, NoParams>`: active `saved` rules + `savingTotals()`.
- `UseFromSavings implements UseCase<Entry, UseFromSavingsParams>` with `UseFromSavingsParams({required RecurringRule saving, required Money amount})`: validates `EntryValidator.validateAmount`, re-reads the saving's set-aside **in the write** (a put-in could have been deleted behind the sheet), refuses `amount > floor(setAside)` with `UsedTooMuchFailure` and `U3 < ₹1` likewise, resolves `CategoryKeys.saved` through `CategoryRepository.idOf`, then `_ledger.addForSaving(draft, savingId: saving.id)` with `note: saving.label`, kind `used`, date `Clock.today()`.

- [ ] **Step 1: Write the failing tests** (`today = WorkedExample.today`, Mon 26 Oct 2026)

| File | Test | Cites |
|---|---|---|
| `set_aside_test` | `'12 put-ins of ₹1,000 and no use: ₹12,000 set aside'` | BR-19 example, U3 |
| | `'₹12,000 used: nothing is set aside'` | BR-19 table, AC-Y4 zero form |
| | `'a put-in deleted after a use floors at ₹0, never negative'` (put in 11,000, used 12,000) | E99 |
| | `'put in extra is in no saving'` | E100, U4 |
| | `'still set aside sums active savings only; a deleted saving leaves it'` | E98, U4 |
| | `'put in since stays gross after a use'` | U5 |
| | `'anyUse is true when a use exists even with ₹0 set aside'` | A5 |
| `get_set_aside_test` | reads the fake repositories; failure passes through as `DatabaseFailure` | |
| `use_from_savings_test` | `'saves a used entry: kind, today, note = the saving, saving_id, hidden saved category'` | BR-19 |
| | `'₹0 is InvalidAmountFailure; a 10th digit is InvalidAmountFailure'` | BR-10 |
| | `'more than is set aside is UsedTooMuchFailure and writes nothing'` (₹15,000 against ₹12,000) | E94, D175 |
| | `'exactly what is set aside is accepted'` (₹12,000) | E94 boundary |
| | `'a set-aside under one rupee refuses any amount'` | U6 |
| | `'the set-aside is re-read in the write: a put-in deleted since the sheet opened refuses'` | E99 |
| | `'a second use up to what is left is accepted; the same entry twice past the cap is refused'` | E96 |
| | `'a database failure is passed through'` | |
| `get_cycle_summary_used_test` | **`'a used entry changes none of BR-3's terms'`**: build the BR-19 inputs (`I 45,000`, `B 1,200`, `S_prev 27,150`, ₹420 today, the 12 insurance put-ins so `Sv_before = 1,000`, `R = 0`); the summary before and after a `used` ₹12,000 entry is equal in `pool` 15,650, `todayShare` 1,738, `safeToday` 1,318, `remaining` 15,230, `tomorrowShare` 1,903 | BR-19 table, U7, E92 |
| | `'a used entry dated yesterday leaves the morning note unchanged'` | BR-8 |
| | `'the pace forecast ignores a used entry'` | BR-7 |
| | `'the wrong models are not what is built'`: assert hero **is not** ₹0 and `savedExtraToday` is ₹0 | BR-19 "wrong models" |

- [ ] **Step 2: Run** `flutter test test/ledger/domain` → fails (nothing exists).
- [ ] **Step 3: Implement.** If `get_cycle_summary_used_test` fails on the first run, **do not edit `GetCycleSummary`**: a failing assertion means a sum is not filtering by kind. Find it (`grep "EntryKind" lib/ledger/domain`) and report before changing anything.
- [ ] **Step 4: Wire** the two use cases in `ledger_module.dart` and `ledger.dart`; add `GetSetAside` and `UseFromSavings` to `FakeServices`.
- [ ] **Step 5: Verify.** `flutter test test/ledger` green; `flutter analyze lib/ledger test/ledger` clean.

---

### Task 4: The Savings list: third line and footer (AC-Y3, AC-Y4)

**Files**
- Modify: `lib/settings/presentation/bloc/bills_bloc.dart`, `bills_state.dart`, `lib/settings/presentation/widgets/bill_row.dart`, `bills_list.dart`, `lib/settings/presentation/pages/bills_page.dart`, `lib/settings/presentation/widgets/rule_list_actions.dart` (no change expected; check), `lib/l10n/app_en.arb`, `lib/app/routes.dart` (`bills(...)`)
- Test: mirrors; `test/settings/presentation/pages/bills_page_test.dart`

**Interfaces**
- `BillsBloc({... GetSetAside? getSetAside})`: **optional**; used only when `kind == EntryKind.saved`. `BillsReady.setAside` (`Option<SetAsideSummary>`, default none), in `props` and `copyWith`.
- `BillRow({... Money? setAside})`: a third line "{amount} set aside" only when above ₹0.
- ARB: `savingSetAside` ("{amount} set aside"), `savingsStillSetAside` (plural form `=0{Nothing is set aside now.}`), each with `@description` and placeholders; spoken forms `savingSetAsideSpoken`, `savingsStillSetAsideSpoken` (amounts through `spokenAmount`) so TalkBack reads "4,000 rupees set aside".

- [ ] **Step 1: Write the failing tests**

| File | Test | Cites |
|---|---|---|
| `bills_bloc_test` | `'a savings list loads each saving's set-aside beside the put-in total'` | AC-Y3/Y4 |
| | `'a ledger write reloads the set-aside (a Used from the sheet updates the list)'` | D177 |
| | `'a spent list never calls GetSetAside'` | AC-Y3 "every saving" only |
| | `'a failed set-aside read shows BillsFailed'` | |
| `bill_row_test` | `'the third line shows above ₹0 only; the schedule line stays the second'` | AC-Y3 |
| | `'the row is about 84dp with the third line and 64dp without, at 1.0× and 1.5× text'` | AC-Y3 |
| | `'TalkBack reads the set-aside after the schedule'` | AC-Y3 |
| `bills_page_test` | `'footer line 1 stays "₹12,000 put in since Nov"; line 2 reads "Nothing is set aside now." after a full use'` | AC-Y4, BR-19 example |
| | `'line 2 is absent when nothing is set aside and no use exists'` | AC-Y4 "only when…" |
| | `'line 2 reads "₹4,000 still set aside" with ₹4,000 left'` | AC-Y4 |
| | `'at 320×568 with 2.0× text the footer wraps and the pinned keys stay on screen'` | E111, NFR-4 |

- [ ] **Step 2: Run** `flutter test test/settings` → fails. **Step 3: Implement** (bloc, state, row, page footer, ARB, `flutter gen-l10n`). **Step 4: Verify** `flutter test test/settings && flutter analyze lib/settings test/settings`.

---

### Task 5: `PolitePreviewSlot` and `UsedBloc`

**Files**
- Create: `lib/core/widgets/polite_preview_slot.dart`, `lib/settings/presentation/bloc/used_bloc.dart`, `used_event.dart`, `used_state.dart`
- Test: `test/core/widgets/polite_preview_slot_test.dart`, `test/settings/presentation/bloc/used_bloc_test.dart`

**Interfaces**
- `PolitePreviewSlot({required Object stateClass, required String liveText, required Widget child, Duration debounce = const Duration(milliseconds: 1200)})`: wraps `child` (the slot's focusable full text) in `Semantics(liveRegion: true, …)` whose `label` is `liveText`, updated **1.2 s after the last change** or **at once when `stateClass` changes** (FR-KS-4 AC-4). Under non-TalkBack it is just the child. Uses a `Timer`, cancelled in `dispose`; under `MediaQuery.accessibleNavigation` only. The debounce is injectable so tests use `Duration.zero` or pump 1.2 s.
- `UsedBloc({required GetSetAside, required UseFromSavings, required Haptics})`. Events: `UsedLoadRequested(RecurringRule saving)` (`restartable()`), `UsedKeyPressed(String)`, `UsedBackspacePressed`, `UsedCleared`, `UsedAllPressed`, `UsedSavePressed` (`droppable()`), `UsedReset`. States: sealed `UsedState`: `UsedLoading`, `UsedFailed(Failure)`, `UsedReady({saving, setAsideRupees, rupees, rejections, capShown, allSelected (derived), saving, saveFailed, nothingToUse})`, `UsedDone(UsedOutcome)` where `UsedOutcome({Entry entry, RecurringRule saving})`.

- [ ] **Step 1: Write the failing tests**

| File | Test | Cites |
|---|---|---|
| `used_bloc_test` | `'load shows ₹0 typed (empty) and the set-aside from the ledger'` | AC-Y6: amount **empty** |
| | `'a digit adds to the amount; line 1 becomes "{left} will still be set aside"'` | U8, AC-Y7 |
| | `'typing the whole set-aside shows "Nothing will be set aside."'` | AC-Y7 |
| | `'a digit past the set-aside is refused: reject haptic, rejections + 1, capShown true, amount unchanged'` | E94, AC-Y8, FR-KS-2 |
| | `'the cap line clears on the next accepted key'` | AC-Y8 "until the next valid key" |
| | `'a 10th digit is refused with the same signals'` (set-aside 999,999,999 edge) | E93, FR-KS-2 |
| | `'All of it fills the set-aside; a second press clears; the first key afterwards replaces it'` | AC-Y6, A7, FR-AD-8 |
| | `'allSelected is true only while the amount equals the set-aside'` | AC-Y11 |
| | `'Save with ₹0 or empty does nothing'` | AC-Y6 |
| | `'Save writes the entry, emits UsedDone with success haptic'` | AC-Y9 |
| | `'a double Save writes one entry'` (`droppable()` with a gated fake) | E96 |
| | `'a failed write keeps the keypad and digits, saveFailed true, reject haptic'` | AC-Y9 |
| | `'a refused write (UsedTooMuch, set-aside fell behind the sheet) refreshes the set-aside and keeps the sheet'` | E99 |
| | `'the set-aside falling to ₹0 behind the sheet shows nothingToUse and disables Save'` | AC-Y8 last sentence |
| | `'a reload restarts: an older slower read does not land last'` | bloc.md `restartable()` |
| | `'UsedReset clears digits without closing'` | AC-5 of FR-SE-1 "unsaved typing is dropped" |
| `polite_preview_slot_test` | `'with accessibleNavigation, text changes announce 1.2 s after the last change'` (pump 1.1 s: old label; 1.2 s: new) | FR-KS-4 AC-4, E114 |
| | `'a change of stateClass announces at once'` | D186 |
| | `'without accessibleNavigation there is no live label'` | |
| | `'the timer is cancelled on dispose'` | hygiene |

- [ ] **Step 2: Run** → fails. **Step 3: Implement** (`// why:` on each transformer and on the cap-shown flag). **Step 4: Verify** `flutter test test/core/widgets test/settings/presentation/bloc && flutter analyze lib/core/widgets lib/settings/presentation/bloc test/…`.

---

### Task 6: The *Used* question inside the saving's sheet (AC-Y5 to AC-Y9, AC-Y11)

**Files**
- Create: `lib/settings/presentation/widgets/bill_sheet/used_question.dart`, `used_all_chip.dart`
- Modify: `lib/settings/presentation/bloc/bill_sheet_state.dart` (`BillAnswer.used`; `BillSheetUsed(UsedOutcome)` outcome; `BillSheetReady.setAside` as `Option<Money>`), `bill_sheet_bloc.dart` (`BillSheetUsedPressed`; load set-aside through an optional `GetSetAside`), `bill_sheet_event.dart`, `lib/settings/presentation/pages/bill_sheet.dart`, `widgets/bill_sheet/bill_summary.dart`, `lib/l10n/app_en.arb`
- Test: `test/settings/presentation/pages/bill_sheet_used_test.dart` (new) and the mirrors

**Interfaces and behaviour**
- `BillSummary` (a saving's sheet only): under the amount line "{amount} set aside" when above ₹0 (`savingSetAside`); an **outlined** *Used some of it* key (`savingUsedAction`, hint `waitingOpensHint`) in the middle, nowhere near *Delete saving*; on the three yearly pills only, `savingUsedHint` above the key. Before the first put-in the sheet is as today (AC-Y5). The key shows only when `setAside >= ₹1`.
- `UsedQuestion` is `PinnedKeypadBody` with `lead` = the title `savingUsedQuestion(saving)`, the slot (`PolitePreviewSlot`, two fixed lines: line 1 U8, line 2 `savingUsedSame` always) and the failed line; `figure` = `AmountDisplay(rejections:)` with `UsedAllChip` beside it (a 48dp chip; **below** the amount at large text); `controls` = `Keypad` + a full-width `SignalKey` *Save* with the `typeAmountFirst` hint when disabled.
- `BillSheet.show(context, bloc, {UsedBloc? used})` gains a settled wait **only when `used != null`**: after `route.completed`, if `used.state` is `UsedReady(saving: true)` await the next settled state; then close `used` and return `BillSheetUsed` for `UsedDone`. Without `used` the method is exactly as it is.
- A `BlocListener<BillSheetBloc, …>` on `open == used` adds `UsedLoadRequested(rule)`; going back adds `UsedReset`.
- A *Used* save closes the whole sheet (the question "closes to the list or to Home"): `UsedDone` → `Navigator.pop`.
- Back from the question returns to the bill (`BillSheetBackPressed`, existing); Back on the bill closes it (AC-5).

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| `'with ₹12,000 set aside the sheet shows "₹12,000 set aside" and the outlined Used some of it key'` | AC-Y5 |
| `'before the first put-in the sheet has neither the line nor the key'` | AC-Y5 |
| `'the hint "Paid the cost from this?" shows on Insurance, School fees and Festival, not on RD'` | AC-Y5, O6 |
| `'tapping the key opens the question: title, empty amount (₹0 shown), pinned keypad, Save off'` | AC-Y6, AC-3 of FR-SE-1 |
| `'All of it fills ₹12,000 and is selected in semantics; a second tap clears it'` | AC-Y6, AC-Y11 |
| `'the slot reads "₹12,000 is set aside." then "₹8,000 will still be set aside." as digits are typed, and always "Your daily number doesn't change."'` | AC-Y7 |
| `'a digit past ₹12,000 shows "That's all you have set aside. Add the rest as a spend." in place of line 1, with the shake and the held ring'` | AC-Y8, FR-KS-2 |
| `'Save closes the sheet and returns BillSheetUsed with the entry'` | AC-Y9 |
| `'Back while Save is writing closes the sheet and the outcome still arrives'` | AC-Y9, FR-KS-4 AC-3, P7, Review focus 3 |
| `'Back from the question returns to the bill with the digits dropped'` | AC-5 |
| `'a failed save keeps the keypad with "Couldn't save. Try again."'` | AC-Y9 |
| `'TalkBack: the slot is a polite live region; All of it reads "All of it, button, selected"; the disabled Save has the hint "Type an amount first."'` | AC-Y11, FR-KS-4 AC-5 |
| `'layout: at 320×568 (1×, 1.5×, 2×), 412×400, 412×300, landscape 915×412, book 673×841, tabletop 701×841 the amount and Save are on screen above the bottom inset; the slot scrolls'` | E111, FR-KS-1, `pinned_keypad_expectations.dart` |
| `'the 48dp handle is not drawn under 600dp tall; swipe, scrim and Back still close'` | E115, D180 |
| `'at 2.0× text the keypad is 248dp and Save stays on screen at 320×568'` | E113, FR-KS-3 |
| `'All of it as a chip wraps below the amount at 2.0× text'` | AC-Y6 |

- [ ] **Step 2: Run** `flutter test test/settings/presentation` → fails.
- [ ] **Step 3: Implement.** Reuse `test/helpers/pinned_keypad_expectations.dart` for the layout assertions (read it first). ARB: `savingUsedAction`, `savingUsedHint`, `savingUsedQuestion`, `savingUsedAll`, `savingUsedSetAside`, `savingUsedLeft`, `savingUsedSame`, `savingUsedCap`, `savingUsedNothing`, `typeAmountFirst` (the key is new; reuse `save` and `couldntSave`), each with `@description`; spoken forms for the two amounts. `flutter gen-l10n`.
- [ ] **Step 4: Verify.** `flutter test test/settings && flutter analyze`.

---

### Task 7: Name pills and the yearly caption (AC-Y1, AC-Y2)

**Files**
- Modify: `lib/settings/presentation/widgets/bill_name_step.dart`, `bill_sheet/bill_name_question.dart`, `bill_amount_step.dart`, `bill_sheet/bill_amount_question.dart`, `lib/settings/presentation/bloc/bill_editor_{bloc,event,state}.dart`, `lib/l10n/app_en.arb` (`savingName` select, `savingYearlyCaption`, `savingYearlyUsedHint`)
- Test: mirrors; `bill_name_step_test`, `bill_amount_step_test`, `bill_editor_bloc_test`

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| `'the saving name pills are RD, SIP, Gold scheme, Chit in that order, then Insurance, School fees, Festival'` | AC-Y1 (the first four never move) |
| `'tapping Insurance fills the name and moves on; the three questions and the tap path are unchanged'` | AC-Y1 |
| `'the amount question shows the two-sentence caption only after a yearly pill'` | AC-Y2 |
| `'a hand-typed "Insurance" does not show it; a pill does'` | A8 |
| `'no yearly-amount field, no ÷12 key, no due date, no reminder is offered'` | D174 |
| `'the body scrolls above the pinned keypad at 320×568 and 2.0× text'` | AC-Y2, E111 |
| `'the bill sheet's Amount question (editing an existing saving) shows no caption'` | AC-Y2 "while adding" is the editor |
| `'a spent bill's pills are unchanged'` | regression |

- [ ] **Step 2: Run** → fails. **Step 3: Implement** (`BillEditorState.yearlyPill` set by the chip, cleared by typing). **Step 4: Verify** `flutter gen-l10n && flutter test test/settings && flutter analyze`.

---

### Task 8: Doors, snackbar and Undo (AC-Y9, AC-Y10, E110, NFR-12)

**Files**
- Modify: `lib/settings/presentation/bloc/bills_{bloc,event}.dart` (`BillsUsedDone`, `BillsUsedUndoRequested`; `BillsReady.usedUndo`), `bills_page.dart` (snackbar), `lib/home/presentation/bloc/home_{bloc,event,state}.dart` (`HomeUsedDone`, `HomeUsedUndoRequested`; `HomeReady.usedUndo`), `home_page.dart`, `lib/app/routes.dart` (`openBillSheet` passes a `UsedBloc`; both callers handle `BillSheetUsed`), `lib/l10n/app_en.arb` (`savingUsedDone`, `savingDeletedKeeps`)
- Test: mirrors; `test/app/routes_used_test.dart`

**Behaviour**
- **Settings door:** `bills(...).onEdit` gets `BillSheetUsed`, adds `BillsUsedDone(outcome)`; the list's snackbar reads "Insurance: ₹12,000 used" (`savingUsedDone`, name first, D132) with *Undo* (4 s; held under TalkBack, D105). Undo deletes the entry through `DeleteEntry` and does **not** reopen the sheet. `success` fires at `UsedDone`.
- **Home door** (the due-soon saving row → `openBillSheet` through `holdingHome`, P1): `HomeUsedDone(outcome)`; Home's snackbar; Undo = `HomeUsedUndoRequested(entry)` → `DeleteEntry`. Home holds under the sheet and reloads at the route's completion (NFR-12), so the *Used* row grows into Today **after** the hero is read (UI_DESIGN §6). An Undo offered while Home is loading waits for the next good load (the `_pendingAmountUndo` pattern: add `_pendingUsedUndo`).
- **AC-Y10:** deleting a saving's Undo reads "Insurance deleted. What you put in stays in your history." when that saving has had a put-in: `ruleDeleted` for a saving gets a sibling `savingDeletedKeeps`. No extra *Used* step is offered on delete (D175).

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| `'BillsBloc: BillsUsedDone shows the snackbar state once; Undo deletes the entry and the list reloads'` | AC-Y9 |
| `'HomeBloc: HomeUsedDone before the first load waits and shows on the first good load'` | FR-HO-8 AC-6 pattern, D127 |
| `'HomeBloc: HomeUsedUndoRequested deletes through DeleteEntry'` | AC-Y9 |
| `'Home holds its numbers while the saving sheet is open and reloads once the route completes'` (hero stays ₹1,318 under the scrim; two overlapping holds keep it held) | E110, NFR-12 |
| `'a Used from the Settings door sends no hold'` | FR-AD-5 |
| `'the snackbar reads "Insurance: ₹12,000 used"; TalkBack reads "Insurance: 12,000 rupees used"; it stays until dismissed under accessibleNavigation'` | AC-Y9, D105 |
| `'Undo does not reopen the sheet'` | AC-Y9 |
| `'deleting a saving with put-ins says what stays'` | AC-Y10 |
| `'hero before and after a used entry: ₹1,318 both'` (widget test over `FakeServices`) | BR-19, U7 |

- [ ] **Step 2: Run** → fails. **Step 3: Implement.** Each transformer gets a `// why:` (Used Undo is a plain handler; the `UsedBloc` save is `droppable()`). **Step 4: Verify** `flutter gen-l10n && flutter test test/settings test/home test/app && flutter analyze`.

---

### Task 9: *Used* rows in Today and Every entry (FR-HO-4, FR-SP-6, D187, NFR-11)

**Files**
- Modify: `lib/ledger/presentation/widgets/entry_row.dart`, `lib/spends/presentation/widgets/entries_day.dart`, `lib/spends/presentation/pages/entries_page.dart`, `lib/spends/presentation/bloc/entries_state.dart` (chips), `lib/home/presentation/widgets/today_list.dart` (no change expected), `lib/l10n/app_en.arb` (`entryUsed`, `entryUsedSpoken`, `entryUsedDetail`)
- Test: `test/ledger/presentation/widgets/entry_row_used_test.dart`, `test/spends/presentation/pages/entries_page_test.dart`, `test/home/presentation/widgets/today_list_test.dart`

**Behaviour**
- Row: line 1 the saving's name (the entry's note), line 2 "Used from savings", the amount at the end, the piggy-bank glyph (`AppIcons.saving`); **no tap** (like `saved`), no tint, no sign. Every entry adds the extra line "Paid from what you set aside." in the **same TalkBack node**. TalkBack: "Insurance. Used from savings 4,000 rupees." plus the extra line in Every entry.
- Not a bite (it is `used`, so already outside `todaySpends`), not in the header total or a day's total (the sums filter `spent`; assert, do not assume).
- Both lists expose *Delete* as a custom semantics action (NFR-11; `EntryRow` already does; assert it for `used`).
- Chips: `saved`, `card_paid` and `not logged` get none (D187, P13): check `EntriesState` first, because the category list comes from `categories.all()`, which already excludes archived rows; a *Used* entry shows under *All* only. If a Savings chip exists today, *Used* follows it (it does not: say so in the report after checking).

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| `'a used row reads the saving's name over "Used from savings", the amount at the end, the saving glyph'` | FR-HO-4 |
| `'it has no tap and no tint'` | FR-HO-4 |
| `'Today: a used row counts among the 5 and is in time order'` | FR-HO-4 |
| `'it is not a bite on today's bar and not in the header total'` | BR-6, FR-HO-4 |
| `'Every entry: the extra line "Paid from what you set aside." is in the same semantics node as the row'` | FR-SP-6, D187 |
| `'each day's total in Every entry leaves a used entry out'` | FR-SP-6 |
| `'swipe deletes with Undo and the amount is set aside again'` | BR-19 |
| `'Delete is a custom semantics action on a used row, in Today and in Every entry'` | NFR-11, P12 |
| `'there is no chip for savings or used; the entry shows under All'` | D187, P13 |
| `'the delete Undo of a used entry restores it with its saving_id'` | E97 |

- [ ] **Step 2: Run** → fails. **Step 3: Implement** (replace Task 2's compile stubs). **Step 4: Verify** `flutter gen-l10n && flutter test test/ledger test/spends test/home && flutter analyze`.

---

### Task 10: Ask AI and the CSV carry `used` (BR-15, D188)

**Files:** Modify `lib/ask_ai/domain/prompt_builder.dart`; Test `test/ask_ai/domain/prompt_builder_test.dart`, `test/helpers/fixtures/ask_ai/prompt_input.dart`

**Behaviour**
- CSV `kind` column gains `used` (`e.kind.name` already yields it); category `savings` for `used` as for `saved` (`_savingsCategory`); note = the saving's name (the entry note). `hideNotes` drops the note column as before.
- A fixed sentence **right after the facts** (BR-15 "Explaining lines"), **only when the export holds a `used` entry**: `Entries of kind "used" are costs the user paid from money they had already set aside in a saving, such as a yearly insurance bill. That money was counted when it was put in, so it is not spending in this period and does not change the daily number. Do not add it to spending.`
- The summary table by category and the "Earlier weeks (spent/got)" totals leave `used` out (they filter on `spent`/`got` already; assert).

- [ ] **Step 1: Write the failing tests**

| Test | Cites |
|---|---|
| `'an export with no used entry is byte-identical to the existing golden'` | BR-15 determinism, D188 |
| **`'golden: an export with a used entry'`** (the string, clause included, written out in full in the test) | BR-15, D188 (new golden 1 of 2) |
| `'a used entry's CSV row is date,amount,used,savings,<saving name>'` | BR-15 |
| `'with notes hidden the used row has no note column'` | BR-15 |
| `'the used clause comes right after the facts line, before the summary'` | BR-15 |
| `'used is in no category total and no weekly total (spent/got)'` | BR-19 |
| `'a used entry in a grouped older week is not counted as spending'` | D64 |
| `'a saving name with a comma is quoted'` | `PromptCsv.field` |

- [ ] **Step 2: Run** → fails. **Step 3: Implement** (replace the Task 2 stub). **Step 4: Verify** `flutter test test/ask_ai && flutter analyze`.

---

### Task 11: Backup, restore, wipe and the widget snapshot with `used`

**Files:** Test only, plus DI: `lib/ledger/di/ledger_module.dart`, `lib/app/routes.dart`, `test/helpers/fake_services.dart`
**Tests:** `test/backup/data/repository/backup_repository_impl_test.dart`, `test/shortcuts/domain/usecase/project_widget_days_test.dart`, `test/app/app_root_test.dart`

| Test | Cites |
|---|---|
| `'a backup with a used entry and a saving restores: kind, saving_id, note and created_at intact'` | BR-16, E101 |
| `'a v4 backup file restores with no message and gains the hidden rows'` (decoded through `BackupJsonMapper`, `_read` → `upgrade`) | BR-16, E101, NFR-5 |
| `'Undo restore puts the snapshot back with its used entries'` | BR-16 |
| `'Delete everything removes used entries'` | BR-16 |
| `'the widget snapshot after a used entry has the same hero for today and every later day'` (₹1,318 and the projected rows equal) | FR-WG-5, BR-19, U7 |
| `'ProjectedBook ignores a used entry in typedSpendsOn'` | FR-WG-3 |
| `'the app boots with GetSetAside and UseFromSavings registered'` | DI |

- [ ] **Step 1: Write the failing tests. Step 2: Run** `flutter test test/backup test/shortcuts test/app` → fails only on the wiring ones. **Step 3: Wire** `GetSetAside`/`UseFromSavings` in the ledger module, `FakeServices`, and the `bills(...)`/`openBillSheet(...)` closures. **Step 4: Verify** the three suites green; `flutter analyze` clean.

---

### Task 12: Docs and final verification

- [ ] **Docs (same change).** Update `docs/features/yearly-costs/01-ux-flow.md` (status: built; list the departures A1 to A9); `docs/PLAN.md` §12 M8 row step (3) done and §8 "migration 005 landed with plan 1"; `docs/DECISIONS.md` append rows **only if** a departure A1, A2, A6, A8 was accepted by the owner (do not edit SPEC/UI_DESIGN here: report instead). `docs/superpowers/plans/2026-11-13-missed-log-line.md` and `…fix-my-number.md` already assume migration 005: no edit.
- [ ] **Commands, in order, from the repo root:**

| Command | Expect |
|---|---|
| `flutter gen-l10n` | no errors; every new key has `@description` |
| `flutter analyze` | `No issues found` |
| `flutter test` | all green (the three version assertions now 5) |
| `scripts/changed_lines_coverage.sh $BASE` | total ≥ 90%; list gaps with a reason each; no `coverage:ignore` |
| `awk … BRDA` per changed file (tests.md) | every never-taken branch has a test or is listed under `Gaps:` |

- [ ] **Report in tests.md's format:** `Coverage (changed lines): <file n/n, …>`, `Total`, `Gaps:`.
- [ ] **Device checks (D14, with the build, not blocking tests):** the saving's sheet at 320×568 with the largest font; TalkBack reads *All of it* as selected; the Undo snackbar persists under TalkBack.

---

## Open questions for the owner (nothing here blocks the build)

1. **`saving_id` FK (A2).** `ON DELETE SET NULL` is the plan. If the owner would rather a *Used* row keep its link after a hard delete, use no FK (an integer plus the index). Rules are only soft-deleted today, so this only matters if a future change hard-deletes them.
2. **The caption keyed to the pill, not the name (A8).** A user who types "Insurance" by hand never sees the two-sentence caption. The alternative (key off the typed text) would show it on a saving the user calls "Insurance for the car" too; the plan prefers the pill because SPEC says "for the three new pills only".
3. **`success` timing on the Settings door (A6).** No figures roll in the list today; `success` fires at `UsedDone`.
4. **A *Used* for exactly the set-aside amount, then a late put-in (E95).** The cap re-reads in the write, so a put-in posted between opening the sheet and Save does not raise the cap for that Save. The user types again. SPEC is silent.
