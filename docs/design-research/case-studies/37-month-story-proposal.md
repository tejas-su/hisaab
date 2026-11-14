# 37 · Month story: a six-page look back at a finished cycle

> **Outcome (2026-11-14): approved and built** (SPEC BR-20, FR-SP-7; D193, D194; PLAN M9). The owner moved the card from above Ask AI to **directly below it**. As built, the wording is "more than came in" (copy deck 46) and the bar order is Bills, Saved, Everyday (mockup 46). The original proposal follows.
>
> **Was: proposed, not approved.** The owner asked for "a monthly breakout or a featured card at the end of the month… something more", and picked a **swipeable story**, **on Spends only**, with **no sharing for now**. Mockup: [45-month-story.html](../../design/mockups/45-month-story.html). It builds on case studies 35 (split bar, comparisons) and 36 (recap risks, principles 91–95). It reopens case study 33's P3 "drop for now" verdict in part, so it needs a DECISIONS row before any SPEC change.

## 1. Why it differs from the dropped P3

Case study 33 dropped *Payday close and carry-over* for three reasons: low pain, a once-a-cycle moment on Home, and *Put in savings* as a second accounting action. This proposal keeps the look back and drops the rest:

- **No Home moment and no notification.** It is reached from Spends only.
- **No accounting action.** The story only reads. Nothing is moved, posted or carried over.
- **The story itself is the value the owner asked for**, not a fix for a pain point. It is the remembered end of a month (principle 49).

## 2. The pages

Each page shows one fact in big type, with the detail below. The user taps to move on, and nothing advances by itself.

| # | Page | Shows | Source of the numbers | Skipped when |
|---|---|---|---|---|
| 1 | The month | The cycle name (as FR-SP-1 names it), its dates, the day count and the entry count, plus a small day-bars preview | Cycle, entry count | Never |
| 2 | What you kept | Spent, against income, with the split bar (Bills, Everyday, Saved, Left over or Past your income) | Split bar, case study 35 idea 2 | No income: shows the spend alone, with no bar |
| 3 | Where it went | Every category, biggest first, with ₹ and BR-13 % | `Where it went` (FR-SP-4) | Never |
| 4 | Your days | **Day bars** (see below): one bar per day of everyday spending, with a dotted line at the daily share. The biggest day is labelled with its amount and named with its note. It also gives the number of days with nothing spent and the biggest weekday total | Entries by day; the share is `(I − K − bills) / days` | Fewer than 14 days with entries |
| 5 | Against last month | The total change, then the 3 biggest category moves in words with arrows | BR-14 #1's comparison, over whole cycles | Last cycle not fully tracked (BR-14 #1's rule) |
| 6 | The end | Spent, Saved and Left over, then *Ask an AI about {cycle}* (marigold, the one act) and *Done* | Same as page 2 | Never |

**Copy rules (principle 94):** every sentence is a count, an amount or a date. There are no adjectives about the person, no ranks, no praise and no warnings. *Not logged*, *Saved* and *Used* stay out of pages 3–5 (BR-14). Bills are on page 3 but not in the page 4 grid.

**Page 4's chart: day bars (chosen by the owner, 2026-11-14).** The days run left to right as one bar each, scaled to the cycle's biggest day. A dotted `sInk2` line marks the daily share, `(I − K − bills) / days`. Bars past the share are solid `sInk` and the rest are the lighter `sSoft`, so "over" is shown by fill, with no hatch or colour. A day with nothing spent is a small dot on the axis. The biggest bar carries its amount. Under the axis are the first date, the biggest day's date and the last date, plus a small dot under each bar of the most-spent weekday. The bars have no y-axis labels, because the sentences carry the numbers (principle 92).
- **Rejected alternatives:**
  - The bottom-filled day blocks (first draft), which the owner disliked.
  - Dots against a share ring.
  - A calendar of tones.
  - All three are kept as switchable options in mockup 45 for the record.
- **What's lost:** day bars give up the weekday grid. The weekday line below makes up for it.

**The weekday line** ("Your 5 Saturdays came to ₹15,840") shows only when one weekday holds at least 35% of everyday spending. It names the day and the amount, and never says "weekend spender".

