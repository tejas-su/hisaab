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
- A home-screen widget, a Quick Settings tile and an app shortcut (FR-WG, D147).
- *Fix my number* (BR-18, FR-FX), yearly costs as savings with *Used from savings* (BR-19), and a once-a-day missed-log line (FR-HO-3), signed off 2026-11-13 (D163 to D189; PLAN M8).

### 1.2 Not in v1
- Accounts, wallets, transfers and splitting.
- Bank or UPI SMS reading.
- Sync, login, multiple devices and multiple currencies.
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
| **Entry** | One money movement: *Spent* (out) or *Got* (in). Two more kinds sit beside them: *Saved* (put into a saving) and *Used* (paid from one), BR-10. The UI never says "transaction" |
| **Recurring rule** | A template that posts an entry on a schedule (salary, rent, Netflix) |
| **Cycle** | The run of calendar days the user's money must last. It starts on payday by default |
| **Today's share** (`A`) | The amount the user can spend today without hurting later days. It is fixed for the day |
| **Safe to spend today** | Today's share minus what was spent today. This is the hero number |
| **Today's bar** | Today's share as one bar: the yellow is what's left, and each thing bought today is a bite out of it (BR-6) |
| **Days rail** | One dot per day left in the cycle, today's first, ending at the payday flag (BR-6) |
| **Range line** | A forecast sentence: does the money last until payday at the current pace? |
| **Month end** | The end of a cycle that follows the calendar month (*It changes*, or month start on the 1st). It has no payday, so the rail, range line and over card name the month end instead (DECISIONS D116) |
| **Bill** | Money that goes out every month on a day. It is *Same every month* (posted by itself), *Changes every month* (Home asks how much on its day) or a *Credit card* bill (a reminder to pay; never counted again) (BR-9, D123) |
| **Waiting** | A changing or card bill whose day has come but whose amount isn't entered yet (BR-9) |
| **Saving** | Money put in on the same day every month, like an RD; today's share leaves room for it, and it is never spending (D120). A yearly cost (insurance, school fees, a festival) is one too: a twelfth a month, then *Used* when paid (D174) |
| **Limit** | An optional cap on one category's spending in a cycle (BR-12) |
| **Category** | What an entry was for: 8 built-in *Spent* categories in fixed places, up to 4 of the user's own after them, and 2 *Got* categories (BR-11, D138) |
| **Starting guess** | The income an *It changes* user typed in onboarding, saved as one *Got* entry with that note (D117) |
| **Backup** | One file with everything in hisaab, made by *Back up* and saved where the user picks (BR-16). The verb is *back up*; a backup is never called an export or "saved" (that word means money put in) |
| **Restore** | Replacing everything in hisaab with a backup file's contents (BR-16) |
| **Delete everything** | Clearing all hisaab data on this phone and opening onboarding. It replaces *Reset app* (FR-SE-4) |
| **Fix my number** | The act of telling hisaab how much of this month's money is left, so it can correct its own figure. "Number" is the Home figure. It adds one *Not logged* entry (BR-18, FR-FX; D165) |
| **Not logged** | The hidden category on the entry a fix adds: *Spent* when money is missing, *Got* when hisaab under-counted. It is pool-side like a bill on its day and is never today's spending (BR-18) |
| **Held** (`H`) | What hisaab expects the user still holds of this cycle's money (BR-18). The word is never shown: the copy says "hisaab thought ₹17,430." |
| **Set aside** | Money put into a saving and not yet used. It is a computed total, never called a balance or a worth (BR-19) |
| **Used from savings** | Paid a cost out of what a saving holds ("Used some of it" on the key). A fourth kind of entry that touches no number (BR-19). *Saved* still means only money put into a saving |

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

### BR-1a A changed payday (D140)
When the pay rule changes on day `c` (Settings, FR-SE-1), the old rule is kept as a *pay switch* (`c`, old rule), so cycles never jump:

- **The bridge cycle:** the cycle `c` falls in keeps its start (from the old rule) and ends the day before the first new payday **after** `c`. A new payday of `c` itself is first paid next month, never on `c`, so no pay is counted twice.
- **Before and after:** cycles before the bridge keep the old rule; cycles after it follow the new one.
- **Several changes:** each change bridges from the cycle as the earlier changes left it. Changing back the same day restores the old cycle exactly.
- **Month start on the 1st:** cycles stay calendar months; only the day the pay is posted changes.
- **Pay:** the salary rule moves to the new schedule with its next pay after `c`. A weekly ↔ monthly change keeps the monthly figure (weekly posts month × 12 ÷ 52, D26). *It changes* stops the rule and keeps its past pay; a fixed day after *It changes* adds a rule for the month the person types.
- **Example:** payday on the 4th moved to the 25th on Mon 26 Oct 2026. The bridge runs Sun 4 Oct to Tue 24 Nov (30 days left). Rent of ₹8,200 on 5 Nov now falls inside it, so `P = 45,000 − (1,200 + 8,200) − 27,150 = 8,450` and `A = floor(8,450 / 30) = ₹281`. Moved to the 1st instead, the cycle ends Sat 31 Oct (6 days) and `A = floor(16,650 / 6) = ₹2,775`. From 25 Nov every cycle runs from the 25th.

### BR-2 Days left
`D = end − t + 1`. It counts today, so `D ≥ 1`, and on the last day of the cycle `D = 1`.

Example: 26 Oct → 3 Nov gives `D = 9`.

### BR-3 Spendable pool at the start of today (`P`)
```
P = I − K − B − S_prev − R_t − F_t
```

| Symbol | Meaning |
|---|---|
| `I` | All *Got* entries dated within the cycle, posted recurring income included, and a *Got* "Not logged" entry (BR-18) |
| `K` | Set aside for savings, computed: `R + Sv_before + Sv_rule_today` (D120) |
| `R` | Saving occurrences due in `(t, end]` and not yet posted |
| `Sv_before` | *Saved* entries dated within `[start, t − 1]`, by a rule or put in extra |
| `Sv_rule_today` | *Saved* entries dated `t` that a saving rule posted |
| `Sv_extra_today` | *Saved* entries dated `t` with no rule (*Put in extra*); they leave `A` fixed and thin the later days (BR-4) |
| `B` | Recurring *Spent* occurrences due in `(t, end]` (after today, within the cycle) and not yet posted, plus a changing bill's occurrences in `[start, t]` still *waiting* (BR-9), each at its estimate. A card bill is never in `B` (D123) |
| `S_prev` | All *Spent* entries dated within `[start, t − 1]`, bills included, and earlier *Spent* "Not logged" entries |
| `R_t` | *Spent* entries dated `t` that a recurring rule posted (bills due today) |
| `F_t` | *Spent* "Not logged" entries dated `t`: what a *Fix my number* found missing today (BR-18). It is pool-side like `R_t`, so it comes out of the pool and never out of today's share. From tomorrow it is part of `S_prev` |

A bill posted on its own day comes out of the pool (`R_t`), not out of today's share: until today it sat in `B`, so the share was already sized for it (DECISIONS D119). Example: rent ₹15,000 posts today, nothing spent yet, `B = 0`, `S_prev = 27,150`: `P = 45,000 − 15,000 − 27,150 = 2,850` and `A = floor(2,850 / 9) = ₹316`. The hero shows ₹316, not ₹0 and "over today".

A changing bill (electricity) waits on its day for the user to say how much; until then its estimate (the last amount entered) stays in `B`. Entering it moves it to `R_t`, so the share follows the real amount (BR-4). A card bill is recorded but never counted, because the card buys were counted when made: paying it changes no number (D123).

**One rule for everything a rule posts:** it is set aside before its day (`B` for bills, `R` for savings) and comes out of the pool on its day, never out of today's share. Worked example 3 (D120): a ₹5,000 RD went in on the 10th, so `K = 5,000`, `P = 45,000 − 5,000 − 1,200 − 27,150 = 11,650` and `A = floor(11,650 / 9) = ₹1,294`; with ₹420 spent the hero shows ₹874. On the RD's own day `P` doesn't move: yesterday's `R` becomes today's `Sv_rule_today`.

**Two entry kinds relate to `P` differently (D166, D175).** A fix's *Spent* entry is `F_t`: its whole job is to move the pool (BR-18). A *Used* entry (BR-19) is in no symbol above: the money left `K` when it was put in, so paying a cost from it moves nothing. A *Got* fix is in `I`.

### BR-4 Today's share and safe to spend
```
A          = max(0, floor(P / D))      // fixed for the whole of day t
S_today    = Spent entries dated t that no recurring rule posted and that are not "Not logged"
safeToday  = A − S_today               // hero shows max(0, safeToday)
overToday  = max(0, S_today − A)
remaining  = P − S_today − Sv_extra_today
tomorrow   = floor(remaining / (D − 1))   // only when D > 1
```
- A *Put in extra* leaves today's `A` fixed and thins the later days: ₹500 put in with ₹420 spent gives `remaining = 10,730` and `tomorrow = floor(10,730 / 8) = ₹1,341` against ₹1,403 without it, so "Each day till payday gets ₹62 less" (D120).
- `A` does **not** change as the user spends during the day. Only `safeToday` changes. Saving an entry dated in the past changes `S_prev`, and entering or changing a bill dated today changes `R_t`; either way `A` is recomputed.
- **A changing bill entered today** (D123): electricity, estimate ₹1,200, due today and waiting, so `B = 1,200`, `P = 16,650`, `A = 1,850` and the hero shows ₹1,430. The user enters ₹1,460: `B = 0`, `R_t = 1,460`, `P = 16,390`, `A = floor(16,390 / 9) = 1,821`, and the hero shows ₹1,401. A card bill of ₹8,000 paid today changes nothing.
- **A fix entered today** (BR-18, D166): `H = 17,430` and the user types ₹13,230. `F_t = 4,200`, `P = 12,450`, `A = floor(12,450 / 9) = 1,383`, and the hero shows `1,383 − 420 = ₹963`. `S_today` is still ₹420 (a fix is not spending) and `A` stays above it, so the hero is simply ₹963. Both directions, the guard and the other examples are in BR-18.
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

A fix (BR-18) reaches state 2 through `remaining`, when the user really holds less than the bills and savings still to come; the existing calm card says it. It is never in `S_today`, but it lowers `A`: if `A` then falls below what was already spent today, state 3 applies exactly as it does when a bill is entered today (E75). A *Used* entry (BR-19) moves no state.

### BR-6 Today's bar and the days rail
Replaces the Day Blocks (D114; [mockup 25](design/mockups/25-today-bar-and-rail.html)).
- **Today's bar:** one bar, the hero's full inner width, 48dp tall.
  - **Span:** `max(A, S_today)`. While `S_today ≤ A` the bar is today's share.
  - **The yellow** (marigold) runs from the start edge: `clamp(A − S_today, 0, A) / span`. It is the hero amount.
  - **Bites:** each *Spent* entry counted in `S_today` (never a bill a rule posted, never a *Not logged* entry) is a `blockIdle` piece of `amount / span`, the first saved at the end edge and each later one next to the yellow, 3dp apart. A bite narrower than 4dp merges with its neighbours. A bite wide enough for its category name has the name under it.
  - **Over today** (`S_today > A`): no yellow. A 2dp `displayInk` tick marks `A / span`, and everything past it is hatched in `displayInk2`.
  - **States (BR-5):** slow down draws the yellow as a marigold outline; over today and over for the cycle draw the hatch. With `A = 0` and nothing spent, the bar is empty.
  - **Worked example:** `A = 1,850`, chai ₹40 then lunch ₹380. The yellow is `1,430 / 1,850 ≈ 77%`; lunch (20.5%) sits next to it and chai (2.2%, about 6dp) at the end. After ₹1,080 groceries and ₹800 cab, `S_today = 2,300`: the span is ₹2,300, the tick sits at `1,850 / 2,300 ≈ 80%`, and the last 20% is hatched.
  - **A change of today's share** (a fix, BR-18) re-spans every segment against the new `A` in one motion. With `A` going from 1,850 to 1,383 and ₹420 spent, the yellow goes from 77% to 70% of the bar and the bite from 23% to 30%; a rise to `A = 1,961` gives 78.6% and 21.4%.
- **Captions:** "₹420 spent" at the start and "of ₹1,850 for today" at the end, under the bar.
- **Days rail:** one dot per day left (`D`), today first at 10dp, the others 6dp `blockIdle` (smaller, down to 2dp, when they would be closer than 2dp apart), then the payday flag with its date. Today's dot: marigold (on track), a marigold ring (slow down), hatched (over today, over for the cycle). Over for the cycle also outlines every later dot. Captions: "Today" and "{D} days to payday" (on the last day, "1 day to payday"). A month-end cycle reads "{D} days left this month" ("Last day of the month" when `D = 1`) and its flag shows the 1st of the next month (D116).
- **Same height in both modes:** the bar with its names and captions, and the week bars with their letters (BR-6a), are laid out in one cell; the card takes the taller, so tapping between *Today* and *This week* never resizes it. The days rail sits under that cell in both modes.

