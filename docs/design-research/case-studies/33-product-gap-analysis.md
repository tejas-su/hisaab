# 33. Product gap analysis: what still makes life hard, and what to add

> **Outcome (2026-11-13): proposed, not approved.** Internal analysis only. No DECISIONS row, SPEC or UI_DESIGN change yet. Handed to `design-product` for review and routing. **Reviewed by `design-product` on 2026-11-13** (see the last section; the verdicts there reshape P2, P3, P4, P7 and P8). Still not approved.

## Job
Find where hisaab still fails its one question, *"how much can I safely spend today?"*, and which features would make the user's life easier without breaking the "5-year-old" bar, the Add path (Add → digits → Next → tile), zero-config (PLAN §2) or the no-network rule.

## Method and caveats
- Read `docs/PLAN.md`, `docs/SPEC.md` (BR-1 to BR-17, FR-*, E1–E71, Q1–Q9), `docs/DECISIONS.md` (D1–D158) and case study 31.
- Checked the code and `lib/l10n/app_en.arb` for what is built: no CSV export UI, no single-limit editor, no app lock, no logging reminder; bills are monthly only.
- **Not done:** no user interviews, diary study or usage data. Every severity below is a judgement from the spec and case study 31's evidence, not measured.
- Already deferred by the owner and left out: Hindi, payment-notification capture, cash/UPI split, any monetisation.

## Where hisaab stands
It owns a spot no popular India-first Android app holds (case study 31): one daily number that already counts bills, savings and the days to payday; changing and card bills handled properly (D123); cycles that follow payday (D3); no network, account or analytics; a previewed Ask AI export; no shaming colours; 4-tap entry.

The main risk is that **the number drifts from reality without the user noticing**, which erodes trust. Most gaps below trace back to it.

## Gaps

### G1. The number goes wrong silently (high)
- **Forgotten entries** (a cash spend, a missed day, an unlogged UPI payment) leave today's share too high. Nothing notices, and there is no one-step fix.
- **A mid-cycle install inflates the first cycle** (SPEC Q6): the whole salary counts, spending before install is unknown. "Corrects itself at the next payday" can mean up to 30 days of a wrong number during the user's first impression.
- **Nothing brings the user back to log.** "Forgot to open it" is the top quit reason in case study 31 (42%, vendor data). Reminders exist only for bills (D126).

### G2. Expenses that aren't monthly aren't modelled (high)
Bills are monthly only (D35). Yearly or seasonal costs (insurance premiums, school fees per term, vehicle insurance, Diwali, weddings, annual subscriptions) land in one cycle and push the user into *Over for the cycle* for a cost they knew was coming: the shame moment D9 avoids.

### G3. Leftover money disappears at payday (medium-high)
`I` counts only *Got* entries dated inside the cycle (BR-3), so last cycle's leftover is not counted. That's safe, but the careful user gets no visible reward, and there is no "cycle closed" moment (principles 44–45; the share card is Q4, pushed to v1.1).

### G4. Planned work not finished (medium)
| Item | Status |
|---|---|
| Change **one** category's limit | Missing; only "Use these limits" (accept all). *Set a limit* waits for a design (D51) |
| CSV export | M6; no UI. CSV exists only inside the Ask AI prompt (`lib/ask_ai/domain/prompt_csv.dart`) |
| Accessibility pass | M6, pending |
| *This week* and the morning note | Strings and widgets exist; check against M3's "done when" |

### G5. Data safety on one device (medium)
Backup is manual only and never nags (BR-16). With no sync, a lost phone without a backup loses everything. There's no app lock (Monefy, Cashew and Money Manager have one).

## Proposals

