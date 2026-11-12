# 32. "Your usual": suggesting the right spend at the right time

> **Outcome (2026-11-13): approved as D153.** The pill, the one-tap add with Undo, and *Your usual* with *Forget* are in SPEC (BR-17, FR-AD-10, FR-SE-2 AC-6, E58–E65). Step 1 uses layout B: 20dp above the amount, 4dp to the 48dp slot, 8dp to the chips, so the keypad moves 8dp. CLAUDE.md's entry-speed rule names the pill as a second exception. Phases 2 and 3 stay proposed. Not built yet.

## Job
When someone opens Add at the time they usually log the same spend (chai ₹20 most weekdays around 10 am), offer that spend as **one tap** so they don't have to type it. The rules: no new tap on the normal path (Add → digits → Next → tile), nothing moves (D13), no network, no settings, no nagging, and never a nudge toward spending more.

The owner asked for this on 2026-10-26 ("I go to breakfast every day between 9 and 10:30 … the app can show the amount I usually use") and again on 2026-11-13 ("the user is buying tea every day at 10 o'clock … the app should recommend that to him").

## Where hisaab stands
- **A full design already exists, not built:** `docs/features/habits/` (2026-10-26). It has three helpers: the *your usual* pill on Add step 1, a missed-log question on Home, and a bill finder on Spends. Detection is pure Dart over one grouped SQL read, with two FSMs. Its status is **Proposed**, and SPEC, UI_DESIGN and DECISIONS don't mention it yet.
- **Its prerequisite is done.** `LedgerRepositoryImpl.replace` and `restore` now keep the original `created_at` (`lib/ledger/data/repository/ledger_repository_impl.dart:51`, `:66`), so editing or undoing no longer moves an entry's time of day.
- **Changes since the design was written:**
  - **D138 (your own categories):** a user can now make *Chai* or *Cigarettes* a real category, with a chai glyph in `HisaabGlyphs`. That covers what `05-tracked-items.md` was for, and the same third grid row is now taken.
  - **D147 (widget, Quick Settings tile, app shortcut):** two new ways into the Add tray. Both open at the keypad, the exact place the pill would sit.
  - **D145:** the light page colour has changed; the mockups use the new values.
- **Add step 1 today** (`lib/add_entry/presentation/widgets/amount_step.dart`):
  - From the top: Spent/Got, the amount, then `SpendPreviewLine`, a single text line that keeps its height when empty.
  - Below that: a 24dp gap, the quick chips (+₹10 … +₹500), the keypad and *Next*.
  - At ₹0 the preview line is empty. That empty line is the pill's slot.

## Method
Desk research: shipped products that predict an action from time or context, the HCI literature on adaptive interfaces, ranking algorithms, and work on anchoring and "creepy" personalisation. Desk research is the cheapest method that can confirm or overturn the thresholds already in `03-detection-maths.md`. What it can't tell us is whether *hisaab's* users find a one-tap add helpful or unsettling. That needs the test round under *Open questions*.

**Limits of this pass.** Most sources were read through search summaries, not full pages. Nothing confirmed how Swiggy, Zomato, GPay, PhonePe, Walnut/axio, Fold, Copilot or Cleo suggest repeat actions, so they are left out rather than guessed. No app was installed and no screens were recorded.

## Research by source

