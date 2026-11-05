# 29 · Changing bills copy deck

Status: **final copy for Phase 2, bills that change and the card bill** (plan `docs/superpowers/plans/2026-11-05-phase-2-changing-bills-and-card.md`, Task 1). The key names and placeholders are the plan's. The plan's default wins unless a row says *yes* and gives the reason.

**Sources:** spec `docs/superpowers/specs/2026-11-04-savings-and-changing-bills-design.md` §2, §5 and §8; the plan's "Where this plan departs" bullet on the card line; case studies 16 and 18; deck 28; the `bill*`, `dueSoon*`, `saving*` and `entry*` strings in `lib/l10n/app_en.arb`.

**Worked example:** today Mon 26 Oct 2026. *Electricity* changes every month, day 18, estimate ₹1,200; on 18 Oct it went out and is still waiting; the user enters ₹1,460. *Credit card* is a card bill, day 26, about ₹8,000; it is due today. A second card the user named *HDFC card* shows the named case.

**Length:** the smallest `TestWindows` size is `smallPhone` 320×568, about 280dp of content, about 37 Latin characters a line of 16sp Mukta. The Home line also has a trailing chevron, so count about 33 there. Line counts are estimates for a `smallPhone` widget test to confirm. A label can be 40 characters (`BillValidator.maxLabelLength`), so the worst case is given too. Hindi needs 30–40% more room.

**Word rules used here:**
- **Goes out / went out** is the bills' verb, as in `billGoesOut` and `billDayQuestion`. A changing bill *went out* on its day; the app asks how much.
- **Due** is for the card bill only. The card is paid by the user, so it is *due*, and the question is *how much did you pay*.
- **Counted** is the existing word for "this takes from your money" (`billStampCounted`). The card row says *not counted again*, and the card hint says the same words, so the user meets one idea in one phrasing.
- **About** marks an estimate everywhere: the amount question, the due-soon line. It is never "approx" or "~".
- **Credit card** is a product name and is allowed. "Credit" and "debit" as accounting words are not used.
- **The bill's name is used as the user wrote it**, capital and all, mid-sentence too. `billAmountQuestion` already does this ("How much is School fees?").

---

## Copy table

