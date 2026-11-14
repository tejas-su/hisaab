# Mockup 46. Spends graphs: copy deck

**Status.** Proposal. Companion to [mockup 44](44-spends-graphs.html), case studies [35](../../design-research/case-studies/35-spends-graphs-proposal.md) and [36](../../design-research/case-studies/36-spending-insights-research.md), and principles 91 to 95. Nothing here is in `lib/`, the ARB file, SPEC, UI_DESIGN or DECISIONS. Keys are proposed; run the grep for clashes before adding them.

**Scope.** Ideas 1 to 4 of mockup 44: (1) comparison sentence, (2) income split bar, (3) *Where it went* headline, row change and top entries, (4) last-6-months strip. Month story ([45](45-month-story.html), case study 37) is the sister feature; terms are shared on purpose.

**How lengths are measured.** Smallest `TestWindows` size is 320dp wide. Spends cards have 16dp page and 18dp card padding, so card text is about 252dp wide. Rough capacity: 35 characters a line at 15sp, 39 at 14sp, 42 at 13sp, 18 at the 28sp hero amount. Lines are an estimate until a widget test measures them. Hindi is planned at +30 to 40%.

## 1. Decisions

### D-A. Mid-cycle word for the empty part of the bar: "Not spent yet" (not "Still free")

| Option | Reads as | Verdict |
|---|---|---|
| **Not spent yet** | A fact about the past. Makes no promise about the future. | **Pick.** |
| Still free | "Free to spend". Home's hero says "Safe to spend today ₹1,430". A bar saying "₹16,430 still free" beside it reads as ₹16,430 you may spend. It also ignores bills still to come, which Home's share already holds back (BR-4). | Reject. It contradicts Home. |
| Left / still left | Collides with the widget's "left today" and the fix sheet's "money … is left" (current cash). Same word, different number. | Reject mid-cycle. |
| Spare | Home's range line already owns it, and as a rounded forecast ("about ₹9,300 spare"). The bar number is exact and not a forecast. | Reject. Never use "spare" for a measured number. |

Why it can't contradict Home: Home says what is *safe* today and what is *spare* at payday (both forecasts, rounded). The bar says what is *not spent yet* (a fact, exact). Three different words for three different numbers. The deck adds one caveat the owner should know: the bar's number is `I − bills posted − everyday − saved`, so it does not hold back bills still to come. "Not spent yet" is true; "free" would not be.

### D-B. Finished cycles: keep "Left over" (no change to the month story)

"Not spent" would be more exact, but a finished cycle has nothing "yet" and no "safe to spend" next to it, so the collision that rules out "left" mid-cycle is gone. "Left over" is two short words, warm, in the month story already, and Hindi readers know it ("bacha hua"). **No change to month story or case study 37.** The two features then use: "Not spent yet" while the cycle runs, "Left over" once it ends, and the same word pair on the strip.

### D-C. "Everyday": keep, and define it in one line under the key

"Everyday" is honest about how hisaab works: it is the spending that eats the daily share, and a ₹2,200 pair of shoes does eat it. The risk is that it sounds like "small stuff". "Other spending" is exact but sits badly beside "Spent" and is longer in Hindi. So the label stays, and the key carries one line: "Everyday is all spending except bills." (key `spendsSplitEverydayNote`). This costs one 13sp line. It also carries *Not logged* (see edge states) so there is still one note under the key, not two.

### D-D. Comparison against a cycle named by dates: "the week before"

| Option | Example | Verdict |
|---|---|---|
| Name it by dates | "₹800 less than by this day in 12 Oct – 18 Oct." | Matches D78 and the insight, but "by this day in" plus a date range is hard to say aloud. |
| "Last week" | "₹800 less than by this day last week." | Wrong when someone has stepped back three weeks. |
| **The week before** | "₹800 less than by this day the week before." | **Pick.** Always true, because the comparison is always against the cycle just before the one shown. It sits under a switcher that already shows the dates. |

