# 34. Fix my number: can people answer "How much money do you have right now?" in one number

> **Outcome (2026-11-13): desk research done, user test planned and not run.** Nothing here is approved. It hands `design-ux`, `design-content` and `design-validation` a starting wording, a test script and the guardrails. No change to SPEC, PLAN, UI_DESIGN, DECISIONS or code. The owner's answers in case study 33 ("Owner answers") are binding and are not reopened.

## Question
Case study 33 §4.1 proposes *Fix my number* (P1): the user says how much money they have, and hisaab posts one *Spent* (or, when the real figure is higher, one *Got*) entry noted "Not logged" for the gap. P2′ (§4.2) turns a yearly cost into a monthly *saving*, with a "used" action (owner answer P2′-1) for the day it is paid.

The riskiest assumption (§7): **people can name one number for "money I have right now"** (bank, cash, several accounts, money held back), so the app can subtract bills `B` and savings `K` (SPEC BR-3) and correct the hero. This study asks:
1. How do other apps ask for, record and talk about a balance correction, and what do users complain about?
2. What evidence is there that people know their balance?
3. How do other apps let a user spend from a set-aside pot (P2′)?
4. What should the five-person test be, and what should design start from?

## Method and what I could not do
- **Desk research and competitive reading**, the cheapest method that can change the decision (no build, no recruitment). Sources are in the table below.
- **I cannot run the user test.** I have no participants, no phone and no way to observe anyone. Section "Test plan" is a script for the owner to run. Everything under "Findings" is desk evidence; nothing is measured on hisaab users.
- **Not read, so not claimed:**
  - YNAB support pages (`support.ynab.com`): the fetch returned only each page's one-line description. The reconcile wording below is from a search summary of those pages.
  - BudgetBakers Wallet help and Money Lover help: both returned **403**. Their steps are from search summaries.
  - PocketGuard's "inaccurate balance" help page: **403**. Search summary only.
  - Realbyte's Money Manager "balance adjustment": no page found, so I say nothing about it.
  - Spendee's "update balance", Jupiter, Fi, Fold and axio: no help page describing a balance true-up was found. Case study 31 already notes the Indian apps are SMS or Account Aggregator based; I found no evidence they ask for a balance.
  - YNAB targets and Goodbudget envelopes as sinking funds: no readable official page; not claimed.
  - Simplifi's community thread on "spending without affecting the saved amount" sits behind a sign-in; I have only the search summary.
  - Jupiter pots: nothing relevant found.

## Findings

### A. How other apps true up a balance (confidence: medium on mechanism, low on wording)

