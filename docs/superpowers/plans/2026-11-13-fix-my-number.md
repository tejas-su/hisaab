# Fix my number (D165 to D169, D181 to D183, D187 to D190). Implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Build order:** plan **3 of 3** (M8 step 5). Needs **plan 1** (`2026-11-13-yearly-costs-and-used.md`: migration 005 with the hidden `not logged` rows, `PolitePreviewSlot`, `TestWindows`, `EntryKind.used`) and **plan 2** (`2026-11-13-missed-log-line.md`: `HomeLinesBloc`, the nudge slot's evaluation points). **SPEC wins over this plan.**

**Goal:** The user types how much of this month's money is left. hisaab compares it with its own figure `H` and, on *Fix it*, adds one *Not logged* entry for the difference (*Spent* when money is missing, *Got* when hisaab under-counted). The hero follows (₹1,430 to ₹963 in the worked example) and an Undo snackbar reverts it. A higher gap above `I ÷ 10` asks one more question first.

**Scope:** BR-18 and its edits to BR-3 to BR-8, BR-10 to BR-17; FR-FX-1 to FR-FX-6; FR-HO-3 (the **install line**), FR-HO-9 (the foot row), FR-HO-4 (*Not logged* rows), FR-SE-1 (the Settings row), FR-SP-4a (the three-part Spends line), FR-SP-6 / D187, BR-15 (*Not logged* clause), BR-16; FR-KS-1 to FR-KS-4 as they apply to this sheet; E72 to E92, E105 to E115; NFR-11, NFR-12; D165 to D169, D176, D181 to D183, D186 to D190. Build prerequisite items P4, P7, P8, P9, P12, P13, P14, P17, P19 of `docs/features/fix-my-number/08` §3.

**Architecture:**
- **A fix is an ordinary `out` or `in` entry in a hidden category** (D166) filed under the two rows migration 005 created. `Entry` gains `isNotLogged`, set by a **join on the category key** in the entries data source (both `between` and `byId`), so every reader (Home, Spends, Ask AI, the widget projection, habits) can tell a fix from spending without a category lookup. Why a join and not a category-id set: `CategoryRepository.all()` excludes archived system rows, so no consumer has the hidden ids, and restore and *Delete everything* change ids; the key is stable.
- **BR-3 gets `F_t`.** `CycleInputs.fixedToday` (a *Spent* fix dated today) comes out of the pool, never out of `S_today`; a *Spent* fix dated earlier is already in `S_prev` (it is a *Spent* entry), and a *Got* fix is in `I` (kind `got`). `CycleSummary` exposes `income`, `billsDue`, `savingsDue` and `fixedToday` so the maths below never recomputes them. Every `kind == spent` reader that means "spending" (`_isTyped`, `spentOnDay`, `paceSpentBefore`, `todaySpends`, category shares, insights, limits, the pace chart, the widget's bites, learned habits) excludes `isNotLogged`: Task 2 lists each with a test.
- **`FixMyNumber` is pure Dart** (`lib/ledger/domain/fix_my_number.dart`): `(CycleSummary, typed rupees)` → `FixPreview` (a sealed state: empty, equal, close, lower, short, overToday, higher, large, lastDay variants, `H ≤ 0` first-line variants). `H = remaining + B + R` from the summary. The *Fix it* write is a use case that **recomputes `H` and the gap in its own write** and refuses a stale one (BR-18 *Stale write*).
- **`FixBloc`** (new). Neither Home nor Settings owns a sheet both open, so it lives in a small feature `lib/fix/` with `presentation/` only, importing ledger only through `ledger.dart`. Doors in Home and Settings are builders passed from `AppRoutes`, as `usualRow` is. Events are sealed, `droppable()` on the write and on both guard answers; **the 300 ms guard-ignore uses the injected `Clock`**, not a timer, so tests are deterministic.
- **Three doors, one sheet** in the bill sheet's route (`BillSheet.route`), copying `BillAmountSheet.show`: wait for a settled state after `route.completed`, `BlocProvider.value`, close the bloc afterwards (P7). The outcome (`FixOutcome` with the entry) goes to the caller: **Home door** → `HomeBloc` (`HomeFixDone`), **Settings door** → a bloc inside the Settings route (`FixUndoBloc`, P4: Home's snackbar host is under Settings and would never show it).
- **The preview slot** reuses plan 1's `PolitePreviewSlot` and the shared pinned keypad body.
- **The install line** is the third item of plan 2's `HomeLinesBloc` slot (waiting, due-soon, **install**, missed-log). Its *seen* flag is a `settings` row (`install_line_seen`), which backup carries and *Delete everything* clears with no extra code (plan 1 Task 1 proves both).

**Prerequisites:** plans 1 and 2 merged; P1 (hold as a count), P2/P3 (`PinnedKeypadBody`), P5/P6 (`AmountDisplay(rejections:)`), P15 (key clamp) from the other agent.

**Tech stack:** as plan 1. No new dependency.

**Spec:** BR-18 (all), BR-3/BR-4/BR-5/BR-6/BR-7/BR-8 as amended, BR-10, BR-11, BR-12 to BR-17, BR-15, BR-16; FR-FX-1 to 6; FR-KS-1 to 4; FR-HO-3, FR-HO-4, FR-HO-9; FR-SE-1; FR-SP-4a, FR-SP-6; FR-WG-5; E72 to E92, E105, E107, E109 to E115; NFR-5, NFR-11, NFR-12; UI_DESIGN §5.2, §5.4, §5.7, §6 to §10, §13; D165 to D169, D176, D179 to D190; `docs/features/fix-my-number/01` to `08`; copy deck [41](../../design/mockups/41-fix-my-number-copy-deck.md) §2 to §5, §8.

## Where this plan departs from the docs, and what is ambiguous

