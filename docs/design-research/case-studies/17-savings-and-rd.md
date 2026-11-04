# 17. Savings and the RD: saving without it looking like spending

## Job of the feature
The owner, in his words: "I save money daily or monthly. In my case I have an RD (recurring deposit) which goes in on specific days in a month. It would be nice to have in the app that I am saving something, and to see how much I saved and spent."

So the feature has three jobs, in this order:
1. **Keep saved money out of "safe to spend"** on the right days, so the hero stays true.
2. **Say that saving happened**, as a fact the user did, not as a cost.
3. **Answer "how much did I save, and how much did I spend?"** for this cycle, and in total.

It must not become accounts, balances, net worth, interest or maturity maths (SPEC §1.2; case study 14 rejected net worth).

## What's wrong today
- **`K` has no way in.** SPEC BR-3 subtracts a keep-aside amount `K`, FR-SE-1 lists "Keep aside each month" and PLAN §2 calls it a toggle. The value is stored (`keep_aside_minor`, D20) and used by `SafeToSpend._pool`, the pace chart's steady line (`I − K`, FR-SP-3) and the Ask AI facts line (BR-15). But `lib/l10n/app_en.arb` has no keep-aside string, so there is no screen that sets it. In practice `K = 0` for everyone.
- **`K` has no date and no record.** It's one lump per cycle. It can't say "RD ₹5,000 goes in on the 10th", it never shows up as something that happened, and nothing adds it up across cycles. So the app can't answer "how much did I save?".
- **The workaround is wrong in three places.** Without a savings feature, the owner would log the RD as a *Spent* entry or a monthly bill. Then:
  - it lands in *Where it went* as a category share (BR-13), so saving looks like spending;
  - on the RD day it's in `S_today`, so a ₹5,000 deposit makes Home say "₹X over today" (BR-5 #3), a guilt state for a good act;
  - if typed by hand rather than posted by a rule, it inflates the pace `V_prev` (BR-7) and moves the forecast.
- **"Saved" already means something else.** BR-8's morning note reads "You saved ₹X yesterday" when yesterday came in under its share. That money is still spendable; it rolls into later days. With a real savings feature, one word would mean two things.

