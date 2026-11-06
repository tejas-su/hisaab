# 20. Changing income after onboarding

## Job
The user typed their income once, in onboarding (FR-ON-2/3). Later something changes: a raise, a new job, a pay cut, a different payday, a move from salary to freelance, or a single month that came in different. The job: **let the user tell hisaab what changed in one obvious place, so that today's safe-to-spend number is right from the next pay, and what already happened stays as it was.**

## What's wrong today
- **Nothing is built.** SPEC FR-SE-1 lists "Money coming in (edits the income rule; future cycles only; D116)". `lib/settings/` has no income code and `app_en.arb` has no such string.
- **The SPEC row cites the wrong decision.** D116 is about the income copy fitting everyone and says nothing about future cycles. No DECISIONS row records "future cycles only". This needs a row (see *Conflicts*).
- **The model already separates the rule from the money.** `I` is "all *Got* entries dated within the cycle, posted recurring income included" (BR-3). So the salary the engine posted this cycle is a real entry. Changing the rule's amount leaves it alone, and only the next posted pay changes. In practice, "future cycles only" for the amount comes for free.
- **A payday change is different. It moves the cycle itself.** BR-1 derives every cycle's start and end from the *current* pay rule. If payday moves from the 4th to the 25th on 26 Oct, the current cycle becomes 25 Oct–24 Nov. The salary posted on 4 Oct now falls in the *previous* cycle, so `I = 0` and Home shows "No income" (BR-5 state 1), even though the user was paid. Past cycles on Spends and in Ask AI would also be redrawn on the new boundaries. No competitor documents a fix for this (see below).

## Research by source

