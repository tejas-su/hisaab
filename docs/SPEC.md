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
- Daily "safe to spend", today's bar and the days rail, the range forecast, Spends insights, and the Ask AI export.
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
| **Today's bar** | Today's share as one bar: the yellow is what's left, and each thing bought today is a bite out of it (BR-6) |
| **Days rail** | One dot per day left in the cycle, today's first, ending at the payday flag (BR-6) |
| **Range line** | A forecast sentence: does the money last until payday at the current pace? |
| **Month end** | The end of a cycle that follows the calendar month (*It changes*, or month start on the 1st). It has no payday, so the rail, range line and over card name the month end instead (DECISIONS D116) |
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
P = I − K − B − S_prev − R_t
```

| Symbol | Meaning |
|---|---|
| `I` | All *Got* entries dated within the cycle, posted recurring income included |
| `K` | Set aside for savings, computed: `R + Sv_before + Sv_rule_today` (D120) |
| `R` | Saving occurrences due in `(t, end]` and not yet posted |
| `Sv_before` | *Saved* entries dated within `[start, t − 1]`, by a rule or put in extra |
| `Sv_rule_today` | *Saved* entries dated `t` that a saving rule posted |
| `Sv_extra_today` | *Saved* entries dated `t` with no rule (*Put in extra*); they leave `A` fixed and thin the later days (BR-4) |
| `B` | Recurring *Spent* occurrences due in `(t, end]` (after today, within the cycle) and not yet posted, plus a changing bill's occurrences in `[start, t]` still *waiting* (BR-9), each at its estimate. A card bill is never in `B` (D123) |
| `S_prev` | All *Spent* entries dated within `[start, t − 1]`, bills included |
| `R_t` | *Spent* entries dated `t` that a recurring rule posted (bills due today) |

A bill posted on its own day comes out of the pool (`R_t`), not out of today's share: until today it sat in `B`, so the share was already sized for it (DECISIONS D119). Example: rent ₹15,000 posts today, nothing spent yet, `B = 0`, `S_prev = 27,150`: `P = 45,000 − 15,000 − 27,150 = 2,850` and `A = floor(2,850 / 9) = ₹316`. The hero shows ₹316, not ₹0 and "over today".

A changing bill (electricity) waits on its day for the user to say how much; until then its estimate (the last amount entered) stays in `B`. Entering it moves it to `R_t`, so the share follows the real amount (BR-4). A card bill is recorded but never counted, because the card buys were counted when made: paying it changes no number (D123).

**One rule for everything a rule posts:** it is set aside before its day (`B` for bills, `R` for savings) and comes out of the pool on its day, never out of today's share. Worked example 3 (D120): a ₹5,000 RD went in on the 10th, so `K = 5,000`, `P = 45,000 − 5,000 − 1,200 − 27,150 = 11,650` and `A = floor(11,650 / 9) = ₹1,294`; with ₹420 spent the hero shows ₹874. On the RD's own day `P` doesn't move: yesterday's `R` becomes today's `Sv_rule_today`.

### BR-4 Today's share and safe to spend
```
A          = max(0, floor(P / D))      // fixed for the whole of day t
S_today    = Spent entries dated t that no recurring rule posted
safeToday  = A − S_today               // hero shows max(0, safeToday)
overToday  = max(0, S_today − A)
remaining  = P − S_today − Sv_extra_today
tomorrow   = floor(remaining / (D − 1))   // only when D > 1
```
- A *Put in extra* leaves today's `A` fixed and thins the later days: ₹500 put in with ₹420 spent gives `remaining = 10,730` and `tomorrow = floor(10,730 / 8) = ₹1,341` against ₹1,403 without it, so "Each day till payday gets ₹62 less" (D120).
- `A` does **not** change as the user spends during the day. Only `safeToday` changes. Saving an entry dated in the past changes `S_prev`, and entering or changing a bill dated today changes `R_t`; either way `A` is recomputed.
- **A changing bill entered today** (D123): electricity, estimate ₹1,200, due today and waiting, so `B = 1,200`, `P = 16,650`, `A = 1,850` and the hero shows ₹1,430. The user enters ₹1,460: `B = 0`, `R_t = 1,460`, `P = 16,390`, `A = floor(16,390 / 9) = 1,821`, and the hero shows ₹1,401. A card bill of ₹8,000 paid today changes nothing.
- **Worked example:**
  - Inputs: `I = 45,000`, `K = 0`, `B = 1,200` (electricity due Thu 29 Oct), `S_prev = 27,150`.
  - Pool: `P = 16,650`.
  - Today's share: `A = 16,650 / 9 = 1,850`.
  - After spending ₹420 today: **safe to spend today = ₹1,430**.
  - If ₹2,450 more is spent today: over today by ₹1,020, and tomorrow's share is `floor(13,780 / 8) = ₹1,722`.

### BR-5 States
The states below are evaluated in order, and the first match wins.

| # | State | Condition | Hero | Today's bar and dot (BR-6) |
|---|---|---|---|---|
| 1 | **No income** | `I = 0` and no recurring income | Onboarding prompt | — |
| 2 | **Over for the cycle** | `remaining < 0` | `₹0`, plus "Over by ₹X this cycle" where `X = −remaining` | Bar hatched past the share tick; every rail dot outlined |
| 3 | **Over today** | `S_today > A` | `₹0`, plus "₹X over today" | Bar hatched past the share tick; today's dot hatched |
| 4 | **Slow down** | `safeToday < 0.25 × A`, **or** the forecast (BR-7) runs out before `end` | `safeToday` | The yellow drawn as a marigold outline; today's dot a marigold ring |
| 5 | **On track** | Otherwise | `safeToday` | Solid marigold, draining |

### BR-6 Today's bar and the days rail
Replaces the Day Blocks (D114; [mockup 25](design/mockups/25-today-bar-and-rail.html)).
- **Today's bar:** one bar, the hero's full inner width, 48dp tall.
  - **Span:** `max(A, S_today)`. While `S_today ≤ A` the bar is today's share.
  - **The yellow** (marigold) runs from the start edge: `clamp(A − S_today, 0, A) / span`. It is the hero amount.
  - **Bites:** each *Spent* entry dated today is a `blockIdle` piece of `amount / span`, the first saved at the end edge and each later one next to the yellow, 3dp apart. A bite narrower than 4dp merges with its neighbours. A bite wide enough for its category name has the name under it.
  - **Over today** (`S_today > A`): no yellow. A 2dp `displayInk` tick marks `A / span`, and everything past it is hatched in `displayInk2`.
  - **States (BR-5):** slow down draws the yellow as a marigold outline; over today and over for the cycle draw the hatch. With `A = 0` and nothing spent, the bar is empty.
  - **Worked example:** `A = 1,850`, chai ₹40 then lunch ₹380. The yellow is `1,430 / 1,850 ≈ 77%`; lunch (20.5%) sits next to it and chai (2.2%, about 6dp) at the end. After ₹1,080 groceries and ₹800 cab, `S_today = 2,300`: the span is ₹2,300, the tick sits at `1,850 / 2,300 ≈ 80%`, and the last 20% is hatched.
- **Captions:** "₹420 spent" at the start and "of ₹1,850 for today" at the end, under the bar.
- **Days rail:** one dot per day left (`D`), today first at 10dp, the others 6dp `blockIdle` (smaller, down to 2dp, when they would be closer than 2dp apart), then the payday flag with its date. Today's dot: marigold (on track), a marigold ring (slow down), hatched (over today, over for the cycle). Over for the cycle also outlines every later dot. Captions: "Today" and "{D} days to payday" (on the last day, "1 day to payday"). A month-end cycle reads "{D} days left this month" ("Last day of the month" when `D = 1`) and its flag shows the 1st of the next month (D116).
- **Same height in both modes:** the bar with its names and captions, and the week bars with their letters (BR-6a), are laid out in one cell; the card takes the taller, so tapping between *Today* and *This week* never resizes it. The days rail sits under that cell in both modes.

### BR-6a Week bars (*This week*)
- **Days:** Monday to Sunday. Monday (or the cycle start, if later) to today each get a bar; days still to come in the cycle get a stub; days before the cycle start or from payday on get nothing.
- **Each past day's share `A_d`** is that day *as it stood*, with the ledger as it is now: entries dated on or before `d`; bills posted after `d` still counted in `B`; income dated after `d` not yet in `I` (BR-3, BR-4; the same rebuild as BR-8's yesterday). A back-dated entry changes that day and the days after it.
- **Each bar** fills to the day's typed *Spent* total; a bill posted that day is in its pool (`R_t`), not its bar (D119). A tick marks `A_d`; any spend above it is hatched, never red. Today's bar is marigold; past bars are `displayInk2`.
- **Scale:** zero at the bottom; the tallest spend or share in the week reaches the top (64dp, the card's full inner width; D114).
- **Words:** the range slot reads "Spent ₹4,950 this week · Tue was ₹460 over its share" (the most-over day, then "and N more days"), "Today is ₹220 over its share" when today is the most over, or "· every day within its share". A day exactly at its share is within it.
- **Worked example:** today Thu 29 Oct. Spent Mon ₹1,240, Tue ₹2,310, Wed ₹980, Thu ₹420 so far. With Tue's `A_d = 1,850`, Tue's ₹460 above its tick is hatched and the sentence names it.

### BR-7 Range forecast (the range line)
- **Pace:** `pace = V_prev / E`.
  - `V_prev` is the *Spent* entries in `[start, t − 1]` that were **not** posted by a recurring rule.
  - `E = t − start` is the number of whole days elapsed before today.
- **Hidden** when `E < 3`, since there is too little history. In that case the line reads "Lasts till payday" when `A > 0`.
- **Spare at payday:** `spare = remaining − pace × (D − 1)`; the pace counts *Spent* only. It is rounded **to the nearest ₹100** and always prefixed with "about", because it is a forecast, not a promise.
- **Messages:**
  - `spare ≥ 0`: "Lasts till payday · about ₹{spare} spare".
  - A month-end cycle says "month end" for "payday" throughout: "Lasts till month end", "still lasts till month end", and "new month in {D} days" for over the cycle (D116).
  - `spare < 0`: "At this pace it runs out on {date}", where `date = t + floor((P − S_today) / pace) + 1` days.
- **Worked example:** `V_prev = 27,150 − 8,200 = 18,950`, `E = 22`, `pace ≈ 861.4`. Then `spare = 16,650 − 420 − 861.4 × 8 ≈ 9,339`, which displays as "about ₹9,300 spare".

### BR-8 Midnight and resume
- When the app resumes, and at local midnight while it is open, the app re-runs the recurring engine (BR-9) and then recomputes BR-1 to BR-7.
- If the date changed, `A` is recomputed. The "you saved ₹X yesterday" note appears if yesterday's `S_today < A`.
  - **Saved:** `X = A_yesterday − S_yesterday`, where `A_yesterday` is rebuilt from the ledger as it stood yesterday: *Got* entries dated up to yesterday, and bills posted today still counted in `B`.
  - **Each day more:** `Y = floor(X / D)`, with `D` counted from today. With nothing else changed, today's `A` is exactly `A_yesterday + X / D`, so the note credits only the underspend (DECISIONS D38).
  - The note reads "Yesterday was ₹{X} under its share, so every day got ₹{Y} more." When `Y < ₹1` it reads "Yesterday was ₹{X} under its share." It never says "saved", which means only money put into a saving (D121). It shows all day. It never shows on the cycle's first day, since yesterday belongs to the previous cycle. It also never shows when the first entry was saved today, since the app wasn't tracking yesterday (DECISIONS D38).
  - **Example:** in the worked example nothing was spent on Sun 25 Oct, when `A = 16,650 / 10 = ₹1,665`. So `X = ₹1,665` and `Y = floor(1,665 / 9) = ₹185`, which matches `1,850 − 1,665`.

### BR-9 Recurring engine
- Each rule has: `amountMinor`, kind (*Spent*/*Got*/*Saved*; a *Saved* rule's entry carries the rule's name as its note, D120), category, frequency (weekly / every 2 weeks / monthly / yearly), anchor date, `next_due` and `active`.
- **On every app start and resume**, for each active rule, while `next_due ≤ t`:
  1. Insert the entry dated `next_due`.
  2. Advance `next_due` by one period, with monthly rules clamped as in BR-1.
- All inserts for one run happen in **one DB transaction**.
- **Amount changes? (D123).** A bill is *Same every month* (fixed, posted as above), *Changes every month* or a *Credit card*. Savings and income are always fixed.
  - The engine **never posts** a changing or card bill and never moves its `next_due`, which stays the first date it may wait from (D33).
  - An occurrence **waits** when it falls in this cycle on or before today, not before `next_due`, and its month has neither an entry nor a skip of that bill. A month is answered once, so moving the bill's day or an entry's date never asks (or reserves) the same month twice. Nothing else is stored: deleting an entered bill makes it wait again, and a bill left unanswered drops out when the cycle ends (it is never posted; it can still be added by hand, E6).
  - **Entering** an amount posts an entry dated on the occurrence, linked to the rule: *Spent* for a changing bill, a card bill paid (kind `card`, in a hidden category, named after the card) for a card. The amount becomes the estimate for next time. Undo deletes the entry and puts the old estimate back.
  - **Didn't go out this month** records a skip for that date; Undo removes it.
  - **Switching to *Same every month*** moves `next_due` up to the latest occurrence on or before today, when that is later, so at most that one is posted, at the estimate; one already entered or skipped is left out. Older unanswered months are never back-posted (D124, D34).
  - The bill sheet's *Amount changes?* row files a card bill in the hidden card category, and moves it back to *Bills* when it stops being one.
- **Idempotency:** the unique index `(recurring_id, date)` plus `ConflictAlgorithm.ignore` means a crash or double run never double-posts.
- **Catch-up:** after 6 weeks away, a weekly rule posts all 6 occurrences, each with its own date.
- **Editing a rule** changes future occurrences only; already-posted entries are not touched. **Deleting a rule** stops future posts and keeps past entries.
  - A bill **added** in Settings first goes out on its next due date on or after today; earlier dates this cycle are not back-posted (DECISIONS D33).
  - When a bill's **day changes**, its next date is the new day in the month of the old `next_due` (the first month not yet posted), or, if that day has passed, the next due date from today. No month is posted twice and nothing is back-posted (D34).
  - **Delete** stops the rule at once, with Undo (6 s) that resumes it (D35).
- **Due-soon nudge:** when an unposted *Spent* occurrence falls 1 to 5 days after today, Home shows "{Label} ₹{amount} goes out in {n} days" ("goes out tomorrow" when `n = 1`). Only the soonest one is shown; on a tie, the rule saved first wins. Occurrences due today are the engine's and never shown. Saving rules are nudged the same way, worded "{Label} ₹{amount} goes in on {weekday}" ("goes in tomorrow" when `n = 1`) (D120). A changing or card bill says "about": "Electricity about ₹1,200 goes out tomorrow" (D123).
- **Bill stamp (D118):** the bill sheet (FR-SE-1) stamps the bill:
  - When its next unposted occurrence is 1 to 5 days away (the due-soon window): "Due in {n} days" ("Due tomorrow" when `n = 1`).
  - Otherwise, when an entry posted by this rule is dated on or after the occurrence one month before `next_due`: "Counted {d MMM}" with that entry's date, or "Counted today" when it is today.
  - Otherwise no stamp. A bill added this cycle after its day (D33) has no entry, so it never claims to be counted.
  - Nobody marks a bill as paid. The engine counts it on its day; a month that differed is fixed by editing or deleting that entry in *Every entry*.
- **Bill icon (D118):** a bill's icon is the one the user picked, or else the icon its name suggests (`BillIcon.forName`, whole-word matches, first group wins: loan, card, power, internet, phone, TV & apps, school, water, gas, insurance, house help, milk, society, home, car; else the plain bill glyph). Picking the icon the name already suggests clears the pick, so a later rename moves the icon with the name. A picked icon survives a rename.

### BR-10 Entries
- The amount is 1 to 999,999,999 rupees (at most 9 digits) and is stored as paise.
- The date defaults to today. The user may pick yesterday, or a date in the current or previous cycle. Future dates are not allowed.
- A note is optional, at most 80 characters, with whitespace trimmed.
- **Delete** happens at once with an Undo snackbar (6 s; with TalkBack it stays until dismissed, D105). **Edit** reopens the tray prefilled. A *Saved* entry can be deleted (that skips the month, and a rule's saving says "Skipped this month", never "missed") but never edited in the tray, which knows only *Spent* and *Got* (D120). A card bill paid is the same: never edited in the tray, and deleting it makes the bill wait again (D123).
- After any write, the ledger notifies listeners, and Home and Spends recompute.

### BR-11 Categories
- **Seed list (fixed order):**
  - Spent: Food, Travel, Shopping, Bills, Fun, Health, Home, Other.
  - Got: Money in, Other income. The stored key stays `salary`; "Money in" fits pay, pension, pocket money and family money alike (D116).
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
  - Goal: How did I do? / Where can I save? / What should my limits be? / Will my money last till payday? / Ask something else (the user's own question) (DECISIONS D71). *Will my money last till payday?* is offered only when the cycle shown holds today; otherwise it is hidden, and a pick of it falls back to *How did I do?* (DECISIONS D72). A cycle that ends at month end (*It changes*, or month start on the 1st) asks *Will my money last the month?* instead (DECISIONS D117).
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
  3. **Facts from the app**, only when the period holds today: "From my app, and correct: safe to spend today ₹1,430; at this pace it lasts till payday with about ₹9,300 spare; I save ₹5,000 a month (RD on the 10th)." The numbers are Home's own (`GetCycleSummary`, BR-4 and BR-7), never recomputed (DECISIONS D79):
     - Safe to spend today is the hero's number: ₹0 when today or the cycle is over.
     - The forecast reads "at this pace it lasts till payday with about ₹X spare" ("till month end" for a month-end cycle, D117) or "at this pace it runs out on YYYY-MM-DD", and is left out while it is too early to forecast (`E < 3`). It stays for "It changes" income, as on Home.
     - The savings clause lists every active saving rule, soonest first, and their monthly total: "I save ₹5,500 a month (RD on the 10th, Chit on the 15th)". It is left out when there are none (D120).
     - With no income at all (Home shows the No income card), the whole line is left out.
  4. Summary table by category (spent / limit).
  5. Recurring bills.
  6. Entries as CSV (`date,amount,kind,category,note`, oldest first; the note column is dropped when notes are hidden). `kind` is `spent`, `got`, `saved` or `card_bill_paid`; a saved entry's category is `savings` (D120) and a card bill's is `card bill` (D123). In the recurring bills, a changing bill reads "Electricity monthly on day 20 (changes, about 1,200)" and a card bill ends "(credit card; purchases already listed)".
  7. The task text for the chosen goal (DECISIONS D79):
     - How did I do?: "Task: Tell me how this period went. Give: 1) 3 things that stand out, good or bad, with ₹ amounts 2) the one change that would save the most, and how much a month 3) one habit worth keeping."
     - Where can I save?: "Task: Show me where I can save. Give 5 specific cuts, easiest first, each with how much it saves a month, then the total. Don't cut rent, EMIs, other fixed bills or health."
     - What should my limits be?: "Task: Suggest a spending limit per category for one pay cycle. Together they must fit my income after fixed bills and savings. Show a table: category, limit in ₹, one short reason."
     - Will my money last till payday?: "Task: Will my money last till payday? Use the numbers from my app as correct; don't recalculate them. Tell me which 1–2 categories are pushing my pace up and one thing to change this week."
       A month-end cycle reads "Task: Will my money last the month? …" with the same rest (D117).
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
- **FR-ON-2** Step 1 asks "How much money comes in each month?" with the keypad open. The hint names money, not a job, so it fits salaried, self-employed, gig, pension and family money alike: "Pay, business, pension or family money. If it changes, a low month is a safe guess." Between the keypad and Next, a lock and "It stays on this phone. The app never uses the internet." (DECISIONS D116).
  - Given 45000 is typed, then the preview reads "That's about ₹1,500 a day", captioned "Every day gets its own share". This is `floor(amount / 30)`, for the preview only.
  - Next is enabled only when the amount is greater than 0.
- **FR-ON-3** Step 2 asks "When does it come?" with five chips: *1st of the month*, *Last day*, *Pick a date* (day 1–31), *Every week* (weekday), *It changes*. The hint reads "Your month runs from one payday to the next. No fixed day? Pick It changes." Selecting a chip advances.
- **FR-ON-4** Step 3, "Any fixed bills?", offers chips (Rent, EMI, Phone, Internet, School fees, Subscriptions) that each open a mini keypad and a due day. **Skip** is always visible.
- **FR-ON-5** Finishing creates the income rule (for *It changes*, this month's money as one *Got* entry noted "Starting guess", D27, D117), any bill rules and the seed categories in one transaction. It then runs the recurring engine, lands on Home with the "assemble" motion (today's bar fills and the rail's dots arrive one by one) and fires the success haptic.
- **FR-ON-6** If the user leaves mid-onboarding, it resumes at the same step.

### 4.2 Home (FR-HO)
- **FR-HO-1** Shows the wordmark, today's date (`EEE, d MMM`, e.g. "Mon, 26 Oct") and a Settings button.
- **FR-HO-2** **Hero card:**
  - "Safe to spend today" with the hero amount (BR-4/BR-5).
  - Today's bar with its captions, then the days rail with "Today", "{D} days to payday" and the payday flag date (BR-6).
  - The range line (BR-7).
  - Tapping the hero toggles *Today* ↔ *This week*. *This week* shows `A × min(7, D) − (spent since the start of the week, Monday)`, and the toggle lasts for the session only.
    - The week's spending starts on Monday, or on the cycle start if that is later, and runs to today (DECISIONS D37). It counts typed spending only; bills posted in the week are in each day's pool (D119).
    - The title reads "Safe to spend this week". The number never shows below ₹0; past it, the hero shows ₹0, muted, beside "₹X over this week".
    - Today's bar and its captions give way to the week bars and weekday letters (BR-6a), in a 150ms crossfade; the days rail and its flag stay. The card's height never changes between the two (BR-6, D114). The range slot says the week in words (BR-6a). TalkBack reads each day by its full name with its amount, then the week sentence, and offers "Double tap to show this week" (or "show today") (D111).
- **FR-HO-3** **The nudge slot** shows one line: a bill **waiting** for its amount (BR-9), else the due-soon nudge, else nothing (D123).
  - **Waiting:** "Electricity went out today. How much?" ("…went out on 24 Oct. How much?" for an earlier day); a card bill reads "Credit card bill is due today. How much did you pay?" ("…was due on 24 Oct…"), naming the card. The oldest waits first; on a tie, the rule saved first. It has the due-soon row's shape and edges; TalkBack reads the sentence, then "Opens the keypad." A tap opens the bill amount sheet (FR-HO-8).
  - **Due-soon nudge** (BR-9), when applicable. It is a tappable `sunk` row at least 56dp tall: the bill's icon in a well, the sentence, the date under it, and a chevron. TalkBack reads the sentence, then "Opens the bill." ("Opens the saving." for a saving, D120). A tap opens that bill's or saving's sheet (FR-SE-1) over Home. After a change Home reloads; *Delete bill* deletes it from Home with Undo (D35, D118).
- **FR-HO-4** **Today list:**
  - The header shows today's total (typed spending, `S_today`) and *See all*.
  - A bill the app posted is listed like any entry; with no note, its second line reads *Bill* (D119, D123).
  - A card bill paid reads the card's name, *Paid, not counted again* and the amount, with the card glyph. It is never a bite on today's bar, is not in today's total, and has no tap; swiping deletes it with Undo, and the bill waits again (D123).
  - A saving reads its name (or *Put in extra*), *Saved* and the amount, with the piggy-bank glyph. It is never a bite on today's bar and has no tap; swiping deletes it with Undo (D120).
  - At most the 5 most recent entries for today.
  - Swipe left to delete, with Undo (BR-10). Tapping a row edits it.
  - Empty state: "Nothing spent today. Tap Add when you do."
- **FR-HO-5** **Over states** (BR-5 #2 and #3) show a calm card with one next step, *See where it went*, which opens Spends.
  - Over today: "It happens. The ₹220 is spread across the next 3 days, so each one is a little smaller." (with one day after today: "comes out of tomorrow"). On the last day `A = P`, so any overspend is over for the cycle.
  - Over for the cycle: "It happens. This month's money is used up. It starts again on payday, 4 Nov." A weekly cycle says "This week's money"; a month-end cycle drops "payday": "…It starts again on 1 Nov." (D116)
  - The step is hidden when Spends is already beside Home in two panes (DECISIONS D54).
- **FR-HO-6** The dock offers Home · **Add** · Spends. Add opens the tray (FR-AD).
- **FR-HO-7** The hero card is announced as one TalkBack node (UI_DESIGN §9).
- **FR-HO-8** **Bill amount sheet** (D123, mockup [29](design/mockups/29-changing-bills.html)):
  - **AC-1** It opens from the waiting line, in the bill sheet's route, straight onto the keypad. Back, a swipe down or the scrim closes it with nothing done.
  - **AC-2** The title is "{Bill} · {d MMM}" (the occurrence's date). The amount is prefilled with the estimate and the first key replaces it (FR-AD-8). The caption reads "Last time ₹1,200", or "You said about ₹1,200" before the bill was ever entered. A card bill adds "Add what you buy on the card on the day you buy it. This bill only reminds you to pay. It isn't counted again."
  - **AC-3** *Save* (marigold) enters the amount; untouched, it enters the estimate in one tap. ₹0 saves nothing. The sheet closes with the tick haptic and Home shows "Electricity ₹1,460 added" with Undo.
  - **AC-4** The text chip *Didn't go out this month* skips the occurrence; Home shows "Electricity skipped this month" with Undo.
  - **AC-5** A failed save keeps the sheet open with "Couldn't save. Try again."
  - **AC-6** Its content starts on the page gutter (D122).

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
  - The cumulative *Spent* line (solid ink) against the steady-pace line from (start, 0) to (end, `I − K`) (dotted), with `K` computed from the cycle's savings, posted or still to come (D120).
  - Fixed y-axis labels at ₹0 and at round thirds of `I`, in compact `en_IN` (₹20K).
  - A "Spending slower" or "Spending faster" verdict with a glyph (DECISIONS D77).
  - A today marker in marigold.
  - Labels sit every 1, 2 or 5 × 10ⁿ rupees from a third of `I − K` (₹45,000 gives ₹0 / ₹20K / ₹40K), up to the larger of `I − K` and the spending. When spending runs far past `I − K`, the step moves up the same ladder so at most 4 labels sit above ₹0 (₹3,000 with ₹5,00,000 spent gives ₹0 / ₹2L / ₹4L). Without income there is no steady line, so only the total shows (DECISIONS D49, D115).
  - Verdict: *Spending slower* when spending so far is at or under the steady line on the same day.
- **FR-SP-4** **Where it went:** categories sorted by amount, showing icon, name, % (BR-13), ₹, and a bar with an optional limit tick (BR-12). When any bar is hatched, one line under the rows reads "Striped part is over the limit." (hidden from TalkBack, since each row says "past limit") (D110).
- **FR-SP-4a** **Spent and saved:** one `ink2` line above *Where it went*, "Spent ₹27,570 · Saved ₹5,000", when the cycle shown has saves. Saves are never in the bars, percentages, week bars, pace or insights (D120).
- **FR-SP-5** **Insights** (BR-14), with their actions.
- **FR-SP-6** *See every entry* opens a day-grouped list with category and cycle filter chips. Swipe to delete and tap to edit, as on Home. A saving is listed with *Saved* and has no tap; each day's total counts spending only (D120).
  - The list shows the cycle picked in Spends (Home's *See all* opens the current one), with *All* plus a chip for each category that has entries. An insight's *See {Cat} entries* opens it on that category (DECISIONS D53).

### 4.5 Ask AI (FR-AI)
- **FR-AI-1** The goals (4, or 3 when *Will my money last till payday?* is hidden, BR-15) are a single column of list rows, each with an icon, followed by an own-question row: a 200-character text field that is always visible, with the placeholder "Ask something else". While it has focus and is empty, the placeholder reads "Like: can I afford a new phone this month?" (DECISIONS D73). Tapping or typing in it picks it. The pick shows an ink check at the row's end and a bold label, never a fill or marigold (DECISIONS D67).
- **FR-AI-2** The period segments and the *Leave out my notes* switch regenerate the preview immediately. The segments are named by their dates, as the cycle switcher names cycles: the shown cycle ("October"), and the three cycles oldest to newest ("Aug – Oct" for monthly cycles, short month names with no year; "12 Oct – 1 Nov" for weekly ones, the oldest start to the newest end) (DECISIONS D76).
- **FR-AI-3** The preview shows "What the AI will see · {n} entries", then the caption "Nothing leaves your phone until you share it.", then (when weeks were grouped) "Older weeks are shown as totals to keep it short.", the first 4 lines, and *Show full text*, which expands to the full scrollable text (DECISIONS D75).
- **FR-AI-4** The actions follow BR-15: *Copy & open ChatGPT*, *Other apps* and *Copy only*. When the prompt is too long to prefill ChatGPT, the paste caption sits directly above them. Nothing is sent anywhere by the app itself.

### 4.6 Settings (FR-SE)
- **FR-SE-1** Money settings:
  - Money coming in (edits the income rule; future cycles only; D116).
  - Bills (list, add, edit, delete rules; renamed from *Fixed bills*, D123). The list shows each bill's name, day and amount, soonest first. Each row shows the bill's icon (BR-9). **Adding** asks three questions: the name (typed, or one of 8 chips: the 6 from onboarding, then *Credit card* and *Electricity*, which fills it in; Next moves on, D86), the amount on the keypad, then the day of the month (1–31), where tapping a day saves. Bills are monthly. Rent goes in *Home*, a credit card in a hidden category (D123); every other bill goes in *Bills*. A name is 1–40 characters after trimming. Swipe removes a bill with Undo (BR-9).
  - **Changing a bill** happens in the bill sheet (D118, mockup [27](design/mockups/27-bill-sheet.html)):
    - **AC-1** Tapping a bill row, or Home's due-soon row (FR-HO-3), opens the sheet over the current screen. No page is pushed.
    - **AC-2** The sheet is a paper bill: its name, icon, amount, "Every month on day N" and stamp (BR-9), then five rows (Amount, Amount changes?, Day of the month, Name, Icon), then "Next goes out on {date}". TalkBack reads the bill as one sentence and each row as "Change {answer}, {value}".
    - **AC-3** A row opens its one question inside the sheet: the keypad prefilled with the amount (the first key replaces it, as FR-AD-8), the 1–31 grid with the current day picked, the name field without pills, or the grid of 16 icons with the current one picked.
    - **AC-4** Amount and name save with *Save*; a day or an icon saves on tap. Each save changes only that answer (a day follows D34), returns to the bill, flashes the row, and the footer reads "Saved." for 2.4 s. Saving an unchanged answer writes nothing.
    - **AC-5** Back from a question returns to the bill. Back, a swipe down or the scrim closes the sheet; unsaved typing is dropped, saved answers stay.
    - **AC-6** *Delete bill*, a full-width `sunk` key at the foot of the bill, closes the sheet and deletes the bill with Undo (D35).
    - **AC-7** A failed save keeps the question open with "Couldn't save. Try again."
    - **AC-8** *Amount changes?* shows *Same every month*, *Changes every month* or *Credit card* (the value may take two lines). Its question is the three answers stacked, the current one picked; a tap saves (BR-9, D123).
    - **AC-9** The *Credit card* chip makes a card bill and *Electricity* a changing one; any other name starts fixed. A changing bill's amount question reads "About how much is Electricity?", a card's "About how much is the Credit card bill?", with the card line of FR-HO-8 AC-2 under it while adding.
  - **Savings** (D120; replaces "Keep aside each month"): the same list, three questions and sheet as fixed bills, worded "goes in". The name pills are RD, SIP, Gold scheme and Chit. Savings are monthly and filed in a hidden category; the sheet has no Icon row (the piggy-bank glyph) and its stamp reads "Put in {date}". The list's footer reads "₹X put in since {Mon}": everything ever put in, never "worth" or "balance". *Put in extra* opens a keypad for a one-off saving today:
    - **AC-1** It opens the keypad in a sheet, in the bill sheet's route.
    - **AC-2** The line under the amount is `tomorrow(remaining) − tomorrow(remaining − x)`: "Each day till payday gets ₹62 less" in the worked example ("…till month end…" for a month-end cycle), or "Payday's tomorrow." when `D = 1` (E-h).
    - **AC-3** The keypad refuses a digit that would go past `remaining`; with nothing left it reads "Nothing left to put in for now." and Save stays off.
    - **AC-4** Save posts a *Saved* entry dated today and closes the sheet with the success haptic. Today's share stays fixed; the later days get the less.
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
| E19 | A saving's day is the 29th–31st | Clamped to the month's last day, as in BR-1 (D120) |
| E20 | A saving bigger than everything left | `P < 0`: Over for the cycle, as E5 |
| E21 | App closed for weeks with an RD | Each missed month posts once, dated on its day (BR-9, E7) |
| E22 | The RD posted, and the user also logs the bank debit as *Spent* | Not prevented; the RD row on Today and the due-soon line are the cues (case study 17 risk) |
| E23 | A changing bill on the 31st in a 30-day month | Waits on the 30th, as BR-1 clamps (D123) |
| E24 | A changing bill never entered by the cycle's end | Drops out of `B` and stops waiting; never posted; can be added by hand (E6) |
| E25 | Entering a bill twice for the same date | Not offered (it no longer waits); the unique `(recurring_id, date)` index refuses a second entry |
| E29 | A changing bill's day moved, or its entry's date edited, after the month was entered | The month stays answered: nothing more is reserved or asked for (D123) |
| E26 | Undo after entering | The entry goes and the bill waits again, with its old estimate |
| E27 | A long-ignored changing bill switched to *Same every month* | Only the latest occurrence on or before today is posted, at the estimate; older months never (D124) |
| E28 | A card bill with income that changes | No difference: a card bill never touches the pool |

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