### Tier 1: keep the number trustworthy
| # | Feature | What the user sees | Fit | Effort |
|---|---|---|---|---|
| P1 | **"Fix my number" (true-up)** | A quiet way to answer "How much do you really have left?" on the keypad. The app posts one *Spent* entry in *Other*, noted "Not logged", for the difference, and the hero corrects itself. The same question optionally closes Q6 in onboarding ("Already spent some this month?") | Reuses the keypad and BR-3; no setting; doesn't touch the Add path. Open: where it lives (Home, Settings, the over card), and what to do when the real figure is *higher* than the app's | M |
| P2 | **Yearly and occasional bills** | The bill sheet gets "Every year on {date}" or "Every 3 months". The app sets aside 1/12 (or 1/3) each month, as savings do (D120), so the bill's day doesn't sink the hero | Fits BR-3's "set aside before its day". Reverses part of D35 (monthly only), so it needs a new decision | M–L |
| P3 | **Payday close and carry-over** | On payday morning, once: "October closed with about ₹3,400 left." *Add to this month* (a *Got* "From October") or *Put in savings* | The missing peak-end moment (case study 11); once a cycle, so never noise | M |
| P4 | **Evening nudge (opt-in)** | About 21:00, only on a day with no entries: "Anything to add for today?" A tap opens the keypad. Asked once; no streaks | Case study 31 item 4; reuses D126's notification setup | S |

### Tier 2: finish and protect
| # | Feature | Notes | Effort |
|---|---|---|---|
| P5 | **Set a limit** for one category | A *Where it went* row opens a keypad sheet in the bill-sheet pattern; unblocks D51 | S–M |
| P6 | **CSV export** | A *Your hisaab* row reusing `prompt_csv.dart` and the *Save to* picker | S |
| P7 | **Backup safety net** | A single soft line after 30 days without a backup, or a weekly backup to a folder the user picked once (persistent folder grant, no network). Conflicts with BR-16's "nothing ever nags" and case study 23's "no folder auto-backup in v1" | S / M |
| P8 | **App lock with the phone's own lock** | One *Your hisaab* row; device credential, not a custom PIN | S |

### Tier 3: explore later
- **"Can I afford it?" without logging:** FR-AD-3 previews the effect only while logging. A planning answer for a future buy ("₹15,000 phone on the 20th → each day gets ₹X less") would keep the question in the app instead of in Ask AI.
- **Udhaar (money lent and borrowed):** an Indian need, but a different job (case study 25). Only if users ask.
- Voice entry, CSV import from Money Manager or Monefy, and Hindi once un-deferred.

### Don't
Bank sync or Account Aggregator, cloud sign-in, accounts and wallets, in-app AI chat, streaks or badges, category colours, ads (case study 31; D9, D15; owner: never monetised).

## Recommendation
1. **P1, Fix my number:** the cheapest protection for the core promise; closes Q6; makes any forgotten spend recoverable in about 5 seconds.
2. **P4, evening nudge:** the smallest build here, aimed at the top quit reason.
3. **P2, yearly bills:** removes the biggest predictable shock.

## Risks
- P1 could become a crutch that hides poor logging; the "Not logged" entry must stay visible in Spends and Ask AI.
- P2 and P7 reverse earlier decisions (D35; BR-16 and case study 23), so each needs a DECISIONS row.
- P3 and P4 add moments to a calm app; both need a blind read for tone.
- None of this is validated with users.

## Design-product review (2026-11-13)

Reviewed against SPEC (BR-3, BR-8, BR-9, BR-12, BR-16, Q4, Q6, FR-HO-3), DECISIONS (D9, D35, D51, D120, D123, D126, D153–D156), case studies 11 and 31 and `principles.md`. Docs only; no code was read, so "built" claims in G4 are not re-checked here. Nothing in SPEC, UI_DESIGN, PLAN or DECISIONS was changed.

### 1. Checks against the docs

