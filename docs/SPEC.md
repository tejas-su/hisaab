# hisaab• Product Specification (v1)

**Status:** draft, 2026-10-26.

**Companion documents:**
- [PLAN.md](PLAN.md) (scope, milestones, architecture)
- [UI_DESIGN.md](UI_DESIGN.md) (visual and interaction spec)
- [DECISIONS.md](DECISIONS.md) (why things are the way they are)

This document is the source of truth for **behaviour**. Where it disagrees with a mockup, this document wins and the mockup is a bug.

**Requirement IDs:**

| Prefix | Meaning |
|---|---|
| `BR-` | Business rule (exact computation) |
| `FR-<area>-` | Functional requirement |
| `NFR-` | Non-functional requirement |

Tests should cite the ID they cover.

---

## 1. Scope

### 1.1 In v1
- Android (API 24+), on phones, foldables, tablets and in multi-window, in any orientation (UI_DESIGN §13). One user per device. Works fully offline.
- One currency (INR) and English text. The code is ready for other locales and currencies (PLAN §5).
- Recurring income and recurring bills.
- Manual expenses and manual income ("Got").
- Daily "safe to spend", Day Blocks, the range forecast, Spends insights, and the Ask AI export.
- Optional category limits, local backup/restore and CSV export.

### 1.2 Not in v1
- Accounts, wallets, transfers and splitting.
- Bank or UPI SMS reading.
- Sync, login, multiple devices and multiple currencies.
- Widgets and the Quick Settings tile (planned for M6+).
- Hindi (the ARB file is ready for it).
- Calling any AI service from the app. The app only prepares text; the user sends it.

### 1.3 Success criteria
- A first-time user finishes onboarding in under 60 s.
- A returning user logs an expense in under 5 s, using no more than 4 taps plus the digits.
- A user can say what they can spend today after looking at Home for 2 s.

---

## 2. Glossary

| Term | Meaning |
|---|---|
| **Entry** | One money movement: *Spent* (out) or *Got* (in). The UI never says "transaction" |
| **Recurring rule** | A template that posts an entry on a schedule (salary, rent, Netflix) |
| **Cycle** | The run of calendar days the user's money must last. It starts on payday by default |
| **Today's share** (`A`) | The amount the user can spend today without hurting later days. It is fixed for the day |
| **Safe to spend today** | Today's share minus what was spent today. This is the hero number |
| **Day Blocks** | One block per day left in the cycle. Today's block drains as you spend |
| **Range line** | A forecast sentence: does the money last until payday at the current pace? |
| **Keep aside** | Optional money set aside each cycle and never counted as spendable |

---

## 3. Business rules

All amounts are integer **paise** (`amountMinor`). The UI shows whole rupees. Display rounding is always **floor to the rupee**, except for forecasts (BR-7). All dates are **local calendar dates**; times of day are ignored.

### BR-1 Cycle boundaries
The inputs are the **pay rule** (set in onboarding) and the **month start** setting: *Payday* (default) or *1st of month*.

| Pay rule | Cycle start for date `t` | Cycle end |
|---|---|---|
| Monthly on day `d` (1–31) | The latest date `s ≤ t` whose day-of-month is `min(d, daysInMonth(s))` | The day before the next start |
| Last day of month | The last day of the previous month (or `t`, if `t` is the last day) | The day before the next start |
| Weekly on weekday `w` | The latest date `s ≤ t` that falls on `w` | `s + 6 days` |
| It changes (irregular) | The 1st of `t`'s month | The last day of `t`'s month |
| Any rule, with month start = *1st of month* | The 1st of `t`'s month | The last day of `t`'s month |

- **Clamping:** payday on the 31st gives 30 Sep, 31 Oct, 30 Nov, 28 Feb (29 in a leap year). The next cycle starts on the clamped date, and the day after is never skipped.
- **Example:** payday on the 4th, `t` = Mon 26 Oct 2026. The cycle is Sun 4 Oct to Tue 3 Nov 2026 (31 days).

### BR-2 Days left
`D = end − t + 1`. It counts today, so `D ≥ 1`, and on the last day of the cycle `D = 1`.

Example: 26 Oct → 3 Nov gives `D = 9`.

### BR-3 Spendable pool at the start of today (`P`)
```
P = I − K − B − S_prev
```