## 3. Doors (Spends only)

- **On a finished cycle:** the top card, above Ask AI, is a dark story card. It shows page 2's headline ("₹4,400 left over" or "₹3,100 more than you earned"), a small day-bars preview and *See the story*. It shows when the cycle has at least 10 entries.
- **On the current cycle, days 1–7:** a slim row reads "**September is done.** See your month ›" and opens the story directly. After day 7 it is gone. There is no stored "seen" flag, so there is **no schema change**.

## 4. Interaction, motion, accessibility

- **Navigation:** tapping the right two-thirds goes forward and the left third goes back. A swipe, the arrow keys and TalkBack's *Next* and *Back* also work. The close button and system back return to Spends. There is no auto-advance and no hold-to-pause.
- **Progress:** a row of 6 thin bars at the top; a skipped page has no bar.
- **Motion:** a short spring slide between pages, and a crossfade under reduced motion. Nothing animates on its own.
- **TalkBack:** each page is one sentence with spoken amounts, as listed in mockup 45. The day bars are one node that reads the facts, not 30 bars.
- **Look:** the story uses one dark "evening" surface in both themes, so it reads as a separate moment. It needs story tokens (`design-system`). Amounts are set in Anek Latin at a narrower width for the big lines.
- **Layout:** in two panes or on a tablet, the story opens as a full-height sheet over Spends, not full screen. Test at the `TestWindows` sizes.

## 5. Edge cases

| Case | Behaviour |
|---|---|
| First ever cycle | No page 5 |
| Cycle with fewer than 10 entries | No story and no door |
| Weekly cycles | No story. They are too frequent for a once-a-month moment. **Assumption to confirm.** |
| Spending past income | Page 2's headline reads "₹X more than you earned". The part of the bar past the income mark is striped |
| Income set to *It changes* or none | Page 2 shows "You spent ₹X" with no bar. Page 4 has no share line, and every bar uses the one lighter fill |
| A back-dated entry after the story was seen | The story is rebuilt each time it opens, from the same use cases as Spends |
| Notes off or empty | Page 4 shows the biggest day without a note |

## 6. Build plan (when approved)

1. **Docs:** add a DECISIONS row (story on Spends, no Home moment, no carry-over; partly supersedes case study 33's P3 verdict). Add SPEC BR-20 *Month story* and FR-SP-7, a UI_DESIGN section with the story tokens, and a PLAN milestone. → verify: the BR-20 worked example reproduces mockup 45's numbers.
2. **Domain (TDD):** `lib/month_story/domain/` gets `BuildMonthStory`, a pure use case from a cycle's entries, the cycle and the previous cycle to a `MonthStory` entity holding the list of present pages. It reuses `PeriodCalculator`, the BR-13 percentages and BR-14 #1's comparison. → verify: unit tests for each skip rule, the 30-, 31- and 28-day cycles, spending past income, no income, ₹0 days, and the 35% weekday threshold.
3. **Bloc:** `MonthStoryBloc` with sealed events, `restartable()` for load, and `FakeClock`. → verify: bloc tests.
4. **Presentation:** a `PageView` story route, a `DayBarsPainter` (a painter, as with the pace chart; no `fl_chart`) that is also used small in the cover and door previews, and the two doors on Spends. All strings go in the ARB file. → verify: widget tests at the `TestWindows` sizes, TalkBack semantics tests, and a reduced-motion test.
5. **Done:** run `flutter analyze` and `flutter test`, and changed-line coverage of at least 90%.

No new package and no schema change.

## 7. Open questions for the owner

1. Is "Left over" the right word, or should it be "Not spent"? Hand to `design-content`, and check it against Home's hero words.
2. Should weekly-cycle users get the story at all, perhaps every 4 weeks?
3. Is 10 entries the right minimum for the door to show?
4. Sharing (deferred): the pages are composed so a later *Share as image* could render one, with amounts hideable. That needs `share_plus` and its own decision.

## 8. Before the build

A blind read of mockup 45 with 3–5 people. Ask "What does page 4 tell you?" and "Did anything feel like a judgement?". Hand to `design-validation`.
