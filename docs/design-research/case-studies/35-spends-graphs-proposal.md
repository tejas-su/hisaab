# 35. Spends graphs: saved, biggest spend, other signals (proposal)

**Status (2026-11-14): approved and built** as revised in mockup 46: SPEC BR-21, FR-SP-3a, FR-SP-4 AC-R1 to AC-R3, FR-SP-4b and FR-SP-8; D195 to D197; PLAN M10. The owner kept insight #1 and took mockup 46's defaults. The original ideation follows.

**Was:** Ideation only. Nothing here is decided or built. No SPEC, PLAN, DECISIONS or `lib/` change is made by this file.

**Question.** The owner wants the Spends graphs to say better (1) how much I saved, (2) which category or item I spend most on, and (3) other useful money signals.

**Context.** FR-SP-3 (pace chart), FR-SP-4 (*Where it went*), FR-SP-4a (*Spent · Saved · Not logged* line), FR-SP-5 and BR-14 (insights), BR-12 (limits), BR-13 (shares), BR-18 and BR-19 (*Not logged*, *Used*). Code: `lib/spends/presentation/widgets/` (`pace_chart_painter.dart`, `where_it_went_card.dart`, `category_spend_row.dart`, `spent_saved_line.dart`, `insights_card.dart`). Related: [21](21-pace-chart-portrait.md), [33](33-product-gap-analysis.md), [14](14-unfold-money.md), [15](15-unfold-takeaways-plan.md).

**Method.** Desk read of the spec and the widgets only. No users, no competitor screenshots. Effort and "schema change" are my reading of the docs, not of the data layer; the owner or `design-platform` should confirm the three flagged in "Assumptions to check".

## The job

When a cycle ends (or midway), I want to see at a glance how much I kept, what ate my money, and whether I'm doing better than last time, so I can decide to spend less or save more next cycle. Evidence it is real: Unfold's takeaways (14, 15) and the gap analysis (33, P3 "payday close") both point at the missing "how did I do" moment. The spec already asks it twice, in the Ask AI goal *How did I do?* and in BR-14's comparisons. The app answers it only through a sentence, a cumulative line and a ranked list.

## Diagnosis: what the Spends screen answers today

| Question | What exists | What it fails to answer |
|---|---|---|
| (1) How much did I save? | One grey `ink2` line, "Spent ₹27,570 · Saved ₹1,000" (FR-SP-4a). Savings are barred from every chart (D120) | It is a number with no scale. Saved against what? Of what income? Better or worse than last cycle? It also **cannot show money simply left over**, which is most of what a user means by "saved". The pace chart's end point ("about ₹9,300 spare") is the only trace of it, and it is a forecast, gone on a finished cycle |
| (2) What do I spend most on? | Bars sorted by amount, with share (FR-SP-4) | The answer is right but passive: no headline sentence, no change against last cycle in the row, and nothing below the category. "Food ₹9,840" does not say whether that is ten lunches or one wedding. The only item-level hint is BR-14 #2, "biggest {cat} spend", and it fires only if one entry is above 2x that category's median |
| (3) Other signals | Pace and gap against steady pace (FR-SP-3), up to three insights (BR-14) | Everything is **this cycle only**. No trend over cycles. No split of fixed bills against everyday spend, which is the one number that says what the user can change. No daily average |

The root cause is one scope choice: the screen shows a single cycle as a single story. Saved and left-over money lives in a one-line caption, outside the visual system.

## Ideas, ranked

Effort: S under a day of build, M a few days, L a week or more. "Schema" means a new column or table.

### 1. Income split bar: "Where your income went" (answers 1)

One horizontal bar for the cycle's income `I`, in four labelled parts. It **replaces** the FR-SP-4a line, so the screen gains no card.

```
Where your income went                 ₹45,000
[#### Bills ####][== Everyday ==][ Saved ][  Left  ]
 ₹9,400           ₹18,170         ₹1,000   ₹16,430
You kept 39% of your income.
```

