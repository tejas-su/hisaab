# 26 · Income copy deck (proposal, scratch)

Status: **proposal only**. Nothing here is in `app_en.arb`, SPEC, UI_DESIGN or DECISIONS yet. Final location may change.

**Who the words must fit** (PLFS 2025: ~24% regular salary, 56% self-employed, 20% casual): salaried, pensioners, weekly gig workers, shop owners, freelancers and tutors, daily-wage workers (they pick *It changes*), students (pocket money), homemakers (household money from family).

**Worked example:** today Mon 26 Oct 2026.
- Monthly: ₹45,000, paid on the 4th. 9 days left; the flag shows 4 Nov.
- Weekly: ₹10,000 a week.
- It changes: ₹30,000 in a low month. The cycle is the calendar month, so 6 days left (26–31 Oct); the flag shows 1 Nov.

**Length:** the smallest `TestWindows` size is `smallPhone` 320×568, which leaves about 280dp of content. Body text at 16sp in Mukta fits about 37 Latin characters a line. Line counts below are estimates and must be checked with a `smallPhone` widget test. Hindi needs 30–40% more room.

---

## 1. Principles behind the choices

1. **Name the money, not the job.** "Salary" leaves out three in four workers. "Money", "pay", "pension" and "family money" each name a *source*, so nobody has to say what work they do.
2. **Keep "payday" as the system word.** It is short, Hindi-first readers know it, and it fits weekly payouts, pension day and the day the family gives money. It is the glossary term the rail, range line and Ask AI already use. The fix is not a new word for payday: it is a **month-end variant** for cycles that have no payday.
3. **The variant follows the cycle, not the pay rule.** A salaried user who sets *My month starts on: 1st* (BR-1, last row) also has a cycle that ends at month end. Today they see "9 days to payday" on a cycle that ends 31 Oct, which is wrong. So pick the variant like this: `cycle.end == last day of its month && cycle has no payday inside the next day` → month-end copy. In practice: *It changes* or month start = *1st* → month-end; everything else → payday.
4. **Privacy is a fact, not a promise.** "It stays on this phone" is literally true (there is no network permission). It goes where the amount is asked, because that is the moment that feels intrusive.
5. **Safety beats accuracy.** For irregular money, a low month is the safe number. Say so *before* the amount is typed.

---

## 2. Tier 1: copy only, flow unchanged

Step 1 amount → Step 2 five chips → Step 3 bills.

### Step 1: amount