| Claim in this analysis | Check | Result |
|---|---|---|
| BR-3: last cycle's leftover is not counted | `I` is "all *Got* entries dated within the cycle" (SPEC BR-3) | **True.** But the money is not lost: it stays in the user's account and the user can log it as *Got* any day. "Disappears" is too strong. It is *not counted*, which is the safe side |
| Bills are monthly only (D35) | D35 says *Settings* bills are monthly only. BR-9 says a rule's frequency can be weekly, every 2 weeks, monthly or **yearly** | **Half true.** The engine and schema already support yearly. Only the bill sheet offers monthly. P2 is a UI and set-aside question, not an engine change |
| Yearly costs land in one cycle | A yearly rule due in the cycle sits in `B` from day 1 (BR-3), so the hero drops at the cycle's start, not on the day | **True,** and it is a *known* drop, not a surprise on the day |
| Q6: mid-cycle install inflates the first cycle | Q6 records the problem and the owner's answer: "No extra question; the share corrects itself at the next payday" | **True, and already decided.** P1's onboarding half reopens an owner decision |
| Reminders exist only for bills (D126) | Yes. Principle 48 bans "come back" prompts; principle 62 says a reminder is a bonus and the in-app line is the guarantee | **True, and by design** |
| "Forgot to open it" is 42% | Case study 31 labels it vendor data (SpendTrak) | **Weak evidence.** Real as a pattern, unmeasured for hisaab |
| No logging reminder | The widget, Quick Settings tile and app shortcut are built (D156); *your usual* is built (D153–D155) | Partly answered already: the fixes for "forgot to open it" are one-tap entry points, not pushes |
| Missed-log question | Designed, status *Proposed*, in `docs/features/habits/` (D153 "stays proposed") | **The analysis missed it.** It is the in-app answer to forgotten days |

### 2. Verdict per gap

| Gap | Real? | Stated correctly? | Verdict |
|---|---|---|---|
| G1 The number goes wrong silently | Yes: the one gap that hits the core promise | Bullets 1 and 2 yes. Bullet 3 mixes two causes (forgot to open vs forgot to log). Open-and-log is already 4 taps, plus the widget, tile and usual | **Keep.** Reword bullet 3 |
| G2 Non-monthly costs | Plausible, frequency unknown (insurance, school fees, festivals are common in India, but unmeasured) | Partly: yearly already exists in the engine | **Keep, reshape.** It is a copy-and-template gap |
| G3 Leftover at payday | Low to medium. A careful user sees no reward, but nothing is wrong | Overstated ("disappears"). The user can log it as *Got* | **Downgrade to low.** Peak-end (case study 11) is "day-long, many-episode experiences did not follow the rule" and "overusing celebrations flattens peaks" |
| G4 Unfinished work | Housekeeping, not a user gap. CSV and the a11y pass are already M6; D51 already says *Set a limit* waits for a design | Fine | **Not a gap.** Keep as a to-do list. Check "This week" against M3's done-when separately |
| G5 Data safety | Real in a different way: Auto Backup is **off on purpose** (BR-16, FR-SE-5), so the risk is the price of the privacy line. App lock is unmeasured | Fine | **Keep as medium-low** |

### 3. Verdict per proposal

| # | Verdict | Why |
|---|---|---|
| P1 Fix my number | **Keep, reshape** | Right job, right size. Two reshapes: (a) the correction must not land in *today's share* or it says "over today"; (b) do not reopen Q6 in onboarding (see section 4) |
| P2 Yearly bills | **Reshape** | The 1/12 sinking fund needs a balance across cycles. `I`, `K` and `B` are per cycle and "computed, never stored" (D120). A fund breaks that. Use what exists: a monthly *saving* named for the cost, paid from the pot. Does not reverse D35 |
| P3 Payday close | **Drop for now** | Low pain, adds a once-a-cycle moment, and "Put in savings" is a second accounting action. Revisit with Q4's share card, if ever. The user can already log *Got* |
| P4 Evening nudge | **Drop** | Breaks principle 48 ("no come-back prompts", nagging is a dark pattern in India) and the house rule that the only nudge is spend less or save. Evidence is vendor data. It cannot fix "forgot to open it" any better than the widget and tile do. Replace it with the **missed-log question** (in-app, already designed) |
| P5 Set a limit | **Keep, later** | Small and unblocks D51, but limits are off by default and optional. After M6 |
| P6 CSV export | **Keep** | Already M6 (FR-SE-4). No design question. Not a "proposal" |
| P7 Backup safety net | **Drop** | The soft line is a nag (BR-16 "nothing ever nags", principle 48). A picked-folder auto backup is a persistent folder grant, which case study 23 rejected for v1. Leave as is |
| P8 App lock | **Defer** | A real privacy want on shared phones, but `local_auth` is a new dependency (ask first), and the widget shows today's number on the home screen, so a lock that does not cover the widget is half a lock. Needs an answer on the widget first |
| Tier 3 "Can I afford it?" | **Keep as explore** | Closest to the core question; but FR-AD-3 already previews while logging, and Ask AI covers planning. Wait for a signal |
| Tier 3 Udhaar, voice, CSV import | **Agree** | Different jobs or new dependencies |