| Symbol | Meaning |
|---|---|
| `I` | All *Got* entries dated within the cycle, posted recurring income included |
| `K` | Keep-aside amount, 0 if off |
| `B` | Recurring *Spent* occurrences due in `(t, end]` (after today, within the cycle) and not yet posted |
| `S_prev` | All *Spent* entries dated within `[start, t − 1]` |

Bills due **today** are posted by the recurring engine (BR-9), so they count as spent today, not in `B`.

### BR-4 Today's share and safe to spend
```
A          = max(0, floor(P / D))      // fixed for the whole of day t
S_today    = Spent entries dated t
safeToday  = A − S_today               // hero shows max(0, safeToday)
overToday  = max(0, S_today − A)
tomorrow   = floor((P − S_today) / (D − 1))   // only when D > 1
```
- `A` does **not** change as the user spends during the day. Only `safeToday` changes. Saving an entry dated in the past changes `S_prev`, so `A` is recomputed.
- **Worked example:**
  - Inputs: `I = 45,000`, `K = 0`, `B = 1,200` (electricity due Thu 29 Oct), `S_prev = 27,150`.
  - Pool: `P = 16,650`.
  - Today's share: `A = 16,650 / 9 = 1,850`.
  - After spending ₹420 today: **safe to spend today = ₹1,430**.
  - If ₹2,450 more is spent today: over today by ₹1,020, and tomorrow's share is `floor(13,780 / 8) = ₹1,722`.

### BR-5 States
The states below are evaluated in order, and the first match wins.

| # | State | Condition | Hero | Today's block |
|---|---|---|---|---|
| 1 | **No income** | `I = 0` and no recurring income | Onboarding prompt | — |
| 2 | **Over for the cycle** | `P − S_today < 0` | `₹0`, plus "Over by ₹X this cycle" where `X = S_today − P` | All blocks empty and outlined |
| 3 | **Over today** | `S_today > A` | `₹0`, plus "₹X over today" | Hatched; future blocks shorter |
| 4 | **Slow down** | `safeToday < 0.25 × A`, **or** the forecast (BR-7) runs out before `end` | `safeToday` | Marigold outline with a sliver |
| 5 | **On track** | Otherwise | `safeToday` | Solid marigold, draining |

### BR-6 Day Blocks geometry
- **Number of blocks:** `D`.
- **Today's fill:** `clamp(safeToday / A, 0, 1)`. If `A = 0`, the fill is 0. Once `S_today > 0`, the fill is at most `0.9`, a 4dp band on the 40dp block, so any spend shows (D91).
  - **Worked example:** `A = 11,218`, `S_today = 700` gives `10,518 / 11,218 ≈ 0.94`, which shows as `0.9`. `S_today = 0` shows `1`.
- **Future blocks:** height ratio `clamp(tomorrow / A, 0.4, 1)` when `A > 0`. They shrink when today is overspent, and never grow above full height. The ghost outline of full height is drawn only when the ratio is below 1.
- **Widths:** blocks share the width equally. If that is under 6dp, render one block per day for the next 7 days plus a "+N" label. The payday flag is always last.

### BR-6a Week bars (*This week*)
- **Days:** Monday to Sunday. Monday (or the cycle start, if later) to today each get a bar; days still to come in the cycle get a stub; days before the cycle start or from payday on get nothing.
- **Each past day's share `A_d`** is that day *as it stood*, with the ledger as it is now: entries dated on or before `d`; bills posted after `d` still counted in `B`; income dated after `d` not yet in `I` (BR-3, BR-4; the same rebuild as BR-8's yesterday). A back-dated entry changes that day and the days after it.
- **Each bar** fills to the day's *Spent* total. A tick marks `A_d`; any spend above it is hatched, never red. Today's bar is marigold; past bars are `displayInk2`.
- **Scale:** zero at the bottom; the tallest spend or share in the week reaches the top (88dp).
- **Words:** the range slot reads "Spent ₹4,950 this week · Tue was ₹460 over its share" (the most-over day, then "and N more days"), "Today is ₹220 over its share" when today is the most over, or "· every day within its share". A day exactly at its share is within it.
- **Worked example:** today Thu 29 Oct. Spent Mon ₹1,240, Tue ₹2,310, Wed ₹980, Thu ₹420 so far. With Tue's `A_d = 1,850`, Tue's ₹460 above its tick is hatched and the sentence names it.

### BR-7 Range forecast (the range line)
- **Pace:** `pace = V_prev / E`.
  - `V_prev` is the *Spent* entries in `[start, t − 1]` that were **not** posted by a recurring rule.
  - `E = t − start` is the number of whole days elapsed before today.
