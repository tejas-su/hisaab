# 14. Unfold: a close competitor, compared

## Job of the study
The owner found [Unfold: Money & Budget Tracker](https://play.google.com/store/apps/details?id=com.unfoldmoney) (`com.unfoldmoney`) on Google Play and noted that its screens look very like Hisaab's. The questions:
- What does it do that we don't?
- What should Hisaab take from it, in product and in UI?
- What should Hisaab avoid?

## Method and limits
- **Sources read:** the Play Store listing (`hl=en_IN`, fetched 4 Nov 2026), its full description, its Data safety summary and its six screenshots (900 × 1600).
- **Limits:**
  - The app was not installed, so flows, motion, empty states and the Add flow beyond one screenshot are unseen.
  - It has **10+ downloads** and no public reviews (listing updated 1 Nov 2026), so nothing here is evidence that its users like a pattern. Treat it as one designer's answer to the same problem, not as validated UX.
  - Web search for "Unfold money" returns Fold Money and Unfold, the story-maker app; neither is this one.

## What Unfold is
From the listing: "a calm, simple way to see where your money goes. Add a spend in seconds, see your week at a glance, and know exactly what's left in your budget." Its features:
- Spends and income.
- A week and month view on Home.
- Per-category budgets.
- Net worth from accounts the user adds.
- A transaction list with a calendar, filters and search.
- **Privacy mode:** one tap hides every figure on screen.
- CSV export.
- Light and a "warm graphite" dark theme.
- **Sign-in with Google.** Data safety says it collects personal and financial info, encrypted in transit and not shared, so the data lives on its servers.

## The screens

| # | Screen | What it shows |
|---|---|---|
| 1 | Home, "Your week at a glance" | "Spent this week ₹6,640" with a *Week / Month* toggle and "Daily average ₹1,660". A bar per weekday (M–S): past days dark grey, **today orange**, future days flat stubs. The part of a bar over the daily budget is **striped orange**, with a key below: "Striped part is over your daily budget of ₹1,852". Under that, a three-stat row (Income ₹93,120 in green · Budget left ₹18,221 · Net worth ₹6,32,041), then *Latest*, grouped by day with "₹540 spent" in each day header |
| 2 | Transactions | *All · Spending · Income · Transfers* segments; *Accounts* and *Categories* dropdowns and a calendar button; "Search payees and notes"; a summary "40 transactions · ₹39,179 spent · ₹93,120 received"; rows with a tinted category icon, payee as the title, "Category · account" below, and red "−₹120" |
| 3 | Add, "Add it in two taps" | A sheet titled "₹420 at Kashi Art Cafe". One card of six rows: Type (*Spent* in red / Received / Moved), Category, Paid from, Date (*Today* / *Yesterday* / calendar), Time, Note (optional) |
| 4 | Budgets, "Budgets that keep pace" | "Left to spend in October ₹18,221", a progress bar, "₹39,179 spent · of ₹57,400", and a callout: "**You can spend ₹1,071 a day for the next 17 days.**" Category rows with a bar each and words on the right: "₹370 over" (red bar), "₹0 left", "₹980 left" |
| 5 | Net worth | ₹6,32,041, "+₹1,25,881 (+24.9%) past 3 months" in green, a stacked area chart in four oranges (1M / 3M / 6M / All), and "You own − You owe = Net worth" as an equation row |
| 6 | Dark | The Home of screen 1 on warm graphite |

### Visual language
- **Cards on a grainy pastel gradient:** lilac and peach on Home, mint and lime on Budgets, sand on Net worth. Each screen has its own wash.
- **Hero numbers:** a very large, tight grotesque, with a **small ₹ raised to the cap line**, so the digits carry the weight.
- **Controls:**
  - Pills everywhere. The pick is a black-filled pill with white text, the same as our D100 `ink` pick.
  - A floating "‹ Oct ›" month pill and an avatar sit in the top bar.
- **Wordmark:** "unfold." in lower case with an **orange full stop**. That is the same device as "hisaab•" with its marigold dot.
- **Colour meanings:**
  - Orange means today (the bar) *and* over (the stripes).
  - Red means spent (the Type pill and the amounts) *and* over (the budget bar).
  - Green means income *and* growth.
  - Each category has its own tint.

## Compared with Hisaab

| Question | Unfold | Hisaab |
|---|---|---|
| The hero | What you **spent** this week or month. The daily figure is a callout on the Budgets screen | What is **safe to spend today** (BR-4), backed by the Arizona / Think Forward finding that a month-left figure raises spending (UI_DESIGN §1) |
| Past days | A bar per day this week, overspend striped | Day Blocks only run from today to payday, so past days are gone. History is the cumulative pace line on Spends. Mockups 19 and 20 explore it |
| Over | Striped segment plus a sentence key; red bars and red amounts elsewhere | Hatch past the limit tick, words, never red (BR-12, D-principle 4) |
| Add | Amount, then a six-row card | Add → digits → Next → tile; the tile saves (FR-AD-5) |
| Back-dating | *Today / Yesterday / calendar* in one control | A *Today ▾* chip that opens a sheet with *Today · Yesterday · Pick a date* (`date_chip.dart`, FR-AD-5) |
| Finding an entry | Search payees and notes, calendar, filters | Category and cycle chips (FR-SP-6); no search |
| Day totals in lists | Yes, "₹540 spent" | Yes, in *Every entry* (`entries_day.dart`) |
| Limit rows | "₹980 left" / "₹370 over" / "₹0 left" in words | "₹840 past limit" only once over; nothing in words before that (`category_spend_row.dart`) |
| Hiding figures | Privacy mode, one tap | Nothing |
| Accounts, transfers, net worth | Yes | Out of v1 (SPEC §1.2) |
| Data | Google sign-in, server-side | Offline, no sign-in, nothing leaves the phone (NFR-2, NFR-3) |
| Colour | Orange, red, green, category tints, a pastel wash per screen | One signal colour; no red, green or category colours |

**What this confirms:** two independent designers reached a calm card on warm neutrals, a black pill pick, an over shown as stripes rather than a colour change, a daily allowance in a plain sentence, and a warm dark theme. That supports D100, D106 and D108 and the hatch rule in BR-12.

## Recommendations

Ranked by value for the cost, in Hisaab's own terms. None is agreed; each needs a DECISIONS row before it is built.

### Take

1. **A one-line key under every hatch.** Unfold writes "Striped part is over your daily budget of ₹1,852" under the chart. Our hatch on limit bars, and on the over day in Day Blocks, is never explained in words.
   - Under *Where it went*, add one caption line, shown only when a row has a hatch: "Striped part is over the limit."
   - This follows principle 7, "every icon has a word" (WCAG 1.4.1).
   - Cost: one ARB string and one conditional caption.

2. **Limit rows say what's left, in words.** Today a row with a limit shows its share until it goes over. Instead, show "₹980 left" while under and "₹840 past limit" once over. "₹0 left" reads as calmer than a full bar.
   - This makes BR-12's display a sentence rather than a picture to decode.
   - Cost: copy plus `category_spend_row.dart`.

3. **A *Yesterday* option on the date chip: already built.** People log the morning after more than any other back-date. Unfold puts it in the control itself.
   - Correction (4 Nov 2026): `date_chip.dart` already opens *Today · Yesterday · Pick a date*, so yesterday is 2 taps. Nothing to do.

4. **Hide figures from the recent-apps screen, with no UI.** Unfold's privacy mode answers a real worry: a shared phone and someone looking over your shoulder are common in India. A visible toggle adds a control to Home and fails "less, but better".
   - Zero-UI half: mark the window secure while it is in the background, so the app switcher shows a blank card rather than your money. On Android 13+ this is `Activity.setRecentsScreenshotEnabled(false)`, which leaves screenshots working. `FLAG_SECURE` would also block screenshots, which people use to share.
   - Visible half (an eye button beside Settings that swaps every amount for "₹•••"): needs a blind read before it is added.

5. **A small, raised ₹ on hero amounts.** Unfold sets the rupee sign at about 40% of the digit size, raised to the cap line. The number reads first and the sign stops competing with it.
   - For us: `AmountText` in the hero only, in Anek, with tabular figures kept.
   - Check at 1.5× text (E12), and keep TalkBack reading "1,430 rupees".
   - Prototype it in a mockup next to the current hero.

6. **A *This week* picture: a bar per weekday, with the over part hatched.** This is the strongest idea in Unfold and it fills our known gap, since Day Blocks forget past days.
   - Where: when the hero is toggled to *This week* (FR-HO-2), the Day Blocks could swap for seven bars, Mon–Sun:
     - past days in `ink2`;
     - today marigold, with the ink edge in light;
     - future days as idle stubs;
     - the part of any bar over that day's share hatched, with a one-line key.
   - It joins the mockup 19/20 work (dot ledger, cycle heatmap) as a fourth candidate for history. Unlike those, it reuses a chart form everyone already reads.
   - **Cost and risk:**
     - Each past bar needs that day's share `A`, which BR-3 recomputes from the start-of-day pool. It is derivable, but needs a rule written for back-dated entries (does an edit change a past day's line?).
     - It conflicts with FR-HO-2 ("the Day Blocks ... stay on today").
     - Unfold's single flat "daily budget" line is simpler than our per-day `A`. Showing one line (today's `A`) is honest only if the caption says so.