Monthly (and month-end) cycles use the switcher's own name ("September", "Dec 2025" when the year differs), exactly as D78 does. Bridge cycles (BR-1a, up to about 62 days) are named by the switcher too, so they take the monthly form. Row deltas use the short name ("Sep"). This differs from `insightCategoryUp`, which names a weekly cycle by dates; the insight is a sentence on its own, the comparison sits next to the switcher. Flagged in section 6.

### D-E. "Income" and "earned" do not appear on screen

The user-facing term is **Money coming in** (Settings; onboarding hint "Pay, business, pension or family money"). "Earned" is wrong for a pension or family money, and "income" is a developer word here. So the deck says "money in" and "came in". This **changes two approved strings**: the month story's "₹3,100 more than you earned" becomes "₹3,100 more than came in", and the key "Past your income" becomes "More than came in". Both features must change together. It also reads without "you", so it blames no one.

### D-F. Counts, not labels (principles 91 to 95)

The strip summary counts months and never grades them. It also leaves out "Spent less than you earned", which would disagree with the bar: a month can have spent less than came in and still be over once saves are counted (the readout and month story count saves). The summary uses the same test as the bar: "left over".

### D-G. The comparison sentence (options, pick)

| Option | Text |
|---|---|
| A | **₹2,100 less than by this day in September.** |
| B | You spent ₹2,100 less than September so far. |
| C | Down ₹2,100 from September, same day. |

A: neutral, no "you" (no blame), front-loads the number, says what "same point" means, and matches principle 93. B adds "you spent" and drops the same-day idea, so it can mislead on day 5. C uses "Down", which can read as good or bad.

## 2. Copy table

Placeholders: `{amount}` is `MoneyFormatter` text (`₹1,25,000`, never paise). `{cycle}` is the switcher's name ("September", "12 Oct – 18 Oct"). `{cycleShort}` is the short form ("Sep"). `{kind}` is `week` or `other` (monthly, month-end, bridge). `{state}` is `now` (cycle still running) or `done`. `{dir}` is `less`, `more` or `same`. Length is characters, then lines at 320dp.

### Idea 1. Comparison sentence