### Products that predict an action from time and context
- **iOS Siri Suggestions and Shortcuts.** Apps "donate" actions as the user performs them. Suggestions come from time of day, day of week, location and motion, and they are computed **on the device**. They appear in Spotlight, the Lock Screen and Siri suggestions ([WWDC20 session 10084](https://developer.apple.com/wwdc20/10084); [VentureBeat on iOS 12](https://venturebeat.com/2018/09/17/10-ways-siri-is-smarter-in-ios-12)). How many show at once wasn't confirmed.
- **Android app predictions.** The AOSP fallback service fills the launcher's top row with the 5 most recently used apps ([AOSP `PredictionService`](https://android.googlesource.com/platform/packages/apps/OnDeviceAppPrediction/+/refs/heads/master/src/com/android/apppredictionservice/PredictionService.java)). The Pixel launcher also suggests apps in the hotseat ([XDA](https://www.xda-developers.com/pixel-launcher-android-11-hints-showing-suggested-apps-home-screen-dock/)). Google's own model and count weren't confirmed.
- **Google Maps suggested destinations.** It learns from home, work and the commute ([Android Police](https://www.androidpolice.com/google-maps-create-commute/)). Users complain about **random wrong places** among the suggestions ([autoevolution](https://www.autoevolution.com/news/google-quietly-releases-a-highly-anticipated-google-maps-update-on-android-auto-259708.html)), which shows what a low bar for showing a guess costs.
- **Firefox address bar ("frecency").** Visits are weighted by recency with an exponential decay and a **30-day half-life**. The legacy version used buckets (4, 14, 31, 90 days) and a daily decay of 0.975, about a 28-day half-life ([Firefox ranking](https://firefox-source-docs.mozilla.org/browser/urlbar/ranking.html); [legacy](https://firefox-source-docs.mozilla.org/browser/urlbar/ranking-legacy.html)).
- **Expense trackers (Spendee, Wallet, Money Manager).** They offer widgets, planned payments and general insights, but **no time-of-day "usual" suggestion** was found ([Spendee on Play](https://play.google.com/store/apps/details?id=com.cleevio.spendee&hl=en); [BudgetBakers Wallet](https://budgetbakers.com/en/products/wallet/)). Case study 31's survey of popular Play Store trackers found none either. **If built, hisaab would be early here.** That cuts both ways: the position is open, and there is no precedent to copy.

### Adaptive interfaces (HCI)
- **Accuracy matters more than predictability.** Gajos et al. compared an adaptive split toolbar at **50% and 70%** accuracy. Higher accuracy improved satisfaction, speed and use more than higher predictability did ([CHI 2008](http://aiweb.cs.washington.edu/ai/puirg/papers/kgajos-chi08-predictability.pdf)).
- **Copy, don't move.** Split *interfaces* (which copy a likely item into a fixed spot) beat split *menus* (which move it) ([Gajos dissertation](http://aiweb.cs.washington.edu/ai/puirg/papers/kgajos-dissertation.pdf)).
- **The benefit appears near 79%.** Findlater et al. found ephemeral adaptation beat a static menu at **79%** accuracy. At **50%** it was no slower and degraded more gracefully than a split menu ([CHI 2009](https://www.cs.ubc.ca/labs/edapt/papers/findlater2009.pdf)). A 2010 follow-up used 78% and 50% ([Findlater 2010](https://www.cs.ubc.ca/labs/edapt/papers/findlater2010.pdf)).
- **No published break-even.** The evidence brackets it: around 50% is neutral, and 70–79% is a clear benefit. These studies measured menu selection, not a one-tap *add*, where a wrong accept costs an Undo.

### Anchoring and creepiness
- **Suggested amounts move behaviour.** Higher default tip options in New York taxis raised tips, and also raised the share of riders leaving nothing by 1.7 percentage points ([Haggag & Paci](http://www.kareemhaggag.com/f/Default_Tips.pdf)). A suggestion that looks bigger than what you did is a nudge, and some people push back against it. A weaker source on default reactance: [Harvard thesis](https://dash.harvard.edu/server/api/core/bitstreams/4c440e41-076c-4698-939b-9ddd45f470cc/content).
- **Accurate but unexplained personalisation feels creepy.** It lowers trust and adoption ([Petrova 2026](https://onlinelibrary.wiley.com/doi/10.1002/mar.70089)). The EFF argues that being shown the inputs helps but may not be enough ([EFF](https://www.eff.org/deeplinks/2018/04/were-uncanny-valley-targeted-advertising?language=en&page=1)).

### Detection maths
- **The circular kernel used for time-of-day data is von Mises** ([MetricGate](https://metricgate.com/docs/circular-kernel-density/); [CRAN `circular`](https://cran.r-project.org/web/packages/circular/circular.pdf)). The current design's 48 half-hour buckets with wrap-around and `[¼, ½, ¼]` smoothing are a discretised version of the same idea. No mobile-prediction source was found that needs the continuous form.

## Patterns compared

| Product | Signal | How many shown | Where | Dismiss |
|---|---|---|---|---|
| iOS Siri Suggestions | Time, weekday, place, motion; on-device | Not confirmed | Spotlight, Lock Screen | Reset in Settings (third-party source) |
| Android app predictions | Time, place, app sequence | 5 (AOSP fallback) | Launcher top row, hotseat | Not found |
| Google Maps destinations | Home, work, commute | A few, home and work first | Search box, Android Auto | Not found |
| Firefox URL bar | Frequency × recency (30-day half-life) | Ranked list | Address bar | Remove from history |
| Spendee, Wallet, Money Manager | None by time | — | — | — |
| **hisaab (proposed)** | Time slot × weekday/weekend × category × amount; on-device | **1** | Add step 1, in the empty preview line | Ignore it; Undo; quiet for the day |

## Testing the existing design against the evidence

| Parameter in `03-detection-maths.md` / `04-ux-and-copy.md` | Evidence | Verdict |
|---|---|---|
| One exact amount covers ≥ 70% of hits | 70–79% is where adaptive UIs start to help (Gajos 2008, Findlater 2009) | **Keep** |
| Show one suggestion, not 2–3 | Several pills add choice and break "one voice per screen". The AOSP 5 is an app grid, not a money entry | **Keep** |
| Copy into a fixed slot; tiles never move | Split interfaces beat split menus (Gajos); spatial memory (case study 22) | **Keep** |
| 14-day half-life | Firefox uses 30 days for browsing. Spending follows weekly and monthly rhythms and moves faster | **Keep**; test it against a full pay cycle |
| 48 half-hour circular buckets, `[¼, ½, ¼]` | A discretised circular kernel; von Mises adds maths, not much accuracy | **Keep** |
| Weekday and weekend learned separately | Day of week is a standard signal (WWDC20). But splitting halves the data, so a real habit may never reach 5 hits | **Change:** fall back to the pooled profile when one side lacks hits but still clears 70% |
| Silent until 14 days and 10 active days; ≥ 5 hits | No published number. Wrong early guesses cost trust (Petrova; Maps complaints) | **Keep** |
| The amount is the weighted mode | Suggested amounts anchor behaviour (Haggag & Paci) | **Keep, and pin it with a test:** the pill shows exactly an amount the user logged, never rounded or averaged |
| "your usual", never "we noticed" | Avoids framing the app as watching. Accuracy alone can still feel watched (EFF) | **Keep**, and **add** a place to see and forget what was learned (below) |
| 2 × "Not today" in 14 days rests it for 30 days | No source on dismissal timing. Control lowers creepiness | **Keep** |
| Undo 4 s after a one-tap add | No source found | **Test** (mis-tap task, 5 users) |
| Tracked items (`05-tracked-items.md`) | Overtaken by D138: *Chai* is now a real category | **Retire** |

## Recommendation

**Build the *your usual* pill first, on its own, and keep the existing design with five changes.** The other two helpers ship later as separate slices, because each detector is independent by design.

1. **Pooled fallback.** If the weekday or weekend profile is short of 5 hits but the pooled profile meets every bar, use the pooled one.
2. **Let people see and forget a learned usual,** without a new screen or a setting. The category sheet in Settings › Categories (D138) gains one line, "Your usual: ₹20, weekdays around 10 am", with *Forget*. Forget clears that habit's history and rests it for 30 days. A usual only shows there once it is Regular. This is the one place the app admits it noticed something, and it sits where the user goes to manage that category.
3. **Retire tracked items.** Habit keys become `(category_id, dayType)`, and the `tracked_items` table and column are dropped from the plan.
4. **Every way into Add gets the pill:** the dock, the app shortcut and the Quick Settings tile (D147). Opening Add from the widget is the moment someone is most likely logging a routine spend. The widget itself never shows the pill (below).
5. **Pin the amount with a test.** The pill's amount equals one the user actually logged in the window. Never round it, average it or raise it.

### Where it lives, screen by screen (mockup 40)

| Screen | What appears | When | Phase |
|---|---|---|---|
| **Add, step 1** | A hairline pill "Chai ₹20 · your usual" in the empty preview line, 48dp tall | New *Spent* entry, ₹0, before any input, the date is today, and now is inside a Regular habit's window | 1 |
| **Home** | Nothing new. The pill's one-tap add uses the usual close: tray drops, block drains, number rolls, then a snackbar "Added ₹20 to Chai" with Undo | After a pill tap | 1 |
| **Settings › Categories › a category** | "Your usual: ₹20, weekdays around 10 am" with *Forget* | The habit is Regular | 1 |
| **Home note line** | "Spent on Chai today? Usually around 10 am." with × | ≥ 90 min after the window, not logged, no higher note | 2 |
| **Spends insights** | "Gym ₹1,500 every month, around day 5" with *Make it a fixed bill* | ≥ 3 cycles, same note and amount | 3 |

### Considered and not proposed

| Idea | Why not |
|---|---|
| Two or three pills at once | Choice load. "One voice per screen". No evidence it helps |
| Outline the likely tile on step 2 | Saves no tap, reads as "already selected", anchors a wrong pick (habits ideation log) |
| A *Chai ₹20* button on the widget or QS tile that logs without opening the app | Logs money with no confirming look. Shows a habit on the home screen, where tracked names are kept off (habits 05, Privacy). A pocket tap would post money |
| Prefill the amount instead of a pill | The user would have to clear it to type something else. That adds a tap and a correction to the normal path |
| A notification at 10 am | Out of bounds: the feature sends no push (habits 06). Nagging is a listed dark pattern under India's CCPA 2023 guidelines |
| Let the pill learn from location | Needs a permission and a sensor, and breaks "nothing leaves, nothing extra is read" |

## Conflicts (for `design-product`; `DECISIONS.md` wins until changed)
- **SPEC FR-AD-1 / FR-AD-3:** the preview line becomes a fixed 48dp slot for everyone, about 28dp taller than today. The keypad moves down once, permanently. Check the `TestWindows` compact heights at 1.5× text.
- **BR-10:** normal saves have no Undo. The one-tap add gets one, because it skips the steps that would have caught a mistake.
- **CLAUDE.md, "Entry speed":** the pill adds a control to step 1. It adds no tap to the normal path and moves nothing, but it needs the owner's yes.
- **`04-ux-and-copy.md` voice rule 6** ("no name for the feature in the UI"): the *Your usual* line in the category sheet is a small exception. It names a fact about the category, not a feature.
- **`05-tracked-items.md`** is superseded by D138 and should be marked so.

## Principles (proposed for `principles.md`; not appended until approved)
- **A guess earns a place on screen only above about 70% accuracy, and only one guess at a time.** Below that it costs more glances than it saves. *Sources:* Gajos et al. 2008; Findlater et al. 2009. *Applies to:* the pill, any future suggestion.
- **Suggest only what the person did; never a number they didn't.** A suggested amount anchors behaviour, so it repeats an observed amount exactly. *Sources:* Haggag & Paci; principle 48. *Applies to:* the pill, quick chips, limits.
- **What the app has learned about you is visible where you manage the thing it learned about, and can be forgotten in one tap.** *Sources:* Petrova 2026; EFF. *Applies to:* habits, any inferred state.

## Open questions
1. **Is it helpful or creepy?** Show five UPI-first users the pill at their own time (a prototype seeded with a week of their own spends) and ask what they think it does and why it's there. Listen for "watching" words.
2. **The cost of a wrong accept.** In a mis-tap task, measure whether 4 s of Undo is enough, and whether people notice the snackbar at all.
3. **Does 70% hold for a one-tap *add*?** The literature measured menus. Replay real logs (with the owner's consent, on the device) to count how often the pill would have been right.
4. **Two habits in the same window** (chai and a cigarette at 10 am). Top-1 picks the higher daily probability. Do people then miss the second? Watch for it in a diary.
5. **The 48dp slot on short windows:** below a tabletop fold, step 1 is side by side (`sideBySide`). Where does the pill go there? Ask design-platform.
6. **Not read:** how Swiggy, Zomato, GPay and PhonePe handle reorder and frequent payees, and any Indian expense app with a time-of-day suggestion.