7. **Search notes in *Every entry*.** Notes are where people write "Swiggy" or "Ravi's birthday". Searching them answers "when did I last…" with no new data.
   - It is a field on the list screen, not on the Add flow.
   - It is lower value while notes are optional and short. Revisit when usage data shows notes are used, or with M6.

### Already ours, keep it
- **The daily figure as the hero.** Unfold puts "₹1,071 a day for the next 17 days" in a callout on its third screen. We lead with it, and the research behind UI_DESIGN §1 says that is the right order.
- **Day totals in day headers**, which we already have.
- **No sign-in and no server.** This is a real difference in the store. Play Store copy and the Data safety form should say it plainly: "No sign-in. Nothing leaves your phone." (handoff to `design-brand` and `design-content`).

### Don't take
- **Spent as the hero** with a three-stat row (income · left · net worth). It is the month-total framing that the research warns about, and it shows four numbers where we show one.
- **Red, green and category tints.** Unfold shows what happens without a one-colour rule: orange means both *today* and *over*, and red means both *spent* and *over*. That is the confusion D8–D10 prevent.
- **A pastel wash per screen.** It is pleasant, but it is decoration with no meaning, and grain already lives on our hero only (D106).
- **The six-row Add card** (type, category, account, date, time, note). Unfold calls it "two taps", but each row is a decision. Our tile-saves flow is faster, and principle 3 forbids adding to it.
- **Accounts, transfers and net worth.** These are out of v1 (SPEC §1.2), and each one adds a field to Add.
- **Payee as the row title.** It needs a payee field or SMS reading. Our rows lead with the category and use the note when there is one.