### 4. Top three (reordered)

Order: **P1, P2 reshaped, the missed-log question.** The analysis's P4 is replaced by the missed-log question, and P2 moves ahead of it because it removes a predictable shock and needs almost no build.

| Rank | Proposal | One line |
|---|---|---|
| 1 | P1 Fix my number | The cheapest way to make a wrong number right in about five seconds |
| 2 | P2′ Set aside for a yearly cost | Yearly costs become a monthly saving, so the hero never takes the whole hit at once |
| 3 | P4′ Missed-log question (replaces P4) | An in-app question on Home, timed to the user's own habit; no notification |

#### 4.1 P1 Fix my number

**Job.** When I know my hisaab number is too high because I forgot to log, I want to say how much money I really have, so I can trust today's number again without finding the missing entries.

**Who.** Anyone who pays in cash or UPI and misses entries (most users); the mid-cycle installer on day 1.

**Evidence.** Spec-level: the number is only as good as the log (SPEC Q6; case study 31 G1). Unmeasured how often users drift.

**Journey**
1. Home shows a number that feels too high. Emotion: doubt, a little guilt. Copy must say it is fine.
2. The user taps one quiet row on Home, "Fix my number" (placement under IA below).
3. A keypad page asks "How much money do you have right now?" with one line: "Bank and cash together. We'll take out your bills and savings."
4. The page previews before saving, as FR-AD-3 does: "That's ₹4,200 less than hisaab thought. Each day gets ₹350 less." If equal: "Spot on. Nothing to fix."
5. One *Fix it* key saves one *Spent* entry in *Other*, noted "Not logged". Home reflows with the usual motion. A snackbar says what happened, with Undo.
6. Recovery: Undo removes it; the entry is visible and editable in Spends like any other.

**Design calls**
- **The correction comes out of the pool, not today's share.** Same rule as bills (BR-3, "one rule for everything a rule posts"): like `R_t`, it moves `A` and never says "over today". Without this, a ₹4,000 correction reads as shame. It needs a hidden `correction`-style category, as `saved` and `card_paid` are (D120, D123).
- **When the real figure is higher** than hisaab's: post a *Got* "Not logged" for the gap, with the same preview. Symmetry is easier to teach than a refusal. Confirm with the owner.
- **Keep it out of habits.** It must not train *your usual* (BR-17), and the morning note (BR-8) must not call yesterday "over".
- **Ask in the user's words, not ours.** "Balance" and "true-up" are finance words. Users know their bank balance; the app subtracts `B` and `K`. Assumes all spendable money is in the one number the user states. Cash held back is the user's call.

**IA.** Not on the Add path, so it adds no tap there. Home owns the answer, so the link lives on Home. The nudge slot (FR-HO-3) is one line and busy with bills, so put the row at the foot of Home's content, quiet, text only with an icon, and also under Settings > *Your hisaab* as a fallback. For a mid-cycle install, show the same line once in the empty nudge slot: "Already spent some this month? Fix my number". `design-ia` to confirm the placement.

**Open questions for the owner**
1. **Q6.** Keep "no extra question in onboarding" and use the one-time Home line instead? Recommended: yes.
2. Real figure higher than hisaab's: post a *Got*? Recommended: yes.
3. Is "Not logged" visible in Spends and the Ask AI export as it is? Recommended: yes, so the fix never hides poor logging.
4. Should one fix per day be the limit, to stop it becoming a habit of lazy logging? Recommended: no limit; the preview is the check.

**Decisions it adds or changes.** New DECISIONS row; new SPEC rule (BR-3/BR-4 correction entry, BR-8 and BR-17 exclusions, FR-HO row, FR-AD-3-style preview); amend Q6 only if the owner wants the onboarding question (not recommended). Schema: one hidden category, no table.

#### 4.2 P2′ Set aside for a yearly cost

**Job.** When a big cost comes once a year (insurance, school fees, Diwali), I want to spread it over the months before it, so I can spend each day without the bill wiping out one cycle.

**Who.** Anyone with a known yearly or term cost. Frequency unmeasured.