| Key | Text | Description for translators | Length at 320dp | Notes |
|---|---|---|---|---|
| `spendsCompareNow` | less: "₹2,100 less than by this day in September." more: "₹2,100 more than by this day in September." same: "Same as by this day in September." Weekly: "…than by this day the week before." / "Same as by this day the week before." | Spends, top card of the current cycle: spending so far against the same day of the cycle before (BR-14 #1 maths). Neutral; no good or bad word. | 42 to 49 chars, 2 lines | Key is the sentence; the arrow icon has its own label. |
| `spendsCompareDone` | less: "₹4,300 less than in September." more: "₹4,300 more than in September." same: "Same as in September." Weekly: "…than the week before." | Same card on a finished cycle: whole cycle against the whole cycle before. | 30 to 36 chars, 1 to 2 lines | No "by this day": a finished cycle has no today. |
| `spendsCompareArrowLabel` | less: "Less" more: "More" same: "Same" | Label for the arrow beside the comparison sentence (icon label for TalkBack, never read twice). | 4 chars | The arrow is `excludeSemantics`; the sentence carries it. Reuse via `dir` select. |

Edge states:
- **First cycle, or last cycle not fully tracked:** the card is not drawn. No placeholder, no apology, so nothing to translate.
- **Both amounts are ₹0:** not drawn.
- **Under ₹100 apart:** use the `same` form. Recommend the rule go to SPEC; ₹37 "more" is noise.
- **No money coming in:** still shown; it compares spending only.

TalkBack: reuse the same key with a spoken amount: "2,100 rupees less than by this day in September." / "Same as by this day in September."

### Idea 2. Income split bar

| Key | Text | Description for translators | Length at 320dp | Notes |
|---|---|---|---|---|
| `spendsSplitTitle` | now/month: "Your ₹45,000 this month"; now/week: "Your ₹10,000 this week"; done/month: "Your ₹45,000 in September"; done/week: "Your ₹10,000 for 12 Oct – 18 Oct" | Card title: the money that came in for the cycle shown. | 22 to 32 chars, 1 line | "for", not "in", before a date range. |
| `spendsSplitHeadFree` | now: "₹16,430 not spent yet"; done: "₹16,430 left over" | Big line when something is not spent: now = cycle running, done = cycle over. | 17 to 21 chars; 2 lines at 28sp when over 18 | Allow two lines; amount stays tabular. |
| `spendsSplitHeadNone` | now: "All of it is spent or saved."; done: "Nothing left over." | Big line when exactly ₹0 is not spent. | 18 to 28 chars, 1 to 2 lines | Rare; a fact, not a warning. |
| `spendsSplitHeadOver` | "₹3,100 more than came in" | Big line when spending and saving passed the money in. | 24 chars, 2 lines | Month story's headline, reworded (D-E). |
| `spendsSplitSubSaved` | free: "And ₹1,000 saved."; over: "That includes ₹1,000 saved." | Small line under the big line, only when saved is above ₹0. | 17 to 27 chars, 1 line | Hidden at ₹0: no "saved ₹0" to feel bad about. |
| `spendsSplitEveryday` | "Everyday" | Bar part and key label: all spending except bills. | 8 chars | Define in the note below. |
| `spendsSplitFreeNow` | "Not spent yet" | Key label for the empty part while the cycle runs. Not "free" or "left": see the doc. | 13 chars | Hindi room: wraps at 2x text, fine. |
| `spendsSplitFreeDone` | "Left over" | Key label for the empty part once the cycle is over. | 9 chars | Same as month story. |
| `spendsSplitOver` | "More than came in" | Key label for the striped part past the money in. | 17 chars | Replaces "Past your income". |
| `spendsSplitEverydayNote` | none: "Everyday is all spending except bills."; with Not logged: "Everyday is all spending except bills, including ₹4,200 not logged." | One line under the key. The select is whether Not logged is above ₹0. | 38 chars, 1 line; 66 chars, 2 lines | Reuses the *Not logged* term (BR-18). |
| `spendsSplitEmptyNote` | "Add a spend and it fills in here." | Under the big line when nothing is spent, saved or posted yet in the cycle. | 33 chars, 1 line | The dock's Add is always on screen, so no extra button. |
| `spendsSplitSpentOnly` | "₹27,570 spent" | Big line when there is no money coming in: the spend alone, no bar. | 13 chars | As the month story does. |
| `spendsSplitNoIncomeTitle` | now/month: "Spending this month"; now/week: "Spending this week"; done/month: "Spending in September"; done/week: "Spending for 12 Oct – 18 Oct" | Card title when no money coming in is set. | 19 to 28 chars, 1 line | |
| `spendsSplitNoIncomeBody` | "Add the money coming in to see how it splits." | Under the spend, when no money coming in is set. | 45 chars, 2 lines | Says what will appear. |
| `spendsSplitNoIncomeAction` | "Add money coming in" | Key that opens the income slip (FR-SE-1). | 19 chars | One verb, one action. |

Reused: `fixedBills` ("Bills"), `entrySaved` ("Saved"), `spent`.

Edge states:
- **Over income:** big line "₹3,100 more than came in", sub "That includes ₹1,000 saved.", key shows the striped row "More than came in ₹3,100" and no empty-part row.
- **Zero change or exactly used:** `spendsSplitHeadNone`.
- **Bills or Saved at ₹0:** the row is left out of the key and the spoken text. Everyday and the empty-part row always show.
- **First cycle, mid-way:** shows as normal. The bar measures only what is logged.
- **Weekly:** same strings, "this week" and the dates title. Money in is the week's pay, so the headline never says "month".

TalkBack (one node, `role: image`), built from the title key and the visible labels with spoken amounts, one sentence a part, zeros left out:
- Now: "Your 45,000 rupees this month. Bills 8,200 rupees. Everyday 19,370 rupees. Saved 1,000 rupees. Not spent yet 16,430 rupees."
- Done: "Your 45,000 rupees in September. Bills 9,400 rupees. Everyday 30,200 rupees. Saved 1,000 rupees. Left over 4,400 rupees."
- Over: "Your 45,000 rupees in August. Bills 9,400 rupees. Everyday 37,700 rupees. Saved 1,000 rupees. More than came in 3,100 rupees."
- Weekly done: "Your 10,000 rupees for 12 Oct to 18 Oct. …" (en dash read as "to").

### Idea 3. Where it went

| Key | Text | Description for translators | Length at 320dp | Notes |
|---|---|---|---|---|
| `spendsWhereHeadline` | "The most went on Food, ₹9,840 of ₹27,570." | Sentence above the rows: the biggest category. | 42 chars, 2 lines | "Most went" would be false at 36%, so "The most". |
| `spendsWhereHeadlineAll` | "All of it went on Food, ₹9,840." | Same, when one category holds everything. | 31 chars, 1 line | |
| `spendsRowChange` | less: "₹1,200 less than Sep"; more: "₹1,200 more than Sep"; same: "Same as Sep". Weekly: "₹1,200 more than the week before" / "Same as the week before" | Small line under a category row: change against the cycle before, at the same day. | 11 to 32 chars | At 320dp the row's text column is about 100dp, which fits 16 characters. Ask `design-ui` to span the line across the amount column (about 166dp, 26 chars) and allow a second line. |
| `spendsTopCaption` | one: "Only entry"; two: "Both entries"; many: "Biggest 3 of 21" | Over the opened row's list. | 10 to 15 chars | ICU plural on count. |
| `spendsTopNoNote` | "No note" | Entry label when it has no note. Shown in `ink2` italic. | 7 chars | Italic is a style, not a colour. |
| `spendsTopSeeAll` | "See Food entries" | Link that opens the category's entries (FR-SP-6). | 16 chars | Custom category names may be long; one line, ellipsis. |
| `spendsRowOpenHint` | "Show biggest entries" | TalkBack tap hint while the row is closed. | 20 chars | Not drawn. |
| `spendsRowCloseHint` | "Hide biggest entries" | TalkBack tap hint while open. | 20 chars | Not drawn. |
| `spendsTopEntrySpoken` | "{label}, {date}, {amount}" | TalkBack for one top entry; label is the note or "No note". | n/a | "Dinner out, 20 October, 2,400 rupees." |

Reused: `whereItWent`, `seeAll`.

Edge states: a row with one entry shows `Only entry` and the entry. A category with nothing in the cycle before still gets the sentence ("₹3,600 more than Sep"), which is true. First cycle: the change line is left out, the headline stays. No spends: the existing empty state, no headline.

TalkBack row: the existing category row sentence, then the change: "Food, 9,840 rupees, 36 percent. 1,200 rupees more than September." The row is a button with `expanded` state and the hint above.

### Idea 4. Last 6 months strip

| Key | Text | Description for translators | Length at 320dp | Notes |
|---|---|---|---|---|
| `spendsStripTitle` | month: "Last 6 months"; week: "Last 6 weeks" | Card title; count is how many bars are drawn (3 to 6). | 12 to 13 chars | Plural on count; shown only after 2 finished cycles. |
| `spendsStripSummary` | some: "Money was left over in 4 of the last 5 months."; none: "Nothing was left over in the last 5 months."; all: "Money was left over in all 5 months."; two: "Money was left over in both months." Weeks: same with "weeks". | Counts finished cycles only. Left over means spent plus saved did not pass the money in. | 36 to 46 chars, 1 to 2 lines | Replaces "Spent less than you earned in 4 of the last 5 months" (D-E, D-F). A count, no grade. |
| `spendsStripKey` | "Dark is spent. Outline is saved." | Line under the chart; the dotted line has its own label. | 32 chars, 1 line | Dashed outline = cycle still running; the readout says it. |
| `spendsStripLine` | "Money in {amount}" | Label on the dotted line, full `MoneyFormatter` text. | 16 chars at 11sp | Not "Income ₹45K": "K" is not Indian and "income" is not our word. |
| `spendsStripReadDone` | left: "September: spent ₹39,600, saved ₹1,000. ₹4,400 left over."; over: "August: spent ₹47,100, saved ₹1,000. ₹3,100 more than came in."; even: "…Nothing left over."; no saves: "September: spent ₹39,600. ₹4,400 left over." Weekly: "12 Oct – 18 Oct: …" | Readout under the strip for the bar picked, finished cycle. | 43 to 70 chars, 2 to 3 lines | Reserve 3 lines of height. |
| `spendsStripReadNow` | "October so far: spent ₹27,570, saved ₹1,000. 8 days to go." (1 day: "1 day to go.") | Readout for the running cycle. | 58 chars, 2 lines | Plural on days. |
| `spendsStripReadNone` | "August: nothing spent or saved." | Readout when a cycle has no entries. | 31 chars | |
| `spendsStripPartial` | month: "You started on 14 Sep, so this one is part of the month."; week: "…part of the week." | Extra line when the first cycle began mid-way. | 56 chars, 2 lines | Cycle isn't called a "cycle" in the UI. |
| `spendsStripGroupSpoken` | "{title}. Dotted line is money in, {amount}. Dark is spent. Outline is saved." | TalkBack label on the whole chart. | n/a | |

Bar labels under the chart use the formatter: "May" (short month), or the start date "12 Oct" for weekly. Each bar's TalkBack label is its readout sentence, so no extra key: "September: spent 39,600 rupees, saved 1,000 rupees. 4,400 rupees left over."

Edge states: under 2 finished cycles, hidden (no copy). A cycle with no money coming in is drawn without a left-over statement: "September: spent ₹39,600, saved ₹1,000." and is left out of the summary count. The picked bar on a finished cycle view defaults to the shown cycle; on the current cycle, to the last finished one.

## 3. Proposed ARB entries

Sketch of the shape (full text as in the tables; nested `select` first, `plural` inside where a count shows). Every entry carries a `@key` description from the table.

```json
"spendsCompareNow": "{dir, select, less{{kind, select, week{{amount} less than by this day the week before.} other{{amount} less than by this day in {cycle}.}}} more{{kind, select, week{{amount} more than by this day the week before.} other{{amount} more than by this day in {cycle}.}}} other{{kind, select, week{Same as by this day the week before.} other{Same as by this day in {cycle}.}}}}",
"@spendsCompareNow": {"description": "Spends top card, running cycle: spending so far against the same day of the cycle before. dir is less, more or same. kind is week for a weekly cycle. Neutral wording, no good or bad word (BR-14 #1).", "placeholders": {"dir": {"type": "String"}, "kind": {"type": "String"}, "amount": {"type": "String"}, "cycle": {"type": "String"}}},
"spendsSplitHeadFree": "{state, select, now{{amount} not spent yet} other{{amount} left over}}",
"@spendsSplitHeadFree": {"description": "Big line of the income split card when some money is not spent. state is now while the cycle runs, done once it is over.", "placeholders": {"state": {"type": "String"}, "amount": {"type": "String"}}},
"spendsStripSummary": "{kind, select, week{{kept, plural, =0{Nothing was left over in the last {total} weeks.} other{Money was left over in {kept} of the last {total} weeks.}}} other{{kept, plural, =0{Nothing was left over in the last {total} months.} other{Money was left over in {kept} of the last {total} months.}}}}",
"@spendsStripSummary": {"description": "Under the Last 6 months title: how many finished cycles had money left over. A count, never a grade. All and both cases use spendsStripSummaryAll.", "placeholders": {"kind": {"type": "String"}, "kept": {"type": "int"}, "total": {"type": "int"}}}
```

The code picks `spendsStripSummaryAll` when `kept == total`; that is a branch, not string concatenation. Spoken versions reuse the same keys with a spoken-amount argument, which is why most keys here have no `…Spoken` twin. Where a spoken sentence differs (the split bar, the row), it is built from the same visible keys.

## 4. Terms table

| Term | Use | Never | Notes |
|---|---|---|---|
| Money coming in / money in / came in | The user's word for income | Income, earned, salary, earnings | Pension and family money are not "earned". |
| Bills | Entries a rule posted (BR-9) | Fixed costs, EMIs | Same as `fixedBills`. |
| Everyday | All spending except bills, including Not logged | Daily, regular, small stuff | Define it once under the key. |
| Saved | Money put into savings | Kept, set aside | "Kept" is Saved plus left over and appears nowhere on screen. |
| Not spent yet | Empty part of the bar while the cycle runs | Free, still free, left, spare | "Spare" belongs to Home's forecast. |
| Left over | Empty part of the bar once the cycle is over; strip counts | Left (alone), unused, surplus | Same as month story. |
| More than came in | Spending plus saving past the money in | Overspent, deficit, past your income | Fact, no blame. |
| Not logged | The Fix my number part (BR-18) | Unknown, missing | Existing term. |
| the week before | Comparison against a weekly cycle | last week, previous cycle | Monthly cycles use the switcher's name. |
| Note | The optional text on an entry | Description, memo | "No note" when empty. |
| Entries | List of one category's entries | Transactions | Banned word avoided. |

## 5. Checks

- **Banned words:** no "transaction", "debit", "credit", "budget period" or "Oops". No exclamation marks. No "you overspent" or similar blame; the only "you" is in "Your ₹45,000", a possessive.
- **Glossary:** "Bills", "Saved", "Not logged", "Money coming in", "entries" follow SPEC. New terms for the glossary: Everyday, Not spent yet, Left over, More than came in.
- **Voice:** every comparison says a fact and gives its scale; none says good or bad. Over-income states pair the fact with the saves included, and Home's over card already holds the next step. Principles 91 to 95: counts not labels, no named score, same-day comparison, one neutral sentence.
- **Money:** all amounts via `MoneyFormatter`, whole rupees. The strip's dotted-line label uses the full form, not "K".
- **Reading level:** sentences are under 12 words, short Anglo words. Hindi readers know "left over", "bills" and "saved". No jargon like "split" in a user's face except in the no-money-in body ("how it splits"); fine, but the first test should check it.
- **Plurals:** counts use ICU plural (caption, days to go, strip). Gender-neutral.
- **Accessibility:** each graphic reads as one sentence, amounts in "rupees" words; icons (arrow, caret, bars) carry labels or are merged into the sentence.

## 6. Conflicts and doc edits (not made)

Conflicts with existing wording:
1. **Month story "₹3,100 more than you earned"** (mockup 45, case study 37, page 2): change to "₹3,100 more than came in" (D-E). The same applies to its key "Past your income".
2. **Mockup 44's "Still free"**: change to "Not spent yet" (D-A). "Left over" stays.
3. **Mockup 44's strip summary** "Spent less than you earned in 4 of the last 5 months": change to "Money was left over in 4 of the last 5 months." (D-E, D-F).
4. **Mockup 44's "Income ₹45K" chart label**: change to "Money in ₹45,000".
5. **`insightCategoryUp`** names a weekly cycle by dates; the comparison here says "the week before". Acceptable, but the SPEC should say which is which (BR-14 #1 against FR-SP new).
6. **FR-SP-4a** ("Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200") and the keys `spendsPartSpent`, `spendsPartSaved`, `spendsPartNotLogged`, `spendsPartNotLoggedSpoken` are replaced by the split bar. Keep them until the bar is built.
7. **Headline "Most went on Food"** in mockup 44 is false when the top category is under 50%; use "The most went on Food".

Doc edits for the owner or `design-ops`:
- **UI_DESIGN §8:** add "not spent yet" (running) and "left over" (finished); "more than came in" for passing the money in; never "free", "earned" or "income" on screen; comparison sentences name the week as "the week before".
- **SPEC glossary:** add Everyday, Not spent yet, Left over, More than came in.
- **SPEC:** a rule for the `same` form (under ₹100); "Saved" and "Bills" rows hidden at ₹0; the headline's one-category and top-category-under-half forms.
- **Mockups 44 and 45:** copy fixes in the list above, done by `design-ui`.
- **DECISIONS:** one row for D-A and D-E.

## 7. Open questions

1. Should the headline skip *Bills* when it is the biggest category? "The most went on Bills" is true but changes nothing. Left as is; test with real data.
2. Does the bar's *Not spent yet* need a bills-to-come note? It would mean showing a second number next to Home's. Left out to keep the screen calm.
3. Does the first test read "how it splits" and "Everyday" without help? Add both to the blind read in mockup 44's table.