### Where income is edited
- **PocketGuard:** income is a list of recurring incomes. You edit one from the upcoming/paid list ("tap the income and then the green badge under its name") or from *All Incomes* by swiping left. The name can't be edited. If an income was skipped, you can move its next due date ([PocketGuard help, Recurring income](https://pocketguard.com/help/recurring-income/); **403 to the fetch tool**, so this comes from the search summary). **Placement: the income object itself, in a list.**
- **Goodbudget:** an old support reply sent users to *Setup Budget → Income* to change estimated income. A later update **removed the estimated-income field**. Staff said "there is no equivalent elsewhere within the app", that "the field wasn't used very frequently", and that it confused new users, who expected it to behave like real income. Users replied "I feel like I don't have control anymore and can't figure out how to update my income" and "a deal breaker for me" ([Goodbudget forum](https://forums.goodbudget.com/t/estimated-income-no-longer-part-of-app-update/1724)). For irregular income, Goodbudget advises pooling income "into a one month cushion" and filling envelopes from money already available ([Goodbudget, Multiple or variable incomes](https://goodbudget.com/?p=12586)). The budget period is changed in *Edit Envelopes*, and changing it "will not change when your Envelopes get refilled" ([Goodbudget, Change budget period](https://goodbudget.com/help/budgeting-with-goodbudget/change-budget-period/)).
- **YNAB:** there's no expected-income setting. "You only assign the dollars you have on hand right now", and "You won't assign future income", so upcoming pay is planned with scheduled transactions ([YNAB, Assigning future income](https://support.ynab.com/en_us/assigning-future-income-an-overview-BJsTo0jCq.md)). For irregular income, the question is "What does this money have to do before I'm paid again?" ([YNAB blog, via search](https://www.ynab.com/budget-with-irregular-income/); not opened). **Income is whatever arrived. Nothing needs editing.**
- **Copilot Money:** "there isn't anywhere you'll need to enter your monthly income amount in the app". Income is never tied to spending automatically, and the user sets the budget "based on your personal knowledge of your income" ([Copilot help, Income vs budget](https://help.copilot.money/en/articles/5542019-income-vs-budget)). The same answer as YNAB, reached by bank sync.
- **Monarch:** the budget is based on "how much income you expect to receive that month", and estimates are edited by typing into the box ([Monarch help, Budget](https://help.monarch.com/hc/en-us/articles/360048883631-Budget); **403**, from the search summary). A community API wrapper exposes an `apply_to_future` flag on budget amounts ([monarchmoney docs](https://312-dev.github.io/monarchmoney/docs/api/set_budget_amount); unofficial). That suggests a "this month or all future months" choice, but **I couldn't confirm Monarch's UI**.
- **Simplifi:** a custom income in the Spending Plan applies "only to the individual month you set it for", and changing it for all future months had to be requested as an idea ([Simplifi community #15726](https://community.simplifimoney.com/discussion/15726/how-to-change-custom-income-in-spending-plan-for-all-future-months-edited); the thread body didn't render, so this comes from the search summary). A related thread, "Spending plan changes retroactively?", sits behind a Quicken sign-in and **couldn't be read**.
- **Emma:** the budget period (weekly, monthly, a fixed date, a variable date or the penultimate working day) is changed under *Budget → pencil → Edit Budget → Period*, and "changes to your budget period will apply to **all past, current, and future budgets**" ([Emma help](https://help.emma-app.com/en/article/how-do-i-edit-my-budgeting-period-7b3z5v/)). **The clearest example of a payday change rewriting history.**
- **EveryDollar:** *Safe to Spend* is driven by *Paycheck Planning*, and the setting lives under *Today → menu → Settings* ([EveryDollar help, via search](https://everydollar.help.ramseysolutions.com/hc/en-us/articles/11667520933773-Paycheck-Planning); **403**).
- **Safe To Spend (iOS, a small indie app):** setup is "Enter your paycheck amount and payday schedule". Extra income sources each run on their own schedule, and a new job's income "counts" only once "your first check arrives" ([App Store listing](https://apps.apple.com/us/app/-/id6758524287); there are too few reviews to show any). **A change takes effect from the next real pay.**
- **Rocket Money, Payday View:** pay is detected from at least three paychecks, can't be added by hand, and income "with inconsistent amounts or pay dates, such as commission" can't be tracked ([Rocket Money help](https://help.rocketmoney.com/en/articles/6235627-enabling-payday-view)). **It leaves irregular earners out entirely.**
- **Copilot budgets (an analogue for "from now on"):** editing one month's budget carries forward to later months unless a later month has its own budget, with a choice of "The same budget for all months" or "Different budgets for different months" ([Copilot help, Editing budgets by month](https://help.copilot.money/en/articles/6206293-editing-budgets-by-month)).
- **Google Calendar (the general pattern for recurring edits):** *This event* / *This and following events* / *All events*. Only *All events* changes past occurrences ([Stony Brook IT guide](https://it.stonybrook.edu/help/kb/setting-up-a-recurring-repeating-meeting-in-google-calendar); a third-party guide, since Google's own page didn't come up).

### India
- **Jupiter:** a user complained that "Money deposited on 1st July 3:27am is counted in June month's budget … This will mess up at the monthly tracking we do", and another user had the same problem. There's no staff reply ([Jupiter community](https://community.jupiter.money/t/money-deposited-on-1st-july-3-27am-is-counted-in-june-months-budget/34558)). Pay landing on a cycle boundary is a real complaint. A "choose my own pay day" thread turned out to be about salary advances, not budgeting ([Jupiter community](https://community.jupiter.money/t/ability-to-choose-my-own-pay-day/1626)).
- **Fi, axio (Walnut):** I found no public material on editing income or a salary date. axio's blog describes only a "monthly budget planner" ([axio blog](https://www.axio.co.in/blogs/managing-money-with-axio)). Wallet (BudgetBakers), Spendee and Money Manager (Realbyte): this search found nothing on editing income or a repeat "only this / all future". **Not cited as patterns.**
- **Context:** about 76% of Indian workers aren't salaried (PLFS 2025, already cited in D116). For most of hisaab's users, "my income changed" means a month that was different, not a raise.

### Complaints and pitfalls
- **Not being able to edit income at all:** Goodbudget's removal (above). An App Store reviewer of Budget Bestie couldn't edit the income they had entered, and the developer pointed them to the transactions section (search summary of [App Store](https://apps.apple.com/us/app/budget-bestie/id6460258044); not opened). A lender's guide lists "asks you to input a fixed monthly income and won't let you change it easily" as a warning sign for variable earners ([Gerald guide, via search](https://joingerald.com/learn/financial-wellness/how-to-choose-budgeting-app-income-drops); a vendor blog, low confidence).
- **Changing every future month by hand:** Lunch Money: "The only option seems to be to manually go to each future month … and overwrite the value. What happens when we experience a financial change …?" There was no staff reply ([Lunch Money feedback](https://feedback.lunchmoney.app/budget/p/overwrite-future-months-with-new-value)). Simplifi's per-month income has the same problem (above).
- **Rewriting history:** Emma applies a period change to all past budgets (above). YNAB's own docs warn that editing a target of a former type "may [make it] disappear in previous months" ([YNAB, How to use targets, via search](https://support.ynab.com/en_us/how-to-use-targets-rk5kkI9ks.md)). Monarch users report that halving annual income makes the app "assume yearly income to be halved moving forward" (Reddit snapshot, via search; anecdotal).

## Synthesis

**What apps do:** every app studied puts income editing in a settings-like place (an income list, Edit Envelopes, Edit Budget, Settings). None puts an income editor on the main screen. Apps that budget from money that has actually arrived (YNAB, Copilot, Goodbudget's cushion) have no "change income" problem, because a different month is simply a different entry. Apps that store an *expected* income either apply an edit to one month only, which pushes the work onto users (Simplifi, Lunch Money), or rewrite every period (Emma). None documents how the period *containing* a payday change is handled.

**What users say:** they want an obvious place to change income ("can't figure out how to update my income"), they want "from now on" without editing month by month, and they are upset when their history or month boundaries move.

**Confidence:**
- **High** that placement belongs in settings, on the income object itself (consistent across 5+ apps' official help).
- **Medium** that "from the next pay" is the expected default (Simplifi, Safe To Spend and the calendar pattern agree; there's no usability data).
- **Low** on the payday-change bridge (no source documents it; this is my reasoning from BR-1).
- **No primary user research yet.**

## Patterns compared

### What an amount change applies to

| Option | Who | Current cycle | Past | Effort | Fit for hisaab |
|---|---|---|---|---|---|
| A. Per period only | Simplifi | That month | Untouched | Repeat each month | No: a raise needs re-entry |
| B. Ask "this / following / all" | Google Calendar, Monarch (unconfirmed) | User picks | *All* rewrites | 1 more question | Too much for the 5-year-old bar |
| C. All periods | Emma (period) | Changes | **Rewritten** | 0 | No: breaks history and Ask AI |
| **D. The rule changes the next pay; this cycle's posted pay is a normal entry, edited where it sits** | hisaab's model (BR-3); Safe To Spend; YNAB/Copilot in spirit | Unchanged unless the entry is edited | Untouched | 0 questions | **Yes** |

D splits "my pay changed" (the rule, in Settings) from "this pay was different" (the *Got* entry, edited like any entry). That is *This event* versus *This and following*, with no dialog, because the two live in different places.

### What a payday change applies to

| Option | Current cycle | Past cycles | Risk |
|---|---|---|---|
| a. Recompute everything from the new rule (BR-1 today) | Jumps to new boundaries; this cycle's pay can fall outside it | Redrawn | `I = 0` "No income" on a paid user; Spends history shifts (as Emma) |
| **b. Bridge: the current cycle runs until the day before the new payday; past cycles keep their boundaries** | Stretches or shrinks once; the posted pay stays inside it | Frozen | Needs the pay rule's history (an effective-from date) or stored cycle starts |
| c. The new payday takes effect only after this cycle ends | Unchanged | Frozen | Same storage need; a payday moved *earlier* posts the next pay in the old cycle |

## Implications for hisaab (for design-product)
1. **Placement: a "Money coming in" row in Settings → Money, opening a sheet in the bill-sheet pattern (case study 16, D118).** It's a summary of the rule with Change rows: *Amount*, *When it comes*. Each row asks its one onboarding question again and saves on its own. That's no new pattern and no new screen type.
2. **The amount applies from the next pay, and the sheet says so in one sentence.** After saving: "Changed. Your next pay, on 4 Dec, counts ₹52,000." The money already posted this cycle stays. If it was different, the user changes that *Got* entry in the list (FR-SE-1 for rules, the entry tray for entries). Don't ask "this or future".
3. **A one-off different month is an entry, not a rule change.** For *It changes* users, this is already the model: *Got* entries plus the "Starting guess" (D27, D117). Switching *When it comes* to or from *It changes* must live in the same sheet, because a salaried user turning freelance is the commonest "income changed" case in India.
4. **A payday change must not redraw history or leave this cycle without its pay.** Use bridge option b: the current cycle ends the day before the new payday, and earlier cycles keep their dates. This touches BR-1 and needs the pay rule to carry an effective-from date. The sheet states the result in words: "This month runs till 24 Nov. After that, payday is the 25th." This is a BR change, so it's **design-product's call**.
5. **The Home hero changes at once, with no celebration.** A change to the rule's amount leaves `I` alone until the next pay. A payday change alters `D` and so `A` today, so the sheet's sentence must name the new daily share if it changes ("Today's share is now ₹1,640").

## Conflicts
- **SPEC FR-SE-1 cites D116 for "future cycles only", but D116 doesn't say that.** A DECISIONS row is needed for income-rule edits.
- **BR-1 derives every cycle from the current pay rule.** Bridge option b needs rule history and amends BR-1, E-cases and Spends' cycle switcher (D52 cycle names).
- **D3** ("one Settings override, month start on the 1st") is unaffected, but the *My month starts on* row has the same redraw-history risk as a payday change. The same bridge rule should apply.

## Principles (proposed; not appended to `principles.md` in this change, as asked)
- **Edit the rule where rules live, and the money where money lives.** "My pay changed" goes to the rule in Settings, and "this pay was different" goes to that entry. Never ask "this or all future". *Sources:* YNAB future income; Copilot income vs budget; Google Calendar recurring edits; Simplifi per-month income. *Applies to:* the income sheet, bills, savings.
- **A change to recurring money takes effect from its next occurrence and never rewrites a past one.** Say the date it takes effect in the confirmation. *Sources:* Safe To Spend listing; Emma (counter-example); Lunch Money and Simplifi requests. *Applies to:* income, bills (D34 already does this), savings.
- **Moving a cycle boundary bridges the current cycle; it never redraws closed ones.** *Sources:* Emma (counter-example); Jupiter boundary complaint; Goodbudget (a period change doesn't move fills). Low confidence. *Applies to:* payday change, month start on the 1st, BR-1.
- **Income must always be editable from one obvious place.** Removing or hiding it costs trust. *Sources:* Goodbudget forum; Budget Bestie review; Gerald guide. *Applies to:* Settings → Money.

## Sources (candidates for `sources.md`)
- [Emma help](https://help.emma-app.com/): fetches cleanly; clear statements of period behaviour.
- [Copilot help](https://help.copilot.money/): fetches cleanly.
- [PocketGuard help](https://pocketguard.com/help/) and [EveryDollar help](https://everydollar.help.ramseysolutions.com/): **403** to the fetch tool, so read them in a browser.
- [Simplifi community](https://community.simplifimoney.com/): thread bodies often don't render, and some threads sit behind a Quicken sign-in.
- [Jupiter community](https://community.jupiter.money/): fetches; mostly user posts with few staff replies.
- [Goodbudget forum](https://forums.goodbudget.com/): fetches, with staff replies.

## Open questions
1. **Do Indian users think "my income changed" mostly means a raise, a different month, or a moved payday?** Run 5 interviews (Mom Test: "Tell me about the last time your pay was different from usual").
2. **Bridge or wait (option b vs c)?** Run a 5-user think-aloud on low-end Android. Task: "Your company moved payday to the 25th; tell the app." Measure success, errors, SEQ, and whether users can say what happens to this month.
3. **Should payday morning offer "Pay came in: ₹45,000 · Change" on Home** (the instance edited where it appears)? It would reuse the one nudge slot (FR-HO-3). It needs a diary study across a payday (as case study 11) before adding anything to Home.
4. **Rule history storage:** an effective-from date on the income rule, or stored cycle starts? This is a data-model question for design-product and engineering.
