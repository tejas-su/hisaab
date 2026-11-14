# Hisaab — Product & Build Plan

Target: **Android only** (v1). Currency: **INR** (architected for any locale/currency).
Stack: Flutter · flutter_bloc (Bloc with events) + bloc_concurrency · get_it · sqflite · equatable · fpdart · intl + gen-l10n · hugeicons · bundled fonts (Anek Latin, Mukta).

---

## 1. Core idea

The app answers one question: **"How much can I still spend?"**

- **Money in** — recurring income, entered once, auto-added every payday.
- **Money out** — expenses + recurring bills (auto-added).
- **Left** — one big number on Home: today's safe share. No red or green; states are shown by fill, outline, hatch and words (DECISIONS D9).

North-star test: a 5-year-old can log an expense, and anyone can understand Home in under 2 seconds.

---

## 2. Decisions made for the user (zero-config defaults)

Every setting the user must think about is friction. The app decides; power users can change it in Settings.

| Topic | Default (no question asked) | Changeable in Settings |
|---|---|---|
| Budget period | **Follows payday automatically.** Paid on the 1st → same as calendar month. Paid on the 25th → 25th to 24th. Income "keeps changing" → calendar month. The words "budget period" never appear in the UI. | "My month starts on: Payday / 1st of month" |
| Payday on 29–31st | Clamped to last day of shorter months | — |
| Category budgets | **None at start.** Only the overall "left to spend". After the first full cycle the app offers "Use these limits?" (based on actual spend), one tap to accept. | Edit per category |
| Currency | INR, no picker in onboarding | Later (architecture ready) |
| Date of expense | Today. Chips: "Today" / "Yesterday" / "Pick" | — |
| Accounts / wallets / cash vs UPI | Not in v1 | — |
| Delete | Instant + Undo snackbar (no "Are you sure?") | — |
| Edit recurring rule | Applies to future entries; past entries untouched. No dialog. | — |
| Over budget | Shown as "₹1,200 over" in words, never "-₹1,200" and never red | — |
| Paise | Whole rupees only: no decimal key, never displayed (stored as minor units) | — |
| Savings | *Savings* in Settings: monthly savings (RD, SIP…) set aside before their day and recorded on it; *Put in extra* for one-offs (D120). A yearly cost (insurance, school fees, a festival) is a saving too, a twelfth a month, and *Used some of it* records paying it from what is set aside (D174, D175) | List in Settings |
| The Home number looks wrong | *Fix my number*: the user says how much of this month's money is left and hisaab adds one *Not logged* entry for the difference. No setting, no limit, no reminder; a large higher figure asks one more question, at 10% of income (D165 to D169) | A row at the end of Home and of Settings › Money |
| Missed log | A once-a-day question after a habit's window, when the category has no entry today. No ×, no repeat, no setting (D171) | *Forget* on the category (D153) |
| Bills that change, and card bills | A bill is *Same every month* unless its chip says otherwise: *Electricity* changes (set aside at its last amount, and Home asks how much on its day); a *Credit card* bill is recorded when paid but never counted, because card buys count when made (D123). Onboarding offers only fixed bills (D125) | *Kind of bill* on the bill sheet |

---

## 3. Screens

1. **Onboarding (3 steps, progress dots):** income amount, when it comes, optional fixed bills (SPEC FR-ON).
2. **Home:** the hero card (safe to spend today, Day Blocks, range line), the nudge slot (waiting bill, due-soon, install line, missed-log line; D170), Today list, the *Fix my number* foot row, dock (FR-HO).
3. **Add tray:** amount keypad, then category tiles; tapping a tile saves (FR-AD).
4. **Spends:** Ask AI card, pace chart, where-it-went bars (no donut), up to 3 insights, and *See every entry* for the full day-grouped history (FR-SP).
5. **Ask AI:** goal, period, preview, copy/share/open ChatGPT (FR-AI).
6. **Settings:** money (with *Fix my number* at its end), categories, look, Your hisaab (FR-SE, D139).
7. **Keypad sheets:** the Fix my number sheet, the *Used* question and the other bill-sheet-route keypads, with pinned controls (FR-KS, FR-FX; mockups 41, 42).

Navigation: floating dock with **Home · (+ Add) · Spends**. Ask AI is the top card on Spends. The full history opens from Home ("See all") or Spends. Settings is at the top right of Home. See UI_DESIGN.md §4.

---

## 4. Design system

