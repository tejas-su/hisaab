# 41 · Copy deck: Fix my number, yearly costs (*Used*) and the missed-log line

> **Status: proposed (2026-11-13).** One deck for **three proposed features**: *Fix my number* (`docs/features/fix-my-number/01` to `04`), yearly costs with *Used* (`docs/features/yearly-costs/01-ux-flow.md`) and the missed-log line (`docs/features/habits/08-missed-log-line.md`). None of it is in `lib/l10n/app_en.arb`, SPEC, PLAN, UI_DESIGN or DECISIONS, and none is approved. Nothing here is final until the owner signs off the designs and the blind read (section 9) has run. Strings marked *reuse* already exist in the ARB.

**Sources:** the three feature folders above, `03-information-architecture.md` (labels, placement), case studies 33 ("Owner answers", binding) and 34 (wording findings, blind-read plan), `lib/l10n/app_en.arb`, DECISIONS D59, D105, D116, D120, D121, D132, copy deck 28.

**Worked example (SPEC):** payday on the 4th, today 26 Oct, `D` = 9. hisaab expects `E` = ₹17,430. Lower: user types ₹13,230, gap ₹4,200, each day ₹467 less, hero becomes ₹963. Higher: types ₹18,430, gap ₹1,000, each day ₹111 more, hero ₹1,541. Large: types ₹47,430, gap ₹30,000 (more than 10% of ₹45,000).

## 0. Conventions

- **Budgets.** Smallest `TestWindows` size is `smallPhone` 320×568: about 280dp of content. At 1x, 16sp Mukta fits about 37 characters a line. **At 1.5x text: about 24 characters a line for body, about 18 for a 22sp title, about 20 for the 14sp snackbar text beside *Undo*, and about 7 for a keypad action key (about 88dp wide).** "Chars" is the English text with a typical amount (₹17,430); "worst" adds a lakh amount. Line counts are estimates for a `smallPhone` widget test at 1.5x. Hindi needs 30 to 40% more.
- **Spoken amounts.** Every `{amount}`-style placeholder is a `MoneyFormatter` string. For TalkBack the caller passes the spoken form ("4,200 rupees", as `spokenAmount` does) into the **same key**, so most strings need no separate TalkBack key. The TTS then says "four thousand two hundred rupees". A column says "same" when only the placeholder changes, and gives a sentence where the shape differs.
- **Amount format on the Fix my number sheet:** full Indian grouping always (`₹1,25,000`, never `₹1.25L`), because a compact figure would hide a ₹500 gap. Open question 3.
- **Cycle words.** `{period}` is `week` or `month` (month end and payday cycles both say *month*, as FR-HO-5 and D116). Weekly cycles read "this week's".
- **One word per idea (D132).** *Fix* (the act: door "Fix my number", key "Fix it", snackbar "Fixed"), *Not logged* (the entry), *set aside* (money waiting in a saving), *Used from savings* (paid from that pot), *put in* (money into a saving), *Saved* (only that, D120), *less / more* (direction, never colour).
- **Idioms are out (D121).** "Spot on" and "came in under" do not travel to a Hindi-first reader.
- **Every ARB key gets a `@key` `description`.** The "where it shows" column below is the description text.

## 1. Conflicts resolved

