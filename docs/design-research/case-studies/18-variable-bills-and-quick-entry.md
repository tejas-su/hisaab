# 18. Bills that change every month, and entering them fast

## Job
The owner's words: "I have credit card bills which go out on a specific day; this applies to all other bill types too. It would be nice if I could enter the amount by tapping something, or getting a notification or whatever, so I can enter it quickly and track it too."

The job, then: **on the day a bill goes out, record what it really was, in as few taps as possible, while today's safe-to-spend number stays honest before and after.** The user knows the day ahead of time. The amount is usually known only from a statement or an SMS, at or just before the due day.

## What's wrong today
- **Bills are fixed.** A bill is a monthly rule with one amount. The recurring engine posts it on its day (BR-9), and the bill wizard asks name, amount, day (FR-SE-1, D35). This fits rent, an EMI, Netflix or a SIP. It doesn't fit a credit card, electricity, piped gas, water or a postpaid phone, which are different every month.
- **The workaround is slow and silent.** On the due day the engine posts last month's amount. To fix it the user has to notice, open the app, find the entry in the Today list (or *See all* if it was a day or more ago), tap it, clear the amount, type the new one, tap *Next*, then tap the tile: 4 taps plus digits, and nothing prompts them. If they never fix it, `S` stays wrong for the cycle.
- **Nothing reaches the user outside the app.** Home's due-soon line (BR-9, FR-HO-3) shows only while the app is open, and only 1–5 days *before* the day. On the day itself the bill is "the engine's" and the line goes away. There are no notifications, widget, tile or shortcuts (SPEC §1.2; PLAN §11 lists `home_widget` and `quick_settings_tile` as "later").
- **A credit card can be counted twice.** If the user logs card purchases as they happen *and* adds the card as a bill, the same money leaves `P` twice. The app has no accounts (SPEC §1.2), so it can't tell a card payment from spending.
- **A bill on its day lands in today's spending.** BR-3 says "Bills due **today** are posted by the recurring engine, so they count as spent today, not in `B`." `GetCycleSummary` does exactly this: `spentToday` sums every *Spent* entry dated `t`, bills included (`lib/ledger/domain/usecase/get_cycle_summary.dart`, `_DayTotals.inputs`). The bill leaves `B`, so `A = P / D` rises by only `bill / D`, while `S_today` rises by the whole bill. On rent day the hero reads ₹0 with "over today". This bug exists already for fixed bills. Any new way of entering a bill on its day hits it too (see *Formula impact*).

## Research by source