Full spec, research and verified tokens are in **[UI_DESIGN.md](UI_DESIGN.md)**. Summary:
- Name: **hisaab•** wordmark (lowercase, marigold dot). The Play Store title gets a descriptor such as "hisaab• – Daily Spend Tracker", because the bare name is crowded; see UI_DESIGN.md.
- Hero concept: **Day Blocks.** The money for the pay cycle is cut into one block per day until payday. Today's block glows marigold and drains as you spend. A range line underneath ("Lasts till payday · about ₹9,300 spare") answers "will it last?". There is no mascot.
- Palette: calm warm monochrome plus **one signal colour, marigold `#FFB020`**, which means "today / act" only. This follows the Braun ET66 lineage. There is no red: states are shown by fill, outline and hatch plus words.
- Type: Anek Latin (amounts and titles, `wdth` 85) and Mukta (body). Both are bundled and have ₹, tabular figures and Devanagari.
- Icons: Hugeicons stroke-rounded, monochrome, always with a label.
- Motion: Apple-style springs (critically damped by default, 0.8 damping only for gestures with momentum). Delight scales inversely with frequency, and reduced motion is respected.

---

## 5. Internationalisation architecture

Dependencies added: `intl`, `flutter_localizations`, `flutter: generate: true`, `l10n.yaml` (ARB in `lib/l10n/`, generated code in `lib/l10n/gen/`).

- **Strings**: no hard-coded user-facing text in widgets. All via `AppLocalizations.of(context)`. Plurals with ICU (`{count, plural, ...}`). English first; Hindi is a drop-in `app_hi.arb`.
- **Money**:
  - Stored as `int amountMinor` + `String currency` ('INR') per row — future multi-currency needs no migration.
  - `Money` value object (amountMinor, currency) in `core/money/`.
  - `MoneyFormatter` (single place) wraps `NumberFormat.currency(locale, name, symbol)` → `₹1,25,000`; `NumberFormat.compactCurrency` for charts → `₹1.2L`; hides paise when zero.
  - `CurrencySpec` (code, symbol, minor digits) from settings; INR default.
- **Dates**: `DateFormat` with app locale; "Today/Yesterday" via ARB; week start from `MaterialLocalizations.firstDayOfWeekIndex`.
- **Keypad**: decimal separator from `NumberFormat(locale).symbols.DECIMAL_SEP`.
- **Layout**: `EdgeInsetsDirectional` / `AlignmentDirectional` everywhere (RTL-safe for free).
- **Locale source**: `SettingsBloc` holds `Locale` + `CurrencySpec`; `MaterialApp` reads them. Default `en_IN`.

---

## 6. Key logic (pure Dart, unit-tested)

- `PeriodCalculator` — given payday rule + month-start setting + today → current cycle start/end, days left.
- `SafeToSpend`: today's share `A = floor((income − keep-aside − bills still due − spent before today) ÷ days left incl. today)`; hero = `A − spent today`. The exact rules are in SPEC BR-3 to BR-7.
- `RecurringEngine` — on app start/resume, posts every due occurrence up to today (catch-up for missed days), advances `next_due`. Idempotent (unique key `recurring_id + due_date`).
- `InsightRules` — category deltas vs previous cycle, biggest category, unusual single expense (> 2× category median).
- `BudgetSuggester`: after one full cycle, suggests per-category limits equal to last cycle's spend, rounded up to the next ₹500 (SPEC BR-12).

---

## 7. Ask AI export

1. Pick period: *This month* · *Last 3 months* · *Custom*.
2. Pick goal (big cards): *Review my spending* · *Find savings* · *Build me a budget* · *Am I on track?* · *Ask my own question*.
3. App builds the prompt: role + context + summary table + recurring bills + transactions CSV + task.
4. Actions: **Copy** (clipboard) · **Share** (Android share sheet → ChatGPT / Claude / Gemini apps) · **Open ChatGPT** (`https://chatgpt.com/?q=` for short prompts, else copy + open).
5. Privacy toggle: exclude notes.
6. Preview the exact text before sending (expandable).

Template (built by `PromptBuilder`, unit-tested):
```
You are a friendly personal finance coach. Be specific, use numbers, no jargon.
Context: income ₹50,000/month (payday 1st), currency INR, period 2026-09-01..2026-09-30.
Summary by category (spent / limit): Food 12,400/10,000; Travel 3,100/4,000; ...
Recurring bills: Rent 15,000; Netflix 649; ...
Transactions (CSV): date,amount,type,category,note
...
Task: Review my spending. Give: 1) 3 biggest problems 2) 3 concrete savings with ₹ amounts
3) a suggested budget per category for next month 4) one habit to change.
```