| App | What it asks | Words | How the gap is recorded |
|---|---|---|---|
| YNAB | Whether the bank's balance matches the app's *cleared balance*; if not, the user enters the bank's figure | "Looks Good" or "Let's Fix It"; "Create Adjustment & Finish" ([search summary of YNAB's reconcile guide](https://support.ynab.com/en_us/reconciling-accounts-a-guide-BJFE3fHys)) | A visible *Reconciliation Balance Adjustment*. A reconciled transaction can't be unreconciled, but a wrong adjustment can be deleted and reconciled again. YNAB advises against its manual adjustment ([balance adjustments guide, description only](https://support.ynab.com/en_us/balance-adjustments-a-guide-rko4OwILs)) |
| Wallet (BudgetBakers) | Tap the pencil next to the current balance of one account | "Adjust with a record" or "Adjust initial balance" ([help article, search summary; page 403](https://support.budgetbakers.com/hc/en-us/articles/7149497597970-Adjust-Incorrect-Balance)) | A balancing record, or a silent change to the starting amount. Works only for manual accounts |
| Money Lover | Edit the wallet's balance | "Adjust wallet's balance" | An income or expense transaction, **excluded from totals by default** ([help, search summary; page 403](https://moneylover.zendesk.com/hc/en-us/articles/35569781199001-Adjust-wallet-s-balance)) |
| Cashew | Edit an account, then *Correct Total Balance* (or *Transfer*) | "Balance correction" | A transaction that is "not globally categorized by Cashew as Income or Expense" ([Cashew FAQ](https://cashewapp.web.app/faq.html); only the opening lines were returned) |
| Goodbudget | Edit the account balance to "accurate as of today" | "Adjustment" line | An *Adjustment* item; because accounts and envelopes are "the same money", it shifts *Unallocated* ([forum thread](https://forums.goodbudget.com/t/fix-account-balance-without-affecting-envelopes/534)) |
| PocketGuard | No balance edit found for cash accounts; add transactions or "corrective" ones excluded from calculations | n/a | Corrective transactions, per [search summary of its help](https://pocketguard.com/help/track-cash-in-pocketguard/). Its *In My Pocket* subtracts bills and goals from available cash and shows one figure, the nearest thing to hisaab's derivation |

What the pattern says:
1. **Every app asks per account, in the user's bank's own terms** ("current balance", "bank's balance"). None asks one number across accounts and then derives a spendable figure. hisaab's question is a different, harder one: it asks for money across accounts and the app subtracts `B` and `K`. No precedent tests that.
2. **The gap becomes a visible entry in most apps.** Wallet offers both, and the maintainer of Monekin, asked to add this feature, wrote that "if you adjust the balance, there is no record of it" and called the silent edit the weakness ([Monekin issue 335](https://github.com/enrique-lozano/Monekin/issues/335)). The owner's answer P1-3 (visible in Spends and Ask AI) matches this.
3. **Most apps keep the adjustment out of income and expense** (YNAB, Money Lover, Cashew). hisaab's is deliberately a *Spent*/*Got* entry (owner answer P1-2), since the pool needs to move. It must therefore be filed under a hidden category and kept out of today's share, as case study 33 §4.1 says. Nothing in the desk research contradicts that.
4. **Complaints.** Goodbudget users can't fix an account balance without disturbing something else, and the staff answer is "you can't adjust an account balance without affecting your envelopes" ([same thread](https://forums.goodbudget.com/t/fix-account-balance-without-affecting-envelopes/534)). The same coupling applies to hisaab: the user's one number moves the whole pool. Another user in that thread had added £900 years earlier "to rebalance" and was still asking whether it worked (no answer given): a correction nobody can later explain is a trust problem.
5. **Undo is the safety net apps rely on** (YNAB: delete the adjustment and redo). hisaab's Undo plus an editable entry is in line.

### B. Do people know their balance? (confidence: low)
- **Indian evidence on how well people know a balance: none found.** I searched for surveys of how often Indians check their bank balance in UPI apps. The only results concerned NPCI's rule that limits a UPI app to [50 balance checks a day](https://trak.in/stories/from-august-1-upi-allowed-to-check-balance-only-50-times-a-day/), introduced to reduce "repetitive API requests and growing system load". The article says nothing about typical frequency. The cap shows balance-checking is common enough (and automated enough) to need a limit. It does not show that people can *state* a balance or a total.
- **US vendor polls**, via search summaries only, not read in full: Cushion/OnePoll via [Yahoo Finance](https://finance.yahoo.com/news/know-bank-account-balance-55-110026373.html) reports 84% think they could be within $200 of their balance and 19% think they would know it exactly; [US News](https://www.usnews.com/banking/articles/survey-nearly-1-in-3-avoid-checking-bank-balances-due-to-anxiety) reports about a third avoid checking due to anxiety. These are vendor polls on US adults, self-reported, and say nothing about cash or several accounts. Treat them as a reason to expect a rough answer, not as proof.
- **What this means:** the cheap, defensible part (one bank account, looked up on a phone) is likely fine. The part nobody has evidence on is the sum across accounts and cash, and the "what is mine to spend" question. The test must target those.

### C. Two structural problems in the one-number question (my analysis from SPEC BR-3; not user evidence)
1. **Opening balance.** `I` counts only *Got* entries dated within the cycle, and last cycle's leftover is not counted (case study 33, review table). A person who keeps any buffer, or who saved last month's leftover, has real money *higher* than the app expects every time. With "How much money do you have right now?" they will give the full bank balance, and the *higher* branch (owner answer P1-2) would post a *Got* for the whole buffer. That inflates the hero by the buffer divided by the days left. The mid-cycle installer on day one is the extreme case: the app can't know their pre-cycle money at all. Whether to anchor on the first fix, to scope the question to this month's money, or to cap the higher branch is a `design-ux` call. This study only says the test must find out how many users have a buffer and whether they would include it.
2. **What `K` means.** `K = R + Sv_before + Sv_rule_today` (BR-3). `R` is money still in the user's account waiting to be saved; `Sv_before` has already left, if it really went to an RD or pot. A user who states the account balance after an auto-debited RD has already lost `Sv_before`; a user who states "all my money" has not. The helper line "We'll take out your bills and savings" may double count. The test must check what people include (see the "what did you count" probe).

### D. Spending from a set-aside pot (P2′, confidence: medium on mechanism)
- **Copilot:** money allocated to a savings goal "counts as saved rather than spent"; the user can spend it any time and "the Goal's balance adjusts". Spending is recorded by opening the goal and linking a transaction ("Update progress", "Add transactions", "Add to goal"). Two settings exist: *Reactivate When Funds Dip* and *Update Budgets on Spend*, which removes linked spending from category totals and shows it separately ([Copilot help](https://help.copilot.money/en/articles/11100511-spending-from-savings-goals)). Spending from the pot is its own action, kept out of the month's spending.
- **Monzo:** a regular pot can pay a bill; "the money moves from the Pot into your main account to pay it", and any shortfall comes from the main balance. The user logs nothing ([Monzo help](https://monzo.com/help/budgeting-overdrafts-savings/web-bill-pots)). Manual *Withdraw* also exists ([search summary of Monzo's pot help](https://monzo.com/help/budgeting-overdrafts-savings/moving-money-to-from-pots)).
- **Simplifi:** "spend from savings goal" is a listed plan feature, but users ask for a way to link an expense to a goal; the workaround is a manual withdraw, then excluding the transaction from the spending plan. A user calls it confusing that spending lowers the amount saved so far and can't be zeroed ([community threads, search summary; the confusing-saved-amount thread needs a sign-in](https://community.simplifimoney.com/discussion/12572/make-it-easier-to-spend-from-pre-funded-savings-goals-or-sinking-funds)).
- **Implications for hisaab's "used" action:** it should be one action on the saving, it should reduce the savings total and not appear as new spending (the money was already counted by `K` each month; counting it again would double charge the hero), and the word for it needs a blind read. Candidates: "Used", "Paid from this", "Spent from savings". "Spent" invites confusion with the *Spent* entry kind. Nothing found tells how Indian users think about yearly costs (insurance, school fees); the test asks.

## Test plan: five people, owner runs it (no build needed)

**Who runs it:** the owner, in a hallway or on a call, 20 to 25 minutes each. The owner knows the product, so the main risk is leading people. Follow *The Mom Test*: ask about the past, never "would you use", never explain a word before the person has read it.

**Recruit (5):** 3 to 4 UPI-first people who pay in a mix of UPI and cash; at least one with two or more bank accounts, one mostly paid in cash or with irregular income, one who prefers Hindi, one who does not know what "budget" means. No finance workers. One of the five must be on a low-end Android phone. Not family members who know the app. Pay in tea, not money. Confidence of any result from five is low to medium: it finds problems, it does not size them.

**Material to prepare:** three cards on paper or a phone image, shown one at a time, rotated in order across participants:
- Card 1: a Home screen with a row reading **Fix my number** (no explanation).
- Card 2: a Spends list row reading **Not logged** with an amount (no category icon explained).
- Card 3: a keypad page with the title **How much money do you have right now?** and nothing else.
- Card 4 (later): the preview line, "That's ₹4,200 less than hisaab thought. Each day gets ₹350 less."
- Card 5 (later): the same with "more", and "Spot on. Nothing to fix."
- Card 6: a saving row named *Car insurance* with a button reading each of *Used*, *Paid from this*, *Spent from savings* (one word per card).

**Consent and privacy:** say what you record and that they can skip any question. Never write down a real balance. Part C asks them to look up their balances **privately**; they tell you only the gap, never the figures. No screenshots of their banking apps. Notes carry a participant letter only.

### Script
| Step | Mins | Do and ask (exact words) | Record |
|---|---|---|---|
| 0 Intro | 2 | "I'm testing an idea, not you. There are no wrong answers. Please think out loud." | Consent given |
| 1 Past behaviour | 5 | "Tell me about the last time you wanted to know how much money you had. What did you do?" Then: "Which app or place did you look?" "Did you add anything up?" "Last time you had cash on you, how did you know how much?" "Is there money you don't think of as 'yours to spend', for example savings, rent money, or a family fund?" | Which apps; how many accounts; cash yes or no; any buffer or set-aside; anything they sum |
| 2 Blind read of words | 5 | Show Card 1: "What do you think this says? What would happen if you tapped it?" Card 2: "What do you think this is? Who put it there? How does it make you feel?" Card 3 comes in step 3. | Their own words verbatim; right, partly right or wrong reading; any alarm or blame |
| 3 The read | 6 | Show Card 3, **cold**: "Please answer as you would. Say a number." Wait. Do not help. Then, in a rotated order, ask the same with a variant: V2 add the line "Bank and cash together. We'll take out your bills and savings."; V3 "How much do you have in your bank right now?"; V4 "How much can you spend before payday?"; V5 two fields, *Bank* and *Cash*. Each person sees V1 first, then **two** of V2 to V5, so each variant is seen by at least 2 people | For each: time to answer (seconds); asked "which one?"; said a number; "what did you count?" (open: "Tell me what you included"); rounded or exact; wanted to open an app |
| 4 Check, privately | 3 | "Please open your bank or UPI app now, in private, and add up what you'd normally count. Don't tell me the numbers. Just tell me how far off you were, in rupees or in percent." Optional if they decline | Gap bucket: under ₹100, ₹100 to ₹1,000, over ₹1,000; direction (they over or understated); what was missed |
| 5 The preview | 3 | Show Card 4: "Say this back in your own words." Then Card 5. "What would you do next?" "Who is this telling off?" | Correct reading; any blame; understanding that today gets less (or more) |
| 6 Yearly cost (P2′) | 3 | "Tell me about the last big once-a-year cost you had. How did you pay it? Did you plan for it?" Then Card 6, one word at a time: "When you've paid it from this saving, which word would you press? What does it mean?" | Past behaviour; words picked; whether "Spent" is read as a new expense |
| 7 SEQ | 1 | After steps 3 and 5: "How easy was that, 1 to 7?" (SEQ) | Two scores each |
| 8 Close | 2 | "Is there anything you expected me to ask?" | Anything unprompted |

**Record separately: what they did** (time, counted items, the gap) **and what they said** (opinions). Do not rank on opinions.

### Pass and fail (my proposed thresholds, not published norms)
| Measure | Pass | Fail |
|---|---|---|
| V1 produces one number, unprompted, in under 20 s | 4 of 5 | 2 or more say "which account?" or give a range |
| What people counted agrees with what the app will subtract (bank plus cash, **excluding** a buffer or set-aside they described in step 1) | 4 of 5 | 2 or more include money the app would not expect (a buffer, a family fund) |
| Stated figure within ₹1,000 or 5% of their real total (step 4) | 4 of 5 | 2 or more over ₹1,000 or 10% off, or understate cash |
| Blind read: "Fix my number" understood as correcting the app's figure | 4 of 5 | 2 or more read it as editing the *income*, deleting entries or "fixing a bug" |
| Blind read: "Not logged" read as "not recorded by me" with no blame | 4 of 5 | 2 or more read it as an error, a failed payment or a rebuke |
| Preview said back correctly | 4 of 5 | 2 or more misread the direction ("more" vs "less") |
| SEQ after step 3 | median ≥ 6 | median ≤ 4 |

### What each outcome decides
| Outcome | Decision handed to design |
|---|---|
| V1 passes on reading and on gap, and no one counts a buffer | Build one number as in 33 §4.1. Start the wording from V1 |
| V1 passes but the helper (V2) is needed to avoid counting savings | Keep V2's helper line; carry it into the page's copy |
| Some say "which account?" or sum slowly, but **bank and cash** are the only two parts | Keep one number with a hint, and test V5 (two fields) in a second round. If V5 wins on time and gap, show *Bank* and *Cash* only on the page, still one Fix it key |
| 2 or more have a buffer or a set-aside they would include | The question must be scoped, V4 style ("for this month") or the first fix must set an anchor; do not post a *Got* for the whole buffer. Route to `design-ux` before anything else |
| Gap in step 4 is mostly **under**stated cash | Add nothing yet, but the preview must say "about"; rerun with cash-heavy users |
| "Fix my number" misread | Try *Correct today's number*, or put the question on the page and name the row by the question |
| "Not logged" feels like blame | Try *Added to match*; check with `design-content` |
| People choose "Used" for yearly costs and do not read it as new spending | Use "Used" as the saving's action. If "Spent from savings" is chosen, add a words key under it saying it is not counted again |
| Fewer than 3 of 5 manage the task at all | Stop P1 as designed and return to the owner |

## Recommendation (for the test and for design to start from)

1. **Start the design with V1 plus the helper line (V2):** page title "How much money do you have right now?", one line beneath: "Bank and cash together. We'll take out your bills and savings." This is the owner's and `design-product`'s working copy. The test decides whether the helper line is needed; it does not change the starting point. It gives the helper a job: say what is counted.
2. **One number, not two fields, to begin.** The Add path's whole rule is speed (CLAUDE.md), and every extra field costs a step. One number is also what the person reads off a UPI app. Keep *Bank* and *Cash* as the fallback only if the test shows several people can't sum in their head (V5). I did not find a competitor doing the one-number-across-accounts version, so this is the least-evidenced choice in the study.
3. **Guardrails** (for `design-ux` to take or reject):
   - **Preview before saving, in both directions, and an Undo** (in 33 §4.1 and consistent with the way apps treat corrections as visible entries).
   - **Say what is counted** in a sentence; and decide how the app treats money the user keeps outside the month's pool (opening balance, finding C1) before a *Got* branch is built. Do not post a *Got* that is large relative to the cycle's income without a second question ("Is all of this for this month?"); the threshold is a design question.
   - **Ask for the sum after the user's own subtraction, not before:** if the test shows people hold back money, offer "money you can spend" wording (V4) rather than a longer helper.
   - **Show "about" in the preview** when the user's figure is a round number, since people answer roughly.
   - **Keep the entry visible and editable** (owner answers P1-3), out of today's share, out of *your usual* and the morning note (case study 33 §4.1).
   - **Never ask for a bank account number, a login or a balance screenshot.** The figure is typed.
4. **P2′:** put the "used" action on the saving, reducing the pot and not counted as spending again. Test "Used" against "Spent from savings" in step 6.

## Open questions
- Does the Indian user who has several bank accounts and a UPI wallet give a total, or only the account they checked last? (No evidence; test steps 1 and 3.)
- How big and how common is the opening buffer, and does the owner want the *higher* branch capped? (Owner and `design-ux`.)
- Is `Sv_before` out of the user's balance for typical hisaab users (RD auto-debited) or still in? (Test step 1.)
- Do Hindi speakers read "Fix my number" the same way? Hindi is deferred, but the English words still need a read by Hinglish speakers.
- Are there Indian apps (Fold, axio, Jupiter) with a true-up? None found; a hands-on look at the apps would settle it.
- Conflicts with `docs/DECISIONS.md`: none found. D120 and D123 (hidden categories) and the owner answers stand.

## Sources
Read in full: [Goodbudget forum thread](https://forums.goodbudget.com/t/fix-account-balance-without-affecting-envelopes/534), [Monekin issue 335](https://github.com/enrique-lozano/Monekin/issues/335), [Copilot help](https://help.copilot.money/en/articles/11100511-spending-from-savings-goals), [Monzo help](https://monzo.com/help/budgeting-overdrafts-savings/web-bill-pots), [trak.in on UPI balance-check limits](https://trak.in/stories/from-august-1-upi-allowed-to-check-balance-only-50-times-a-day/). Partly read: [Cashew FAQ](https://cashewapp.web.app/faq.html) (opening lines). Search summaries only: YNAB reconcile and balance-adjustment guides, BudgetBakers Wallet and Money Lover help (403), PocketGuard help (403), Monzo pot withdraw help, Simplifi community threads, Cushion/Yahoo Finance and US News balance polls. Internal: `docs/SPEC.md` BR-3 and BR-4; case study 33.
