# 28 · Savings copy deck

Status: **final copy for Phase 1 Savings** (plan `docs/superpowers/plans/2026-11-04-phase-1-savings.md`, Task 4 Step 1 and Task 9). The key names are the plan's. The plan's default wins unless a row says *yes* and gives the reason.

**Sources:** spec `docs/superpowers/specs/2026-11-04-savings-and-changing-bills-design.md` §5 and §8; case study 17; the `bill*`, `dueSoon*`, `savedYesterday*` and `*over its share` strings in `lib/l10n/app_en.arb`.

**Worked example:** today Mon 26 Oct 2026, payday on the 4th, `D` = 9. RD ₹5,000 on the 10th, put in on 10 Oct. *Put in extra* ₹500 gives "Each day till payday gets ₹62 less". BR-8: `X` = ₹1,665, `Y` = ₹185.

**Length:** the smallest `TestWindows` size is `smallPhone` 320×568, about 280dp of content, about 37 Latin characters a line of 16sp Mukta. Line counts are estimates for a `smallPhone` widget test to confirm. Hindi needs 30–40% more room.

**Word rules used here:**
- **Saved** means only money put into an RD, SIP, gold scheme or chit. It appears only in `entrySaved` and `spentAndSaved`.
- **Put in** is the verb for the act and the total ("₹42,000 put in since Jan"). Never "worth" or "balance": the app doesn't know interest, penalties or closure.
- **Goes in** mirrors the bills' **goes out**.
- **Cycle** stays a system word. No user-facing string in the ARB says it, so none here does.

---

## Copy table