- Parts: *Bills* (rule-posted, BR-9), *Everyday* (the rest of *Spent*), *Saved* (`K` posted, plus extra saves), *Left* (`I − B − S − saved`; "Still free" on the current cycle). *Not logged* stays a separate word line beneath, as AC-2 says it is not inside *Spent*.
- Encoding without colour: *Bills* solid `ink`; *Everyday* a lighter neutral step; *Saved* an **outline** with its word; *Left* the empty `sunk` track. **Not hatch**, because hatch already means "over the limit" (D110, one colour one meaning). Marigold is never used.
- The sentence is the point: "You kept 39% of your income" = (Saved + Left) / `I`. Say "kept", not "saved", because Hisaab's *Saved* is money moved to a pot and the user's own idea of saved is both. Show both words in the bar, so the two never blur.
- Touches: **conflicts with FR-SP-4a** ("Saves are never in the bars, percentages…", D120). The split is a separate card from the *Where it went* bars and shares are untouched, so the conflict is wording, but it needs a DECISIONS row. Also touches BR-3 (`I`, `K`, `B`) read-only, BR-13 (unchanged), BR-19 (*Used* stays out; AC-4).
- Effort M. Schema: none (all computed, D120). Hide when the cycle has no income (as FR-SP-3 does for the steady line).

### 2. Category row opens to its top entries (answers 2)

Tap a row in *Where it went* and it opens in place to its three biggest entries, then *See Food entries* (the existing FR-SP-6 filter).

```
Food   36%                ₹9,840
[##########............]
  Biggest
  Wedding gift dinner  14 Oct   ₹2,100
  Swiggy               3 Oct    ₹640
  Swiggy               9 Oct    ₹610
  See Food entries
```

- Row label is the entry's note, else its date. Notes are optional, so a user who never types one sees dates and amounts only; that is still better than nothing.
- "Merchants" are not derivable: notes are free text. Don't pretend to. A light version: when the **same note repeats 3 or more times** in the cycle (case-insensitive), the first line reads "Swiggy x 9, ₹2,700". That is a *repeat* signal, not a merchant model. Ship it only if the first version tests well.
- Nothing moves unless the user moves it (§2): the tap is the move. One row open at a time, closes on a second tap. Row needs a 48dp target and TalkBack `expanded` state.
- Touches FR-SP-4, FR-SP-6; adds a sentence to BR-14's neighbourhood. Does not touch BR-13. Effort M. Schema: none (the entry list is already per cycle and category).

### 3. A headline above the bars, and change against last cycle (answers 2, 3)

```
Food is where most went: ₹9,840, 36%.
Food   36%   ₹9,840   up ₹1,200 from September
```

