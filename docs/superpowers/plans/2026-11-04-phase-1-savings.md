# Phase 1: Savings. Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An RD (or any monthly saving) is set up once in Settings → *Savings*, posts itself on its day as a *Saved* entry, is reserved before its day and never drains today's bar. Spends shows "Spent ₹X · Saved ₹Y", and the keep-aside setting is replaced by computed `K`.

**Architecture:**
- **Data.** A saving is a recurring rule of a new kind, `EntryKind.saved` (stored as `'save'`). The existing engine posts it like a fixed bill.
- **Formula.** `K` stops being a setting: `CycleInputs` gets `R`, `Sv_before`, `Sv_rule_today` and `Sv_extra_today`, and `keepAside` becomes a getter. `SafeToSpend._pool` is unchanged in form, and only `remaining` changes.
- **Screens.** Settings reuses the bill list, wizard and sheet (D118), switched on the rule's kind, so nothing is copied. *Put in extra* is the only new screen: a keypad sheet that reuses the bill sheet's route.
- **Migration.** Migration 003 rebuilds `recurring` and `transactions` to widen their `kind` CHECKs. It also adds everything Phase 2 needs (`'card'`, `amount_mode`, `recurring_skips`, the hidden `card_paid` category), so Phase 2 needs no migration of its own.

**Tech Stack:** Flutter 3.47 / Dart 3.13, sqflite (+ `sqflite_common_ffi` in tests), flutter_bloc + bloc_concurrency, fpdart, gen-l10n, hugeicons, hand-written fakes.

**Spec:** [docs/superpowers/specs/2026-11-04-savings-and-changing-bills-design.md](../specs/2026-11-04-savings-and-changing-bills-design.md): §9 phase 1, and the savings parts of §2–§5, §7 and §8. Research: [case study 17](../../design-research/case-studies/17-savings-and-rd.md), "B in detail" and "Formula impact". Phase 0 (`R_t`, D119) is built in `dff4d34`.