| key | final text | placeholder? | changed? | note |
|---|---|---|---|---|
| `fixedBills` | Bills | none | no | Settings row and list title, beside *Savings* (spec §5 IA). The key stays `fixedBills`; only the value changes. Tests that find "Fixed bills" change with it (plan Task 1 Step 4, D123). See the out-of-scope list: four neighbours still say "fixed". |
| `billName` | `{kind, select, rent{Rent} emi{EMI} phone{Phone} internet{Internet} schoolFees{School fees} subscriptions{Subscriptions} creditCard{Credit card} electricity{Electricity} other{Bill}}` | `kind` String | no | Two cases added; the other six are unchanged. "Credit card" is what Indian banks and users call it; "Card" alone could be a debit card. Settings only; onboarding keeps its six pills (D125). |
| `billAmountQuestionVaries` | About how much is {bill}? | `bill` String | no | Mirrors `billAmountQuestion` ("How much is {bill}?") with "About" front-loaded, so the user knows a guess is fine. "About how much is Electricity?" 30 characters, 1 line. |
| `billAmountQuestionCard` | About how much is the {bill} bill? | `bill` String | no | "About how much is the Credit card bill?" (39, 2 lines) and "…the HDFC card bill?" (36, 1 line) both read well. Asks about the bill, not the swipes. If the user typed a name that ends in "bill" ("HDFC card bill") it reads "bill bill"; see build notes. |
| `billCardHint` | Add what you buy on the card on the day you buy it. This bill only reminds you to pay. It isn't counted again. | none | **yes** | Options: (a) the default, "Add card buys when you make them. This only reminds you to pay, so nothing counts twice."; (b) "Add card spends as they happen…"; (c) this one. Picked (c). "Card buys" uses *buy* as a noun, which a Hindi-first reader may not parse, and "spends" as a noun is Indian English but clashes with the *Spends* tab. "Nothing counts twice" is abstract: it asks the reader to picture the double count. "It isn't counted again" says the fact and uses the same words as the row the user will see (`entryCardPaid`). Three short sentences, all one-syllable verbs. About 110 characters, 3 to 4 lines. |
| `billModeRow` | Amount changes? | none | no | Bill sheet row label. Options: (a) "Amount changes?"; (b) "Kind of bill"; (c) "Each month". Kept (a): it front-loads *Amount*, the word a user hunts for when the electricity bill is different. (b) fits the other row labels (all nouns) and the *Credit card* answer better, but a user looking for "my amount changes" would tap *Amount* instead. Two flags for build: the answer *Credit card* reads a little sideways under "Amount changes?" (it is still true: a card bill changes); and `billChangeSpoken` will say "Change Amount changes?, Same every month". TalkBack drops the "?", so it is heard as "Change amount changes, same every month". Check this on the phone; if it jars, use (b) for the row and keep (a) as the question title. |
| `billModeFixed` | Same every month | none | no | Plain and parallel with the next one. |
| `billModeVaries` | Changes every month | none | no | Parallel with *Same every month*; one word differs, so the choice is easy to see. |
| `billModeCard` | Credit card | none | no | The same text as the `billName` pill, on purpose: the user picks *Credit card* once in the wizard and sees the same words here. Not a collision (different keys, same meaning). Build note: picking the *Credit card* pill should set this mode. |
| `waitingVariesToday` | {bill} went out today. How much? | `bill` String | no | Home's nudge slot. The name first, then the fact, then the question. "Electricity went out today. How much?" 37, 2 lines with the chevron. Worst case (40-character name) 3 lines. |
| `waitingVariesOn` | {bill} went out on {date}. How much? | `bill` String, `date` String | no | "Electricity went out on 18 Oct. How much?" 41, 2 lines. `{date}` is the short form used by `billStampCounted` ("18 Oct"). Never a nag: no "still", no "you forgot", no count of days. |
| `waitingCardToday` | {bill} bill is due today. How much did you pay? | `bill` String | no | The plan's recorded departure: the line names the card. "Credit card bill is due today. How much did you pay?" 52, 2 lines; "HDFC card bill is due today…" 49, 2 lines. Options: (a) this; (b) "…due today. How much?"; (c) "…due today. How much are you paying?". Kept (a): what the user types is what they *paid* (it may be the minimum due, not the bill), and "did you pay" says so. Someone who hasn't paid yet answers later; the line stays until then. |
| `waitingCardOn` | {bill} bill was due on {date}. How much did you pay? | `bill` String, `date` String | no | "Credit card bill was due on 18 Oct. How much did you pay?" 57, 2 lines. Past tense matches the past date. Worst case 3 lines. |
| `waitingOpensHint` | Opens the keypad. | none | **yes** | Full stop added. The neighbours `dueSoonOpensBill` ("Opens the bill.") and `dueSoonOpensSaving` end with one, and TalkBack pauses on it. |
| `billGoesOutAbout` | `{bill} about {amount} goes out {days, plural, =1{tomorrow} other{in {days} days}}` | `bill` String, `amount` String, `days` int | **yes** | The plan's draft had a `{when}` String. The existing `billGoesOut` takes an int `days` with a plural select, so this mirrors it exactly: same placeholders, same cases, "about" added before the amount. `rule_words.dart` `ruleGoesOut` can then pick the key by mode and pass the same arguments. Due-soon is 1 to 5 days ahead, so there is no "today" case: on the day it becomes the waiting line. "Electricity about ₹1,200 goes out in 3 days" 43, 2 lines. For the card: "Credit card about ₹8,000 goes out tomorrow", which is true (the payment leaves the bank). `{amount}` is the spoken form for TalkBack, as for `billGoesOut`. |
| `billAmountTitle` | {bill} · {date} | `bill` String, `date` String | no | "Electricity · 18 Oct". The `·` joiner matches the row lines. TalkBack reads the dot as a pause. |
| `billAmountLastTime` | Last time {amount} | `amount` String | no | Caption under the prefilled keypad: "Last time ₹1,200". Short and true **only once there is a last time**. The first month the prefill is the user's own guess; see the proposed `billAmountYourGuess` below. |
| `billDidntGoOut` | Didn't go out this month | none | no | The skip chip. A fact, not a failure: no "skip", no "missed". It works for the card too (no payment left the bank). The apostrophe is safe: the ARB already has "Payday's tomorrow". |
| `billAmountAdded` | {bill} {amount} added | `bill` String, `amount` String | no | Snackbar with Undo: "Electricity ₹1,460 added". Mirrors the `billGoesOut` order (name, amount, verb). For a card bill it reads "Credit card ₹8,000 added", which could sound like it was added to spending; the row's *Paid, not counted again* answers that one glance later, so no extra key. |
| `billSkipped` | {bill} skipped this month | `bill` String | no | Snackbar with Undo after *Didn't go out this month*. It names the bill, unlike `savingSkipped` ("Skipped this month"), because it shows on Home after the sheet closes, away from the row. |
| `entryCardPaid` | Paid, not counted again | none | no | Second line of the card bill row: "Credit card · Paid, not counted again · ₹8,000". Sentence case to match `entrySaved` and `entryPutInExtra`. It informs: the money left the bank, and the app already counted the swipes. 23 characters, 1 line. |