- One sentence above the rows, always the top category. It is the answer to "what do I spend most on", in words, as case study 15 asks (HIG: summarise the main message).
- Each row gets a second small `ink2` clause "up ₹1,200 from September" or "down ₹300" when the change is at least ₹500 and 10%, at the **same day-of-cycle** (the BR-14 #1 maths, so it never disagrees with the insight). Words only: no arrow colour, no red or green, no shame ("up", not "overspent").
- Touches BR-14 #1 (reuses its comparison; the insight then repeats the biggest row, so make #1 skip a category that already shows its delta, or drop #1). Effort S to M. Schema: none.

### 4. Last 6 cycles strip (answers 1, 3)

One small card, a bar per cycle, above or below the pace card.

```
Last 6 cycles
 |   ##  ##  ##  ##  ##  ##        - - -  usual (I − K)
 Jun Jul Aug Sep Oct Nov
 Each bar: spent. Tap a bar to open that cycle.
 Saved sits above a bar as an outlined cap.
```

- Bars start at zero (HIG), a dotted line for the cycle's own `I − K` (the same line the pace chart calls steady). A bar under the line reads "under", with the word on the verdict line: "4 of 6 cycles ended under your steady line." Current cycle is drawn outlined, not filled, because it is not finished. Tapping a bar equals the cycle switcher (FR-SP-1), so no new navigation.
- Answers "am I getting better or worse" and "how much did I save, cycle by cycle" together via the outlined cap.
- Touches FR-SP-1 (an added path to the same state). Needs per-cycle `I`, `K`, `S`: computed from the ledger, not stored (D120), but it is six computations on open. Effort L (new painter, six-cycle read, narrow-width and text-scale layout). Schema: none. Hide until there are 2 finished cycles.
- Risk: it is another card on a long screen. Offset: delete the standalone Insights card slot if a strip proves richer (hallway test below).

### 5. Bills against everyday (answers 3)

A sentence, or the first two parts of idea 1's bar: "₹9,400 is bills. ₹18,170 is everyday." This is the controllable-spend number; users cannot cut rent. It also fixes a quiet distortion: *Bills* appears as one large bar in *Where it went* and tells the user nothing they can act on.

- Needs the "was posted by a rule" flag per entry. If the ledger has it (BR-9 posts entries, so a rule id is likely on the row), no schema change. **Verify.**
- Folded into idea 1 so it costs no space. Standalone effort S.

### 6. Daily average with last cycle's (answers 3)

One `ink2` line under the pace card's verdict: "₹918 a day so far. ₹1,100 a day in September." Plain, one number, no judgement. Uses the same `pace` BR-7 computes, so it can't disagree with Home. Effort S. Schema: none. Weak on its own, but nearly free. Skip if idea 4 ships.

### 7. A finished-cycle summary line (answers 1)

On a past cycle only, above everything: "October ended with ₹3,400 left and ₹1,000 saved." This is the P3 payday-close idea (33) without a modal, a carry-over action or a once-a-cycle nudge, which 33 dropped for good reasons. It is passive, in the place the user already looks, and only on cycles that are over. Overlaps idea 1's sentence; choose one. Effort S. Schema: none.

### 8. Weekday pattern insight (answers 3)

A BR-14 style sentence, "Most of your spending happens on weekends", when weekend days carry at least 2x the weekday average over the last 3 cycles. A sentence, not a chart: a weekday bar chart already exists on Home (*This week*, case study 15 R6), so a second one on Spends would be repetition. BR-14 allows three insights, so this competes with the other four rules. Effort S. Schema: none. Medium value, low risk; add only if an insight slot is free.

## What I would reject, and why

| Idea | Verdict | Reason |
|---|---|---|
| Donut or pie by category | **No** | PLAN §4 chose bars. A bar sorts and labels; a donut needs colours to tell slices apart, and category colours are banned |
| Category colours on the income split or strip | **No** | Banned. Fill, outline and words carry it. Note the one trap: don't reuse hatch for *Saved*; hatch means over-limit |
| Green "saved" and red "overspent" deltas | **No** | Banned, and shaming (inform, don't shame) |
| Savings goal ring or "saved 40% of your goal" | **No** | Needs a goal, a new setting and a target the user never set. The app has no goals (zero-config) |
| Saving streaks, "best month", badges | **No** | Engagement mechanics. The only nudge allowed is "spend less / save". A streak shames the broken month |
| Merchant auto-detection and per-merchant charts | **No** | Notes are free text and optional; a guess would be wrong often and would need a data model. The repeat-note line in idea 2 is the honest ceiling |
| Spending-by-weekday chart on Spends | **No** | Home already has *This week*; do the sentence in idea 8 instead |
| Net-worth or yearly savings projection | **No** | Outside "how much can I safely spend today"; invites false precision from one cycle's data |
| Peer comparison ("you spend more than 70% of users") | **No** | Needs network and analytics. Never |

## Top 3

1. **Income split bar (idea 1, with idea 5 folded in).** It is the only idea that answers "how much did I save" with a scale, and it does so by **replacing** a line rather than adding a card. It also surfaces left-over money, which the app currently hides. Riskiest part: whether the word "kept" reads as obvious to a 5-year-old. Needs the FR-SP-4a wording amended.
2. **Category row opens to its top entries, with a headline and change against last cycle (ideas 2 and 3).** It turns the answer to "what do I spend most on" from a list into a reason, uses data already on the device and follows the one-tap rule that leaves the Add flow alone. Do the headline and delta first (S to M); the open-in-place drill is the second step.
3. **Last 6 cycles strip (idea 4).** The only way to answer "am I improving". It is the biggest build (L), so third. Gate it on 2 finished cycles so a new user never sees an empty chart.

Idea 7 is the cheap stand-in for idea 1 if the owner wants only a sentence this week.

## What we are not doing

No new setting for any of this; every default is chosen above. No change to Add, the keypad, categories or the dock. No change to the pace chart (21 covers it). No new dependency: all of it is paint and arithmetic on data the app already holds. Never ads, paid tiers or sharing features (hobby app, per the owner's memory), and no analytics to learn which graph gets used.

## Assumptions to check

1. Rule-posted entries carry a rule or source id, so *Bills* can be split from *Everyday* without a schema change (ideas 1, 5). `design-platform` or the owner should confirm in the ledger schema.
2. `I`, `K` and `B` can be computed for a past cycle, not just the current one (idea 4). BR-3 says computed, never stored (D120), so this should hold, but six cycles on open needs a timing check.
3. Notes are filled often enough to be worth showing (idea 2). The owner can look at their own entries; no analytics may measure it.

## Risks and validation

- **Riskiest assumption:** that people read a stacked bar of four parts without help. **Cheapest test:** a blind read of an HTML mockup with three people ("What does the empty part mean? How much did you keep?"), then a 5-person hallway test of idea 1 against the current line. The north star remains logged days per week, so the pass mark is comprehension, not time spent.
- **Anxiety:** a bar that shows *Left* can read as "you failed" when it is small. Copy must say "left", never "only", and the current cycle must say "still free".
- **Screen length:** the Spends scroll is already five cards. Every idea above either replaces something (1 replaces the line, 3 enhances rows, 7 is a line) or is gated (4).
- **TalkBack:** each new graphic needs one sentence read in a single node, as FR-SP-4a AC-5 does. Row expansion needs an `expanded` state.
- **Doc consistency:** idea 3 and BR-14 #1 would say the same thing twice.

## Doc changes needed (not written)

- **SPEC:** FR-SP-4a reworded for the split bar (and its "never in the bars" sentence scoped to *Where it went*); FR-SP-4 gains the headline and the delta clause; FR-SP-4 or a new FR-SP-4b for the row drill-down; a new FR for the strip (idea 4); BR-14 #1 adjusted to avoid repeating the delta.
- **UI_DESIGN:** Spends section: the split bar's fill grammar (solid, lighter neutral, outline, empty), reaffirming hatch means over-limit only.
- **DECISIONS:** one row for "the income split is a Spends card, and it shows left-over money as part of what the user kept", and one for the repeat-note limit (no merchant model).
- **Mockups:** new `docs/design/mockups/NN-spends-income-split.html` before any build.

## Next agents

| Agent | What it takes |
|---|---|
| `design-ux-research` | The comprehension test for "kept" and the four-part bar; check how many of the owner's entries have notes |
| `design-ui` | Mockup for ideas 1, 2 and 4: fill grammar, spacing, narrow and large-text layouts |
| `design-content` | Copy: "kept", "left", "still free", "up ₹1,200 from September", the finished-cycle line, the repeat-note line; all banned-word checked |
| `design-accessibility` | One-sentence TalkBack readings, row `expanded` state, outline against `sunk` contrast, 1.5x text |
| `design-interaction` | Open-in-place row (one open at a time) and tapping a strip bar |
| `design-motion` | How a row opens and how bars rise; reduced-motion fallback |
| `design-ia` | Where the split and strip sit in the Spends order, and what leaves to keep the scroll short |
| `design-system` | Whether the lighter neutral and the outline fill need new tokens (`better-colors` skill) |
| `design-platform` | Confirm assumptions 1 and 2 against the schema and cycle maths; narrow phones and foldables |
| `design-validation` | Blind-read and hallway test plan; design QA once built |
| `design-ops` | SPEC, UI_DESIGN and DECISIONS sync if the owner accepts any idea |
