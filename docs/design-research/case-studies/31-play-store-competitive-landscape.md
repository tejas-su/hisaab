# 31 · Where hisaab stands among popular Play Store expense trackers

Date: 2026-11-11. Status: **research only, nothing adopted.** Kept local: not published or shared.

## The question

hisaab is about to meet a crowded shelf. Which popular Android expense trackers will an Indian user compare it with? Where does hisaab stand against them? What does it lack, and which gaps are worth closing without breaking the "5-year-old can use it" bar?

## Method and caveats

- **Play listings, measured by script** (`curl` of the listing with `hl=en_US&gl=IN`, reading the `ratingValue` from the page's structured data plus the downloads bucket and review count). WebFetch cannot render Play pages. The numbers are a snapshot from 2026-11-11 and are listed in the table below.
- **Desk research:** 2026 "best expense tracker in India" roundups, review sites, developer sites, Play policy pages and forum threads. **Most roundups are written by a competing app maker** (Moneyview, Jupiter, FinArt, mFinley, Aaptam, SpendTrak, AI Money Vault). They are used for which apps get named and for feature lists, never for verdicts. The quit-reason statistics come from such vendors, so treat them as directional only.
- **Not done:** no apps installed, no screens, no tap counts, no user interviews. Earlier studies already cover Unfold (14), Bharpai (25), Mera Kharcha (26), My Spend (27) and Play colours (30). This study does not repeat them.

## The field

### Play listing snapshot (India store, 2026-11-11)

| App | Downloads | Rating | Reviews | Ads | Entry model |
|---|---|---|---|---|---|
| Money Manager (Realbyte) | 10M+ | 4.65 | 469K | Yes + IAP | Manual, double-entry accounts |
| Wallet (BudgetBakers) | 10M+ | 4.69 | 389K | IAP | Manual + bank sync (not India) + CSV import |
| Monefy | 10M+ | 3.99 | 195K | IAP | Manual, pie-chart home |
| axio (ex-Walnut) | 10M+ | 4.46 | 267K | IAP | **Bank SMS auto-read**, plus loans, BNPL and FDs |
| Money Lover | 5M+ | 4.25 | 208K | Yes + IAP | Manual |
| Spendee | 1M+ | 4.32 | 64K | IAP | Manual + bank sync, shared wallets |
| Cashew | 500K+ | 4.87 | 28K | IAP (lifetime $20) | Manual, local-first, open source (Flutter) |
| Fold | 100K+ | 4.58 | 1.5K | IAP (Fold Plus) | **Account Aggregator** (RBI AA) auto-import |
| PennyWise | 5K+ | 4.52 | 187 | IAP | SMS auto-read, on-device |

### Not measured, but relevant

These are named in the research, but their Play numbers were not checked:
- **PocketGuard**: its "In My Pocket" figure is the closest idea to hisaab's, but the app is US and bank-linked.
- **Daily Budget (KVANNLI)**: 120K downloads, last updated in 2019.
- **Today's Budget**: iOS only.
- **Plan & Multiply**: a daily limit with no bank, on iOS and Android.
- Other Indian SMS and voice trackers: FinArt, Kharch Log, AiXpense, Voxpense.

### Five camps

1. **Manual ledgers** (Money Manager, Monefy, Money Lover). Huge installed base, years of ratings, and accounts, calendars and charts. None answers "how much today?". Their reviews complain about ads, moves to subscriptions, hard-to-edit recurring entries, and the learning curve. One Money Manager reviewer asks outright for bill tracking or a "safe to spend" figure.
2. **Feature-rich hybrids** (Wallet, Spendee, Cashew). Multi-account, multi-currency, sync, widgets, goals, CSV import and export. They win on depth and look; the cost is a learning curve. Cashew shows that a local-first Flutter app with no sign-in can earn 4.9★.
3. **SMS auto-capture** (axio, PennyWise, FinArt, Kharch Log). These answer the top quit reason, typing every spend. Reliability is their weak point: axio's 2026 reviews describe missed banks, duplicates and an app that won't open. Play requires a separate SMS declaration for them.
4. **Account Aggregator** (Fold, CRED Money). They import your bank data with consent. The pitch is "everything automatic". They need a network and an account, and their coverage depends on which banks join.
5. **Daily-number apps** (PocketGuard, Daily Budget, Today's Budget, Plan & Multiply). Reviewers say the one number "changes behaviour on day one" (Spendalyst on PocketGuard). **No India-first, popular Android app holds this spot.** PocketGuard is US-only and bank-linked, and Daily Budget was abandoned in 2019. This matches the conclusion of case studies 26 and 27.

## Where hisaab stands

### Strengths: rare, or ours alone

| Strength | Who else has it |
|---|---|
| **One daily number** that already counts bills, savings and the days to payday | PocketGuard (bank-linked, US). The manual-ledger camp has nothing like it |
| **Bills that change and card bills** handled properly: changing bills wait with an estimate, card bills are never double-counted (D123) | None found. Card double-counting is a real flaw in SMS trackers (axio's duplicate complaints) |
| **Pay cycle follows payday automatically**, with no "budget period" setting | Cashew has custom periods, but the user has to set them |
| **No network, no account, no analytics** | Monefy and Cashew are local-first but still have optional cloud. None found with *no internet permission at all* |
| **Ask AI with a full preview**, so nothing leaves until the user sees it | Fold AI and Mera Kharcha send data to a server-side AI |
| **No shaming colours**; underspend rolls into tomorrow (the morning note) | SpendTrak lists "shame from seeing overspending" as a quit reason (66%, vendor data) |
| **4-tap entry** with quick-amount chips | Monefy is praised for speed; Money Manager has quick-add widgets |
| **Adaptive layout, TalkBack, reduced motion** | Rarely mentioned by any competitor |

### Weaknesses

| Gap | Severity | Note |
|---|---|---|
| **Everything is typed by hand** | High | The top quit reason across every source. Only partly offset by fast entry |
| **No home-screen widget or quick tile** | High | Money Manager, Monefy and Cashew all have one. hisaab's number is the most glanceable thing in the field and is hidden behind opening the app. PLAN §13 lists it as *Later* |
| **English only** | Medium–High | Mera Kharcha has 29 languages; Kharch Log, AiXpense and Voxpense offer Hindi or Hinglish. The architecture is ready (PLAN §5), but `app_hi.arb` doesn't exist |
| **Nothing brings the user back to log** | Medium | Bill reminders exist (D126), but nothing like "anything to add today?". The SpendTrak data lists "forgot to open it" at 42% |
| **No app lock** | Medium | Monefy, Cashew and Money Manager offer a passcode or biometrics. hisaab's recent-apps blanking (D109) covers only half of this |
| **No social proof yet** | Medium | Zero ratings against 10M+ incumbents. The store listing has to sell the *daily number* idea in a single screenshot |
| No CSV import from another app | Low–Medium | Wallet and Cashew import CSV. It would make switching from Money Manager or Monefy painless |
| No CSV export on its own | Low | Planned in M6. Today, CSV exists only inside the Ask AI prompt (`prompt_csv.dart`) |
| No cash / UPI / card split | Low | One Fold user asked for it. Deliberately out of scope (PLAN §2) |
| Only one device | Low | Competitors sync; hisaab has file backup (D139). It fits the privacy pitch |

## What could be added

Each item is scored on two counts: user pull (in the evidence above) and fit with hisaab's rules (zero-config, 4-tap entry, no network, one signal colour).

### Do next: high pull, good fit

1. **Home-screen widget: today's number plus Add.** It shows "₹1,240 left today" and has a tap target that opens the Add tray at the keypad. This turns the core value into something glanceable and takes one step off every entry. Needs `home_widget` (already named in PLAN §11 under *later*) and a design pass with `design-product` → `design-ui` → `design-platform`. Risk: what a widget shows on the lock screen or home screen, which is the same privacy question as D109. Offer a "hide the amount" variant through a blind read, not a setting.
2. **Quick Settings tile "Add a spend".** A tiny build, and it saves taps for heavy users. Also listed in PLAN §11.
3. **Hindi UI (`app_hi.arb`).** The best match for the "5-year-old" and emergent-user audience (Gupta et al., cited in case study 23). The copy needs `design-content`; the hero sentence and plurals need native review. Mukta and Anek Latin already have Devanagari, so no font work.
4. **An opt-in evening nudge.** One local notification at about 21:00 on a day with no entries: "Anything to add for today?" It opens straight to the keypad. It reuses the D126 notification plumbing, asks once, and never streaks or guilts (case study 11 rejected streaks).

### Explore: high pull, risky fit

5. **Assisted capture from payment notifications, not SMS.** On-device, a `NotificationListenerService` sees "Paid ₹240 to …" from GPay, PhonePe or a bank app and offers a *one-tap confirm* row on Home with the amount filled in. The user still picks the tile, so entry speed and category quality hold. Why not READ_SMS: Play needs an SMS declaration with uncertain review, and full auto-posting gives axio-style duplicates plus double-counting of card bills, which D123 was built to avoid. Open questions: parser upkeep across banks and apps, the Play special-access disclosure, and whether a suggestion row breaks the "never add a tap" rule (it adds a path, not a tap). **Recommend a research spike first** (`design-ux-research` + a prototype), not a build.
6. **Voice entry ("chai 40").** Indian rivals push Hinglish voice, but most send audio to a server (Mera Kharcha needs internet and Premium). Android's on-device recogniser (`EXTRA_PREFER_OFFLINE`) could keep the no-network rule, but its quality on Hinglish is unknown. Test with 5 users before deciding.
7. **App lock with the phone's own screen lock** (device credential, not a custom PIN). Low effort. It goes against "no settings" (PLAN §2), so it should be a single *Your hisaab* row, or a blind read on whether D109 already covers what people fear.

### Later: medium pull, good fit

8. **CSV import** from Money Manager, Monefy and Wallet exports, mapping their categories to the 8 + 4. A switching tool, offered on onboarding's first screen next to Restore (D139).
9. **CSV export** as M6 already plans, reusing the Ask AI CSV writer.

### Don't: these fight the product

| Feature | Why not |
|---|---|
| Bank sync / Account Aggregator | Needs a network, an account and a partner. It breaks the no-network promise, which is hisaab's sharpest point of difference |
| Accounts, net worth, investments, loans | The Money Manager / Wallet / Fold job. Adds setup; PLAN §2 keeps it out |
| Cloud sync, sign-in | The privacy pitch; file backup covers the reinstall case |
| Shared or family budgets, splitting | A different job (case study 25) |
| In-app AI chat | Sends data out; the previewed export is the better privacy story |
| Category colours, red/green, streaks, badges | D9, case study 11 |
| Ads, or a subscription bait-and-switch | The most common complaint in Money Lover and Monefy reviews. If hisaab is ever monetised, a one-time unlock (as Cashew's $20 lifetime) is what reviewers reward |

## Positioning for the store listing

- **Lead with the question nobody else answers in India:** "How much can I spend today?". Shot 1 is the hero number, not a chart. Every big incumbent's shot 1 is a chart or a list.
- **Say what's missing, as a feature:** "No sign-in. No bank login. No internet. No ads." This is checkable on the Data safety form. Case study 27 shows rivals whose copy says "on device" while their policy says "uploaded". hisaab's claim is literally true; make it loud.
- **Name the Indian specifics:** payday on any date, rent and EMI handled before your daily share, credit-card bills not counted twice.
- Title descriptor as PLAN §4 already says: "hisaab• – Daily Spend Tracker".

## Open questions for the owner

1. Is monetisation planned at all? **Answered (2026-11-11): never.** hisaab is a hobby project, so "no ads" can be promised for good.
2. Is Hindi in scope for v1, or after launch? **Answered: later.**
3. Should the widget show the amount by default, given D109's stance on the recent-apps preview? Open; [mockup 38](../../design/mockups/38-widget-and-tile.html) proposes a second, private widget.
4. Is assisted capture (item 5) acceptable in principle, given that it means reading payment notifications on the device? **Answered: later.**

Next step: the widget and tile (items 1 and 2) are drawn in [mockup 38](../../design/mockups/38-widget-and-tile.html).

## Sources

- Play listings (scripted, 2026-11-11): Money Manager `com.realbyteapps.moneymanagerfree`, Wallet `com.droid4you.application.wallet`, Monefy `com.monefy.app.lite`, axio `com.daamitt.walnut.app`, Money Lover `com.bookmark.money`, Spendee `com.cleevio.spendee`, Cashew `com.budget.tracker_app`, Fold `money.fold.marble`, PennyWise `com.pennywiseai.tracker`
- India roundups (several vendor-written): [aayushbhaskar.com](https://aayushbhaskar.com/best-monthly-expenses-tracking-apps-india/), [Jupiter](https://jupiter.money/blog/best-expense-tracker-app/), [Moneyview](https://moneyview.in/insights/best-personal-finance-management-apps-in-india), [moonproduct (mFinley)](https://www.moonproduct.tech/insights/upi-expense-tracker-india-2026/), [FinArt](https://finart.app/best-expense-tracker-apps-india/), [Aaptam](https://aaptam.com/blog/best-expense-tracker-apps-india)
- Money Manager: [realbyteapps.com](https://www.realbyteapps.com/), [appviewable review](https://appviewable.com/apps/app-money-manager-expense-budget/), [AppEight](https://appeight.com/review/money-manager-expense-budget)
- Wallet, Spendee, Monefy: [ledgerly](https://ledgerly.download/blog/budget-app-android), [getfinny free apps](https://getfinny.app/blog/best-free-expense-tracker-apps-2026), [aimoneyvault Android](https://aimoneyvault.app/resources/articles/best-expense-tracker-apps-android), [monefy.com](https://www.monefy.com/), [portofelo Monefy alternatives](https://portofelo.com/blog/monefy-alternatives)
- Cashew: [GitHub](https://github.com/jameskokoska/Cashew), [Android Police](https://www.androidpolice.com/best-open-source-expense-manager-on-android/), [Code With Andrea review](https://codewithandrea.com/videos/code-review-cashew-app/)
- axio: [Play listing](https://play.google.com/store/apps/details?id=com.daamitt.walnut.app&hl=en_US), [TechnoFino thread](https://technofino.in/community/threads/please-suggest-good-app-to-track-expenses.4583/page-4)
- Fold: [App Store India](https://apps.apple.com/in/app/fold-money/id1626994334), [Inventiva](https://www.inventiva.co.in/trends/top-10-best-budgeting-software-in-india-in-2027/), [Business Standard on CRED Money](https://www.business-standard.com/amp/finance/news/cred-launches-product-to-track-expenses-view-total-bank-account-balances-124072400997_1.html)
- Money Lover complaints: [App Store reviews](https://apps.apple.com/us/app/money-lover-money-manager/id486312413?see-all=reviews), [AppsHunter](https://appshunter.io/ios/app/486312413)
- Daily-number apps: [Penny Hoarder on PocketGuard](https://www.thepennyhoarder.com/budgeting/pocketguard-review/), [Spendalyst](https://spendalyst.com/blog/pocketguard-review), [BudgetingApps.org](https://budgetingapps.org/apps/pocketguard/), [Daily Budget on AppBrain](https://www.appbrain.com/app/daily-budget/com.kvannli.simonkvannli.dailybudget), [Today's Budget](https://www.todays-budget.com/), [Plan & Multiply](https://www.planandmultiply.com/en)
- Quit reasons (vendor data): [AI Money Vault](https://aimoneyvault.app/resources/articles/expense-tracking-statistics-2026), [SpendTrak](https://spendtrak.app/blog/why-people-quit-budgeting-apps)
- UPI and SMS capture: [FinArt UPI guide](https://finart.app/track-upi-expenses-automatically/), [UPI Expense Tracker on F-Droid](https://f-droid.org/en/packages/com.goushik.upiwallet/), [Play SMS/Call Log policy](https://support.google.com/googleplay/android-developer/answer/17225965?hl=en), [dev.to: why nobody reads SMS](https://dev.to/shadowmonarch9/i-built-an-sms-reading-expense-tracker-then-i-learned-why-nobody-else-does-that-309a), [Medium: auto-tracking without READ_SMS](https://medium.com/@owinojumahjerome/how-i-built-a-privacy-first-auto-expense-tracker-in-flutter-without-the-read-sms-api-6c7c66d56af5)
- Hindi and voice: [Mera Kharcha](https://merakharcha.in/), [AiXpense](https://aixpense.in/), [Voxpense](https://www.voxpense.app/), [Kharch Log](https://kharchlog.com/)