## Where this plan departs from the spec (the code moved on)
- **Migration number.** The spec says "migration 002, v1 → v2". Schema v2 already shipped as `migration_002_bill_icon.dart` (D118), so this plan adds **migration 003 (v2 → v3)**. The upgrade test starts from a **v1** file with data, so it runs 002 and then 003.
- **Hidden categories** are seeded rows with `archived = 1` and `kind = 'out'`. `CategoriesLocalDataSource.all()` already skips archived rows, so no grid, chart, chip or limit ever sees them. Only `recurring` and `transactions` need rebuilding. `categories` is the parent of both and is left alone, which avoids a third and riskier rebuild.
- **The bill sheet already exists** (D118, with an Icon row). A saving reuses it **without** the Icon row: every saving shows the piggy-bank glyph.
- ***Fixed bills* keeps its name** in Phase 1, because every bill is still fixed. The rename to *Bills* ships with changing bills in Phase 2.
- **`GetSavedTotal` takes no `since`.** The Savings footer is all-time ("₹5,000 put in since Oct", from the first saved entry; case study 17 Q5). The Spends line sums the shown cycle's own entries.
- **The preview reads ₹62, not ₹63.** Spec §5 says "₹63 less", while worked example 3 gives `1,403 − 1,341 = ₹62`. The preview is `tomorrow(remaining) − tomorrow(remaining − x)`, which gives ₹62.
- **E-b ("naming the saving").** `OverCard` doesn't name the bill for E5 either, so a saving that overdraws reads *Over for the cycle* the same way. Nothing extra is built.
- **Keep-aside is defensive.** No screen writes `keep_aside_minor` today (FR-SE-1's "Keep aside each month" was never built), so the migration only matters for a hand-edited database. Because D33 doesn't back-post, the converted rule first goes in on the next payday, and `K` for the current cycle drops to ₹0.

## Global Constraints
- Money is `int` paise in `Money`. Shares are floored to whole rupees (`SafeToSpend._floorShare`). Never use `double` for an amount; never show paise.
- "Today" comes from the injected `Clock`, and tests pin it with `FakeClock`. The **only** exception is migration 003's no-income keep-aside branch, which runs before DI exists and uses SQLite's `date('now','localtime')`, with a `// why:`.
- User-facing text lives only in `lib/l10n/app_en.arb`, followed by `flutter gen-l10n`. Banned words: "transaction", "debit/credit", "budget period", "Oops". The savings words are *saved*, *put in*, *goes in* and *Put in extra*, never "worth" or "balance" (spec §8, §11).
- No red, no green, no new colour. A saving is marked by a glyph and a word only. Icons are Hugeicons through `AppIcon`, always with a label.
- The Add flow is untouched: no *Saved* segment, no new tap (spec §10).
- No new dependency.
- Existing tests are the contract. A task that **changes** a documented rule names each test it changes and why, citing D120/D121. A signature-only edit in a test (a new required argument) is listed too. Any other test going red means stop and ask.
- **Decision numbers.** Before writing a DECISIONS row, run `grep -o '^| D[0-9]*' docs/DECISIONS.md | sort -t D -k2 -n | tail -1` and use the next free number. The plan calls the rows D120 (savings) and D121 (BR-8 wording), because the last row today is D119.
- **Commits** are local only. Never `git push` and never add a remote. Commit once per task, staging only that task's files (`git status` first: a parallel session may have its own changes). Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Before Task 1:** run `git rev-parse HEAD` and keep the hash as `BASE` for the coverage script.
- **Done** means `flutter analyze` is clean, `flutter test` is green, `scripts/changed_lines_coverage.sh $BASE` is ≥ 90% (uncovered lines listed with reasons), and SPEC, UI_DESIGN and DECISIONS are updated in the same change. There is a mockup for each new screen, and new screens are tested at every `TestWindows` size.

## Review Focus
1. **The upgrade must keep every entry's link to its rule.** With `foreign_keys = ON`, `DROP TABLE recurring` runs an implicit DELETE that fires `ON DELETE SET NULL` on `transactions.recurring_id`, which would turn every posted bill and salary into typed spending. → Task 1, test "upgrading a v1 database keeps ids, links and indexes", asserting `recurring_id` per row and `PRAGMA foreign_key_check` empty.
2. **Ask AI must not crash on a saved entry.** `_Names.of` does `_byId[id]!`, and a saved entry's category is hidden, so it isn't in `categories.all()`. → Task 8, test "a saved entry is listed as kind saved, category savings".
3. **Tapping a saved row must not open the Add tray.** The tray only knows *Spent*/*Got*, so an edit there would silently turn an RD into spending. → Task 6, test "a saved row has no tap action but can still be swiped away".
4. ***Put in extra* with nothing left** (`remaining ≤ 0`, Over for the cycle) or on the last day (`D = 1`). The first must save nothing; the second must not divide by zero. → Task 5, tests "with nothing left, Save does nothing" and "on the last day the preview says payday is tomorrow".
5. **Skipping a month by deleting the posted RD** must give the money back and must never be re-posted (`next_due` has already moved on). → Task 2, test "deleting this month's posted RD gives its money back and nothing re-posts it".

---

## File map
| File | Responsibility | Task |
|---|---|---|
| `lib/core/db/migrations/migration_003_savings_and_changing_bills.dart` (new) | Schema v3: rebuilt `recurring`/`transactions`, `recurring_skips`, hidden categories, keep-aside → rule | 1 |
| `lib/core/db/db_schema.dart`, `migrations/migrations.dart` | New names (`recurring_skips`, `amount_mode`, `'save'`, `'card'`); register 003 | 1 |
| `lib/ledger/domain/entities/entry_kind.dart`, `data/mapper/entry_kind_mapper.dart` | `EntryKind.saved` ↔ `'save'` | 1 |
| `lib/ledger/{domain/repository,data/repository,data/datasource}/category*` | `idOf(key)`, which also finds hidden categories | 1 |
| `lib/ledger/{domain/repository,data/repository,data/datasource}/ledger*`, `entries*`, `domain/entities/saved_total.dart` (new) | `savedTotal()` | 1 |
| `lib/ledger/domain/entities/cycle_inputs.dart`, `cycle_summary.dart`, `put_in_preview.dart` (new), `safe_to_spend.dart`, `due_amounts.dart` (new), `usecase/get_cycle_summary.dart`, `data/repository/recurring_repository_impl.dart` | Spec §3 formula; saves posted with their name as the note | 2 |
| `lib/ledger/domain/usecase/{add_bill,get_bills,get_due_soon_bill}.dart`, `get_saved_total.dart` (new), `put_in_extra.dart` (new), `entities/saving_kind.dart` (new), `failures/ledger_failures.dart`, `di/ledger_module.dart` | Use cases | 3 |
| `lib/ledger/presentation/rule_words.dart` (new), `bill_icon_extensions.dart`, `lib/core/design/app_icons.dart` | Bill or saving words and glyph, chosen by the rule's kind | 4 |
| `lib/settings/presentation/**` (BillsBloc/Page, BillEditorBloc/steps, bill sheet widgets, SettingsPage), `lib/app/routes.dart` | Savings list, wizard, sheet, Settings row | 4 |
| `lib/settings/presentation/bloc/put_in_extra_*.dart`, `pages/put_in_sheet.dart` (new) | *Put in extra* | 5 |
| `lib/ledger/presentation/widgets/entry_row.dart`, `lib/home/presentation/{widgets/due_soon_row.dart,pages/home_page.dart}` | Saved row, "goes in" nudge | 6 |
| `lib/spends/domain/{usecase/get_spends_overview.dart,entities/spends_overview.dart}`, `presentation/widgets/spent_saved_line.dart` (new), `pages/spends_page.dart` | "Spent ₹X · Saved ₹Y"; `I − K` from computed `K` | 7 |
| `lib/ask_ai/domain/{entities/prompt_input.dart,usecase/get_prompt_input.dart,prompt_builder.dart}`, `lib/ledger/domain/entities/budget_settings.dart`, `data/repository/budget_settings_repository_impl.dart` | Facts line, CSV, `keepAside` removed | 8 |
| `lib/l10n/app_en.arb` (BR-8 keys), `home/presentation/widgets/saved_yesterday_note.dart` (doc only) | BR-8 wording | 9 |

---

### Task 1: Migration 003 and the data layer

**Files:**
- Create: `lib/core/db/migrations/migration_003_savings_and_changing_bills.dart`, `lib/ledger/domain/entities/saved_total.dart`
- Modify: `lib/core/db/db_schema.dart`, `lib/core/db/migrations/migrations.dart`, `lib/ledger/domain/entities/entry_kind.dart`, `lib/ledger/domain/entities/category.dart` (`CategoryKeys.saved`), `lib/ledger/data/mapper/entry_kind_mapper.dart`, `lib/ledger/domain/repository/{category,ledger}_repository.dart`, `lib/ledger/data/repository/{category,ledger}_repository_impl.dart`, `lib/ledger/data/datasource/{categories,entries}_local_data_source.dart`, `lib/ledger/ledger.dart` (export `saved_total.dart`)
- Modify (fakes): `test/helpers/fakes/fake_category_repository.dart`, `test/helpers/fakes/fake_ledger_repository.dart`, `test/helpers/fixtures/ledger/categories.dart` (`SeedCategoryIds.saved = 11`)
- Modify (docs): `docs/PLAN.md` §8 data model
- Test: `test/core/db/app_database_test.dart`, `test/ledger/data/mapper/entry_mapper_test.dart`, `test/ledger/data/repository/{category,ledger}_repository_impl_test.dart`

**Interfaces:**
- Produces, in `db_schema.dart`:
  - `Tables.recurringSkips = 'recurring_skips'`
  - `RecurringColumns.amountMode = 'amount_mode'`
  - `RecurringSkipColumns { recurringId = 'recurring_id', date = 'date' }`
  - `EntryKindValues.saved = 'save'` and `EntryKindValues.cardPaid = 'card'`
  - `AmountModeValues { fixed, varies, card }`
- Produces: `migration003SavingsAndChangingBills(DatabaseExecutor db) → Future<void>`, appended to `migrations`, so `AppDatabase.schemaVersion == 3`.
- Produces: `enum EntryKind { spent, got, saved }`. `EntryKindMapper`: `saved` ↔ `'save'`. `'card'` stays unknown (`InvalidDataFailure`) until Phase 2.
- Produces: `CategoryKeys.saved = 'saved'`. The migration seeds keys `'saved'` and `'card_paid'` as literals (core can't import ledger); a test pins `'saved' == CategoryKeys.saved`.
- Produces: `CategoryRepository.idOf(String key) → TaskEither<Failure, int>`, backed by `CategoriesLocalDataSource.idOf(String key) → Future<int?>` (`SELECT id … WHERE key = ?`, archived or not). A missing key is `Left(InvalidDataFailure('No "$key" category'))`.
- Produces: `final class SavedTotal extends Equatable { const SavedTotal({required Money total, required CalendarDate since}); }`, plus `LedgerRepository.savedTotal() → TaskEither<Failure, Option<SavedTotal>>`, backed by `EntriesLocalDataSource.savedTotal() → Future<({int totalMinor, String? firstDate})>` (`SUM(amount_minor)` and `MIN(date)` where `kind = 'save'`). It returns none when there are no saved entries.
- Phase 1 neither reads nor writes `amount_mode`, `recurring_skips`, `'card'` or `card_paid`. They exist so Phase 2 has no schema bump. `RecurringModel` is unchanged: inserts get the `'fixed'` default, and its `update` doesn't name the column.

- [ ] **Step 1: Write the failing database tests** (group `'Schema v3 (D120)'` in `app_database_test.dart`; build the v1 file exactly as the existing "upgrading a v1 database…" test does)

| Test | Arrange | Assert |
|---|---|---|
| `'upgrading a v1 database keeps ids, links and indexes'` | v1 file with: salary rule id 1 (`in`, monthly, anchor `2026-10-04`, next_due `2026-11-04`, income source); rent rule id 2 (`out`, category 7); entries id 1 (salary, `recurring_id` 1, `2026-10-04`), id 2 (rent, `recurring_id` 2, `2026-10-05`), id 3 (typed, note `'Chai'`, `2026-10-26`) | after `AppDatabase.open`: `PRAGMA user_version` = 3; transactions ids `[1, 2, 3]` with `recurring_id` `[1, 2, null]` and note `'Chai'` on id 3; recurring ids `[1, 2]`, `icon` null, `amount_mode` `'fixed'` on both; `PRAGMA foreign_key_list(transactions)` names table `recurring`; `PRAGMA foreign_key_check` returns no rows; `PRAGMA index_list(transactions)` holds `ux_transactions_recurring_date`, `ix_transactions_date` and `ix_transactions_category_date`, and `index_list(recurring)` holds `ux_recurring_one_income_source`; re-inserting `(recurring_id 2, 2026-10-05)` with `ConflictAlgorithm.ignore` inserts 0 rows |
| `'v3 accepts saved and card entries and save rules'` | fresh database | a transaction with kind `'save'` and one with `'card'` insert; `'gift'` throws `DatabaseException`; a recurring row with kind `'save'` inserts; kind `'card'` on `recurring` throws; `amount_mode` `'varies'` inserts and `'weekly'` throws |
| `'recurring_skips holds one row per rule and date'` | fresh database, one rule | the first insert of `(rule, '2026-11-05')` succeeds; a second throws |
| `'hidden categories are seeded but never listed'` | fresh database | keys `'saved'` and `'card_paid'` exist with `archived = 1`; 10 rows have `archived = 0`; `'saved' == CategoryKeys.saved` |
| `'keep aside becomes a Keep aside saving on payday'` | v1 file with the salary rule above and setting `keep_aside_minor = '500000'` | one rule with label `'Keep aside'`, kind `'save'`, amount `500000`, freq `monthly`, anchor `'2026-10-04'`, next_due `'2026-11-04'`, last_day_of_month 0, and the `saved` category's id; no `keep_aside_minor` row is left |
| `'keep aside with no monthly income goes in on the 1st'` | v1 file, no income rule, `keep_aside_minor = '200000'` | the rule's next_due ends in `-01`, equals its anchor, and is ≥ `SELECT date('now','localtime')` |
| `'keep aside of zero makes no rule and is removed'` | `keep_aside_minor = '0'` | no `'save'` rule; the key is gone |
| `'a failed upgrade leaves the v2 database as it was'` | v2 file (001 + 002) with the rent rule, its entry and `keep_aside_minor`, plus a stray table named `recurring_v3` | `AppDatabase.open` returns `Left(DatabaseFailure)`; reopened raw at `version: 2`: `user_version` 2, the rows are unchanged, and the key is still there |

Add in `entry_mapper_test.dart`: `'saved round-trips as "save"'`. Add in `ledger_repository_impl_test.dart` (real SQLite): `'savedTotal sums Saved entries and dates the first'`, with saves of ₹5,000 on `2026-10-10` and ₹500 on `2026-10-26` and a ₹420 spend, giving `Some(SavedTotal(total: ₹5,500, since: 10 Oct 2026))`; and `'savedTotal is none with no saves'`. Add in `category_repository_impl_test.dart`: `'idOf finds a hidden category'` (`'saved'` → 11), `'idOf finds a seed'` (`'bills'` → 4), and `'idOf of an unknown key is InvalidDataFailure'`.

**Existing assertions that change (D120):**
- `'is at the latest schema version'`: `schemaVersion` becomes 3.
- `'seeds the fixed category list in order'`: add `where: '${CategoryColumns.archived} = 0'`, so the hidden rows aren't counted.
- `'reopening keeps data…'`: categories become `hasLength(12)`.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/db test/ledger/data`
Expected: compile errors (`EntryKind.saved`, `idOf`, `savedTotal`), then `user_version` 2 ≠ 3.

- [ ] **Step 3: Implement migration 003**

Use this statement order. It is the only order in which no drop fires `SET NULL` on a live link:
```
1  CREATE TABLE recurring_v3 (… v2 columns …, kind CHECK IN ('out','in','save'),
       amount_mode TEXT NOT NULL DEFAULT 'fixed' CHECK (amount_mode IN ('fixed','varies','card')))
2  INSERT INTO recurring_v3 (<every v2 column>) SELECT <same> FROM recurring
3  CREATE TABLE transactions_v3 (… v1 columns …, kind CHECK IN ('out','in','save','card'),
       recurring_id … REFERENCES recurring_v3(id) ON DELETE SET NULL)
4  INSERT INTO transactions_v3 SELECT <every column> FROM transactions
5  DROP TABLE transactions            -- the child goes first
6  DROP TABLE recurring               -- nothing references it any more
7  ALTER TABLE recurring_v3 RENAME TO recurring        -- rewrites transactions_v3's FK
8  ALTER TABLE transactions_v3 RENAME TO transactions
9  recreate ux_recurring_one_income_source, ix_transactions_date,
   ix_transactions_category_date, ux_transactions_recurring_date (v1 definitions)
10 CREATE TABLE recurring_skips (recurring_id INTEGER NOT NULL REFERENCES recurring(id) ON DELETE CASCADE,
       date TEXT NOT NULL, PRIMARY KEY (recurring_id, date))
11 INSERT categories ('saved','saved','out',sort 0,archived 1), ('card_paid','card_paid','out',sort 1,archived 1)
12 keep-aside → rule (below), then DELETE the keep_aside_minor setting
```
- **Comments.** Add a `// why:` on step 5 (the implicit DELETE of a parent fires `ON DELETE SET NULL`) and on step 10 (`startFresh` deletes rules, so skips must cascade).
- **Keep-aside, in Dart.** Read the setting. If it is a positive integer, insert a rule with:
  - label `'Keep aside'`. A `// why:` says it is stored data, like the onboarding labels, and no ARB string reaches the database.
  - kind `'save'` and the `saved` category's id.
  - from an active monthly income rule: its `anchor_date`, `last_day_of_month` and `next_due`. This keeps D33: it is the next payday the engine hasn't posted.
  - with no monthly income rule (none, or weekly or fortnightly pay): monthly on the 1st, with anchor = next_due = `CASE WHEN strftime('%d','now','localtime') = '01' THEN date('now','localtime') ELSE date('now','localtime','start of month','+1 month') END`.
- **Constant.** Keep `SettingKeys.keepAsideMinor`. Change its dartdoc to "removed by migration 003; nothing else reads it once Task 8 lands".

- [ ] **Step 4: Implement the data layer** from the Interfaces block: `EntryKind.saved` and the mapper, `idOf` (data source, repository and fake), and `savedTotal` (data source, repository and fake). `FakeCategoryRepository.idOf` looks the key up in `categories` first, then in a `hidden` map that defaults to `{'saved': 11, 'card_paid': 12}`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/core/db test/ledger`
Expected: all pass.

- [ ] **Step 6: Update PLAN §8**

- **Categories:** "hidden `saved` and `card_paid` rows (`archived = 1`) for saved and card-bill entries; never shown".
- **`recurring`:** kind `in/out/save`, plus `amount_mode`.
- **`transactions`:** kind `in/out/save/card`.
- **New row:** the `recurring_skips` table.
- **One sentence:** "Schema v3 (migration 003, D120) holds Phase 2's columns too."

- [ ] **Step 7: Commit**

```bash
git add lib/core/db lib/ledger test/core/db test/ledger test/helpers docs/PLAN.md
git commit -m "feat(db): schema v3 for savings, with keep-aside moved to a saving rule

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The formula (spec §3): `K` is computed, extras thin later days

**Files:**
- Create: `lib/ledger/domain/entities/put_in_preview.dart`, `lib/ledger/domain/due_amounts.dart` (both exported from `ledger.dart`)
- Modify: `lib/ledger/domain/entities/cycle_inputs.dart`, `cycle_summary.dart`, `lib/ledger/domain/safe_to_spend.dart`, `lib/ledger/domain/usecase/get_cycle_summary.dart`, `lib/ledger/data/repository/recurring_repository_impl.dart` (`_validatedModel`)
- Modify (fixture): `test/helpers/fixtures/ledger/worked_example.dart` (add `rd`)
- Modify (docs): `docs/SPEC.md` BR-3, BR-4, BR-5 #2, BR-7, BR-9 (engine posts saves); `docs/DECISIONS.md` (D120)
- Test: `test/ledger/domain/safe_to_spend_test.dart`, `test/ledger/domain/usecase/get_cycle_summary_test.dart`, `test/ledger/data/repository/recurring_repository_impl_test.dart`, `test/ledger/domain/usecase/post_due_recurring_test.dart`, `test/ledger/domain/entities_equality_test.dart`

**Interfaces:**
- Consumes: `EntryKind.saved` (Task 1).
- Produces on `CycleInputs`:
  - the `keepAside` constructor parameter is removed;
  - new required parameters: `savingsDue` (`R`), `savedBefore` (`Sv` in `[start, t−1]`), `savedByRuleToday` (`Sv_rule_today`) and `savedExtraToday` (`Sv_extra_today`), all `Money` and all in `props`;
  - `Money get keepAside => savingsDue + savedBefore + savedByRuleToday`, documented as "`K`, computed (spec §3, D120)".
- Produces on `CycleSummary`: `savedExtraToday` (`Money`, default `Money.zero`, in `props`) and `Money get remaining => pool - spentToday - savedExtraToday`.
- Produces: `sealed class PutInPreview`, with `EachDayLess(Money less)` and `PaydayTomorrow()`. Also `SafeToSpend.previewPutIn(CycleSummary summary, Money amount) → PutInPreview`, where `less = tomorrow(remaining) − tomorrow(remaining − amount)` and `PaydayTomorrow` when `daysLeft == 1`.
- Produces: `DueAmounts.after(Iterable<RecurringRule> rules, {required CalendarDate today, required PayCycle cycle}) → Money`. This is today's `_billsAfter` logic, made public, so Spends can reuse it for `R`.
- Changes: `SafeToSpend.compute` uses `remaining = pool − spentToday − savedExtraToday`. `previewSpend`'s `tomorrow` uses `summary.remaining − amount`. `GetCycleSummary` stops reading `settings.keepAside`, which Task 8 deletes.
- Changes: the engine posts a save rule's entry with `note: rule.label`, so the Today row can say "RD".

- [ ] **Step 1: Write the failing `SafeToSpend` tests**

In `_inputs`, replace `int keepAside = 0` with `int savingsDue = 0, int savedBefore = 0, int savedByRuleToday = 0, int savedExtraToday = 0`. The test `'keep aside is never spendable'` becomes `'money saved earlier this cycle is never spendable'`, with `savedBefore: 1650` and the same pool of ₹15,000 (D120). Add the group `'SafeToSpend — savings (spec §3, D120)'`. Today is the worked example's 26 Oct, with `D = 9`, `I = 45,000`, `B = 1,200`, `S_prev = 27,150` and `S_today = 420`:

| Test | Inputs | Expect |
|---|---|---|
| `'an RD posted on the 10th leaves ₹1,294 for today (worked example 3)'` | `savedBefore: 5000` | `pool` ₹11,650, `todayShare` ₹1,294, `safeToday` ₹874 |
| `'the share is the same whether the RD is still to come, posted today or posted earlier'` | `savingsDue: 5000` / `savedByRuleToday: 5000` / `savedBefore: 5000` | `todayShare` ₹1,294 for each |
| `'K is the three saving terms'` | `savingsDue: 1000, savedBefore: 2000, savedByRuleToday: 3000` | `inputs.keepAside` ₹6,000 |
| `'₹500 put in today keeps the share and thins tomorrow'` | `savedBefore: 5000, savedExtraToday: 500` | `todayShare` ₹1,294, `safeToday` ₹874, `tomorrowShare` `Some(₹1,341)`, `remaining` ₹10,730, `state` `OnTrack()` |
| `'an extra thins the spare at payday'` | `savedBefore: 5000`, then with `savedExtraToday: 500` | `LastsTillPayday(₹4,300)` → `LastsTillPayday(₹3,800)` |
| `'previewPutIn: ₹500 makes each day till payday ₹62 less'` | `savedBefore: 5000` | `previewPutIn(s, ₹500) == EachDayLess(₹62)` |
| `'previewPutIn on the last day says payday is tomorrow (E-h)'` | `today: 3 Nov 2026` | `PaydayTomorrow()` |
| `'previewSpend after an extra uses what is left'` | `savedBefore: 5000, savedExtraToday: 500` | `previewSpend(s, ₹1,000) == OverTodayShare(over: ₹126, tomorrow: Some(₹1,216))` |
| `'a saving bigger than everything left is Over for the cycle (E-b)'` | `savedByRuleToday: 20000` | `todayShare` ₹0, `state` `OverCycle(₹3,770)` |

- [ ] **Step 2: Write the failing `GetCycleSummary` tests**

Add `WorkedExample.rd`: id 4, label `'RD'`, ₹5,000, `EntryKind.saved`, category `SeedCategoryIds.saved`, monthly, anchor 10 Oct 2026, `nextDue` 10 Nov 2026. Extend the file's `addEntry` with a `kind` argument (it already takes one). The test `'keep aside reduces the pool'` becomes `'money saved earlier in the cycle reduces the pool'`: `addEntry(1650, 10 Oct, kind: EntryKind.saved)`, with the pool still ₹15,000 (D120). Add the group `'GetCycleSummary — savings (D120)'`:

| Test | Arrange | Assert |
|---|---|---|
| `'an RD posted on the 10th leaves ₹1,294 for today'` | rules + `rd`; `addEntry(5000, 10 Oct, kind: saved, recurringId: 4)` | `pool` ₹11,650, `todayShare` ₹1,294, `safeToday` ₹874, `spentToday` ₹420 |
| `'the pool doesn't move on the RD's day'` | `rd` anchored on the 26th. On 25 Oct (`setToday`): `nextDue` 26 Oct, no entry. On 26 Oct: `nextDue` 26 Nov, entry ₹5,000 dated 26 Oct | `pool` ₹11,650 on both days |
| `'₹500 put in today: share ₹1,294, tomorrow ₹1,341'` | the RD entry, plus `addEntry(500, 26 Oct, kind: saved)` | `todayShare` ₹1,294, `tomorrowShare` `Some(₹1,341)`, `spentToday` ₹420, `spentThisWeek` ₹420 |
| `'an RD posted today was still to come yesterday (BR-8)'` | `setToday(27 Oct)`; `rd` anchored on the 27th with `nextDue` 27 Nov; entry ₹5,000 dated 27 Oct | `savedYesterday == Some(YesterdaySaving(saved: ₹874, eachDayMore: ₹109))` |
| `'deleting this month's posted RD gives its money back and nothing re-posts it'` | `rd` with `nextDue` 10 Nov and no RD entry | `pool` ₹16,650 and `todayShare` ₹1,850. In `post_due_recurring_test`, the same rule on 26 Oct posts 0 entries |

In `recurring_repository_impl_test.dart` (real SQLite), add `'a save rule posts a Saved entry named after it'`: post an `Occurrence(rd, 10 Oct)`; the row has kind `'save'`, note `'RD'` and `recurring_id` 4. Add `'saves catch up once each after weeks away (E-g)'` in `post_due_recurring_test.dart`: `rd` with `nextDue` 10 Oct and today 26 Nov 2026 posts 10 Oct and 10 Nov, then `nextDue` becomes 10 Dec.

- [ ] **Step 3: Run them to verify they fail**

Run: `flutter test test/ledger`
Expected: compile errors (`savedBefore`, `previewPutIn`, `remaining`).

- [ ] **Step 4: Implement**

- **`CycleInputs`, `CycleSummary`, `PutInPreview`, `DueAmounts`:** as in Interfaces.
- **`SafeToSpend`:** `_pool` stays `income − keepAside − billsDue − spentBefore − billsPostedToday`, with `keepAside` now the getter. `compute` and `previewSpend` change as stated.
- **`GetCycleSummary._summarise`:**
  - `billsDue` is `DueAmounts.after(spent rules, …)` and `savingsDue` is `DueAmounts.after(saved rules, …)`.
  - `_DayTotals.inputs(today, entries, {billsDue, savingsDue})` splits *Saved* entries into before, rule-today and extra-today.
  - `_asItStood` adds rule-posted saves dated after `date` to `savingsDue`, mirroring `postedSince` for bills, with a `// why:` naming BR-8.
- **`RecurringRepositoryImpl._validatedModel`:** add `note: rule.kind == EntryKind.saved ? rule.label : null` to the draft.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/ledger test/add_entry test/home`
Expected: green. The Add tray and Home use `previewSpend` and the summary, and their numbers are unchanged when nothing is saved.

- [ ] **Step 6: Update the docs**

- **SPEC BR-3:**
  - The `K` row becomes "computed: `R + Sv_before + Sv_rule_today` (D120)".
  - Add rows for `R`, `Sv_before`, `Sv_rule_today` and `Sv_extra_today`, worded as in spec §3.
  - Add the sentence "anything a rule posts is set aside before its day and comes out of the pool on its day".
  - Add worked example 3.
- **SPEC BR-4:**
  - `remaining = P − S_today − Sv_extra_today`.
  - `tomorrow = floor(remaining / (D − 1))`.
  - "A *Put in extra* leaves today's `A` fixed and thins the later days."
- **SPEC BR-5 #2:** the condition becomes `remaining < 0`.
- **SPEC BR-7:** `spare = remaining − pace × (D − 1)`. The pace counts *Spent* only.
- **SPEC BR-9:** the engine also posts *Saved* rules, with the rule's name as the note.
- **SPEC §5:** add E-a, E-b, E-g and E-k from spec §7, for savings.
- **DECISIONS D120 (2026-11-04).**
  - **Decision:** "Savings replace keep-aside: a monthly *Saved* rule posted by the engine; `K = R + Sv_before + Sv_rule_today`; *Put in extra* thins later days; schema v3 (migration 003) also carries Phase 2's columns; hidden categories are archived rows; a saved row can be deleted but not edited in the Add tray".
  - **Why:** "an RD logged as *Spent* inflated spending and could read *Over today*; keep-aside had no date or record (case study 17)".
  - **Rejected:** "a visible keep-aside row (A); savings pots with targets (C); a *Saved* segment in Add".

- [ ] **Step 7: Commit**

```bash
git add lib/ledger test/ledger test/helpers docs/SPEC.md docs/DECISIONS.md
git commit -m "feat(ledger): savings are reserved before their day; K is computed

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Use cases (add, list, due soon, total, Put in extra)

**Files:**
- Create: `lib/ledger/domain/entities/saving_kind.dart`, `lib/ledger/domain/usecase/get_saved_total.dart`, `lib/ledger/domain/usecase/put_in_extra.dart`
- Modify: `lib/ledger/domain/usecase/add_bill.dart`, `get_bills.dart`, `get_due_soon_bill.dart`, `lib/ledger/domain/failures/ledger_failures.dart`, `lib/ledger/di/ledger_module.dart`, `lib/ledger/ledger.dart`, `test/helpers/fake_services.dart`, and every `GetBills` call site (`lib/settings/presentation/bloc/bills_bloc.dart`)
- Test: `test/ledger/domain/usecase/{add_bill,get_bills,get_due_soon_bill,get_saved_total,put_in_extra}_test.dart`

**Interfaces:**
- Consumes: `CategoryRepository.idOf`, `LedgerRepository.savedTotal` (Task 1); `CycleSummary.remaining` (Task 2).
- Produces: `enum SavingKind { rd, sip, goldScheme, chit }`. These are the pills, in order.
- Produces: `AddBillParams({required BillInput input, Option<BillKind> kind = none, EntryKind entryKind = EntryKind.spent})`.
  - `AddBill` looks the category up with `idOf`: `CategoryKeys.saved` for a saving, else the chip's key or `bills`.
  - The draft's kind is `entryKind`.
  - **AddSaving, EditSaving and DeleteSaving (spec §4) are `AddBill` with `entryKind: saved`, plus `EditBill` and `DeleteBill`/`RestoreBill` unchanged.** Those already work on any rule id and keep the rule's kind, so there are no copies.
- Produces: `GetBills implements UseCase<List<RecurringRule>, EntryKind>`, which returns active rules of that kind, soonest first.
- Changes: `GetDueSoonBill` considers `spent` **and** `saved` rules. The first rule still wins a tie.
- Produces: `GetSavedTotal implements UseCase<Option<SavedTotal>, NoParams>`.
- Produces: `PutInExtra({required GetCycleSummary getCycleSummary, required LedgerRepository ledger, required CategoryRepository categories, required Clock clock}) implements UseCase<Entry, Money>`.
  - It validates the amount (`EntryValidator.validateAmount`).
  - It fails with `PutInTooMuchFailure` when `amount > summary.remaining`.
  - Otherwise it adds `EntryDraft(kind: saved, categoryId: idOf('saved'), date: today, note: null)`.
- Produces: `final class PutInTooMuchFailure extends Failure`.
- Test edits that change signatures only: `getBills(const NoParams())` becomes `getBills(EntryKind.spent)` in `get_bills_test.dart`.

- [ ] **Step 1: Write the failing tests** (today is 26 Oct 2026, with the worked example)

| File | Test | Assert |
|---|---|---|
| `add_bill_test` | `'a saving is a Saved rule in the hidden category, first going in on its next day'` | `AddBillParams(input: RD ₹5,000 day 10, entryKind: saved)` gives a rule with kind `saved`, category 11, anchor 10 Oct, `nextDue` 10 Nov |
| `add_bill_test` | `'a saving due today goes in today (D33)'` | day 26 gives `nextDue` 26 Oct |
| `get_bills_test` | `'lists only rules of the asked kind, soonest first'` | with rent, electricity and `rd`: `spent` gives `[electricity, rent]` and `saved` gives `[rd]` |
| `get_due_soon_bill_test` | `'a saving 2 days away is due soon'` | without electricity, `rd` with `nextDue` 28 Oct gives `DueSoonBill(rule: rd, dueDate: 28 Oct, daysAway: 2)` |
| `get_due_soon_bill_test` | `'a bill and a saving on the same day: the first rule wins'` | `rd` with `nextDue` 29 Oct gives electricity |
| `get_saved_total_test` | `'none with no saves'`, `'₹5,500 since 10 Oct'` | as in Task 1's repository test, through the fake |
| `put_in_extra_test` | `'₹500 is saved today as an extra'` | the fake ledger gains `EntryDraft(₹500, saved, 11, 26 Oct, note: null)` with no `recurringId` |
| `put_in_extra_test` | `'the most it takes is what is left: ₹11,230'` | with the RD entry: ₹11,230 succeeds; ₹11,231 is `Left(PutInTooMuchFailure)` and nothing is added |
| `put_in_extra_test` | `'₹0 is refused'` | `Left(InvalidAmountFailure)` |

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/ledger/domain/usecase`
Expected: compile errors (`entryKind`, `GetSavedTotal`, `PutInExtra`).

- [ ] **Step 3: Implement as in Interfaces**, and register `GetSavedTotal` and `PutInExtra` in `registerLedgerServices` and in `test/helpers/fake_services.dart`. `BillsBloc` passes `EntryKind.spent` for now; Task 4 makes it the bloc's kind.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/ledger test/settings test/home`
Expected: green.

- [ ] **Step 5: Commit**

```bash
git add lib/ledger lib/settings test/ledger test/helpers
git commit -m "feat(ledger): add, list and put in savings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Settings → Savings (list, wizard, sheet), reusing the bill screens

**Files:**
- Create: `lib/ledger/presentation/rule_words.dart`, `docs/design/mockups/28-savings.html`, `docs/design/mockups/28-savings-copy-deck.md`
- Modify: `lib/core/design/app_icons.dart` (`saving = HugeIcons.strokeRoundedPiggyBank`), `lib/ledger/presentation/bill_icon_extensions.dart`, `lib/l10n/app_en.arb`
- Modify (generalise, never copy):
  - `lib/settings/presentation/bloc/bills_bloc.dart`, `bills_state.dart`
  - `pages/bills_page.dart`
  - `bloc/bill_editor_bloc.dart`, `bill_editor_event.dart`
  - `widgets/bill_name_step.dart`, `bill_amount_step.dart`, `bill_day_step.dart`, `bill_row.dart`
  - `widgets/bill_sheet/{bill_summary,bill_head,bill_icon_well,bill_question_frame,bill_amount_question,bill_day_question,bill_name_question,bill_sheet_copy}.dart`
  - `pages/settings_page.dart`
  - `lib/app/routes.dart`
- Modify (docs): `docs/SPEC.md` FR-SE-1 (the Savings bullets replace "Keep aside each month"), `docs/UI_DESIGN.md` §5.6, `docs/design/README.md` (mockup 28 row)
- Test: `test/ledger/presentation/rule_words_test.dart`, `test/settings/presentation/{bloc/bills_bloc_test,bloc/bill_editor_bloc_test,pages/bills_page_test,pages/bill_editor_page_test,pages/bill_sheet_test,pages/settings_page_test}.dart`

**Interfaces:**
- Consumes: `GetBills(EntryKind)`, `AddBillParams.entryKind`, `GetSavedTotal`, `SavingKind` (Task 3).
- Produces: `extension RuleWords on AppLocalizations`. Each method returns the bill string for `EntryKind.spent` and the `saving*` string for `EntryKind.saved`:
  - `ruleListTitle(k)`, `ruleListHint(k)`, `ruleAdd(k)`, `ruleNone(k)`
  - `ruleNameQuestion(k)`, `ruleNameHint(k)`, `ruleAmountQuestion(k, label)`, `ruleDayQuestion(k, label)`
  - `ruleEyebrow(k)`, `ruleDelete(k)`, `ruleNext(k, date)`, `ruleStampDue(k, days)`, `ruleStampCounted(k, date)`, `ruleStampCountedToday(k)`, `ruleSlipSpoken(rule, icon, amount, day)`
  - `ruleDeleted(RecurringRule)`, `ruleGoesOut(RecurringRule, String amount, int days, String weekday)`, `ruleOpensHint(k)`
- Produces: `extension RuleGlyph on RecurringRule { AppIconData get glyph }`. A saving always shows `AppIcons.saving`; a bill shows `shownIcon.glyph`.
- Changes:
  - **`BillIconWell`, `BillHead` and `BillQuestionFrame`** take `AppIconData glyph` instead of `BillIcon icon`, and every caller passes `rule.glyph`.
  - **`BillSheetCopy.stampText(BillStatus status, {EntryKind kind = EntryKind.spent})`.**
  - **`BillsBloc`** gets `{EntryKind kind = EntryKind.spent, required GetSavedTotal getSavedTotal, required LedgerRepository ledger}`. It loads `GetSavedTotal` only for `saved`, and it reloads on `ledger.changes` as well as `recurring.changes`.
  - **`BillsReady`** gets `saved: Option<SavedTotal>` (default none).
  - **`BillsPage`** gets `{EntryKind kind = EntryKind.spent, VoidCallback? onPutInExtra}`.
  - **`BillEditorBloc`** gets `{EntryKind kind = EntryKind.spent}`, exposed as `final EntryKind kind`. It saves with `entryKind: kind`.
  - **New event `BillEditorSavingPicked(SavingKind kind, String label)`.** It fills the name and ticks, and the state's `kind` (`BillKind`) stays none.
  - **`SettingsPage`** gets `required VoidCallback onOpenSavings`.
  - **`AppRoutes`:** `bills(getIt, {EntryKind kind = EntryKind.spent})` and `billEditor(getIt, {EntryKind kind = EntryKind.spent})`.
- On a saving, **`BillSummary`** has 3 rows (Amount, Day of the month, Name) and no Icon row. **`BillNameQuestion`**'s caption is `billEveryMonth(day)` rather than the icon line. **`BillNameStep`** offers the `SavingKind` pills.
- Test edits that change signatures only: `BillsBloc(...)` in `bills_bloc_test`/`bills_page_test` gains `getSavedTotal:` and `ledger:`; `SettingsPage(...)` gains `onOpenSavings:`.

- [ ] **Step 1: Get the copy from `design-content`**

Dispatch the `design-content` agent (`.claude/agents/design-content.md`). It reads spec §5 and §8, case study 17 and the existing `bill*` ARB strings, and writes `docs/design/mockups/28-savings-copy-deck.md`, with one row per key, its final text and a reason. Brief it that banned words apply, plus "worth" and "balance"; that "saved" may only mean real saving; and that the defaults below win unless it gives a reason. The deck also settles **BR-8** (Task 9). The defaults, which are also what tests assert unless the deck changes them:

| Key | Default |
|---|---|
| `savings` | Savings |
| `savingsHint` | Money you put away on the same day every month, like an RD. Today's share already leaves room for it. |
| `addSaving` / `noSavings` | Add a saving / No savings yet. Add an RD, SIP or anything you put in every month. |
| `savingName` | `{kind, select, rd{RD} sip{SIP} goldScheme{Gold scheme} chit{Chit} other{Saving}}` |
| `savingNameQuestion` / `savingNameHint` | What do you save in? / RD, SIP, gold scheme… |
| `savingAmountQuestion` / `savingDayQuestion` | How much goes into {saving}? / Which day does {saving} go in? |
| `savingSheetEyebrow` / `deleteSaving` / `savingDeleted` | Saving / Delete saving / Deleted {saving} |
| `savingStampDue` | `{days, plural, =1{Goes in tomorrow} other{In {days} days}}` |
| `savingStampCounted` / `savingStampCountedToday` | Put in {date} / Put in today |
| `savingNextGoesIn` / `savingSlipSpoken` | Next goes in on {date} / {saving}, {amount}, every month on day {day} |
| `savingGoesIn` | `{saving} {amount} goes in {days, plural, =1{tomorrow} other{on {weekday}}}` |
| `dueSoonOpensSaving` | Opens the saving. |
| `entrySaved` / `entryPutInExtra` | Saved / Put in extra |
| `savedSince` | {amount} put in since {month} |
| `putInExtra` / `putInQuestion` | Put in extra / How much extra are you putting in? |
| `putInEachDayLess` | `{end, select, monthEnd{Each day till month end gets {amount} less} other{Each day till payday gets {amount} less}}` |
| `putInLastDay` | `{end, select, monthEnd{The month ends today.} other{Payday's tomorrow.}}` |
| `putInNothingLeft` | Nothing left to put in this cycle. |
| `spentAndSaved` | Spent {spent} · Saved {saved} |
| `savedYesterday` / `savedYesterdayOnly` (BR-8) | Yesterday came in {amount} under, so every day got {more} more. / Yesterday came in {amount} under. |

- [ ] **Step 2: Draw mockup 28**

Create `docs/design/mockups/28-savings.html` in the style of mockup 27 (the `design-ui` agent may do this). It shows, in light and dark:
- Settings with *Fixed bills* and *Savings*
- the Savings list with the footer and *Put in extra*
- the saving sheet (3 rows, "Put in 10 Oct")
- the *Put in extra* sheet showing "Each day till payday gets ₹62 less"
- Home with the row "RD · ₹5,000 · Saved" and the nudge "RD ₹5,000 goes in on Thu"
- the Spends line "Spent ₹27,570 · Saved ₹5,000"

Add its row to `docs/design/README.md`.

- [ ] **Step 3: Write the failing tests**

| File | Test | Assert |
|---|---|---|
| `rule_words_test` | `'bill and saving words differ only where they should'` | `ruleDayQuestion(spent, 'Rent')` is "Which day does Rent go out?"; `ruleDayQuestion(saved, 'RD')` is "Which day does RD go in?"; `ruleDeleted(rd)` is "Deleted RD" |
| `bills_bloc_test` | `'a savings list loads saving rules and the total'` | `kind: saved` gives `BillsReady(bills: [rd], saved: Some(SavedTotal(₹5,000, 10 Oct)))`; GetBills was asked for `saved` |
| `bills_bloc_test` | `'a savings list reloads when an entry changes'` | after a ledger write, the total becomes ₹5,500 |
| `bills_page_test` | `'the Savings list: title, add, rows, footer, Put in extra'` | texts "Savings", "Add a saving", "RD", "₹5,000 put in since Oct"; tapping `ValueKey('put-in-extra')` calls `onPutInExtra` |
| `bills_page_test` | `'no saves yet: no footer'` | "put in since" is not found |
| `bills_page_test` | `'the Savings list fits every TestWindows size'` | pump at each size; no overflow exception |
| `bill_editor_bloc_test` | `'a saving is saved with its day'` | `kind: saved`: pick RD (`BillEditorSavingPicked`), type 5000, choose day 10; AddBill gets `entryKind: saved`, label 'RD'; the state is `BillEditorSaved` |
| `bill_editor_page_test` | `'the saving questions say goes in'` | "What do you save in?", the 4 pills `saving-rd`…`saving-chit`, then "How much goes into RD?", then "Which day does RD go in?" |
| `bill_sheet_test` | `'a saving's sheet: eyebrow, 3 rows, stamp, delete'` | "Saving"; `bill-row-icon` is absent; with status counted on 10 Oct and today 26 Oct, "Put in 10 Oct"; "Next goes in on 10 Nov"; "Delete saving" |
| `settings_page_test` | `'Savings opens the savings list'` | `ValueKey('open-savings')` reads "Savings"; a tap calls `onOpenSavings` |

All existing bill tests stay green unchanged: the bill path is the `spent` default.

- [ ] **Step 4: Run them to verify they fail**

Run: `flutter test test/ledger/presentation test/settings`
Expected: compile errors (`RuleWords`, `onOpenSavings`, `BillEditorSavingPicked`).

- [ ] **Step 5: Implement**

1. Add the ARB keys from the deck and run `flutter gen-l10n`.
2. Add `RuleWords`, `RuleGlyph` and `AppIcons.saving`.
3. Generalise each class as listed in Interfaces. Each widget picks its words with `strings.rule…(rule.kind)` (or `bloc.kind` in the wizard), and `BillNameStep` builds pills from `SavingKind.values` when `bloc.kind == saved`.
4. `routes.dart`:
   - `settings()` passes `onOpenSavings: () => push(bills(getIt, kind: EntryKind.saved))`.
   - `bills()` passes `kind` to `BillsBloc` and `BillsPage`, and `onAdd` pushes `billEditor(getIt, kind: kind)`.
   - Leave `onPutInExtra` null until Task 5.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/ledger test/settings test/app`
Expected: green.

- [ ] **Step 7: Update the docs**

- **SPEC FR-SE-1:** replace "Keep aside each month" with a *Savings* bullet:
  - the same list, three questions ("goes in") and sheet as bills;
  - pills RD, SIP, Gold scheme, Chit; monthly only;
  - a hidden category; no Icon row (the piggy-bank glyph);
  - the footer "₹X put in since {Mon}" (all time, never "worth" or "balance");
  - *Put in extra* (Task 5).
- **UI_DESIGN §5.6:** the same, in its own words, linking mockup 28.

- [ ] **Step 8: Commit**

```bash
git add lib test/ledger test/settings docs/SPEC.md docs/UI_DESIGN.md docs/design
git commit -m "feat(settings): Savings list, wizard and sheet on the bill screens

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: *Put in extra*

**Files:**
- Create: `lib/settings/presentation/bloc/put_in_extra_bloc.dart`, `put_in_extra_event.dart`, `put_in_extra_state.dart`, `lib/settings/presentation/pages/put_in_sheet.dart`
- Modify: `lib/settings/presentation/pages/bill_sheet.dart` (extract the route), `lib/app/routes.dart` (`onPutInExtra`), `lib/settings/settings.dart` (exports)
- Modify (docs): `docs/SPEC.md` FR-SE-1 *Put in extra* acceptance criteria, `docs/UI_DESIGN.md` §5.6
- Test: `test/settings/presentation/bloc/put_in_extra_bloc_test.dart`, `test/settings/presentation/pages/put_in_sheet_test.dart`

**Interfaces:**
- Consumes: `GetCycleSummary`, `PutInExtra`, `SafeToSpend.previewPutIn`, `PutInPreview` (Tasks 2–3).
- Produces: `BillSheet.route(BuildContext context, {required WidgetBuilder builder}) → ModalBottomSheetRoute<void>`. This is the body of today's `show` route, unchanged. `BillSheet.show` now uses it.
- Produces: `PutInExtraBloc({required GetCycleSummary getCycleSummary, required PutInExtra putInExtra, required Haptics haptics})`.
  - Events: `PutInExtraLoadRequested` (`restartable`), `PutInExtraKeyPressed(String key)`, `PutInExtraBackspacePressed`, `PutInExtraCleared` and `PutInExtraSavePressed` (`droppable`).
  - States: `PutInExtraLoading`, `PutInExtraFailed(Failure)`, `PutInExtraDone`, and `PutInExtraReady({required CycleSummary summary, int rupees = 0, int rejections = 0, bool saving = false, bool saveFailed = false})`.
  - `PutInExtraReady` getters: `int roomRupees` (`max(0, summary.remaining.floorMajor)`), `bool nothingLeft` (`roomRupees == 0`) and `Option<PutInPreview> preview` (none at ₹0).
  - A key that would take `rupees` above `roomRupees` is rejected: `rejections + 1` and a reject haptic, as the bill keypad does.
- Produces: `PutInSheet.show(BuildContext context, PutInExtraBloc bloc) → Future<void>`.
  - The sheet shows the question, an `AmountDisplay`, the preview line or the nothing-left line, a `Keypad` and a *Save* `SignalKey`.
  - Save is disabled at ₹0, while saving and when nothing is left.
  - A save closes the sheet with a success haptic. There is no snackbar: the footer total is the feedback, and the entry can be swiped away on Home.

- [ ] **Step 1: Write the failing tests** (the fakes hold the worked example plus the RD entry, so `remaining` is ₹11,230)

| Test | Assert |
|---|---|
| `'loads today's summary'` | `PutInExtraReady` with `roomRupees` 11230 |
| `'₹500 previews each day ₹62 less'` | keys 5, 0, 0 give `preview == Some(EachDayLess(₹62))` |
| `'a key past what is left is refused'` | typing 1,1,2,3,0 gives `rupees` 11230; another `0` leaves 11230 and `rejections` 1 |
| `'on the last day the preview says payday is tomorrow'` | clock on 3 Nov 2026: `preview == Some(PaydayTomorrow())` |
| `'with nothing left, Save does nothing'` | today's spending exceeds the pool (add ₹12,000 spent today): `nothingLeft`; `PutInExtraSavePressed` doesn't call PutInExtra |
| `'Save puts it in and finishes'` | ₹500 then Save: PutInExtra got ₹500; the state is `PutInExtraDone` |
| `'a failed save says so'` | the ledger fails: `saveFailed` true and the state stays Ready |
| (widget) `'the sheet shows the preview and closes on Save'` | after 5, 0, 0: "Each day till payday gets ₹62 less"; Save pops the sheet |
| (widget) `'month-end wording'` | an `endsAtMonthEnd` summary reads "Each day till month end gets ₹62 less" |
| (widget) `'fits every TestWindows size'` | no overflow |

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/settings/presentation/bloc/put_in_extra_bloc_test.dart test/settings/presentation/pages/put_in_sheet_test.dart`
Expected: compile errors.

- [ ] **Step 3: Implement as in Interfaces.** In `routes.dart`, `bills()` passes `onPutInExtra` for `EntryKind.saved` only. It opens `PutInSheet.show(context, PutInExtraBloc(...)..add(const PutInExtraLoadRequested()))`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/settings`
Expected: green, `bill_sheet_test` included (the route extraction must not change it).

- [ ] **Step 5: Update the docs**

SPEC FR-SE-1 gets *Put in extra* AC-1 to AC-4:
- **AC-1:** it opens the keypad in a sheet.
- **AC-2:** the preview is `tomorrow(remaining) − tomorrow(remaining − x)` ("₹62 less" in the worked example), or "Payday's tomorrow." when `D = 1` (E-h).
- **AC-3:** the keypad refuses more than `remaining`; with nothing left, it reads "Nothing left to put in this cycle."
- **AC-4:** Save posts a *Saved* entry dated today and closes.

UI_DESIGN §5.6 gets the same.

- [ ] **Step 6: Commit**

```bash
git add lib/settings lib/app test/settings docs/SPEC.md docs/UI_DESIGN.md
git commit -m "feat(settings): put in extra, capped at what is left

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Home: the saved row and the "goes in" nudge

**Files:**
- Modify: `lib/ledger/presentation/widgets/entry_row.dart`, `lib/home/presentation/widgets/due_soon_row.dart`, `lib/home/presentation/pages/home_page.dart` (`_offerBillUndo`)
- Modify (docs): `docs/SPEC.md` BR-9 (the due-soon sentence for savings), FR-HO-3, FR-HO-4, BR-10 (saved rows); `docs/UI_DESIGN.md` §5.2
- Test: `test/ledger/presentation/widgets/entry_row_test.dart`, `test/home/presentation/widgets/due_soon_row_test.dart`, `test/home/presentation/bloc/home_bloc_test.dart`, `test/home/presentation/pages/home_page_test.dart`

**Interfaces:**
- Consumes: `RuleWords`, `RuleGlyph`, `AppIcons.saving`, `entrySaved`, `entryPutInExtra` (Task 4); `GetDueSoonBill` with savings (Task 3).
- Changes: a *Saved* entry in `EntryRow` has:
  - the leading glyph `AppIcons.saving`;
  - the title `entry.note ?? strings.entryPutInExtra`;
  - the second line `strings.entrySaved`;
  - the amount plain, with no "+";
  - **`InkWell.onTap: null`**. Swipe and the TalkBack Delete action stay, and a delete is the "skip this month" (case study 17 §4).
- Changes: `DueSoonRow` uses `bill.rule.glyph`, `strings.ruleGoesOut(rule, amount, daysAway, weekday)` (weekday `EEE` of `dueDate`) and `strings.ruleOpensHint(rule.kind)`. Home's bill-undo snackbar uses `strings.ruleDeleted(rule)`.
- Unchanged and pinned by tests: `HomeReady.todaySpends` (kind `spent`, no rule), so a saving is never a bite on today's bar; `todayEntries` lists it.

- [ ] **Step 1: Write the failing tests**

| File | Test | Assert |
|---|---|---|
| `entry_row_test` | `'a posted saving reads RD · Saved · ₹5,000'` | finds "RD", "Saved" and "₹5,000"; no category name |
| `entry_row_test` | `'an extra reads Put in extra'` | a *Saved* entry with no note shows "Put in extra" |
| `entry_row_test` | `'a saved row has no tap action but can still be swiped away'` | tapping doesn't call `onEdit`; a fling left calls `onDelete`; the semantics have the Delete custom action and no tap action |
| `due_soon_row_test` | `'a saving goes in on its weekday'` | `rd` due 29 Oct, `daysAway` 3: "RD ₹5,000 goes in on Thu"; the semantics hint is "Opens the saving." |
| `due_soon_row_test` | `'a saving tomorrow'` | `daysAway` 1: "RD ₹5,000 goes in tomorrow" |
| `home_bloc_test` | `'a saving today is listed but never a bite'` | the RD entry dated today is in `todayEntries`, not in `todaySpends`; `summary.spentToday` is ₹420 |
| `home_page_test` | `'deleting a saving from its sheet offers Undo with its name'` | the snackbar reads "Deleted RD" |

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/ledger/presentation test/home`
Expected: "Saved" and "goes in on Thu" are not found, and the tap calls `onEdit`.

- [ ] **Step 3: Implement as in Interfaces.** Add a `// why:` on the null tap: "the Add tray knows only Spent and Got; editing there would turn a saving into spending (D120)".

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/home test/ledger`
Expected: green, `home_page_test` at the `TestWindows` sizes included.

- [ ] **Step 5: Update the docs**

- **SPEC BR-9:** "Saving rules show '{Label} ₹{amount} goes in on {weekday}' ('tomorrow' when `n = 1`)".
- **SPEC FR-HO-3:** the row opens a saving's sheet too.
- **SPEC FR-HO-4:** "A saving reads its name, *Saved*, and the amount, with the piggy-bank glyph; it is never a bite and has no tap; swipe deletes it with Undo".
- **SPEC BR-10:** saved entries are deleted, never edited in the tray.
- **UI_DESIGN §5.2:** the same.

- [ ] **Step 6: Commit**

```bash
git add lib/ledger lib/home test/ledger test/home docs/SPEC.md docs/UI_DESIGN.md
git commit -m "feat(home): savings show as Saved rows and go-in nudges

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Spends: "Spent ₹X · Saved ₹Y"

**Files:**
- Create: `lib/spends/presentation/widgets/spent_saved_line.dart`
- Modify: `lib/spends/domain/entities/spends_overview.dart`, `lib/spends/domain/usecase/get_spends_overview.dart`, `lib/spends/presentation/pages/spends_page.dart`
- Modify (docs): `docs/SPEC.md` FR-SP-3 (`K` computed), the new FR-SP-4a line, FR-SP-6 (saved rows); `docs/UI_DESIGN.md` §5.4
- Test: `test/spends/domain/usecase/get_spends_overview_test.dart`, `test/spends/domain/category_shares_test.dart`, `test/spends/presentation/pages/spends_page_test.dart`, `test/spends/presentation/pages/entries_page_test.dart`, `test/spends/presentation/bloc/spends_state_test.dart`

**Interfaces:**
- Consumes: `DueAmounts.after` (Task 2), `EntryKind.saved`.
- Produces: `SpendsOverview.saved` (`Money`, required, in `props`), which is *Saved* entries in the cycle up to `asOf`.
- Changes: `budget = I − K`, where `K = saved` plus `DueAmounts.after(saved rules, today: asOf, cycle)`. The second term is ₹0 for a past cycle. The overview no longer reads `settings.keepAside`.
- Produces: `SpentSavedLine({required Money spent, required Money saved})`. It is one `bodyMedium` `ink2` line reading `strings.spentAndSaved(…)`, placed above `WhereItWentCard`, and only when `saved` > ₹0.

- [ ] **Step 1: Write the failing tests**

| File | Test | Assert |
|---|---|---|
| `get_spends_overview_test` | `'savings come off the budget and are counted apart'` (replaces `'keep aside comes off the budget'`, D120) | with `rd` and its ₹5,000 entry on 10 Oct: `budget` ₹40,000, `saved` ₹5,000, `spent` ₹27,570 |
| `get_spends_overview_test` | `'an RD still to come this cycle is reserved but not yet saved'` | `rd` with `nextDue` 30 Oct and no entry: `budget` ₹40,000, `saved` ₹0 |
| `get_spends_overview_test` | `'saves never reach the rows, the pace or the insights'` | `rows`, `pace` and `insights` are equal with and without the RD entry |
| `category_shares_test` | `'Saved entries are not spending'` | a ₹5,000 *Saved* entry adds no row |
| `spends_page_test` | `'the Spent · Saved line sits above Where it went'` | "Spent ₹27,570 · Saved ₹5,000" is found, above the "Where it went" title (compare `getTopLeft`) |
| `spends_page_test` | `'no saves: no line'` | "Saved" is not found |
| `entries_page_test` | `'a saved row is listed but the day total counts spending only'` | the 10 Oct header reads ₹0 and the RD row shows "Saved" |

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/spends`
Expected: compile error (`saved`), and the budget is ₹45,000 ≠ ₹40,000.

- [ ] **Step 3: Implement as in Interfaces.** Add the `saved` argument to every `SpendsOverview(...)` in tests and fixtures. That is a signature-only edit; list the files in the commit body.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/spends`
Expected: green.

- [ ] **Step 5: Update the docs**

- **SPEC FR-SP-3:** `I − K` uses the computed `K` (D120).
- **New bullet after FR-SP-4:** "One line above *Where it went*, 'Spent ₹27,570 · Saved ₹5,000', when the cycle has saves; saves are never in bars, percentages, week bars, pace or insights".
- **SPEC FR-SP-6:** saved rows are listed with *Saved* and the day total counts spending.
- **UI_DESIGN §5.4:** the same.

- [ ] **Step 6: Commit**

```bash
git add lib/spends test/spends docs/SPEC.md docs/UI_DESIGN.md
git commit -m "feat(spends): spent and saved, side by side

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Ask AI facts and CSV; `keepAside` removed

**Files:**
- Modify: `lib/ask_ai/domain/entities/prompt_input.dart`, `lib/ask_ai/domain/usecase/get_prompt_input.dart`, `lib/ask_ai/domain/prompt_builder.dart`, `lib/ledger/domain/entities/budget_settings.dart`, `lib/ledger/data/repository/budget_settings_repository_impl.dart`, `lib/core/db/db_schema.dart` (the `keepAsideMinor` dartdoc)
- Modify (fixtures): `test/helpers/fixtures/ask_ai/prompt_input.dart`
- Modify (docs): `docs/SPEC.md` BR-15
- Test: `test/ask_ai/domain/prompt_builder_test.dart`, `test/ask_ai/domain/usecase/get_prompt_input_test.dart`, `test/ask_ai/presentation/bloc/ask_ai_state_test.dart`, `test/ledger/data/repository/budget_settings_repository_impl_test.dart`

**Interfaces:**
- Changes: `PromptInput.keepAside` is replaced by `savings` (`List<RecurringRule>`, default empty), which holds the active *Saved* rules, and `props` follow.
- Changes: `BudgetSettings` drops `keepAside`, keeping only `monthStart`. `BudgetSettingsRepositoryImpl` reads only `month_start`.
- Facts clause (only when `savings` isn't empty): "I save {₹ total of the rules} a month ({label} on the {ordinal day}, …)". The labels are joined with ", ", soonest `nextDue` first.
- CSV: `kind` is `e.kind.name`, so `saved`. **The category column for a *Saved* entry is the literal `savings`**: its hidden category isn't in `categories`, and `_Names.of` would throw.
- The *What should my limits be?* task reads "…after fixed bills and savings." instead of "…and what I keep aside." (spec §5: Ask AI drops "keep aside").
- `_cycleWord` becomes unused and is deleted.

- [ ] **Step 1: Write the failing tests** (`prompt_builder_test`, group `'facts line from the app (BR-15)'`)

| Test | Assert |
|---|---|
| `"follows the context line with Home's numbers and the savings"` (replaces the keep-aside version, D120) | with `savings: [rd]`, line 4 is `'From my app, and correct: safe to spend today ₹1,430; at this pace it lasts till payday with about ₹9,300 spare; I save ₹5,000 a month (RD on the 10th).'` |
| `'two savings are added up and listed soonest first'` | RD ₹5,000 on the 10th and Chit ₹500 on the 15th: it ends `'I save ₹5,500 a month (RD on the 10th, Chit on the 15th).'` |
| `'leaves out the savings clause when there are none'` (was the keep-aside ₹0 test) | the text is unchanged from the old ₹0 expectation |
| `'a saved entry is listed as kind saved, category savings'` | an entry ₹5,000 dated 10 Oct with note 'RD' gives the CSV row `'2026-10-10,5000,saved,savings,RD'`, and building doesn't throw |
| `'the limits task asks to fit income after fixed bills and savings'` | the last line ends `'…fit my income after fixed bills and savings. Show a table: category, limit in ₹, one short reason.'` |

- **Deleted, because the behaviour is gone (D120):** `'weekly pay keeps aside a week'`, `budget_settings_repository_impl_test`'s keep-aside rows (the `'…and a keep-aside amount'` read becomes month-start only), and the two "bad keep aside" cases.
- **Changed:** `get_prompt_input_test`'s `"…carries Home's summary and the keep-aside"` becomes `"…and the savings"`: with `rd` in the rules, `input.savings == [rd]`. `ask_ai_state_test` drops `input.keepAside` from its props list.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/ask_ai test/ledger/data`
Expected: compile errors (`savings`), then a `Null check operator` failure on the saved CSV row.

- [ ] **Step 3: Implement as in Interfaces**

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test`
Expected: the whole suite is green. Nothing reads `keepAside` any more: `grep -rn keepAside lib test` returns nothing.

- [ ] **Step 5: Update SPEC BR-15**

- §3 example: "…; I save ₹5,000 a month (RD on the 10th)".
- The keep-aside bullet becomes the savings rule above.
- §6: the CSV `kind` values are `spent`, `got` and `saved`; a saved entry's category is `savings`.
- The limits task text changes as above.

- [ ] **Step 6: Commit**

```bash
git add lib test docs/SPEC.md
git commit -m "feat(ask_ai): tell the AI what I save; drop keep-aside

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: BR-8: "saved" means only real saving

**Files:**
- Modify: `lib/l10n/app_en.arb` (`savedYesterday`, `savedYesterdayOnly` values and descriptions), `lib/home/presentation/widgets/saved_yesterday_note.dart` (the dartdoc example only; the class name stays)
- Modify (docs): `docs/SPEC.md` BR-8 (note text), `docs/UI_DESIGN.md` §5.2, `docs/DECISIONS.md` (D121)
- Test: every test asserting "You saved", found with `grep -rln "You saved" test`

**Interfaces:**
- Consumes: the BR-8 row of `docs/design/mockups/28-savings-copy-deck.md` (Task 4 Step 1). The default is "Yesterday came in ₹{X} under, so every day got ₹{Y} more." / "Yesterday came in ₹{X} under."
- Unchanged: `YesterdaySaving`, the maths (D38) and the keys' names.

- [ ] **Step 1: Change the expected text in the found tests to the deck's wording** (D121; a documented copy change). Example: `'Yesterday came in ₹1,665 under, so every day got ₹185 more.'` (BR-8 example: `X = 1,665`, `Y = 185`).

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/home`
Expected: "Yesterday came in ₹1,665 under…" is not found.

- [ ] **Step 3: Change the two ARB values, then run `flutter gen-l10n`**

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/home && grep -rn "You saved" lib docs/SPEC.md docs/UI_DESIGN.md`
Expected: green, and no matches.

- [ ] **Step 5: Update the docs**

- **SPEC BR-8** and **UI_DESIGN §5.2:** the new text.
- **DECISIONS D121 (2026-11-04).**
  - **Decision:** "The morning note says 'Yesterday came in ₹X under…', not 'You saved'".
  - **Why:** "'saved' now means money put into a saving (D120); case study 17".
  - **Rejected:** "keeping 'You saved'; 'You spent ₹X less than its share' (longer)".

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/home test docs
git commit -m "fix(home): the morning note no longer calls an underspend saving

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Docs, research index and the phase check

**Files:**
- Modify: `docs/PLAN.md` §2 (the "Savings goal" row), `docs/design-research/README.md`, `docs/design-research/principles.md`, `docs/design-research/sources.md`, `docs/design-research/case-studies/17-savings-and-rd.md` and `18-variable-bills-and-quick-entry.md` (mark which principles and sources were appended)

- [ ] **Step 1: PLAN §2.** The "Savings goal" row becomes:
  - Default: "*Savings* in Settings: monthly savings (RD, SIP…) set aside before their day and recorded on it; *Put in extra* for one-offs".
  - Setting column: "List in Settings".
  - Cite D120.

- [ ] **Step 2: Research index**

- **`docs/design-research/README.md`:** add rows **18** and **17** above 16:
  - **18:** "Bills that change every month, and fast entry: E (fixed + changing bills), the card bill as an uncounted reminder, a Home line plus a due-day notification. Approved in the savings-and-bills spec; `R_t` built (D119); the rest is Phase 2–3".
  - **17:** "Savings and the RD: B, savings that work like fixed bills, `K` computed, *Put in extra*, 'Spent · Saved' on Spends. Built (D120, D121)".
- **`principles.md`:**
  - a section "Savings (case study 17)" with principles 57–59, the three from that study;
  - a section "Bills and reminders (case study 18)" with 60–63, its four;
  - each with *Sources* and *Applies to*, as written in the studies.
- **`sources.md`:** add the rows from both studies' source lists that aren't there yet. Keep each one's access note: 403s, redirects, binary PDFs.

- [ ] **Step 3: Full verification**

Run: `flutter analyze && flutter test && scripts/changed_lines_coverage.sh $BASE`
Expected:
- "No issues found!"
- all tests pass
- ≥ 90% of changed lines covered, with every uncovered line listed and a reason

- [ ] **Step 4: Check on the device** (`live-app-inspection` skill)

1. Add an RD of ₹5,000 for today's date in Settings → Savings.
2. Home: the hero doesn't move, the Today row reads "RD · Saved · ₹5,000", and there is no bite on the bar.
3. Back in Savings, the footer reads "₹5,000 put in since {month}".
4. *Put in extra* ₹500: the preview line shows, and Home's share stays the same.
5. Spends shows "Spent ₹… · Saved ₹5,500".
6. Swipe the RD row away on Home, then tap Undo.

- [ ] **Step 5: Commit**

```bash
git add docs
git commit -m "docs: savings in PLAN, research index, principles and sources

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Self-review (done while writing)
- **Spec coverage (Phase 1 row of §9):**

  | Spec item | Task |
  |---|---|
  | Migration (all of §4) | 1 |
  | `saved` kind | 1–2 |
  | Saving rules | 2–3 |
  | Keep-aside migration | 1 |
  | Savings list and wizard | 4 |
  | Home row and due-soon | 6 |
  | *Put in extra* | 5 |
  | Spends line | 7 |
  | Ask AI | 8 |
  | BR-8 copy | 9 |
  | Edge cases E-a | 2 (clamp reused, BR-1) |
  | Edge cases E-b, E-h, E-k | 2, 5, 6 (cues only) |
  | E-g | 2 |
  | Mockups | 4 |
  | `TestWindows` | 4, 5, 6 |

  **Left to Phase 2 on purpose:** `AmountMode`, the waiting state, `cardPaid`, the *Bills* rename, and the bill amount sheet.
- **Types used across tasks:** `EntryKind.saved`, `CycleSummary.remaining`, `PutInPreview`/`EachDayLess`/`PaydayTomorrow`, `DueAmounts.after`, `SavedTotal`, `GetBills(EntryKind)`, `AddBillParams.entryKind`, `RuleWords`/`RuleGlyph`, `BillsBloc.kind`, `PutInExtra`/`PutInTooMuchFailure` are each defined once and used under the same name.
- **Numbers, re-derived:**
  - `P = 45,000 − 5,000 − 1,200 − 27,150 = 11,650`
  - `A = ⌊11,650 / 9⌋ = 1,294` and `1,294 − 420 = 874`
  - `⌊11,230 / 8⌋ = 1,403`, `⌊10,730 / 8⌋ = 1,341`, so the preview is ₹62
  - spare `(11,230·22 − 18,950·8) / 22 ≈ 4,339 → ₹4,300`, and with the extra `≈ 3,839 → ₹3,800`
  - E-b `45,000 − 20,000 − 1,200 − 27,150 − 420 = −3,770`
  - BR-8 on 27 Oct: `X = 1,294 − 420 = 874`, `Y = ⌊874 / 8⌋ = 109`
  - `previewSpend(₹1,000)` after the extra: over ₹126, tomorrow `⌊9,730 / 8⌋ = 1,216`
- **Proportion:** the spec is 174 lines for four phases, and this plan for the largest phase is about 3× that. Code appears only as the migration order (an algorithm the tests don't fix) and test tables; there are no method bodies.