---

## 8. Data model (sqflite, versioned migrations from v1)

| Table | Columns |
|---|---|
| `categories` | id, name, icon_key, kind (in/out), budget_minor NULL, sort, archived. Hidden `saved` and `card_paid` rows (`archived = 1`) hold saved and card-bill entries and are never shown. Two more hidden rows, `not_logged` (out) and `not_logged_in` (in), both `archived = 1`, name `not logged` (a reserved name, BR-11), hold the entries a *Fix my number* adds (D166); a *Used* entry is filed in `saved`. A category the user made has key `own_<n>` and sort after the 8; hiding it sets `archived = 1`, which takes it out of the Add tray and Settings but keeps it in Spends, filters and exports (D138) |
| `transactions` | id, amount_minor, currency, kind (in/out/save/card/used), category_id, date, note NULL, recurring_id NULL, saving_id NULL, created_at. `used` (D175) is a payment from a saving's set-aside money; `saving_id` (NULL except on `used`) is the saving's `recurring.id`, kept apart from `recurring_id` because `(recurring_id, date)` is unique and a use on a put-in's date would be refused. A fix is an ordinary `out` or `in` row in a hidden `not logged` category |
| `recurring` | id, label, amount_minor, currency, kind (in/out/save), category_id, freq (weekly/biweekly/monthly/yearly), interval, anchor_date, next_due, active, icon NULL, amount_mode (fixed/varies/card) |
| `recurring_skips` | recurring_id, date (primary key together): a month a changing bill didn't go out |
| `suggestion_state` | category_id (primary key, references `categories`, deleted with its category), quiet_on NULL, rest_until NULL, forgotten_at NULL, asked_on NULL (schema v5, D172). What the user told one category's *your usual* (BR-17, D153): quiet for the day of an Undo, resting until a date, and when *Forget* was tapped; and `asked_on`, the day the missed-log line was last asked for it (never `quiet_on`, which feeds the Undo count). Dates are `YYYY-MM-DD`; `forgotten_at` is a local ISO timestamp like `created_at`. It goes into a backup and is wiped by *Delete everything* with the rest |
| `settings` | key, value. Ledger-owned keys: `currency`, `month_start`, `pay_switches` (JSON list of earlier pay rules, D140) (`keep_aside_minor` until schema v3). Settings-owned keys: `theme_mode`, `onboarding_done`, `onboarding_draft` (JSON). Backup-owned keys, local to the phone and never written into a backup: `last_backup`, `restore_snapshot` (the replaced data's backup JSON, kept 7 days for *Undo restore*), `restored_at` (D139). The pay rule lives on the income `recurring` row (DECISIONS D20) |

Indexes: `transactions(date)`, `transactions(category_id, date)`, unique `transactions(recurring_id, date)`.

Schema v3 (migration 003, D120) also holds the columns changing bills use since D123 (`amount_mode`, `recurring_skips`, the `card` kind), and moves a non-zero `keep_aside_minor` to a *Keep aside* saving rule, then deletes the key.

Schema v4 (migration 004, D153) adds `suggestion_state` and changes nothing else. Habits themselves are not stored: they are worked out from the last 56 days of `transactions` on every load.

Schema v5 (migration 005, D172, D175, D188) is for Fix my number, *Used* and the missed-log line. **Migration 005 is landed** (D191, with the yearly-costs build): all three parts, in one step:
1. Add the two hidden `categories` rows, `not_logged` (out) and `not_logged_in` (in), `archived = 1`. A fresh install seeds them too, and a backup older than v5 gains them on its in-memory migration.
2. Allow `transactions.kind = used` (a value only, unless a constraint on `kind` has to be widened) and add `transactions.saving_id` (NULL, an integer pointing at `recurring.id`), with an index on it.
3. Add `suggestion_state.asked_on` (TEXT NULL, `YYYY-MM-DD`).
4. The install line's *seen* flag is a `settings` key, and the install day is the local date of the earliest entry's `MIN(created_at)` (as D39; no new column). It travels in the backup and is wiped by *Delete everything*.
5. The backup's `schemaVersion` becomes 5. A pre-v5 file restores as before; migration 005 is tested from v4 and from a v4 backup (NFR-5). BR-16's restore and wipe must cover the new rows, the new column and the flag (tested).

---

## 9. Code architecture

Conventions are in `CLAUDE.md` and `.claude/rules/`. The layout is feature-first clean architecture:

```
lib/
  main.dart
  app/                         MaterialApp, theme wiring, l10n delegates, routes.dart
  core/
    db/                        AppDatabase (sqflite), versioned migrations
    design/                    tokens (HisaabColors), type, motion, haptics, AppIcon/AppIcons
    di/                        get_it registration (composition root only)
    errors/                    base Failure abstract class
    logging/                   AppLogger
    money/                     Money, CurrencySpec, MoneyFormatter
    time/                      Clock, PeriodCalculator
    usecases/                  UseCase<T, Params>
    layout/                    AppLayout.resolve, AppLayoutScope (adaptive panes, folds)
    widgets/                   Keypad, AmountText, DayBlocks, SignalKey, Tray, CategoryTile
  ledger/                      shared money feature: transactions, categories, recurring
    domain/ data/              entities, repositories, use cases (SaveEntry, GetCycleSummary,
                               PostDueRecurring), SafeToSpend, InsightRules, BudgetSuggester
  onboarding/ home/ add_entry/ spends/ ask_ai/ settings/
    presentation/              pages, widgets, bloc (+ domain/ when the feature owns logic,
                               e.g. ask_ai/domain/PromptBuilder)
  habits/                      your usual (BR-17, D153); see docs/features/habits/07-your-usual-build.md
    domain/                    HabitIndexBuilder, UsualSpendDetector, SuggestionGate, use cases
    data/                      suggestion_state data source, model, mapper, repository
    presentation/              HabitsBloc, UsualRowBloc, UsualAddedNotice, YourUsualRow
  l10n/                        app_en.arb, gen/
```

Rules:
- UI features depend on `ledger` only through `ledger.dart`, and on `habits` only through `habits.dart`.
- Widgets never touch the DB.
- Domain code is pure Dart with an injected `Clock`.
- Errors use `fpdart` `TaskEither<Failure, T>` (added in M0).
- Every state holder is a Bloc with sealed events (no Cubits); loads are `restartable()` and saves `droppable()` (D58).

## 10. Android specifics
- `minSdk 24`, edge-to-edge (enforced on Android 15), predictive back enabled.
- Every orientation and window size. Adaptive layout for foldables, tablets and multi-window (UI_DESIGN §13, DECISIONS D22).
- Other platform folders (ios/macos/linux/windows/web) left untouched but not built or tested.
- Privacy policy for the Play listing: `site/privacy/`, published by GitHub Pages to https://tejas-su.github.io/hisaab/privacy/ (DECISIONS D152). Update it when a permission or data flow changes.

## 11. Dependencies
Added: `intl`, `flutter_localizations`, `hugeicons`, `bloc_concurrency` (D58). `flutter_local_notifications` + `timezone` for the due-day bill reminders (owner-approved in the savings-and-bills spec §6, D126); `core library desugaring` is on in `android/app/build.gradle.kts` for it. `file_picker` for the system *Save to* and *Open* screens of Back up and Restore (owner-approved, D139); it adds no network permission. `material_ui` (Flutter's Material library, now a separate package; owner-requested, D146): every `package:flutter/material.dart` import became `package:material_ui/material_ui.dart`, and the app's localization delegates come from `material_ui`.
To add when the milestone needs them: `animations` (not needed in M1; the tray slides up), `fl_chart` (M4), `share_plus` + `url_launcher` (M5), `path` (M0). M7 (D147, D156) adds no Dart package: the widget, tile and shortcut talk to Dart over the app's own `hisaab/shortcuts` channel. Native only: `androidx.work:work-runtime-ktx` for the widget's midnight job, and, for the Kotlin unit tests only, `junit` and `org.json`. Mukta Regular and SemiBold are also copied into `android/app/src/main/res/font/` for the widget's words.
Fonts: Anek Latin (variable) and Mukta `.ttf` files bundled under `assets/fonts/` (M0).

---

## 12. Milestones

| # | Scope | Done when |
|---|---|---|
| M0 | Design tokens + theme (light/dark), AppIcon, l10n wiring, Money/formatter, Clock, AppLogger, DI, DB + migrations, seeded categories; add `fpdart`, `path`; bundle fonts; `git init` | App boots in `en_IN`, ₹ formats Indian-style, analyze clean, coverage script runs |
| M1 ✓ | Onboarding, Home hero (all BR-5 states, range line), Add tray, Today list, undo, core motion. Pulled forward because the hero needs them: `SafeToSpend` (BR-3..BR-7) and the recurring engine on start/resume | Log an expense in < 5 s, Add → digits → Next → tile |
| M2 ✓ | Recurring: midnight re-run (BR-8), due-soon nudge (FR-HO-3), bills in Settings, Money coming in: the amount and the payday (D137, D140) | Payday auto-adds income at midnight; nudge shows the soonest bill |
| M3 | *This week* toggle (FR-HO-2), "you saved yesterday" (BR-8), auto-suggested budgets (BR-12: `BudgetSuggester`, `GetSuggestedLimits`, `ApplySuggestedLimits`, category limits saved; the "Use these limits?" offer is shown by Spends in M4 as BR-14 insight #4) | Weekly view and morning note work |
| M4 ✓ | Spends: pace chart (a painter, not `fl_chart`), *Where it went* with limits, insights (BR-14), *Every entry* (FR-SP-6); Home's *See all* and over card. The Ask AI card comes with M5 and *Set a limit* waits for a design (DECISIONS D49–D54) | vs-last-cycle shown, 3 tips max |
| M5 | Ask AI export | Prompt copies/shares and pastes cleanly into ChatGPT |
| M6 | JSON backup & restore, Delete everything (D139), CSV export, accessibility pass (TalkBack, 1.5× text), polish | Data survives reinstall through a backup file; TalkBack reads every control |
| M7 | Home-screen widget (4 sizes, the hero's paper, the day-by-day snapshot), Quick Settings tile, app shortcut, Settings › Shortcuts (SPEC FR-WG, FR-SE-6, D147, D156, mockup 38). Built; see `docs/features/shortcuts/` | The widget is right after midnight and payday with the app closed; Add on the widget, tile or shortcut opens the keypad |
| M8 | *Fix my number*, yearly costs with *Used*, and the missed-log line (SPEC BR-18, BR-19, FR-KS, FR-FX, FR-HO-3, FR-HO-9, FR-SE-1 AC-Y1 to AC-Y11, FR-SP-4a; D163 to D189; mockups 41 to 43). No new package. Built in this order (08 §8.4): **(1) shared fixes** that hurt users today and everything after needs: the hold on every Home-door sheet as a count (FR-AD-5, P1), the pinned keypad body in the bill-sheet route with the bottom inset and the posture-agnostic anchor (FR-KS-1, P2, P3), the cap's held ring and spoken line in every keypad (FR-KS-2, P5, P6) and the 1.5× key-label clamp (FR-KS-3, P15); **(2) schema v5** (§8; **landed with step 3 as migration 005**, D191); **(3) yearly costs with *Used*** (BR-19, FR-SE-1, the Today, Every entry and Spends rows; **built 2026-11-13**); **(4) the missed-log line** (`MissedLogDetector`, FR-HO-3, `asked_on`; **built 2026-11-14**); **(5) Fix my number** (BR-18, FR-FX, the foot row, the install line, the Settings row and its door's own Undo, P4; **built 2026-11-14**, `docs/features/fix-my-number/01-ux-flow.md` "As built"; the device checks of 08 §5 are still to run). Also: the two Ask AI clauses and CSV `used`/`not logged` (BR-15), `TestWindows` additions (UI_DESIGN §13), the ARB keys with a `@description` each, and a neutral glyph for the *Not logged* row and Settings row (`design-system`) | Everything in the SPEC's M8 IDs is covered by tests that cite it, with the worked examples of BR-18 and BR-19 as golden cases (₹963, ₹1,541, ₹4,763, ₹866, ₹930, ₹852, hero ₹1,318 before and after a *Used*); a bill, a fix and a *Used* entry made from Home never drain under the scrim; every keypad sheet keeps its amount and action key on screen at 320×568, 412×400, landscape, book and tabletop; migration 005 passes from v4 and a v4 backup restores; `flutter analyze` is clean and changed-line coverage is at least 90%. **Before the Play release, not before the build (D164):** the pre-release user test (08 §4) and the device checks of 08 §5 (D1 guard focus, D6 the 400 ms drain, D13 largest font) are run, and their outcomes may change ARB strings and the guard's threshold only |

Tests: unit tests for all of `domain/` and `core/money`, `core/time`; widget tests for M1 flows.

## 13. Later (not v1)
UPI/bank SMS auto-read (as payment-notification capture, case study 31) · Hindi · cloud sync · multi-currency.