| # | Conflict | Options | Decision | Reason |
|---|---|---|---|---|
| R1 | Page title | A "How much money do you have right now?" (study 34 V1). B "How much of this month's money is left?" (01). C "How much money is left, from this month?" | **B**, with study 34's V2 as the fall-back if the blind read says B loses | A invites the whole bank total, and `E` is only this cycle's money: the buffer case would post a *Got* for older money (01 §1.1, study 34 finding C1). B reuses "this month's money" from the over card, so the user has met the phrase. C reads as a fragment |
| R2 | Helper | A "Bank and cash together. Leave out older savings." B "Bank and cash together. Leave out money from before this month." C "Add up bank and cash. Count only this month's money." | **B** | "Savings" is also the name of the RD feature, whose money has already left the bank. "Before this month" names the buffer by time, which a user can check. C repeats the title and the notice after *No*. It does **not** say "we'll take out your bills and savings": the typed figure still contains the bills' money (01 §1.5) |
| R3 | Does line 1 show hisaab's own figure? | A one sentence, no figure ("That's ₹4,200 less than hisaab thought."). B two lines: "hisaab thought ₹17,430." then the gap | **B**, shown only after the first digit | A hidden number cannot be checked or explained (principle 86). Shown only after typing, so the user reads their bank first and is not anchored (principle 87). It also makes *hisaab* the one that guessed, so no blame on the user. The gap sentence drops "than hisaab thought", which line 1 now carries |
| R4 | "about" before the gap | A "about ₹4,200 less" when the answer is round. B never on the gap, always on the per-day effect | **B** | The gap is an exact difference and that exact amount is what gets posted. "About" would suggest the entry may differ. The per-day figure really is approximate (a floor), so "about" stays there. Rough answers are already covered by *Close enough* |
| R5 | Snackbar "Fixed. Today you can spend ₹X." | A as drafted. B "Fixed. Safe to spend today: ₹X." | **B** | It repeats the hero's own title (`safeToSpendToday`), so the user links the snackbar to the number that just rolled. At ₹0 it needs no softening (04 open question 9): "Safe to spend today: ₹0" is the hero's own calm state, and the over card carries any next step. No praise, no exclamation |
| R6 | Entry word and second line | A "Not logged" with "Added to match your money". B "Added to match" alone. C "Not logged" with "Added when you fixed your number." | **C** | "Not logged" is the owner's word (33, P1-3) and is the category and CSV value. "Your money" is vague (the bank? the pay?). C names the user's own act, answers "who put this here?" (study step 2) and removes any sense of a failed payment (I-5). B is the blind-read fall-back |
| R7 | *Used* | A "Used". B "Paid from this". C "Spent from savings". D "Used from savings" on rows and parts, "Used some of it" on the key | **D** | Study 34: "Spent" invites a clash with the *Spent* kind (C out). "Paid from this" has no noun on a row (B out). Bare "Used" reads as an insurance claim (IA 4.2) and sits near the over card's "used up" (IA 4.5). "Used from savings" keeps the one root word the key teaches, names the pot, and cannot be read as a claim. The second line says it in plain words: "Paid from what you set aside." |
| R8 | Does the *Not logged* row show its direction? | Omit the kind word (02 draft) or always show it (IA 4.2) | **Always: "Not logged · Spent" and "Not logged · Got"** | With no sign and no colour the word is the only carrier of direction (IA 4.2a). It is the same *Spent*/*Got* pair as elsewhere |
| R9 | "Fix it will check with you first" (04 S3) | Keep, or a plain sentence | **"That's ₹30,000 more. One question first."** | A button label is not a speaker. The new line says what comes next, in four words |
| R10 | "Spot on" / "Close enough" | Keep or plain | **"That matches. Nothing to fix." / "That's close enough. Nothing to fix."** | "Spot on" is an idiom (see conventions) |
| R11 | Yearly caption "a twelfth" | A "Put in about a twelfth each month." B "Put in the cost divided by 12 each month." | **B** | "A twelfth" is a rare fraction word. "Divided by 12" is plain and an exact instruction. It still never promises a first-year cover (U2) |
| R12 | "Saving…" on the *Fix it* key after 1s (04 S9) | Change the label or keep it | **Keep "Fix it", show the pressed and disabled state, and say "Saving" to TalkBack only** | "Saving…" is 7 characters and does not fit an 88dp key at 1.5x |
| R13 | Missed-log line | A "Spent on Food today?" with "Usually around 1 pm." (existing `04-`). B "Did you spend on Food today?" with "You usually do, around 1 pm." | **A**, B goes in the blind read | A is shorter and describes the habit without addressing the person. "no" is a fine answer either way |

## 2. Home, Settings and the install line

| key | English | Where it shows, and `@description` | TalkBack | Budget at 1.5x |
|---|---|---|---|---|
| `fixMyNumber` | `Fix my number` | The label everywhere: Home foot row, Settings row title, the install line's second line. "A door's label: the user's own word for the Home figure" | "Fix my number, button. Opens the keypad." (hint reuses `waitingOpensHint`) | 13 chars, 1 line |
| `fixSettingsDetail` | `When the number on Home looks wrong.` | Settings row second line, under `fixMyNumber`. "Says when to use it, in the user's words" | same | 36 chars, 2 lines |
| `fixInstallTitle` | `Already spent some {period, select, week{this week} other{this month}}?` | First line of the one-time Home line (mid-cycle install). The second line is `fixMyNumber`. "One-time pointer, shown once, never a nudge" | "Already spent some this month? Fix my number. Opens the keypad." One merged node | 30 chars, 2 lines of about 16 chars in the row; second line 1 line |

Notes: the foot row has no second line and no count (IA 2.1). The label is the same everywhere; the page title is a question (R1).

## 3. The Fix my number sheet

Placeholders: `{gap}` (whole rupees, full format), `{amount}` (hisaab's figure, `E`), `{perDay}` (int rupees, for the plural) and `{perDayAmount}` (its formatted string), `{short}` (rupees short of what is still due), `{period}` (week or month).

| key | English | State and `@description` | TalkBack | Budget at 1.5x |
|---|---|---|---|---|
| `fixTitle` | `How much of {period, select, week{this week's} other{this month's}} money is left?` | Sheet title (S0 to S9). "The one question, scoped to this cycle's money" | Heading, same | 40 chars, 3 lines of 18 |
| `fixHelper` | `Bank and cash together. Leave out money from before {period, select, week{this week} other{this month}}.` | S0, S0b: replaced by the preview after the first digit. "Says what to count and what to leave out" | Same | 63 chars, 3 lines |
| `fixPreviewBase` | `hisaab thought {amount}.` | Line 1 in every preview state after the first key (S1 to S5). Hidden when `E` is zero or below (F7). "What hisaab expected, shown after the user typed so they are not anchored" | "hisaab thought 17,430 rupees." | 23 chars, 1 line; worst 28, 2 lines |
| `fixPreviewLess` | `That's {gap} less. {perDay, plural, =0{Each day stays about the same.} other{Each day gets about {perDayAmount} less.}}` | S1, line 2 | "That's 4,200 rupees less. Each day gets about 467 rupees less." | 50 chars, 3 lines; worst 62, 3 lines |
| `fixPreviewMore` | `That's {gap} more. {perDay, plural, =0{Each day stays about the same.} other{Each day gets about {perDayAmount} more.}}` | S2, line 2. Also F7 (no line 1) | "That's 1,000 rupees more. Each day gets about 111 rupees more." | 50 chars, 3 lines |
| `fixPreviewLessShort` | `That's {gap} less, and {short} short of what's still due.` | S1 when the answer leaves less than the bills and savings still to come (F4). Takes precedence over the last-day and per-day lines. "Informs; the calm over card follows and carries the next step" | "That's 4,200 rupees less, and 300 rupees short of what's still due." | 55 chars, 3 lines |
| `fixPreviewLessLastDay` | `That's {gap} less. Today takes all of it.` | S1 on the last day, `D` = 1 (F10) | "That's 4,200 rupees less. Today takes all of it." | 42 chars, 2 lines |
| `fixPreviewMoreLastDay` | `That's {gap} more. Today gets all of it.` | S2 on the last day | same shape | 41 chars, 2 lines |
| `fixPreviewEqual` | `That matches. Nothing to fix.` | S4, key off. Line 1 still shows | Same | 29 chars, 2 lines |
| `fixPreviewClose` | `That's close enough. Nothing to fix.` | S5: a round answer within ₹50 (F2), key off | Same | 36 chars, 2 lines |
| `fixPreviewBig` | `That's {gap} more. One question first.` | S3: a large *higher* gap. *Fix it* stays on and opens the guard | "That's 30,000 rupees more. One question first." | 40 chars, 2 lines |
| `fixAction` | `Fix it` | The bottom-right key, where *Next* sits. "Posts one Not logged entry for the gap" | Button. Disabled hints below | 6 chars, 1 line (fits 88dp at 1.5x) |
| `typeAmountFirst` | `Type an amount first.` | TalkBack hint on a disabled action key (S0, S0b, S0c) and on *Save* of the *Used* keypad. "Hint only; never shown" | Hint | spoken only |
| `fixActionHintNothing` | `Nothing to fix.` | TalkBack hint on a disabled *Fix it* in S4 and S5. "Hint only; never shown" | Hint | spoken only |
| `fixSavingSpoken` | `Saving` | Polite announcement while the write runs (R12). "Not shown; the key keeps its label" | Spoken | spoken only |
| `fixLoadFailed` | `Couldn't check your number.` | S0c, with the *reuse* key `tryAgain` as a 48dp text key. "E could not be loaded" | Same, then "Try again, button" | 27 chars, 2 lines |
| `fixNoticeChanged` | `Things changed. Check the new amount.` | S6: the save was refused because the ledger moved (F13). Replaces line 1 until the next key | Same, polite | 37 chars, 2 lines |
| `couldntSave` | *reuse:* `Couldn't save. Try again.` | S8, failed write (F15) | Same | 25 chars, 2 lines |

### The guard (large *higher*)

| key | English | Where | TalkBack | Budget at 1.5x |
|---|---|---|---|---|
| `fixGuardQuestion` | `That's {gap} more. Is all of it from {period, select, week{this week} other{this month}}?` | Slot line 2 in the guard step, under `fixPreviewBase`. "Second question before a large Got is posted" | "That's 30,000 rupees more. Is all of it from this month?" Focus lands here first | 50 chars, 3 lines |
| `fixGuardNo` | `No, some is older` | First key, focused first. "Back to the keypad with the digits kept" | Button, same | 17 chars, 1 line |
| `fixGuardYes` | `Yes, add {gap}` | Second key. Says what happens. "Posts a Got entry for the gap" | "Yes, add 30,000 rupees, button" | 16 chars, 1 line; worst 22 |
| `fixNoticeCountOnly` | `Count only {period, select, week{this week's} other{this month's}} money.` | S7, the notice after *No*, until the next key | Same, polite | 30 chars, 2 lines |

R9: `fixPreviewBig` is what the slot says while the keypad is still on screen, and `fixGuardQuestion` is what it says once the keys have changed.

### After the save

| key | English | Where | TalkBack | Budget at 1.5x |
|---|---|---|---|---|
| `fixDone` | `Fixed. Safe to spend today: {amount}.` | Snackbar with *Undo* (4 s, D105). "Says what changed in the Home number" | "Fixed. Safe to spend today: 963 rupees." Stays until dismissed under TalkBack | 33 chars, 2 lines of 20; worst 38, 2 lines |
| `undo` | *reuse:* `Undo` | Snackbar action | Button | 4 chars |
| `undone` | `Undone.` | Polite announcement after *Undo*. "Not shown" | Spoken | spoken only |

## 4. Today list and Every entry rows

| key | English | Where | TalkBack | Budget at 1.5x |
|---|---|---|---|---|
| `entryNotLogged` | `Not logged` | The row title (the hidden category's name), both directions | Part of the sentence below | 10 chars |
| `notLoggedRow` | `Not logged · {direction, select, got{Got} other{Spent}}` | Today list and Every entry: title and kind word. Amount beside it. No bite, no tap, not in the header total, swipe deletes with Undo. "Direction is a word, never a colour or sign" | `notLoggedRowSpoken`: `Not logged, {direction, select, got{got} other{spent}}, {amount}` gives "Not logged, spent, 4,200 rupees" and "Not logged, got, 1,000 rupees" | 18 chars; row wraps to 2 lines |
| `notLoggedDetail` | `Added when you fixed your number.` | Every entry second line, both directions | Read after the row | 33 chars, about 3 lines |
| `entryUsed` | `Used from savings` | Kind word on the *Used* row: "Insurance · Used from savings", amount beside it. No tap, swipe deletes with Undo | `entryUsedSpoken`: `{saving}, used from savings, {amount}` gives "Insurance, used from savings, 4,000 rupees" | 17 chars; row wraps to 2 lines |
| `entryUsedDetail` | `Paid from what you set aside.` | Every entry second line | Read after the row | 29 chars, about 3 lines |

## 5. Spends line (FR-SP-4a)

The line is parts, fixed in order, each shown only when above ₹0 and each unbreakable. The widget wraps **between** parts and joins them with the `·` it already uses. The parts replace the single string `spentAndSaved`, which cannot wrap between its two halves. Keep `spentAndSaved` until the migration is done. A part is a whole phrase, so a translator may reorder words inside it.

| key | English | Notes | Budget at 1.5x |
|---|---|---|---|
| `spendsPartSpent` | `Spent {amount}` | The same words as today | 14 chars |
| `spendsPartSaved` | `Saved {amount}` | Money put into a saving only | 14 chars |
| `spendsPartUsed` | `Used from savings {amount}` | Only in a cycle with a use | 26 chars; worst 31. May exceed one line at 1.5x, so allow a wrap inside this part as a last resort (amount to the next line), never an ellipsis |
| `spendsPartNotLogged` | `Not logged {amount}` | The *Spent* side only. A *Got* fix is in Every entry (IA open question 3) | 19 chars; worst 24 |

TalkBack: one sentence, the same keys with spoken amounts, parts separated by a full stop: "Spent 27,570 rupees. Saved 1,000 rupees. Used from savings 12,000 rupees. Not logged 4,200 rupees."

## 6. Yearly costs: the saving, the *Used* key and its keypad

| key | English | Where, and `@description` | TalkBack | Budget at 1.5x |
|---|---|---|---|---|
| `savingName` (extend) | add `insurance{Insurance} schoolFees{School fees} festival{Festival}` to the existing select | Three more name chips, after RD, SIP, Gold scheme and Chit, which never move | Chip, same | 12 chars at most |
| `savingYearlyCaption` | `Paid once a year? Each month, put in the cost divided by 12.` | Under the amount, for the three new chips only (S2) | Same | 60 chars, 3 lines |
| `savingYearlyUsedHint` | `When you pay it, tap Used some of it.` | Second sentence, same place (IA 3). `design-ui` may drop it on a short window | Same | 37 chars, 2 lines. With the caption: 5 lines at 1.5x, so the body scrolls above the fixed keypad |
| `savingSetAside` | `{amount} set aside` | Savings list row second line, and the balance line on the saving's sheet. Only above ₹0 | "4,000 rupees set aside" | 16 chars, 1 line |
| `savingUsedHint` | `Paid the cost from this? Tap Used some of it.` | Sheet, under the balance line. Only with something set aside | Same | 45 chars, 2 lines |
| `savingUsedAction` | `Used some of it` | The outlined mid-sheet key. "Opens the keypad to say how much of the pot was used" | Button, hint `waitingOpensHint` | 15 chars, 1 line on a full-width key |
| `savingUsedQuestion` | `How much did you use from {saving}?` | *Used* keypad title | Heading, same | 36 chars, 2 lines of 18 plus the name |
| `savingUsedAll` | `All of it` | Chip right of the amount. Prefills the whole pot | "All of it, chip, selected" when the amount equals the pot | 9 chars; about 140dp at 1.5x, so it may drop below the amount (`design-ui`) |
| `savingUsedSetAside` | `{amount} is set aside.` | Slot line 1 before a digit | "4,000 rupees is set aside." | 20 chars, 1 line |
| `savingUsedLeft` | `{left, plural, =0{Nothing will be set aside.} other{{amount} will still be set aside.}}` | Slot line 1 while digits are typed. `{left}` is int rupees, `{amount}` its string | "0 rupees" never spoken: the zero form says "Nothing will be set aside." | 33 chars, 2 lines |
| `savingUsedSame` | `Your daily number doesn't change.` | Slot line 2, always. "Answers the first worry before the user commits" | Same | 33 chars, 2 lines |
| `savingUsedCap` | `That's all you have set aside. Add the rest as a spend.` | Replaces line 1 when a digit past the pot is refused (reject haptic and shake). Says why and the next step | Read once, polite | 55 chars, 3 lines |
| `savingUsedNothing` | `Nothing is set aside to use.` | Slot when the pot fell to ₹0 behind the sheet; *Save* off | Same | 28 chars, 2 lines |
| `save` | *reuse:* `Save` | Action key | Disabled hint: `typeAmountFirst` | 4 chars |
| `savingUsedDone` | `{saving}: {amount} used` | Snackbar with *Undo* (D132: name first) | "Insurance: 4,000 rupees used" | 22 chars, 2 lines |
| `savingsStillSetAside` | `{left, plural, =0{Nothing is set aside now.} other{{amount} still set aside}}` | Footer line 2 of the Savings list, under `savedSince`. Only when any saving has something set aside or a use exists | "5,000 rupees still set aside" | 22 chars, 1 to 2 lines |

Failure on the *Used* keypad: *reuse* `couldntSave`.

## 7. The missed-log line (Home)

| key | English | Where | TalkBack | Budget at 1.5x |
|---|---|---|---|---|
| `missedLogTitle` | `Spent on {category} today?` | Line 1 of the line in the nudge slot | One merged node: "Spent on Food today? Usually around 1 pm. Opens the keypad." (hint reuses `waitingOpensHint`). Not a live region, no announcement | 20 chars plus the name, 2 to 3 lines (the category is never cut) |
| `missedLogBody` | `Usually around {time}.` | Line 2. `{time}` is `DateFormat.j` with `en_IN` ("1 pm"). "Describes the person's habit, hedged; a no is a fine answer" | Same | 20 chars, 1 to 2 lines |

No ×, so `notToday` is not added (08 §3). There is no "missed", "forgot" or "didn't log" anywhere in this line.

## 8. Ask AI facts clause and CSV (not ARB, D59)

`PromptBuilder` holds the fixed English. Proposed wording for the clause, added **only when the export holds such entries**, so the existing golden string for other exports stays byte-stable (BR-15 needs two new goldens):

- **Not logged:** `Entries with the category "not logged" are corrections. When the user checked their real money it differed from this list, so one entry was added for the difference. Treat each as a one-off, not as a purchase or a habit, and do not give spending advice about it.`
- **Used:** `Entries of kind "used" are costs the user paid from money they had already set aside in a saving, such as a yearly insurance bill. That money was counted when it was put in, so it is not spending in this period and does not change the daily number. Do not add it to spending.`

| CSV column | Values |
|---|---|
| `kind` | `spent`, `got`, `saved`, `used` (new) |
| `category` | `not logged` (new, lowercase, a reserved name per BR-11), `savings` for *Saved* and *Used* |
| `note` | `Not logged` for a fix; the saving's name for *Used* |

## 9. Blind-read list (study 34 plan, to run before the build)

Five people, owner runs it, cards shown cold and rotated. Nobody explains a word before it is read. Pass lines are study 34's: 4 of 5.

| # | Card or string | Ask (exact) | Pass |
|---|---|---|---|
| B1 | Home row `Fix my number` (no explanation), and the Settings row with `When the number on Home looks wrong.` | "What do you think this says? What would happen if you tapped it?" | 4 of 5 read it as correcting the figure, not editing income or deleting entries. Fallback: "Correct today's number" |
| B2 | Row `Not logged · Spent ₹4,200`, **first alone**, then with `Added when you fixed your number.` | "What is this? Who put it there? How does it make you feel?" | 4 of 5 read it as "not recorded", no blame, no failed payment. Fallback: "Added to match" |
| B3 | Page titles, rotated (each person sees V1 first, then two others): V1 "How much money do you have right now?"; V2 V1 plus "Bank and cash together. We'll take out your bills and savings."; V3 "How much do you have in your bank right now?"; V4 "How much can you spend before payday?"; V5 two fields, *Bank* and *Cash*; **V6 `fixTitle` with `fixHelper`** | "Say a number." then "Tell me what you included." | One number in under 20 s; what they counted matches (no buffer). If V6 loses, fall back to V2 |
| B4 | Helper line: `Leave out money from before this month.` against the old `Leave out older savings.` | "What would you leave out?" | 4 of 5 name the right money. Also probes a card bill still owed (F17) |
| B5 | Preview with `hisaab thought ₹17,430.` and `That's ₹4,200 less. Each day gets about ₹467 less.`, then the `more` version, then `That matches. Nothing to fix.` | "Say this back in your own words. Who is this telling off?" | 4 of 5 get the direction right; none feel blamed; "hisaab thought" is read as hisaab's guess |
| B6 | Guard: `That's ₹30,000 more. Is all of it from this month?` with `No, some is older` and `Yes, add ₹30,000` | "What would each key do?" | 4 of 5 know *No* goes back to typing |
| B7 | Snackbar `Fixed. Safe to spend today: ₹963.` and the ₹0 version | "What happened?" | Read as the Home number changing, not a bug being fixed |
| B8 | Saving *Car insurance* with the key as each of `Used some of it`, `Paid from this`, `Spent from savings`, `I paid from it`; and rows `Insurance · Used`, `Insurance · Used from savings` | "When you've paid it, which would you press? What does the row mean?" | Not read as new spending or as an insurance claim. If "Spent from savings" wins, add a second line saying it is not counted again |
| B9 | The over card's `This month's money is used up.` beside the *Used* row | "Are these the same word? What does each mean?" | Not confused (IA 4.5 clash) |
| B10 | `Paid once a year? Each month, put in the cost divided by 12.` against "a twelfth" | "What would you put in each month?" | 4 of 5 divide the year's cost by 12 |
| B11 | `set aside` and `still set aside` | "What does this number mean?" | Read as money waiting, not spent, not a "balance" |
| B12 | The missed-log line A and B (R13) | "What would you do? How does it feel?" | No pressure or watching felt; a "no" feels free |
| B13 | `Already spent some this month?` (the install line) | "What is this asking?" | Read as an offer, not a charge. Hinglish speakers read "Fix my number" the same way (study 34 open question) |

## 10. Checks

- **Banned words** ("transaction", "debit", "credit", "budget period", "Oops", "balance", "worth", "reconcile", "true-up"): none in any proposed string. They appear in this deck only in the check lists.
- **"Saved"** appears only in `spendsPartSaved` (money put into a saving) and the existing `entrySaved`. No string says "saved" for an underspend, a pot, a *Used* entry or a fix.
- **Blame:** none. "hisaab thought" puts the guess on the app. The missed-log line has no "forgot", "missed" or "didn't". No "over today" is ever tied to a fix. No exclamation marks.
- **Glossary:** "share", "payday", "set aside", "put in" used as defined. "Cycle" is never user-facing. *Not logged*, *Used from savings*, "set aside" and "Fix my number" are new terms (section 11).
- **ICU:** `select` for direction and period, `plural` for the zero cases (`perDay`, `left`); no concatenation across sentences. Placeholders stay at the start of a clause or after a short word, so a Hindi order can move them.
- **Reading level:** every string is words of one or two syllables, with "divided by 12", "set aside" and "nothing" the longest ideas. No idiom.
- **Reuse:** `tryAgain`, `undo`, `couldntSave`, `save`, `waitingOpensHint`, `safeToSpendToday` (by repeating its words), `savedSince`, `spentAndSaved` (until the parts replace it).

## 11. Doc edits needed (listed, not made)

| Doc | Edit |
|---|---|
| SPEC §2 glossary | **Fix my number**: the act of telling hisaab how much of this month's money is left; "number" = the Home figure. **Not logged**: the hidden category on the entry a fix adds. **Set aside**: money put into a saving and not yet used. **Used from savings** (key "Used some of it"): paid a cost from a saving; touches no number. Note: *Saved* still means only money put into a saving |
| UI_DESIGN §8 voice | Add: no idioms ("spot on"); direction is a word, never a sign or colour; the app, not the user, is the one that "thought" wrong; "about" only on a figure that really is approximate; a zero is stated, not softened ("Safe to spend today: ₹0"); a preview slot is two sentences, the anchor first |
| SPEC FR-HO-3, FR-HO-4, FR-SP-4a, FR-SE-1, BR-15 | Copy cites the keys above. FR-SP-4a: four parts as separate keys |
| DECISIONS | One row per R1 to R13 that the owner accepts |
| `04-ux-and-copy.md` (habits) | Already says the line has no `notToday`. Add the keys `missedLogTitle` and `missedLogBody` as final once approved |

## 12. Open questions

1. **"hisaab" at the start of a line.** `fixPreviewBase` opens with the lowercase brand. Keep it (the brand is lowercase) or write "Hisaab thought"? `design-brand` to rule.
2. **Guard threshold** (10% of income) and *Fix it* on for a large *higher*: owner questions from 02 §7 still stand. The copy works for any threshold.
3. **Full or compact amounts** on the sheet. This deck says full Indian grouping. Confirm with `design-ui`.
4. **Used on every saving** (RD too): the hint `savingUsedHint` says "the cost"; on an RD it reads oddly. Option: show the hint only on the three yearly chips.
5. **`E` zero or below (F7):** `fixPreviewMore` shows without line 1 and says "more" with no anchor. Acceptable for a rare case, or add "hisaab thought nothing was left"? The gap uses the unclamped `E`, so that line could contradict the amount.
6. **Hero ₹0 snackbar** reads "Safe to spend today: ₹0." Confirm the owner is happy with the plain statement (R5).
7. **Hindi.** Deferred, but "Fix my number", "set aside" and "Not logged" need a Hinglish read (B1, B11, B13) before any translation.
8. **Install line in over states** waits (IA open question 4), so this copy never appears there.