**Evidence.** Spec-level: a yearly rule falls into one cycle's `B` (BR-3), and an overspend above a cycle's pool shows *Over for the cycle* (BR-5).

**Why not the 1/12 fund.** It needs a balance carried across cycles and a first-year shortfall, against "computed, never stored" (D120). Reuse the monthly *saving* (D120), which already sets money aside in `K`.

**Journey**
1. Settings > Savings > add: name chips include *Insurance*, *School fees*, *Festival* beside the usual ones. The sheet says "Set aside each month for a cost that comes once a year."
2. The user enters a monthly amount (a caption can suggest "premium ÷ 12", not compute it).
3. Each month the engine posts the *Saved* entry as today; the hero already counts it before its day (D120).
4. When the cost falls due, the user pays it from the pot and logs nothing, so the hero is untouched.
5. Missed or skipped months follow the saving's existing quiet-skip rules (principle 58).

**Open questions for the owner**
1. If a Savings total counts everything ever saved, paying a premium from it leaves the total high. Is that fine, or does it need a "used" action? Recommended: ship the template first, add "used" only if a user asks.
2. Do you want a due-date reminder (D126 style) on a yearly saving? Recommended: no; skip.

**Decisions it adds or changes.** Does **not** reverse D35 (the bill sheet stays monthly). Adds one DECISIONS row: yearly costs are a saving, not a bill. SPEC: a copy note under BR-9 or the saving sheet. Light.

#### 4.3 P4′ Missed-log question (replaces the evening nudge)

**Job.** When I spent something I usually spend at this time and forgot to log it, I want a gentle question in the app, so I can add it in one tap and keep the number honest.

**Who.** Users who already have habits (BR-17 needs history). New users get nothing, which is why P1 stands first.

**Evidence.** The habit work found a well-timed in-app reminder fits (`docs/features/habits/06-research-and-guardrails.md`); D153 left it "proposed" on purpose.

**Journey**
1. The user opens Home in a habit's window and the nudge slot is free.
2. One line: "Spent on Food today? Usually around 1 pm." A tap opens the Add tray for that category at ₹0, with *your usual* ready.
3. Answering or ignoring clears it for the day. No count, no streak, no repeat.
4. Quiet state is per category (BR-17), so *Forget* silences it for good.

**IA.** Home's single note line, below a waiting bill and a due-soon nudge (FR-HO-3). No notification, so principles 48 and 62 hold.

**Open questions for the owner**
1. Does the tap land on Add step 2 with the category chosen, or on step 1? The first removes a tap (and keeps the entry path "Add → digits → Next → tile" untouched since it is a different door). Confirm with `design-interaction`.
2. Accept that it only helps people who open the app? Recommended: yes; the widget, tile and shortcut (D156) are the answer for "forgot to open".

**Decisions it adds or changes.** Lifts "stays proposed" from D153; new DECISIONS row; FR-HO-3 gains a third line type; reconciles with `docs/features/habits/04-ux-and-copy.md`.

### 5. Routing

| Order | Agent | For | Why |
|---|---|---|---|
| 1 | `design-ux-research` | P1, P2′ | Cheapest test first: a five-person read of "How much money do you have right now?" and of whether people state bank balance, cash or both |
| 2 | `design-ux` | P1 | Task flow, the higher-figure branch, the preview, Undo, the day-1 install path |
| 3 | `design-ia` | P1, P4′ | Placement on Home and in Settings; the nudge slot's priority order |
| 4 | `design-interaction` | P1, P4′ | Keypad page behaviour, preview states, where the P4′ tap lands |
| 5 | `design-content` | P1, P2′, P4′ | "Fix my number", the preview line, "Not logged", yearly-cost chips; no shame, no banned words |
| 6 | `design-ui`, `design-motion` | P1 | Hi-fi screen and the reflow when the hero corrects itself |
| 7 | `design-accessibility`, `design-platform` | all | Spoken amounts, targets, the preview read by TalkBack; adaptive layouts |
| 8 | `design-validation` | all | Blind read of the copy, then a device check |
| 9 | `design-ops` | all | Doc sync once the owner approves: BR-3/BR-4, BR-8, BR-17, FR-HO-3, DECISIONS rows |