- **Hidden** when `E < 3`, since there is too little history. In that case the line reads "Lasts till payday" when `A > 0`.
- **Spare at payday:** `spare = P − S_today − pace × (D − 1)`. It is rounded **to the nearest ₹100** and always prefixed with "about", because it is a forecast, not a promise.
- **Messages:**
  - `spare ≥ 0`: "Lasts till payday · about ₹{spare} spare".
  - `spare < 0`: "At this pace it runs out on {date}", where `date = t + floor((P − S_today) / pace) + 1` days.
- **Worked example:** `V_prev = 27,150 − 8,200 = 18,950`, `E = 22`, `pace ≈ 861.4`. Then `spare = 16,650 − 420 − 861.4 × 8 ≈ 9,339`, which displays as "about ₹9,300 spare".

### BR-8 Midnight and resume
- When the app resumes, and at local midnight while it is open, the app re-runs the recurring engine (BR-9) and then recomputes BR-1 to BR-7.
- If the date changed, `A` is recomputed. The "you saved ₹X yesterday" note appears if yesterday's `S_today < A`.
  - **Saved:** `X = A_yesterday − S_yesterday`, where `A_yesterday` is rebuilt from the ledger as it stood yesterday: *Got* entries dated up to yesterday, and bills posted today still counted in `B`.
  - **Each day more:** `Y = floor(X / D)`, with `D` counted from today. With nothing else changed, today's `A` is exactly `A_yesterday + X / D`, so the note credits only the underspend (DECISIONS D38).
  - The note reads "You saved ₹{X} yesterday, so every day got ₹{Y} more." When `Y < ₹1` it reads "You saved ₹{X} yesterday." It shows all day. It never shows on the cycle's first day, since yesterday belongs to the previous cycle. It also never shows when the first entry was saved today, since the app wasn't tracking yesterday (DECISIONS D38).
  - **Example:** in the worked example nothing was spent on Sun 25 Oct, when `A = 16,650 / 10 = ₹1,665`. So `X = ₹1,665` and `Y = floor(1,665 / 9) = ₹185`, which matches `1,850 − 1,665`.

