# 15. Unfold takeaways: research and design plan

## Scope
The owner asked for research and a plan covering colour, components, micro-animation, UX and every other aspect of the items from [case study 14](14-unfold-money.md), drawn in [mockup 21](../../design/mockups/21-unfold-takeaways.html):

| # | Item | In this plan |
|---|---|---|
| R1 + R2 | Limit rows in words, and a key under the hatch | §1 |
| R6 | *This week*: a bar per weekday | §2 |
| R4 | A blank card in recent apps; optional eye button | §3 |
| R7 | Search in *Every entry* | §4 |
| — | Play Store screenshots | §5 |

Out of scope: R5 (the raised ₹), at the owner's request, and R3 (*Yesterday*), which is already built in `date_chip.dart`.

**Status (4 Nov 2026):** R4, R1 + R2 and R6 (W2) are **built** (D109–D111), with SPEC and UI_DESIGN updated. R7 was built (D112) and then **removed at the owner's request** (D113); §4 stays as the record. Store screenshots wait for the wordmark decision (`design-brand`); R4b waits for a blind read.

**As built, where it differs from this plan:**
- R6: today's block does not travel into its weekday's column. The rows crossfade (150ms) while the card resizes and the bars rise from the baseline, today's first. The travel needs shared geometry across two painters; it is left for a later pass.
- R6: no per-letter payday flag; the existing flag column at the row's end stays, so payday is still shown once.
- R6: the hero is still one TalkBack node whose label changes on the toggle; no extra `SemanticsService` announcement was added, since the existing toggle test shows the new label is read.
- R1 + R2: the swatch reuses `LimitBarPainter` (`HatchKey`, `lib/spends/presentation/widgets/hatch_key.dart`).

