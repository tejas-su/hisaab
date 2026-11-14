# 36. Spending insights and "how much did I save": what other apps show, what worked, what backfired

> **Outcome (2026-11-14): proposed, not approved.** Desk research only. No DECISIONS row, SPEC, UI_DESIGN or PLAN change. Implications go to `design-product`. Two proposals below touch earlier calls: a payday recap (case study 33 dropped P3 "for now") and any search or "most often" list (D113 dropped search). `docs/DECISIONS.md` wins until a new row changes it.

## Question
(a) How do other apps show "how much did I save" and "where my money goes / what I spend most on"? Savings rate, month-over-month, top merchants or items, calendar heatmaps, weekday patterns, year-in-review, streaks, goals. (b) Which of these would most improve hisaab without breaking its limits: extreme simplicity, no red/green or category colours, one marigold signal, no bank sync, no network, no ads?

## Context: what hisaab already has
Pace chart with gap and forecast (FR-SP-3, case study 21); *Where it went* bars with %, ₹ and limit hatching (FR-SP-4); the *Spent · Saved · Not logged* line (FR-SP-4a); up to 3 insights (BR-14: a category up 20% and ₹1,000 against last cycle at the same day, a standout entry, the steadiest category, plus the limit offer); week bars (D109–D111); the Ask AI export; *your usual* (BR-17); the widget, tile and shortcut (D156); *Fix my number*. Case study 33 lists what is missing (silent drift, yearly costs, leftover at payday) and what it dropped (payday close, evening nudge).

## Method
Cheapest method that can change the decision: **desk and competitive research**, because nothing here needs users yet to rank ideas, and hisaab has no telemetry to mine. I read the help pages and papers I could fetch and used search summaries for the rest (marked **[summary]**). Evidence is split into what people **did** (field or lab behaviour) and what they **said** (survey, review, interview). No apps were installed and no screens were seen: Mobbin needs a login (`sources.md`), so how any competitor *looks* is unverified.

**What this study cannot say.** Almost every finance app named here is US or UK and bank-linked; no Indian app publishes a spending-insight page (below). The two behaviour studies are lab or US-field studies. Nothing was tested with Hindi/English, low-end-phone, UPI-first users.

## 1. How others show "how much did I save"