### How apps model bills that vary
- **Simplifi (Quicken).** It doesn't average a varying bill. A staff answer says an average for varying recurring items "is not currently available", and users have asked for "the average of the last x months" ([Simplifi community #448](https://community.simplifimoney.com/discussion/448/have-varying-recurring-bills-use-average-of-last-six-months-for-the-amount-edited); read through the search summary, not opened). Quicken's own advice is to set the expected amount "high enough" so the spending plan holds enough back, and to turn on *match any amount*: "when the bill is paid, Simplifi will match it and adjust to the actual amount automatically" ([Quicken blog, Spending Plan hacks](https://www.quicken.com/blog/spending-plan-hacks/)). **Model: an estimate held back in the plan, replaced by the real amount when it arrives.** That replacement relies on bank sync, which we don't have.
- **YNAB.** A scheduled transaction isn't entered on its date. It "appears in bold" in the register and is approved either by a bank import or by hand. You can change one occurrence or all future ones, and enter one "now" ([YNAB, Scheduled transactions](https://support.ynab.com/en_us/scheduled-transactions-a-guide-BygrAIFA9.md)). The guide mentions no reminders. Users flag card payments and utilities "where I need to check the statement" ([r/ynab thread, via search](https://lr.in.psf.lt/r/ynab/comments/1e6bm5i/enhancement_request_automatically_schedule); a forum, low confidence). **Model: due, then waits to be approved.**
- **Actual Budget** (open source, local-first). A schedule's amount can be *is exactly*, *is approximately* (±7.5%) or *is between*. Each schedule either adds itself automatically or waits "to approve each entry manually", and its menu offers post, skip and complete ([Actual docs, Schedules](https://actualbudget.org/docs/schedules)). **The clearest public statement of the two-mode design**: automatic for fixed bills, approve-by-hand for the others.
- **Chronicle (bill organiser).** An *Amount Due Varies* switch resets the amount to "Not Set" after each payment, to remind the user to enter the next one. If nothing is entered, it "will use the average paid to guess how much you owe" ([Chronicle user manual PDF](https://chronicleapp.com/static/downloads/UserManual.pdf); read through the search summary, not opened). **Model: ask-on-due, with an average as a fallback estimate.**
- **Lunch Money.** Users ask to override the expected amount for "any given occurrence", for utilities ("I set an 'average' for my power bill") and card payments. There is no staff reply ([Lunch Money feedback](https://feedback.lunchmoney.app/recurring-items/p/ability-to-modify-the-expected-amount-for-an-individual-occurrence)). This is evidence of demand, not of a design.
- **Copilot Money.** A recurring item is created from an existing transaction and matched with filters such as "from $9 to $10 around the 23rd", which is an amount range ([Copilot help, Create recurrings](https://help.copilot.money/en/articles/3760068-create-recurrings)). A recurring item can't be excluded from the budget ([Copilot help, Excluded transactions](https://help.copilot.money/en/articles/9718801-excluded-transactions)). A roadmap commenter notes that card and utility payments "are variable" ([Copilot roadmap](https://roadmap.copilot.money/feature-requests/p/credit-card-due-dates-and-statements); via search).
- **Rocket Money.** A manual bill has one editable amount and due date ([Rocket Money help](https://help.rocketmoney.com/en/articles/2185531-managing-your-bills-and-subscriptions)). The help page says nothing on reminders, marking paid or varying amounts. A user request says some billers' amounts differ every month and "there isn't an easy way" to say so ([Rocket Money Canny](https://rocketmoney.canny.io/feature-requests/p/multiple-bills-from-same-biller-each-month); via search).
- **Goodbudget.** On Android a scheduled transaction "posts automatically every time". The web version can email a set number of days before, and a *+ Now* button posts early ([Goodbudget, How to schedule](https://goodbudget.com/help/customize-your-goodbudget/how-to-schedule/)). The page doesn't cover amounts that vary.
- **Wallet (BudgetBakers).** Its planned payments page lists "payment reminders" and converting payments into planned ones. It doesn't say how reminders are sent or how a varying amount is handled ([BudgetBakers, Planned payments](https://budgetbakers.com/planned-payments)). Not enough to cite a pattern.
- **Prism.** It fetched real bill amounts from more than 11,000 billers and shut down on 20 Feb 2024 ([Stacking Benjamins](https://www.stackingbenjamins.com/prism)). Fetching amounts needs a network and biller integrations, so it's off the table for us.
- **India.** PhonePe reminds users of upcoming bills based on bills and recharges paid in PhonePe, and lets them set manual reminders ([PhonePe help](https://cms.phonepe.com/en/myhelp/autopay-payment-reminders/payment-reminders/how-do-i-set-payment-reminder-phonepe/); the bill-notification page redirected to the help home and couldn't be read, so this is from the search summary). Paytm fetches the outstanding amount and due date after the user enters a consumer number ([Paytm support](https://paytm.com/support/bill-payment/setting-up-reminders-for-pending-bill-payments-on-paytm); via search). Users report that CRED reads card dues through BBPS bill fetch or statement emails ([r/CreditCardsIndia, via search](https://pol1.lr.ggtyler.dev/r/CreditCardsIndia/comments/1k2qyva/how_does_cred_get_access_to_statement_amount); anecdotal, and no official CRED page was found). axio (formerly Walnut) reads transactional SMS to find spends and bills ([listing mirror](https://appwisp.com/app/android/com.daamitt.walnut.app); via search). **All of these get the amount from a network or SMS.** hisaab reads neither (SPEC §1.2, privacy), so the user has to type it. Indian payment apps have made people used to *seeing* the amount, but never to *typing* it.
- **Not found:** Spendee, Bills Monitor and BillOut had no public material on varying amounts in this search. Monarch's help article on card payments returned **403**, so its claim below comes from the search summary.

### Credit cards: the double count
- **YNAB:** a card purchase is spending from its category at the time it's made. The money moves into the card's payment category, where it "sits" until the bill is paid, so paying the bill isn't new spending ([YNAB, Handling credit cards](https://support.ynab.com/en_us/handling-credit-cards-overview-ry7cNub1s.md)).
- **Monarch:** the card payment is a *transfer* in the *Credit Card Payment* category and doesn't count as spending; the purchases are the expenses. Interest is a real expense ([Monarch help](https://help.monarch.com/hc/en-us/articles/360048393292): 403 to the fetch tool, so this comes from the search summary).
- **Money Manager (Realbyte):** a card payment is recorded as a transfer, "From: Accounts To: Cards", and transfers between your own accounts are neither income nor expense ([Realbyte, Record a transfer](https://help.realbyteapps.com/hc/en-us/articles/360042842254-How-to-record-a-transfer); the card-settlement article returned 403; both are from the search summary).
- **Copilot:** a recurring item can't be excluded, so a card payment set up as recurring counts as spending unless it's moved to an excluded category ([Copilot help](https://help.copilot.money/en/articles/9718801-excluded-transactions)).
- **All four agree:** the purchase is the spending and the bill payment is not. They do it with accounts and transfers, which hisaab doesn't have.
- **Why it matters for a daily number:** Soman (2001) found that past payments hold back future spending most when the payer writes the amount down (rehearsal) and the money leaves at once (immediacy). Card payments have neither ([Journal of Consumer Research abstract, IDEAS](https://ideas.repec.org/a/oup/jconrs/v27y2001i4p460-74.html); abstract only). Logging at the swipe puts the rehearsal back.
- **India context:** RuPay credit cards on UPI make up about 38% of credit card transactions by volume (Bernstein, via [Mint/Magzter](https://www.magzter.com/en/stories/newspaper/Mint-New-Delhi/CREDIT-CARD-UPI-LIFTS-RUPAY-VOLUME-MKT-SHARE-TO-38); via search, secondary). So a card swipe is now often a UPI scan at a chai stall, and it's logged the same way as any other UPI spend.

### Fast-entry surfaces on Android
- **Notification permission:** on Android 13+, notifications are **off by default for new installs** until the app asks. Google advises asking "in context" from a user action ([Android, Notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)).
- **Tapping a notification:** every notification must respond to a tap, usually by opening the matching screen. It allows up to 3 action buttons, which "must not duplicate the action performed when the user taps the notification". Direct reply (`RemoteInput`, API 24+) sends typed text without opening the app ([Android, Create a notification](https://developer.android.com/develop/ui/views/notifications/build-notification)). `RemoteInput` has no numeric keyboard: a Stack Overflow question asking for one has no accepted answer, so the reply field uses the full text keyboard ([search summary](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/tagged/remote-input); low confidence, unverified against the API reference).
- **Lock screen:** `VISIBILITY_PRIVATE` with a public version hides the content on the lock screen ([same page](https://developer.android.com/develop/ui/views/notifications/build-notification)). Apple: "avoid including sensitive, personal, or confidential information" ([HIG Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications.md)).
- **Exact alarms:** most apps should use inexact alarms. `setAndAllowWhileIdle()` suits "user-specified action that should happen after a specific time (even if system in idle state)". On Android 12+ an inexact alarm fires within an hour of its time unless battery saving is on. `SCHEDULE_EXACT_ALARM` is **not pre-granted** on fresh installs targeting Android 13+. `USE_EXACT_ALARM` is for limited use cases under Play policy. Alarms are cleared on reboot unless re-armed from `BOOT_COMPLETED` ([Android, Schedule alarms](https://developer.android.com/develop/background-work/services/alarms/schedule)). A bill reminder doesn't need to fire to the minute, so **inexact is right**.
- **OEM battery killers:** dontkillmyapp ranks Xiaomi 2nd, OnePlus 3rd, Samsung 4th, Oppo 8th, Vivo 11th and realme 12th worst ([dontkillmyapp](https://dontkillmyapp.com/)). On MIUI, "in default settings, background processing simply does not work right". The fixes are user-side settings: autostart, *No restrictions* and locking the app in recents ([dontkillmyapp/xiaomi](https://dontkillmyapp.com/xiaomi)). The page doesn't name alarms specifically. **A scheduled reminder may never arrive on the phones most common in India.** Home has to stay the guaranteed surface.
- **`flutter_local_notifications`** (22.3.3) supports action buttons, inexact schedule modes, `requestExactAlarmsPermission()`, and a boot receiver to reschedule after a reboot. Actions can run in a background isolate without opening the app. Since v16 it declares only `POST_NOTIFICATIONS` and `VIBRATE` ([pub.dev](https://pub.dev/packages/flutter_local_notifications)). The page documents text-input actions only for Windows and Web. It doesn't mention network access. It's local only, but scheduling with `zonedSchedule` uses `TZDateTime` from the `timezone` package (from general knowledge of the plugin; check before approving). Developers who used exact modes on Android 14 hit `exact_alarms_not_permitted`, and the advice is to switch to `inexactAllowWhileIdle` ([issue #2316](https://www.github.com/MaikuB/flutter_local_notifications/issues/2316); via search).
- **Quick Settings tile:** Google advises against using a tile "for one-time user actions" ("use an app shortcut or a notification instead"), says a tile shouldn't just launch the app, and recommends at most two per app. Adding a tile takes 4 steps in the edit panel, or one prompt from `requestAddTileService()` on Android 13+ ([Android, Quick Settings tiles](https://developer.android.com/develop/ui/views/quicksettings-tiles)). `quick_settings_tile` on pub.dev has one stable release, 0.0.1, while its docs show 1.0.0 ([pub.dev](https://pub.dev/packages/quick_settings_tile)). It's immature.
- **Home-screen widget:** widgets support only touch and vertical swipe. "Generative functions", such as creating something new, are good link targets ([Android, App widgets overview](https://developer.android.com/develop/ui/views/appwidgets/overview)). A widget can't take typed digits, so the amount still has to be typed in the app. `home_widget` supports interactive callbacks that run Dart code ([pub.dev API](https://pub.dev/documentation/home_widget/latest/home_widget/HomeWidget-class.html)).
- **App shortcuts:** shown when the user long-presses the launcher icon; most launchers show up to 4 ([Android, App shortcuts](https://developer.android.com/develop/ui/views/launch/shortcuts)). Long-press is hidden, which D21 rules out as the main path.

### Notification UX
- **Material** (M1 patterns page, the newest one that could be fetched): notifications are for "short, timely, and relevant information". Well-timed task reminders are one of the most effective kinds. They "should not be the primary communication channel", with no "haven't seen you in a while". A stale notification should be dismissed automatically ([Material, Notifications pattern](https://m1.material.io/patterns/notifications.html)). Titles are under 30 characters and text under 40.
- **Apple HIG:** "Avoid sending multiple notifications for the same thing, even if someone hasn't responded … people may turn off all notifications from your app." Avoid "an action that merely opens your app" ([HIG Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications.md)).
- **What users say:** one bill-reminder review complains of "too many notifications: multiple bill reminders each day" ([grand-screen reviews](https://grand-screen.com/apps/bill-payment-reminder-budgets/reviews/)). Another user wanted a *second* reminder after dismissing one by mistake ([App Store, via search](https://apps.apple.com/app/id514301848)). Both are anecdotal. Vendor surveys (Localytics 2017, n = 1,000 US) put about 10% disabling notifications at one a week, rising sharply at 2–5 a week ([Business of Apps](https://www.businessofapps.com/marketplace/push-notifications/research/push-notifications-statistics/); self-reported and old, low confidence).
- **Timing:** I found no study comparing a reminder on the morning of the due day with one the day before. My inference is that hisaab's job is to *record* the bill, not to make the user pay it (the bank or autopay does that). The amount is known on the due day at the latest, so the due-day morning suits recording. Low confidence; this needs the diary study.

## Patterns compared

### Bill model

| Model | Who does it | `safe to spend` before the amount is known | After entry | Effort per month | Fit |
|---|---|---|---|---|---|
| A. Fixed auto-post (today) | Goodbudget Android, hisaab | Last amount reserved | Wrong unless edited | 4 taps + digits, unprompted | Rent/EMI only |
| B. Auto-post an estimate, correct later | Simplifi (with bank match) | Estimate reserved | Wrong until corrected | Same as A, and easy to forget | Needs bank sync to be honest |
| **C. Waits for the amount ("due, how much?")**, estimate reserved until then | YNAB, Actual (manual), Chronicle | Estimate reserved, including after the day | Exact | 2–3 taps + digits, prompted | Variable bills |
| D. Amount range | Actual, Copilot | Range is a matching aid | — | — | Only matters with imports |
| **E. Two kinds: fixed bills post, changing bills wait (A + C)** | Actual (per-schedule auto vs approve) | As A or C | Exact | Fixed: 0; changing: 2–3 + digits | **Both** |

### Fast-entry surface
Taps to done: from wherever the phone is, to the amount saved. Digits are excluded and so is unlocking. The count assumes the app or notification is already in reach.

| Surface | Taps to done | Discoverable | Reliable | New package | Network |
|---|---|---|---|---|---|
| Today's workaround: find the posted entry, edit | open 1 + row 1 + Next 1 + tile 1 = **4** | Low (nothing says it's wrong) | Yes | — | No |
| **Home "how much?" line → bill amount sheet** | open 1 + line 1 + Save 1 = **3** | High, on Home on the day | **Always**, when the app is opened | **None** | No |
| **Due-day notification → opens the same sheet** | tap 1 + Save 1 = **2** | High once allowed; off by default on 13+ | Inexact (within ~1 h); may never come on MIUI/ColorOS | `flutter_local_notifications` (+ `timezone`) | No |
| Notification action "₹X, same as last time" | 1 (expand + 1 on some phones) | Medium | As above, runs in a background isolate | Same | No |
| Notification direct reply (`RemoteInput`) | Reply 1 + Send 1 = 2 | Medium | Text keyboard, no ₹ grouping, no Indian-grouping preview, no undo | Same; not documented for Android text input | No |
| Home-screen widget button → sheet | 1 + Save 1 = 2 (after a one-time placement) | Low: the user must add it | Good | `home_widget` + native layout | No |
| Quick Settings tile → sheet | pull 1 + tile 1 + pick bill 1 + Save 1 = 4 | Low; Google says not for one-time actions | Good | `quick_settings_tile` (0.0.1) | No |
| App shortcut (long-press icon) | press 1 + item 1 + Save 1 = 3 | Low; hidden gesture (D21) | Good | `quick_actions` (first-party) or none (static XML) | No |

## Recommendation

### Bill model: E, two kinds of bill, with C for the changing kind (top pick)
- **"Same every month"** works as today: posted on its day (BR-9).
- **"Changes every month"** is never auto-posted. Its *estimate* is the last amount entered (the setup amount the first time), and it stays reserved in `B` until the user enters the real amount or says it didn't happen this month.
- **No new question in the wizard.** The kind is set from the name pill: *Credit card*, *Electricity*, *Gas*, *Water* and *Phone* default to "Changes every month"; everything else (Rent, EMI, a typed name) defaults to "Same every month". The bill sheet from case study 16 gets one more Change row, **"Amount: Changes every month › / Same every month ›"**. For changing bills the wizard's amount question reads "About how much?" This follows PLAN §2: a sensible default, changeable in one place.
- **On Home**, the one nudge slot (FR-HO-3) does three jobs, in this order (only one line ever shows):
  1. A changing bill due today or earlier in this cycle that hasn't been entered: **"Card bill went out today. How much?"** (or "…on 18 Nov. How much?").
  2. The existing due-soon line, with "about" for changing bills: "Electricity about ₹1,200 goes out in 3 days".
  3. Nothing.
- **Tapping the line** opens the bill sheet (case study 16) straight on its amount keypad. It's prefilled with the estimate, a caption reads "Last time ₹1,200", and the marigold key reads *Save*. One tap on *Save* confirms "same as last time". A text chip in the sheet, **"Didn't go out this month"**, skips the occurrence and frees the reserve.
- **Saving** posts one entry with the rule's `recurring_id`, dated the due day (the BR-9 unique index keeps it to exactly once), then plays the `tick` haptic with Undo.
- **This is not the Add flow.** The Add tray's Add → digits → Next → tile stays untouched. Confirming a bill is a bill-sheet task, like changing its amount.

### Formula impact (BR-3 symbols)
Today, `B` = unposted *Spent* occurrences due in `(t, end]`. With waiting bills:

```
B = Σ fixed occurrences due in (t, end], at their amount            (unchanged)
  + Σ changing occurrences due in [start, end] not yet entered or skipped, at their estimate
```

A changing bill still waiting on or after its day stays in `B` until the user acts, so **an unknown bill is always reserved**. An occurrence from a past cycle isn't in `B`. If the user enters it late, its entry is dated in that cycle (BR-10 allows the previous cycle) and touches only that cycle (E6).

**The day-of problem has to be fixed at the same time** (see *What's wrong*). I propose that a bill entry (`recurring_id` set) dated `t` comes out of the pool, not out of today's share:

```
P       = I − K − B − S_prev − R_t        R_t = Spent entries dated t with recurring_id set
S_today = Spent entries dated t with recurring_id unset
```

- **Worked example** (SPEC numbers, `t` = Mon 26 Oct, `D` = 9): `I` = 45,000, `S_prev` = 27,150, and electricity estimate ₹1,200 due **today** and still waiting, so `B` = 1,200. Then `P` = 16,650, `A` = 1,850, and with ₹420 spent `safeToday` = 1,430, all as SPEC's example.
- The user enters **₹1,460**. `B` falls to 0 and `R_t` = 1,460. `P` = 45,000 − 0 − 1,460 − 27,150 = **16,390** and `A` = floor(16,390 / 9) = **1,821**, so the hero reads **₹1,401**. The ₹260 surprise is spread over 9 days (about ₹29 a day) and today isn't "over".
- Under the current rule (bill in `S_today`), `P` would be 17,850, `A` = 1,983 and `S_today` = 1,880, so the hero would drop to **₹103**. A ₹1,460 bill would look like ₹1,460 of today's spending.
- This changes BR-3, BR-4 ("`A` is fixed for the whole of day `t`": entering a bill today recomputes `A`, as a back-dated entry already does) and BR-8 (`A_yesterday` already treats today's bill posts as `B`, so it agrees). It needs a DECISIONS row. **This is design-product's call.**

### Credit card: log the swipe, and the card bill is a reminder that doesn't count (top pick)
- **The rule:** a card purchase is spending when it happens, and the user adds it like any UPI payment. The card bill is a **pay reminder only**. It shows on Home on its day, and the user can note what they paid, but it is **never added to `B` or `S`**. This is what YNAB, Monarch and Money Manager do with transfers, without needing accounts. It also keeps today's number honest at the moment of choice (Soman's rehearsal).
- **Why not "log the bill, not the swipes"?** It's simpler, one entry a month, and cash-honest (this cycle's salary pays last month's statement). But for a whole month the daily number can't see card spending, and every card purchase falls into *Bills*, which hides food and travel from Spends. The double count comes back the first time the user also logs a card swipe. That fails the app's single question.
- **Making it visible without a question:** when the user picks the *Credit card* pill, the wizard's amount step reads "About how much is the bill?". One sentence under it says **"Add card buys when you make them. This only reminds you to pay; it won't count twice."**
- **Alternative (B), if the owner prefers it:** one yes/no in the card wizard, "Do you add card buys here when you make them?". *Yes* gives a reminder only; *No* makes it a changing bill that counts (model C). That's one extra question for one pill only. It's honest for both habits, but it's a choice a 5-year-old shouldn't have to make.
- **Conflict:** the owner said "enter the amount … and track it too". Under the top pick the card amount is *recorded* but not *counted*. The owner must say whether that matches what they meant by "track".

### Fast entry: a Home line now, a due-day notification next
1. **Now, no new package (fallback and foundation):** the Home "How much?" line opens the bill sheet on its keypad: **3 taps + digits**. It always works, it's visible (D21) and it uses the existing nudge slot.
2. **Top pick, needs owner approval for `flutter_local_notifications` (and probably `timezone`):** one local notification per changing-bill occurrence, on the **morning of the due day** (inexact, `inexactAllowWhileIdle`, around 9:00, no exact-alarm permission).
   - **Copy:** title "Card bill went out today", text "Tap to add how much".
   - **Lock screen:** the public version reads "A bill is due". No amount ever shows on the lock screen.
   - **Tap:** opens the app on the bill sheet's keypad: **2 taps + digits**.
   - **Rules:** no action buttons in v1, since tapping already does the job and Material and HIG warn against duplicating it. One notification per occurrence, never repeated. It's cancelled automatically when the amount is saved in the app. Swiping it away means "back off" for that occurrence (the user's no-nag rule; principle 48).
   - **Permission:** asked in context, once, the first time a changing bill is saved: "Remind you on the day it goes out?" with *Remind me* / *Not now*. *Not now* is never asked again; the system notification settings are the off switch.
   - **Reboot:** `RECEIVE_BOOT_COMPLETED` re-arms the reminder, and every app start re-arms it too (as BR-8 re-runs the engine).
3. **Later, not for bills:** widget, tile and shortcut. They serve general quick-add (UI_DESIGN §10 "Later quick-add options") better than bills. Google itself says tiles aren't for one-time actions, and a widget can't take digits.

**Rejected:**
- Notification direct reply: text keyboard, no ₹ formatting, no undo, and not documented for Android in the plugin.
- A "same as last time" action button for now: a one-tap guess on a varying bill invites wrong numbers. It's an open question below.
- Exact alarms: a Play policy risk and a permission screen, for precision nobody needs.

## Risks
- **The reminder doesn't arrive on Xiaomi, Oppo, Vivo or realme** (dontkillmyapp). The design treats the notification as a bonus. Home's line is the guarantee. Never ask the user to change battery settings: that's a dark-pattern-adjacent chore and fails the 5-year-old bar.
- **A waiting bill that's never entered** keeps its estimate reserved for the rest of the cycle. That's safe (it errs low) but can look stuck. "Didn't go out this month" fixes it. At the cycle's end the occurrence drops out of `B` silently, with no carry-over nag.
- **The estimate is too low.** Last month's amount can undershoot (a summer electricity bill). Quicken advises "high enough", and Chronicle uses an average. "Last amount" is the simplest to explain ("Last time ₹1,200"). See open question 3.
- **The kind is guessed wrong.** A typed name like "Airtel" defaults to "Same every month". The Change row fixes it in 3 taps. If tests show users miss it, add the question to the wizard.
- **The `R_t` change touches the core formula and its tests** (BR-3, BR-4, BR-6, BR-6a, BR-8). It's a bigger change than the feature. Without it, however, every bill entered on its day reads as "over today", which is already true for rent.
- **Privacy:** the notification body names a bill. Lock-screen visibility is private, and the text has no amount and no note (NFR privacy; never log notes).
- **The Add flow stays untouched.** Bill confirmation lives in the bill sheet. Never add a "bill" toggle to the Add tray.

## Proposed principles (to add to `principles.md` under a new "Bills and reminders (case study 18)" section, numbered 57 onwards after case study 16's)
- **A known date with an unknown amount waits for the amount; it is never posted as a guess.** Reserve an estimate until the real amount is entered or skipped. *Sources:* Actual Budget schedules (approve manually); YNAB scheduled transactions; Chronicle *Amount Due Varies*. *Applies to:* changing bills, BR-3 `B`.
- **Count money once, at the moment of choice.** A card purchase is spending; paying the card is not. *Sources:* YNAB credit card handling; Monarch transfers; Realbyte transfers; Soman 2001. *Applies to:* credit card bills, any future "account" idea.
- **A reminder is a bonus; the in-app line is the guarantee.** Design so nothing breaks if the notification never arrives. *Sources:* dontkillmyapp; Android alarms (inexact, Doze, reboot). *Applies to:* bill reminders, any scheduled nudge.
- **One notification per thing, opened by its tap, with no action that repeats the tap; ask permission at the moment it helps.** *Sources:* Material notifications pattern; Apple HIG Notifications; Android notification permission. *Applies to:* bill reminders.

## New sources (to add to `sources.md`)
- [Actual Budget docs](https://actualbudget.org/docs/schedules): fetches cleanly; the clearest auto-vs-approve schedule spec.
- [YNAB support `.md`](https://support.ynab.com/en_us/scheduled-transactions-a-guide-BygrAIFA9.md): already listed for colours; it works for scheduled transactions and credit cards too.
- [Monarch help](https://help.monarch.com/hc/en-us/articles/360048393292) and [Realbyte help](https://help.realbyteapps.com/hc/en-us/articles/360043392253-How-to-settle-credit-card-payments): both return **403**, so read them in a browser.
- [PhonePe help](https://cms.phonepe.com/en/myhelp/autopay-payment-reminders/payment-reminders/how-do-i-set-payment-reminder-phonepe/): `cms.phonepe.com` redirects through `iris.phonepe.com` to the help home, so the article body isn't reachable by fetch.
- [dontkillmyapp.com](https://dontkillmyapp.com/): OEM ranking and per-vendor user fixes; fetches cleanly; the vendor pages don't mention alarms by name.
- [Android: alarms](https://developer.android.com/develop/background-work/services/alarms/schedule), [notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission), [build a notification](https://developer.android.com/develop/ui/views/notifications/build-notification), [QS tiles](https://developer.android.com/develop/ui/views/quicksettings-tiles), [widgets](https://developer.android.com/develop/ui/views/appwidgets/overview), [shortcuts](https://developer.android.com/develop/ui/views/launch/shortcuts): all fetch cleanly.
- [Material M1 notifications pattern](https://m1.material.io/patterns/notifications.html): fetches; the m3.material.io equivalent wasn't tried, given the known render failures.
- [Apple HIG Notifications `.md`](https://developer.apple.com/design/human-interface-guidelines/notifications.md): fetches cleanly.
- [Simplifi community](https://community.simplifimoney.com/) and [Lunch Money feedback](https://feedback.lunchmoney.app/): user requests and staff replies; demand, not design.

## Open questions
1. **What did the owner mean by "track" the card bill?** A recorded but uncounted card bill (top pick) or a counted bill with no swipe logging (alternative B)? This decides the double count.
2. **Should the `R_t` fix (bills come out of the pool, not today's share) ship first and on its own?** It's a live bug for fixed bills too. Conflicts with BR-3's sentence on bills due today and with BR-4's "`A` fixed for the day". It needs a DECISIONS row.
3. **What estimate?** Last amount (top pick), the average of the last 3, or the highest of the last 3 (safest)? A diary study across two pay cycles would show how far real bills swing.
4. **A "₹X, same as last time" notification action** (1 tap)? It's useful for a phone bill that rarely changes and risky for a card. Test it in a usability round before building.
5. **Reminder timing:** the due-day morning (top pick) or the day before (better for someone who pays by hand)? There's no evidence either way. Ask "tell me about the last time you paid your card bill" in 5 interviews (Mom Test).
6. **Packages:** `flutter_local_notifications` (and likely `timezone`) aren't in PLAN §11. Is owner approval given? `home_widget` and `quick_settings_tile` aren't needed for this feature.
7. **Conflicts to log:** FR-SE-1 (bills are fixed and monthly; the wizard asks "About how much?" for changing bills), D35 (three questions: still true under the top pick, not under alternative B), BR-9 (the due-soon nudge never shows on the day; the "How much?" line does), SPEC §1.2 (no notifications in v1).
8. **Validation:** a 5-user think-aloud with UPI-first users on low-end Xiaomi/realme phones. Tasks: set up a card bill and an electricity bill; on the due day, enter the amount from the Home line; then from the notification. Measure task success, time, errors and SEQ. Add a blind read of "Card bill went out today. How much?".