### BR-9 Recurring engine
- Each rule has: `amountMinor`, kind (*Spent*/*Got*), category, frequency (weekly / every 2 weeks / monthly / yearly), anchor date, `next_due` and `active`.
- **On every app start and resume**, for each active rule, while `next_due ≤ t`:
  1. Insert the entry dated `next_due`.
  2. Advance `next_due` by one period, with monthly rules clamped as in BR-1.
- All inserts for one run happen in **one DB transaction**.
- **Idempotency:** the unique index `(recurring_id, date)` plus `ConflictAlgorithm.ignore` means a crash or double run never double-posts.
- **Catch-up:** after 6 weeks away, a weekly rule posts all 6 occurrences, each with its own date.
- **Editing a rule** changes future occurrences only; already-posted entries are not touched. **Deleting a rule** stops future posts and keeps past entries.
  - A bill **added** in Settings first goes out on its next due date on or after today; earlier dates this cycle are not back-posted (DECISIONS D33).
  - When a bill's **day changes**, its next date is the new day in the month of the old `next_due` (the first month not yet posted), or, if that day has passed, the next due date from today. No month is posted twice and nothing is back-posted (D34).
  - **Delete** stops the rule at once, with Undo (6 s) that resumes it (D35).
- **Due-soon nudge:** when an unposted *Spent* occurrence falls 1 to 5 days after today, Home shows "{Label} ₹{amount} goes out in {n} days" ("goes out tomorrow" when `n = 1`). Only the soonest one is shown; on a tie, the rule saved first wins. Occurrences due today are the engine's and never shown.

### BR-10 Entries
- The amount is 1 to 999,999,999 rupees (at most 9 digits) and is stored as paise.
- The date defaults to today. The user may pick yesterday, or a date in the current or previous cycle. Future dates are not allowed.
- A note is optional, at most 80 characters, with whitespace trimmed.
- **Delete** happens at once with an Undo snackbar (6 s; with TalkBack it stays until dismissed, D105). **Edit** reopens the tray prefilled.
- After any write, the ledger notifies listeners, and Home and Spends recompute.

### BR-11 Categories
- **Seed list (fixed order):**
  - Spent: Food, Travel, Shopping, Bills, Fun, Health, Home, Other.
  - Got: Salary, Other income.
- The user may **rename** a category or **change its icon**. Order and count are fixed in v1, so muscle memory survives.
- Every entry has exactly one category. Entries posted by recurring rules use the rule's category.

### BR-12 Category limits (optional)
- They are off by default. After the **first full cycle**, Spends offers "Use these limits?" with each limit set to that category's spend last cycle, **rounded up to the next ₹500**. One tap accepts all of them.
  - **Full cycle:** the previous cycle counts as full when the earliest entry in the ledger was *saved* (`created_at`, not its date) on or before that cycle's start (DECISIONS D39).
  - Only categories with spending last cycle get a limit. Exactly ₹500 stays ₹500, and ₹501 becomes ₹1,000.
  - The offer is not made once any category has a limit.
- **Display:** the bar fills to `spent / max(spent of any category)`. A limit tick sits at `limit / max`, and any spend past the tick is drawn hatched, never red.
  - Under its limit a row says "₹200 left" beside the name, and "₹0 left" at the limit exactly; past it, "₹840 past limit" replaces the share. The words show even when the limit is beyond the biggest bar and no tick is drawn (D110).

### BR-13 Percentages (Spends)
- The shares of the cycle total use the **largest-remainder method**, so the shown integers always sum to exactly 100.
- **Example:**

  | Category | Spent | Share |
  |---|---|---|
  | Food | ₹9,840 | 36% |
  | Bills | ₹8,200 | 30% |
  | Travel | ₹4,100 | 15% |
  | Shopping | ₹3,600 | 13% |
  | Fun | ₹1,830 | 6% |

### BR-14 Insights (Spends)
At most **3** are shown, chosen in priority order:
1. **A category up at least 20% and at least ₹1,000 against the previous cycle at the same day-of-cycle.** "{Cat} is ₹X more than in {previous cycle}.", where the previous cycle is named as the cycle switcher names it ("September", or "19 Oct – 25 Oct") (DECISIONS D78). Day-of-cycle `k` is compared with day `min(k, previous cycle length)` of the previous cycle; this matters for 28-, 30- and 31-day cycles.
2. **A single entry larger than 2× that category's median entry this cycle.** "Your biggest {cat} spend was ₹X on {date}."
3. **The cycle's steadiest category** (lowest week-to-week variance, with at least 4 entries). "{Cat} costs about the same every week."
4. **The limit offer** from BR-12, on the current cycle only. "Set limits from {previous cycle}'s spending? Each one is rounded up to the next ₹500."

- Each rule gives at most one insight. #1 picks the biggest rise and needs a fully tracked previous cycle (the first entry saved on or before its start). #2 picks the biggest standout. #2 and #3 leave out bills posted by a rule.
- #3 compares the spread of whole-week totals relative to their size (coefficient of variation), needs at least 2 whole weeks, and breaks ties by the bigger total (DECISIONS D50).
- Each insight carries one action: *See {Cat} entries* (#1–#3, filtered to the category) or *Use these limits* (#4). *Set a limit* waits for its own design (DECISIONS D51).

### BR-15 Ask AI prompt
- **Inputs:**
  - Goal: How did I do? / Where can I save? / What should my limits be? / Will my money last till payday? / Ask something else (the user's own question) (DECISIONS D71). *Will my money last till payday?* is offered only when the cycle shown holds today and income has a payday (not "It changes"); otherwise it is hidden, and a pick of it falls back to *How did I do?* (DECISIONS D72).
  - Period: this cycle (default) or the last 3 cycles. "This cycle" is the one Spends shows; the last 3 are it and the two before it (DECISIONS D60).
  - "Leave out my notes" switch (off by default).
- **Output:** plain UTF-8 text in this order:
  1. Role, three lines:
     ```
     You are a friendly money coach for someone in India. Reply in simple English, under 200 words.
     Use only the numbers below. Write amounts in ₹ with Indian grouping (₹1,25,000).
     If there is too little data to judge, say so. Don't name specific stocks, funds, loans or apps.
     ```
  2. Context (income, pay rule, currency, period dates).
  3. **Facts from the app**, only when the period holds today: "From my app, and correct: safe to spend today ₹1,430; at this pace it lasts till payday with about ₹9,300 spare; I keep aside ₹5,000 a month as savings." The numbers are Home's own (`GetCycleSummary`, BR-4 and BR-7), never recomputed (DECISIONS D79):
     - Safe to spend today is the hero's number: ₹0 when today or the cycle is over.
     - The forecast reads "at this pace it lasts till payday with about ₹X spare" or "at this pace it runs out on YYYY-MM-DD", and is left out while it is too early to forecast (`E < 3`). It stays for "It changes" income, as on Home.
     - The keep-aside clause is left out when keep-aside is ₹0. It reads "a week" for weekly pay, "a month" otherwise.
     - With no income at all (Home shows the No income card), the whole line is left out.
  4. Summary table by category (spent / limit).
  5. Recurring bills.
  6. Entries as CSV (`date,amount,kind,category,note`, oldest first; the note column is dropped when notes are hidden).
  7. The task text for the chosen goal (DECISIONS D79):
     - How did I do?: "Task: Tell me how this period went. Give: 1) 3 things that stand out, good or bad, with ₹ amounts 2) the one change that would save the most, and how much a month 3) one habit worth keeping."
     - Where can I save?: "Task: Show me where I can save. Give 5 specific cuts, easiest first, each with how much it saves a month, then the total. Don't cut rent, EMIs, other fixed bills or health."
     - What should my limits be?: "Task: Suggest a spending limit per category for one pay cycle. Together they must fit my income after fixed bills and what I keep aside. Show a table: category, limit in ₹, one short reason."
     - Will my money last till payday?: "Task: Will my money last till payday? Use the numbers from my app as correct; don't recalculate them. Tell me which 1–2 categories are pushing my pace up and one thing to change this week."
     - Ask something else: "My question: {question}", trimmed.
- **Determinism:** the same data always produces byte-identical text, so it can be checked with a golden-string test.
- **Size guard:** if the text is over 12,000 characters, the oldest entries are summarised by week first, and the preview says so. Weeks are 7-day blocks from the period start, folded oldest first, one at a time, until the text fits (DECISIONS D64).
- **"Copy & open ChatGPT":**
  1. Copy the text to the clipboard.
  2. Open `https://chatgpt.com/?q=<url-encoded>` when the encoded text is ≤ 2,000 characters. Otherwise open `https://chatgpt.com/`. In that case the screen already says, before the tap, "ChatGPT will open empty. Long-press the message box and tap Paste." as a caption above the actions, so no toast follows (the user has left the app). When nothing could open the link, the toast "Copied. In the chat, long-press and tap Paste." shows (DECISIONS D62, D74).
- **Other actions:** "Other apps" opens the Android share sheet with the text. "Copy only" copies it and shows the same toast.
- **Own question:** while it is blank, all three actions are disabled.

### BR-16 Backup, restore, export
- **Backup:** a single JSON file (`hisaab-backup-YYYY-MM-DD.json`) containing the schema version, settings, categories, rules and entries. It is saved through the system file picker.
- **Restore** replaces all data after a confirmation dialog, which is the **only** confirmation dialog in the app. The file is validated (version, required fields) before anything is deleted, and the restore runs in one transaction.
- **CSV export:** entries only, in the same columns as BR-15.

---

## 4. Functional requirements

Acceptance criteria are written as Given / When / Then. Copy in quotes is the English ARB value.

### 4.1 Onboarding (FR-ON)
- **FR-ON-1** A fresh install opens onboarding. A finished onboarding never shows again unless the user resets the app.
- **FR-ON-2** Step 1 asks "How much money comes in each month?" with the keypad open.
  - Given 45000 is typed, then the preview reads "That's about ₹1,500 a day". This is `floor(amount / 30)`, for the preview only.
  - Next is enabled only when the amount is greater than 0.
- **FR-ON-3** Step 2 asks "When does it come?" with five chips: *1st of the month*, *Last day*, *Pick a date* (day 1–31), *Every week* (weekday), *It changes*. Selecting a chip advances.
- **FR-ON-4** Step 3, "Any fixed bills?", offers chips (Rent, EMI, Phone, Internet, School fees, Subscriptions) that each open a mini keypad and a due day. **Skip** is always visible.
- **FR-ON-5** Finishing creates the income rule, any bill rules and the seed categories in one transaction. It then runs the recurring engine, lands on Home with the "blocks assemble" motion and fires the success haptic.
- **FR-ON-6** If the user leaves mid-onboarding, it resumes at the same step.

### 4.2 Home (FR-HO)
- **FR-HO-1** Shows the wordmark, today's date (`EEE, d MMM`, e.g. "Mon, 26 Oct") and a Settings button.
- **FR-HO-2** **Hero card:**
  - "Safe to spend today" with the hero amount (BR-4/BR-5).
  - Day Blocks (BR-6), with the "Today" and "{D} days to payday" captions and the payday flag date.
  - The range line (BR-7).
  - Tapping the hero toggles *Today* ↔ *This week*. *This week* shows `A × min(7, D) − (spent since the start of the week, Monday)`, and the toggle lasts for the session only.
    - The week's spending starts on Monday, or on the cycle start if that is later, and runs to today (DECISIONS D37).
    - The title reads "Safe to spend this week". The number never shows below ₹0; past it, the hero shows ₹0, muted, beside "₹X over this week".
    - The Day Blocks give way to the week bars (BR-6a) and their captions to the weekday letters; the payday flag stays. The card grows 48dp for the bars, only in *This week*. The range slot says the week in words (BR-6a). TalkBack reads each day by its full name with its amount, then the week sentence, and offers "Double tap to show this week" (or "show today") (D111).
- **FR-HO-3** **Due-soon nudge** (BR-9), when applicable.
- **FR-HO-4** **Today list:**
  - The header shows today's total and *See all*.
  - At most the 5 most recent entries for today.
  - Swipe left to delete, with Undo (BR-10). Tapping a row edits it.
  - Empty state: "Nothing spent today. Tap Add when you do."
- **FR-HO-5** **Over states** (BR-5 #2 and #3) show a calm card with one next step, *See where it went*, which opens Spends.
  - Over today: "It happens. The ₹220 is spread across the next 3 days, so each one is a little smaller." (with one day after today: "comes out of tomorrow"). On the last day `A = P`, so any overspend is over for the cycle.
  - Over for the cycle: "It happens. This month's money is used up. It starts again on payday, 4 Nov."
  - The step is hidden when Spends is already beside Home in two panes (DECISIONS D54).
- **FR-HO-6** The dock offers Home · **Add** · Spends. Add opens the tray (FR-AD).
- **FR-HO-7** The hero card is announced as one TalkBack node (UI_DESIGN §9).

### 4.3 Add tray (FR-AD)
- **FR-AD-1** Step 1, amount:
  - *Spent* / *Got* segmented control, with *Spent* selected by default.
  - Phone-layout keypad with `00`, `0` and ⌫. Long-pressing ⌫ clears the amount.
  - Quick chips +₹10 / +₹20 / +₹50 / +₹100 / +₹500 **add** to the amount.
- **FR-AD-2** Input rules:
  - Leading zeros are ignored.
  - A 10th digit is rejected with a head-shake and the reject haptic.
  - There is no decimal key.
  - The amount shows live Indian grouping.
- **FR-AD-3** A helper line previews the effect, for example "₹1,020 over today's share · tomorrow ₹1,722", using BR-4 with the typed amount.
- **FR-AD-4** **Next** is enabled when the amount is greater than 0 and opens step 2. The tray shortens, and the amount flies up into the title.
- **FR-AD-5** Step 2 shows a 2×4 grid of categories for *Spent*, or the *Got* categories, plus *Today ▾* and *Add a note* chips. **Tapping a tile saves**, then:
  1. The tile flashes (120 ms).
  2. The tray closes.
  3. Once the tray has fully closed, Home recomputes. Today's block drains and the hero number rolls to its new value, starting in the same frame. While the tray covers Home, Home holds its last numbers (D91).
  4. The success haptic fires.
- **FR-AD-6** Double-taps while saving are ignored. If the save fails, the tray stays open with "Couldn't save. Try again." and nothing is lost.
- **FR-AD-7** Back from step 2 returns to step 1 with the amount intact. Back from step 1 closes the tray without saving.
- **FR-AD-8** Edit mode opens step 1 prefilled. Saving replaces the entry, and *Delete* is shown in step 2.

### 4.4 Spends (FR-SP)
- **FR-SP-1** A cycle switcher `‹ October ›` shows the current and earlier cycles. Next is disabled on the current cycle.
  - A cycle is named after the month holding most of its days, with the year when it isn't this year; a weekly cycle by its dates (DECISIONS D52).
  - Earlier is enabled while the cycle before has entries, or the app was in use before it ended.
  - An empty cycle reads "Nothing spent in October yet." and hides the chart and the list.
- **FR-SP-2** The **Ask AI** card at the top opens FR-AI for the cycle shown. It shows only when that cycle has spends (DECISIONS D53, D61). It reads "Ask an AI about October", with "You'll see exactly what it gets." below in smaller grey text; TalkBack reads both as one button (DECISIONS D70).
- **FR-SP-3** **Pace chart:**
  - The cumulative *Spent* line (solid ink) against the steady-pace line from (start, 0) to (end, `I − K`) (dotted).
  - Fixed y-axis labels at ₹0 and at round thirds of `I`, in compact `en_IN` (₹20K).
  - A "Spending slower" or "Spending faster" verdict with a glyph (DECISIONS D77).
  - A today marker in marigold.
  - Labels sit every 1, 2 or 5 × 10ⁿ rupees from a third of `I − K` (₹45,000 gives ₹0 / ₹20K / ₹40K), up to the larger of `I − K` and the spending. Without income there is no steady line, so only the total shows (DECISIONS D49).
  - Verdict: *Spending slower* when spending so far is at or under the steady line on the same day.
- **FR-SP-4** **Where it went:** categories sorted by amount, showing icon, name, % (BR-13), ₹, and a bar with an optional limit tick (BR-12). When any bar is hatched, one line under the rows reads "Striped part is over the limit." (hidden from TalkBack, since each row says "past limit") (D110).
- **FR-SP-5** **Insights** (BR-14), with their actions.
- **FR-SP-6** *See every entry* opens a day-grouped list with category and cycle filter chips. Swipe to delete and tap to edit, as on Home.
  - The list shows the cycle picked in Spends (Home's *See all* opens the current one), with *All* plus a chip for each category that has entries. An insight's *See {Cat} entries* opens it on that category (DECISIONS D53).

### 4.5 Ask AI (FR-AI)
- **FR-AI-1** The goals (4, or 3 when *Will my money last till payday?* is hidden, BR-15) are a single column of list rows, each with an icon, followed by an own-question row: a 200-character text field that is always visible, with the placeholder "Ask something else". While it has focus and is empty, the placeholder reads "Like: can I afford a new phone this month?" (DECISIONS D73). Tapping or typing in it picks it. The pick shows an ink check at the row's end and a bold label, never a fill or marigold (DECISIONS D67).
- **FR-AI-2** The period segments and the *Leave out my notes* switch regenerate the preview immediately. The segments are named by their dates, as the cycle switcher names cycles: the shown cycle ("October"), and the three cycles oldest to newest ("Aug – Oct" for monthly cycles, short month names with no year; "12 Oct – 1 Nov" for weekly ones, the oldest start to the newest end) (DECISIONS D76).
- **FR-AI-3** The preview shows "What the AI will see · {n} entries", then the caption "Nothing leaves your phone until you share it.", then (when weeks were grouped) "Older weeks are shown as totals to keep it short.", the first 4 lines, and *Show full text*, which expands to the full scrollable text (DECISIONS D75).
- **FR-AI-4** The actions follow BR-15: *Copy & open ChatGPT*, *Other apps* and *Copy only*. When the prompt is too long to prefill ChatGPT, the paste caption sits directly above them. Nothing is sent anywhere by the app itself.

### 4.6 Settings (FR-SE)
- **FR-SE-1** Money settings:
  - Salary and payday (edits the income rule; future cycles only).
  - Fixed bills (list, add, edit, delete rules). The list shows each bill's name, day and amount, soonest first. Adding or editing asks three questions: the name (typed, or one of the onboarding chips, which fills it in; Next moves on, D86), the amount on the keypad, then the day of the month (1–31), where tapping a day saves. Bills are monthly. Rent goes in *Home*; every other bill goes in *Bills*. A name is 1–40 characters after trimming. Swipe or *Delete* removes a bill with Undo (BR-9).
  - Keep aside each month.
  - My month starts on: *Payday* / *1st*.
- **FR-SE-2** Categories: rename, change icon.
- **FR-SE-3** Look: Light / Dark / Match phone (default).
- **FR-SE-4** Data: Backup, Restore, Export CSV (BR-16), and *Reset app*. Reset asks the user to type "RESET", then wipes all data and returns to onboarding.
- **FR-SE-5** About: version, licences, and the privacy sentence "Everything stays on this phone."

---

## 5. Edge cases (each needs a test)

| # | Case | Expected |
|---|---|---|
| E1 | Payday on the 31st in Feb 2027 / Feb 2028 | Cycle starts 28 Feb 2027 / 29 Feb 2028 (BR-1) |
| E2 | Today is the last day of the cycle | `D = 1`; no `tomorrow`; the range line shows the payday message |
| E3 | Cycle crosses the year (payday on the 25th, 25 Dec → 24 Jan) | Correct `D`, and the chart spans both months |
| E4 | `P ≤ 0` at the start of the day | `A = 0`; state is Over for the cycle or Slow down; never a negative hero |
| E5 | A bill bigger than all remaining money | `B` makes `P` negative, so Over for the cycle, naming the bill in the card |
| E6 | Back-dated entry into the previous cycle | That cycle's Spends updates; today's `A` doesn't change unless the entry is in the current cycle |
| E7 | App closed for 6 weeks | Recurring engine catches up, each occurrence posted exactly once (BR-9) |
| E8 | Two app launches race the engine | The unique index prevents duplicates |
| E9 | Device date moved backwards | No crash; no un-posting; `next_due` is never moved back |
| E10 | Irregular income with no *Got* entry yet this month | `I = 0`, so Home asks "Add money you got this month" |
| E11 | 9-digit amount (₹99,99,99,999) | Accepted; formats `₹99,99,99,999`; compact `₹100Cr` on charts |
| E12 | Text scale 1.5× | Hero steps down to 56 / 44 with no clipping (UI_DESIGN §3.4) |
| E13 | Reduce motion on | All motion becomes 150 ms crossfades; values still update |
| E14 | Restore with a corrupt or older file | Validated first; an invalid file changes nothing; an older version is migrated |
| E15 | More than 31 days left (weekly cycles can't; monthly can't) | Not possible by BR-1; asserted in a test |
| E16 | Foldable opened into book posture while the app is running | Re-lays out into two panes split at the fold, with no data or state loss |
| E17 | Tabletop posture | Content above the fold, controls below it |
| E18 | App in a 412×400dp split-screen window | Compact layout; every control still reachable |

---

## 6. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 | Cold start to an interactive Home in ≤ 1.5 s on a 4 GB Android 10 device; Add tray opens in ≤ 150 ms; the drain begins ≤ 400 ms after the save (Doherty threshold: feedback starts, D91) |
| NFR-2 | Fully offline. No network permission is used, except opening ChatGPT through the browser (an intent, not app networking) |
| NFR-3 | No analytics, no crash reporting that leaves the device, no ads. Logs never contain notes |
| NFR-4 | Accessibility: WCAG AA contrast (verified in UI_DESIGN §3.2), touch targets of 48dp or more, full TalkBack coverage, 1.5× text, reduced motion |
| NFR-5 | Data safety: every multi-row write is in a transaction; migrations are tested from each previous schema version; backup/restore round-trips byte-equal data |
| NFR-6 | APK under 15 MB (fonts subset to Latin plus Devanagari) |
| NFR-7 | Changed-lines test coverage ≥ 90% (target 100%) per change (`.claude/rules/tests.md`) |
| NFR-8 | Adaptive layout: no orientation or size lock; works from 320dp phones to tablets, in every foldable posture and in multi-window (UI_DESIGN §13) |
| NFR-9 | The launch splash never delays Home: it is dismissed on Flutter's first frame. Its icon animation lasts 800 ms or less. Its background matches Home's in light and dark (UI_DESIGN §3.7) |
| NFR-10 | The recent-apps preview never shows amounts on Android 13+ (`setRecentsScreenshotEnabled(false)`); screenshots keep working. Android 7–12 are unchanged, since `FLAG_SECURE` would block screenshots (D109) |

---

## 7. Open questions

| # | Question | Default until answered |
|---|---|---|
| Q1 | Should "Got" entries outside the salary (gifts, refunds) count towards `I`? | Yes. All *Got* entries in the cycle count |
| Q2 | Weekly view (FR-HO-2): Monday or locale week start? | Monday (`MaterialLocalizations.firstDayOfWeekIndex` once more locales ship) |
| Q3 | Play Store title descriptor | "hisaab• – Daily Spend Tracker", pending a trademark search |
| Q4 | Should the cycle-summary share card be in v1 (UI_DESIGN §6) or v1.1? | v1.1 |
| Q5 | Should long-pressing a day block show that day's share, or long-pressing Next offer "make this repeat"? | Neither in v1. Hidden gestures fail the 5-year-old test; recurring bills are added in Settings (FR-SE-1) |
| Q6 | Installing mid-cycle: the whole salary counts but spending before install is unknown, so the first days' share is too high. Ask "How much is left right now?" in onboarding? | No extra question; the share corrects itself at the next payday |
