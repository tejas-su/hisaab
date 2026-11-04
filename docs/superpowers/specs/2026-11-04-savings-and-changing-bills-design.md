# Savings and bills that change: design

**Status:** design approved in chat on 2026-11-04 (owner answers: credit card = A, `flutter_local_notifications` approved, keep-aside replaced). Waiting: review of this written spec.
**Research:** [case study 17, savings and RD](../../design-research/case-studies/17-savings-and-rd.md) · [case study 18, variable bills and quick entry](../../design-research/case-studies/18-variable-bills-and-quick-entry.md) · [case study 16, bill sheet](../../design-research/case-studies/16-bill-edit-flow.md)
**Next decision number:** D119 (D117–D118 were taken by parallel work).

## 1. Problem
The owner's two jobs:
1. **"I save something on set days (an RD), and I want to see how much I saved and how much I spent."** Today a saving can only be the hidden keep-aside `K`. It has no date, no record and no total, and logging the RD as *Spent* inflates spending.
2. **"Bills like the credit card go out on a set day, but the amount changes. Let me enter the amount quickly, from a tap or a notification, and track it."** Today every bill is a fixed amount that posts by itself, so a changing bill is wrong every month. Fixing it means finding the entry and editing it (4 taps, unprompted).

There's also a **live bug** that both jobs make worse. A bill posted on its own day counts as today's spending (SPEC BR-3: "Bills due today… count as spent today"), so on rent day the hero shows ₹0, *Over today*.

**Success:**
- An RD shows up on its day without a tap, never drains today's bar, and Spends shows "Spent ₹X · Saved ₹Y".
- A changing bill is entered in ≤ 3 taps plus digits from Home, and ≤ 2 from the notification.
- Card swipes are counted once.
- No day reads *Over today* just because a bill or saving went out.
- The Add flow is untouched.