### BR-6a Week bars (*This week*)
- **Days:** Monday to Sunday. Monday (or the cycle start, if later) to today each get a bar; days still to come in the cycle get a stub; days before the cycle start or from payday on get nothing.
- **Each past day's share `A_d`** is that day *as it stood*, with the ledger as it is now: entries dated on or before `d`; bills posted after `d` still counted in `B`; income dated after `d` not yet in `I` (BR-3, BR-4; the same rebuild as BR-8's yesterday). A back-dated entry changes that day and the days after it. A *Not logged* entry dated on or before `d` is in that day's pool (`F_t` or `S_prev`), never in its bar; a *Used* entry is in nothing (BR-18, BR-19).
- **Each bar** fills to the day's typed *Spent* total; a bill posted that day is in its pool (`R_t`), not its bar (D119). A tick marks `A_d`; any spend above it is hatched, never red. Today's bar is marigold; past bars are `displayInk2`.
- **Scale:** zero at the bottom; the tallest spend or share in the week reaches the top (64dp, the card's full inner width; D114).
- **Words:** the range slot reads "Spent ₹4,950 this week · Tue was ₹460 over its share" (the most-over day, then "and N more days"), "Today is ₹220 over its share" when today is the most over, or "· every day within its share". A day exactly at its share is within it.
- **Worked example:** today Thu 29 Oct. Spent Mon ₹1,240, Tue ₹2,310, Wed ₹980, Thu ₹420 so far. With Tue's `A_d = 1,850`, Tue's ₹460 above its tick is hatched and the sentence names it.

### BR-7 Range forecast (the range line)
- **Pace:** `pace = V_prev / E`.
  - `V_prev` is the *Spent* entries in `[start, t − 1]` that were **not** posted by a recurring rule and are not *Not logged* (BR-18). One big fix must not read as a fast pace; `remaining` still falls, so the spare falls honestly.
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
  - **Saved:** `X = A_yesterday − S_yesterday`, where `A_yesterday` is rebuilt from the ledger as it stood yesterday: *Got* entries dated up to yesterday, and bills posted today still counted in `B`. `S_yesterday` leaves out *Not logged*; a fix dated yesterday is pool-side in `A_yesterday` (as `S_prev` is), so the note neither credits nor blames it (D189). A *Used* entry is in nothing (BR-19).
  - **Each day more:** `Y = floor(X / D)`, with `D` counted from today. With nothing else changed, today's `A` is exactly `A_yesterday + X / D`, so the note credits only the underspend (DECISIONS D38).
  - The note reads "Yesterday was ₹{X} under its share, so every day got ₹{Y} more." When `Y < ₹1` it reads "Yesterday was ₹{X} under its share." It never says "saved", which means only money put into a saving (D121). It shows all day. It never shows on the cycle's first day, since yesterday belongs to the previous cycle. It also never shows when the first entry was saved today, since the app wasn't tracking yesterday (DECISIONS D38).
  - **Example:** in the worked example nothing was spent on Sun 25 Oct, when `A = 16,650 / 10 = ₹1,665`. So `X = ₹1,665` and `Y = floor(1,665 / 9) = ₹185`, which matches `1,850 − 1,665`.

### BR-9 Recurring engine
- Each rule has: `amountMinor`, kind (*Spent*/*Got*/*Saved*; a *Saved* rule's entry carries the rule's name as its note, D120), category, frequency (weekly / every 2 weeks / monthly / yearly), anchor date, `next_due` and `active`.
- **On every app start and resume**, for each active rule, while `next_due ≤ t`:
  1. Insert the entry dated `next_due`.
  2. Advance `next_due` by one period, with monthly rules clamped as in BR-1.
- All inserts for one run happen in **one DB transaction**.
- **Kind of bill (D123).** A bill is *Same every month* (fixed, posted as above), *Changes every month* or a *Credit card*. Savings and income are always fixed.
  - The engine **never posts** a changing or card bill and never moves its `next_due`, which stays the first date it may wait from (D33).
  - An occurrence **waits** when it falls in this cycle on or before today, not before `next_due`, and its month has neither an entry nor a skip of that bill. A month is answered once, so moving the bill's day or an entry's date never asks (or reserves) the same month twice. Nothing else is stored: deleting an entered bill makes it wait again, and a bill left unanswered drops out when the cycle ends (it is never posted; it can still be added by hand, E6).
  - **Entering** an amount posts an entry dated on the occurrence, linked to the rule: *Spent* for a changing bill, a card bill paid (kind `card`, in a hidden category, named after the card) for a card. The amount becomes the estimate for next time. Undo deletes the entry and puts the old estimate back.
  - **Didn't go out this month** records a skip for that date; Undo removes it.
  - **Switching to *Same every month*** moves `next_due` up to the latest occurrence on or before today, when that is later, so at most that one is posted, at the estimate; one already entered or skipped is left out. Older unanswered months are never back-posted (D124, D34).
  - The bill sheet's *Kind of bill* row files a card bill in the hidden card category, and moves it back to *Bills* when it stops being one.
- **Idempotency:** the unique index `(recurring_id, date)` plus `ConflictAlgorithm.ignore` means a crash or double run never double-posts.
- **Catch-up:** after 6 weeks away, a weekly rule posts all 6 occurrences, each with its own date.
- **Editing a rule** changes future occurrences only; already-posted entries are not touched. **Deleting a rule** stops future posts and keeps past entries.
  - A bill **added** in Settings first goes out on its next due date on or after today; earlier dates this cycle are not back-posted (DECISIONS D33).
  - When a bill's **day changes**, its next date is the new day in the month of the old `next_due` (the first month not yet posted), or, if that day has passed, the next due date from today. No month is posted twice and nothing is back-posted (D34).
  - **Delete** stops the rule at once, with Undo (4 s) that resumes it (D35).
  - **Yearly costs stay savings** (D174): the bill sheet is still monthly (D35). A *Used* entry is not a rule's entry: it has no `recurring_id` and links to its saving by its own `saving_id` column, because `(recurring_id, date)` is unique and a use on a put-in's date would be refused. Deleting a saving keeps its past entries, *Used* included (BR-19).
- **Due-soon nudge:** when an unposted *Spent* occurrence falls 1 to 5 days after today, Home shows "{Label}, ₹{amount}, due in {n} days" ("due tomorrow" when `n = 1`). Only the soonest one is shown; on a tie, the rule saved first wins. Occurrences due today are the engine's and never shown. Saving rules are nudged the same way, worded "{Label}, ₹{amount}, due on {weekday}" ("due tomorrow" when `n = 1`) (D120). A changing or card bill says "about": "Electricity, about ₹1,200, due tomorrow" (D123, D132).
- **Bill stamp (D118):** the bill sheet (FR-SE-1) stamps the bill:
  - When its next unposted occurrence is 1 to 5 days away (the due-soon window): "Due in {n} days" ("Due tomorrow" when `n = 1`).
  - Otherwise, when an entry posted by this rule is dated on or after the occurrence one month before `next_due`: "Went out {d MMM}" with that entry's date, or "Went out today" when it is today (D132).
  - Otherwise no stamp. A bill added this cycle after its day (D33) has no entry, so it never claims to be counted.
  - A changing or card bill that still waits for its amount (FR-HO-3) is stamped "Waiting" first, and the footer gives the day it went out instead of next month's: "Went out on {d MMM}. Home asks how much." ("Was due on {d MMM}. Home asks what you paid." for a card). A card bill already paid reads "Paid {d MMM}" or "Paid today", never "Counted", because it isn't counted (D127).
  - Nobody marks a bill as paid. The engine counts it on its day; a month that differed is fixed by editing or deleting that entry in *Every entry*.
- **Bill icon (D118):** a bill's icon is the one the user picked, or else the icon its name suggests (`BillIcon.forName`, whole-word matches, first group wins: loan, card, power, internet, phone, TV & apps, school, water, gas, insurance, house help, milk, society, home, car; else the plain bill glyph). Picking the icon the name already suggests clears the pick, so a later rename moves the icon with the name. A picked icon survives a rename.
- **Due-day reminder (D126):** a bonus on top of Home's waiting line, which is the guarantee (some phones drop reminders). Only once the user said *Remind me* (FR-SE-1 AC-10):
  - Each changing or card bill gets one local notification for its next due day at about 09:00 (inexact, no exact-alarm permission). Today's counts only while it still waits and it is before 09:00, so none is ever shown after the fact. A card reads "{Card} bill is due today", a changing bill "{Bill} went out today"; the text is "Tap to add how much". Never an amount or a note; a locked screen hides the text (private visibility).
  - The id comes from the rule and the date, so re-arming never shows two. They are re-armed on every start, resume and write: one already shown stays while its bill waits and goes once it is entered or skipped; a deleted bill's go too. A swiped-away one is never sent again. No action buttons.
  - A tap carries `hisaab://bill/{ruleId}/{date}`; it goes back to Home and opens that bill's amount sheet (FR-HO-8), or only Home when the bill no longer waits.


### BR-10 Entries
- The amount is 1 to 999,999,999 rupees (at most 9 digits) and is stored as paise.
- The date defaults to today. The user may pick yesterday, or a date in the current or previous cycle. Future dates are not allowed.
- A note is optional, at most 80 characters, with whitespace trimmed.
- **Delete** happens at once with an Undo snackbar (4 s; with TalkBack it stays until dismissed, D105). **Edit** reopens the tray prefilled. A *Saved* entry can be deleted (that skips the month, and a rule's saving says "RD skipped this month", never "missed") but never edited in the tray, which knows only *Spent* and *Got* (D120). A card bill paid is the same: never edited in the tray, and deleting it makes the bill wait again (D123). Editing the amount of a changing bill's latest entry in the tray makes it next month's estimate, as entering it did (D127).
- **A save from the Add tray** has no Undo, except a one-tap add from the *your usual* pill (FR-AD-10, D153): "Added ₹20 to Chai" with *Undo* (4 s; with TalkBack it stays until dismissed), over whichever of Home or Spends is in view. Undo deletes that entry and quiets that category until midnight (BR-17).
- **Four kinds (D175):** *Spent*, *Got*, *Saved* and *Used*. Two entries are written by an act other than Add, both dated today with no date picker, both deleted with Undo and never edited in the tray:
  - **A fix** (BR-18): a *Not logged* entry, *Spent* or *Got*. Tapping its row does nothing. To change it, delete it and fix again (two taps).
  - **A *Used* entry** (BR-19): kind `used`, from 1 rupee up to what the saving has set aside.
- **Undo on the two corrective saves** (*Fix it*, *Used*) is 4 s like every Undo, held until dismissed with TalkBack (D105). Switch Access users can't beat 4 s, so every *Not logged* and *Used* row also exposes *Delete* as a custom semantics action in Today and Every entry (the same Undo follows).
- After any write, the ledger notifies listeners, and Home and Spends recompute.

### BR-11 Categories
- **Seed list (fixed order):**
  - Spent: Food, Travel, Shopping, Bills, Fun, Health, Home, Other.
  - Got: Money in, Other income. The stored key stays `salary`; "Money in" fits pay, pension, pocket money and family money alike (D116).
- The user may **rename** any category or **change its icon** (FR-SE-2). The 8 built-in *Spent* and 2 *Got* categories keep their places, are never hidden, and their count is fixed, so muscle memory survives.
- **Your own (D138):** the user may add up to **4** *Spent* categories. They come after the 8 in the order they were made and are never sorted by use. *Got* has no categories of the user's own.
  - **Name:** 1–16 characters after trimming. It must not match any category's name, shown or hidden, ignoring case: a name that matches saves into that category instead (a hidden one comes back). It must not be `savings`, `card bill` or `not logged`, the hidden categories' export names (D120, D123, D166).
  - **Icon:** `icon_key` stores an app-owned key from the curated set (UI_DESIGN §3.5), never glyph data or a Hugeicons name. `CategoryIcon.forName` suggests a key from the name's words (first match in the table wins; no match is `tag`). A key unknown to the app draws *Other*'s icon. A shipped key never changes meaning.
  - **Hiding:** only the user's own can be hidden (`archived = 1`), with Undo. A hidden category leaves the Add tray and Settings' count, keeps its entries, name and icon, and still shows in Spends, filters, past cycles and exports. It is never the same as the system-hidden `saved`, `card_paid` and `not_logged` rows.
  - **System-hidden rows (D166):** `saved` (also holds *Used* entries, export name `savings`), `card_paid` and the two `not logged` rows hold entries the Add tray never lists. The `not logged` pair is one *Spent* row and one *Got* row, both `archived = 1`, both exported as `not logged`; a fresh install and migration 005 (PLAN §8) create them. None is renameable, hideable or given a chip (FR-SP-6).
- Every entry has exactly one category. Entries posted by recurring rules use the rule's category.

### BR-12 Category limits (optional)
- They are off by default. After the **first full cycle**, Spends offers "Use these limits?" with each limit set to that category's spend last cycle, **rounded up to the next ₹500**. One tap accepts all of them.
  - **Full cycle:** the previous cycle counts as full when the earliest entry in the ledger was *saved* (`created_at`, not its date) on or before that cycle's start (DECISIONS D39).
  - Only categories with spending last cycle get a limit. Exactly ₹500 stays ₹500, and ₹501 becomes ₹1,000.
  - The offer is not made once any category has a limit.
  - *Not logged*, *Saved*, *Used* and card-bill entries are never in a category's spend, so they never move a limit (BR-18, BR-19).
- **Display:** the bar fills to `spent / max(spent of any category)`. A limit tick sits at `limit / max`, and any spend past the tick is drawn hatched, never red.
  - Under its limit a row says "₹200 left" beside the name, and "₹0 left" at the limit exactly; past it, "₹840 over limit" replaces the share. The words show even when the limit is beyond the biggest bar and no tick is drawn (D110).

### BR-13 Percentages (Spends)
- The shares of the cycle total use the **largest-remainder method**, so the shown integers always sum to exactly 100. The total is the same *Spent* entries as the bars: *Not logged*, *Saved* and *Used* are not in it (*Not logged* has its own part on the Spends line, FR-SP-4a).
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
1. **A category up at least 20% and at least ₹1,000 against the previous cycle at the same day-of-cycle.** "{Cat} spending is ₹X more than in {previous cycle}.", where the previous cycle is named as the cycle switcher names it ("September", or "19 Oct – 25 Oct") (DECISIONS D78). Day-of-cycle `k` is compared with day `min(k, previous cycle length)` of the previous cycle; this matters for 28-, 30- and 31-day cycles.
2. **A single entry larger than 2× that category's median entry this cycle.** "Your biggest {cat} spend was ₹X on {date}."
3. **The cycle's steadiest category** (lowest week-to-week variance, with at least 4 entries). "{Cat} spending stays about the same every week."
4. **The limit offer** from BR-12, on the current cycle only. "Set limits from {previous cycle}'s spending? Each one is rounded up to the next ₹500."

- Each rule gives at most one insight. #1 picks the biggest rise and needs a fully tracked previous cycle (the first entry saved on or before its start). #2 picks the biggest standout. #2 and #3 leave out bills posted by a rule. No insight counts *Not logged*, *Saved* or *Used* entries (BR-18, BR-19).
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
     - **Explaining lines (D188):** one fixed sentence for each kind the export holds, right after the facts, so every other export stays byte-identical (two new goldens: one with each clause).
       - *Not logged:* `Entries with the category "not logged" are corrections. When the user checked their real money it differed from this list, so one entry was added for the difference. Treat each as a one-off, not as a purchase or a habit, and do not give spending advice about it.`
       - *Used:* `Entries of kind "used" are costs the user paid from money they had already set aside in a saving, such as a yearly insurance bill. That money was counted when it was put in, so it is not spending in this period and does not change the daily number. Do not add it to spending.`
  4. Summary table by category (spent / limit).
  5. Recurring bills.
  6. Entries as CSV (`date,amount,kind,category,note`, oldest first; the note column is dropped when notes are hidden). `kind` is `spent`, `got`, `saved`, `used` or `card_bill_paid`; a saved or used entry's category is `savings` (D120, D175), a card bill's is `card bill` (D123), and a fix keeps `kind` `spent` or `got` with category `not logged` and note `Not logged` (D166). A used entry's note is its saving's name. In the recurring bills, a changing bill reads "Electricity monthly on day 20 (changes, about 1,200)" and a card bill ends "(credit card; purchases already listed)".
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
Mockup [34](design/mockups/34-data-controls.html), copy deck [34](design/mockups/34-data-controls-copy-deck.md), case study 23, DECISIONS D139.
- **Backup:** a single JSON file (`application/json`, default name `hisaab-backup-YYYY-MM-DD.json`) holding the schema version, the date made, settings (including Look), categories, all rules (inactive too) and all entries with their notes and `created_at`. It is saved only when the user taps *Back up*, through the system *Save to* screen (`file_picker`), in a place the user picks. There is no automatic or scheduled backup. The file has no password.
  - The phone remembers the date of the last backup and shows it under the row (FR-SE-4). Nothing ever nags about it.
  - If the picked place already has that name, Android names the new file itself (for example `… (1).json`). The snackbar says the name it got.
- **Restore** reads the picked file into memory, then validates it before anything changes:
  - The picker shows all files (`*/*`), so no storage app greys the backup out; the contents are what's checked.
  - Not JSON, no `hisaab` marker, or required fields missing → refused, "That's not a hisaab backup. Pick a file whose name starts with hisaab-backup."
  - `schemaVersion` newer than the app → refused, "This backup is from a newer hisaab. Update hisaab from Play Store, then try again."
  - An older `schemaVersion` is migrated in memory, with no message. A file from before schema v5 gains the two hidden `not logged` rows in that migration (PLAN §8).
  - Categories the user made (no seed key) restore like the built-in ones, hidden flag included. An icon key this version doesn't know draws *Other*'s icon and is kept, so a newer version can draw it (D138).
  - A file whose onboarding was never finished (no `onboarding_done`) is refused as not a backup; it would have no income for hisaab to work from. The file is also loaded into a scratch database first, so a table, column or row that doesn't fit refuses it as broken before the real data is touched.
  - **From Settings:** the one confirmation dialog in the app (D4): "Replace with this backup?", the file's date and entry count, and what it replaces on this phone. Keys *Replace* / *Keep what's here*.
  - **From onboarding** (FR-ON-1): nothing is there to replace, so there is no dialog and no Undo.
  - The replace runs in one transaction. Before it, the current data is copied to an app-private snapshot.
  - Afterwards the user stays on Settings, where they tapped, with "Backup from {date} restored" and *Undo*; Home behind it is rebuilt on the restored data. For 7 days Settings also shows an *Undo restore* row. Undo puts the snapshot back. The snapshot is dropped after 7 days, on the next restore, on Undo, or on *Delete everything*.
  - Reminders are re-armed from the restored bills. The recurring engine then runs once as on any start (BR-9), so no catch-up is posted twice.
- The backup and restore carry every table, including the *your usual* quiet states and their `asked_on` dates (BR-17; category ids and dates only), the hidden `not logged` rows and their entries (BR-18), `used` entries with their `saving_id` (BR-19), and the install line's *seen* flag (FR-FX-1). The backup's schema version is 5; an older file restores as before.
- **Delete everything** (FR-SE-4) wipes the database in one transaction, then the stored preferences (onboarding done, its draft, Look, last-backup date, the install line's *seen* flag), the restore snapshot and every scheduled reminder. It keeps no hidden copy. Backup files the user saved are not touched.
- **CSV export:** entries only, in the same columns as BR-15 (M6; not part of the backup work).
- **Android Auto Backup is off** (`allowBackup="false"` plus `dataExtractionRules` excluding everything), so the only copy of the data that leaves the phone is a backup the user makes (FR-SE-5).

### BR-17 Your usual (D153, D154)
Maths and the quiet states in detail: `docs/superpowers/plans/2026-11-13-your-usual.md` (resolved maths) and `docs/features/habits/03-detection-maths.md`. Times come from the injected `Clock`.
- **Learned entries:** *Spent* entries dated in the 56 days ending today (today − 55 … today) that were logged on the day they were spent (`created_at`'s local date equals `date`), were not posted by a recurring rule and are not *Not logged* entries (BR-18: a hidden-category fix would otherwise count as a learned day for other habits). Entries dated after today are ignored. Editing and Undo keep `created_at` (BR-10), so they never move an entry's time.
- **A habit** is a category plus a day type: weekdays (Mon–Fri) or weekends (Sat–Sun). Hidden categories and the system-hidden rows have none.
- **Time profile:** each learned entry's local `created_at` falls into one of 48 half-hour slots that wrap at midnight. It weighs `0.5^(age_days / 14)` and is smoothed ¼ · ½ · ¼ over its slot and the two beside it. The **window** is the run of slots around the highest slot (the earlier one on a tie) whose weight is strictly above half of it, widened by 15 minutes each side. An entry is **inside** the window when its logged minute is.
- **Regular** when every one holds:
  1. ≥ 14 days since the first learned entry in any category, and ≥ 10 days with a learned entry in any category.
  2. ≥ 5 learned entries of this habit inside the window.
  3. Among the days of this day type in the 28 days before today that have a learned entry in any category, the window was hit on ≥ 60%.
  4. One exact amount is ≥ 70% of the weighted entries inside the window.
  - If a day type fails only rule 2 or 3 **and has at least 2 entries of its own inside the pooled window** in the 28 days before today, the pooled profile (all days) is used for it when it passes all four.
  - A Regular habit whose window was missed on its 3 most recent days of that day type that have any learned entry stops suggesting until it is hit again. Days with no entry are not misses.
- **Suggestion:** that exact amount, never rounded, averaged or raised. It is offered while now is inside the window and the category has no entry dated today (typed or posted). When two qualify, the higher share of days wins, then the more recent hit.
- **Quiet** (kept per category in a `suggestion_state` table, new migration):
  - An Undo after a pill add quiets that category until midnight. A second within 14 days (counting day 14) rests it until the end of the 30th day after it (the day of the Undo is day 0).
  - *Forget* (FR-SE-2 AC-6) ignores that category's entries logged before that moment when working out its own habit, and rests it until the end of the 30th day after. They still count as days with a learned entry for every other habit, as a hidden category's entries do. Undo after Forget puts the earlier state back.
  - **Asked** (D171, D172): `suggestion_state` has a nullable `asked_on` (`YYYY-MM-DD`), the local date the missed-log line was last asked for that category. It is a column of its own because `quiet_on` feeds the 14-day Undo count and reusing it would corrupt that count. Tapping the line, ignoring it and Back write only `asked_on`; none is an Undo, so none rests a habit.
  - The state is backed up, restored and wiped with everything else (BR-16). It holds category ids and dates only.
- **The missed-log line** (D171; shown by FR-HO-3): it asks when all of these hold at an evaluation point (FR-HO-3):
  1. A Regular habit of today's day type, not fading, whose category is shown on Home, with an open gate (no Undo-quiet today, no rest, not forgotten).
  2. The category has no entry dated today, typed or posted.
  3. Now is at least **90 minutes after the window's end**, on the window's own local date. A window that crosses midnight never asks. Inside the window the *your usual* pill already covers the user.
  4. No category has `asked_on` equal to today: one question a day in total.
  - With two qualifying habits the pill's tie-break applies (higher share of days, later hit, lower id). The pure `MissedLogDetector` takes the habit index, `now`, the categories, the `asked_on` dates and the day type, and is tested with `FakeClock` at the 90-minute edge. **Example:** Food's window ends 2:00 pm, so the line can first show at 3:30 pm; one opened at 1:50 pm shows nothing.
- **"Around {time}"** is the hour nearest the window's middle, rounding a half hour up, formatted with `DateFormat.j` for `en_IN` with a plain space ("10 am").
- Everything is worked out on the device. Nothing is logged with amounts or names (NFR-3), and nothing is sent or notified. Ask AI never reads it.

### BR-18 Fix my number (D165–D168, D181)
Design: `docs/features/fix-my-number/` (01 to 05), copy deck [41](design/mockups/41-fix-my-number-copy-deck.md), mockup [41](design/mockups/41-fix-my-number.html). The screens are FR-FX.
- **Idea:** the user says how much of *this cycle's* money they still hold. hisaab compares it with its own figure `H` and adds one entry for the difference. It corrects the pool; it is never a day's spending.
- **Symbols:** `H` is what hisaab expects the user still holds, and `T` is the whole-rupee figure the user typed. (BR-7's `E` and BR-8's `X` keep their meanings.)
```
H   = remaining + B + R
    = I − (S_prev + R_t + F_t + S_today) − (Sv_before + Sv_rule_today + Sv_extra_today)
gap = H − T                       // in paise, from the unclamped H (which may be ≤ 0)
n   = floor(|gap| / 100)          // the rupees posted; n = 0 is "equal"
```
- `H` **keeps** the money earmarked for bills (`B`) and savings (`R`) still to come, because it is still in the account, and **drops** `Sv_before` and today's saves, because a *Saved* entry says the money left. So `H` is the figure the user can read off their bank and cash as "this month's money", with no subtraction on their part: the app does the sums (Tesler). Nothing is stored; `H` is recomputed from the ledger on every key and at the write.
- **Posting:** `gap > 0` (money is missing) posts a *Spent* entry of `n` rupees; `gap < 0` (hisaab under-counted) posts a *Got* of `n`. Both are in the hidden `not logged` category (BR-11), dated today, noted "Not logged", with no `recurring_id`: one entry per *Fix it*. After either, `H = T` to within ₹1, and `remaining' = T − B − R`. There is no limit on fixes per day; a second compares with the ledger as it is, so straight after the first it reads "That matches".
- **Compare states** (the preview, FR-FX-3):

  | State | Condition | *Fix it* |
  |---|---|---|
  | Equal | `n = 0` | Off |
  | Close | `T` is a multiple of ₹100 and `0 < \|gap\| ≤ ₹50`: a rounded answer, so no entry for a few rupees | Off |
  | Lower | `T < H`, beyond *close* | On |
  | Short | Lower, and `T < B + R`: the user holds less than is still due. `m = (B + R) − T`; the hero is ₹0 and the over card (FR-HO-5) follows. It informs and never blocks | On |
  | Over today | Lower, not *Short*, and `A_after < S_today`: the lower share falls below what was already spent today (E75). `o = S_today − A_after`. It informs and never blocks (D190) | On |
  | Higher | `T > H`, beyond *close* and `−gap ≤ I ÷ 10` | On |
  | Large | `T > H` and `−gap > I ÷ 10` (the guard) | On; opens the question |

  - **Per day:** `n_day = |A_after − A_before|`, with `A_after` computed as if the entry were posted. "about" goes on this figure only, because it is a floor; never on the gap, which is exact and is what is posted. When `n_day = 0` the line says "Each day stays about the same.". On the last day (`D = 1`) it says "Today takes all of it." (less) or "Today gets all of it." (more) instead.
  - **`H ≤ 0`** (the month was already overspent): the gap uses the unclamped `H`. Line 1 reads "hisaab thought nothing was left." when `H = 0` and "hisaab thought you were ₹X short." when `H < 0`, with `X = −H`. Only *higher*, *equal* and *close* can then occur, since `T ≥ 0`.
- **The guard** (D167): when `gap < 0` and `−gap > I ÷ 10` (10% of the cycle's income, set by nothing), *Fix it* posts nothing yet and asks "Is all of it from this month?". *Yes, add {gap}* posts the *Got*; *No, some is older* clears the digits and asks again for this month's money. The threshold is the one number in the design that is derived from nothing; a buffer under it passes, is previewed first and can be undone. There is **no guard on a large lower gap** (D167): the preview says "₹45,000 less" in words before saving, and Undo reverts.
- **Stale write:** the save recomputes `H` and the gap in its own write. If either differs from what the user saw (midnight, a bill posted while the sheet was open), nothing is saved, the preview refreshes and the slot says "Things changed. Check the new amount."
- **Where a fix goes in the other rules:**

  | Rule | Effect |
  |---|---|
  | BR-3, BR-4 | *Spent* fix = `F_t`; *Got* fix in `I`. `K`, `B`, `R`, `Sv_*`, `R_t` are untouched. `S_today` and `overToday` never include it |
  | BR-5, BR-6, BR-6a | Never a bite, never in a day's bar; in the pool of the day it is dated and after. State 2 through `remaining`; state 3 only if the lower `A` falls below what was already spent today (E75) |
  | BR-7, BR-8 | Not in `V_prev` or `S_yesterday`; in `A_yesterday` as pool |
  | BR-9 | Not a rule's entry |
  | BR-12 to BR-14, FR-SP-4a | Out of limits, bars, percentages and insights; its own part on the Spends line (*Spent* side) |
  | BR-15, BR-16 | An ordinary entry in the CSV (category `not logged`); the explaining clause; backed up and wiped with everything |
  | BR-17 | Not a learned entry; never forms or feeds a habit, never triggers the missed-log line |
  | FR-WG | The snapshot is rewritten after the write like any entry, so the widget shows the new hero |

- **Edit and delete:** never edited in the tray (BR-10). Delete with Undo and the number reverts exactly (it was computed, never stored). A fix is dated today only; no date picker. A fix is never dated in the previous cycle; on day 1 of a cycle it is valid, and the user's account then holds last cycle's leftover, so a *higher* figure there is the buffer case the guard asks about.
- **Worked example** (`I = 45,000`, `K = 0`, cycle 4 Oct to 3 Nov, `t` = Mon 26 Oct, `D = 9`, `B = 1,200`, `S_prev = 27,150`, ₹420 spent today). Before any fix: `P = 16,650`, `A = 1,850`, hero ₹1,430, `remaining = 16,230`, so `H = 16,230 + 1,200 = ₹17,430` (check: `45,000 − 27,150 − 420`). The guard line is `I ÷ 10 = 4,500`.

  | Case | Types `T` | `gap` | Posts | `P` | `A` | Hero | `remaining` | Preview line 2 |
  |---|---|---|---|---|---|---|---|---|
  | 1 Forgot ₹4,200 | 13,230 | +4,200 | *Spent* 4,200 | 12,450 | `floor(12,450 / 9)` = 1,383 | `1,383 − 420` = **963** | 12,030 | "That's ₹4,200 less. Each day gets about ₹467 less." |
  | 2 Under-count ₹1,000 | 18,430 | −1,000 | *Got* 1,000 | 17,650 | `floor(17,650 / 9)` = 1,961 | `1,961 − 420` = **1,541** | 17,230 | "That's ₹1,000 more. Each day gets about ₹111 more." |
  | 3 ₹30,000 buffer, typed the total | 47,430 | −30,000, over 4,500 | the guard asks; *Yes* posts *Got* 30,000 | 46,650 | 5,183 | 4,763 | 46,230 | "That's ₹30,000 more. One question first." |
  | 3, then *No* and this month's only | 17,430 | 0 | nothing | 16,650 | 1,850 | 1,430 | 16,230 | "That matches. Nothing to fix." |
  | Same, close | 17,400 | +30 | nothing (a rounded answer within ₹50) | | | | | "That's close enough. Nothing to fix." |
  | Short of what's still due | 1,000 | +16,430 | *Spent* 16,430 | 220 | 24 | ₹0 | −200 | "That's ₹16,430 less, and ₹200 short of what's still due." The over card says *Over by ₹200 this cycle* |

  Case 3 *Yes* would have made every day ₹3,333 bigger (`30,000 / 9`) for money the pay never funded: the guard is why that path asks.
- **Mid-cycle install** (`I = 45,000`, `B = 1,200`, `S_prev = 0`, nothing spent today, `t` = 26 Oct; 36,000 was already spent before hisaab was installed): `P = 43,800`, `A = floor(43,800 / 9) = 4,866`, `H = 43,800 + 1,200 = 45,000`. The user types the ₹9,000 of this month's pay that is left: `gap = 36,000`, `F_t = 36,000`, `P = 7,800`, `A = 866`, hero ₹866, `remaining = 7,800 = 9,000 − 1,200`.
- **Last day** (`D = 1`, `t` = 3 Nov, `I = 45,000`, `K = B = R = 0`, `S_prev = 43,150`, ₹420 spent today): `P = A = 1,850`, hero ₹1,430, `remaining = 1,430 = H`. The user types `T = 930`: `gap = 500`, `F_t = 500`, `P = A = 1,350`, hero `1,350 − 420 = 930`. Today falls by exactly the gap, so line 2 reads "That's ₹500 less. Today takes all of it."
- **With a yearly saving** (BR-19's inputs: `K = 1,000`, so `P = 15,650`, `A = 1,738`, hero ₹1,318, `remaining = 15,230`): `H = 15,230 + 1,200 + 0 = ₹16,430` (check: `45,000 − (27,150 + 420) − 1,000`). The user types 12,230: `gap = 4,200`, `P = 15,650 − 4,200 = 11,450`, `A = floor(11,450 / 9) = 1,272`, hero `1,272 − 420 = ₹852` (each day about ₹466 less), `remaining = 11,030 = 12,230 − 1,200`. A *Used* entry afterwards moves none of these terms.
- **`H ≤ 0`:** with `H = −300` and `T = 2,000`: line 1 "hisaab thought you were ₹300 short.", `gap = −2,300`, line 2 "That's ₹2,300 more.", a *Got* of ₹2,300 (under 4,500, so no guard). With `H = 0`, line 1 is "hisaab thought nothing was left."

### BR-19 Used from savings (D174, D175)
Design: `docs/features/yearly-costs/01-ux-flow.md`, mockup [42](design/mockups/42-yearly-costs.html). The screens are in FR-SE-1 (Savings).
- **The entry:** kind `used`, in the hidden `saved` category (export name `savings`), dated today, whole rupees from 1 up to what the saving has set aside, note the saving's name, and `saving_id` the saving's rule id. It is a **fourth entry kind that touches no BR-3 symbol**: the money left `K` when it was put in, and put-ins from past cycles are not in this cycle's `I` or `K`, so paying from the pot moves nothing. The bank falls; the hero doesn't.

  | Entry | `I` | `K` | `B` | `S_prev` | `S_today` | `R_t` | `remaining` | Put in | Set aside |
  |---|---|---|---|---|---|---|---|---|---|
  | *Spent* | | | | in | in | | in | | |
  | *Saved* (rule) | | in | | | | | | + | + |
  | *Saved* (extra) | | in | | | | | in (today) | + | |
  | ***Used*** | no | **no** | no | **no** | **no** | no | **no** | no | **−** |

- It never reaches BR-4 to BR-8 (pace counts *Spent* only; the morning note rebuilds without it), BR-12 to BR-14, BR-17, the Spends line, the bars, the week bars or the pace chart. *Why not a negative *Saved*:* it would drop `K` and make the hero jump. *Why not *Spent*:* it would land in `S_today`, read "over today" and put saving into *Where it went*.
- **Set aside**, per saving: `Σ Saved entries posted by that saving's rule − Σ Used entries with its saving_id`, floored at ₹0, computed and never stored (D120). *Still set aside* is the sum over **active** savings. *Put in since* stays gross (money put in is never reduced by a use). *Put in extra* belongs to no saving, so it adds to *put in since* and never to a set-aside amount.
- **Worked example** (`I = 45,000`, `B = 1,200`, `S_prev = 27,150`, cycle 4 Oct to 3 Nov, `t` = 26 Oct, `D = 9`, ₹420 spent today). An *Insurance* saving of ₹1,000 on the 5th started 5 Nov 2025, so it has put in 12 times (₹12,000, 5 Nov 2025 to 5 Oct 2026). This cycle's put-in was 5 Oct: `Sv_before = 1,000`, `R = 0`, `K = 1,000`.

  | Step | `K` | `P` | `A` | Hero | `remaining` | `tomorrow` |
  |---|---|---|---|---|---|---|
  | Before | 1,000 | `45,000 − 1,000 − 1,200 − 27,150` = 15,650 | `floor(15,650 / 9)` = 1,738 | `1,738 − 420` = **1,318** | 15,230 | `floor(15,230 / 8)` = 1,903 |
  | *Used* ₹12,000 | 1,000 | 15,650 | 1,738 | **1,318** | 15,230 | 1,903 |

  Nothing moved. The list's footer then reads "₹12,000 put in since Nov" and "Nothing is set aside now."; the Spends line reads "Spent ₹27,570 · Saved ₹1,000" (`27,150 + 420`), with no *Used* part. Wrong models: as *Spent*, `S_today = 12,420`, the hero is ₹0 and "₹10,682 over today", `remaining = 3,230`; as a negative *Saved*, `K = −11,000`, `P = 27,650`, `A = 3,072` and the hero would rise to ₹2,652 for money that is gone.
- **Over the balance** (D175, refuse): a premium of ₹15,000 with ₹12,000 set aside cannot be recorded as *Used* beyond ₹12,000: the keypad refuses the digits (FR-SE-1, FR-KS-2). The user records ₹12,000 *Used* and adds the other ₹3,000 in Add, *Bills*: `S_today = 3,420`, `A = 1,738`, so the hero is ₹0 and "₹1,682 over today", `remaining = 15,650 − 3,420 = 12,230`, `tomorrow = floor(12,230 / 8) = 1,528`. The existing over-today state says it; the later days share the cost. The excess-as-*Spent* alternative is rejected: it needs a rule so the excess doesn't read "over today".
- **Delete and restore:** swiping a *Used* row deletes it with Undo (BR-10); the amount is set aside again. Deleting the saving afterwards keeps every entry, so *put in since* keeps its history, but the deleted saving leaves *still set aside* and *Used* is no longer reachable: use it first, or Undo the delete. Backup and restore carry `used` entries with their `saving_id` (BR-16).

### BR-20 Month story (D193, D194)
Design: case study 37, mockup [45](design/mockups/45-month-story.html). The screens are in FR-SP-7.

- **Which cycles get one:** the cycle has ended (`today > end`), it lasts at least 28 days (weekly cycles never do), and it holds at least 10 entries of any kind.
- **Numbers.** Every number is computed when the story opens, never stored. For a cycle `C`:
  - `I` = Σ *Got* in `C`.
  - `Sv` = Σ *Saved* in `C`.
  - `B` (*Bills*) = Σ *Spent* posted by a rule (`recurring_id` set), not *Not logged*.
  - `E` (*Everyday*) = Σ *Spent* typed by the user (`recurring_id` null), not *Not logged*.
  - `NL` = Σ *Spent* *Not logged*.
  - **Spent** = `B + E`. This is Spends' own *Spent* (FR-SP-4a), which leaves out *Not logged*.
  - **Left** `L = I − B − E − NL − Sv`. *Not logged* is money that went, so it comes off what was left.
  - *Used* and card bills paid touch nothing (BR-19, D123).
- **Pages**, in this order. A page whose condition fails is left out, not shown empty.
  1. **The month:** the cycle's name (as FR-SP-1 names it), its first and last days, the number of days and the number of entries.
  2. **What you kept:** "You spent ₹{B + E}" and, when `I > 0`, "of ₹{I} that came in".
     - **The bar** has these parts: *Bills*, *Saved* (at least 12dp wide when above ₹0, so it never vanishes beside the track), *Everyday* with *Not logged* in the same fill, then *Left over* as the empty track with an `ink2` edge. This is the order of the Spends split bar (mockup 46).
     - **The headline** is "₹{L} left over" when `L ≥ 0`, or "₹{−L} more than came in" when `L < 0`. In the second case, the part past `I` is striped.
     - **The line under the headline** is "and ₹{Sv} saved", shown when `Sv > 0`.
     - **With no income** (`I = 0`), the page shows the spend alone, with no bar and no headline.
  3. **Where it went:** *The most went on {top category}* and every row of FR-SP-4 (BR-13 shares), biggest first.
  4. **Your days**, shown when at least 7 days have *Everyday* spending.
     - **The bars:** one bar per day of `E` (bills and *Not logged* are left out).
     - **The daily share** is `share = floor((I − Sv − B) / days)`. There is no share when it is ₹0 or less.
     - **Biggest day:** the day with the most `E`, the earliest on a tie. It is named by the note of its biggest entry, or by that entry's category name when the entry has no note.
     - **Quiet days:** the days with no `E`.
     - **Weekday line:** the weekday whose `E` adds up to the most, shown only when it holds at least 35% of all `E`. It reads "Your {n} {weekday}s came to ₹X", where `n` is how many of that weekday the cycle has.
  5. **Against {previous cycle}:** shown when the previous cycle was fully tracked (BR-14 #1's rule) and has *Spent*.
     - **Change** `Δ = Spent(C) − Spent(previous)`, read as "₹X less than", "₹X more than" or "The same as".
     - **Moves:** the three biggest per-category changes by size, leaving out zero changes. Ties go to the bigger amount in `C`, then the category order.
  6. **The end:** Spent, Saved (when above ₹0) and *Left over* or *More than came in* (when `I > 0`), then *Ask an AI about {cycle}* and *Done*.
- **Counts, never labels** (principle 94, D193): every sentence is an amount, a count or a date. Nothing praises or warns, and nothing names a habit.
- **Worked example:** September, Fri 4 Sep to Sat 3 Oct 2026, 30 days, 31 entries (pay, the RD, two bills and 27 everyday spends on 21 days; test fixture `september_story.dart`).
  - **Inputs:** `I = 45,000`, `Sv = 1,000`, `B = 9,400` (rent ₹8,200 and electricity ₹1,200), `E = 30,200`, `NL = 0`.
  - **Page 2:** Spent ₹39,600. `L = 45,000 − 9,400 − 30,200 − 0 − 1,000 = 4,400`, so "₹4,400 left over" and "and ₹1,000 saved".
  - **Page 3:** Food ₹12,100 (30%), Bills ₹9,400 (24%), Travel ₹7,300 (18%), Shopping ₹6,200 (16%), Fun ₹3,100 (8%), Health ₹1,500 (4%).
  - **Page 4:**
    - `share = floor((45,000 − 1,000 − 9,400) / 30) = 1,153`.
    - The biggest day is Sat 12 Sep, ₹4,850, *Train tickets*.
    - 9 days have nothing spent.
    - The 5 Saturdays (5, 12, 19 and 26 Sep, 3 Oct) add up to ₹15,840. That is 52% of ₹30,200, so the line shows: "Your 5 Saturdays came to ₹15,840."
  - **Page 5:** August spent ₹47,100, so "₹7,500 less than August". The moves are Shopping ₹3,900 less, Food ₹2,200 less and Fun ₹1,600 less (Travel's ₹1,200 more is fourth, so it is left out).
  - **Over income:** August itself (`B = 9,400`, `E = 37,700`, `Sv = 1,000`) gives `L = −3,100`, so "₹3,100 more than came in".


### BR-21 Spends breakdown (D195, D196)
Design: mockup [46](design/mockups/46-spends-graphs-v2.html), its copy deck and accessibility review. The screens are in FR-SP-3a, FR-SP-4, FR-SP-4b and FR-SP-8. Every number is computed when Spends loads, never stored.

- **The split** of the cycle shown, over its entries up to the day it is seen from, uses BR-20's symbols:
  - `I`, `Sv`, `B`, `E` and `NL` are as in BR-20.
  - `L = I − B − E − NL − Sv`.
  - Bills and savings still to come are not in it; it measures what was logged.
- **The comparison** needs the cycle before to have been fully tracked (BR-14 #1's rule).
  - On the current cycle it is `Δ = Spent(C, up to today) − Spent(P, up to day min(k, length(P)))`, where `k` is today's day of the cycle, as BR-14 #1 counts it.
  - On a finished cycle it is the whole cycle against the whole cycle before.
  - *Spent* is Spends' own (BR-20).
  - The comparison is not shown when both amounts are ₹0.
  - Under ₹100 apart reads as *the same*.
- **A row's change** is the same comparison for one category. It shows only when the comparison does.
- **A row's entries** are its *Spent* entries (not *Not logged*), biggest first. A tie goes to the earlier day, then to the entry saved first. At most 3 show, with the count.
- **The strip** is a window of up to 6 cycles ending at the cycle shown, each one that ended on or after the first day anything was logged.
  - Each cycle has its own `Spent`, `Sv`, `I` and `L`.
  - It shows when the window holds at least 2 finished cycles and the cycle shown has `I > 0`.
  - **The count** is of finished cycles with `I > 0`. A cycle is *left over* when `L > 0`.
- **Worked example**, the SPEC's October on Mon 26 Oct, with September from BR-20 and ₹1,000 saved on 5 Oct:
  - **The split:** `I = 45,000`, `B = 8,200`, `E = 19,370`, `Sv = 1,000`, `NL = 0`, so `L = 16,430`: "₹16,430 not spent yet".
  - **The comparison:** today is day 23. September's day 23 is Sat 26 Sep, and BR-20's September had spent ₹32,330 by then (rent ₹8,200 and ₹24,130 everyday). So `Δ = 27,570 − 32,330 = −4,760`: "₹4,760 less than by this day in September." (Mockup 46's ₹2,100 was illustrative.)

---

## 4. Functional requirements

Acceptance criteria are written as Given / When / Then. Copy in quotes is the English ARB value.

### 4.1 Onboarding (FR-ON)
- **FR-ON-1** A fresh install opens onboarding. A finished onboarding never shows again unless the user deletes everything (FR-SE-4).
  - Step 1 has a quiet *Restore a backup* text chip on its own row at the top end (TalkBack: "Restore a backup from another phone"). It is a way out, not a question: onboarding still asks three. It is never marigold.
  - A valid file restores straight away (BR-16, no dialog) and lands on Home. An invalid or newer file keeps the user on step 1 with BR-16's snackbar.
- **FR-ON-2** Step 1 asks "How much money comes in each month?" with the keypad open. The hint names money, not a job, so it fits salaried, self-employed, gig, pension and family money alike: "Pay, business, pension or family money. If it changes, a low month is a safe guess. Paid weekly? Add up a month." Between the keypad and Next, a lock and "What you type stays on this phone. The app never uses the internet." (DECISIONS D116).
  - Given 45000 is typed, then the preview reads "That's about ₹1,500 a day", captioned "Every day gets its own share". This is `floor(amount / 30)`, for the preview only.
  - Next is enabled only when the amount is greater than 0.
- **FR-ON-3** Step 2 asks "When does it come?" with five chips: *1st of the month*, *Last day of the month*, *Pick a date* (day 1–31), *Every week* (weekday), *It changes*. The hint reads 'Your month runs from one payday to the next. No fixed day? Pick "It changes".' Selecting a chip advances. A decorative picture fills the space above the chips and the day pickers, and is left out when that space is under 120dp (D144).
- **FR-ON-4** Step 3, "Any fixed bills?", offers chips (Rent, EMI, Phone, Internet, School fees, Subscriptions) that each open a mini keypad and a due day. **Skip** is always visible. A decorative picture fills the space above the chips, under the same rule as FR-ON-3 (D144).
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
- **FR-HO-3** **The nudge slot** shows one line, the first that applies of four: a bill **waiting** for its amount (BR-9), the due-soon nudge, the **install line**, the **missed-log line**, else nothing (D123, D170). The saved-yesterday note (BR-8) is not a slot item: it sits above the slot and never silences a line.
  - **Waiting:** "Electricity went out today. How much?" ("…went out on 24 Oct. How much?" for an earlier day); a card bill reads "Credit card bill is due today. How much did you pay?" ("…was due on 24 Oct…"), naming the card. The oldest waits first; on a tie, the rule saved first. It has the due-soon row's shape and edges; TalkBack reads the sentence, then "Opens the keypad." A tap opens the bill amount sheet (FR-HO-8).
  - **Due-soon nudge** (BR-9), when applicable. It is a tappable `sunk` row at least 56dp tall: the bill's icon in a well, the sentence, the date under it, and a chevron. TalkBack reads the sentence, then "Opens the bill." ("Opens the saving." for a saving, D120). A tap opens that bill's or saving's sheet (FR-SE-1) over Home. After a change Home reloads; *Delete bill* deletes it from Home with Undo (D35, D118).
  - **Install line** (D169): "Already spent some this month?" ("this week" for a weekly cycle) with "Fix my number" under it, in the due-soon row's shape. TalkBack reads one node: "Already spent some this month? Fix my number. Opens the keypad." A tap opens FR-FX. It is a pointer, not an onboarding question (Q6).
    - **AC-1** It shows only when the first Home visit's cycle started before the install day, taken as the local date of the earliest entry's `created_at` (`MIN(created_at)`, as D39; `recurring` has no `created_at`, and onboarding saves its first entries on the install day) (no new column), and only in that cycle.
    - **AC-2** It shows once. *Seen* is written when the line is on screen with Home visible and no tray or sheet over it, and it never returns after that, tapped or not. A bill line holding the slot, a tray over Home or an over state means it was not seen, so it waits. Any *Not logged* entry consumes it. The flag is backed up, restored and wiped with everything else (BR-16).
  - **Missed-log line** (D171): "Spent on {Category} today?" with "Usually around 1 pm." under it, when BR-17's rules hold. It is a `sunk` row at least 56dp tall, the due-soon row's shape: a neutral question glyph in a `surface` well (never the category's glyph, so it can't read as a logged entry), the two lines (the category name is never cut) and a chevron. It shows no amount and has **no ×**. Pressed it fills `hairline`; hovered or focused on a large screen, a 1dp `ink2` outline and the focus ring. Never marigold.
    - **AC-1** Home is ready, not *No income* and not in an over state, and no waiting, due-soon or install line holds the slot. In an over state and in *No income* it waits.
    - **AC-2** A tap fires `tick` and opens the Add tray at step 1 (₹0, *Spent*, dated today) carrying this habit, so the *your usual* pill shows outside its window (FR-AD-10 AC-1). The category is not pre-selected on step 2; no tap is added to Add and nothing is reordered. A second tap is ignored until the tray has closed.
    - **AC-3** Back without saving (system back, drag down, scrim) removes the line: the tap answered the day's question, and a line that came back would be a repeat. No haptic. The slot collapses after the tray has closed; after a save the collapse finishes no later than the drain. It also leaves when an entry in that category is logged by any door, when the category goes quiet or is forgotten, and at midnight.
    - **AC-4** *Asked* (`asked_on`, BR-17) is written only when the line is on screen with Home visible and no tray or sheet over it. A line drawn under a door-opened tray is **not asked**, and the tray's close can only remove it, never add it.
    - **AC-5** TalkBack reads one button, "Spent on Food today? Usually around 1 pm.", then "Opens the keypad.". It is not a live region and announces nothing on appearing or leaving.
    - **AC-6** Habit-derived Spends insights (BR-14 gains none yet) wait while the line shows, in a single pane only; in two panes both panes are on screen and they do not wait (D173).
  - **When a line is decided (D170):** the install and missed-log lines are decided at an *evaluation point* only: a cold start, a resume, or the resume a door-opened tray causes (widget, tile, shortcut). Not rebuilds, ledger ticks, rotation, a fold, or the clock passing the 90-minute mark. A user's own act can make them leave, never appear, so closing a bill sheet never brings one in behind it. Like the *your usual* pill, a line is in Home's first frame or waits for the next point; if the habits load after the first frame on a cold start it is missed for that open, with no pop-in.
  - **Order stays stable:** a bill line (waiting, due-soon) may arrive at any reload, because the money guarantee outranks calm. When a higher item clears mid-day the slot collapses to empty and the next lower item does **not** slide in; it waits for the next evaluation point. When a higher item arrives while a lower line is showing (midnight), the higher takes the slot. No count and no badge ever shows ("2 more").
  - **Focus:** when the opener was the install or missed-log line and it is removed, focus goes to the node now in its place, the "Today" heading, never to the top of the page.
- **FR-HO-4** **Today list:**
  - The header shows today's total (typed spending, `S_today`) and *See all*.
  - A bill the app posted or the user entered is listed like any entry; with no note, its second line is the bill's name ("Bills · Electricity", "Home · Rent"), or *Bill* once the bill is deleted (D119, D123, D127).
  - A card bill paid reads the card's name, *Paid, not counted again* and the amount, with the card glyph. It is never a bite on today's bar, is not in today's total, and has no tap; swiping deletes it with Undo, and the bill waits again (D123).
  - A saving reads its name (or *Put in extra*), *Saved* and the amount, with the piggy-bank glyph. It is never a bite on today's bar and has no tap; swiping deletes it with Undo (D120).
  - A fix reads two lines (D166, D176): line 1 "Not logged", line 2 "Spent" or "Got" (direction is a word, never a sign or colour), the amount at the end, with a neutral glyph. TalkBack: "Not logged. Spent 4,200 rupees." / "Not logged. Got 1,000 rupees.". It is never a bite, not in the header total, has no tap and no tint; swiping deletes it with Undo.
  - A *Used* entry reads two lines too: line 1 the saving's name ("Insurance"), line 2 "Used from savings", the amount at the end, with the piggy-bank glyph. TalkBack: "Insurance. Used from savings 4,000 rupees.". Same rules as a fix: no bite, not in the total, no tap, swipe to delete with Undo.
  - Both kinds sit in the list in time order with the other entries (a fix posted now is on top) and count among the 5; each also exposes *Delete* as a custom semantics action (BR-10).
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
  - **AC-6** Back while *Save* is still writing closes the sheet, and the save still ends with its Undo on Home. An Undo offered while Home can't show (still loading, or a failed reload) waits for Home's next good load (D127).
  - **AC-7** Its content starts on the page gutter (D122).
  - **AC-8** Home holds its numbers while the sheet covers it and recomputes once the sheet has fully closed (the hold of FR-AD-5; D179). Before this a bill entered from Home drained under the scrim.
- **FR-HO-9** **The foot row** (D169): one quiet text row, "Fix my number", at the end of Home's scroll below the Today list and *See all*.
  - **AC-1** It has no fill, no icon well and no second line or count, sits in `ink2` and is 48dp or taller. It must not look like the nudge slot's `sunk` row, which would read as a nudge that never leaves. TalkBack: "Fix my number, button. Opens the keypad."
  - **AC-2** It is always there once Home is ready, including the over states (where the over card keeps *See where it went* as its one next step, and the foot row is not a second one). It is hidden in *No income* (BR-5 #1) and while Home loads or has failed.
  - **AC-3** A tap opens the Fix my number sheet (FR-FX). It moves nothing above it: the dock and the Add key stay put. A snackbar may cover it for 4 s; with TalkBack it stays until dismissed.

### 4.3 Add tray (FR-AD)
- **FR-AD-1** Step 1, amount:
  - *Spent* / *Got* segmented control, with *Spent* selected by default.
  - Phone-layout keypad with `00`, `0` and ⌫. Long-pressing ⌫ clears the amount.
  - Quick chips +₹10 / +₹20 / +₹50 / +₹100 / +₹500 **add** to the amount.
  - Under the amount, a slot at least 48dp tall holds the *your usual* pill (FR-AD-10) or the preview (FR-AD-3), never both. Showing or hiding the pill never changes its height (D153, D154).
  - **Fit (D192):** when the tray's box is at least 360dp wide and shorter than the header plus the stacked keypad and *Next* (scaled by text size), step 1 lays out side by side (amount, chips and slot beside a 48dp-key keypad), as FR-KS-1 does for keypad sheets; nothing is reordered and no tap is added. Under 240dp the Spent | Got switch shares the width, and under 280dp the quick chips wrap. In a compact-height window the tray drops its 72dp top gap, and under 600dp tall it draws no drag handle (E115). Tested at 960×600, 915×412 and 412×400.
- **FR-AD-2** Input rules:
  - Leading zeros are ignored.
  - A 10th digit is rejected with a head-shake and the reject haptic, **and** a 2dp ring held on the amount until the next accepted key, **and** a one-shot polite announcement, "That's the most you can type." (no visible words; D184, FR-KS-2). Before this the reject had no signal that survives reduced motion or haptics off.
  - There is no decimal key.
  - The amount shows live Indian grouping.
- **FR-AD-3** A helper line in the slot (FR-AD-1) previews the effect, for example "₹1,020 over today's share · tomorrow's share ₹1,722", using BR-4 with the typed amount.
- **FR-AD-4** **Next** is enabled when the amount is greater than 0 and opens step 2. The tray shortens, and the amount flies up into the title.
- **FR-AD-5** Step 2 shows a 2×4 grid of the built-in categories for *Spent*, then the user's own in row 3 and a *New* tile (FR-AD-9), or the *Got* categories, plus *Today ▾* and *Add a note* chips. **Tapping a category tile saves**, then:
  1. The tile flashes (120 ms).
  2. The tray closes.
  3. Once the tray has fully closed, Home recomputes. Today's block drains and the hero number rolls to its new value, starting in the same frame. While the tray covers Home, Home holds its last numbers (D91).
  4. The success haptic fires.
  - **The hold covers every sheet opened from Home** (D179, widens D91): the Fix my number sheet (FR-FX), the *Used* sheet and bill sheet from the due-soon row, and the waiting-bill amount sheet (FR-HO-8, also from a reminder tap). Home is told before the sheet opens and again after its route has completed, in a `finally` so an error can't leave Home frozen; Back while writing releases it at the route's completion, so the write lands with Home in view. Two holds can overlap (a door that pops one tray and opens another), so the hold is a **count**: Home reloads when it reaches zero. A sheet opened from Settings sends no hold: Home is not under it.
  - **`success` fires with the first visible change** (D183): at the same frame as the roll when Home is under the sheet, and as the exit starts when nothing visible follows (the Settings door).
- **FR-AD-6** Double-taps while saving are ignored. If the save fails, the tray stays open with "Couldn't save. Try again." and nothing is lost.
- **FR-AD-7** Back from step 2 returns to step 1 with the amount intact. Back from step 1 closes the tray without saving.
- **FR-AD-8** Edit mode opens step 1 prefilled. Saving replaces the entry, and *Delete* is shown in step 2.
- **FR-AD-9** New category (D138, mockup [33](design/mockups/33-own-categories.html)):
  - **AC-1** On *Spent*, a dashed *New* tile sits in the first free slot after the 8 built-in tiles and the user's own, under a "Your own" rule. With 4 of the user's own it is gone, and one line reads "4 of your own is the most. Hide one in Settings to make room." No category tile ever moves.
  - **AC-2** Tapping *New* replaces the grid with a name step inside the tray: the amount stays in the title, "What's it called?" under it, a focused name field with the keyboard up, and 6 name chips (Groceries, Kids, Family, Pets, Petrol, Salon) that narrow to what is typed and leave out names already shown. A chip tap fills the field.
  - **AC-3** A line under the field shows the icon the name picks ("Icon from the name: Fuel", or "The name picks an icon" while empty) and a *Change* link. *Change* opens the icon step: the curated icons in their groups, each with its word under it, the current one picked. A tap picks and returns to the name step without saving; picking the name's own icon goes back to following the name.
  - **AC-4** The tray's marigold key reads *Save in {name}* and is disabled while the name is empty. Saving finds or makes the category, then saves the entry in it, and FR-AD-5's close sequence runs. If the entry's save fails, the category stays and the name step shows "Couldn't save. Try again."; trying again saves into it, since the name now matches. A name that matches an existing category reads *Save in {that name}*, says "You have Food already. It saves there." (or "You hid Gym. Saving brings it back."), and saves there.
  - **AC-5** Back closes the keyboard first, then returns to the grid with the amount intact; back from the icon step returns to the name step. What was typed is kept until the tray closes.
  - **AC-6** Double-taps while saving are ignored. A failed save keeps the name step open with "Couldn't save. Try again." and nothing is lost.
  - **AC-7** TalkBack reads "New category, button", "Name for the new category, edit box", "Icon, Fuel, from the name. Double tap to change" and "Save 250 rupees in Petrol"; the "Your own" rule is not read.

- **FR-AD-10** *Your usual* (D153, BR-17, mockup [40](design/mockups/40-your-usual.html)):
  - **AC-1** Shown only for a new *Spent* entry at ₹0 before any input, dated today, when BR-17 has a suggestion **or the tray was opened from the missed-log line for that habit** (FR-HO-3; the pill then shows outside the habit's window). Never in edit mode (FR-AD-8) or on *Got*. It is read in the tray's first frame and never appears late. A tray opened by the app shortcut or the Quick Settings tile on a cold start waits for the habits to load, so it shows the pill too; after 1 s it opens without it (D156).
  - **AC-2** A fully round pill centred in the slot, 40dp tall and growing with text up to the slot's 48dp, with a 48dp touch target: a 1dp `ink2` edge on `surface`, no fill, never marigold; the category icon (20dp), "{category} {amount} · your usual". If one line can't hold it, "· your usual" drops; if it still can't, nothing is shown.
  - **AC-3** Any input (a digit, a chip, ⌫, a long-press clear, switching to *Got*) crossfades it to the preview in 150 ms with no height change. It doesn't come back until the tray opens again.
  - **AC-4** A tap saves that amount in that category, today, with no note. The pill fills `ink` for 120 ms, FR-AD-5's close sequence runs, and BR-10's snackbar offers Undo. Double taps are ignored. A failed save keeps the tray open and the pill reads "Couldn't save. Try again."; a tap tries again.
  - **AC-5** TalkBack reads one button: "Add {category}, {spokenAmount}, your usual".

### 4.4 Spends (FR-SP)
- **FR-SP-1** A cycle switcher `‹ October ›` shows the current and earlier cycles. Next is disabled on the current cycle.
  - A cycle is named after the month holding most of its days, with the year when it isn't this year; a weekly cycle by its dates (DECISIONS D52).
  - Earlier is enabled while the cycle before has entries, or the app was in use before it ended.
  - An empty cycle reads "Nothing spent in October yet." (a finished one "Nothing was spent in September.") and hides the chart and the list.
- **FR-SP-2** The **Ask AI** card at the top opens FR-AI for the cycle shown. It shows only when that cycle has spends (DECISIONS D53, D61). It reads "Ask an AI about October", with "You'll see exactly what it gets." below in smaller grey text; TalkBack reads both as one button (DECISIONS D70).
- **FR-SP-3** **Pace chart:**
  - The cumulative *Spent* line (solid ink; it leaves out *Not logged*, as BR-7's pace does, D166) against the steady-pace line (dotted) from (start, 0) to (end, `I − K`), with `K` computed from the cycle's savings, posted or still to come (D120).
  - The steady line steps up by each bill on its own day: bills already posted, and on the current cycle the bills still to come (a changing bill at its estimate; never a card bill, D123). Between bills it rises by an even daily share of the rest: `steady(d) = bills due by d + floor((I − K − all bills) × (d + 1) / days)`, the share counted as ₹0 when the bills reach `I − K`. Worked example: rent ₹8,200 on 5 Oct and electricity ₹1,200 on 29 Oct give `steady(26 Oct) = 8,200 + floor(35,600 × 23 / 31) = ₹34,612`, so ₹27,570 is *Spending slower* (D129).
  - Fixed y-axis gridlines at ₹0 and at round thirds of `I`, labelled in compact `en_IN` (₹20K) just above each line at the plot's left edge; ₹0 is the unlabelled baseline (D135).
  - A "Spending slower" or "Spending faster" verdict with a glyph (DECISIONS D77).
  - A today marker in marigold.
  - On the current cycle (D133, mockup [31](design/mockups/31-pace-chart.html)):
    - **Gap:** a bracket from today's point to the steady line: spending so far less `steady(today)`.
    - **Forecast:** a dashed line from today's point, labelled *At this pace* in the key: spending so far, plus BR-7's `pace` a day (floored to the rupee), plus each bill still to come on its day. It ends at the cycle's last day (BR-7's spare); or, when BR-7 says it runs out, where it meets `I − K` (or on the run-out day), with a ring. Its numbers are BR-7's, computed by the same function as Home's range line, so the two never disagree. Hidden while BR-7 is too early (`E < 3`).
    - **In words** (D135): one line under the key says the gap and the forecast, "₹7,042 under steady pace. At this pace about ₹9,300 spare." (or "₹1,958 over steady pace. At this pace it runs out on 1 Nov."; the forecast sentence is left out while BR-7 is too early). No amount is painted on the plot.
    - **TalkBack** adds the same two sentences after the verdict, with spoken amounts: "7,042 rupees under steady pace. At this pace about 9,300 rupees spare." (or "…it runs out on 1 Nov.").
  - **Height** (D135): 0.6 of the card's width, kept between 168 and 216dp; 160dp in a window under 480dp tall. All text on the chart follows the phone's text size.
  - **Dates:** a row under the plot (the plot keeps its height) with the cycle's first and last days and, on the current cycle, *Today* under today's point; a date that would touch *Today* gives way to it.
  - Labels sit every 1, 2 or 5 × 10ⁿ rupees from a third of `I − K` (₹45,000 gives ₹0 / ₹20K / ₹40K), up to the larger of `I − K` and the spending. When spending runs far past `I − K`, the step moves up the same ladder so at most 4 labels sit above ₹0 (₹3,000 with ₹5,00,000 spent gives ₹0 / ₹2L / ₹4L). Without income there is no steady line, so only the total shows (DECISIONS D49, D115).
  - Verdict: *Spending slower* when spending so far is at or under the steady line on the same day. Rent posted on day 2 with nothing else spent is *Spending slower*.
- **FR-SP-3a** **The comparison line** (BR-21, D195) sits in the pace card, under the total.
  - **Wording:** "₹2,100 less than by this day in September." On a finished cycle it reads "₹7,500 less than in August.". Under ₹100 apart it reads "Same as …", and against a weekly cycle "the week before".
  - **The arrow:** an arrow glyph sits beside it, hidden from TalkBack. There is no colour and no good or bad word.
  - **When it is left out:** when the cycle before was not fully tracked, and when both amounts are ₹0. Nothing takes its place.
  - **TalkBack:** the pace card reads the line with spoken amounts after its verdict.
- **FR-SP-4** **Where it went:** categories sorted by amount, showing icon, name, % (BR-13), ₹, and a bar with an optional limit tick (BR-12). When any bar is hatched, one line under the rows reads "Striped part is over the limit." (hidden from TalkBack, since each row says "over limit") (D110).
  - **AC-R1 Headline (D195):** one line above the rows, "The most went on Food." When one category holds everything, it reads "All of it went on Food.".
  - **AC-R2 Opening a row:** a row is a button with an expanded state and a caret. Tapping it opens it, and closes any other open row; no row is open to start. The caret turns without animation under reduced motion.
    - The open row shows, in order:
      - its change (BR-21), such as "₹1,200 more than Sep", when the comparison shows;
      - a caption: "Only entry", "Both entries", "All 3 entries" or "Biggest 3 of 21";
      - up to 3 entries, each its note or *No note*, its date and its amount;
      - for a category with more than 3 entries, *See Food entries*.
    - TalkBack reads the row's existing sentence, then the change while open. The hints are "Show biggest entries" and "Hide biggest entries".
    - At 1.3× text and above, the icon wells drop.
  - **AC-R3:** insight #1 (BR-14) stays as it is, beside the row change (owner, 2026-11-14).
- **FR-SP-4b** **The split card** (BR-21, D195, D196) replaces FR-SP-4a's line. It sits between the pace card and *Where it went* whenever the cycle has spends.
  - **Title:** "Money in ₹45,000".
  - **The answer, biggest:** "₹16,430 not spent yet" while the cycle runs, or "₹4,400 left over" once it is finished. It reads "₹3,100 more than came in" past what came in, and "All of it is spent or saved." or "Nothing left over." at exactly ₹0.
  - **The line under it:** "And ₹1,000 saved.". Past what came in, it reads "That includes ₹1,000 saved.". It is left out at ₹0.
  - **The bar** is the month story's bar (one shared painter), on `surface`.
    - In order: Bills in `ink`; Saved as an outline at least 12dp wide, left out at ₹0; Everyday and Not logged in `fillSoft` (D197); then the `sunk` track with a 1dp `ink2` edge.
    - Past what came in, the end of the bar is striped after an `ink` mark.
  - **The key** has amounts for Bills and Everyday only, since the sentence says the other two. A Bills row at ₹0 is left out. Under it, one `bodySmall` line: "Everyday is all spending except bills." (or "…, including ₹4,200 not logged.").
  - **No money in** (`I = 0`): the title is "Spending this month" (or "Spending in September"). It shows "Add the money coming in to see how it splits." and an *Add money coming in* chip, which opens Settings, where *Money coming in* is (FR-SE-1). It does not repeat the spend, which the pace card's total already shows (mockup 46 open question 6).
  - **TalkBack:** one node, answer first: "16,430 rupees not spent yet of 45,000 rupees. Bills 8,200 rupees. Saved 1,000 rupees. Everyday 19,370 rupees."
- **FR-SP-4a** *(superseded by FR-SP-4b, D195: the line is no longer shown; its words stay for the record)* **Spent, saved and not logged** (D176): one `ink2` line above *Where it went*, "Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200", when the cycle shown has saves or a fix. Saves are never in the bars, percentages, week bars, pace or insights (D120).
  - **AC-1** Three parts at most, in this fixed order, so *Spent* and *Saved* never move and the new part only appends: *Spent*, *Saved*, *Not logged*. A part shows only when above ₹0. **Each part is unbreakable and the line wraps between parts** at narrow widths or large text, with no trailing dots (mockup 42 option B). Each is its own ARB key (`spendsPartSpent`, `spendsPartSaved`, `spendsPartNotLogged`), which replace the single `spentAndSaved` once the build has moved over.
  - **AC-2** The *Spent* figure **excludes** *Not logged*, as it excludes *Saved*: the part is its own number and is not inside "Spent". Worked example: `27,150 + 420` is ₹27,570 Spent, and the ₹4,200 fix is the third part (BR-18, case 1).
  - **AC-3** *Not logged* here is the *Spent* side only. A *Got* fix is money in, and this line shows no *Got* total for any entry; it is visible in Every entry and the export (D176).
  - **AC-4** *Used from savings* is **not on this line** (D176): *Used* is not spending. It shows in Every entry and on the Savings list, where "set aside" lives.
  - **AC-5** TalkBack reads one sentence, the parts separated by a full stop and the `·` hidden: "Spent 27,570 rupees. Saved 1,000 rupees. Not logged, spent 4,200 rupees." (`spendsPartNotLoggedSpoken`).
- **FR-SP-5** **Insights** (BR-14), with their actions.
- **FR-SP-6** *See every entry* opens a day-grouped list (D131: the way in is *See all* at the end of *Where it went*'s title row, read by TalkBack as "Every entry in October"; a cycle with nothing spent shows its sentence alone in one card, with no link, D151; Home's *See all* and the list's cycle chips still reach income and savings), with category and cycle filter chips. Swipe to delete and tap to edit, as on Home. A saving is listed with *Saved* and has no tap; each day's total counts spending only, so *Not logged* and *Used* are not in it (D120, D166, D175).
  - **Rows (D187):** a *Not logged* row reads "Not logged" over "Spent" or "Got" with an extra line "Added when you fixed your number."; a *Used* row reads the saving's name over "Used from savings" with an extra line "Paid from what you set aside.". Neither has a tap or a tint; swipe deletes with Undo, and each exposes *Delete* as a custom semantics action. The extra line is read in the same TalkBack node.
  - **Chips (D187):** the chips stay *All* plus each category with entries a user can pick. The system categories (`saved`, so *Used* rides with it, `card_paid` and `not logged`) get none; their entries show under *All*. If a Savings chip exists today it is left as built for *Saved* and *Used* follows it. There is still no search (D113).
  - The list shows the cycle picked in Spends (Home's *See all* opens the current one), with *All* plus a chip for each category that has entries. An insight's *See {Cat} entries* opens it on that category (DECISIONS D53).
- **FR-SP-7** **Month story** (BR-20, D193, D194, mockup [45](design/mockups/45-month-story.html)): a look back at a finished cycle in up to six full-screen pages. It is reached from Spends only. There is no notification, nothing on Home and no sharing.
  - **AC-1 The story card** is on every finished cycle that BR-20 gives a story, **directly below the Ask AI card**. It shows *Your month*, page 2's headline (or "₹X spent" with no income), a small day-bars preview and *See the story*. TalkBack reads it as one button, "Your September story. 4,400 rupees left over.", and the preview is hidden from it.
  - **AC-2 The slim row:** for days 1 to 7 of the current cycle, when the cycle before has a story, a one-line row reads "**September is done.** See your month ›". It sits directly below the Ask AI card, or below the *Nothing spent* card when the current cycle is still empty. Nothing is stored, so after day 7 it is gone.
  - **AC-3 Moving:** a tap on the right two-thirds goes on, and a tap on the left third goes back. The two zones are real buttons named *Next page* and *Previous page*, so TalkBack, Switch Access and a keyboard reach them, and a swipe and the arrow keys do the same. The Back well (as on every pushed screen) and system Back return to Spends. **Nothing advances on its own.** Progress is one thin bar per page present, at the top.
  - **AC-4 Look:** the story always uses the dark theme's tokens, whatever the phone's theme, so it reads as its own evening moment.
    - The only marigold is *Ask an AI about {cycle}* on the last page.
    - Page 4 draws **day bars** (D194), one per day. A dotted `ink2` line marks the share. A bar past the share is solid `ink`; the rest are `ink2`. Both are at least 3:1 against the page, and the share line and the words carry the meaning, not the lightness alone (accessibility review 46). A day with nothing spent is a small dot on the axis. Under the axis are the first date, the biggest day's date (dropped when it would touch an end) and the last date, plus a small dot under each day of the weekday line. There are no y-axis labels.
  - **AC-5 TalkBack:** each page is read as one node, with spoken amounts, in the order of its sentences. Page 4's chart is not read bar by bar; its sentences carry it.
  - **AC-6 Motion:** a page slides in on `HisaabMotion` springs, and under reduced motion it crossfades.
  - **AC-7 Layout:** in an expanded window or two panes, the story is a centred column no wider than 480dp on the dark page. Each page scrolls when its content is taller than the window, and its big amount steps down from `displayMedium` to `displaySmall` at 1.5× text, so nothing clips at 2.0×. It is tested at the `TestWindows` sizes.
  - **AC-8 Ask AI** on page 6 opens FR-AI for that cycle. *Done* closes the story.

- **FR-SP-8** **The months strip** (BR-21, D195) is the last card on Spends, shown as BR-21 says.
  - **Title and count:** "Last 5 months" (or "weeks"), with the count: "Money was left over in 4 of the last 5 months.", "…in both months.", "…in all 5 months." or "Nothing was left over in the last 5 months.".
  - **How many:** 5 cycles, or 6 when the card's inner width is at least 288dp, so every slot is a 48dp-wide target.
  - **Each bar:**
    - Spent is solid `ink`, and Saved is an outlined cap with a 5dp floor.
    - A dotted `ink2` line marks that cycle's money in. The part past it is striped.
    - The running cycle is a dashed outline, with the pace chart's marigold dot (ink ring) under it.
  - **Labels:** month labels ("May", or a weekly cycle's start date) and "Money in ₹45,000" are real text under the chart, never painted. A key line reads "Dark is spent. Outline is saved.".
  - **Picking a month:**
    - The picked month (by default the cycle shown when finished, else the last finished one) gets the picked-chip look. Keyboard focus is a separate ring.
    - A read-out line under the chart, hidden from TalkBack, says it: "September: spent ₹39,600, saved ₹1,000. ₹4,400 left over." or "October so far: spent ₹27,570, saved ₹1,000. 8 days to go.".
    - Beside the read-out is *Open*, unless the picked month is the one shown. *Open* shows that cycle.
  - **TalkBack:** each month is one button with that same sentence (spoken amounts) and its selected state.
  - **Large text:** at 1.5× text and above, the bars become 48dp rows (month, bar, amount).

### 4.5 Ask AI (FR-AI)
- **FR-AI-1** The goals (4, or 3 when *Will my money last till payday?* is hidden, BR-15) are a single column of list rows, each with an icon, followed by an own-question row: a 200-character text field that is always visible, with the placeholder "Ask something else". While it has focus and is empty, the placeholder reads "Like: can I afford a new phone this month?" (DECISIONS D73). Tapping or typing in it picks it. The pick shows an ink check at the row's end and a bold label, never a fill or marigold (DECISIONS D67).
- **FR-AI-2** The period segments and the *Leave out my notes* switch regenerate the preview immediately. The segments are named by their dates, as the cycle switcher names cycles: the shown cycle ("October"), and the three cycles oldest to newest ("Aug – Oct" for monthly cycles, short month names with no year; "12 Oct – 1 Nov" for weekly ones, the oldest start to the newest end) (DECISIONS D76).
- **FR-AI-3** The preview shows "What the AI will see · {n} entries", then the caption "Nothing leaves your phone until you share it.", then (when weeks were grouped) "Older weeks are shown as totals to keep it short.", the first 4 lines, and *Show full text*, which expands to the full scrollable text (DECISIONS D75).
- **FR-AI-4** The actions follow BR-15: *Copy & open ChatGPT*, *Other apps* and *Copy only*. When the prompt is too long to prefill ChatGPT, the paste caption sits directly above them. Nothing is sent anywhere by the app itself.

### 4.6 Settings (FR-SE)
- **FR-SE-1** Money settings:
  - **Money coming in** (D137, mockup [32](design/mockups/32-income-sheet.html), case study 20): the first Money row.
    - **AC-1** The row reads "Money coming in" with the income under it: "₹45,000 · on day 4", "₹45,000 · last day of the month", "₹44,998 · every Friday" (weekly shows the month that posts that week, D26) or "Changes each month" (*It changes*). Until the income loads it shows the label only and doesn't open.
    - **AC-2** Tapping it opens the bill sheet's paper slip (D118): the "Money coming in" eyebrow, the monthly amount with the stamp "Came {date}" of the latest pay, "Comes every month on day 4" (or the last day, or "Comes every Friday, about ₹10,384 a week"), the rows *Amount* and *When it comes*, and "Next payday 4 Nov". There is no Delete. TalkBack reads the slip as one sentence.
    - **AC-3** *Amount* opens onboarding's question "How much money comes in each month?" on the keypad, prefilled (the first key replaces it, FR-AD-8), with "From payday, 4 Nov." and "This month's ₹45,000 stays as it came." above the keys ("This week's" for weekly pay).
    - **AC-4** *Save* changes only the rule's amount (a weekly rule stores the month × 12 ÷ 52, floored to the rupee). The pay already posted stays, today's share doesn't move, and `next_due` doesn't change: the new amount is posted from the next payday. The slip flashes the row and the footer reads "Changed. From payday, 4 Nov." for 2.4 s. Saving an unchanged amount writes nothing; ₹0 is refused with a shake; the 9-digit cap applies.
    - **AC-5** When the latest pay was posted by the rule at its old amount, the footer offers *Change this month too* ("…this week…" for weekly pay). It sets that one entry to the new amount and reads "This month's pay is now ₹50,000." with *Undo*. A pay already changed by hand is never offered.
    - **AC-6** A failed save keeps the question open with "Couldn't save. Try again."
    - **AC-7** *When it comes* opens onboarding's five choices ("When does it come?") with the current one checked. *1st of the month*, *Last day of the month* and *It changes* pick at once; *Pick a date* opens the 1–31 grid and *Every week* the weekdays, and a pick returns to the choices. A picked change shows, before *Save*, "This money lasts till 24 Nov." and "That's 30 days, about ₹281 a day." from Home's own maths (BR-1a). *Save* records the change (D140); the slip flashes the row and the footer reads "Changed. This money lasts till 24 Nov." Back returns one step at a time; a failed save keeps the choices with "Couldn't save. Try again."
    - **AC-8** *It changes* has no amount: the slip reads "It changes", "Each month runs from the 1st" and "Add money when it comes. Tap Add, then Got."
    - **AC-9** From *It changes*, *Save* on a fixed day asks the amount first: onboarding's keypad, prefilled with every *Got* this month, under "Comes every month on day 1" and the effect of AC-7. One *Save* adds the salary rule and records the change.
  - Bills (list, add, edit, delete rules; renamed from *Fixed bills*, D123). The list shows each bill's name, day and amount, soonest first; a changing or card bill's amount reads "about ₹1,200", its estimate (D127). Each row shows the bill's icon (BR-9). **Adding** asks three questions: the name (typed, or one of 8 chips: the 6 from onboarding, then *Credit card* and *Electricity*, which fills it in; Next moves on, D86), the amount on the keypad, then the day of the month (1–31), where tapping a day saves. Bills are monthly. Rent goes in *Home*, a credit card in a hidden category (D123); every other bill goes in *Bills*. A bill switched to *Credit card* and back goes back to where its icon puts it: *Home* for the home icon, *Bills* for the rest (D127). A name is 1–40 characters after trimming. Swipe removes a bill with Undo (BR-9). *Add a bill* is a full-width marigold key pinned to the bottom, in thumb reach, shown once the list loads (not while loading, nor beside *Try again*); the rows scroll above it and the Undo bar rises right above it. The list and the key share one column at most 560dp wide (D136).
  - **Changing a bill** happens in the bill sheet (D118, mockup [27](design/mockups/27-bill-sheet.html)):
    - **AC-1** Tapping a bill row, or Home's due-soon row (FR-HO-3), opens the sheet over the current screen. No page is pushed.
    - **AC-2** The sheet is a paper bill: its name, icon, amount, "Every month on day N" and stamp (BR-9), then five rows (Amount, Kind of bill, Day of the month, Name, Icon), then "Next due on {date}". TalkBack reads the bill as one sentence and each row as "Change {answer}, {value}".
    - **AC-3** A row opens its one question inside the sheet: the keypad prefilled with the amount (the first key replaces it, as FR-AD-8), the 1–31 grid with the current day picked, the name field without pills, or the grid of 16 icons with the current one picked.
    - **AC-4** Amount and name save with *Save*; a day or an icon saves on tap. Each save changes only that answer (a day follows D34), returns to the bill, flashes the row, and the footer reads "Changed." for 2.4 s ("Saved" means only real saving, D120). Saving an unchanged answer writes nothing.
    - **AC-5** Back from a question returns to the bill. Back, a swipe down or the scrim closes the sheet; unsaved typing is dropped, saved answers stay.
    - **AC-6** *Delete bill*, a full-width `sunk` key at the foot of the bill, closes the sheet and deletes the bill with Undo (D35).
    - **AC-7** A failed save keeps the question open with "Couldn't save. Try again."
    - **AC-8** *Kind of bill* shows *Same every month*, *Changes every month* or *Credit card* (the value may take two lines). Its question, "What kind of bill is it?", is the three answers stacked, the current one picked; a tap saves (BR-9, D123).
    - **AC-9** The *Credit card* chip makes a card bill and *Electricity* a changing one; any other name starts fixed. A changing bill's amount question reads "About how much for Electricity each month?", a card's "About how much for Credit card each month?", with the card line of FR-HO-8 AC-2 under it while adding.
    - **AC-10** The first time a changing or card bill exists (added, or switched in *Kind of bill*), a sheet asks once "Remind you on the day it's due?" with *Remind me* (marigold) and *Not now*. *Remind me* then shows Android's permission prompt. Either answer is kept and never asked again; Back leaves it unanswered, to ask next time (D126). If Android refuses the permission, a second sheet says "Reminders are off. Home still shows bills that need an amount." with *Done* (E30, D132).
  - **Savings** (D120; replaces "Keep aside each month"): the same list, three questions and sheet as Bills, worded "put in" ("How much do you put in RD each month?"). The name pills are RD, SIP, Gold scheme and Chit, then three for yearly costs (AC-Y1). Savings are monthly and filed in a hidden category; the sheet has no Icon row (the piggy-bank glyph) and its stamp reads "Put in {date}". The list's footer reads "₹X put in since {Mon}": everything ever put in, never "worth" or "balance". *Add a saving* is the pinned marigold key, and *Put in extra* a full-width chip under it (beside it, in one row, in a window under 480dp tall; D136). *Put in extra* opens a keypad for a one-off saving today:
    - **AC-1** It opens the keypad in a sheet, in the bill sheet's route.
    - **AC-2** The line under the amount is `tomorrow(remaining) − tomorrow(remaining − x)`: "Each day till payday gets ₹62 less" in the worked example ("…till month end…" for a month-end cycle), or "Payday's tomorrow." when `D = 1` (E2).
    - **AC-3** The keypad refuses a digit that would go past `remaining`; with nothing left it reads "Nothing left to put in for now." and Save stays off.
    - **AC-4** Save posts a *Saved* entry dated today and closes the sheet with the success haptic. Today's share stays fixed; the later days get the less.
  - **Yearly costs and *Used from savings*** (D174, D175, BR-19, mockup [42](design/mockups/42-yearly-costs.html), `docs/features/yearly-costs/`):
    - **AC-Y1** The name pills are RD, SIP, Gold scheme and Chit (never moved), then *Insurance*, *School fees* and *Festival*. The three questions and the tap path are unchanged. A yearly cost is a monthly saving; the bill sheet stays monthly (D35).
    - **AC-Y2** For the three new pills only, the amount question shows under the amount "Paid once a year? Each month, put in the cost divided by 12." and "When you pay it, tap Used some of it." The body scrolls above the pinned keypad if it doesn't fit. There is no yearly-amount field, no ÷12 key, no due date and no reminder (D174).
    - **AC-Y3** The list's row gets a **third line**, "{amount} set aside", only above ₹0 and on every saving; the schedule line "Every month on the 5th" stays as the second. The row grows from about 64 to 84dp.
    - **AC-Y4** The list's footer keeps line 1, "₹X put in since {Mon}", and adds line 2, "₹Y still set aside" (zero form "Nothing is set aside now."), only when a saving has something set aside or a use exists (D177).
    - **AC-Y5** When something is set aside, the saving's sheet shows "₹12,000 set aside" under its amount line and an outlined *Used some of it* key in the middle of the sheet, nowhere near *Delete saving*. On the three yearly pills only, "Paid the cost from this? Tap Used some of it." sits above the key until the hallway test shows the key alone is understood (4 of 5), then it is dropped. Before the first put-in the sheet is as it is today.
    - **AC-Y6** *Used some of it* opens a question inside the saving's sheet, as *Amount* does (AC-3 of Changing a bill): "How much did you use from Insurance?", the amount **empty** (₹0 means nothing typed and is refused), the shared pinned keypad with `00` and a full-width marigold *Save* under it (FR-KS-1). *All of it* is a 48dp chip beside the amount (below it at large text) that fills the whole set-aside amount; the first key afterwards replaces it (FR-AD-8) and a second tap on it clears the amount. It is `selected` in semantics while the amount equals the set-aside amount.
    - **AC-Y7** The slot has two fixed lines: "₹12,000 is set aside." becoming "₹{left} will still be set aside." as digits are typed ("Nothing will be set aside." at the full amount), and always "Your daily number doesn't change.".
    - **AC-Y8** A digit that would pass what is set aside is refused: reject haptic, the shake, the held ring (FR-KS-2) and the line "That's all you have set aside. Add the rest as a spend." in place of line 1 until the next valid key. If the set-aside amount fell to ₹0 behind the sheet the slot reads "Nothing is set aside to use." and *Save* is off.
    - **AC-Y9** *Save* posts the entry of BR-19 and closes the question to the list (Settings door) or to Home (due-soon door). The hero does not move. `success` fires with the first visible change: the list's figures rolling (Settings door), or the *Used* row growing into Today (Home door). The snackbar reads "Insurance: ₹12,000 used" with *Undo* (4 s, D105; name first, D132); Undo deletes the entry and doesn't reopen the sheet. A failed save keeps the keypad with "Couldn't save. Try again."; Back while writing closes it and the Undo still shows.
    - **AC-Y10** Deleting a saving's Undo reads "Insurance deleted. What you put in stays in your history." No extra *Used* step is offered on delete (D175).
    - **AC-Y11** TalkBack reads the slot as a polite live region (FR-KS-4); *All of it* as "All of it, button, selected".
  - My month starts on: *Payday* / *1st*.
  - **Fix my number** (D169, FR-FX-1): the last row of *Money*, after *My month starts on*, with the detail "When the number on Home looks wrong.". It opens the sheet of FR-FX over Settings, and is hidden in *No income*. A tree test (T8) may move it to *Your hisaab*; a tie keeps *Money*.
- **FR-SE-2** Categories (D138, mockup [33](design/mockups/33-own-categories.html)):
  - **AC-1** Settings has a *Categories* group under *Look*, with one row that opens the Categories page. The page lists *Your own* ("2 of 4") with an *Add a category* row while under 4, then *Spending* (the 8 built-in) and *Money in* (2). Hidden categories are not listed.
  - **AC-2** A row opens a sheet with the category's icon and name ("Your own" or "Built in" above it), and *Name* and *Icon* rows that open the name and icon steps (FR-AD-9) without an amount. A saved row flashes once.
  - **AC-3** The user's own also has *Hide {name}*. Hiding closes the sheet and shows "{name} hidden" with *Undo*; the note under the key reads "Its entries stay in Spends. It leaves the Add tray."
  - **AC-4** A renamed built-in category says "Built in as Fun. The new name shows on its past entries too.", and its row in the list has "Built in as Fun" as a second line. It has no *Hide*.
  - **AC-5** *Add a category* opens the name step without an amount; its key reads *Add {name}*, or *Bring back {name}* for a hidden one, and is disabled for a name already shown.
  - **AC-6** When the category has a Regular habit (BR-17), the sheet shows one *Your usual* row: "₹20, weekdays around 10 am" ("weekends", or no day word for the pooled profile; with both, today's day type). It has a *Forget* text button (TalkBack: "Forget your usual {name}") and "Worked out on this phone from what you add." under it. *Forget* removes the row; the sheet stays open and shows "Forgotten" with *Undo* inside it, and Undo puts the earlier state back (D153, D154).
- **FR-SE-3** Look: Match phone (default) / Light / Dark (D130, mockup [30](design/mockups/30-look-setting.html), case study [19](design-research/case-studies/19-theme-choice.md)).
  - **AC-1** A *Look* group sits under *Money*: one row reading *Light or dark* with the current look's name under it, and three icon buttons at its end (phone, sun, moon), the current one filled. Nothing is stored until the user taps.
  - **AC-2** One tap on an icon applies the look to the whole app in the same frame (no sheet, no fade, no Save, no message), remembers it in `theme_mode`, and the name under *Light or dark* changes.
  - **AC-3** TalkBack reads the three buttons as one group of exclusive choices by name ("Match phone, light or dark like your phone, selected", "Light", "Dark"); the row's words are not read twice.
  - **AC-4** A failed read keeps matching the phone. A failed save still applies the look for now, and it is lost at the next launch.
  - **AC-5** The words may wrap beside the buttons but never break mid-word: when a word can't fit, the three buttons move under the words, still in one row.
- **FR-SE-4** *Your hisaab*: Back up, Restore and Delete everything (BR-16, mockup [34](design/mockups/34-data-controls.html), D139). This replaces *Reset app* and its typed "RESET". Export CSV comes later (M6).
  - **AC-1** A *Your hisaab* group sits under *Look*. Card 1 holds *Back up* (second line "Last backed up 12 Oct", "Backed up today" or "Not backed up yet"), *Restore* ("Bring back from a backup file"), and, while a restore snapshot exists, *Undo restore*. Under card 1: "The backup file has no password. Anyone who has it can read your entries and notes, so keep it safe." Card 2 holds *Delete everything* ("Clear it all and start again") alone.
  - **AC-2** *Back up* opens the system *Save to* screen with the default name. While writing, the row reads "Backing up…". On success: "Backed up as {fileName}" and the row's line updates. A cancelled picker shows nothing. A failure shows "Couldn't back up there. Try another folder." and the line is unchanged.
  - **AC-3** *Restore* follows BR-16. While reading, the row reads "Checking the backup…". The dialog's keys say outcomes; *Keep what's here* changes nothing. During the replace the keys give way to "Bringing back your hisaab…" and the dialog can't be dismissed. A failed replace rolls back: "Couldn't restore. Nothing changed. Try again."
  - **AC-4** *Delete everything* opens a full page, not a dialog: "This clears hisaab on this phone. It opens again at the first step, like new.", a card listing what goes (every entry, money coming in, bills and their reminders, savings, categories you added or changed, Look and your other settings), "Once it's deleted, there's no getting it back.", "Backup files you made stay where you put them." and "Only hisaab is cleared. Your phone and other apps stay as they are."
  - **AC-5** Above the delete key, the last-backup line ("Not backed up yet. Back up first to keep a copy." when there is none) and a *Back up first* key. It runs AC-2 and returns to this page with the line updated.
  - **AC-6** The delete key reads "Hold to delete everything", with the caption "Press and hold to delete." at rest; it names no duration (D149). Pressing fills it evenly over 1.5 s (D143) (`tick()` on press). When full it reads "Let go to delete" (`threshold()`). Releasing it starts AC-6a. Letting go early, or sliding off, drains the fill and changes nothing; the caption becomes "Keep holding till it fills up." Under reduced motion the fill steps instead of sweeping; the timing is the same.
  - **AC-6a** A 5 s Undo (D149). On release the key reads "Undo" with the Undo02 glyph, and its fill drains back evenly over 5 s. The caption counts down: "Deleting in 5 seconds. Tap Undo to stop." Nothing is deleted yet. When the fill is empty, AC-8 runs. A tap on the key in that time stops it (`tick()`). The fill drains on `snap`, nothing is deleted, and the caption reads "Stopped. Nothing was deleted."; the next delete needs a full hold again. A press that slides off during the countdown neither stops it nor restarts the fill. Under reduced motion the drain steps, but the 5 s are the same. TalkBack hears "Deleting everything in 5 seconds. Double-tap to undo." and the key reads "Undo. Keep everything". Leaving the page during the countdown deletes nothing.
  - **AC-7** TalkBack, Switch Access and keyboard users can't feel a timed hold, so the same key is arm-then-confirm: the first activation arms it ("Double-tap again to delete everything"), and a second within 10 s starts AC-6a's countdown, which a third activation undoes. After 10 s an armed key disarms.
  - **AC-8** After the countdown ends, BR-16's wipe runs and the app opens onboarding step 1 with the back stack cleared, with no snackbar. TalkBack hears "Everything deleted. hisaab is starting again." A failure rolls back and stays on the page: "Couldn't delete. Nothing changed. Try again."
- **FR-SE-5** About: version, licences, and the privacy line "Everything stays on this phone. Nothing leaves unless you share it or back it up." It is true because Auto Backup is off (BR-16) and the app has no INTERNET permission (NFR-2).
- **FR-SE-6** *Shortcuts* (D147, mockup [38](design/mockups/38-widget-and-tile.html) §6): a group with two rows.
  - **AC-1** *Add a widget* ("See what's safe to spend from your home screen") calls `requestPinAppWidget`, which opens the launcher's own dialog. The row is hidden when `isRequestPinAppWidgetSupported()` is false.
  - **AC-2** *Add to quick settings* ("Add a spend from the pull-down") calls `requestAddTileService`, which opens Android's own dialog. The row is hidden below Android 13.
  - **AC-3** When neither row can show, the group is hidden. Nothing in the app ever offers either one unasked.

### 4.7 Widget, tile and shortcut (FR-WG)
Everything here only opens hisaab sooner. The entry path is unchanged: Add → digits → Next → tile (D147).
- **FR-WG-1** **One resizable widget**, *hisaab*, in four sizes. On Android 12+ these use size-mapped layouts; below that, the layout is chosen from the widget's reported size. It is placed at 4×2.
  | Size | Shows |
  |---|---|
  | 2×1 | The amount, "left today" (or the over line), Add |
  | 2×2 | "Safe to spend today", the amount, today's bar, "{D} days left" and the payday flag, a full-width *Add* key |
  | 4×1 | "Safe to spend today", the amount, today's bar, Add |
  | 4×2 | "Safe to spend today", the amount, Add, today's bar, the days rail with the payday flag, the divider, the range line (BR-7) and "{D} days" |
- **FR-WG-2** **Look:** the hero's paper (`display`), with `DisplayEtchPainter`'s rosette, grain and solid and dashed keylines (D106, D107) at every size. It has no shadow and no sheen. Content stays 10dp clear of the dashed keyline. Today's bar keeps BR-6's drawing, without the captions and category names. The widget follows the app's *Look* setting (FR-SE-3), not only the phone's.
- **FR-WG-3** **States:** BR-5's hero and bar rules apply. Over today and over for the cycle show `₹0` in `displayInk2` with the hero's "₹X over today" or "₹X over"; the 2×1, which has no range line, says "Over by ₹X" over the cycle (D156). *No income* shows the wordmark, "Set up hisaab to see what's safe to spend today." and a *Set up* key. **The amount is always shown** (D147).
- **FR-WG-4** **Taps:**
  - **AC-1** The marigold Add key opens Home with the Add tray at the keypad.
  - **AC-2** A tap anywhere else opens Home. *Set up* opens onboarding.
  - **AC-3** No other tap targets.
- **FR-WG-5** **Fresh without the app** (BR-8):
  - The app writes a snapshot after every save, edit, delete, Undo, restore and settings change. The snapshot is one row per day from today until a cycle past the next payday, each row holding that day's hero, `A`, state, `D`, payday and range line.
  - The rows assume no new entries. This is exact, because the ledger can only change while the app is open.
  - The widget picks today's row on every update: about 00:01, on a date, time or time-zone change, and at Android's periodic refresh.
  - All maths stays in Dart (`SafeToSpend`, `PeriodCalculator`). Native code only picks a row.
- **FR-WG-6** **Quick Settings tile:**
  - **AC-1** Label "Add a spend", subtitle "hisaab", a Hugeicons glyph, inactive state. It never shows money.
  - **AC-2** A tap collapses the shade and opens the Add tray at the keypad. If the phone is locked, it unlocks first (`unlockAndRun`).
  - **AC-3** A long-press opens Home.
- **FR-WG-7** **App shortcut:** long-pressing the launcher icon offers "Add a spend", which opens the Add tray at the keypad.
- **FR-WG-8** **TalkBack:**
  - The widget reads the hero's own sentence (FR-HO-7), with amounts spoken: "Safe to spend today: 1,430 rupees. 9 days to payday. Lasts till payday, about 9,300 rupees spare." (D156)
  - The Add key reads "Add a spend".
  - The tile reads "Add a spend, hisaab".

### 4.8 Keypad sheets (FR-KS)
Every keypad sheet in the bill sheet's route: the bill sheet's amount question, *Bill amount* (FR-HO-8), *Put in extra*, *Money coming in*'s amount, Fix my number (FR-FX) and the *Used* question. The Add tray and onboarding keep their own layouts but share FR-KS-2 and FR-KS-3, since they share the keypad. D178 to D180, D184 to D186; mockups [41](design/mockups/41-fix-my-number.html) and [42](design/mockups/42-yearly-costs.html); platform review `docs/features/fix-my-number/07-platform-review.md`.
- **FR-KS-1** **Layout.** Before this, the route's body was one scrolling column with the keypad inside it: at 320×568 the *Save* key sat below the window and the amount scrolled away.
  - **AC-1** The keypad, its action key (*Save*, *Fix it*) and the typed amount are **pinned** and stay on screen at every size; the title and the slot scroll between them. The first key typed scrolls the slot into view (150 ms; no motion under reduced motion), with the amount still visible above the keypad.
  - **AC-2** Arrangement is **stacked, with the amount pinned, at every width under about 560dp**: a 320dp window can't hold a 220dp keypad pane beside a readable header. It is side by side only at 560dp wide or more with a short height (landscape; 412×400 is borderline and tested) and in a tabletop. When the region the slot scrolls in would drop under 96dp, the amount joins the scrolling part. Medium (673×841) and the flat expanded windows (841×701, 1280×800) keep a 560dp centred stack, centred over both panes as the Add tray is.
  - **AC-3** Keys are 56dp, and 48dp in a short window or side by side. The action key is 56dp (48 short) and is re-measured in the build.
  - **AC-4** The pinned bottom padding is the gutter plus the system bottom inset, so the action key clears a gesture pill and a 3-button bar; the sheet's background runs behind the bar.
  - **AC-5** The 48dp drag handle is **not drawn when the window is under 600dp tall** (D180); swipe down, the scrim and Back still close the sheet. In a fold the window is the sub-screen the sheet sits in, so a tabletop's lower half draws none.
  - **AC-6** A sheet sits in one sub-screen of a fold, never across it: in book posture the left sub-screen (Home's pane); in tabletop the whole sheet in the lower half, side by side and at most 560dp wide (D29). The route is posture-agnostic: it anchors with `anchorPoint: Offset(0, windowHeight)` always and a 560dp maximum width, so folding while a sheet is open doesn't strand it. Digits, step and notice live in the bloc and survive a fold, a rotation or a resize.
  - **AC-7** In two panes each pane is its own focus group, Home then Spends, so Tab never alternates between them.
- **FR-KS-2** **The 9-digit cap.** A key that would make a 10th digit is refused with the reject haptic and the amount's shake, **plus** a 2dp ring held on the amount until the next accepted key and a one-shot polite announcement, "That's the most you can type." (`amountCapReached`), spoken only and never shown as text. `Shake` is skipped under reduced motion and haptics may be off, so the ring and the announcement are the signals that always work; a 150 ms flash is not used, since it is gone before the eye arrives. This covers the Add tray (FR-AD-2), Fix, *Used* and every other keypad sheet. A balance cap (*Used*, *Put in extra*) refuses the same way, with its reason line (FR-SE-1).
- **FR-KS-3** **Key labels stop growing at 1.5× text** on the shared keypad, the Add tray and onboarding included (D185). At 2.0× text the keypad is `4 × 56 + 24 = 248dp`, so the action key stays on screen at 320dp. This is a deliberate exception to WCAG 1.4.4 for key digits only: titles, slots and every other text still scale. A 48dp short key must not grow at 1.5× (27sp × 1.5 × about 1.2 line height is about 49dp, so it is checked); tests run at 2.0× on the tight layout.
- **FR-KS-4** **Exits and a screen reader.**
  - **AC-1** Back, system back and Escape (all through `maybePop`) and the scrim act as **Back**: on a one-step sheet they close it and drop typing; on a two-step sheet (the Fix guard) they step back one level (FR-FX-4). Swipe down and the handle close the whole sheet, and never post anything.
  - **AC-2** A sheet has no back preview: Back commits, then the sheet's exit or the 150 ms crossfade plays (D183). Nothing promises a preview.
  - **AC-3** Back while a save is writing closes the sheet, and the save still ends with its Undo on the parent (FR-HO-8 AC-6). Each sheet's `show` waits for a settled state and closes its bloc afterwards, as `BillAmountSheet.show` does, never as `BillSheet.show`, which loses the Undo.
  - **AC-4** A preview slot is a polite live region. Under TalkBack its text changes 1.2 s after the last key, or at once when its state class changes; the live text is short ("4,200 rupees less.") and the full sentence is the slot's focusable text (D186). The amount is not a live region, so digits aren't read one by one: the key pressed is spoken by the key. Empty reads "No amount yet" and typed zero "0 rupees".
  - **AC-5** A disabled action key carries a TalkBack hint ("Type an amount first." or "Nothing to fix.") and a hatch or outline, never colour alone. "Empty" and "typed 0" are different keypad states (BR-18, E74); the Add tray treats 0 as nothing.
  - **AC-6** No hardware-keyboard mapping is added (D186): a later change to the shared `Keypad` would serve every keypad page at once.

### 4.9 Fix my number (FR-FX)
Maths in BR-18; strings in the [copy deck](design/mockups/41-fix-my-number-copy-deck.md); design `docs/features/fix-my-number/`. D165 to D168, D181 to D183. The sheet follows FR-KS.
- **FR-FX-1** **Doors.**
  - **AC-1** Three doors open the same sheet in the bill sheet's route and close back to where they started: the Home foot row (FR-HO-9), Settings › Money (FR-SE-1) and the install line (FR-HO-3). The over card never offers it, onboarding never asks it (Q6), and *No income* has none.
  - **AC-2** The tap path from Home is the foot row, the digits, then *Fix it*: 7 taps for a 5-digit figure. The Add path (Add, digits, Next, tile) gains nothing and moves nothing.
- **FR-FX-2** **The sheet.**
  - **AC-1** The title is "How much of this month's money is left?" ("this week's" for a weekly cycle) and the helper "Bank and cash together. Leave out money from before this month." It never promises to "take out your bills and savings": the typed figure is compared with money that still holds the bills' share (BR-18). This is the working copy; the pre-release user test may change the ARB strings, not behaviour (D164).
  - **AC-2** The amount is **empty** at open (₹0 shown): nothing is prefilled and hisaab's figure is hidden until the first key, so the user reads their bank first and isn't anchored. The keypad is the shared one (`1–9`, `00 · 0 · ⌫`, never reordered) with a full-width marigold *Fix it* under it (FR-KS-1). There are no quick chips: they add amounts, and this is a total. Backspacing to empty brings the helper back.
  - **AC-3** Amounts on the sheet use full Indian grouping (`₹1,25,000`), never compact, because `₹1.25L` would hide a ₹500 gap. "hisaab" is lower case at the start of a sentence.
  - **AC-4** Typed 0 is valid ("I have none of it left"); empty is not. If `H` is still loading the helper stays and *Fix it* is off; if it failed, the slot reads "Couldn't check your number." with a 48dp *Try again* text key and *Fix it* is off.
- **FR-FX-3** **The preview.** A two-line slot of fixed height (every state is a child of one stack and only the visible one is in semantics), directly under the amount. Line 1 anchors; line 2 says the gap and its effect. Direction is words ("less", "more"), never colour or sign; no red, no green. Digit changes inside a state swap instantly; a change of state class crossfades in 150 ms.

  | State (BR-18) | Line 1 | Line 2 | *Fix it* |
  |---|---|---|---|
  | Empty, or `H` loading | none | helper (AC-1) | Off |
  | Lower | "hisaab thought ₹17,430." | "That's ₹4,200 less. Each day gets about ₹467 less." | On |
  | Higher | same | "That's ₹1,000 more. Each day gets about ₹111 more." | On |
  | Short | same | "That's ₹16,430 less, and ₹200 short of what's still due." | On |
  | Over today | same | "That's ₹15,000 less. Today is ₹237 over its share." (worked example, `T = 2,430`: `P = 1,650`, `A_after = 183`, `o = 420 − 183`) | On |
  | Last day (`D = 1`) | same | "That's ₹500 less. Today takes all of it." / "…more. Today gets all of it." | On |
  | Equal | same | "That matches. Nothing to fix." | Off |
  | Close | same | "That's close enough. Nothing to fix." | Off |
  | Large | same | "That's ₹30,000 more. One question first." | On: opens the guard |
  | `H = 0` | "hisaab thought nothing was left." | as Higher or Equal | by state |
  | `H < 0` | "hisaab thought you were ₹300 short." | as Higher or Equal | by state |
  | Ledger changed | "Things changed. Check the new amount." replaces line 1 until the next key | as the live state | On if a gap remains |
  | After *No* | "Count only this month's money." over ₹0, until the first key | none | Off |
  | Save failed | "Couldn't save. Try again." until the next key | | On, digits kept |

  - A zero per-day figure reads "Each day stays about the same."; "about" is on the per-day figure only.
  - *Fix it* stays enabled for a large higher gap and the guard opens on the press, not live: swapping the keypad under a thumb mid-typing (a 6-digit total crosses the threshold as it is typed) would be a hidden mode change. The slot warns first.
- **FR-FX-4** **The guard.** *Fix it* in the *Large* state posts nothing and replaces the keypad and action key with an answer panel, in the same sheet. The amount and slot stay; **the sheet shortens** to fit, since an unchanged height would leave a hole under two keys (D168).
  - **AC-1** The slot's line 2 becomes "That's ₹30,000 more. Is all of it from this month?" and the panel holds two equal-weight 56dp full-width keys, stacked, neither marigold: **"No, some is older"** first (the safe answer for a typed total, first in reading and focus order) and **"Yes, add ₹30,000"** second.
  - **AC-2** Both keys ignore input for about 300 ms after the swap (the 150 ms crossfade runs inside it). The stack ends where *Fix it* was, so a quick second tap or a late finger lift would otherwise land on *Yes* and post a large *Got*; the single-event guard of the save (`droppable()`) can't stop that, since it is a different event. There is no visible mode.
  - **AC-3** *No, some is older* returns to the keypad step with the digits **cleared** (nothing to keep: the typed total was wrong) and the notice "Count only this month's money." over ₹0; focus goes to that notice, which is read once and is not also a live region. *Yes* posts the *Got* (FR-FX-5).
  - **AC-4** Back, system back, Escape and the scrim are *No* (they step back); swipe down and the handle close the whole sheet with nothing posted. A second Back, on the keypad step, closes it. While a save runs Back closes the sheet and the save still lands.
  - **AC-5** If `H` changes while the guard is open, the panel stays; the save re-checks (BR-18) and, if the gap differs, posts nothing, returns to the keypad step and shows "Things changed. Check the new amount."
  - **AC-6** TalkBack: the question is a focusable `Focus` and `Semantics` node, and focus is requested in the frame the panel is built, so it isn't lost when the pressed key disappears; it is read once, then *No*, then *Yes*. If a device shows TalkBack doesn't follow, use a live region and focus *No*. A device check is mandatory before the build is called done.
- **FR-FX-5** **Save.** One event carries what the user typed and saw, and is `droppable()`; the write recomputes `H` (BR-18).
  - **AC-1** Press: a pressed fill, no haptic; the key disables. The label stays "Fix it" (TalkBack says "Saving" only if the write passes 1 s). Double taps make one entry.
  - **AC-2** Success: the sheet closes. After it has fully closed Home reloads (the hold, FR-AD-5), the hero rolls from ₹1,430 to ₹963 and today's bar re-spans in one motion (BR-6); `success` fires in the same frame. A new *Not logged* row then grows into the Today list 300 ms later, so a figure is read before the list shifts. A lower and a higher figure play the **same** motion: no hatch, no flash, no sheen, no emphasis on the row, and the duration doesn't scale with the size of the change.
  - **AC-3** A snackbar through the host: "Fixed. Safe to spend today: ₹963." (the hero's own title; at ₹0 "Safe to spend today: ₹0." with no softening) and *Undo*, 4 s or until dismissed with TalkBack (BR-10). If Home can't show it yet (loading or a failed reload) the Undo waits for Home's next good load (D127). It is the one announcer; the hero isn't also a live region.
  - **AC-4** Undo removes the entry, the number goes back along the same path, `tick`, and "Undone." is announced. It starts at once; the order isn't mirrored.
  - **AC-5** From the Settings door there is no hero under the sheet: `success` fires as the exit starts and the snackbar and its Undo appear on Settings. A bloc inside the Settings route owns that Undo (D179); Home's snackbar host is under Settings and would not show it.
  - **AC-6** A failed write keeps the sheet and the digits: "Couldn't save. Try again.", the reject haptic, *Fix it* on again. A failure after *Yes* returns to the keypad step. A write refused as stale (BR-18) saves nothing and refreshes the preview with the reject haptic.
  - **AC-7** The widget snapshot is rewritten after the write like any other (FR-WG-5).
- **FR-FX-6** **Components and focus.** State is fill, outline, hatch and words, never colour alone; marigold only on *Fix it* (an act). Focus order: Back, title (a heading), amount, slot, keys `1`–`9`, `00`, `0`, ⌫, *Fix it*; in the guard, Back, title, amount, slot (the question, focused first), *No*, *Yes*. The sheet returns focus to the control that opened it. When the opener was the install line it is gone, so focus goes to the "Today" heading. The row exposes *Delete* as a custom action (BR-10).

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
| E10 | Irregular income with no *Got* entry yet this month | `I = 0`, so Home asks "Add the money that came in" |
| E11 | 9-digit amount (₹99,99,99,999) | Accepted; formats `₹99,99,99,999`; compact `₹100Cr` on charts |
| E12 | Text scale 1.5× | Hero steps down to 56 / 44 with no clipping (UI_DESIGN §3.4) |
| E13 | Reduce motion on | All motion becomes 150 ms crossfades; values still update. Opacity is allowed, anything that moves jumps: the Fix guard's resize is instant and the bar's re-span jumps; `Shake` is skipped, so a 9-digit cap is carried by the held ring and the spoken line (FR-KS-2); the list rows and the *Used* row get their height at once with a 150 ms fade, no delay |
| E14 | Restore with a corrupt, older or newer file | Validated first; an invalid file changes nothing; an older version is migrated; a newer one is refused with "Update hisaab" (BR-16) |
| E15 | More than 31 days left (weekly cycles can't; monthly can't) | Not possible by BR-1; asserted in a test. A bridge cycle after a payday change (BR-1a) can run to about 62 days; the days rail still fits (tested at 320dp) |
| E16 | Foldable opened into book posture while the app is running | Re-lays out into two panes split at the fold, with no data or state loss. An open keypad sheet sits in the left sub-screen and keeps its digits and step (FR-KS-1) |
| E17 | Tabletop posture | Content above the fold, controls below it. A keypad sheet is the whole sheet in the lower half, side by side, with the typed amount and its action key on screen (FR-KS-1) |
| E18 | App in a 412×400dp split-screen window | Compact layout; every control still reachable. A keypad sheet keeps the typed amount and its action key on screen at 320×568 and 412×400 (FR-KS-1) |
| E19 | A saving's day is the 29th–31st | Clamped to the month's last day, as in BR-1 (D120) |
| E20 | A saving bigger than everything left | `P < 0`: Over for the cycle, as E5 |
| E21 | App closed for weeks with an RD | Each missed month posts once, dated on its day (BR-9, E7) |
| E22 | The RD posted, and the user also logs the bank debit as *Spent* | Not prevented; the RD row on Today and the due-soon line are the cues (case study 17 risk) |
| E23 | A changing bill on the 31st in a 30-day month | Waits on the 30th, as BR-1 clamps (D123) |
| E24 | A changing bill never entered by the cycle's end | Drops out of `B` and stops waiting; never posted; can be added by hand (E6) |
| E25 | Entering a bill twice for the same date | Not offered (it no longer waits); the unique `(recurring_id, date)` index refuses a second entry |
| E26 | Undo after entering | The entry goes and the bill waits again, with its old estimate |
| E27 | A long-ignored changing bill switched to *Same every month* | Only the latest occurrence on or before today is posted, at the estimate; older months never (D124) |
| E28 | A card bill with income that changes | No difference: a card bill never touches the pool |
| E29 | A changing bill's day moved, or its entry's date edited, after the month was entered | The month stays answered: nothing more is reserved or asked for (D123) |
| E30 | Notification permission refused, or turned off later | Nothing is asked again; Home's waiting line still works (D126). A refusal right after *Remind me* says "Reminders are off. Home still shows bills that need an amount." (D132) |
| E31 | A bill entered before 9:00 on its day | That day's reminder is removed before it shows; next month's is armed (D126) |
| E32 | A reminder tapped after its bill was entered, skipped or deleted | Opens Home only (D126) |
| E33 | The phone restarts, or the app is updated | The plugin's boot receiver re-arms the reminders; the next start or resume re-arms them too (D126) |
| E34 | Entered, then swiped away, then *Undo* on the entered snackbar | The old estimate comes back; the bill waits again (D127) |
| E35 | The *Save to* or *Open* screen is cancelled | Nothing happens; no message (BR-16) |
| E36 | Saving the backup fails, or the place is full | A message; the last-backup line is unchanged; a half-written file is removed if the picker allows (FR-SE-4 AC-2) |
| E37 | The picked file is moved, deleted or goes offline after picking | No effect: its bytes were read when picked. If it can't be read at all: "Couldn't open that file. Try again or pick another." |
| E38 | The app is killed during a restore | The transaction rolls back, so the old data is intact; a snapshot without its "finished" marker is dropped on the next launch |
| E39 | The app is killed during *Delete everything* | The database wipe is one transaction. If it finished, the next launch finds no income and opens onboarding, then clears what's left |
| E40 | Restore, then the next start runs the recurring engine | Each due occurrence posts exactly once; the unique `(recurring_id, date)` index refuses repeats (BR-9) |
| E41 | A backup with 0 entries (just after onboarding) | Backs up and restores; the dialog says "with no entries" |
| E42 | *Undo restore* after entries were added since | The row says how many will go ("The 3 entries added since will go."); Undo puts the snapshot back exactly |
| E43 | A new category's name matches a built-in one, renamed or not ("food", "Movies" after Fun was renamed) | The entry saves into that category; nothing new is made (D138) |
| E44 | A hidden category's name is typed again | That category comes back with its old entries and icon; no copy is made (D138) |
| E45 | Hiding one of the user's own leaves a gap in row 3 | The later ones close up within row 3; the 8 never move (D138) |
| E46 | A restored backup holds an icon key this version doesn't know | The category shows *Other*'s icon; the key is kept, so a newer version can draw it (D138) |
| E47 | Payday moved to today's date (BR-1a) | The new payday is first paid next month; the bridge runs to the day before it; no pay is posted twice |
| E48 | Payday changed and changed back the same day | The old cycle comes back exactly; both switches stay recorded |
| E49 | Weekly ↔ monthly payday (BR-1a) | The monthly figure is kept (weekly posts month × 12 ÷ 52, D26); the bridge ends with the new week or month |
| E50 | *It changes* moved to a fixed day | The amount is asked first, prefilled with every *Got* this month; the bridge starts on the 1st |
| E51 | Widget placed before onboarding is finished | The *Set up* state (FR-WG-3); finishing onboarding updates it |
| E52 | *Delete everything* (FR-SE-4) | The snapshot is wiped with the data and the widget returns to *Set up* |
| E53 | App not opened past the snapshot's last row | The widget shows the wordmark and "Open hisaab to update"; a tap opens Home, which writes a new snapshot |
| E54 | Restore, or *Undo restore* | The widget updates to the restored data at once |
| E55 | Midnight, payday, a clock or time-zone change while the app is closed | The widget picks the matching row (FR-WG-5); a bill posted that day is already in the row (D119) |
| E56 | Tile tapped on the lock screen | Android asks to unlock; nothing about money shows before it |
| E57 | Launcher can't pin widgets, or Android below 13 | The matching *Shortcuts* row is hidden (FR-SE-6) |
| E58 | A habit's window crosses midnight (23:15–00:45) | The pill shows on both sides of midnight; "no entry today" uses the `Clock`'s date (BR-17) |
| E59 | The category is hidden after its habit formed | No pill and no *Your usual* row; bringing it back brings the habit back |
| E60 | An entry is edited to another category, amount or earlier date | It counts with its stored values: in the new category, or not at all once back-dated |
| E61 | Two habits' windows overlap (chai and a cigarette at 10 am) | One pill: the higher share of days, then the more recent hit |
| E62 | The clock or time zone changes | Entries keep their stored local `created_at`; nothing is re-bucketed |
| E63 | The pill is tapped, then Undo, twice within 14 days | The entry is gone; no pill for that category until midnight; after the second, none for 30 days |
| E64 | Weekdays are Regular; weekends have 3 hits, 2 of them in the pooled window | Weekends use the pooled profile if it passes. With fewer than 2 own hits there, nothing shows on weekends |
| E65 | The category already has an entry dated today, typed or posted, any amount | No pill |
| E66 | The phone's clock is set back, so some entries are dated after today | Those entries are ignored until their date comes |
| E67 | Empty ledger, or under 14 days of use | No pill, no *Your usual* row |
| E68 | *Forget*, then *Undo* | The row and the habit come back as before |
| E69 | A hidden category with a quiet or rest state is brought back | Its state is kept |
| E70 | 29 Feb or 1 Jan falls inside the 56 days | Ages and day types are counted on `CalendarDate`; nothing skips or doubles |
| E71 | A habit's profile is flat or has two peaks | The window is the run around the highest slot (earlier on a tie); a flat profile's run would take in the whole day, so it has no window |
| E72 | Fix my number: `T` equals `H` (a gap under ₹1) | "That matches. Nothing to fix."; *Fix it* off; nothing saved (BR-18) |
| E73 | Fix: a round answer (a multiple of ₹100) within ₹50 of `H`, such as 17,400 against 17,430 | "That's close enough. Nothing to fix."; nothing saved, so a ₹30 entry is never made |
| E74 | Fix: typed 0 | Valid, "I have none of it left": `gap = H`. The hero is ₹0 and *Over for the cycle* only when `T < B + R`. Empty and typed 0 are different keypad states |
| E75 | Fix: the lower `A` falls below what was already spent today (`P` becomes 2,000, so `A = 222`, with ₹420 spent) | State 3 applies as it does when a bill is entered today: hero ₹0, "₹198 over today", the calm card. It is BR-4's arithmetic, not spending: the fix is not in `S_today`. The preview's per-day line shows the drop before saving |
| E76 | Fix: lower, and `T < B + R` | Saves; hero ₹0; the over card reads "Over by ₹X this cycle"; the preview says "₹m short of what's still due". It informs and never blocks |
| E77 | Fix: higher by more than `I ÷ 10` | The guard (FR-FX-4). *Yes* posts the *Got*; *No*, Back and the scrim clear the digits and return; swipe and the handle close the sheet with nothing posted. A buffer under `I ÷ 10` passes, previewed and undoable |
| E78 | Fix: `H ≤ 0` (the month was already overspent) | The gap uses the unclamped `H`. Line 1 reads "hisaab thought nothing was left." or "hisaab thought you were ₹X short."; only *higher*, *equal* or *close* can occur (BR-18) |
| E79 | Fix: day 1 of a cycle, or payday with the pay not yet arrived | Day 1 is valid, and the leftover is the buffer case the guard asks about. If the pay hasn't arrived and the user truthfully says none is left, a large *Spent* posts: no guard on a lower gap (D167); the preview says it in words and Undo reverts |
| E80 | Fix: installed mid-cycle | The user types what is left of this month's pay; the lower branch posts the spending from before install (BR-18's example). The install line points here once |
| E81 | Fix: the last day (`D = 1`) | Today's hero falls by exactly the gap; line 2 reads "Today takes all of it." |
| E82 | Fix, then logging the item the user had forgotten | It counts twice, since the pool falls again. The row's line "Added when you fixed your number." is the cue; recovery is deleting the *Not logged* row. No matching on notes |
| E83 | Two fixes on one day | Allowed, no limit (D189). Each compares with the ledger as it is, so the second right after the first reads "That matches." |
| E84 | Midnight or a recurring post while the Fix sheet is open | The preview follows the live ledger. The save recomputes the gap; if it changed it saves nothing and says "Things changed. Check the new amount." |
| E85 | A double tap on *Fix it*, or a quick second tap that lands on a guard key | One entry. Both guard keys ignore input for about 300 ms after the swap (FR-FX-4) |
| E86 | The Fix write fails, or Back while it writes | A failure keeps the sheet and the digits ("Couldn't save. Try again."). Back while writing closes the sheet and the save still ends with its Undo on the parent |
| E87 | A fix made yesterday, seen today | Today it is in `S_prev`; `A_yesterday` is rebuilt with it as pool, so the morning note neither credits nor blames it (BR-8) |
| E88 | The user owes a credit-card bill, or logged a *Saved* entry whose money is still in the bank | Their honest figure reads "higher" by that amount. The guard catches a large gap; a small one inflates the hero. A known limit, watched in the pre-release test (D164) |
| E89 | A weekly cycle, or a bridge cycle after a payday change (BR-1a) | `H` uses the current cycle; the words say "this week's" for a weekly one |
| E90 | *No income*, or Home still loading or failed | No foot row and no sheet; the Settings row is hidden in *No income* |
| E91 | Restore, *Undo restore* or *Delete everything* with fixes present | A fix and the hidden rows travel with the backup; *Delete everything* removes them and the install line's *seen* flag (BR-16) |
| E92 | A user with both a fix and a yearly saving | BR-18's combined example: `H = 16,430`; a *Used* entry moves none of its terms |
| E93 | A 10th digit on any keypad (Add, Fix, *Used*, others) | Refused: reject haptic, shake (not under reduced motion), a held 2dp ring, and "That's the most you can type." spoken once (FR-KS-2) |
| E94 | *Used* for more than is set aside | The keypad refuses the digits; the rest is added as a normal spend (BR-19) |
| E95 | *Used* before the first year of put-ins is complete | Only what has been put in is set aside, so the rest is spending. The caption doesn't promise a first-year cover |
| E96 | *Used* twice for one cost, or a double tap | Allowed up to what is left, and the keypad's line shows the drop. Double taps are dropped (`droppable()`) |
| E97 | A wrong *Used* amount | Undo for 4 s, then swipe the row in Every entry (a custom action exists) and use again. A *Used* entry is never edited in the tray |
| E98 | A saving deleted after a *Used* | Entries stay. The saving leaves *still set aside* and stays in *put in since*; *Used* is no longer reachable, so use it first or Undo the delete |
| E99 | A put-in deleted (skipped) after a use | Set aside floors at ₹0, never negative; the *Used* entry is neither blocked nor edited |
| E100 | A saving keeps running after a use; *Put in extra* | It posts again next month, so next year's cost needs nothing. *Put in extra* belongs to no saving: it adds to *put in since* only |
| E101 | Backup and restore with *Used*; an older backup | `used` and its `saving_id` round-trip; an older file restores as before and gains the hidden rows (BR-16) |
| E102 | A yearly cost paid as *Spent* out of habit | The hero takes the hit and the pot stays high (a double count). Recovery: delete the *Spent* entry and mark *Used*. No matching on notes |
| E103 | The missed-log line: the habit's window crosses midnight, or now is inside the window | Never asks (BR-17); inside the window the *your usual* pill covers the user |
| E104 | The missed-log line: Back without saving, or an entry in the category logged later | The line goes and doesn't come back today; an entry deleted later today is still "asked", with no second question |
| E105 | A door-opened tray (widget, tile, shortcut) over Home | The line is evaluated at the resume and drawn under the scrim but **not asked**; the tray's close can only remove it |
| E106 | The habits load after Home's first frame on a cold start | The line is missed for that open: no pop-in, no late arrival. It is evaluated again at the next cold start or resume |
| E107 | The install or missed-log line in an over state or *No income* | It waits (one next step). Bill lines still show; the foot row stays |
| E108 | A higher slot item clears mid-day (a waiting bill is answered) | The slot collapses to empty; the next lower line doesn't slide in until the next evaluation point (FR-HO-3) |
| E109 | The install line: not a mid-cycle install, a bill line holds the slot, or it was seen already | Not shown, waits, or never again. Any *Not logged* entry consumes it, and after the install cycle it is never offered |
| E110 | A sheet opened from Home (Fix, *Used* from the due-soon row, the bill sheet, a waiting bill, a reminder tap) | Home holds its numbers under the scrim and reloads once the route completes. Two overlapping holds keep Home held until both close. A sheet from Settings sends none (FR-AD-5) |
| E111 | A keypad sheet at 320×568 (1×, 1.5×, 2×), 412×400, 412×300 or landscape | The typed amount and the action key are on screen, above the bottom inset; the title and slot scroll (FR-KS-1) |
| E112 | Back, the scrim or a swipe on a keypad sheet | Back and the scrim step back or close; swipe and the handle close the whole sheet; nothing is posted; no back preview (FR-KS-4) |
| E113 | Text scale 1.5× and 2.0× on the keypad | Key labels stop growing at 1.5×; at 2.0× the keypad is 248dp and the action key stays on screen (FR-KS-3) |
| E114 | TalkBack while typing in a preview slot | One short polite sentence 1.2 s after the last key, or at once when the state class changes; no per-digit speech (FR-KS-4) |
| E115 | The drag handle in a window under 600dp tall | Not drawn; swipe down, the scrim and Back still close the sheet (FR-KS-1) |
| E116 | Month story: a finished cycle of 9 entries, or a weekly cycle | No story card, no slim row, and no story (BR-20) |
| E117 | Month story: the first cycle ever, or a previous cycle not fully tracked | No page 5; the bars show 5 pages |
| E118 | Month story: income `I = 0` | Page 2 shows the spend alone, with no bar or headline; page 4 has no share line and every bar is `ink2`; page 6 has no *Left over* |
| E119 | Month story: spending past income | Page 2 reads "₹3,100 more than came in", with the part past `I` striped; the story card says the same |
| E120 | Month story: fewer than 7 days with *Everyday* spending | No page 4 |
| E121 | Month story: a back-dated entry into a finished cycle | The story card and the story show the new numbers the next time they load (BR-20 is never stored) |

---

## 6. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 | Cold start to an interactive Home in ≤ 1.5 s on a 4 GB Android 10 device; Add tray opens in ≤ 150 ms; the drain begins ≤ 400 ms after the save (Doherty threshold: feedback starts, D91); the same for a sheet opened from Home, where the drain or roll begins ≤ 400 ms after the sheet's exit (checked on the device; if the sheet's exit is slower, the hold may release at 90% of the exit, with its own decision row) |
| NFR-2 | Fully offline. No network permission is used, except opening ChatGPT through the browser (an intent, not app networking) |
| NFR-3 | No analytics, no crash reporting that leaves the device, no ads. Logs never contain notes |
| NFR-4 | Accessibility: WCAG AA contrast (verified in UI_DESIGN §3.2), touch targets of 48dp or more, full TalkBack coverage, 1.5× text, reduced motion. One deliberate exception to WCAG 1.4.4 (D185): keypad key labels stop growing at 1.5×, so the action key stays on screen at 2×; every other text still scales. A cap or refusal that haptics and `Shake` can't carry is also spoken (FR-KS-2); a polite live region under TalkBack is debounced 1.2 s (FR-KS-4) |
| NFR-5 | Data safety: every multi-row write is in a transaction; migrations are tested from each previous schema version; backup/restore round-trips byte-equal data, including notes, inactive rules, `created_at`, `used` entries with their `saving_id`, the hidden `not logged` rows and `asked_on` (migration 005 is tested from v4, with a pre-v5 backup restored) |
| NFR-6 | APK under 15 MB (fonts subset to Latin plus Devanagari) |
| NFR-7 | Changed-lines test coverage ≥ 90% (target 100%) per change (`.claude/rules/tests.md`) |
| NFR-8 | Adaptive layout: no orientation or size lock; works from 320dp phones to tablets, in every foldable posture and in multi-window (UI_DESIGN §13). A keypad sheet keeps its typed amount and its action key on screen at 320×568 and 412×400 and clear of the system bottom inset (FR-KS-1) |
| NFR-9 | The launch splash never delays Home: it is dismissed on Flutter's first frame. Its icon animation lasts 800 ms or less. Its background matches Home's in light and dark (UI_DESIGN §3.7) |
| NFR-10 | The recent-apps preview never shows amounts on Android 13+ (`setRecentsScreenshotEnabled(false)`); screenshots keep working. The placeholder is Home's `bg` edge to edge, never the system's white card (D134). Android 7–12 are unchanged, since `FLAG_SECURE` would block screenshots (D109). The Quick Settings tile never shows money, so the lock screen shows none. The home-screen widget shows the amount, because the user places it (D147) |
| NFR-11 | A corrective write is reversible: *Fix it* and *Used* end with Undo for 4 s (held until dismissed under TalkBack, D105), and every *Not logged* and *Used* row can be deleted without a swipe through a custom semantics action, asserted in a test (WCAG 2.5.1; D186) |
| NFR-12 | Home never recomputes under a scrim: every sheet opened from Home holds Home's numbers until its route completes, and overlapping holds are counted (FR-AD-5; D179) |

---

## 7. Open questions

| # | Question | Default until answered |
|---|---|---|
| Q1 | Should "Got" entries outside the salary (gifts, refunds) count towards `I`? | Yes. All *Got* entries in the cycle count |
| Q2 | Weekly view (FR-HO-2): Monday or locale week start? | Monday (`MaterialLocalizations.firstDayOfWeekIndex` once more locales ship) |
| Q3 | Play Store title descriptor | "hisaab• – Daily Spend Tracker", pending a trademark search |
| Q4 | Should the cycle-summary share card be in v1 (UI_DESIGN §6) or v1.1? | v1.1 |
| Q5 | Should long-pressing a day block show that day's share, or long-pressing Next offer "make this repeat"? | Neither in v1. Hidden gestures fail the 5-year-old test; recurring bills are added in Settings (FR-SE-1) |
| Q6 | Installing mid-cycle: the whole salary counts but spending before install is unknown, so the first days' share is too high. Ask "How much is left right now?" in onboarding? | **Closed (D169).** No extra question in onboarding. A one-time Home line points mid-cycle installers to *Fix my number* (FR-HO-3, FR-FX-1); the share also corrects itself at the next payday |
| Q7 | *Your usual* on short phones (the plan's OQ-8, FR-AD-10 AC-1, FR-AD-1). On a window shorter than about 686dp at 1× text, or about 716dp at 1.5×, the pill starts below the Add tray header's scroll viewport when the tray opens. At 360×640 and 1× only 2 of its 48dp show; it is reached by scrolling, and by TalkBack. The quick chips are already cut off at those sizes today. Should the short tray be laid out again so the pill is in view? | As built. A short-tray layout pass follows |
| Q8 | *Your usual*: a failed save (FR-AD-10 AC-4). "Couldn't save. Try again." follows the pill's one-line fit rule (AC-2), so at large text on a narrow phone it doesn't fit and no words show; only the reject haptic says the save failed. The tray stays open. Should the message be allowed to wrap or move? | As built: no words when the line doesn't fit |
| Q9 | *Your usual* under reduced motion (FR-AD-10 AC-3 "the same under reduced motion"). Flutter scales every animation controller's duration towards zero when the system turns animations off, so the 150 ms crossfade from the pill to the preview is near-instant there. Should the app force the 150 ms? | As built: the system setting wins |