## Risk: the wordmark
"unfold." with an orange full stop and "hisaab•" with a marigold dot are the same brand device, in the same colour family, on the same kind of app, in the same store, aimed at the same Indian users.
- Hisaab's first commit is 26 Oct 2026. Unfold's first release date isn't shown, only its latest update (1 Nov 2026), so neither is known to be first.
- Either way, on a Play Store results page the two could read as related.
- Ask `design-brand` to judge distinctiveness before the store listing (SPEC Q3 already holds the title for a trademark search). Options:
  - keep the dot but change its form or position, for example a dot as the "i"'s tittle;
  - or lean on the Day Blocks as the mark.

## Store screenshots
Unfold's six screenshots are a useful pattern for our own:
- a two-line, benefit-first headline ("Your week at a glance", "Add it in two taps");
- one plain sub-line;
- one device frame;
- the light theme first, with the dark theme as the last screenshot.

Ours could read:
- "Know what you can spend today"
- "Add a spend in four taps"
- "Your money, till payday"
- "Ask any AI, see exactly what it gets"
- "Nothing leaves your phone"
- "Easy on the eyes at night"

This is a handoff to `design-brand`.

## Next steps
1. The owner picks which of recommendations 1–7 to pursue.
2. Mockup built: [21-unfold-takeaways.html](../../design/mockups/21-unfold-takeaways.html) shows 1, 2, 4, 5, 6 and 7 next to the screens as built, plus the store frames. The full plan for 1, 2, 4, 6, 7 and the store screenshots is [case study 15](15-unfold-takeaways-plan.md).
3. For 4, `design-platform` confirms the recents-screen API on our minimum SDK (API 24). `setRecentsScreenshotEnabled` is API 33+; below that, the only option is `FLAG_SECURE`, which also blocks screenshots.
4. Agreed items get DECISIONS rows and SPEC/UI_DESIGN updates in the same change.