P2′ needs only `design-content` and `design-ux` after the owner answers; it can run beside P1. P4′ already has a design set in `docs/features/habits/`; start from `design-interaction`.

### 6. What we are not doing, and why

| Not doing | Why |
|---|---|
| Evening notification (P4) | Principle 48; the house rule that the only nudge is spend less or save |
| Backup nag or folder auto-backup (P7) | BR-16 "nothing ever nags"; case study 23 |
| Payday close with carry-over (P3) | Low pain; adds a once-a-cycle moment and an accounting choice. Logging *Got* already works |
| A yearly sinking fund (P2 as written) | A cross-cycle balance, against "computed, never stored" (D120) |
| Onboarding question for Q6 | An owner decision; a one-time Home line does the job without a fourth first-minute question |
| App lock now (P8) | New dependency, and the widget shows the number |

### 7. Risks and validation

| Risk | Cheapest test |
|---|---|
| **Riskiest:** users cannot answer "how much do you have right now?" in one number (several accounts, cash) and the fix is wrong | A five-person hallway read with real balances; then a device check of the preview maths on the worked example (SPEC BR-4) |
| P1 becomes a crutch that replaces logging | Keep "Not logged" visible in Spends and Ask AI; watch logged days per week by hand |
| A big correction feels like blame | Blind read of the copy; confirm the correction never produces "over today" in a unit test on BR-3 |
| P2′ users forget to log the paid premium and the saved total reads high | Ask the owner (open question 1); revisit when a user asks |
| P4′ fires wrongly or too often | Bounded by BR-17's quiet state; a one-week self-test by the owner |
| All severities here are judgement, not data | There is no analytics (and there must be none): the north star is logged days per week, read in hallway tests |

### 8. Doc changes needed (not written; waiting for approval)

| Doc | Change |
|---|---|
| SPEC | New correction entry rule in BR-3/BR-4 and BR-8/BR-17 exclusions; new FR for Fix my number (Home and Settings entry, keypad page, preview, Undo); FR-HO-3 gains the missed-log line; Q6 left as is, noting the one-time Home line; E-rows for the higher figure and for day 1 of a cycle (a correction dated that day) |
| UI_DESIGN | The Fix my number page and its Home row; the missed-log line in the nudge slot |
| PLAN | Place the work after M6, and the yearly-cost chips in §2's defaults |
| DECISIONS | One row each: the correction entry; yearly costs as a saving (D35 untouched); the missed-log question leaves "proposed"; the evening nudge and backup nag rejected, with principle 48 |

## Owner answers (2026-11-13)

The owner accepted the review's top three (P1, P2′, P4′) and asked for the routing in §5 to run. Answers to the open questions:

| # | Question | Answer |
|---|---|---|
| P1-1 | Keep Q6 closed; one-time Home line for a mid-cycle install | **Yes** |
| P1-2 | Real figure higher than hisaab's: post a *Got* "Not logged" | **Yes** |
| P1-3 | "Not logged" visible in Spends and the Ask AI export | **Yes** |
| P2′-1 | Paying a yearly cost from a saving leaves the total high | **Add a "used" action** (not "template first") |
| P4′-1 | Where the missed-log tap lands | **Add at the keypad** (step 1), not step 2 |

| A11y-S3 | Keypad key labels at 2.0× text (`docs/features/fix-my-number/06-accessibility-review.md` S3) | **Key labels stop growing at 1.5×.** Applies to the shared keypad, so the Add tray too; needs a DECISIONS row at sign-off |

**Signed off (2026-11-13):** the owner delegated every remaining product decision to Claude as product manager. The decisions, and the call that the user test runs before the Play release rather than before the build, are in `docs/features/fix-my-number/08-design-qa-and-signoff.md` §8.

Still open before sign-off (now resolved in §8): P1-4 (a limit on fixes per day; review recommends none), P2′-2 (reminder on a yearly saving; review recommends none). Designers take the recommendations as the default.

Design work lives in `docs/features/fix-my-number/`, `docs/features/yearly-costs/` and `docs/features/habits/` (from `08-`), with mockups 41 (Fix my number), 42 (yearly costs) and 43 (missed-log line). Nothing is approved for SPEC, PLAN, UI_DESIGN or DECISIONS until the owner signs off the finished designs.