## 2. The model: what each outgoing does
| Kind (`EntryKind`) | Stored as | Example | Reserved before its day | On its day | Counts in *Where it went*, pace, insights | Over today possible |
|---|---|---|---|---|---|---|
| `spent` (logged) | `out` | chai, a card swipe | — | `S_today` | yes | yes |
| `spent` (bill, posted by a rule) | `out` + `recurring_id` | rent, electricity | `B` | `R_t` (out of the pool, **not** today's share) | *Where it went* yes (as now); pace and insights no (as now, BR-7, BR-14) | no |
| **`saved`** (new) | `save` | RD, SIP, *Put in extra* | `R` | `Sv` (out of the pool) | **never** | no |
| **`cardPaid`** (new) | `card` | the credit card bill paid | never | never counted | never | no |
| `got` | `in` | salary | — | `I` | — | — |

Owner decision 1 = A: **a card swipe is spending when it happens, and paying the card bill is not spending.** The card bill is recorded so the owner can track it, but it is never added to any total.

## 3. Formulas (replaces SPEC BR-3, amends BR-4, BR-6, BR-7, BR-8)
```
P = I − K − B − S_prev − R_t
K = R + Sv_cycle_to_yesterday + Sv_rule_today          // computed; no longer a setting
A = max(0, floor(P / D))
safeToday = A − S_today
remaining = P − S_today − Sv_extra_today
tomorrow  = floor(remaining / (D − 1))                  // D > 1
```
| Symbol | Meaning |
|---|---|
| `B` | Bill occurrences in this cycle not yet posted: **fixed** bills due in `(t, end]` at their amount, plus **changing** bills due in `[start, end]` still *waiting* (not entered, not skipped) at their estimate |
| `R` | **Saving** rule occurrences due in `(t, end]`, not yet posted |
| `R_t` | *Spent* entries dated `t` with `recurring_id` set (bills posted or entered today) |
| `S_prev` | All *Spent* entries dated `[start, t−1]`, bills included (unchanged) |
| `S_today` | *Spent* entries dated `t` with **no** `recurring_id` (bills dated today are `R_t`) |
| `Sv_cycle_to_yesterday` | All `saved` entries dated `[start, t−1]` |
| `Sv_rule_today` | `saved` entries dated `t` posted by a rule |
| `Sv_extra_today` | `saved` entries dated `t` with no rule (*Put in extra*). Like an overspend, they leave today's `A` fixed and thin the later days |

**One rule, said in words:** *anything a rule posts is set aside before its day and comes out of the pool on its day, never out of today's share.*

- **BR-4 amendment:** `A` is fixed for the day **except** when a bill amount is entered or changed today. That recomputes `A`, as a back-dated entry already does.
- **BR-7:** the pace already ignores rule-posted entries and now also ignores `saved` and `cardPaid`. The spare is `remaining − pace × (D − 1)`.
- **BR-8:** "yesterday as it stood" applies the same rule. Rename the note (see §8), because "You saved" now collides with real saving.

**Worked examples** (SPEC's numbers: `t` = Mon 26 Oct, `D` = 9, `I` = 45,000, `S_prev` = 27,150, ₹420 spent today):
1. **Bug fix, rent day** (nothing spent yet today, ₹15,000 rent posts today, no other bills):
   - **Before:** `P` = 45,000 − 27,150 = 17,850, `A` = 1,983 and `S_today` = 15,000, so the hero shows ₹0, *₹13,017 over today*.
   - **After:** `R_t` = 15,000, so `P` = 2,850, `A` = 316 and the hero shows **₹316**.
   - Yesterday, rent sat in `B`, so the share was already sized for it. **Nothing jumps on rent day.**
2. **Changing bill entered today.** Electricity, estimate ₹1,200, due today and waiting: `B` = 1,200, `P` = 16,650, `A` = 1,850, hero ₹1,430. The user enters ₹1,460: `B` = 0, `R_t` = 1,460, `P` = 16,390, `A` = 1,821, hero **₹1,401**. (Old rule: ₹103.)
3. **RD.** A ₹5,000 RD on the 10th has already posted, so `K` = 5,000, `P` = 11,650 and `A` = 1,294, identical to the old `K` = 5,000. *Put in extra* ₹500 today: `A` and the hero stay at 1,294 and ₹874; `tomorrow` = floor(10,730 / 8) = 1,341.
4. **Card bill.** A card bill of ₹8,000 paid today changes nothing: `P`, `A` and the hero are unchanged. The swipes were counted when they happened.

## 4. Data
**Migration 003** (schema v2 → v3, since v2 shipped as the bill-icon migration, D118; SQLite can't alter a `CHECK`, so `recurring` and `transactions` are rebuilt in one transaction, keeping ids):
- `transactions.kind` CHECK: `'out','in','save','card'`.
- `recurring.kind` CHECK: `'out','in','save'`.
- `recurring.amount_mode TEXT NOT NULL DEFAULT 'fixed' CHECK IN ('fixed','varies','card')`. It applies to `out` rules only. `save` rules are always `fixed`.
- New table `recurring_skips(recurring_id, date, PRIMARY KEY(recurring_id, date))` records "didn't go out this month" for a changing bill. Waiting state is derived: an occurrence ≤ today with no entry and no skip.
- **Category:** `saved` and `cardPaid` entries use the rule's category. A seeded **hidden** category per kind (`saved`, `card`) is never shown in any grid or chart (BR-11's 8 + 4 are unchanged).
- **Keep-aside migration:** if `keep_aside_minor` > 0, create a `save` rule "Keep aside" for that amount on the pay day (the income rule's day; the 1st if income "changes"), with `next_due` set by D33 (no back-post). Then delete the key. `BudgetSettings.keepAside` and `CycleInputs.keepAside` go; `K` is computed.

**Domain** (`lib/ledger/`):
- `EntryKind { spent, got, saved, cardPaid }`, with the mapper and validator updated.
- `AmountMode { fixed, varies, card }` on `RecurringRule`.
- `BillKind` gains `creditCard` and `electricity`. `BillKind.amountMode`: `creditCard` → `card`, `electricity` → `varies`, the rest → `fixed`.
- New `SavingKind` pills: RD, SIP, Gold scheme, Chit.
- **Recurring engine (BR-9):** it posts `fixed` bills and `save` rules on their day. It **never** posts `varies` or `card` rules; it only advances their `next_due` once the occurrence is entered or skipped, or the cycle moves past it.
- New use cases:
  - `GetWaitingBill`: the oldest waiting `varies`/`card` occurrence in this cycle; ties go to the rule saved first.
  - `EnterBillAmount(rule, date, amount)`: posts an entry with the rule's `recurring_id` and the occurrence date. For `card` the kind is `cardPaid`. The estimate is updated to this amount (the estimate is the last amount entered).
  - `SkipBillOccurrence`, `PutInExtra(amount)`, `AddSaving`, `EditSaving`, `DeleteSaving`, and `GetSavedTotal(since)`.
- `SafeToSpend` and `CycleInputs` gain `R`, `R_t`, `Sv…` per §3.

## 5. Screens
**Settings (IA):** two rows, **Bills** (renamed from *Fixed bills*) and **Savings**. Each opens its own list.

**Adding (three questions, as today, D35):**
- *Bills:* name (8 pills in two columns, 4 rows: Rent, EMI, Phone, Internet, School fees, Subscriptions, **Credit card**, **Electricity**) → amount → day.
  - For `varies` the amount question reads **"About how much?"**.
  - For `card` it reads **"About how much is the bill?"**, with one line under it: **"Add card buys when you make them. This only reminds you to pay, so nothing counts twice."**
  - When the first `varies`/`card` bill is saved, ask once: **"Remind you on the day it's due?"** with *Remind me* / *Not now*, then the Android permission prompt. *Not now* is never asked again.
- *Savings:* name (pills: RD, SIP, Gold scheme, Chit) → amount → day. The question titles say "goes in", e.g. "Which day does it go in?".

**Changing (the bill sheet, case study 16, built here):** tap a row and a sheet rises with the summary and Change rows: *Amount*, *Day*, *Name*, plus for bills **Amount changes?** with the options *Same every month* / *Changes every month* / *Credit card*. Saving one answer saves it alone. *Delete* is on the summary, with Undo.

**Bill amount sheet (the quick entry):**
- Opened from the Home line or the notification, straight onto the keypad.
- Title: "Electricity · 18 Nov". Prefilled with the estimate, caption **"Last time ₹1,200"**, and the marigold key reads **Save**. One tap confirms "same as last time".
- A text chip, **"Didn't go out this month"**, skips the occurrence.
- Save: `tick` haptic, the sheet closes, a snackbar "Electricity ₹1,460 added" with Undo.

**Home:**
- **The nudge slot (FR-HO-3) shows one line,** in this order of priority:
  1. A waiting bill: **"Card bill is due today. How much did you pay?"** (`card`), **"Electricity went out today. How much?"** (`varies`), or "…on 18 Nov. How much?" for an earlier day. Tappable, with a trailing chevron.
  2. Due-soon (1–5 days ahead): bills "Rent ₹15,000 goes out in 3 days"; `varies`/`card` with "about": "Electricity about ₹1,200 goes out tomorrow"; savings "RD ₹5,000 goes in on Thu".
  3. Nothing.
- **Today list rows:** a saving reads "RD · ₹5,000 · *saved*" (own glyph, word, no colour, never a bite on today's bar). A card bill reads "Card bill · ₹8,000 · *paid, not counted again*". A bill posted today shows as now, but isn't a bite on today's bar.
- The hero, today's bar and the rail don't change for any of this.

**Savings list:** rows (name, day, amount), a footer **"₹42,000 put in since Jan"** (never "worth" or "balance"), and a button **Put in extra**. It opens the keypad with a preview line, "Each day till payday gets ₹62 less", and is capped at `remaining`.

**Spends:**
- One line above *Where it went*: **"Spent ₹27,570 · Saved ₹5,000"** for the period shown.
- `saved` and `cardPaid` are never in the bars, percentages, week bars or insights.
- *Every entry* lists them with their word.

**Ask AI (BR-15):**
- The facts line becomes "…I save ₹5,000 a month (RD on the 10th)" and drops "keep aside".
- The CSV `kind` gains `saved` and `card_bill_paid`.
- The recurring list marks changing bills "(changes, about ₹X)" and the card "(credit card; purchases already listed)".

## 6. Notification (Phase 3)
- **Package:** `flutter_local_notifications` (+ `timezone`), approved by the owner. Manifest: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`. **No** exact-alarm permission.
- **One per `varies`/`card` occurrence, at about 09:00 on the due day,** `inexactAllowWhileIdle`.
  - Title "Card bill is due today" / "Electricity went out today"; text "Tap to add how much".
  - Visibility private; the public version reads **"A bill is due"**. No amount or note ever shows.
- **Tap:** a deep link `hisaab://bill/{ruleId}/{date}` opens Home, then the bill amount sheet.
- **No action buttons. Never repeated.** Cancelled when the occurrence is entered or skipped, or the rule is deleted. A swipe-away isn't re-sent.
- **Scheduling:** on every app start or resume and after boot, re-arm the next occurrence of each `varies`/`card` rule (idempotent: the notification id comes from `ruleId` and the date). Home's line is the guarantee, and the notification is a bonus (Xiaomi, Oppo, Vivo and realme may drop it).
- Code: `lib/core/notifications/` (a `BillReminders` port with an Android adapter and a `FakeBillReminders` for tests). Notification text comes from ARB through a non-widget l10n lookup.

## 7. Edge cases (add to SPEC §5)
| # | Case | Behaviour |
|---|---|---|
| E-a | A bill or RD day of 29–31 | Clamped as in BR-1 |
| E-b | A saving bigger than everything left | `P` < 0: Over for the cycle, naming the saving (as E5) |
| E-c | A waiting bill never entered by the cycle's end | It drops out of `B` silently; no carry-over nag; it isn't posted. Late entry is allowed, dated in its own cycle (E6) |
| E-d | Entering a bill twice for the same occurrence | Unique `(recurring_id, date)`; the second is an edit of the first |
| E-e | Undo after entering | Back to waiting; the estimate goes back to the previous one |
| E-f | The rule changes from *varies* to *fixed* mid-cycle | Waiting occurrences stay waiting; future ones auto-post |
| E-g | App closed for 6 weeks | Fixed and saves catch up once each (E7). Only the current cycle's changing bills wait; past cycles' are dropped |
| E-h | `D = 1` (payday tomorrow) and *Put in extra* | Allowed up to `remaining`; the preview reads "Payday's tomorrow" (no per-day split) |
| E-i | Notification permission denied or revoked | Nothing is asked again; the Home line still works |
| E-j | A card bill with income "changes" | No difference; a card bill never touches the pool |
| E-k | An RD posted, then the user also logs ₹5,000 *Spent* from a bank SMS | Not prevented (risk). The RD row on Today and the due-soon line are the cues. Blind-read test |

## 8. Copy (via `design-content` before build; strings in `app_en.arb`)
- Banned words still apply. "Card bill" is fine; never "transaction", "debit" or "credit".
- New words: *saved*, *put in*, *goes in*, *Put in extra*, *Didn't go out this month*, *paid, not counted again*.
- **BR-8 note reworded**, so "saved" means only real saving. Suggested: "Yesterday came in ₹X under, so every day got ₹Y more." Final wording is `design-content`'s.

## 9. Delivery: four phases, each shippable
| Phase | Ships | Depends on |
|---|---|---|
| **0. Bills come out of the pool, not today** | `R_t` in `SafeToSpend`, BR-3/4/6/6a/8 tests, DECISIONS D119 | — |
| **1. Savings** | Migration 003 (all of §4 at once, so there's one schema bump), the `saved` kind, saving rules, keep-aside migration, Settings → Savings list and wizard, Home row and due-soon, *Put in extra*, the Spends line, Ask AI, BR-8 copy | 0 |
| **2. Changing bills and card** | The bill sheet (case study 16), `AmountMode`, the 2 new pills, the waiting state, `B` with estimates, the bill amount sheet, the Home "How much?" line, `cardPaid` | 1 (migration) |
| **3. Due-day notification** | The package, `BillReminders`, permission ask, deep link, boot re-arm | 2 |

**Each phase is done when** `flutter analyze` is clean, `flutter test` passes, changed-line coverage is ≥ 90%, SPEC, UI_DESIGN and DECISIONS are updated in the same change, there's a mockup for every new screen (Savings list, bill amount sheet, Home line, Spends line), and it's tested at the `TestWindows` sizes.

## 10. Not in this
Savings targets, progress bars, interest, maturity and tenure, balances, opening amounts, withdrawals; daily or weekly saving rules; a *Saved* segment in Add; notification action buttons or direct reply; a home widget, Quick Settings tile or shortcut; bank or SMS reading; averaging estimates.

## 11. Risks
- **The `R_t` change touches the core formula** and many tests (BR-3 to BR-8). It goes first and alone.
- **RD double-logging** from a bank SMS (E-k). Validate with a 5-user test before Phase 1 ships, if possible.
- **"Put in" totals read as a balance.** The copy never says "worth" or "balance".
- **Reminders don't arrive on aggressive OEMs.** The design doesn't depend on them.
- **A table-rebuild migration** risks data loss. Test v1 → v2 with real SQLite (`sqflite_common_ffi`), ids and the unique index preserved, and a rollback on failure (as `runMigrations` does).
