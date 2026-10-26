# Hisaab — Product & Build Plan

Target: **Android only** (v1). Currency: **INR** (architected for any locale/currency).
Stack: Flutter · flutter_bloc (Cubits) · get_it · sqflite · equatable · fpdart · intl + gen-l10n · hugeicons · figma_squircle · bundled fonts (Anek Latin, Mukta).

---

## 1. Core idea

The app answers one question: **"How much can I still spend?"**

- **Money in** — recurring income, entered once, auto-added every payday.
- **Money out** — expenses + recurring bills (auto-added).
- **Left** — one big number on Home. Green / amber / red.

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
| Over budget | Shown as "₹1,200 over" in red, never "-₹1,200" | — |
| Paise | Whole rupees only: no decimal key, never displayed (stored as minor units) | — |
| Savings goal | Off. Optional "Keep aside every month" amount, subtracted from spendable | Toggle |

---

## 3. Screens

1. **Onboarding (3 steps, progress dots):** income amount, when it comes, optional fixed bills (SPEC FR-ON).
2. **Home:** the hero card (safe to spend today, Day Blocks, range line), due-soon nudge, Today list, dock (FR-HO).
3. **Add tray:** amount keypad, then category tiles; tapping a tile saves (FR-AD).
4. **Spends:** Ask AI card, pace chart, where-it-went bars (no donut), up to 3 insights, and *See every entry* for the full day-grouped history (FR-SP).
5. **Ask AI:** goal, period, preview, copy/share/open ChatGPT (FR-AI).
6. **Settings:** money, categories, look, data (FR-SE).

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
- **Locale source**: `SettingsCubit` holds `Locale` + `CurrencySpec`; `MaterialApp` reads them. Default `en_IN`.

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
| `categories` | id, name, icon_key, kind (in/out), budget_minor NULL, sort, archived |
| `transactions` | id, amount_minor, currency, kind, category_id, date, note NULL, recurring_id NULL, created_at |
| `recurring` | id, label, amount_minor, currency, kind, category_id, freq (weekly/biweekly/monthly/yearly), interval, anchor_date, next_due, active |
| `settings` | key, value. Ledger-owned keys: `currency`, `month_start`, `keep_aside_minor`. Settings-owned keys: `theme_mode`, `onboarding_done`, `onboarding_draft` (JSON). The pay rule lives on the income `recurring` row (DECISIONS D20) |

Indexes: `transactions(date)`, `transactions(category_id, date)`, unique `transactions(recurring_id, date)`.

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
    presentation/              pages, widgets, cubit (+ domain/ when the feature owns logic,
                               e.g. ask_ai/domain/PromptBuilder)
  l10n/                        app_en.arb, gen/
```

Rules:
- UI features depend on `ledger` only through `ledger.dart`.
- Widgets never touch the DB.
- Domain code is pure Dart with an injected `Clock`.
- Errors use `fpdart` `TaskEither<Failure, T>` (added in M0).
- Cubits are the default, and Bloc is used only when event modelling is needed.

## 10. Android specifics
- `minSdk 24`, edge-to-edge (enforced on Android 15), predictive back enabled.
- Every orientation and window size. Adaptive layout for foldables, tablets and multi-window (UI_DESIGN §13, DECISIONS D22).
- Other platform folders (ios/macos/linux/windows/web) left untouched but not built or tested.

## 11. Dependencies
Added: `intl`, `flutter_localizations`, `hugeicons`.
To add when the milestone needs them: `figma_squircle` (M0), `animations` (M1), `fl_chart` (M4), `share_plus` + `url_launcher` (M5), `path` (M0), `file_picker` (M6), `home_widget` + `quick_settings_tile` (later).
Fonts: Anek Latin (variable) and Mukta `.ttf` files bundled under `assets/fonts/` (M0).

---

## 12. Milestones

| # | Scope | Done when |
|---|---|---|
| M0 | Design tokens + theme (light/dark), AppIcon, l10n wiring, Money/formatter, Clock, AppLogger, DI, DB + migrations, seeded categories; add `fpdart`, `figma_squircle`, `path`; bundle fonts; `git init` | App boots in `en_IN`, ₹ formats Indian-style, analyze clean, coverage script runs |
| M1 | Onboarding, Home hero, Add tray, Today list, undo, core motion | Log an expense in < 5 s, Add → digits → Next → tile |
| M2 | RecurringEngine (income + bills), PeriodCalculator | Payday auto-adds income; catch-up works; tests green |
| M3 | Safe-to-spend, status colours, auto-suggested budgets | Over-budget turns red with one shake |
| M4 | Insights: charts + rule tips | vs-last-cycle shown, 3 tips max |
| M5 | Ask AI export | Prompt copies/shares and pastes cleanly into ChatGPT |
| M6 | CSV/JSON backup & restore, accessibility pass (TalkBack, 1.5× text), polish | Data survives reinstall; TalkBack reads every control |

Tests: unit tests for all of `domain/` and `core/money`, `core/time`; widget tests for M1 flows.

## 13. Later (not v1)
UPI/bank SMS auto-read · home-screen quick-add widget · Hindi · cloud sync · multi-currency.