| # | Point | What the plan does |
|---|---|---|
| C1 | **FR-HO-3 AC-1 and PLAN P18 say the install day is "the income rule's `created_at` (no new column)". `recurring` has no `created_at` column** (`RecurringColumns`, migrations 001 to 005). | **SPEC contradicts the code.** The plan uses `LedgerRepository.firstLoggedOn()` (the day the earliest entry was saved) as the install day. Onboarding posts the income entry on finish, so for a new install this is the install day, and a restored backup keeps its original date (the line then never shows, which is right). Needs an owner OK; flagged. |
| C2 | The deck gives **no ARB key** for D181's first lines ("hisaab thought nothing was left.", "hisaab thought you were ₹X short.") or D190's *Over today* line 2 ("That's ₹15,000 less. Today is ₹237 over its share."). The deck's `fixPreviewBase` is described as "hidden when `H` is zero or below", which D181 reverses. | Add `fixPreviewBaseNothing`, `fixPreviewBaseShort` and `fixPreviewLessOverToday` (working names, each with `@description`); `design-content` may rename. `fixPreviewBase` is **never hidden**. Flagged. |
| C3 | BR-18 *Close*: "`T` is a multiple of ₹100 and `0 < |gap| ≤ ₹50`". "multiple of ₹100" is about the typed `T` in rupees; `gap` is paise-exact. | `close ⇔ T % 100 == 0 && 0 < |gap| ≤ 5000 paise`, with `n = floor(|gap|/100) = 0` already *equal*; a gap of ₹50.50 is **not** close (above ₹50). Tested at 5000 and 5001. |
| C4 | BR-18 says `n = floor(|gap| / 100)` posts whole rupees. A gap of ₹4,200.50 posts ₹4,200, so `H` ends within ₹1 of `T` (spec: "to within ₹1"). | Post `n`; the stale-write check compares the **gap in paise**, not `n`, so a paise-level change refuses. Flagged as a SPEC reading. |
| C5 | *Empty* vs *typed 0* (E74, FR-FX-2 AC-4, P8). `AmountInput` holds an `int`, in which empty and 0 are identical. | `FixReady.typed` is a `String` of digits (`''` = empty). `rupees` is derived (`''` → none). Backspacing to `''` returns to empty; `0` typed is `'0'` (a leading-zero rule: `AmountInput.append('0')` yields 0, so the bloc keeps `typed = '0'` as a flag `zeroTyped`). Decision: add `bool zeroTyped` to the state instead of a string, to reuse `AmountInput`. |
| C6 | FR-FX-3 *Ledger changed* state: "replaces line 1 until the next key". The preview must follow the live ledger (E84). | `FixBloc` listens to `LedgerRepository.changes` (a `restartable()` reload event, never emitting from the callback) and re-reads `H`. A stale **save** is refused by the use case; the bloc then sets `notice = changed`, refreshes the preview and fires the reject haptic. |
| C7 | The *Over today* state (D190): `A_after < S_today`. `A_after` for a *Got* fix cannot be below `S_today` (it rises). | `OverToday` only on the lower branch, after *Short* is ruled out (BR-18 table order). Tested at `T = 2,430` (₹237 over, FR-FX-3 example). |
| C8 | FR-FX-1 AC-2 "7 taps for a 5-digit figure" and BR-18 "Add path gains nothing". | A test counts the taps in `home_page` (foot row, 5 digits, Fix it = 7) and asserts the Add tray's tests are unchanged (no edit to `add_entry`). |
| C9 | FR-FX-5 AC-2: "A new *Not logged* row then grows into the Today list 300 ms later". | Implemented as a delayed reveal in `TodayList` for **a row id the bloc marks `justFixed`**, not a timer in the bloc. Motion values stay UI_DESIGN §6 (no new token). |
| C10 | BR-15 does not say whether the summary table and "Earlier weeks (spent/got)" include a fix. The CSV keeps it. | Exclude `isNotLogged` from both (the clause says "treat each as a one-off"). Flagged for owner. |
| C11 | "Any *Not logged* entry consumes the install line" (AC-2). | The fix use case writes `install_line_seen` after a successful post; an Undo does not un-consume it. A restored backup carries the flag. |
| C12 | **P4:** Settings' `FixUndoBloc` is "the `IncomeBloc` scope". `IncomeBloc` is about income. | A new small `FixUndoBloc` provided next to `IncomeBloc` in `AppRoutes.settings`; blocs do not reference each other, so the page connects `FixOutcome` → `FixUndoBloc` with a listener. |
| C13 | **P17** (two-pane tab order) is not in the other agent's list but FR-KS-1 AC-7 requires it. | Task 14 adds one `FocusTraversalGroup` per pane in `AppShell`, if the other agent has not (grep first). |

## Global constraints

As plan 1's *Global constraints*, plus:
- **Direction is a word, never colour or sign.** No red, no green; marigold only on *Fix it* (an act). The guard keys are neither marigold. State is fill, outline, hatch, words.
- "hisaab" is lower case at a sentence start. Amounts on the sheet use full Indian grouping via `context.money.format` (never `compact`); "about" only on the per-day figure; a zero is stated ("Safe to spend today: ₹0.").
- **A fix is dated today only**, no date picker; never edited in the tray (`EntryRow` tap is null); never in `S_today`, a bite, a day's bar, a pace, a limit, a percentage, an insight, a habit or the morning note.
- **Entry speed:** the Add path is untouched. **Nothing in `lib/add_entry/` changes** in this plan.
- The only existing assertions edited: none. Constructor additions on existing classes are optional. If an existing test goes red (a reader that now excludes fixes may break a fixture): stop and ask.

## The maths, resolved (what the tests pin)

All amounts paise internally; rupees below. Worked example: `I = 45,000`, `K = 0`, `B = 1,200`, `S_prev = 27,150`, ₹420 today, `D = 9`, `t = 26 Oct`.

| # | Quantity | Definition |
|---|---|---|
| F1 | `H` | `remaining + billsDue + savingsDue` from `CycleSummary`, **unclamped** (may be ≤ 0). Equals `I − (S_prev + R_t + F_t + S_today) − (Sv_before + Sv_rule_today + Sv_extra_today)`. Example: 17,430 |
| F2 | `gap` | `H − T·100` (paise). `n = floor(|gap| / 100)` |
| F3 | Direction | `gap > 0`: post *Spent* `n`; `gap < 0`: post *Got* `n` |
| F4 | Equal | `n = 0` |
| F5 | Close | `T % 100 == 0 && 0 < |gap| ≤ 5,000` and not equal (C3) |
| F6 | Large | `gap < 0 && −gap > I ÷ 10` (`I` = `summary.income`, paise, integer division) |
| F7 | Short | lower (`gap > 0`), `T < B + R`; `m = (B + R) − T` |
| F8 | OverToday | lower, not Short, `A_after < S_today`; `o = S_today − A_after` (C7) |
| F9 | `A_after` | `max(0, floor((P ∓ n·100) / D))` with `P − n·100` for a *Spent* fix and `P + n·100` for a *Got* (floor division on a possibly negative pool: reuse `SafeToSpend.shareOn` over adjusted `CycleInputs`, do not re-implement `_floorDiv`) |
| F10 | `n_day` | `|A_after − A_before|`; 0 → "Each day stays about the same." |
| F11 | Last day | `D = 1`: line 2 "…Today takes all of it." (less) / "…Today gets all of it." (more), instead of the per-day line |
| F12 | Line 1 | `H > 0`: `fixPreviewBase(H)`; `H = 0`: `fixPreviewBaseNothing`; `H < 0`: `fixPreviewBaseShort(−H)` (C2) |
| F13 | Pool after | Spent fix: `P − n`; hero `A_after − S_today`; `remaining' = T − B − R` (to within ₹1) |

