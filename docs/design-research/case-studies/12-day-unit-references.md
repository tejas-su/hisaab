# 12. The day unit: real-world references and four new directions

## Question
The hero's Day Blocks are one unit per day from today to payday. Today's unit is marigold and drains as you spend (UI_DESIGN §1, §3.3, §5.2). The owner rejected every visual form tried so far:
- rounded blocks (current build);
- capsule pills ([15-day-pills.html](../../design/mockups/15-day-pills.html));
- a ticket strip, gold ingots and mini rupee notes ([16-day-unit-concepts.html](../../design/mockups/16-day-unit-concepts.html)).

The owner kept the micro animations: fill in, drain with a trail, new-day collapse, underspend growth and payday assemble (D91, case study 05). The question: **what do shipped products and published design work do with "one countable unit per day, one of them live", and which structures could replace the block while the animations survive?**

Filters, from UI_DESIGN §2, §3.3 and §12, and from D7:
- Marigold `#FFB020` is the only hue and means today. Everything else is grey. No red, no green.
- State shows through fill, outline, hatch and words.
- No loops, no nagging, and reduced motion respected.
- Countable from 1 to 31 at a glance on a 360dp phone, and "a 5-year-old can use it".
- Already rejected: rings, the battery or fuel tank, a pace chart on Home, and streak shame.

## Method
**Desk and competitive research** (2026-10-29). This is the cheapest method that can change the decision: the owner asked for real references, and no user has seen a new direction yet. Every claim links to its source. Where only a search summary was readable, it says so.

