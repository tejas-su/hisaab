# Decision log

One row per decision that shaped the product, newest last. To change a decision, add a new row that supersedes the old one; don't edit history.

| # | Date | Decision | Why | Alternatives rejected |
|---|---|---|---|---|
| D1 | 2026-10-26 | **Android only**, Flutter | Focus; the target users are on Android | iOS and web in v1 |
| D2 | 2026-10-26 | **INR only in v1**, but `intl`/gen-l10n, `Money` with a currency code, and `en_IN` formatting from day 1 | Ship simple; avoid a costly migration later | Hard-coded `₹` strings |
| D3 | 2026-10-26 | **The budget cycle follows payday automatically**; a single Settings override sets the month to start on the 1st | Users think in "till salary"; the term "budget period" confuses (SPEC BR-1) | Asking the user at onboarding; calendar month only |
| D4 | 2026-10-26 | **Zero-config defaults**: no category budgets at start (auto-suggested after one cycle), no accounts or wallets, no confirmation dialogs (Undo instead) | "A 5-year-old can use it" | Setup wizards; budgets first |
| D5 | 2026-10-26 | **Hugeicons only**, always paired with a label | Client choice; NN/g on icon labels | Material Icons |
| D6 | 2026-10-26 | Rejected: the **"Gullak" name and clay piggy-bank mascot** | Client didn't like them | — |
| D7 | 2026-10-26 | **Day Blocks** hero, plus an EV-style range line | Countable for children; unclaimed by money apps; daily share curbs overspending (Arizona study: exact totals raise spend 26–33%) | Rings (Apple-owned, angle reads poorly), battery/tank (cliché, alarming late in the cycle), pace chart on Home (needs axes) |
| D8 | 2026-10-26 | **Calm monochrome + one signal colour**, marigold `#FFB020`, meaning "today / act" | Client choice; the Braun ET66 → Apple lineage; colour used only when meaningful | Warm clay palette; bright playful palette |
| D9 | 2026-10-26 | **No red anywhere**; states shown by fill, outline, hatch and words | Avoids shame and panic (Kite, Copilot, Monzo research); colour-blind safe | Red overspend |
| D10 | 2026-10-26 | **No category colours** | One-colour system; categories are told apart by icon, label and fixed position | Okabe-Ito category palette |
| D11 | 2026-10-26 | **Anek Latin + Mukta** (Ek Type) | ₹, tabular figures and Devanagari all verified; instrument-like semi-condensed numbers | Baloo 2 (too playful for the monochrome direction), Fraunces (no tnum/Devanagari), Inter/Plus Jakarta (generic) |
| D12 | 2026-10-26 | **Whole rupees only** in entry and display; stored as paise | Low-literacy research: decimal errors dominate; consistent precision builds trust | A decimal key |
| D13 | 2026-10-26 | **Fixed positions**: categories, keypad (phone layout) and dock never reorder | UPI users memorise positions; PhonePe 2025 backlash | Most-used-first ordering |
| D14 | 2026-10-26 | **Apple-style springs**, critically damped by default, 0.8 damping only for thrown gestures | WWDC18 *Designing Fluid Interfaces* | M3 Expressive bouncy springs everywhere |
| D15 | 2026-10-26 | **Ask AI = export, not integration**: copy, share or open ChatGPT; nothing leaves the phone without the user's tap | Privacy, no API keys, works with any AI | In-app LLM calls |
| D16 | 2026-10-26 | Brand is the **hisaab•** wordmark; the Play Store title carries a descriptor | "Hisaab" is crowded (15+ Play apps); the dot gives visual distinctiveness | Bare "Hisaab"; "Aaj ka Hisaab" |
| D17 | 2026-10-26 | Team rules ported from `melento-nocode-flutter`, with **Cubit-first**, **get_it at the composition root only**, `equatable` instead of `freezed`, and `fpdart` for errors | Same habits as the team, sized for a small offline app | Bloc everywhere; no DI framework |
| D18 | 2026-10-26 | Feature-first layout with a shared **`ledger`** feature | UI features share money data without putting feature logic in `core/` | A global `data/` and `domain/` layer |
| D19 | 2026-10-26 | Forecasts rounded to ₹100 and prefixed "about"; pace excludes recurring bills | Honest about uncertainty; scheduled bills aren't "pace" (SPEC BR-7) | Exact-rupee forecasts |
| D20 | 2026-10-26 | **One `settings` key-value table, split by owner:** ledger owns money keys (`currency`, `month_start`, `keep_aside_minor`), the settings feature owns app preferences (`theme_mode`, `onboarding_done`, `onboarding_draft`). The pay rule lives on the income recurring row | Each key has exactly one owning repository; no feature logic in `core/` | Separate tables per owner; a core-level preferences store |
| D21 | 2026-10-26 | **No hidden long-press features in v1** (day-block detail, "make this repeat") | Undiscoverable for the target user; recurring bills live in Settings | Long-press shortcuts |