| key | final text | changed? | reason |
|---|---|---|---|
| `savings` | Savings | no | Settings row and list title, beside *Bills*. One plain word. |
| `savingsHint` | Money you put away on the same day every month, like an RD. It goes in by itself on its day. Today's share already leaves room for it. | **yes** | `fixedBillsHint` says "They go out by themselves on their day". The default left out the matching sentence, and it is the one that matters most here. Case study 17 and edge case E-k rate double counting as the top risk: a UPI user sees the bank SMS on RD day and logs ₹5,000 as *Spent* again. "It goes in by itself" tells them the app already has it. About 4 lines at 280dp. |
| `addSaving` | Add a saving | no | Mirrors `addBill` ("Add a bill"). A verb first, and it says what happens. |
| `noSavings` | No savings added yet. Add an RD, SIP or anything you put in every month. | **yes** | "No savings yet" under the title *Savings* reads as a verdict on the user ("you have no savings"), which may be false and is shaming. Case study 17 notes saving is getting harder for lower-middle-class users. "added" makes it about this list, not their money. The empty-state shape (what goes here, one action) is unchanged. |
| `savingName` | `{kind, select, rd{RD} sip{SIP} goldScheme{Gold scheme} chit{Chit} other{Saving}}` | no | The owner's and the banks' own words. RD and SIP are known as letters, so they are not spelt out. |
| `savingNameQuestion` | What do you save in? | no | Short, plain, and asks about the place, not the job. |
| `savingNameHint` | RD, SIP, gold scheme… | no | It repeats the pills, but the bill hint now does too (Electricity became a pill), so it is consistent. It is not wrong. |
| `savingAmountQuestion` | How much goes into {saving}? | no | Uses the "goes in" word and mirrors `billAmountQuestion`. |
| `savingDayQuestion` | Which day does {saving} go in? | no | Mirrors `billDayQuestion` ("…go out?") word for word. `rule_words_test` asserts it. |
| `savingSheetEyebrow` | Saving | no | Mirrors `billSheetEyebrow`. |
| `deleteSaving` | Delete saving | no | Mirrors `deleteBill`. Past *Saved* entries stay (BR-9), as for bills. |
| `savingDeleted` | Deleted {saving} | no | Mirrors `billDeleted`. Shown with Undo. |
| `savingSkipped` | Skipped this month | no | Snackbar after swiping away a saving its rule put in (Home, Entries). Never "missed"; no count (case study 17). An extra put in by hand still says "Deleted ₹500". |
| `savingStampDue` | `{days, plural, =1{Goes in tomorrow} other{Goes in {days} days from now}}` | **yes** | The default's other form, "In 3 days", has no verb, so on its own (and to TalkBack) it doesn't say what happens. It also doesn't match its own `=1` form or the bill stamp ("Due in 3 days"). "Goes in in 3 days" would say "in" twice, which trips up slow readers, so it says "from now" instead. The `=1` form is unchanged. At up to 26 characters it is the longest stamp, so check it fits on the `smallPhone` sheet head. |
| `savingStampCounted` | Put in {date} | no | Mirrors `billStampCounted` ("Counted 5 Oct"). It says the act, with no "saved" ambiguity. `bill_sheet_test` asserts "Put in 10 Oct". |
| `savingStampCountedToday` | Put in today | no | Mirrors `billStampCountedToday`. |
| `savingNextGoesIn` | Next goes in on {date} | no | Mirrors `billNextGoesOut`. Asserted by `bill_sheet_test`. |
| `savingSlipSpoken` | {saving}, {amount}, every month on day {day} | no | `billSlipSpoken` without the icon, because a saving has no Icon row. `{amount}` must be the spoken form from `MoneyFormatter`. |
| `savingGoesIn` | `{saving} {amount} goes in {days, plural, =1{tomorrow} other{on {weekday}}}` | no | It matches the spec's "RD ₹5,000 goes in on Thu". A weekday is clear because the line shows only 1 to 5 days ahead. Note for build: pass the full weekday name, or check how TalkBack reads "Thu". |
| `dueSoonOpensSaving` | Opens the saving. | no | Mirrors `dueSoonOpensBill`. |
| `entrySaved` | Saved | no | The row word in "RD · ₹5,000 · Saved". This is real saving, the one place the word belongs. |
| `entryPutInExtra` | Put in extra | no | The row word for a one-off save. It matches the button, so the user sees the same words they tapped. |
| `savedSince` | {amount} put in since {month} | no | "Put in" is a fact, never a value ("worth", "balance"). Note for build: if the first save was in an earlier year, `{month}` needs the year ("Jan 2025"), or "since Jan" is ambiguous. |
| `putInExtra` | Put in extra | no | The button: a verb first, and it says what happens. |
| `putInQuestion` | How much extra are you putting in? | no | One idea, plain words. |
| `putInEachDayLess` | `{end, select, monthEnd{Each day till month end gets {amount} less} other{Each day till payday gets {amount} less}}` | no | It informs without shaming: a fact about the days ahead, with "till payday" / "till month end" following D116 like the other cycle strings. 1 to 2 lines. |
| `putInLastDay` | `{end, select, monthEnd{The month ends today.} other{Payday's tomorrow.}}` | no | Edge case E-h's wording. It explains why there is no per-day split. |
| `putInNothingLeft` | Nothing left to put in for now. | **yes** | The default ends "this cycle". "Cycle" is a glossary system word and no user-facing ARB string uses it: the over cards say "this month's money" or "this week's money". "For now" works for payday, month-end and weekly cycles alike, and it needs no new placeholder, so the message's form is unchanged. It informs without blame: when there is no money left, the user isn't told they overspent. |
| `spentAndSaved` | Spent {spent} · Saved {saved} | no | The spec's line. "Saved" here is real saving. The `·` joiner matches `dotJoin` use elsewhere. |
| `savedYesterday` (BR-8) | Yesterday was {amount} under its share, so every day got {more} more. | **yes** | "Came in ₹X under" is an idiom that a Hindi-first reader may not parse. The app already says the opposite with "{day} was {amount} over its share" (`weekDayOver`) and "{amount} over its share" (`overShare`). So "was ₹X under its share" reuses words the user has already seen, and it uses "share", the glossary word. Still no "saved". About 2 lines at 280dp. Example: "Yesterday was ₹1,665 under its share, so every day got ₹185 more." |
| `savedYesterdayOnly` (BR-8) | Yesterday was {amount} under its share. | **yes** | It pairs with `savedYesterday`, for when `Y` < ₹1. Example: "Yesterday was ₹1,665 under its share." |

## Checks

- **Banned words** ("transaction", "debit", "credit", "budget period", "Oops", "worth", "balance"): none in any final text.
- **"Saved"** appears only in `entrySaved` and `spentAndSaved`, both meaning real saving. The BR-8 note no longer says it. The `savedYesterday*` key names stay, as Task 9 requires.
- **Glossary:** "share" (Today's share), "payday" and "month end" (D116) are used as defined. "Cycle" is not shown to users.
- **ICU:** every select and plural keeps the default's variable names and cases. No placeholder was added or removed.
- **No exclamation marks, no blame**, and no "missed" or "behind" (case study 17).

## Out of scope here: flagged for the plan owner

- **`billSaved` ("Saved.")** is the footer the bill sheet shows for 2.4 s after an answer is saved. On a saving's sheet it would read "Saved." just after the user changes the RD amount, which clashes with *Saved* as real saving. This deck doesn't add a key. One way to fix it is to give the footer the same text on both sheets, for example "Changed.", in a later change.
- **Settings row name:** spec §5 renames *Fixed bills* to *Bills*, but Task 4 Step 2's mockup still shows *Fixed bills* beside *Savings*. `fixedBills` and `billSheetEyebrow` ("Fixed bill") aren't in this deck's key list.