Coverage limits, stated up front:
- **Not reached:** Mobbin (needs a login, see `sources.md`). Dribbble, Rive and LottieFiles community files and Awwwards were not searched in depth. A CodePen search for a Jhey Tompkins dot-matrix pen found none. Rauno Freiberg, Emil Kowalski and Paco Coursey were not researched, so none are cited.
- **Indian fintech** (CRED, Jupiter, Fi, slice, Jar): no public screen-level material on a per-day unit. A Jar search returned only company and savings-model facts ([TechCrunch](https://techcrunch.com/2021/08/31/tribe-and-arkam-back-jar-app-to-help-millions-in-india-start-their-savings-journey/)). Install and record the apps before citing them.

The confidence scale is case study 11's.

## Findings

### 1. Counting at a glance is a grouping problem
- **People see up to about four items at once without counting** (subitizing). Symmetry and layout speed up *counting* above four, but don't raise the limit ([Sakai & Fujii 2007, PMID 17657976](https://pubmed.ncbi.nlm.nih.gov/17657976); abstract only, in Japanese with an English abstract). High confidence: the limit of about four is a long-standing consensus.
- **Grouping into small clusters makes larger sets fast to count ("groupitizing").** People subitize each group, then add the groups. The fluency grows through primary school and predicts arithmetic ([Starkey 2014, Vanderbilt thesis](https://ir.vanderbilt.edu/handle/1803/14694); abstract read). Medium confidence: one thesis plus later citing work seen only in search summaries.
- **So for Hisaab:** 28 equal units in a row can't be counted at a glance. Today's rule (a 3dp gap above 16 days, UI_DESIGN §5.2) makes the row *denser*, not easier to count. Any direction should group the days, and weeks (7) are the group people already know.

### 2. Discrete units for the count, continuous fill for the amount
- **Apple's macOS discrete capacity indicator** is "a horizontal row of separate, equally sized, rectangular segments". Its segments "fill completely — never partially". Apple adds: "Consider using the continuous style for large ranges", because segments get "too small to be useful" ([Apple HIG, Gauges](https://developer.apple.com/design/human-interface-guidelines/gauges.md)). Medium confidence: platform guidance, not a study.
- **Hisaab already mixes the two:** the days are discrete, and today's money is continuous. That is the right split. The guidance warns that a day unit 6dp wide carries the count, not the amount. Today's unit needs enough size, or sub-units, to show a ₹60 spend (case study 05: a 2.4dp change was invisible).

### 3. Daily-allowance apps show a number, not a picture
Three such apps on the App Store ([Budge](https://apps.apple.com/pg/app/id6760899742), [Daily Budget Original](https://apps.apple.com/us/app/-/id747794925), [Pocket Buddy](https://apps.apple.com/app/id6766757353), seen only in a search summary) all lead with one daily number. None of their listings describes a per-day unit. Daily Budget Original's widget shows "a 3-days graph". Budge promises "one clear number" instead of "complex charts". The listings are marketing copy and the screenshots weren't checked, so medium confidence. D7's claim that no money app uses a day strip still holds from what was found. Budge's promise of "how much you can safely spend today" does mean the *number* is not unique to Hisaab.

### 4. The reference board

Fit with Hisaab's constraints: **good** (structure transfers as is), **partial** (one part transfers), **poor** (conflicts with a rule).

| # | Reference | What it shows | Transferable idea (structure, motion or material) | Fit |
|---|---|---|---|---|
| 1 | **Nothing Phone (3) Glyph Matrix** ([developer kit, GitHub](https://github.com/Nothing-Developer-Programme/GlyphMatrix-Developer-Kit); [9to5Google](https://9to5google.com/2025/07/01/heres-what-you-can-do-with-nothing-phone-3-new-glyph-matrix/)) | A 25 × 25 LED dot display on the back of the phone. Brightness runs 0–255 per object, and frames are drawn one by one. The toys include a stopwatch, a battery indicator and "real-time progress indicators, like an incoming delivery or countdown" | **A quantity drawn as a count of lit dots, plus one partly dimmed dot for the remainder.** It's discrete enough to count and has a continuous tail. LEDs switch, they don't slide, so the reduced-motion version looks almost the same as the full one | Good (structure); partial (the surface is Nothing's) |
| 2 | **Nothing OS dot widgets and the NDot font** ([Android Authority, OS 3.0 hands-on](https://www.androidauthority.com/nothing-os-3-hands-on-3488739/)) | Dot widgets and a dot font "drew many people to the small Android brand". The pedometer is "a stick man" on "a dotted line". OS 3.0 uses the dot font less and adds "extra dots elsewhere". A community post says OS 4.0 uses dots only "where it can define character rather than compromise readability" (search summary; [nothing.community](https://nothing.community/d/61774-nothing-os-evolution) failed to load) | **Use dots for a picture and never for the numbers.** The amount stays in Anek | Partial |
| 3 | **TI LM3914 dot/bar display driver** ([TI product page](https://www.ti.com/product/LM3914)) | The classic 10-LED ladder chip. One pin switches between a moving *dot* and a *bar*. In dot mode a small overlap between segments keeps every LED from going off at once (datasheet, via search summary) | **The "level in lit segments" idiom, with a hand-off between neighbours.** As one dot fades, the next is already lit, so the level never flickers to empty. This is the LED version of Hisaab's trail | Good (motion); poor if it ends up as a VU meter |
| 4 | **Teenage Engineering EP-133 K.O. II** ([MusicTech](https://musictech.com/news/gear/teenage-engineering-ep-133-k-o-ii-sampler-sequencer-composer/), [Gearnews](https://www.gearnews.com/teenage-engineering-ep-133-k-o-ii-review-better-than-an-mpc/)) | A custom "super segment hybrid display": fixed, pre-shaped LED segments that light up, likened to Game & Watch | **Fixed slots that light or don't: no layout reflow, just state.** Every day has a permanent place | Partial. Unverified detail: reviews only, no TE documentation found |
| 5 | **Apple macOS discrete level indicator** ([HIG, Gauges](https://developer.apple.com/design/human-interface-guidelines/gauges.md)) | Equal segments that fill whole; the guidance favours continuous for large ranges | **Separate what is counted (days) from what is measured (today's money)** (finding 2) | Good (as a rule) |
| 6 | **Android 16 `Notification.ProgressStyle`** ([Android developers](https://developer.android.com/about/versions/16/features/progress-centric-notifications)) | Android's own progress for "start-to-end journeys": *segments* for stretches, *points* for milestones, and a *tracker icon* at the current position | **A journey bar to a destination:** the segments are days, payday is the end point, and today is the tracker. Native to Android, so users already read it | Good (structure); poor (its examples colour segments by state, such as traffic) |
| 7 | **Instagram Stories progress bar** ([Android library imitating it](https://p.codekk.com/detail/651e87510c2d5a3fbe2aab87); [FlutterFlow thread](https://community.flutterflow.io/ask-the-community/post/recreate-the-instagram-stories-stepper-UZJA0pdb71ZIIM6)) | One thin segment per story. The current one fills in real time, and the rest show how many remain | **Thin segments as a count of what's left, with only the current one animating.** India's most-used segmented progress | Partial. Unverified: no official Meta source; known from use and imitations |
| 8 | **Flighty** ([Behind the Design, copy](https://cur.at/VcCahLU?m=web); [The Sweet Setup](https://thesweetsetup.com/flightys-beautiful-design-fast-push-notifications-make-it-one-of-the-best-flight-tracking-apps-on-the-app-store/); [TechCrunch](https://techcrunch.com/2022/09/08/flightys-app-will-bring-flight-tracking-and-more-to-your-ios-16-lock-screen/amp/)) | Visuals that "recall airport signage conventions". A countdown up to 365 days out, 15 stages of a travel day, and an in-flight progress line with the plane on it in Live Activities and the Dynamic Island. 2023 Apple Design Award | **A destination you travel toward, drawn as a line with you on it,** and a plain countdown before it. Payday is the destination (the same metaphor as UI_DESIGN §1's EV range). The aim: "feels almost boringly obvious" | Partial. Apple's page wasn't fetched directly: a fetch of a guessed URL returned an unrelated article |
| 9 | **Calendar blister pack** (28-day oral contraceptive; [package labels via medlibrary](https://medlibrary.org/lib/rx/meds/blisovi-fe-120/page/6/), 403 to the fetch tool, read from a search summary) | Four rows of seven tablets with the weekdays printed above the first row, and day-label strips to match the start day. A pressed-out cavity shows a day used. The calendar is printed because "the success of OCP is tightly coupled to adherence" ([patent, via search summary](https://patents.justia.com/patent/10431070)) | **Days in rows of seven, one per cavity; used days stay visible as empty holes.** Grouped by week and countable, and designed for daily use by non-experts for decades | Good (structure); partial (height) |
| 10 | **Weekly pill organiser** ([Superpharmacy](https://superpharmacyplus.com.au/pill-organiser-weekly), [Apothecary Products](https://shop.apothecaryproducts.com/es/products/weekly-contoured-patterned-pill-planner)) | One labelled compartment per day with a flip lid; transparent lids "let users see whether a dose has been taken" | **A container per day, where empty means used,** readable without words | Partial (7 days, not 31; the block is already a container) |
| 11 | **Wait But Why, "Your Life in Weeks"** ([Cool Infographics](https://coolinfographics.com/blog/2015/4/17/your-life-in-weeks.html)) | A grid of 52 columns by 90 rows, one dot per week of a life | **Rows as the bigger unit and dots as the smaller one,** so a big count turns into a few rows. The dots make time feel finite | Partial (a sobering tone; Hisaab is calm) |
| 12 | **Year-progress dot widgets** ([Yearli](https://apps.apple.com/lb/app/yearli-year-progress-tracker/id6759508176), [Year Dots](https://apps.apple.com/ca/app/year-dots-progress-tracker/id6758513497), [Dotly](https://apps.apple.com/app/id6761205196)) | A crowded iOS genre of 365-dot grids. Dotly sells seven styles, including "Matrix", "Month Blocks" and "Segmented Arc" | **Proof that a dot grid of days reads without a legend,** and a warning that it's a commodity look | Partial. Dotly's style visuals weren't seen |
| 13 | **GitHub contribution graph** ([react-calendar-heatmap](https://github.com/freecodecamp/react-calendar-heatmap), [alexwlchan, 2015](https://alexwlchan.net/2015/github-contributions/)) | One square per day, weeks as columns, four shades of one hue plus empty | **Weeks as columns (7 tall) give a compact calendar,** and one hue in steps shows an amount | Partial. GitHub's own docs don't describe the levels ([docs.github.com](https://docs.github.com/en/account-and-profile/concepts/contributions-on-your-profile)); 7 tall makes today's cell tiny |
| 14 | **Timepage by Moleskine, Month Heatmap** ([MacStories](https://www.macstories.net/reviews/timepage-a-beautiful-and-clever-calendar-app/), [AppleInsider via search](https://appleinsider.com/articles/17/01/20/timepage-calendar-iphone-app-by-moleskine-adds-style-to-events/)) | Days get "deeper colors when more events are planned for them", one hue per theme | **Value steps of one colour carry a per-day amount** (Hisaab would use greys only) | Partial |
| 15 | **Gentler Streak, Activity Path** ([BGR](https://www.bgr.com/tech/gentler-streak-improves-activity-path-tracking-offers-50-off-in-black-friday-deal), [iMore](https://www.imore.com/apps/health-fitness-apps/want-to-hit-your-2023-fitness-goals-drop-apples-rings-and-try-gentler-streak-instead)) | A recommended band. Days inside it "connect", and leaving it breaks the line. Built as a kinder alternative to Apple's rings | **A range instead of a target,** and a kind tone. The connecting line is still a streak | Poor (a green band, and a streak) |
| 16 | **Linear cycle graph** ([Linear docs](https://linear.app/docs/cycle-graph.md)) | A target line spreads the work evenly over the remaining days and "flattens over weekends" | **Days need not be equal.** Not for Home: D7 rejects a pace chart there | Poor on Home; an idea for Spends |
| 17 | **Clue, cycle view** ([Dashboard Critic](https://dashboardcritic.substack.com/p/data-viz-going-in-circles-when-it); [Clue redesign](https://helloclue.com/articles/how-to-use-clue/clue-period-tracking-relaunched-and-newly-designed)) | A ring for a ~28-day cycle, with a marker on today and coloured phase arcs | **The best shipped "radial dial of days"**, and it relies on colour arcs and a legend | Poor (rings rejected, D7; colour-coded) |
| 18 | **Material 3 Expressive wavy progress** ([Material Components docs](https://gitea.com/784622644/material-components-android/src/branch/master/docs/components/ProgressIndicator.md), mirror; [9to5Google](https://9to5google.com/2025/05/16/material-3-expressive-loading-indicator/)) | A wavy linear and circular progress line that "can make longer processes feel less static" | **What not to do:** a wave that moves while you look at it is a loop, and it reads as *loading* | Poor |

Not on the board: Apple Activity rings and Fitness's ring calendar ([iMore](https://www.imore.com/how-view-your-past-activity-rings-and-workouts-activity-iphone)) and Copilot's pace chart ([Copilot help](https://help.copilot.money/en/articles/6045480-dashboard-tab-overview)). D7 already rejects both. Copilot also colours bars green to red by pace. Oura, Whoop, Streaks, Structured, Amie, Fantastical, Carrot, Mercury, Weathergraph and the budgeting apps YNAB, Monarch, Emma, Toshl and Spendee showed no per-day unit in what could be read. Weathergraph's hourly bars ([App Store](https://apps.apple.com/app/id1501958576)) are a chart with axes, which D7 keeps off Home.

## Directions
Assumptions: the hero is 320dp wide on a 360dp phone (case study 10), with a 20dp content inset each side, so 280dp of content. The payday flag ("⚑ 4 Nov") takes about 56dp, leaving **about 224dp** for the day units. These are estimates, and a mockup must measure them. The worked example is SPEC's: 9 days on Mon 26 Oct and 28 days on Wed 7 Oct, payday Wed 4 Nov.

### A · Dot ledger (an LED column per day)
*Grounded in 1, 2, 3, 4 and 5, plus the groupitizing evidence.*
- **Static look:**
  - Each day is a column of **6 dots**, 40dp tall: 4.5dp dots at a 7dp pitch. A wider gap (+4dp) after every 7th column groups the days into weeks.
  - **28 days:** one dot per column at about a 7.6dp pitch, which fits (28 × 7.6 + 3 × 4 ≈ 224). At 31 days the dots step down to 4dp at a 6.7dp pitch.
  - **9 days:** each day becomes **3 dots wide** (18 dots), with a 5dp gap between days. Fewer days means more dots per day, so today gets finer steps.
  - Idle days are dots in `blockIdle`.
- **Today:** the first column, its dots lit marigold, inside a 1.5dp `ink` capsule outline. The capsule replaces the edge marigold needs on light (1.81:1 on `surface`). The **lit count is today's level**. The topmost lit dot is dimmed in proportion to the remainder, so the level is continuous (Glyph Matrix brightness). Spent dots stay as `hairline` ghost dots, so the empty part is always visible (principle 21). The D91 cap becomes "once anything is spent, the top dot goes out": a whole dot, which can't be missed.
- **States:**
  - **On track:** lit marigold dots, ghost dots above them.
  - **Slow down:** one lit dot, the rest marigold rings (outline) inside the ink capsule.
  - **Over today:** today's column turns to a **checkerboard of `displayInk2` dots**, every other dot lit. This is the dot-matrix form of the hatch. Future columns lose their top dot(s), and each lost dot stays as a ring, so tomorrow is visibly shorter.
  - **Over the cycle:** every column is rings only.
  - The words are unchanged (§3.3).
- **Signature micro animation: "dots go out".** After the tray exits, lit dots switch off from the top, 40ms apart. Each leaves a 300ms afterglow at 50% (the D91 trail as phosphor decay), and the next dot's dim starts before the last one's glow ends (the LM3914 overlap). The others:
  - **New day:** yesterday's column goes dark and the matrix shifts one column left, like a marquee. Today's column then lights from the bottom (the fill in).
  - **Underspend:** each future column gains its top dot, sweeping left to right 20ms apart.
  - **Payday:** the display "boots" column by column from the left (400ms cap).
  - **Reduced motion:** every dot jumps to its end state, which on an LED looks correct, not like a cut.
- **Risks:**
  1. It reads as Nothing's look on Android, the one platform Hisaab ships on.
  2. A column of dots that empties can read as **signal bars, an equaliser or a battery ladder**, the cliché §12 rejects. Keep every future column the same height unless the money says otherwise, and never step heights left to right.
  3. 4–4.5dp idle dots at the 1.5:1 `idleBlock` floor may vanish on low-end panels. A small mark likely needs more contrast than a 40dp block; check with design-accessibility.
  4. Six levels per day are coarse at 28+ days. A small overspend spread over 20 days may not move any future dot, so dim the top future dot too.
  5. 186 circles in one painter is cheap, but must stay inside the existing `RepaintBoundary`.
- **Brand tie:** the unit becomes the **dot of "hisaab•"**. Today is made of the wordmark's marigold dots, and D41's splash already rounds today's block into the h•'s dot.

### B · Blister card (a week-row calendar)
*Grounded in 9, 10, 13 and 11, plus groupitizing.*
- **Static look:**
  - The remaining days sit in a grid **7 columns wide, aligned to weekdays (Mon–Sun)**. Cells are 36 × 14dp with 4dp gaps across 280dp, so the payday flag lives *in* its cell.
  - **9 days (Mon 26 Oct):** two rows, Mon 26–Sun 1, then Mon 2 and Tue 3, with Wed 4 as the flag cell. About 32dp tall.
  - **28 days (Wed 7 Oct):** five rows, the first starting at Wed, two blank cells before it. About 86dp tall, **+46dp** over today.
  - Past days are not shown, as now: blank cells, not pressed-out ones, so there is no shame and no history.
- **Today:** a marigold cell with an `ink` edge that drains **sideways** (right to left across 36dp). 14dp is too short to drain from the top.
- **States:**
  - **On track:** today drains; future cells are `blockIdle`.
  - **Slow down:** today's cell is outlined, with a thin sliver.
  - **Over today:** today's cell is hatched, and each future cell's fill shrinks inside a ghost outline.
  - **Over the cycle:** every cell is outlined.
- **Signature micro animation: "press out".**
  - **New day:** yesterday's cell sinks (scale 0.92) and fades to blank like an emptied cavity. Marigold steps to the next cell, wrapping to the next row's start on a Monday.
  - **Payday:** a new card slides up and the cells fill row by row.
  - **Reduced motion:** a crossfade.
- **Risks:**
  1. **Height:** 32 to 86dp across a cycle, so the hero changes height and the Today list moves, and +46dp pushes hierarchy item 4 down (case study 10).
  2. A wall calendar reads as **schedule or planner**, not money.
  3. Blank leading cells look like missing days to a child.
  4. Today's cell (36 × 14dp) shows a small spend worse than the current 40dp block.
  5. The weekday alignment means nothing without weekday letters, and letters add text and l10n.

### C · Glass and road (today's tank plus a journey rail)
*Grounded in 6, 8 and 7, plus groupitizing.*
- **Static look:**
  - On the left, **today's tank**: about 40 × 40dp, marigold with an `ink` edge, draining from the top as now.
  - On the right, a **10dp rail** of the remaining days from tomorrow to the payday flag. There is one notch per day (1dp breaks) and a taller tick every 7 days, like a Flighty route or a `ProgressStyle` journey.
  - **28 days:** 27 notches over about 170dp, about 6.3dp each.
  - **9 days:** 8 notches, about 21dp each.
  - The rail's **thickness** is each future day's share relative to today's planned share, so equal days give a flat rail.
- **Today:** the only marigold, and the only tall element. The rail is grey.
- **States:**
  - **On track:** a full tank and a flat rail.
  - **Slow down:** the tank is outlined, with a thin sliver.
  - **Over today:** the tank is hatched. The rail **thins** (10 to 9dp), and a ghost outline keeps the old thickness: cause, then effect.
  - **Over the cycle:** the tank and rail are outlines only.
- **Signature micro animation: "the next day steps up".**
  - **New day:** the rail's first notch lifts, swells and morphs into the tank (spatial spring, damping 1). The rail is one notch shorter, and the tank fills in.
  - **Underspend:** the rail thickens in a left-to-right wave.
  - **Payday:** the rail draws from the tank to the flag like a route stroke, and the notches tick in.
  - **Reduced motion:** a crossfade.
- **Risks:**
  1. The tank alone is a rounded rectangle that drains, which is the **battery** §12 rejects; it needs no terminal nub and no bars.
  2. A thin rail reads as a **loading or progress bar** ("wait"), not as days of money.
  3. Today's size is no longer comparable with a future day's, which weakens "every piece is the same chocolate". The thickness encoding has to carry it, and thickness changes of 1dp are hard to see.
  4. It is the nearest to the rejected blocks and pills: the owner may see it as a block plus a bar.

### D · Day dial (a radial clock of days): evaluated and not recommended
*Grounded in 17 and 12, plus the radial view in Flighty's Dynamic Island (8).*
- **Static look:**
  - A ring of N ticks around the amount, today's tick a marigold wedge at 12 o'clock that drains along its arc, and payday a gap with the flag.
  - **9 days:** 9 wide wedges.
  - **28 days:** thin 12° ticks.
- **States:** the same fill, outline and hatch on the wedges.
- **Signature:** on a new day the ring rotates one tick anticlockwise.
- **Why not:**
  1. **Rings are rejected** (D7: "Apple-owned, angle reads poorly", Cleveland & McGill in §12).
  2. **31 ticks on a circle have no start or end to count from**, and grouping by weeks on a circle reads as a clock face.
  3. Wrapping the 76sp amount at 1.5× text breaks the ring or the number.
  4. A rotating ring is the spinner idiom ("loading").
  5. Clue needs colour arcs and a legend to make it readable.

## Ranking
| Rank | Direction | Countable 1–31 | Today's drain visible | Fits one colour and states | Height on 360dp | Distinct from what was rejected | Main risk |
|---|---|---|---|---|---|---|---|
| **1** | **A · Dot ledger** | Yes, week groups | Yes: whole dots out, and the cap is a whole dot | Yes; checkerboard = hatch | 40dp (as now) | Yes: the unit is made of dots | Nothing association; signal-bar read |
| 2 | C · Glass and road | Yes, week ticks | Yes (bigger tank) | Yes | 40dp | Partly | Battery and loading-bar reads |
| 3 | B · Blister card | Yes, rows of 7 | Weaker (14dp cells) | Yes | 32–86dp, varies | Yes | Height; reads as a planner |
| — | D · Day dial | No | Weak (angle) | Yes | Grows with the amount | Yes | Rejected rings |

**Top pick: A, the dot ledger.** It is the only direction that is:
- **Countable:** week groups of dots.
- **More legible than today's block:** whole dots go out, and the 0.9 cap becomes "one dot out".
- **No taller.**
- **Kind to reduced motion:** an LED that steps looks right without animation.
- **Every loved animation keeps a native form:** the drain, the trail as afterglow, the new-day shift, the underspend sweep and the payday boot.

It also gives the brand a reason: today is literally the wordmark's dot. Its risks are about the look, and a blind read can test them. C is the fallback if A reads as Nothing or as signal bars.

## Implications for Hisaab (handed to design-product)
1. Mock A (and C as a control) in the style of mockup 16, at 9, 28 and 31 days, in all four states, light and dark, and at `TestWindows.smallPhone`. Replay every animation, with a reduced-motion toggle.
2. Whatever wins: **group the days by week** (principle 50) and **keep the day count discrete while today's money stays continuous** (principle 51).
3. **Conflicts with `DECISIONS.md`** (it wins until a new row changes it):
   - D7 names "Day Blocks";
   - D91 defines the 0.9 fill cap and the trail for a block;
   - D41's splash animates day blocks;
   - UI_DESIGN §5.2 fixes the geometry (40dp, a 6dp minimum width, 6/3dp gaps);
   - UI_DESIGN §3.3 describes states for a block.

   A, B and C each need a new row superseding those parts. No spec, UI_DESIGN, mockup or code was changed here.

## Open questions
1. **Blind read with real people, 5 per round** (case study 05's method, which used simulated personas): mixed literacy, Hindi and English, UPI-first, low-end Android. Show A, C and the current blocks cold. Tasks:
   - "How many days until payday?" Measure time and errors at 9, 28 and 31 days.
   - "How much is left today?"
   - "What happened?" after an overspend frame strip.
   - SEQ after each task.
   - Ask whether A reads as signal bars, a battery or Nothing.
2. What is the smallest dot that holds 1.5:1 visibly on a low-end panel outdoors? (design-accessibility)
3. Should the week gap follow the calendar (Mon–Sun) or the count from today (every 7 days)? The calendar matches the blister card and D37's *This week*; the count is stable as days pass.
4. Indian fintech references remain unrecorded. Record CRED, Jupiter, Fi, slice and Jar on a device before claiming no one uses a dot or day unit.

## Handoff
- **design-product:** the ranking and the D7/D91/D41 conflicts.
- **design-validation:** open question 1; mockups for A and C.
- **design-motion:** the "dots go out" choreography, the afterglow overlap and the reduced-motion form.
- **design-accessibility:** dot size and idle-dot contrast; checkerboard legibility.
- **design-brand:** the wordmark-dot tie.