## Method and limits
- **Method:** desk research and competitive review, 4 Nov 2026. Help-centre pages first, then official product pages, then community threads (user reports, marked as such), then reviews (inspiration only). Behavioural claims are from the primary paper wherever it could be reached.
- **Not done:** no app was installed, and no user was interviewed. Everything about Indian users' words and habits is from secondary sources, so it's medium or low confidence until a diary study (see Open questions).
- **Unreachable** (HTTP 403 to the fetch tool, so only search summaries were used, and they're marked): Monarch help, PocketGuard help, Realbyte help, Moneylife. No first-party documentation was found for Walnut/axio, Spendee, Monefy or the HDFC/SBI app screens. Acorns and INDmoney's app screens weren't researched.

## Research by source

### 1. Accounting model: expense, transfer, or reservation?
Apps split three ways.

**a. Reservation: subtracted from "available to spend" before spending.** This is the same move as hisaab's `K`.
- **Quicken Simplifi**'s plan is "Income – Recurring Expenses – Planned Spending – Savings Goals = Available to Spend" ([Quicken blog](https://www.quicken.com/blog/simplifi-spending-plan-better-than-budgeting/), via search summary). A goal's monthly contribution is subtracted only if the user picks "Yes, subtract it"; contributions can be made "from any account, at any time", and the money stays in the account: "You're just telling Simplifi to keep track" ([Quicken, savings goals](https://quicken.com/blog/?p=3185)). Its progress bar has three parts: available in the goal, spent from it, and still needed.
- **PocketGuard**: Leftover = Income − Expenses − Goals, and "monthly goal contributions are deducted from your Leftover" (pocketguard.com/help/leftover and /help/goals, **search summary only; both pages returned 403**).
- **Simple** (BBVA's US bank, now closed): *Safe-to-Spend* was the balance minus pending payments, upcoming bills and Goals. A Goal took "a certain amount… out of your Safe-to-Spend balance every day", and users could pause it or drag in extra at any time ([TechCrunch 2012](https://techcrunch.com/2012/08/21/simple-goals)). It's the closest precedent to hisaab's hero: same name, same subtraction.
- **Goodbudget**: savings sit in a *Savings envelope*, because "otherwise it will look like you can just spend it all" ([Goodbudget help](https://goodbudget.com/?p=12770); forum tip via [search](https://forums.goodbudget.com/t/savings-tracking/3656)). The user has to mirror every deposit by hand: "you will need to make an equivalent change to the Savings Envelope".

**b. Transfer: neither income nor spending, excluded from totals.**
- **Monarch**: transfers are excluded from budget, cash flow and spending (help page **403**; search summary of [help.monarch.com](https://help.monarch.com/hc/en-us/articles/360048393292)). Users on Reddit report that goal contributions and Cash Flow disagree (community, low confidence).
- **Copilot**: money allocated to Goals "does not show in your Categories tab or count towards your Spending Total" ([Copilot, savings](https://help.copilot.money/en/articles/11471870-savings-with-copilot)). A goal behind plan shows a **yellow** bar, "a little behind"; on track is green ([Goals FAQ](https://help.copilot.money/en/articles/11139571-goals-faq)).
- **YNAB**: a transfer between two budget accounts needs no category, and the money "stays in your plan". A transfer to a *tracking* account needs a category, because money is "leaving your plan" ([YNAB support](https://support.ynab.com/en_us/transfer-transactions-a-guide-HJOsZz4Jj.md)). The goal lives on the category (Targets), not on the account.
- **Monzo**: "Left to spend" excludes money in pots (community explanations, 2019–2023, [thread](https://community.monzo.com/t/what-does-left-to-spend-mean-in-the-app/107654)). Users were split on whether a pot move should count: "you haven't spent the money so your monthly budget is technically unaffected" against "the money has been ring-fenced and isn't actually 'left to spend'" ([Monzo community, 2019](https://community.monzo.com/t/include-pot-transfers-in-budgets-summary/58264)). The second view is exactly a reservation.

**c. Expense: saving counted as spending, by choice or by accident.**
- **Money Manager (Realbyte)**: transfers between the user's accounts are not expenses by default, but a per-account *Transfer-Expense* setting makes transfers out of savings, insurance, investment or loan accounts count as expenses (Realbyte help, **403**; [search summary](https://help.realbyteapps.com/hc/en-us/articles/360042889454-How-to-set-up-savings-investment-insurance-loan-as-an-expense)). Two models with a switch between them is the complexity hisaab avoids.
- **Monefy**: no first-party docs found. An App Store reviewer complains that moves between their own accounts "take too much in structure of expenses" and wants them out of the chart ([via search](https://apps.apple.com/kz/app/id1212024409?l=en-gb)). Low confidence, but it's the *Where it went* pitfall exactly.
- **Walnut**: one Indian review lists SIPs as one of its spending heads ([freefincal](https://freefincal.com/top-three-apps-to-manage-your-expenses/), via search). Nothing first-party says whether they count in totals.

**Automated savers** (the bank moves the money, and the app shows it):
- **Jupiter** Pots save "daily, weekly, or monthly", from ₹10 ([Jupiter RD page](https://jupiter.money/recurring-deposits)); the community calls the schedule *Habits* ([forum](https://community.jupiter.money/t/pots-for-2022-start-by-saving-thoughts/18193)).
- **Fi**'s FIT Rules move money "from your savings account to mutual funds or jars" by round-up, per-spend AutoSave or schedule ([Fi](https://fi.money/features/fit-rules)). Neither page says what progress the user sees.
- **Revolut Vaults**: one-off deposits, recurring transfers (with "edit, deactivate, or delete") and round-ups ([Revolut help](https://help.revolut.com/help/app-features/savings-vaults/using-savings-vaults/how-do-i-add-money-to-a-savings-vault)).
- **Qapital**'s Set & Forget is a fixed daily, weekly or monthly amount; **Plum** varies the amount by algorithm (reviews only: [moneydoneright](https://moneydoneright.com/qapital-review), [Plum blog](https://blog.withplum.com/what-is-automated-saving/)).
- **Digit**'s algorithm took "safe" amounts automatically, and the CFPB fined it $2.7m when the algorithm caused overdrafts ([Vixio](https://www.vixio.com/insights/pc-hello-digit-goodbye-savings-us-agency-fines-app-faulty-algorithm)). This is a warning against an app deciding how much is safe to save.

**Wallet (BudgetBakers)**: when a budget is underspent, "Wallet will let you know that you have saved $100 and ask you to put it away towards your goal(s)" ([BudgetBakers blog](https://budgetbakers.com/introducing-savings-goals-wallet/)). This is the same "saved" ambiguity as our BR-8, made into a feature.

### 2. How Indian savers think about RD, SIP, chit and gold schemes
- **The RD is a fixed promise on a fixed day.**
  - SBI e-RD: 12–120 months, at least ₹100 a month. "The instalment amount and number of instalments can't be changed" after opening. A late instalment costs ₹1.50 per ₹100 per month (≤ 5 years). After three unpaid months the account stays open, with a ₹10 charge. At maturity the user picks payout or conversion to an FD ([SBI e-RD FAQ](https://onlinesbi.sbi.bank.in/sbijava/osbi_e-RD_faq.html)).
  - HDFC: from ₹1,000, 6 months to 10 years, with no partial instalments. Up to 6 overdue instalments "can be recovered from the linked account", and the bank may close the RD after six in arrears ([HDFC RD features](https://v.hdfc.bank.in/amp/recurring-deposit/features.html)).
  - So for the owner, the RD is a **fixed amount on a fixed day of the month**: a bill-shaped event.
- **Missing one is normal and recoverable.** Banks charge a small penalty and keep the RD open; Federal Bank's guide describes catching up in one go or in stages ([Federal Bank](https://www.federal.bank.in/banking-bytes/deposits/what-happens-if-you-miss-a-recurring-deposit-installment)). Groww has a one-tap **Skip Installment** with a confirmation of the month ([Groww help](https://groww.in/help/mutual-funds/order/can-i-pause-sip-for-next-month)). AMFI counts an SIP as ceased after three consecutive failed instalments ([INDmoney](https://www.indmoney.com/blog/mutual-funds/sip-stoppage-ratio-explained)).
- **Scheduled saving is mainstream.** About 10 crore SIP accounts contributed in August 2026, ₹32,297 crore that month ([Onmanorama, citing AMFI](https://www.onmanorama.com/news/business/2026/10/07/contributing-sip-accounts-cross-10-cr-in-aug-2026-sip-assets-reach-21-4-of-industry-aum.html)). Bank deposits are still the biggest share of household financial savings, but fell from 40.9% (FY21) to 35.2% (FY25) as mutual funds rose (RBI data via [search summary](https://rbi.org.in/SCRIPTS/BS_ViewBulletin.aspx?Id=24298); the figures differ across bulletin revisions).
- **Safety first.** SEBI's 2025 investor survey (Kantar): 79.7% of households put safety ahead of returns; only 9.5% hold securities (via [Business Standard](https://www.business-standard.com/markets/news/indian-households-including-gen-z-remain-risk-averse-sebi-survey-125093001479_1.html); Moneylife returned 403).
- **Other fixed-instalment habits:**
  - Jewellers' gold schemes: 10–11 monthly instalments, redeemed only as jewellery ([Moneylife](https://www.moneylife.in/article/gold-savings-scheme-from-jewellers-what-you-need-to-know/30186.html), via search).
  - Chit funds: a monthly subscription with an auction. In one survey 72% of members joined to save, and 5–10% of urban households in four southern states are in registered chits ([IIMA field survey](https://faculty.iima.ac.in/iffm/literacy/Chit-fund-field-survey-report.pdf), via search).
  - All three have the same shape as the RD: **name, amount, day of month**.
- **Saving is getting harder for many.** In Home Credit's *Great Indian Wallet 2025*, 50% of lower-middle-class respondents managed to save, down from 60% ([Business Today](https://www.businesstoday.in/personal-finance/news/story/rising-costs-falling-savings-inside-the-evolving-wallet-of-indias-lower-middle-class-480859-2025-06-18)). A feature that makes missed saving feel like failure would hit these users hardest.
- **Vocabulary.**
  - Banks and apps say *Recurring Deposit*, *instalment*, *tenure*, *maturity*, *lock-in*, *SIP*, *auto-save*, *Pots* (sources above).
  - The owner says "saving" and "RD".
  - **No source was found** on the words lower-literacy users use (*bachat*, *jama*, "RD", "kisht"). Treat the copy as unvalidated until a blind read.

### 3. Behavioural economics: what makes saving stick, and what to avoid
- **Labelled money is spent less (mental accounting).** Money is not fungible in people's heads: "both the sources and uses of funds are labeled" ([Thaler 1999](https://people.bath.ac.uk/mnsrf/Teaching%202011/Thaler-99.pdf)). This is why a saving should have its own name and its own place, not be a *Spent* category.
- **Earmarking and partitioning work with low-literacy Indian earners.**
  - Soman & Cheema ran a field study with 146 labourers in rural India who could count but "could not read beyond a few lines of prose". Savings were set aside weekly in sealed envelopes ([JMR 2011, PDF read directly](https://www.russellsage.org/sites/default/files/u137/jmr-C-s014-s021-online.pdf)).
  - Splitting the same amount into two envelopes raised 14-week savings from ₹241 to ₹414. A photo of the children on the envelope raised it further (₹350 vs ₹304).
  - The authors' mechanism is **guilt at breaking the rule**. Once an envelope was opened, people spent more from it, the "what-the-hell" effect ([Cochran & Tesser 1996](https://chibe.upenn.edu/publications/the-fresh-start-effect-breaking-points-in-life-motivate-virtuous-behavior/), cited in the paper).
  - **Take the labelling and separation; leave the guilt** (D9, principle 48). The what-the-hell finding is a reason to make a skipped month cheap and quiet, not a broken streak.
- **Commitment and automation raise saving.**
  - SEED, a locked savings account in the Philippines: 28.4% take-up, and balances up 81 percentage points at 12 months ([Ashraf, Karlan & Yin 2006](https://isps.yale.edu/research/publications/isps06-009)).
  - Save More Tomorrow: saving rates went from 3.5% to 13.6% over 40 months ([Thaler & Benartzi 2004](https://www.anderson.ucla.edu/faculty/shlomo.benartzi/savemore.htm)).
  - "Pay yourself first" has no study of its own under that name (no source found). The evidence is for *saving set before spending, on a schedule*, which is what an RD is.
- **Reminders that name the goal help.** Gain-or-loss framing makes no difference ([Karlan et al. 2016, Management Science](https://econpapers.repec.org/RePEc:nbr:nberwo:16205), abstract). hisaab has no notifications, so the in-app equivalent is the existing due-soon line (BR-9) naming the saving.
- **Progress pulls people on.** Purchases speed up near a goal (the goal gradient: [Kivetz, Urminsky & Zheng 2006](https://business.columbia.edu/faculty/research/goal-gradient-hypothesis-resurrected-purchase-acceleration-illusionary-goal)). This argues for a running total "so far". It's not an argument for targets: an RD has no target the user sets, and a target bar brings back the behind/yellow state Copilot uses.
- **Fresh starts.** People begin goals more at temporal landmarks such as a new month ([Dai, Milkman & Riis 2014](https://faculty.wharton.upenn.edu/wp-content/uploads/2014/06/Dai_Fresh_Start_2014_Mgmt_Sci.pdf)). A skipped month should simply be gone by the next cycle.

### 4. Missed, skipped and one-off saves
- **Scheduled saves:** apps let the user edit, pause or skip, not repair. Revolut has edit, deactivate and delete; Simple had pause and resume; Wallet lets the user pause a goal; Groww skips one instalment. Banks recover missed instalments from the account later (HDFC). None of the first-party pages found shows a "missed" alarm. Copilot's yellow "a little behind" is the only behind-state found.
- **One-off saves** are separate from the schedule everywhere: Revolut's "single deposit", Simple's drag from Safe-to-Spend, Simplifi's "any account, at any time", Jupiter's "flexible" saving. One-offs never change the schedule.

### 5. Pitfalls found
| Pitfall | Evidence | Applies to hisaab |
|---|---|---|
| **Saving counted as spending** distorts the category chart | Monefy review; Realbyte needs a setting to switch it; Monzo users split | Logging the RD as *Spent* puts it in *Where it went*, `S_today` and maybe the pace |
| **Double counting**: the app posts the deposit *and* the user logs the bank debit | Goodbudget asks for manual mirroring; Monarch users report goals and Cash Flow disagreeing; YNAB needs a category only on tracking transfers | High risk: UPI-first users see "₹5,000 debited" by SMS and log it out of habit |
| **Two balances that disagree** | Monzo: "Left to spend" counted pot money for some users ("makes the 'left to spend' figure useless", [thread](https://community.monzo.com/t/what-does-left-to-spend-mean-in-the-app/107654)) | Any savings total must come from the same entries as the hero, never a second store |
| **Creep into accounts and net worth** | Realbyte, Goodbudget, Monarch, Unfold (case study 14) all grow accounts once savings appear | Out of scope (SPEC §1.2); interest, maturity and balance need account data the app doesn't have |
| **The app decides what's safe to save** | Digit's CFPB fine | Never auto-move or suggest amounts; the user states the RD |
| **A target that turns into a verdict** | Copilot's yellow "behind" | No target, no behind-state, no colour |

## Patterns compared

| Pattern | Who | Out of spendable? | Shows that saving happened | Saved vs spent | Missed / extra | Fits hisaab? |
|---|---|---|---|---|---|---|
| Saving as a *Spent* category | Walnut (SIP head), Realbyte option, Monefy (by accident) | Yes, but as spending | As a spend row | Mixed together | Edit the entry | **No**: shows as spending, makes RD day "over today", fixed categories (BR-11) |
| Transfer between accounts | Monarch, Copilot, YNAB, Realbyte default, Monzo pots | Only if the account is outside the budget | A transfer row | Separate, but needs accounts | Edit the transfer | **No**: needs accounts (SPEC §1.2) |
| Reservation, no record | hisaab `K` today; Simplifi goals without contributions | Yes, all cycle | No | No | No | Partly: right maths, says nothing |
| Envelope filled by hand | Goodbudget | Yes | Envelope balance | Yes | Manual | No: manual mirroring is the double-entry chore |
| **Scheduled reservation that posts on its day** | Simple Goals and Expenses; Simplifi monthly contribution; Jupiter Habits; bank RD itself | **Yes**: reserved before its day, posted on it | **A row on its day** | **Yes**: separate kind, separate total | Skip this month; one-off extra | **Yes**: same shape as a fixed bill (BR-9), and keeps `P`'s maths |
| Goal pots with targets and progress | Copilot, Simplifi, Revolut, Jupiter, Fi | Yes | Progress bar | Yes | Pause; behind-state | No for v1: targets, several pots and withdrawals are the complexity to avoid |

## Recommendation

### Options
**A. Make keep-aside visible.** Add a *Keep aside* row to Settings for the existing `K`, and a line on Spends: "₹5,000 kept aside this month".
- Cost: tiny. No formula change.
- Answers job 1 only. It has no date, records nothing, can't sum "so far", and can't take a ₹500 extra. The owner's RD on "specific days" isn't represented.

**B. Savings that work like fixed bills (top pick).** A *Saved* kind of entry and rule, set up like a fixed bill (name, amount, day) and posted by the same recurring engine. `K` stops being a setting and becomes the sum of this cycle's saves. Saves never touch the hero's bar, *Where it went* or the pace. Spends says "Spent ₹X · Saved ₹Y".
- Cost: medium. It reuses BR-9 and the bill sheet (case study 16), and adds a new entry kind.
- Answers all three jobs. No accounts.

**C. Savings pots/goals.** Named pots with a target, a progress bar, extra deposits and withdrawals (Copilot, Simplifi, Jupiter).
- Cost: high. It brings targets, behind-states, withdrawals, several pots and a second balance, and it's on the way to net worth.
- Rejected for v1.

### B in detail: the minimum feature set
1. **Settings → *Savings*, next to *Fixed bills*.** The same list and the same three questions: name ("RD", "Gold scheme", "Chit", typed or a pill), amount, day of the month. Monthly only, like bills (D35). Changing a saving uses the bill sheet from case study 16. Delete has Undo and keeps past entries (BR-9). The list's footer shows the total so far: "₹42,000 put in since Jan".
2. **The engine posts a *Saved* entry on the day** (BR-9 unchanged: idempotent, catches up, not back-posted for a day already past, D33).
3. **Home:**
   - **The hero doesn't change.**
   - On the day, the Today list shows the row "RD · ₹5,000 · saved", with its own glyph and the word, no colour. It's not a bite on today's bar and never triggers *Over today*.
   - The due-soon line (BR-9) names it: "RD ₹5,000 goes in on Thu". This is the only nudge, and it points toward saving.
4. **Skip this month.** The posted row can be deleted with Undo, like any entry (BR-10). The money goes back to the pool and the days get more. The words are "Skipped this month", never "missed". No count of skips and no streak.
5. **Put in extra** (the "₹500 extra one day" case). A button on the *Savings* list, not in the Add tray, so the Add flow is untouched. It opens the keypad and saves a one-off *Saved* entry dated today. A helper line previews the effect: "Each day till payday gets ₹63 less". The keypad rejects an amount above what's left this cycle (`P − S_today`), so saving can never cause *Over for the cycle*.
6. **Spends:**
   - One line above *Where it went*: "Spent ₹27,570 · Saved ₹5,000", for the cycle shown.
   - Saves never appear in *Where it went*, its percentages (BR-13), the insights (BR-14) or the week bars (BR-6a).
   - *Every entry* lists them with the word "saved".
7. **Ask AI and export.**
   - BR-15's facts clause becomes "I save ₹5,000 a month (RD on the 10th)".
   - The CSV `kind` column gains `saved` (BR-15 §6, BR-16).
   - The *What should my limits be?* task already says "after fixed bills and what I keep aside".
8. **Not in it:** targets, progress bars, interest, maturity, tenure end, balances, opening amounts, several pots, withdrawals, daily or weekly frequency, auto-sweeping leftovers into savings.

### Formula impact (against SPEC BR-3 symbols)
`K` stops being a stored setting and is computed from the ledger and the rules:

```
K = R + Sv_rule + Sv_prev
P = I − K − B − S_prev                      // BR-3, unchanged in form
A = max(0, floor(P / D))                    // BR-4, unchanged; fixed for the day
remaining = P − S_today − Sv_today          // was P − S_today
tomorrow  = floor(remaining / (D − 1))      // only when D > 1
Over for the cycle (BR-5 #2): remaining < 0 // prevented for saves by the keypad cap
```

| New symbol | Meaning |
|---|---|
| `R` | Scheduled *Save* occurrences due in `(t, end]` and not yet posted. They're reserved ahead, exactly like `B` |
| `Sv_rule` | *Saved* entries dated in `[start, t]` that were posted by a rule. A scheduled save is in `R` until its day and in `Sv_rule` from its day, so **`P` and `A` don't move on the RD day** |
| `Sv_prev` | One-off *Saved* entries dated in `[start, t − 1]` |
| `Sv_today` | One-off *Saved* entries dated `t`. Like an overspend (FR-HO-5), they spread over the days after today and leave today's `A` fixed, as BR-4 requires |

**The same-day case, and study 18's fix.**
- Case study 18 (variable bills) found that a bill posted on its own day falls into `S_today`, so Home shows ₹0 "over today" on that day. It proposes `P = I − K − B − S_prev − R_t`, where `R_t` is the bill entries dated today.
- `Sv_rule` applies the same rule to saves. Its window is `[start, t]`, so a save the engine posts *today* comes out of `P` at the start of the day, never out of `S_today`.
- So on the RD day, `P` is what it was the evening before: yesterday's `R` becomes today's `Sv_rule`. `A` doesn't move, and no bite or *Over today* appears.
- If study 18 is approved, the two terms should share one definition: "entries a rule posts dated today are reserved in `P`, not spent today". Saves would then sit beside bills as `Sv_rule ⊂ K` and `R_t`.
- If study 18 is not approved, bills keep today's behaviour and saves still never reach `S_today`. The two would then be inconsistent, so 18 should go first.

**Unchanged:**
- `S_today`, today's bar, the bites and *Over today* (saves are never *Spent*).
- BR-7's pace (`V_prev` counts *Spent* only). Its spare becomes `remaining − pace × (D − 1)`.
- BR-8 rebuilds yesterday with saves as they stood.
- FR-SP-3's steady line `I − K` now uses the computed `K`.

**Worked example** (SPEC's: `I = 45,000`, `B = 1,200`, `S_prev = 27,150`, `t` = 26 Oct, `D = 9`):
- Add an RD of ₹5,000 on the 10th. It posted on 10 Oct, so `Sv_rule = 5,000`, `R = 0` and `K = 5,000`.
- `P = 45,000 − 5,000 − 1,200 − 27,150 = 11,650`, so `A = floor(11,650 / 9) = ₹1,294`. That's the same result as setting `K = 5,000` today, so the maths is backward compatible.
- Put in ₹500 extra today with ₹420 spent: `remaining = 11,650 − 420 − 500 = 10,730`, so `tomorrow = floor(10,730 / 8) = ₹1,341`, against ₹1,403 without the extra. The preview reads "each day till payday gets ₹62 less" (`floor(500 / 8)`).
- Today's hero still shows ₹874 (`1,294 − 420`).

**Edge cases to add to SPEC §5:**
- An RD day of 29–31 is clamped as in BR-1.
- A saving larger than everything left makes `P` negative (E5 analogue): Over for the cycle, naming the saving.
- With weekly pay, a monthly RD falls in one week's cycle and that week carries all of it (the same as bills today; flag it in the blind read).
- A saving added after its day this cycle isn't back-posted (D33).

### Why B
- **It matches how an RD works.** A fixed amount on a fixed day is a bill's shape, so the user learns nothing new and the engine, the sheet and the due-soon line are reused.
- **It's reservation plus record**, the model of Simple, Simplifi and PocketGuard (reserved from "safe to spend"), with the separate total of Copilot and Monzo (not spending). It needs no accounts.
- **It's labelled and separate, without guilt.** It keeps the part of Soman & Cheema that works (a named, partitioned saving) and removes the guilt and the what-the-hell trap (skip is quiet, with no behind-state).
- **It makes saving visible as an act**, a row on its day and a total so far, which is the only nudge PLAN allows (toward saving).

## Conflicts to hand to `design-product`
- **PLAN §2 "Savings goal: Off. Optional Keep aside… Toggle"** and **FR-SE-1 "Keep aside each month"**: B replaces the setting with *Savings*. `keep_aside_minor` (D20) would be migrated: a non-zero value becomes a saving rule named "Keep aside" on payday. It needs a DECISIONS row.
- **BR-8 copy "You saved ₹X yesterday"** collides with real saving. I'd hand it to `design-content` to reword, for example "Yesterday you spent ₹X less than its share, so every day got ₹Y more". The maths (D38) is unchanged.
- **BR-10/BR-11:** a third entry kind (*Saved*) alongside *Spent*/*Got*. Categories stay fixed (BR-11); a save carries its rule's name, not a category.
- **SPEC §1.2 "Accounts, wallets, transfers… not in v1"**: B is not a transfer and has no balance. That needs stating explicitly so it isn't read as the start of accounts.
- **Add flow (CLAUDE.md "never add a tap or a field")**: B keeps one-off saves out of Add on purpose. If the owner wants *Saved* as a third Spent | Got segment, that's a separate decision.

## Risks
- **Double counting (high).** A UPI-first user gets a bank SMS "₹5,000 debited" on the RD day and logs it as *Spent*. Mitigations: the posted row is already on Home's Today list that morning, and the due-soon line says "goes in on Thu" the days before. Neither is proof. A 5-user test task ("your RD went out today; log your day") should check it before build.
- **Assumed, not confirmed.** The engine posts the save whether or not the bank debit happened (a failed auto-debit, a closed RD). The skip-by-delete covers it, but only if the user notices. The same risk exists for bills today.
- **"Saved" totals can be read as a balance.** "₹42,000 put in" is not what the RD is worth (interest, penalties, a premature closure). Use "put in", never "worth" or "balance".
- **Vocabulary is unvalidated** for Hindi-first and low-literacy users ("saved", "put in", "RD").
- **Scope creep.** Requests for targets, interest and maturity will follow. Section "Not in it" is the line to hold.

## Principles (appended to `principles.md` as 57–59)
- **Saving is reserved before its day and recorded on it, never counted as spending.** Take it out of "safe to spend" ahead of time, show it as its own kind of row on the day, and keep it out of spending charts, pace and over-states. *Sources:* Simple Safe-to-Spend Goals; Simplifi's plan formula; Copilot goals; Monefy and Monzo user complaints; this study. *Applies to:* BR-3, Home's Today list, Spends.
- **Label and separate a saving, but never make breaking it feel like failure.** Naming and partitioning raise saving; guilt and streaks bring the what-the-hell effect. Skipping is a quiet undo, with no behind-state and no count. *Sources:* Soman & Cheema 2011; Thaler 1999; Cochran & Tesser 1996 (as cited); Copilot's "behind" (counter-example); principle 48. *Applies to:* savings rows, skip, any goal idea.
- **One source of truth for every total.** Any saved or spent total is computed from the same entries as the hero, never kept as a second balance. *Sources:* Monzo "left to spend" threads; Monarch goals vs Cash Flow reports; Goodbudget's manual mirroring. *Applies to:* Spends' summary line, the Savings list total.

## Sources (added to `sources.md`)
| Source | Good for | Limits |
|---|---|---|
| [Copilot help](https://help.copilot.money/en/articles/11471870-savings-with-copilot), [Quicken Simplifi blog](https://quicken.com/blog/?p=3185), [YNAB `.md` support](https://support.ynab.com/en_us/transfer-transactions-a-guide-HJOsZz4Jj.md) | How goals and transfers stay out of spending | Fetch cleanly; marketing tone on Quicken's blog |
| Monarch help, PocketGuard help, Realbyte help | Transfer and goal rules | 403 to the fetch tool; only search summaries |
| Indian bank RD terms ([SBI e-RD FAQ](https://onlinesbi.sbi.bank.in/sbijava/osbi_e-RD_faq.html), [HDFC](https://v.hdfc.bank.in/amp/recurring-deposit/features.html)) | Instalment, tenure, penalty, missed-instalment rules | Fetch cleanly; SBI's sbi.co.in RD page returns a title only; no app-screen material |
| [Groww help](https://groww.in/help/mutual-funds/order/can-i-pause-sip-for-next-month), [Jupiter](https://jupiter.money/recurring-deposits), [Fi](https://fi.money/features/fit-rules) | Skip, auto-save and frequency facts | No screens or progress displays described |
| AMFI figures via press ([Onmanorama](https://www.onmanorama.com/news/business/2026/10/07/contributing-sip-accounts-cross-10-cr-in-aug-2026-sip-assets-reach-21-4-of-industry-aum.html), [INDmoney](https://www.indmoney.com/blog/mutual-funds/sip-stoppage-ratio-explained)) | SIP scale, the stoppage ratio and its definition | Secondary; check amfiindia.com before quoting |
| [Soman & Cheema 2011 (Russell Sage PDF)](https://www.russellsage.org/sites/default/files/u137/jmr-C-s014-s021-online.pdf) | Indian field evidence on earmarking and partitioning | The fetch tool returns binary; Read the saved PDF |
| Moneylife | Indian personal-finance reporting | 403 to the fetch tool |

## Open questions for the owner
1. **Replace keep-aside with *Savings*?** B folds `K` into savings. Is there any reason to keep a dateless "keep aside" as well?
2. **"Daily" saving.** You said "daily or monthly". Is daily real (a piggy bank, a Jupiter-style habit), or would *Put in extra* on the days you save cover it? Daily rules would need a new frequency in BR-9.
3. **Where to see the total.** Is "Spent ₹X · Saved ₹Y" on Spends enough, or do you want it on Home? Home would push against the 2-second rule (SPEC §1.3).
4. **Should an RD end?** An end month ("RD ends Mar 2028") would stop posting by itself. It's useful, but it starts tenure tracking.
5. **Money saved before the app.** Should "put in so far" count only what the app recorded (proposed), or take an opening amount (which leads toward balances)?
6. **One-off saves in Add.** Keep them on the *Savings* list (proposed, Add untouched), or make *Saved* a third segment in Add?
7. **Next research step.** A 1–2 week diary study across a payday and an RD day, with 5 UPI-first users, to check double logging, the words ("saved", "put in", "RD"), and whether skip-by-delete is found.