| App | What it shows | Evidence level |
|---|---|---|
| **Monarch** | Cash Flow tab summary card: *Total income, Total spending, Net cash flow, Savings rate* for the period; breakdown by category, group or merchant; Sankey chart. Formula not found; the usual (income − spending) ÷ income is **my assumption** | [Using Reports](https://help.monarch.com/hc/en-us/articles/21846787088916-Using-Reports) returned 403; **[summary]** |
| **Copilot** | *Net This Month*: income vs spend, month-to-date against last month-to-date; Cash Flow tab with week-to-week or month-to-month bars; savings goals (case study 17). Its dashboard page does not mention a savings rate | [Dashboard help](https://help.copilot.money/en/articles/6045480-dashboard-tab-overview) fetched |
| **YNAB** | *Age of Money*: one number of days, averaged so it moves slowly. YNAB's own post warns it "is reporting the past", is not a burn rate or net worth, and "will break down" if pushed to be those; the target changes with card use (above 30 or above 60 days) | [YNAB blog, 2016](https://www.ynab.com/blog/how-old-is-your-money) fetched |
| **Apple Card** | Week, Month, Year in Wallet; under the total, a message of how much more or less than the previous period | [Apple Support](https://support.apple.com/en-us/102329) confirms views and the message; exact wording is not on the page |
| **Wallet (BudgetBakers)** | Dashboard cards: *Expense structure* (pie, 30 days), *Cash flow* (income vs expense), *Balance trend* | **[summary]** of reviews and the Play listing |
| **Money Manager (Realbyte)** | Tabs *Daily, Calendar, Weekly, Monthly, Total*, each with Income, Expenses, Total | [Help](https://help.realbyteapps.com/hc/en-us/articles/360046150874-Home-tab) returned 403; **[summary]** |
| **Indian apps** | No official page found for a savings-rate, month-over-month or recap feature in PhonePe, Google Pay, CRED, Jupiter or Fi. Jupiter markets "Spend Insights" and a health score (marketing, **[summary]**). axio shows daily and monthly views and category budgets from SMS ([Play](https://play.google.com/store/apps/details?id=com.daamitt.walnut.app&hl=en_IN)). Google Pay's *Ask Google Pay* is a chat, limited to some users and gated on "Personalisation" ([help](https://support.google.com/pay/india/answer/17034014?hl=en)) | Absence of a page is not proof of absence of a feature |

**Finding A (medium).** Savings rate exists only in bank-linked, income-aware apps (Monarch) and sits in a *report*, not on the main screen. The one mass-market daily-use savings figure in the field is a count of days (YNAB) that its own author fences with caveats. hisaab already counts *Saved* (D120), so it can say "put in ₹1,000" without a rate.

**Finding B (medium-low, said not did).** In an Indian prototype test (n = 34, PhonePe-based Figma prototype), 56.3% said a *saving streak* would motivate them, 28.1% were unsure and 15.6% said no ([Dev et al., arXiv 2401.09937](https://arxiv.org/html/2401.09937), first 100k characters read). That is stated intent on a prototype, not behaviour; it does not outweigh principle 48.

## 2. How others show "where my money goes / what I spend most on"

| Pattern | Who | What I could verify |
|---|---|---|
| **Category share** | Apple Card (colour-coded bars; the day's bar blends category colours, **[summary]**), Wallet and Monefy (pie), Money Manager | A Monefy App Store reviewer calls the wheel "a bit clumsy" when rent is 95% **[summary]**. Reviewers otherwise praise pies. hisaab chose bars, no donut |
| **Top merchants / frequent spend** | Rocket Money: *Frequent Spend* and *Largest purchases* at the foot of the Spending tab; Monarch: breakdown by Merchant | Rocket Money's page is a team member's blog and a pricing page **[summary]**. Needs bank data to know the merchant |
| **Compare with last period** | Apple Card message; Copilot MTD vs MTD; Emma (compare any period; paid tier **[summary]**); Spendee (previous month in grey on the overview graph; [Medium tips post](https://medium.com/spendee/spendee-201-tips-tricks-to-discover-today-fd714928315) returned 403, **[summary]**) | hisaab's BR-14 #1 already does this per category, at the same day-of-cycle |
| **Calendar / heatmap** | Cashew: a homepage heatmap section with a configurable first weekday ([changelog in the repo](https://github.com/jameskokoska/Cashew/blob/main/budget/lib/widgets/showChangelog.dart): "Heatmap homepage section first weekday setting", "Fix heatmap missing blank days"); Money Manager's Calendar tab shows each day's totals as numbers | Cashew's code shows it exists and had bugs, not that it helps. No usability evidence for heatmaps found |
| **Weekday pattern** | Emma's weekly report shows the biggest day of the previous week; a user asked for a calendar for weekday trends in a thread about 6 years old ([Emma community](https://community.emma-app.com/t/money-calendar-view/2168), **[summary]**). A weekday-by-hour heatmap appears in Wealthfolio's docs (a desktop investment app) | Nothing shows people use or understand weekday views |
| **Month and year in review** | Copilot *Month in Review* in the Transactions tab, shareable slides, past reviews browsable since Oct 2026 ([help](https://help.copilot.money/en/articles/10310024-month-and-year-in-review), thin: no slide list, no opt-out stated); *Year in Monzo* since 2018 ([Monzo's 2024 write-up](https://monzo.com/blog/writing-year-in-monzo-2024)) | See Backfire 2 |
| **Streaks, goals, scores** | Streaks and challenges in many apps (vendor blogs); Copilot goals; Jupiter health score | Streak claims come from blogs. A 2025 systematic review of 45 gamification studies reportedly found heavy self-report and few comparisons with non-gamified versions **[summary]**; I did not read it |

**Finding C (high that it is absent, medium that it matters).** No Indian app, and no daily-number app, has a documented "here is where it went" view that works without bank data. The merchant-level views (Rocket Money, Monarch) depend on sync. hisaab's equivalent is the category plus the note.

## 3. Evidence on what changes behaviour

### 3.1 Showing a shrinking exact figure can raise spending (did)
Pocheptsova Ghosh & Huang, *Dynamic Budget Monitoring: When Access to Budget Feedback Leads to Increase in Spending*: more than 350 US consumers managed a one-week dining and grocery budget. Those who tracked from memory did not overspend; those who got budget updates every other day overspent, with the rise at the **end** of the period (a secondary summary gives +26.7%; I could not confirm it in the paper). The authors' explanation is uncertainty: without data people keep a safety margin, and feedback removes it. Two things reduced the effect: **showing a range** (€20–€60 instead of €40) and **reminding people leftover rolls into the next period**. Splitting the budget into shorter ones did not help; one summary says people may offset overspend in one category against another, but I could not confirm which intervention that sentence belongs to. Sources: [Think Forward Initiative summary via search](https://www.thinkforwardinitiative.com/research/budget-apps-might-they-actually-make-you-spend-more) (DNS failure on fetch), [CEPR working paper PDF](https://cepr.org/system/files/2022-08/Dynamic%20Budget%20Monitoring%20-%20When%20Access%20to%20Budget%20Feedback%20Leads%20to%20Increase%20in%20Spending%20-%20Anastasiya%20Pocheptsova%20Ghosh%20&%20Liang%20Huang.pdf) (403), [BehavioralEconomics.com](https://www.behavioraleconomics.com/the-budgeting-app-trap-when-spending-information-backfires/) (title only), [JCR 2023 on budgets and spending](https://academic.oup.com/jcr/article/49/5/697/6603733) (a related, app-data paper whose results differ, per the summary). **Confidence: low to medium** (one lab study; secondary summaries; US; one week).

This matters more to hisaab than any chart: its whole product is a per-day figure that shrinks. Home already shows a *range* line (BR-7); this study is the only behavioural support found for it.

### 3.2 Easy access to your numbers reduced fees (did)
Carlin, Olafsson & Pagel, *Mobile Apps and Financial Decision Making* (Review of Finance, 2023): when an aggregation platform released a mobile app, which cut the cost of looking at one's finances, non-sufficient-funds fees fell in frequency and amount; the effect on overdraft use and late fees was mixed ([OUP abstract](https://academic.oup.com/rof/article-abstract/27/3/977/6619575), **[summary]**; [Review of Finance blog](https://revfin.org/mobile-apps-and-financial-decision-making/) returned HTTP 425). **Confidence: medium**, and the setting is a bank-linked app. It supports the widget, tile and shortcut (D156) as the highest-value insight surface: the glance, not the report.

### 3.3 Low graph literacy: numbers and tables beat marks (did)
Among 436 US Medicaid adults (85.8% without a bachelor's degree), mean comprehension (0–3) was **table 1.91, bar graph 1.85, icon array 1.80**; graph literacy was "the strongest predictor of graph comprehension" and was well below US norms (1.47 vs 2.21) ([Graph literacy matters, PLOS ONE 2020](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0241844)). The Galesic & Garcia-Retamero line of work found icon arrays help people with low numeracy only if graph literacy is adequate ([search summary](https://pure.mpg.de/rest/items/item_2099200_7/component/file_3565339/content)). Part-to-whole: a 2025 study found pies and bars equally accurate for the part-whole relationship, bars better for ranking ([Hill 2025](https://journals.sagepub.com/doi/10.1177/14738716241259432), 403, **[summary]**). **Caveats:** health-risk tasks in the US, not money in India; differences are small. **Confidence: medium that charts should carry their numbers, low on any ranking of chart types.**

India: MicroSave's oral-user work found numeracy weaker than literacy, with place value a constraint, and other MicroSave work found numeracy common ([MicroSave briefing](https://www.microsave.net/wp-content/uploads/2017/05/Mobile_Wallet_Design_for_Oral_Users.pdf), **[summary]**; CGAP's [smartphone UI/UX principles deck](https://www.cgap.org/sites/default/files/publications/slidedeck/principlesofsmartphonedesign05oct16-161005230428.pdf) came back as binary, so only the search summary: an easy-to-reach balance is reassuring; currency images can help people with numeracy difficulty). The two disagree, which is itself a finding: **do not assume either way; test.**

### 3.4 Said, not did: what Indian users asked for
In the same arXiv study (survey 276, interviews 20, prototype test 34), about 75% said UPI raised their spending, partly from "reduced feelings of guilt". On the prototype: the expense tracker (day and month summaries by category) was "beneficial" to 87.9%; *balance before and after a payment* was wanted by 78.8%; category budget limits were helpful to 54.5%, "unsure" 30.3%; financial tips would reduce spending for only 21.9%; a delay timer 24.2%. Interviewees asked for **percentages beside bar amounts** and for **comparison across months**, and wanted to switch streaks, pop-ups and timers **off**. This is stated preference from one prototype; treat as direction.

## 4. What backfired

1. **A recap that labels the person (did, reported).** Monzo's 2025 *Year in Monzo* told a customer "You foraged and feasted. But mainly, you fast fooded" and put her in the top 15% for a food-delivery app; she took it to the UK Financial Ombudsman, who first said no action, and a senior ombudsman is reviewing on appeal. Monzo said the lines were automated and apologised ([City AM, March 2026](https://www.cityam.com/monzo-slammed-for-shaming-end-of-year-reviews/), via **[summary]**; Guardian original not fetched). Monzo's own 2024 write-up shows the care taken before: a *nice or savage* mood picker with the sharper tone opt-in, about 300 hand-written merchant quips, about 80 end "moods" ([Monzo](https://monzo.com/blog/writing-year-in-monzo-2024)). Even that did not prevent harm once copy was generated at scale. Also: an earlier critique found the recap used only Monzo data, so some insights were wrong **[summary]**.
2. **Persona and "problem area" tone (said).** Cleo's roast mode has fans, but aggregator pages report repetition and insensitivity (one counts 76 reviews, unverified) and a reviewer said it kept flagging daycare as a "problem area" ([FinanceBuzz](https://financebuzz.com/cleo-review), [Best Wallet Hacks](https://wallethacks.com/cleo-review/), **[summary]**; affiliate-style sites, low confidence).
3. **More feedback, more spending at the end (did).** Section 3.1.
4. **A named metric needs its own manual (said by its maker).** YNAB's Age of Money article spends most of its length on what the number is not.
5. **Streaks (said, mixed).** Finding B above; practitioner posts warn that a broken streak makes people quit, with no primary finance study cited **[summary]**. Principle 48 already bans them.

## 5. Transferable patterns, ranked for hisaab

Each is a *proposal*. Fit risk is judged against the constraints; none has been tested with users.

| # | Pattern | Source | What hisaab would do | Fit risk |
|---|---|---|---|---|
| 1 | **Range and roll-over wording near the end of a cycle** | Pocheptsova Ghosh & Huang | Keep BR-7's range line prominent in the last third of the cycle; check that copy says unspent money moves to the days after | Low. Evidence is the weakest link (3.1) |
| 2 | **One neutral comparison line at the same point last cycle** | Apple Card; Copilot MTD | Spends gets one `ink2` line: "₹4,200 less than September by this day." Reuses BR-14's day-of-cycle rule, at total level, no verdict colour, no "good/bad" word | Low. Needs a fully tracked previous cycle and cycles of different lengths (BR-14 already handles both) |
| 3 | **Measure each day against its own share, as a cycle grid** | Cashew heatmap; Money Manager calendar; case study 12's dot ledger; principle 53 | A past-cycle view of the Day Blocks: one cell per day, filled by spent ÷ that day's share, hatched when over. No hue ramp | Medium: no evidence a grid is understood; heatmap colour scales conflict with no-colour rule; cell targets on a small phone |
| 4 | **Rupees kept, not a rate** | Monarch savings rate | A closed cycle says "₹3,400 left over" and *Spent · Saved · Not logged* stays as is. No percentage | Medium: touches G3 (leftover); "left over" must not read as a grade. Rate rejected because of the numeracy evidence (3.3) and YNAB's caveat |
| 5 | **Biggest few entries** | Rocket Money *Largest purchases* | "Biggest three this cycle" in Spends, from existing entries. No merchant, no free-text grouping | Medium: BR-14 #2 already says the biggest in a category; a top-3 list overlaps; notes are messy so "most often" is not safe |
| 6 | **A factual cycle recap, once, on payday** | Copilot Month in Review; Monzo's lessons | One card: spent, saved, left over, biggest day, biggest category, all counts and dates, no adjectives. Dismiss once and it is gone | Medium-high: reopens case study 33's dropped P3 and principle 48's "no come-back prompts" (an in-app card is not a notification); share card is Q4. Needs a blind read of tone |
| 7 | **Ghost line: last cycle on the pace chart** | Spendee (grey previous month) **[summary]** | A faint cumulative line from the previous cycle behind this one | Medium-high: the chart is already seven text elements (case study 21); do #2 first and see if people ask |
| 8 | **A weekday sentence** | Emma (best day); user request | A 4th insight rule: "Saturdays are your biggest day, about ₹X." Only with at least 4 whole weeks, bills excluded as in BR-14 #2 and #3 | Medium: no evidence of value; easy to turn into judgement ("weekend spender") |
| 9 | **Keep "left after this" while logging** | UPI prototype (78.8% wanted it) | Already built as FR-AD-3. Evidence supports it; no change | None |
| 10 | **Keep the row as the chart** | PLOS ONE Medicaid study | *Where it went* already pairs word, %, ₹ and a bar. Any new chart must carry its numbers in words (principle 92) | None |
| 11 | **Spend on the glance, not the report** | Carlin et al.; CGAP "easy-to-reach balance" | Prioritise widget and tile polish (D156) over new Spends views | None |
| 12 | **An off switch for anything extra** | UPI interviews (asked to switch streaks, pop-ups, timers off) | If #6 ever ships, a quiet *Don't show this* beside it, remembered | Low; breaks "no settings" slightly (PLAN §2), so make it a per-card dismissal, not a setting |

## 6. Patterns to avoid
1. **Streaks, badges and "saving streak" counters.** Stated appeal is split (56 / 28 / 16%, Finding B) and the behaviour evidence is practitioner opinion; principle 48 and the CCPA nagging rule stand.
2. **Personality commentary or ranked labels on categories** ("mainly, you fast fooded", "top 15%", "problem area"). Monzo's ombudsman case, and Cleo's flagged daycare. hisaab has no peer data, so a ranking would be invented anyway.
3. **Per-category budgets as the behaviour fix.** One lab study found splitting a budget did not help (confidence low), and only 54.5% in the Indian prototype test thought limits would help. hisaab's limits are off by default (PLAN §2); keep them opt-in and don't promote the limit offer (BR-14 #4) harder.
4. **Named scores and abstract metrics** (savings rate, Age of Money, "health score"). They cost an explanation page; YNAB's own post shows it. Prefer a rupee amount and a date.
5. **Hue-coded share charts.** Apple Card's blended category colours and pies sized by rent fight the no-category-colour rule (principles 37–39) and, on rent day, one slice swallows the rest (Monefy reviewer).

## 7. Implications for hisaab (handed to `design-product`; not approved)
1. **Cheapest first:** #2, the neutral last-cycle line on Spends. It reuses BR-14, adds no chart. Apple Card states the comparison as a message and Copilot as month-to-date figures; only Spendee is reported to draw it (a grey previous month, **[summary]**).
2. **Check what Home already does against #1.** The range line and a roll-over sentence are the only features with behavioural support; verify the copy and the last-days state, and don't replace the range with an exact "₹0 left".
3. **Explore, test first:** #3 (cycle grid) and #6 (payday recap). Both need a blind read; #6 conflicts with the earlier "drop P3" verdict and needs a new row.
4. **Don't build:** a savings rate, streaks, personality copy, merchant lists, category colours, an in-app chat (Google Pay's and Monarch's AI answers need accounts or sync; hisaab's previewed export is the privacy-first equivalent).
5. **Check against DECISIONS:** D9 (no shame moment), D113 (no search), D120 (saved is never spending), D166 (*Not logged* excluded), and case 33's P3 verdict. Insights must keep excluding *Not logged*, *Saved* and *Used* (BR-14).

## 8. Open questions
- Does the range line change what people do in the last week of a cycle? Cheapest test: a 1–2 week diary across a payday with 5 people, with the owner reading logged days and end-of-cycle leftovers by hand (no telemetry).
- Do Hindi/English, low-numeracy users read "₹20K", "₹1.25L" and a day grid? K and L are English abbreviations; the chart labels use them (FR-SP-3). Five-user blind read, including *Where it went* rows vs a bar only.
- Does "left over" read as a grade? Blind read of two wordings.
- Does a small share of people want a weekday sentence, or does it feel like being watched? Interviews ("tell me about the last time you looked at where your money went"), not "would you use".
- Not found: any Indian app's insight screen as pixels; PhonePe or Google Pay's in-app spend view (no official page; the NextLeap case study is a student proposal and its PDF was unreadable); Fi; a Year-in-Review from any Indian app.

## Sources not read, so nothing is claimed from them
Guardian's Monzo story; the Pocheptsova Ghosh & Huang PDF; Monarch's and Realbyte's help pages; Rocket Money's help centre; Emma's help; *The Ostrich in Us* (Olafsson & Pagel), which may bear on people avoiding the app after overspending; the NextLeap PhonePe PDFs.