### Proposed extra key (not in the plan's list)

| key | final text | placeholder? | note |
|---|---|---|---|
| `billAmountYourGuess` | You said about {amount} | `amount` String | The caption the first time a changing bill is entered, when there is no *last time*: "You said about ₹1,200". "Last time ₹1,200" would be untrue then. It uses "about", the estimate word. If the plan owner would rather not add a key, the caption can be left out the first month (the prefilled amount still shows). |

## Checks

- **Banned words** ("transaction", "debit", "credit" as an accounting word, "budget period", "Oops"): none. "Credit card" appears only as a product name, in `billName`, `billModeCard` and through `{bill}`.
- **"Fixed"** is gone from the new strings. It stays in four old ones; see below.
- **"Saved"** is not used for bills (deck 28's rule). The bill sheet's `billSaved` ("Saved.") footer is still the clash deck 28 flagged.
- **Glossary:** "share", "payday", "goes out" used as defined. "Cycle" is not shown.
- **ICU:** `billName` keeps its variable and cases and gains two. `billGoesOutAbout` copies `billGoesOut`'s `days` plural exactly. No string is built by joining pieces.
- **Collisions with existing ARB text:** `billModeCard` and the `billName` `creditCard` case are both "Credit card" (intended; see the note). `billIconName` has `card{Card}`, an icon name, which is not shown beside these. No other new line matches an existing string. Reuse the existing `save` ("Save") for the keypad's marigold key and `undo` ("Undo") for the snackbars; no new keys for them.
- **No exclamation marks, no blame.** The waiting lines never say "still", "forgot" or "late".

## Build notes

- **"bill bill".** `billAmountQuestionCard`, `waitingCardToday` and `waitingCardOn` add "bill" after the name. A name that already ends in "bill" (e.g. "HDFC card bill") would read "HDFC card bill bill". The two pills can't cause it. Don't strip words in code (that breaks in Hindi); instead keep the name field's hint as it is, and add a `smallPhone` test with a 40-character name for line count.
- **`{date}`** is the short day-month form (`18 Oct`), as in `billStampCounted`. If a waiting bill can be from the previous calendar year (a cycle crossing 1 Jan), the date stays short: the line only shows the current cycle's bills.
- **TalkBack** reads the Home line as one sentence plus `waitingOpensHint`. Amounts in `billGoesOutAbout`, `billAmountAdded` and `billAmountLastTime` go through `MoneyFormatter`'s spoken form in semantics.

## Out of scope here: flagged for the plan owner

These existing strings say "fixed" or "by themselves", which stops being true once a bill can change or be a card bill. They aren't in the plan's key list, so this deck doesn't change them; suggested text is given.

| key | today | suggested | why |
|---|---|---|---|
| `fixedBillsHint` | They go out by themselves on their day. Today's share already leaves room for them. | Most go out by themselves on their day. If the amount changes, Home asks how much. | A changing bill doesn't go out by itself; it waits. The second sentence is also false for a card bill, which takes no room. |
| `noBills` | No fixed bills yet. Add rent, EMI or anything that goes out every month. | No bills added yet. Add rent, EMI or anything that goes out every month. | Matches the *Bills* title, and `noSavings`' "added yet". |
| `billSheetEyebrow` | Fixed bill | Bill | The eyebrow sits above an Electricity sheet whose answer is *Changes every month*. |
| `entryFixedBill` | Fixed bill | Bill | The second line of an entered Electricity row would say *Fixed bill*. |
| `billSaved` | Saved. | Changed. | Deck 28's flag, still open: "Saved" means real saving. |

`billsQuestion` ("Any fixed bills?") stays: onboarding offers only the six fixed pills (D125).