**Golden cases the tests assert (BR-18 table and examples):**

| Case | `T` | gap | posts | `P` | `A` | hero | `remaining` | line 2 |
|---|---|---|---|---|---|---|---|---|
| 1 | 13,230 | +4,200 | *Spent* 4,200 | 12,450 | 1,383 | **963** | 12,030 | "That's ₹4,200 less. Each day gets about ₹467 less." |
| 2 | 18,430 | −1,000 | *Got* 1,000 | 17,650 | 1,961 | **1,541** | 17,230 | "That's ₹1,000 more. Each day gets about ₹111 more." |
| 3 | 47,430 | −30,000 > 4,500 | guard; *Yes* → *Got* 30,000 | 46,650 | 5,183 | **4,763** | 46,230 | "That's ₹30,000 more. One question first." |
| 3b | 17,430 after *No* | 0 | none | 16,650 | 1,850 | 1,430 | 16,230 | "That matches. Nothing to fix." |
| close | 17,400 | +30 | none | | | | | "That's close enough. Nothing to fix." |
| short | 1,000 | +16,430 | *Spent* 16,430 | 220 | 24 | **₹0** | −200 | "…₹200 short of what's still due." and *Over by ₹200 this cycle* |
| mid-cycle install | 9,000 (H 45,000, nothing spent today, B 1,200, S_prev 0) | +36,000 | *Spent* 36,000 | 7,800 | 866 | **866** | 7,800 | |
| last day | 930 (`D = 1`, `S_prev 43,150`) | +500 | *Spent* 500 | 1,350 | 1,350 | **930** | | "That's ₹500 less. Today takes all of it." |
| with a yearly saving | 12,230 (`K = 1,000`) | +4,200 | *Spent* 4,200 | 11,450 | 1,272 | **852** | 11,030 | "…about ₹466 less." |
| `H = −300`, `T = 2,000` | | −2,300 | *Got* 2,300 (under 4,500, no guard) | | | | | line 1 "hisaab thought you were ₹300 short." |
| `H = 0` | | | | | | | | line 1 "hisaab thought nothing was left." |
| over today (E75, D190) | 2,430 | | | 1,650 | 183 | ₹0, "₹237 over today" | | "That's ₹15,000 less. Today is ₹237 over its share." |

## Review focus