| Key | Current | Proposed | Lines @280dp | Why |
|---|---|---|---|---|
| `incomeQuestion` | How much money comes in each month? | *(keep)* How much money comes in each month? | 2 (title) | It already names money, not salary. "Comes in" fits pocket money and pension. |
| `incomeHint` | Your salary after tax. You can change it any time. | **Pay, business, pension or family money. If it changes, a low month is a safe guess.** | 3 | Four sources that cover every group without a list. The *It changes* advice has to be here because the amount comes before the chip (see the note below). "Safe guess" takes in "a rough guess is fine". |
| `incomePrivacy` *(new)* | (none) | **It stays on this phone. The app never uses the internet.** | 2 | This is a separate caption, not the end of the hint, so it doesn't get lost at the end of a paragraph. Both sentences are literally true. Placement (for example under the keypad, with a lock icon) is design-ui's call. |
| `dailyPreview` | That's about {amount} a day | *(keep)* That's about ₹1,500 a day | 1 | It works for everyone (÷30). |
| `dailyPreviewCaption` | One block for every day of the month | **Every day gets its own share** | 1 | "Block" goes stale once the preview moves to the bar and rail (D114 says that's a later step). It also says the idea, not the drawing. |

**Where the "low month" note lives (Tier 1).** It goes on step 1, in the hint. Putting it under the *It changes* chip on step 2 is too late: the amount is already typed. Making it useful there would need a "Change amount" link or a back step, and that adds a tap. The cost: salaried users read one line that isn't for them. "If it changes" tells them at once that it isn't, so the cost is low.

Rejected for `incomeHint`:
- *Starting proposal* "Salary, business, pension or money from family. A rough guess is fine. It stays on this phone." "Salary" in first place still reads as the default person. Daily wages and payouts aren't covered. The privacy line is lost at the end of the paragraph. It also has no low-month advice.
- *"Your income after tax."* (close to the current hint) "Income" is a tax-form word, and "after tax" is for salaried people only.
- *"Salary, wages, payouts, pension, business, pocket money or family money."* Every new item makes the missing ones stand out more. It is 4 lines on `smallPhone`.

Rejected for `incomeQuestion`:
- *"What's your monthly income?"* Formal and tax-like. "Monthly" puts off weekly earners.
- *"How much do you earn?"* Students and homemakers don't "earn" this money, and it sounds like a judgement.
- *"What's your salary?"* Leaves out about 76% of workers.

### Step 2: when it comes

| Key | Current | Proposed | Lines | Why |
|---|---|---|---|---|
| `paydayQuestion` | When does it come? | *(keep)* | 1 | Neutral already. |
| `paydayHint` | Your month runs from one payday to the next. | **Your month runs from one payday to the next. No fixed day? Pick It changes.** | 3 | It keeps the idea and gives people with no payday a way out, so daily-wage workers and shop owners know which chip is theirs. |
| `payFirstOfMonth`, `payLastDay`, `payPickDate`, `payEveryWeek`, `payItChanges` | 1st of the month / Last day / Pick a date / Every week / It changes | *(keep all)* | 1 each | None of them assume salary. |
| `payItChangesNote` *(new, optional)* | (none) | **Your month runs from the 1st to the last day** | 2 (small) | Optional sublabel under the *It changes* chip. It tells the user what picking it does (BR-1) before they tap. Skip it if chips can't take a second line. |
| `pickPaydayQuestion` | Which day of the month? | *(keep)* | 1 | |
| `pickWeekdayQuestion` | Which day of the week? | *(keep)* | 1 | |

### Settings

| Key | Current | Proposed | Why |
|---|---|---|---|
| `settingsIncome` *(new; the row has no ARB key today, SPEC FR-SE-1)* | Salary and payday | **Money coming in** | Starts with "Money". It pairs with *Fixed bills* (money going out). Nobody is called salaried. |
| `settingsIncomeValue` *(new, optional)* | (none) | `{rule, select, month{{amount} a month · day {day}} week{{amount} a week · {weekday}} other{About {amount} a month · it changes}}`, giving "₹45,000 a month · day 4", "₹10,000 a week · Friday" and "About ₹30,000 a month · it changes" | The subtitle shows what "payday" used to say in the row's title. "Day {day}" copies `billEveryMonth`, because intl has no ordinals. |

### Got category

| Key | Current | Proposed | Why |
|---|---|---|---|
| `categoryName` → `salary` | Salary | **Money in** | It fits salary, wages, payouts, pension, pocket money and household money equally. The stored key stays `salary`, so no migration is needed. People can still rename it to "Salary" (FR-SE-2). |
| `categoryName` → `other_income` *(optional)* | Other income | **Extra money** | Pairs with "Money in" on the *Got* grid: the regular money, then gifts, refunds and cashback. It drops "income". |

Pick among the three:
- **Pay.** Rejected. Pocket money, pension and household money aren't "pay", and a homemaker can read "you don't get paid" into it. It is the fallback if "Money in" tests badly, because it is the shortest.
- **Earnings.** Rejected. It leaves out students, homemakers and pensioners, and it sounds like a tax form.
- **Money in.** Chosen. Known risk: on the *Got* grid, "Got → Money in" says the same thing twice. That is acceptable, because in Spends lists and the Ask AI prompt the tile is read without "Got" beside it, and there it is clear.

### Month-end variants (Tier 1 and Tier 2)

Example: a month-end cycle with 6 days left, ending Sat 31 Oct; the flag shows 1 Nov. I recommend **separate keys** rather than a nested `select` inside a `plural`. That follows the pattern the ARB already uses, gives translators whole sentences and avoids nested ICU in gen-l10n.

| Key | Current (payday) | Proposed month-end key and text | Example | Why |
|---|---|---|---|---|
| `daysToPayday` → **`daysLeftInMonth`** | `{count} days to payday` / `1 day to payday` | `{count, plural, =1{Last day of the month} other{{count} days left this month}}` | 6 days left this month | `D` counts today (BR-2), and "left this month" counts today too. "6 days to month end" reads as 5 and is wrong. |
| `lastsTillPayday` → **`lastsTillMonthEnd`** | Lasts till payday | **Lasts till month end** | Lasts till month end · about ₹9,300 spare | Same shape, so the `·` join with `aboutSpare` still works. It is 41 characters against 38 today, so check it fits one line on `smallPhone`. |
| `stillLasts` → **`stillLastsMonthEnd`** | still lasts till payday | **still lasts till month end** | Over today · still lasts till month end | Same shape as the payday string. |
| `paydayIn` → **`newMonthIn`** | payday in {count} days / payday tomorrow | `{count, plural, =1{new month tomorrow} other{new month in {count} days}}` | Over by ₹2,000 · new month in 6 days | A fact and when it ends, with no blame. `D = 1` on the 31st, so "tomorrow" is correct. |
| `overCycleCard` → **`overCycleCardMonthEnd`** | It happens. This month's money is used up. It starts again on payday, {date}. | **It happens. This month's money is used up. It starts again on {date}.** | …It starts again on 1 Nov. | Drops "payday"; the date does the work. |
| `overCycleCard` → **`overCycleCardWeek`** *(fix, found in passing)* | (same as above) | **It happens. This week's money is used up. It starts again on payday, {date}.** | …on payday, 30 Oct. | Weekly users are told "this month's money" today, which is wrong for them. |
| `askGoalOnTrack` → **`askGoalLastsMonth`** | Will my money last till payday? | **Will my money last the month?** | (none) | Only needed if D72 changes and the goal is shown to month-end users (see open questions). |
| `noIncomeTitle` / `noIncomeBody` | Add money you got this month / Your daily share starts once there's money to share. | *(keep)* | (none) | Neutral already and fits every group. E10 only happens to month-end users anyway. |
| `aboutSpare` description | "money left at payday" | Description only: "money left at the end of the cycle (payday or month end)" | (none) | Tells translators that both variants use this string. |

TalkBack: `heroSpoken` takes these through `{days}` and `{line}` unchanged, for example "Safe to spend today: one thousand five hundred rupees. 6 days left this month. Lasts till month end, about nine thousand three hundred rupees spare." The rail flag's spoken label (if it has one) should say "New month, 1 November" rather than "Payday".

---

## 3. Tier 2: step order swapped, three chips

Step 1 when → Step 2 amount (wording depends on the answer) → Step 3 bills. This removes D26 (weekly is asked directly), so it needs a DECISIONS row.

### Step 1: when it comes

| Key | Current | Proposed | Lines | Why |
|---|---|---|---|---|
| `paydayQuestion` | When does it come? | **When does your money come in?** | 2 (title) | It is the first screen now, so "it" has nothing to point to. "When" sets up chips that answer *when*. |
| `payEveryMonth` *(new)* | (none) | **Every month** | 1 | Starts with the key word. Matches *Every week* and *It changes* in shape. The exact date comes next. |
| `payEveryMonthSub` *(new)* | (none) | **Salary, pension or family money** | 1 | The sublabels are where people see themselves. **Worth it.** |
| `payEveryWeek` | Every week | *(keep)* | 1 | |
| `payEveryWeekSub` *(new)* | (none) | **Weekly payouts or wages** | 1 | Covers gig workers (Swiggy, Uber) and weekly wages. |
| `payItChanges` | It changes | *(keep)* | 1 | Kept because the brief says daily-wage workers already use it. |
| `payItChangesSub` *(new)* | (none) | **Shop, tuition or daily work** | 1 | Covers shop owners, tutors, freelancers and daily wages. |
| `paydayHint` | Your month runs from one payday to the next. | **(none on this screen)** | (none) | The sublabels do this job, so a hint would only add words. |
| `pickPaydayQuestion` | Which day of the month? | **Which date does it come?** | 1–2 | "Date" is how Indian English says it ("salary comes on the 1st date"). |
| `payFirstOfMonth` → short | 1st of the month | **1st** | 1 | A shortcut chip above the 1–31 grid. Short because the title already says "date". |
| `payLastDay` | Last day | *(keep)* | 1 | Shortcut chip. |
| `pickWeekdayQuestion` | Which day of the week? | *(keep)* | 1 | |

TalkBack reads each chip and its sublabel as one label: "Every month. Salary, pension or family money."

Rejected for the step-1 question:
- *"How does your money come in?"* (the brief's draft). A Hindi-first reader may take "how" to mean cash or UPI, not how often.
- *"How often are you paid?"* "Paid" means an employer. It leaves out family money and sounds like a form.
- *"When is your payday?"* Salaried wording, and *It changes* would answer "never".

Rejected for chip 1: *"Same date every month"*. It is longer, breaks the shape the three chips share, and the date is picked on the next screen anyway.

### Step 2: amount, by answer

| Key | Every month | Every week | It changes |
|---|---|---|---|
| Question: `incomeQuestion` / **`incomeQuestionWeek`** / **`incomeQuestionLow`** | How much comes in each month? | **How much comes in each week?** | **How much comes in a low month?** |
| Hint: **`incomeHintMonth`** / **`incomeHintWeek`** / **`incomeHintLow`** | **Count what reaches you. A guess is fine.** | **Count what reaches you. A guess is fine.** | **Think of a slow month, not a good one. That keeps each day safe.** |
| Privacy: `incomePrivacy` (shared) | It stays on this phone. The app never uses the internet. | (same) | (same) |
| Preview: `dailyPreview` (shared) | That's about ₹1,500 a day (÷30) | That's about ₹1,428 a day (÷7) | That's about ₹1,000 a day (÷30) |
| Caption: `dailyPreviewCaption` (shared) | Every day gets its own share | (same) | (same) |

Why:
- **"Count what reaches you"** covers take-home pay after tax, payouts after commission and pension after deductions, in four short words.
- **"A low month"**: "low" is a word most people know. The original "About how much in a low month?" starts with a filler word, so I rejected it.
- **"Slow month, not a good one"** puts the safe choice in plain words. A shop owner who types a good month would overspend.
- **One hint per variant**: the step-1 answer already says who the person is, so the long list of sources from Tier 1 isn't needed.

Month-end variants: the same as the Tier 1 table.

---

## 4. Checks

- **Banned words:** none of "transaction", "debit", "credit", "budget period" or "Oops" appears in any proposed string. "Income" is no longer user-facing (it stays only in key names and descriptions).
- **Glossary (SPEC §2):** *Got*, *payday*, *share* and *Fixed bills* are reused unchanged. **New term:** *month end*, for the end of a month-end cycle. Add it to the glossary if this is adopted.
- **Voice:** no exclamation marks. The over-states state facts and when things end, with no blame. Every question has a hint, a default or a sublabel.
- **Money:** every amount is a `MoneyFormatter` placeholder. No paise.
- **Plurals:** `daysLeftInMonth` and `newMonthIn` use ICU `plural`, and `settingsIncomeValue` uses `select`. No string concatenation.
- **Reading level:** the longest sentence has 11 words. Only short, common words are used. The hardest word is "pension", which is a loanword Hindi speakers know.

---

## 5. Open questions for the owner

1. **Which tier?** Tier 2 asks the weekly amount directly (this removes D26's ×12÷52 rounding) and gives irregular users the low-month advice at the right moment. It is a flow change (FR-ON-2/3) and needs a DECISIONS row. Tier 1 is copy only.
2. **D27 and "low month".** For *It changes*, the step-2 answer becomes a real *Got* entry dated the 1st. If the user then logs real money as it comes in, it adds on top of the guess and the share is inflated. Should the low-month entry be labelled (for example a note "Starting guess"), or should the advice say "Add more as it comes" instead?
3. **Month start = 1st.** Salaried users with this setting see "days to payday" on a cycle that ends at month end, which is a bug today. Do we key the month-end variants on the cycle (my recommendation) rather than the pay rule?
4. **Ask AI goal (D72).** Show "Will my money last the month?" to month-end users instead of hiding the goal?
5. **"Extra money"** for `other_income`: rename it with "Money in", or leave it alone?
6. **Weekly preview rounding.** "about ₹1,428 a day" looks exact next to "about". Floor to ₹10 ("about ₹1,420") for the preview only? This is a SPEC FR-ON-2 call.
7. **Weekly users and "month" in Settings.** *Keep aside each month* and *My month starts on* mean little on a weekly cycle. Leave them for now, or hide the second one for weekly users?