**Assumptions** (defaults chosen, per the owner's standing preference):
- The current-cycle scope stays everywhere. No item loads other cycles.
- No new dependency. Everything uses the existing widgets, tokens, `Haptics` and `HisaabMotion`.
- Copy below is draft until `design-content` reviews it.

## Method
**Desk research** (4 Nov 2026), plus a read of the code each item touches. Coverage limits:
- **Not read:** `developer.android.com`'s `Activity` reference page was too large for the fetch tool to reach the method, so its API level comes from the [.NET binding of the same API](https://learn.microsoft.com/dotnet/api/android.app.activity.setrecentsscreenshotenabled) and from [XDA](https://www.xda-developers.com/android-13-developers-disable-app-previews/). Two proandroiddev articles returned 403.
- **No first-party source found** on how Google Pay, PhonePe, Paytm or Revolut hide balances. The balance-hiding evidence below comes from other banks and wallets.
- **No source confirms** Apple's exact Screen Time or Health chart styling. Only the HIG Charts page is first-party.

The confidence scale is case study 11's.

---

## 1. Limit rows in words, with a key for the hatch (R1 + R2)

### Research
- **Words, not a picture to decode.** Apple's HIG Charts asks you to "summarize the main message of your chart" and to avoid "relying solely on color" to carry essential information. Shapes or patterns can supplement colour, and the meaning needs words as well ([HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts.md)). High confidence (first-party).
- **A legend is how a chart explains a pattern.** The HIG lists a legend as the element that "describes chart properties that aren't related to a mark's position, such as the use of color or shape". Our hatch is exactly that kind of property.
- **"Left to spend" confuses people when it means two things.** Monzo users repeatedly ask what "Left to spend" means, because it mixes the balance with the budget ([Monzo community](https://community.monzo.com/t/what-does-left-to-spend-mean-in-the-app/107654)). Medium confidence (user reports). So "left" must be attached to the limit it is measured against, which a row naming the category does.
- **Unfold** writes "₹980 left", "₹0 left" and "₹370 over" on each budget row (case study 14, screen 4).

### UX
- **A row with a limit**, while under it, reads **"Food · ₹200 left"** and keeps its share (39%).
  - At exactly the limit, it reads "Bills · ₹0 left".
  - Past the limit, nothing changes: "Shopping · ₹840 past limit", with no share (BR-12, as built).
- **A row without a limit** doesn't change.
- **The key** is one line at the bottom of the *Where it went* card, shown only when at least one row is hatched: a hatch swatch and "Striped part is over the limit."
- **The words fix a gap the picture can't.** When a limit sits beyond the biggest bar, no tick is drawn (`category_spend_row.dart`), so today the user can't see the limit at all. With R2, the words say it.

### Components
| Part | Change |
|---|---|
| `CategorySpendRow` (`lib/spends/presentation/widgets/category_spend_row.dart`) | Adds the `limitLeft` detail when `limit != null && spent <= limit`, as a second span in the same style as `pastLimit` (`bodyMedium`, `ink2`). The share stays |
| `WhereItWentCard` | Adds the key row under the last row, only when any row is past its limit |
| `LimitBarPainter` | Reused as is for the key's swatch: a 22×8dp bar with `fill: 1, limitAt: 0` paints solid hatch. No new painter |

### Colour and type
- No new token. The detail text is `ink2` on `surface`: 7.20:1 in light and 6.42:1 in dark (UI_DESIGN §3.2).
- The key text is `bodySmall`, `ink2`. The swatch is `ink` hatch on `sunk`, as the bars are.

### Motion and haptics
- **None added.** The rows only change when the data changes: on a cycle switch, which already rebuilds the card, or live in two panes. A crossfade here would be motion without a gesture behind it (principle 5).

### Copy (draft)
| Key | English | Note |
|---|---|---|
| `limitLeft` | `{amount} left` | Pairs with the existing `pastLimit` |
| `hatchKey` | `Striped part is over the limit.` | Visual-only, so it is excluded from semantics (below) |

### Accessibility
- The row stays one TalkBack node (`categoryRowSpoken`). Add `limitLeft` to `_spoken`: "Food, 9,800 rupees, 39 percent, limit 10,000 rupees, 200 rupees left."
- The key is wrapped in `ExcludeSemantics`. It describes how the bar *looks*, and the HIG says to "describe what the chart's details represent, not what they look like". Every hatched row already says "past limit" in words.
- At 1.5× text (E12) the name and detail wrap onto two lines and the amount stays right-aligned. Test it.

### Spec and docs
- **SPEC BR-12 Display:** add "Under the limit, the row says '₹X left'; at the limit, '₹0 left'." **FR-SP-4:** add the key.
- **UI_DESIGN §5.4:** the row and the key. **DECISIONS:** one row.

### Tests (test-first)
- Row: under the limit, at it exactly (`₹0 left`), past it, without one, and with a limit above the biggest bar (words present, no tick).
- Key: shown only when some row is past its limit; absent from the semantics tree.
- `_spoken` for each case.
- Pixel check: the row's amount edge stays aligned with and without the detail (pixel-alignment memory).

**Cost:** small. Two strings and two widget branches.

---

## 2. *This week*: a bar per weekday (R6)

### Research
- **Bar marks suit "a sum per period".** "Bar charts work especially well when each value can represent a sum, like the total number of steps taken in a day" (HIG Charts). A day's spending is that kind of sum. High confidence.
- **Start bars at zero, and use a dynamic range** so the tallest bar nearly fills the plot, as the Health app's Steps chart does (HIG Charts).
- **A reference line must say what it is.** Vicki Boykis's critique of Screen Time asked whether its average line meant the day's, the week's or the lifetime average, and recommended labelling it ([vickiboykis.com, 2019](https://vickiboykis.com/2019/04/29/breaking-down-apples-ios-screen-time-report/)). Medium confidence: a single critique, but it matches the HIG's "write descriptions that help people understand what a chart does".
- **Don't hide critical information behind interaction:** "Let people interact with the data when it makes sense, but don't require interaction to reveal critical information" (HIG). So no tap-to-reveal values on the bars.
- **"Help people notice important changes":** animate a change, but also announce it for people using TalkBack or with animations off (HIG).

### The design decision: which line does each bar measure against?
Mockup 21 drew one dashed line at *today's* share. **Recommended: each bar gets its own share tick instead.**
- **Each day's share is different** (BR-3, BR-4): spending less makes the next day's share grow. A single line at today's ₹1,850 would show Tuesday as over even if Tuesday's own share was ₹2,400. That breaks Rams' honesty principle (UI_DESIGN §1).
- **It's cheap.** `GetCycleSummary._yesterday` already rebuilds a past day "as it stood": it uses entries dated up to that day, and adds the bills posted after it back into `B`. Generalising it from yesterday to any day `d` from Monday to today gives each bar's `A_d`.
- **The tick reuses an existing piece of the visual language.** Where it went's bars already show a limit tick with hatching past it (BR-12). A share tick on each weekday bar is the same idea, turned vertical: one rule, learned once.
- The line uses the ledger as it is now. A back-dated entry changes that day's bar, as it already changes `A` (BR-4).

### UX
- **Tapping the hero** toggles *Today* ↔ *This week*, as built (FR-HO-2). In *This week*:
  - **The number** stays "Safe to spend this week", as built.
  - **The Day Blocks are replaced by seven bars, Mon–Sun,** in the same 226dp row and 40dp height. **The hero's height doesn't change**, so the *Today* list below never moves (principle 5).
  - **The caption row** ("Today · 9 days to payday") becomes the day letters M T W T F S S, with today's in Semibold. The payday flag column stays.
  - **The range-line slot** says the week in one sentence:
    - "Spent ₹4,950 this week · Tue was ₹460 over its share";
    - with nothing over: "Spent ₹4,950 this week · every day within its share".

    The sentence is the key, so the hero needs no legend.
- **Each bar:**

  | Day | Bar |
  |---|---|
  | Past day, with spending | `ink2` fill to its spend; a 2dp `displayInk` share tick at its `A_d`, with a `display` notch; anything above the tick hatched in `ink2` |
  | Past day, ₹0 spent | A 2dp `ink2` line at the baseline: "logged nothing" |
  | Today | `signal` fill to today's spend, with the 1.5dp `displayEdge` in light, plus today's tick at `A` |
  | Future day in this cycle | A 6dp `blockIdle` stub |
  | Before the cycle start, or from payday on | No bar. The payday day shows the flag glyph under its letter |

- **Scale:** the tallest of any bar or tick fills 40dp, with zero at the bottom.
- **The tap target** is the whole hero, as built. There is no per-bar interaction.

### Room for the bars (owner's question, 4 Nov 2026)
The owner noted that 40dp bars look cramped and proposed a 4:5 hero. [Mockup 21](../../design/mockups/21-unfold-takeaways.html) §R6b compares four layouts on a whole 360 × 780 phone, with Home's *Today* list and the dock. These are live measurements from the mockup at 1× text; the hero is taller than case study 10's 261dp because the week sentence wraps.

| Option | Hero, *Today* mode | Hero, *This week* | Bars | Room left for the *Today* list above the dock (Today / Week) |
|---|---|---|---|---|
| As planned | 307dp | 307dp | 40dp | 301 / 301dp |
| W1 · 4:5 card | 400dp | 400dp | 120dp | **208 / 208dp** |
| **W2 · grow in *This week* only** | 307dp | 355dp | 88dp | 301 / 253dp |
| W3 · taller row in both modes | 331dp | 331dp | 64dp | 277 / 277dp |

**Recommended: W2.**
- **Today mode, the one people see every day, costs nothing.** The bars get 88dp only after the user asks for the week.
- **W1 takes 93dp from the *Today* list every day,** and leaves Today mode with empty space above the range line. This is case study 10's objection, "the extra height is empty", now measured. A fixed ratio also overflows at 1.5× text, and is either huge or capped on wide windows (case study 10).
- **W2's list moves on a tap,** which "Nothing moves unless you move it" (principle 5) allows, because the user moved it. The hero's height animates on the `standard` spring; with reduced motion the list jumps once, after a 150ms crossfade.
- **W3 also makes the Day Blocks 64dp,** which changes BR-6's geometry (the 4dp spend band, D91). That's a larger change for 24dp of room.

If W2 is chosen, the "the hero's height doesn't change" line above becomes "the hero grows by 48dp in *This week* only", and principle 54 gains that exception.

### Components
| Part | Change |
|---|---|
| `GetCycleSummary` (`lib/ledger/domain/usecase/get_cycle_summary.dart`) | Generalise `_yesterday` to `_asItStood(day)`. Add `weekDays: List<WeekDay>` to the summary, built from Monday (or the cycle start) to today |
| `WeekDay` (new entity, `lib/ledger/domain/entities/`) | `date`, `spent`, `share`, `kind` (past, today, future, outside). Equatable, `Money` only |
| `WeekBars` (new, `lib/core/widgets/week_bars/`, next to `day_blocks/`) | A `CustomPainter` plus layout, with the same geometry constants as `DayBlocksLayout` so the two swap in place |
| `HeroCard` / `HeroCopy` | In week mode, `WeekBars` and the letters row replace `DayBlocks` and the captions; `HeroCopy.week` supplies the week sentence and the spoken text |

### Colour and type (all existing tokens; measured in UI_DESIGN §3.2)
| Element | Light | Dark | Rule |
|---|---|---|---|
| Past bar `ink2` (light uses `displayInk2`) on `display` | 6.17:1 | 6.42:1 | nonText 3:1 ✓ |
| Hatch `ink2` on `display` | same | same | ✓ |
| Share tick `displayInk` on `display` | 17.97:1 | 14.54:1 | ✓ |
| Today `signal` with `displayEdge` | edge 17.97:1 | `signal` on `display` 8.99:1 | ✓ (marigold never bare in light) |
| Future stub `blockIdle` on `display` | 1.53:1 | 1.53:1 | `idleBlock` 1.5:1 ✓. Decorative, so the letters carry it |

**One risk to test:** in Day Blocks, marigold fills with what is *left*; in the bars, marigold fills with what is *spent*. Both obey "marigold means today", but a person may read the fill as the same quantity. Put this in case study 12's blind read: "What does the marigold bar show?"

### Motion (choreography; all tokens exist)
"Fly, don't teleport" (principle 6): today's unit travels to its weekday.

| t (ms) | Today → This week |
|---|---|
| 0 | The number rolls (`numberRoll`, 300ms, as built) |
| 0–100 | The other Day Blocks fade out (`easeOut`) |
| 0–350 | Today's block moves and resizes into today's bar column (`standard` spring, no overshoot) |
| 60–400 | The other bars grow from the baseline, staggered 25ms by distance from today (`standard`) |
| 100–250 | The letters crossfade in place of the captions |

- The reverse runs in mirror. The whole change settles within about 450ms, and a second tap mid-flight reverses from the current values (springs carry velocity).
- **Reduced motion:** one 150ms crossfade of the bar row, the captions and the range slot (`reducedCrossfade`), as every other change does.
- **TalkBack:** the hero is one node (FR-HO-7). After the toggle, `SemanticsService.announce` reads the new label, as the HIG asks: changes must reach people with animations off.

### Haptics
- None added. The hero toggle has none today (`hero_press.dart` only scales), and adding one only in week mode would be inconsistent.

### Copy (draft)
| Key | English |
|---|---|
| `weekSpent` | `Spent {amount} this week` |
| `weekDayOver` | `{day} was {amount} over its share` (`day` is a short weekday name, "Tue") |
| `weekAllWithin` | `every day within its share` |
| `weekSpoken` | One sentence per day with full day names and real values: "Monday, 1,240 rupees. Tuesday, 2,310 rupees, 460 rupees over its share. Wednesday, 980 rupees. Today, 420 rupees so far." Full names follow the HIG's "avoid ambiguous formats and abbreviations" |

- When several days are over, the sentence names the most-over day and adds "and 1 more" (plural). Leave the exact form to `design-content`.

### Edge cases
- Today is Monday: one marigold bar and six stubs.
- The cycle starts on a Wednesday: Mon and Tue show letters with no bar.
- Payday falls on Friday: the flag sits under F, and Fri–Sun have no bars.
- A past day over for the cycle (`A_d = 0`): its tick is at the baseline, so the whole bar is hatched.
- Every past day is ₹0: three baseline lines and today's bar. The scale uses the tallest *tick*, so it never divides by zero.
- D = 1 (payday is tomorrow): this follows the payday rule above.
- A 9-digit amount: the bars are unaffected, and the sentence wraps.
- 1.5× text: the letters row is single characters, and the sentence wraps to two lines. The hero grows only by that wrap, as the range line already does today.

### Adaptive layout
- The bars take the Day Blocks' width wherever the hero is, so they inherit its widths at the `TestWindows` sizes. Add week-mode goldens at each size.

### Spec and docs
- **FR-HO-2:** "The Day Blocks, their captions and the range line stay on today" becomes the week bars, letters and week sentence.
- **New BR-6a, *Week bars*,** with a worked example (below) and the rule "`A_d` as it stood, with the ledger as it is now".
- **UI_DESIGN §5.2:** week mode. **§6:** the choreography above. **DECISIONS:** one row. It also closes the past-days question for mockups 19 and 20 or ranks against them.

### Worked example (for BR-6a)
The week of Mon 26 Oct; today is Thu 29 Oct.
- Spent: Mon ₹1,240, Tue ₹2,310, Wed ₹980, Thu ₹420 so far.
- Each `A_d` comes from `_asItStood`. Using illustrative shares, Tue's `A_d = 1,850`, so its over part is ₹460 and is hatched.
- The sentence: "Spent ₹4,950 this week · Tue was ₹460 over its share".
- Pin "today" with `FakeClock`, and derive the real shares from SPEC's BR-4 inputs.

### Tests (test-first)
- `_asItStood`:
  - yesterday matches the existing `_yesterday` (regression);
  - a bill posted on Wednesday counts in Monday's `B`;
  - income dated Wednesday is absent from Monday;
  - a back-dated entry changes only the days from its date on.
- `weekDays`: a Monday start, a mid-week cycle start, payday mid-week, the year-crossing week of 28 Dec–3 Jan, and a leap day.
- The painter: the tick position, the hatch only above the tick, a ₹0 past day, and the scale when every value is ₹0.
- Widget tests:
  - hero height is equal in both modes at every `TestWindows` size;
  - the TalkBack sentence;
  - reduced motion uses the crossfade only.
- Copy: one day over, two days over, none over.

**Cost:** medium. A domain change, one painter, hero wiring and the motion.

---

## 3. Hide figures from recent apps (R4), plus an optional eye button (R4b)

### Research
- **`setRecentsScreenshotEnabled(false)`** (API 33, Android 13) tells the system not to capture the activity for the recents view. Unlike `FLAG_SECURE`, "user-triggered full-screen capture" still works ([.NET binding of the Android reference](https://learn.microsoft.com/dotnet/api/android.app.activity.setrecentsscreenshotenabled); [XDA](https://www.xda-developers.com/android-13-developers-disable-app-previews/)). High confidence on the behaviour; the API level is from the binding's `ApiSince=33`.
- **`FLAG_SECURE`** blacks out screenshots and recordings, as well as the task switcher ([OWASP MASTG-BEST-0014](https://mas.owasp.org/MASTG/best-practices/MASTG-BEST-0014/)). People share screenshots of their spending, so blocking them costs more than it protects.
- **Toggling `FLAG_SECURE` in `onPause`/`onResume` is unreliable.** Reports conflict by device and version (Android 6–10, Pixel versus Samsung and Huawei), because the thumbnail may be captured before `onPause` runs ([proandroiddev](https://proandroiddev.com/protect-your-android-app-content-and-embrace-its-security-1adeb5437c6); [Stack Overflow mirror](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/a/49442984)). Low confidence either way. Don't build on it.
- **Balance hiding is an established money-app pattern:** an eye toggle, as in [QIB's discreet mode](https://www.qib.com.qa/en/about-us/media-center/news/news-listing/2022/02/10/qib-launches-discreet-mode-first-of-its-kind-feature-in-qatar-on-its-mobile-app), [Neo's privacy mode](https://support.neofinancial.com/hc/en-ca/articles/31720635648013-Privacy-mode-for-your-account-balances) and [Trading 212's privacy mode](https://community.trading212.com/t/introducing-privacy-mode/91187).
  - Trading 212's users complained when the state **wasn't remembered** after the app was closed.
  - A [Zenith Bank UX review](https://medium.com/usabilitygeek/hide-my-account-balance-please-a-zenith-bank-mobile-app-ux-review-c7d338438f8) argues for hidden by default.
  - Medium confidence: the pattern is clearly common, but none of these sources tested it with users.

### R4 plan (recommended, no UI)
- In `MainActivity.kt`, call `setRecentsScreenshotEnabled(false)` in `onCreate` when `Build.VERSION.SDK_INT >= 33`. It needs no platform channel and no Dart.
- **API 24–32:** no change in v1. `FLAG_SECURE` would block screenshots, and the pause toggle is unreliable. Revisit if users ask.
- **What recents shows:** the system draws its own placeholder; we can't draw the wordmark card from mockup 21. **Correct the mockup** to say "system placeholder".
- **Spec:** a new NFR row ("The recent-apps preview never shows amounts on Android 13+"). **DECISIONS:** one row. **Test:** a manual check on an API 33+ device or emulator, recorded in the PR, because a widget test can't reach the recents screen.

**Cost:** tiny.

### R4b plan (only if a 5-user blind read shows a need)
- **Control:** an eye well in Home's header, before Settings, with the same 40dp well in a 48dp target (§3.5).
  - It uses Hugeicons' `ViewIcon` / `ViewOffIcon` through `AppIcon`, with the label "Hide amounts" / "Show amounts".
  - It only appears on Home, the place people are looked over.
- **State:** it **persists** across launches (the Trading 212 lesson) in `AppPreferencesRepository` (`lib/settings/domain/repository/`). Settings gets no second switch (PLAN §2): the eye is the setting.
- **Scope:** every amount shown through `AmountText` reads a `HideAmounts` inherited value and shows `₹•••`.
  - The keypad's entry amount stays visible, because you're typing it.
  - The Ask AI preview stays visible, because you must see what you share.
  - Day Blocks stay: they show proportion, not rupees.
  - The range line's amount is hidden too.
- **Motion:** the digits crossfade to dots in 150ms, through `AmountText`'s existing `AnimatedSwitcher`, and back. No roll.
- **Haptics:** `Haptics.tick` (a toggle, as for chips).
- **TalkBack:** a hidden amount reads "amount hidden". The well is a toggle button with its state.
- **Colour:** no new token. The dots are `displayInk`.
- **Risk:** it adds a control to Home, against "less, but better", so a blind read must show that people want it.

---

## 4. Search in *Every entry* (R7): removed (D113)

### Research
- **Show a type-in field, not a link,** and make it "wide enough to contain the typical query" ([Nielsen, *Search: Visible and Simple*, 2001](https://www.nngroup.com/articles/search-visible-and-simple/)). The article is old, so medium confidence, but its rules have held.
- **Placeholders are forgotten once you type.** NN/g's form research says placeholder text makes it hard to remember what belongs in a field (via [uxdesign.cc](https://uxdesign.cc/best-ux-practices-for-search-inputs-c44dba565448); not read first-hand). For a single, self-evident search field, a magnifier icon plus a placeholder is acceptable. The TalkBack label must still carry the full meaning.

### UX
- **Placement:** a field at the top of *Every entry*, pinned under the top bar (D84), so results stay in view as the list scrolls. The category chips follow it.
- **Matching:**
  - the search and the chip filter combine (AND);
  - case- and accent-insensitive substring matching on the note and the category label;
  - **digits match amounts**: "299" finds the phone recharge.
  - Hinglish transliteration is out of scope.
- **Results** update as you type. The data is already in memory (`EntriesReady.entries`), so there is no debounce. Day headers show the total of the matches only.
- **A match is shown in Semibold** (`HisaabType.emphasized`), with no underline, which would read as a link, and no colour.
- **Clear:** an × appears once there is text, in a 48dp target. System back first closes the keyboard (the system does this), then leaves the screen. The query isn't intercepted.
- **Empty result:** "No “swiggy” in October." This names the cycle being searched, because search stays in the current cycle (assumption).
- **Privacy:** the query is never logged (NFR-3: "Logs never contain notes").

### Components
| Part | Change |
|---|---|
| `EntriesBloc` | A new `EntriesQueryChanged` event with `restartable()` (bloc rules); `EntriesReady.query`; `shown` applies the chip filter, then the query |
| Matcher (new, `lib/spends/domain/`) | A pure function, `matches(Entry, label, query)`. Normalises case and accents, and strips `₹` and `,` from digit queries |
| `EntriesPage` | The pinned field. Reuses the field style from D100: a `control` fill on the page, an `ink` edge when focused |
| `EntriesDay` | Takes the highlighted spans |

### Colour and type
- Field: `control` (light `surface`, 1.17:1 on `bg`; dark `hairline`, 1.56:1). The focused edge is `ink`, 17.97:1 in light and 10.59:1 in dark.
- Placeholder: `ink2` on `control`, 7.20:1 in light and 4.68:1 in dark.
- Text: `bodyLarge`. The magnifier is `ink2`, from Hugeicons `Search01Icon`.

### Motion and haptics
- Filtering is instant; the list doesn't animate rows in and out while you type, which would jitter on every key. With reduced motion off, the empty state fades in over 150ms.
- No haptics.

### Copy (draft)
| Key | English |
|---|---|
| `searchEntries` | `Search notes or amounts` (placeholder) |
| `searchEntriesSpoken` | `Search notes, categories or amounts` (TalkBack label) |
| `searchNoMatch` | `No “{query}” in {cycle}.` |
| `searchCount` | `{count, plural, =1{1 entry} other{{count} entries}}` (announced only) |

### Accessibility
- After the results change, announce the count with `SemanticsService.announce`, with about 500ms of quiet after the last key, so that every keystroke doesn't speak.
- The × has the label "Clear search".
- At 1.5× text the field grows in height, and the pinned header grows with it.

### Spec and docs
- **FR-SP-6:** add search. **UI_DESIGN §5.4:** the field. **DECISIONS:** one row.

### Tests (test-first)
- Matcher:
  - case and accents ("Ravi's" matches "ravis");
  - digits against an amount, including "₹2,310" against "2310";
  - category label;
  - a note with no match;
  - an empty query matches everything.
- Bloc: the query and the filter combine; switching cycles keeps the query.
- Widget: Semibold spans; the empty state names the cycle; × clears; TalkBack announces the count once.

**Cost:** small to medium. Value is lower while notes are optional (case study 14), so build it last.

---

## 5. Play Store screenshots

### Research: Google's own rules ([Play Console Help, preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en); high confidence)
- **Format:** JPEG or 24-bit PNG with no alpha. Sides from 320 to 3840px, with the long side at most twice the short one.
- **Count:** up to 8. **To be eligible for recommendations, at least 4 at 1080 × 1920 or more** (portrait).
- **Text:** "Taglines should not take up more than 20% of the image". Avoid "overloading the screenshot with text in small font sizes". "Prioritize UI in the first three screenshots".
- **Avoid:**
  - **device imagery** ("can become obsolete quickly or alienate some users");
  - fingers on screens;
  - "Best", "#1", "Top", "New" and "Free";
  - calls to action such as "download now";
  - notification-bar clutter (show full battery and signal, with no notifications).
- **Alt text:** up to 140 characters, not starting with "image of".
- **Feature graphic:** 1024 × 500, with the focal point centred. Avoid "pure white, black, or dark gray" backgrounds, and don't repeat the icon.

### Plan
- **Correct mockup 21:** remove the device frames. Each screenshot is the real app, full-bleed at 1080 × 1920, with a tagline band at the top of at most 384px (20%).
- **Order:**
  1. Home hero.
  2. Add (keypad).
  3. Spends.
  4. Ask AI preview.
  5. Privacy.
  6. Dark Home.

  The first three are UI-led. Dark is last (case study 14).
- **Taglines** (draft, for `design-content` and `design-brand`):
  - "Know what you can spend today."
  - "Add a spend in seconds." "Four taps" isn't true for multi-digit amounts.
  - "See where it went."
  - "Ask any AI. See exactly what it gets."
  - "No sign-in. Your data stays on your phone." This must match the Data safety form.
  - "Easy on the eyes at night."
- **Type and colour:** Anek 600 for the tagline, in `ink` on `bg`. Marigold appears only where the app shows it. The tagline band is `bg`, not a colour wash (case study 14 rejects pastel washes).
- **Production:** an `integration_test` with the worked example and `FakeClock` captures the six screens at 1080 × 1920 with a clean status bar (Android demo mode). An HTML template adds the tagline, and headless Chrome renders the PNGs, as the mockups are checked today. Write alt text for each one.
- **Feature graphic:** hand it to `design-brand`. Play asks for "vibrant" and not white, black or dark grey, so a marigold field with ink type (9.90:1) is one option. That would be marigold as decoration, so it's an explicit brand exception to decide, not a default.
- **Wordmark risk** (case study 14): `design-brand` should resolve it before these are made.

---

## Build order
1. **R4.** Tiny, no UI, a privacy win. → Verify on an API 33+ emulator: the recents card shows no amounts, and a screenshot still works.
2. **R1 + R2.** Small, and closes an accessibility gap. → Verify with the row and key tests, `flutter analyze`, and changed-line coverage of at least 90%.
3. **R6.** After the blind read places it against mockups 19 and 20. → Verify with the `_asItStood` tests, equal hero height at every `TestWindows` size, and the motion checked on a device.
4. **Store screenshots.** After the wordmark decision. → Verify against Play's rules: 4 or more at 1080 × 1920, taglines within 20%, alt text.
5. **R7.** When notes usage justifies it. → Verify with the matcher, bloc and widget tests.
6. **R4b.** Only if the blind read asks for it.

## Corrections this plan makes to mockup 21
- R6: a share tick per bar instead of one dashed line, the hero height kept, and a week sentence instead of the key. **Updated.**
- R4: the recents card shows the system placeholder, not a wordmark. **Updated** (labelled).
- R7: matches in Semibold, not underlined. **Updated.**
- Store: no device frames. **Updated.**

## Open questions
1. R6 blind read: "What does the marigold bar show?" (spent, against the blocks' left).
2. R6 against mockups 19 and 20: which one answers "how did my past days go?" best? Include all three in one session.
3. R4b: do people want to hide amounts on Home, or does R4 cover the worry?