1. **A fix is never spending** in any reader (Task 2's list). 2. **Stale write refuses** and refreshes (E84). 3. **The guard cannot be passed by a double tap** (E85, 300 ms via the injected clock). 4. **Home holds under the sheet** and reloads once (NFR-12, E110). 5. **Back while writing keeps the Undo** (E86, P7). 6. **The Add path is byte-identical** (C8). 7. **`H` is unclamped** (E78). 8. **Every *Not logged* row can be deleted without a swipe** (NFR-11). 9. **Hero rolls and the bar re-spans in one motion; a lower and a higher figure play the same** (FR-FX-5 AC-2).

---

## File map

| File | Responsibility | Task |
|---|---|---|
| `lib/ledger/domain/entities/{entry,cycle_inputs,cycle_summary}.dart`, `lib/ledger/data/{model/entry_model,mapper/entry_mapper,datasource/entries_local_data_source}.dart`, `lib/ledger/domain/entities/category.dart` | `isNotLogged`, `F_t`, summary fields | 1, 2 |
| every `kind == spent` reader (Task 2 table) | Exclude fixes | 2 |
| `lib/ledger/domain/fix_my_number.dart`, `entities/{fix_preview,fix_inputs}.dart` | The maths | 3 |
| `lib/ledger/domain/usecase/{get_fix_inputs,fix_my_number_use_case,…}.dart`, `repository/budget_settings_repository.dart` (install flag), `failures/ledger_failures.dart` | The write, the stale check | 4 |
| `lib/fix/presentation/bloc/fix_{bloc,event,state}.dart`, `fix_undo_{bloc,event,state}.dart` (new) | Sheet state and the Settings Undo | 5, 8 |
| `lib/fix/presentation/{pages/fix_sheet.dart,widgets/*}` (new) | The sheet | 6, 7 |
| `lib/home/presentation/{pages/home_page.dart,widgets/fix_foot_row.dart,widgets/install_line_row.dart,bloc/home_*,bloc/home_lines_*}`, `lib/app/routes.dart` | Doors, Undo, install line | 8, 9, 10 |
| `lib/settings/presentation/pages/settings_page.dart`, `widgets/settings_row.dart` | The Settings row (and the neutral glyph, P14) | 8 |
| `lib/ledger/presentation/widgets/entry_row.dart`, `lib/spends/…` | Rows, chips, Spends line | 11, 12 |
| `lib/ask_ai/domain/prompt_builder.dart` | Clause, CSV, summary | 13 |
| `lib/shortcuts/…`, `lib/backup` tests | Snapshot, backup | 14 |
| `lib/core/widgets/day_blocks/…`, `today_bar/…` | Re-span (P9) | 9 |
| `lib/l10n/app_en.arb` | The deck's keys plus C2 | 5–13 |

---

### Task 0: Preflight
- [ ] `git rev-parse HEAD` → `BASE`. Confirm plan 1 (`EntryKind.used`, migration 005, `PolitePreviewSlot`, `TestWindows.book`) and plan 2 (`HomeLinesBloc`) are in: `grep -rn "HomeLinesBloc" lib/home`, `grep -n "not_logged" lib/core/db/migrations/migration_005*`. If not: stop.
- [ ] Check the other agent's work: `holdingHome`, `PinnedKeypadBody`, `AmountCapRing`, 2.0× keypad test. `grep -rn "FocusTraversalGroup" lib` (C13).
- [ ] Decide the feature folder: create `lib/fix/` with `fix.dart` (barrel, exports only what `AppRoutes` needs) and register `docs/features/fix-my-number/` as its doc folder. Layout `data/` is not needed (it reads and writes through `ledger.dart`).

### Task 1: `Entry.isNotLogged` by a category join
**Files:** `entry.dart`, `entry_model.dart`, `entry_mapper.dart`, `entries_local_data_source.dart`, `category.dart` (keys already added in plan 1, Task 2); Tests: mirrors, `fake_ledger_repository.dart`.
**Interface:** `Entry.isNotLogged` (`bool`, optional named, default false, in `props`); `EntryModel.categoryKey` (`String?`, read-only: from the joined `category_key` column, **not** in `toRow`). `between` and `byId` select `t.*, c.key AS category_key FROM transactions t JOIN categories c ON c.id = t.category_id`; `isNotLogged ⇔ key ∈ {not_logged, not_logged_in}`. `restore(entry)` re-inserts the same `category_id`, so the flag round-trips with no field to store.
- [ ] **Step 1: Failing tests:** `'a row in not_logged is a notLogged entry; in not_logged_in too; in food is not'`; `'byId and between agree'`; `'the flag survives delete then restore (Undo)'`; `'the join returns the same rows and order as before for ordinary entries'` (regression on the existing suites); `'a row whose category is gone is InvalidDataFailure, not a crash'` (the FK normally prevents it; assert the join's behaviour); `'the fake sets isNotLogged from a set of ids it is given'`.
- [ ] **Step 2–4:** run `flutter test test/ledger/data`, implement, verify `flutter analyze`.

### Task 2: A fix is never spending (BR-3 to BR-17 edits)
**Files:** the table below. Tests: each mirror plus `test/ledger/domain/usecase/get_cycle_summary_fix_test.dart`.
**Interfaces:** `CycleInputs.fixedToday` (`Money`, `F_t`, default `Money.zero` in the constructor so existing tests need no edit), `CycleSummary.income`, `billsDue`, `savingsDue`, `fixedToday` (defaults `Money.zero`). `SafeToSpend._pool` subtracts `fixedToday`; `compute` copies the four fields into the summary.

| Reader | Edit |
|---|---|
| `GetCycleSummary._DayTotals.inputs` | `spentToday`: also `!e.isNotLogged`; new `fixedToday`: spent, today, `isNotLogged`; `paceSpentBefore` excludes `isNotLogged`; `spentBefore` **keeps** them (BR-3 `S_prev`); `_isTyped` (spentThisWeek) excludes them |
| `GetCycleSummary._asItStood` | no change needed; a test proves A_yesterday treats a fix dated yesterday as pool (BR-8, D189, E87) |
| `HomeBloc._load` `todaySpends` | `&& !e.isNotLogged` |
| `lib/spends/domain/usecase/get_spends_overview.dart` `spent`, `lib/spends/domain/category_shares.dart`, `insight_rules.dart` (two sites), `entities/pace_series.dart`, `lib/ledger/domain/budget_suggester.dart`, `usecase/get_suggested_limits.dart` | exclude `isNotLogged` (BR-12 to BR-14, FR-SP-3) |
| `lib/shortcuts/domain/projection/projected_book.dart` `typedSpendsOn` | exclude (FR-WG-5) |
| `lib/habits/domain/habit_index_builder.dart` `_learned` | exclude (BR-17: a fix would count as a learned day) |
| `lib/spends/presentation/widgets/entries_day.dart` day totals | exclude (FR-SP-6) |
| `lib/ledger/domain/entities/spend_preview` / `SafeToSpend.previewSpend` | none |

- [ ] **Step 1: Failing tests** (BR-18 worked example as the base; a `notLogged(...)` helper entry builder)

| Test | Cites |
|---|---|
| `'a Spent fix today is F_t: pool 16,650 → 12,450, A 1,383, hero 963, S_today stays 420'` | BR-3, BR-4, case 1 |
| `'a Got fix is in I: A 1,961, hero 1,541'` | BR-3, case 2 |
| `'a Spent fix dated yesterday is in S_prev, never in a bar or the week's spent'` | BR-6a, E87 |
| `'overToday is never caused by a fix being counted as spending'` | BR-4 |
| `'a fix is out of V_prev: the forecast pace does not change'` | BR-7 |
| `'the morning note after a fix dated yesterday credits and blames nothing'` | BR-8, D189, E87 |
| `'a lower A below what was spent: state OverToday, hero ₹0, "₹198 over today" (P 2,000)'` | E75 |
| `'remaining < 0 after a fix: OverCycle'` | E76 |
| `'week bars: a fix is not in a day's bar, and is in that day's pool'` | BR-6a |
| `'category shares, limits, insights, pace chart and the widget's bites ignore a fix'` (one test per reader) | BR-12 to BR-14, FR-SP-3 |
| `'a fix is not a learned entry: no habit forms or fades because of it'` | BR-17 |
| `'summary exposes income, billsDue, savingsDue, fixedToday'` | C-fields |
| `'every existing summary test is unchanged'` | contract |

- [ ] **Step 2–4:** run `flutter test test/ledger test/spends test/shortcuts test/habits test/home`, implement, verify. **If any existing test fails, stop and ask.**

### Task 3: `FixMyNumber` (pure Dart, test-first)
**Files:** Create `lib/ledger/domain/fix_my_number.dart`, `entities/fix_preview.dart`. Test `test/ledger/domain/fix_my_number_test.dart`.
**Interface:** `abstract final class FixMyNumber { static Money held(CycleSummary s); static FixPreview preview(CycleSummary s, Option<int> typedRupees); static Option<FixPost> post(CycleSummary s, int typedRupees); }`. `sealed class FixPreview`: `FixEmpty`, `FixEqual`, `FixClose`, `FixLower`, `FixShort`, `FixOverToday`, `FixHigher`, `FixLarge`, each with `held`, `gap`, `n`, `perDay`, `lastDay`, `heldLine` (F12). `FixPost({EntryKind kind, Money amount})`.
- [ ] **Step 1: Failing tests:** every row of *Golden cases*, each as `test('case N: …')` citing BR-18; plus

| Test | Cites |
|---|---|
| `'empty is FixEmpty; typed 0 is a valid state (E74)'` | FR-FX-2, E74 |
| `'T = H: equal (E72); T = 17,400 vs 17,430: close (E73)'` | E72, E73 |
| `'close at +₹50.00 (T multiple of 100), not close at +₹50.01'` | C3 |
| `'close needs T to be a multiple of 100: T = 17,420 (gap 10) is lower, not close'` | C3 |
| `'T = H − 1 rupee: lower of ₹1 (n = 1)'` | F2 |
| `'a gap of ₹4,200.50 posts ₹4,200'` | C4 |
| `'higher equal to I ÷ 10 is higher; one paisa more is large'` (boundary) | F6 |
| `'a huge lower gap is lower, never large (no guard)'` | D167, E79 |
| `'H = 0 and H < 0 pick the first-line variants; the gap uses the unclamped H'` | E78, D181 |
| `'D = 1 uses the last-day sentences'` | E81, F11 |
| `'n_day = 0 says "stays about the same"'` | F10 |
| `'a weekly cycle and a bridge cycle use the current cycle's I'` | E89 |
| `'short beats overToday beats lower'` | table order |
| `'a Got fix on day 1 of a cycle with a large buffer is large'` | E79 |
| `'two fixes on one day: the second compares with the ledger as it is → equal'` (build the summary after the first) | E83 |
| `'a fix with a yearly saving: H = 16,430 and a used entry changes none'` | BR-18 with BR-19, E92 |
| `'post returns none for equal and close'` | F4, F5 |

- [ ] **Step 2–4:** run, implement (each helper ≤ ~20 lines; dartdoc each public member; `// why:` on the strict `>` of the guard and on using `SafeToSpend.shareOn` for `A_after`), verify.

### Task 4: The write, the stale check, the install flag
**Files:** Create `usecase/get_fix_inputs.dart` (re-uses `GetCycleSummary`; returns the summary or the `FixPreview` base), `usecase/fix_my_number_use_case.dart`; Modify `failures/ledger_failures.dart` (`FixStaleFailure`, `FixNothingToFixFailure`), `repository/budget_settings_repository.dart` + impl + fake (`installLineSeen()`/`markInstallLineSeen()`), `ledger_module.dart`, `ledger.dart`. Tests: mirrors.
**Interface:** `FixMyNumberUseCase implements UseCase<Entry, FixParams>` with `FixParams({required int typedRupees, required int seenGapPaise})`. In its own write: reads the summary, recomputes `gap`; if `gap != seenGapPaise` → `Left(FixStaleFailure)` and writes nothing; if equal/close → `Left(FixNothingToFixFailure)`; resolves the hidden category id by key (`CategoryRepository.idOf(CategoryKeys.notLogged | notLoggedIn)`), builds the draft (kind per F3, today from `Clock`, `note: 'Not logged'`, no `recurring_id`), validates with `EntryValidator`, `_ledger.add`, then `markInstallLineSeen()` (a failure of the flag is swallowed like `_keepEstimate`).
- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'case 1 writes Spent ₹4,200 in not logged, dated today, note "Not logged", no recurring id'` | BR-18 |
| `'case 2 writes Got ₹1,000 in not logged (in)'` | BR-18 |
| `'after the write H equals T to within ₹1'` | BR-18 |
| `'a midnight between preview and save: the gap differs, nothing is saved, FixStaleFailure'` | E84 |
| `'a bill posted while the sheet was open: stale'` | E84 |
| `'equal and close write nothing'` | E72, E73 |
| `'a second Fix it right after the first writes nothing (equal)'` | E83 |
| `'₹0 gap, an amount over 9 digits: validator failures'` | BR-10 |
| `'the write dated today, never the previous cycle, even on day 1'` | BR-18 |
| `'a database failure is passed through and nothing is half-written'` | |
| `'a successful write sets install_line_seen; a failed flag write does not fail the fix'` | C11 |
| `'Undo (DeleteEntry) does not clear the flag'` | C11 |

- [ ] **Step 2–4:** run, implement, wire DI and `FakeServices`, verify.

### Task 5: `FixBloc` and `FixUndoBloc`
**Files:** Create `lib/fix/presentation/bloc/fix_{bloc,event,state}.dart`, `fix_undo_{bloc,event,state}.dart`. Tests: `fix_bloc_test.dart`, `fix_undo_bloc_test.dart`.
**Interfaces:** `FixBloc({required GetCycleSummary, required FixMyNumberUseCase, required LedgerRepository ledger (changes), required Clock, required Haptics})`. Events: `FixLoadRequested` (`restartable()`; also fired by the ledger change stream), `FixKeyPressed(String)`, `FixBackspacePressed`, `FixCleared`, `FixSavePressed` (`droppable()`), `FixGuardAnswered(bool yes)` (`droppable()`), `FixBackPressed`, `FixNoticeDismissed`. State: `FixLoading`, `FixFailed(Failure)`, `FixReady({summary, typed digits, zeroTyped, preview, step (keypad|guard), guardOpenedAt, notice (none|changed|countOnly|saveFailed), rejections, saving})`, `FixDone(FixOutcome)`. `FixUndoBloc`: `FixUndoOffered(FixOutcome)`, `FixUndoRequested`.
- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'the amount is empty at open and H is not in the state's visible fields until the first key'` | FR-FX-2 AC-2 |
| `'backspacing to empty restores the helper; typed 0 is zeroTyped, not empty'` | FR-FX-2, C5 |
| `'digits update the preview in the same state class without a crossfade flag; a class change sets one'` | FR-FX-3 |
| `'a 10th digit: reject haptic, rejections + 1, digits unchanged'` | FR-KS-2, E93 |
| `'H loading: Fix it off; failed: FixFailed then Try again reloads'` | FR-FX-2 AC-4 |
| `'Fix it on a lower gap saves, emits FixDone, success haptic (once)'` | FR-FX-5 AC-1/2 |
| `'a double Fix it makes one entry'` (gated fake) | E85, FR-FX-5 |
| `'Fix it on Large posts nothing and moves to the guard step'` | FR-FX-4, E77 |
| `'in the guard, an answer within 300 ms of guardOpenedAt (FakeClock) is ignored; at 300 ms it is accepted'` | E85, FR-FX-4 AC-2 |
| `'No clears the digits, returns to the keypad step and sets notice countOnly'` | FR-FX-4 AC-3 |
| `'Back and Escape in the guard act as No; a second Back closes (Back on the keypad step pops)'` | FR-KS-4 AC-1, FR-FX-4 AC-4 |
| `'Yes posts the Got; a failure after Yes returns to the keypad step with saveFailed'` | FR-FX-5 AC-6 |
| `'H changes while the guard is open: the panel stays; the save re-checks; a differing gap posts nothing, returns to the keypad step, notice changed'` | FR-FX-4 AC-5, E84 |
| `'a stale save refreshes the preview and fires reject'` | FR-FX-5 AC-6, C6 |
| `'a failed write keeps digits: notice saveFailed, reject haptic, Fix it on again; the next key clears the notice'` | FR-FX-5 AC-6, E86 |
| `'a ledger change reloads H and keeps the digits; notice becomes changed only if a gap remains'` | C6, E84 |
| `'a reload restarts: an older slower read does not land last'` | bloc.md |
| `'FixUndoBloc: an offered outcome shows once; Undo deletes the entry and fires tick'` | FR-FX-5 AC-4/5, P4 |
| `'the entry written is never logged: AppLogger spy sees runtimeType only'` | NFR-3 |

- [ ] **Step 2–4:** run, implement (`// why:` on each `droppable()` and on the injected-clock guard), verify.

### Task 6: The preview slot and ARB copy
**Files:** Create `lib/fix/presentation/widgets/{fix_preview_slot,fix_helper}.dart`; Modify `lib/l10n/app_en.arb`. Tests: `fix_preview_slot_test.dart`.
**Keys (deck §2 to §5, each with `@description`, spoken variants per X28):** `fixMyNumber`, `fixSettingsDetail`, `fixInstallTitle`, `fixTitle`, `fixHelper`, `fixPreviewBase`, `fixPreviewLess`, `fixPreviewMore`, `fixPreviewLessShort`, `fixPreviewLessLastDay`, `fixPreviewMoreLastDay`, `fixPreviewEqual`, `fixPreviewClose`, `fixPreviewBig`, `fixAction`, `typeAmountFirst` (added in plan 1: reuse), `fixActionHintNothing`, `fixSavingSpoken`, `amountCapReached` (other agent: reuse), `fixLoadFailed`, `fixNoticeChanged`, `fixGuardQuestion`, `fixGuardNo`, `fixGuardYes`, `fixNoticeCountOnly`, `fixDone`, `undone`, `fixPreviewBaseNothing`, `fixPreviewBaseShort`, `fixPreviewLessOverToday` (C2). The ICU `period` select is `week | other`. Run `flutter gen-l10n`.
**Behaviour:** a two-line slot of fixed height: **every state is a child of one stack and only the visible one is in semantics**; digit changes inside a state swap instantly; a change of state class crossfades 150 ms (both motion modes). Live text is short ("4,200 rupees less."), the full sentence is the slot's focusable text (D186). Uses `PolitePreviewSlot`.
- [ ] **Step 1: Failing tests:** one per row of the FR-FX-3 table asserting both lines' exact English (lines from *Golden cases*), at `smallPhone` 1.0×, 1.5×, 2.0× (no overflow; two lines fit the fixed height); `'only the visible state is in the semantics tree'`; `'the live region speaks 1.2 s after the last key and at once on a class change'`; `'no colour is the only signal: every state's direction is a word'`; `'amounts use full grouping (₹1,25,000), never ₹1.25L'`; `'"hisaab" is lower case at the start of line 1'`; `'a zero per-day figure reads "Each day stays about the same."'`.
- [ ] **Step 2–4:** run, implement, `flutter gen-l10n`, verify.

### Task 7: The sheet (`FixSheet`) and the guard panel
**Files:** Create `lib/fix/presentation/pages/fix_sheet.dart`, `widgets/{fix_keypad_body,fix_guard_panel}.dart`, `lib/fix/fix.dart`. Tests: `fix_sheet_test.dart`, `fix_guard_test.dart`.
**Behaviour:** `FixSheet.show(context, bloc)` copies `BillAmountSheet.show` (P7): `BillSheet.route`, `BlocProvider.value`, wait for a settled state after `route.completed`, close the bloc, return `Option<FixOutcome>`. Body: `PinnedKeypadBody` with title `fixTitle(period)` (heading), slot, `AmountDisplay(rejections:)`, the shared `Keypad` (**no quick chips**), a full-width marigold `SignalKey` *Fix it* (`fixAction`; hint `typeAmountFirst` / `fixActionHintNothing`). The guard step swaps keypad and key for two stacked 56dp keys, **No, some is older first**, then **Yes, add {gap}**, neither marigold; the sheet shortens; the question is a focusable `Focus` + `Semantics` node, focus requested in the frame the panel is built. `period` is `week` for a weekly cycle.
- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'title, helper, empty amount, keypad 1–9, 00 0 ⌫, no chips, Fix it off'` | FR-FX-2 |
| `'typing 13230 shows the lower preview and enables Fix it; Fix it closes with a FixOutcome'` | case 1 |
| `'Fix it on a large gap shows the panel: the slot line 2 reads "That's ₹30,000 more. Is all of it from this month?", keys stacked No then Yes, sheet shorter'` | FR-FX-4 AC-1, D168 |
| `'a tap on a guard key 100 ms after the swap does nothing; at 300 ms it works'` | E85, FR-FX-4 AC-2 |
| `'No: digits cleared, "Count only this month's money." over ₹0, focus on that notice, which is not a live region'` | FR-FX-4 AC-3 |
| `'Back, system back, Escape and the scrim step back from the guard; swipe down and the handle close with nothing posted; on the keypad step Back closes'` | FR-FX-4 AC-4, FR-KS-4 AC-1, E112 |
| `'Back while writing closes the sheet and the outcome still arrives'` | E86, FR-KS-4 AC-3, Review 5 |
| `'TalkBack in the guard: the question is read once, then No, then Yes; focus lands on the question in the frame the panel is built'` | FR-FX-4 AC-6 |
| `'focus order: Back, title (heading), amount, slot, 1–9, 00, 0, ⌫, Fix it; in the guard: Back, title, amount, slot, No, Yes'` | FR-FX-6 |
| `'the sheet returns focus to the control that opened it; when the opener was the install line, to the "Today" heading'` | FR-FX-6 |
| `'layout: 320×568 at 1×, 1.5×, 2×; 412×400; 412×300; 915×412; book 673×841 (and hinge); tabletop 701×841; 841×701; 1280×800: amount and Fix it on screen above the inset; a 560dp stack on medium and expanded; never across a fold'` | E111, FR-KS-1, `pinned_keypad_expectations.dart` |
| `'the handle is not drawn under 600dp tall'` | E115, D180 |
| `'at 2.0× the keypad is 248dp and Fix it stays on screen'` | E113, FR-KS-3 |
| `'a failed save: "Couldn't save. Try again." until the next key, digits kept'` | FR-FX-5 AC-6 |
| `'Fix it is off while H loads; failed shows "Couldn't check your number." and a 48dp Try again'` | FR-FX-2 AC-4 |

- [ ] **Step 2–4:** run `flutter test test/fix`, implement, verify.

### Task 8: Doors, hold, Undo
**Files:** Create `lib/home/presentation/widgets/fix_foot_row.dart`; Modify `home_page.dart`, `home_bloc.dart`/`home_event.dart`/`home_state.dart` (`HomeFixDone(outcome)`, `HomeFixUndoRequested`; `HomeReady.fixUndo`; `_pendingFixUndo`), `lib/settings/presentation/pages/settings_page.dart` + `widgets/settings_row.dart` (the row), `lib/app/routes.dart` (`openFix(context, getIt, {door})`; the Settings route provides `FixUndoBloc` beside `IncomeBloc`), `lib/core/design/app_icons.dart` (P14 neutral glyph), `lib/l10n/app_en.arb` (`fixDone` already; reuse). Tests: `fix_foot_row_test.dart`, `routes_fix_test.dart`, `home_bloc_fix_test.dart`, `settings_page_fix_test.dart`.
**Behaviour**
- **Home foot row (FR-HO-9):** the last thing in Home's scroll, below the Today list and *See all*: `ink2` text "Fix my number", no fill, no icon well, no second line, ≥ 48dp, TalkBack "Fix my number, button. Opens the keypad." Always when Home is ready, **including over states**; hidden in *No income*, while loading and when failed. Tap = `tick`, `openFix(home door)` through `holdingHome`.
- **Settings row (FR-SE-1):** last row of *Money*, after *My month starts on*, detail `fixSettingsDetail`; hidden in *No income*; opens the same sheet over Settings (no hold: Home is not under it). `FixSheet`'s outcome → `FixUndoBloc` (C12), whose snackbar "Fixed. Safe to spend today: ₹963." with *Undo* shows on Settings. `success` fires as the exit starts (FR-FX-5 AC-5).
- **Home door:** `HomeFixDone` → Home's snackbar (the host Home already has) with the hero's own title; at ₹0 "Safe to spend today: ₹0." (no softening). Undo: `HomeFixUndoRequested(entry)` → `DeleteEntry`; the number returns by the same path; `tick`; "Undone." is announced (`undone`).
- Under TalkBack the snackbar stays until dismissed; an Undo offered while Home cannot show waits for the next good load (D127, as `_pendingAmountUndo`). The hero is **not** also a live region.
- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'the foot row is below Today and See all; it is 48dp+, ink2, no fill, no icon, no second line'` | FR-HO-9 AC-1 |
| `'it shows in over states and is not a second next step beside the over card's See where it went'` | FR-HO-9 AC-2, E107 |
| `'hidden in No income, while loading and when failed'` | FR-HO-9 AC-2, E90 |
| `'a tap opens the sheet and moves nothing above it; the dock and the Add key stay put'` | FR-HO-9 AC-3 |
| `'Home holds under the sheet: the hero stays ₹1,430 until the route completes, then rolls to ₹963 in one motion; two overlapping holds keep it held'` | NFR-12, E110, FR-FX-5 AC-2 |
| `'the Settings door sends no hold; success fires as the exit starts; the snackbar and Undo appear on Settings'` | FR-FX-5 AC-5 |
| `'the snackbar reads "Fixed. Safe to spend today: ₹963."; at ₹0 "…₹0."'` | FR-FX-5 AC-3 |
| `'Undo deletes the entry, the hero returns to ₹1,430, tick fires, "Undone." is announced'` | FR-FX-5 AC-4 |
| `'an Undo offered while Home is loading waits for the next good load'` | D127 |
| `'tap count from Home: foot row, 5 digits, Fix it = 7'` | FR-FX-1 AC-2, C8 |
| `'the over card and onboarding never offer it'` | FR-FX-1 AC-1 |
| `'a lower and a higher figure play the same motion: no hatch, flash or sheen (no extra animation controller on the row)'` | FR-FX-5 AC-2 |
| `'the Settings row is last in Money, after My month starts on, hidden in No income; the neutral glyph is not sliders'` | FR-SE-1, P14 |
| `'the widget snapshot is rewritten after the write'` (the existing `ShortcutsBloc` reacts to `changes`: assert with the fake platform) | FR-FX-5 AC-7, FR-WG-5 |

- [ ] **Step 2–4:** run, implement, verify `flutter test test/home test/settings test/app test/fix && flutter analyze`.

### Task 9: Hero roll, bar re-span, Today-row growth (P9)
**Files:** `lib/core/widgets/today_bar/…` (the painter), `lib/core/widgets/day_blocks/…` if used, `lib/home/presentation/widgets/hero_card.dart`, `today_list.dart`. Tests: mirrors.
**Behaviour:** when `A` changes (1,850 → 1,383), every segment re-spans against the new `A` in one motion on `standard` (the yellow 77% → 70%, the bite 23% → 30%; for `A = 1,961` 78.6% / 21.4%). The *Not logged* row grows into the list **300 ms after** the hero (C9: a `justFixed` row id in `HomeReady`).
- [ ] **Step 1: Failing tests:** `'the painter interpolates segment boundaries between two totals: 77% → 70% yellow at 1,850 → 1,383'`; `'… to 78.6% at 1,961'`; `'the hero number rolls to 963 in the same frame success fires (FakeHaptics frame order)'`; `'under reduced motion the roll and re-span are 150 ms crossfades'`; `'the row grows after the number, not with it'`; `'a lower and a higher figure use the same durations; the duration does not scale with the size of the change'`.
- [ ] **Step 2–4:** run, implement (no new motion token), verify.

### Task 10: The install line (FR-HO-3, AC-1, AC-2, E109)
**Files:** Create `lib/home/presentation/widgets/install_line_row.dart`; Modify `home_lines_{bloc,event,state}.dart` (a sealed `HomeLine` with `InstallLine` before `MissedLogLine`), `home_page.dart`, `app_en.arb` (`fixInstallTitle`). Tests: extend plan 2's.
**Behaviour:** "Already spent some this month?" ("this week" for a weekly cycle) over "Fix my number", the due-soon row's shape; TalkBack one node "Already spent some this month? Fix my number. Opens the keypad." Shows only when `firstLoggedOn` (C1) is **before** the cycle's start… precisely: the cycle holding the install day started before it (`cycle.contains(installDay) && cycle.start.isBefore(installDay)`), and only in that cycle. *Seen* is written when it is on screen with Home visible and no tray or sheet over it (`HomeLinesShown`, same probe as plan 2); a bill line holding the slot, a tray over Home or an over state means *not seen* and it waits. Never returns after it was seen, tapped or not. Any fix consumes it (Task 4). A tap opens the sheet; the opener is gone afterwards, so focus goes to the "Today" heading.
- [ ] **Step 1: Failing tests**

| Test | Cites |
|---|---|
| `'shown for a mid-cycle install on its first Home visit'` (install 26 Oct, cycle from 4 Oct) | AC-1, E80 |
| `'not shown when the install day is the cycle's first day, or in a later cycle'` | AC-1, E109 |
| `'a weekly cycle says "this week"'` | copy deck |
| `'seen is written once the line is on screen with no tray over it, and it never returns'` | AC-2 |
| `'a tray over Home, a bill line in the slot, an over state or No income: not seen, waits'` | AC-2, E107, E109 |
| `'a Not logged entry consumes it'` | AC-2, E109 |
| `'it outranks the missed-log line and a higher bill line outranks it; a cleared bill line does not slide it in mid-day'` | FR-HO-3 order, E108 |
| `'a restored backup that carries seen=1 never shows it; Delete everything clears seen'` | BR-16, E91 |
| `'focus goes to the "Today" heading when it opens the sheet and is removed'` | FR-HO-3 Focus |
| `'a tap opens the sheet through holdingHome'` | FR-HO-3, NFR-12 |

- [ ] **Step 2–4:** run, implement, verify.

### Task 11: *Not logged* rows, chips, custom delete (FR-HO-4, FR-SP-6, D187, NFR-11)
**Files:** `lib/ledger/presentation/widgets/entry_row.dart`, `lib/spends/presentation/widgets/entries_day.dart`, `pages/entries_page.dart`, `bloc/entries_state.dart`, `lib/home/presentation/widgets/today_list.dart`, `app_en.arb` (`entryNotLogged`, `notLoggedRow` select, `notLoggedDetail`, spoken forms), `lib/core/design/app_icons.dart` (neutral glyph, P14). Tests: mirrors.
**Behaviour:** line 1 "Not logged", line 2 "Spent" or "Got", the amount at the end, a neutral glyph, no tap, no tint, no sign; TalkBack "Not logged. Spent 4,200 rupees." / "Not logged. Got 1,000 rupees."; Every entry adds "Added when you fixed your number." in the same node. Not a bite, not in the header total or a day's total; counts among the 5 and is in time order (a fix posted now is on top). *Delete* is a custom semantics action in both lists. No chip (D187): the system categories get none and show under *All*.
- [ ] **Step 1: Failing tests:** one per sentence above, plus `'a Not logged row's title never falls back to "Other"'` (A3 of plan 1: the category map lacks it, so `isNotLogged` drives the title), `'swipe deletes with Undo and the number reverts exactly'` (BR-18 *Edit and delete*), `'a fix is on top of the Today list when posted now'`, `'the row has no tap in Home and Every entry'`, `'Delete exposed as a custom action: invoke it and assert the delete event'` (NFR-11, P12), `'no chip exists for not logged; the entry shows under All'`.
- [ ] **Step 2–4:** run, implement, `flutter gen-l10n`, verify.

### Task 12: The Spends line, three parts (FR-SP-4a)
**Files:** `lib/spends/presentation/widgets/spent_saved_line.dart` (rename-free: keep the file, change content), `spends_page.dart`/`where_it_went_card.dart` callers, `lib/spends/domain/entities/spends_overview.dart` (`notLogged` `Money`), `get_spends_overview.dart`, `app_en.arb` (`spendsPartSpent`, `spendsPartSaved`, `spendsPartNotLogged`, `spendsPartNotLoggedSpoken`; **remove `spentAndSaved` only after the parts replace it**). Tests: mirrors.
**Behaviour:** one `ink2` line, up to three parts in the fixed order *Spent*, *Saved*, *Not logged*, each only above ₹0; **each part unbreakable**, the line wraps between parts with no trailing dots (mockup 42 option B); `Spent` excludes *Not logged*; *Not logged* is the *Spent* side only; *Used* is not on it. TalkBack: "Spent 27,570 rupees. Saved 1,000 rupees. Not logged, spent 4,200 rupees." with the `·` hidden.
- [ ] **Step 1: Failing tests:** `'Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200 with 27,150 + 420 spent'`, `'a Got fix adds no part'`, `'no part when ₹0; the line hides when none'`, `'wraps between parts at 320dp and 2.0× text, no trailing dots'`, `'the TalkBack sentence'`, `'a Used entry adds no part'`, `'the order never changes'`, `'a past cycle shows its own fix'`.
- [ ] **Step 2–4:** run, implement, verify.

### Task 13: Ask AI and the CSV (BR-15, D188)
**Files:** `prompt_builder.dart`, `get_prompt_input.dart` (nothing expected), fixtures. Tests: `prompt_builder_test.dart`.
**Behaviour:** CSV: a fix keeps `kind` `spent` or `got`, category `not logged` (lowercase; **never** `names.nameOf`, which would throw because the hidden row is not in `input.categories`), note `Not logged`. The clause (deck §8) sits right after the facts, **only when the export holds a fix**: `Entries with the category "not logged" are corrections. When the user checked their real money it differed from this list, so one entry was added for the difference. Treat each as a one-off, not as a purchase or a habit, and do not give spending advice about it.` The summary table by category and the weekly totals exclude fixes (C10). With both a fix and a *Used* entry both clauses appear in the order *Not logged*, *Used* (flagged).
- [ ] **Step 1: Failing tests:** `'an export without a fix is byte-identical to the existing goldens'` (both with and without used from plan 1), **`'golden: an export with a fix'`** (full string), `'a fix's CSV row is date,amount,spent,not logged,Not logged'` and the Got form, `'notes hidden drops the note column'`, `'the summary table and weekly totals exclude it'`, `'a grouped older week does not count it as spending'`, `'an export with both clauses has both, in order'`.
- [ ] **Step 2–4:** run, implement, verify.

### Task 14: Backup, widget snapshot, focus groups, layout sweep
- [ ] **Backup (BR-16, E91):** tests `'a backup with a fix and the hidden rows restores; the install flag travels'`, `'Delete everything removes the fix and the flag'`, `'Undo restore brings them back'`, `'a v4 backup gains the hidden rows and the flag is absent (line may show)'`.
- [ ] **Widget snapshot (FR-WG-5):** `'a fix changes every projected day's hero as the pool changes; none of its bites'` with `ProjectWidgetDays` over `FakeServices`.
- [ ] **P17 (C13):** `AppShell` gains one `FocusTraversalGroup` per pane (Home, then Spends) if absent; tests `'in two panes Tab never alternates between panes'` (FR-KS-1 AC-7).
- [ ] **Layout and a11y sweep:** `fix_sheet`, `fix_foot_row`, `install_line_row`, the *Not logged* row, the Spends line at every `TestWindows` size (phone, smallPhone, splitScreen, splitScreenShort, phoneLandscape, book, bookHinge, tabletop, foldableLandscape, tablet) at 1.0×, 1.5×, 2.0×; `a11y` assertions per `.claude/rules/accessibility.md` (48dp targets, semantics order).
- [ ] **DI:** `FixMyNumberUseCase`, `GetFixInputs` in `ledger_module.dart`; `AppRoutes.openFix`; `FakeServices`.

### Task 15: Docs and final verification
- [ ] **Docs:** `docs/features/fix-my-number/01` to `08` get a status line "built" and the list of C1 to C13 in a new `09-build-notes.md` (next free number); `docs/PLAN.md` M8 step 5 done. **Do not edit SPEC, UI_DESIGN or DECISIONS here**; report C1 (needs a SPEC fix), C2, C4, C10.
- [ ] **Commands:** `flutter gen-l10n` · `flutter analyze` · `flutter test` · `scripts/changed_lines_coverage.sh $BASE` (≥ 90%, gaps reasoned, no `coverage:ignore`) · the `BRDA` awk per changed file.
- [ ] **Device checks before the build is called done (08 §5):** D1 the guard's focus under TalkBack (mandatory: if focus does not follow, use a live region and focus *No*), D6 the 400 ms drain, D13 largest font; plus a TalkBack pass on the Today and Every entry rows' *Delete* action.
- [ ] **Pre-release (D164, not a build gate):** the user test T0 to T11 may change ARB strings and at most the guard's `I ÷ 10`.

## Open questions

1. **C1** (install day source): SPEC names a column that does not exist; confirm `firstLoggedOn()`.
2. **C2** (three keys the deck lacks), **C4** (whole-rupee posting vs a paise-exact stale check), **C10** (fixes out of the Ask AI summary).
3. **Two clauses together** (a fix and a *Used* in one export): order not specified.
4. **Install line after a restore on a new phone:** never shows (the original install date is kept). Acceptable; confirm.
