# 26. Mera Kharcha: a voice-and-AI tracker with a server

## Question
What is Mera Kharcha, who is it for, and what should hisaab• learn from it or avoid? Does it answer "how much can I safely spend today?"

## Method
Desk and competitive research only, chosen as the cheapest method that could change a decision. Fetched the maker's site and its linked pages, then searched for the Play Store and App Store listings, reviews, Reddit and press. Date of research: 2026-11-11. No app was installed or run, so **nothing here describes how a screen looks or how many taps a flow takes**. Everything below is the maker's own description or inference from it.

## Sources
- [Home](https://merakharcha.in/), [Budget app](https://merakharcha.in/budget-app), [Daily kharcha app](https://merakharcha.in/daily-kharcha-app), [About](https://merakharcha.in/about), [Download](https://merakharcha.in/download)
- [Privacy policy](https://merakharcha.in/pages/privacy), [Mera SMS](https://merakharcha.in/mera-sms)
- Blogs: [Ask AI (blog_13)](https://merakharcha.in/pages/blog_13), [Best money app (blog_11)](https://merakharcha.in/pages/blog_11)
- Play listing: [com.mera_kharcha_expense](https://play.google.com/store/apps/details?id=com.mera_kharcha_expense&hl=en_IN&gl=IN)
- Web search for reviews: found only the maker's pages (see Gaps).

All first-party, so this is marketing plus a privacy policy: low confidence on quality, high confidence on what the maker claims.

## What was tried and what came back
| Attempt | Result |
|---|---|
| Fetch the Play listing | Returned only the title "Mera Kharcha AI Expense Manage" and the category links. **Rating, review count, installs, last update, Data safety and reviews were not read.** The `curl` method in `sources.md` could not be run (no shell in this session) |
| Fetch the older Play listing `com.kharcha_sms` | HTTP 404 |
| Web search for reviews, Reddit, press | No Reddit thread, no press, no independent review. One third-party comparison, [fintrakk](https://fintrakk.com/best-personal-expense-tracker-app-india/), appeared in results but was not opened; its description of the app (local-first, SMS aggregator, AI) comes only from a search summary and conflicts with the privacy policy, so it is not used |
| App Store | Site says the iPhone version arrives on 15 November ([Download](https://merakharcha.in/download)). No listing found. "Kharcha Manager" and "Kharcha Book" on the App Store are different apps |
| Developer's structured data | A 4.5 rating from 8 ratings on [kharcha-platform.web.app](https://kharcha-platform.web.app/), seen only in a search summary. It is the developer's own page, not the Play rating |

## Findings
**Seen on the maker's pages (what they say):**
1. **What it is.** A personal expense tracker for India, tagline "Just say it. In your own language." Voice or chat entry in Hindi, English, Hinglish and more; 29 app languages; charts by category, payment method, top places and a calendar; search; bill reminders; family mode; splits; Google sign-in sync ([Home](https://merakharcha.in/)).
2. **Maker.** Codexcollab, which also makes the Mera SMS app. Only one person is named; no user counts ([About](https://merakharcha.in/about)).
3. **Core job.** Record and review what was spent. It is explicitly not a limit tool: "does not set spending limits or send overspend alerts"; you use the totals "to plan your salary" ([Budget app](https://merakharcha.in/budget-app)).
4. **No safe-to-spend or daily figure.** None on the budget page, the daily page or blog_11 ([Budget](https://merakharcha.in/budget-app), [Daily](https://merakharcha.in/daily-kharcha-app), [blog_11](https://merakharcha.in/pages/blog_11)). "Daily kharcha" means what you spent in a day, not what remains.
5. **Manual entry.** "Type the amount and pick a category", plus a date and a payment method (cash, UPI, card) ([Daily](https://merakharcha.in/daily-kharcha-app)). Tap count is not stated. The FAQ says it "takes a few seconds" ([blog_11](https://merakharcha.in/pages/blog_11)). Payment method and date are extra fields compared with hisaab•'s path.
6. **Automatic entry.** Optional, via the separate Mera SMS app: same Google account in both, then "Auto-track payments". Off by default. Not every payment is detected; cash needs manual entry ([Mera SMS](https://merakharcha.in/mera-sms), [Home](https://merakharcha.in/)).
7. **AI.** Ask AI sends the question plus relevant expense records, not anonymised, to Google Gemini through Vertex AI. Example questions: food this month, Swiggy this month, top five expenses, did the SIP go through ([blog_13](https://merakharcha.in/pages/blog_13), [Privacy](https://merakharcha.in/pages/privacy)).
8. **Recurring.** "Bill reminders" for rent, EMIs and subscriptions, with a reminder before each due date, Premium only. The pages do not say whether an entry is posted automatically ([Budget](https://merakharcha.in/budget-app)).
9. **Privacy.** Records are stored on the maker's backend and cached on the phone. Firebase handles sign-in, **usage analytics**, crash diagnostics and remote config. AdMob serves ads, Meta App Events measures installs, OneSignal sends push, and a speech provider handles voice audio. SMS imports upload sender, body and timestamp after consent. Delete account is in Profile or on the web ([Privacy](https://merakharcha.in/pages/privacy)).
10. **Business model.** Free with ads (manual entry, charts, search, widget, custom categories). Premium removes ads and adds reminders, splits, family creation, Ask AI, summaries, voice and chat entry, quick-add notification. Every new account, guest included, gets a 7-day trial. Token packs add AI allowance. A rewarded-ad "Day Pass" unlocks Ask AI until local midnight. No prices are published ([Home](https://merakharcha.in/), [blog_13](https://merakharcha.in/pages/blog_13)).
11. **Copy tone.** Short, plain, upbeat, everyday Hindi-English ("kharcha", "ghar kharcha", "jama kharch", "No notebook needed") ([Daily](https://merakharcha.in/daily-kharcha-app)).
12. **Recently deleted.** Optional 30-day restore of deleted items ([Home](https://merakharcha.in/), [Privacy](https://merakharcha.in/pages/privacy)).

**Inconsistencies in the maker's own pages (seen):**
- blog_11's May 2026 body says SMS is read "on your device" and calls tracking free, while the same page and its October 2026 update say records sit on servers and AI, voice and some sharing are Premium ([blog_11](https://merakharcha.in/pages/blog_11)). A search summary also reported a claim of "no trial, subscription or premium paywall" in a blog post; that was not re-verified.
- The product moved from reading SMS inside the tracker to a two-app setup (Mera SMS as the default SMS app), per blog_11's update.

**Inferred (not seen):**
- The two-app SMS design means a user must change their default SMS app to get automation. That is a heavy ask, but no data on drop-off exists.
- Voice entry probably takes fewer taps than the keypad for long phrases, and is the headline feature for low-literacy or Hindi-first users. Unverified.
- The free tier being ad-supported implies ad SDKs run on the finance screens. The policy confirms AdMob, not placement.
- Onboarding, colour, type, category list, review praise and complaints: **not found**. No screenshots or reviews were readable.

## Comparison with hisaab•
| Area | Mera Kharcha | hisaab• |
|---|---|---|
| Core question | "What did I spend?" Reports and Q&A | "How much can I safely spend today?" A single number |
| Limits and alerts | None, by design ([Budget](https://merakharcha.in/budget-app)) | Daily share drains with every expense (CLAUDE.md) |
| Entry | Amount, category, date, payment method; voice and SMS as accelerators | Add, digits, Next, tile |
| Network | Server, sign-in, analytics, ads, AI on Gemini ([Privacy](https://merakharcha.in/pages/privacy)) | None |
| AI | In-app chat, paid, user data sent to Google | Exports a prompt the user previews and sends themselves |
| Money model | Free with ads, Premium, token packs, Day Pass | Not specified here; see `docs/PLAN.md` |
| Languages | 29 | See `docs/UI_DESIGN.md` |
| Social | Family, splits, invite codes | None |

**Overlap.** Both are India-first, INR, UPI-aware, simple-entry trackers with category totals and an AI angle.

**Where hisaab• is stronger.**
- It answers the question users actually plan with, and Mera Kharcha says it does not.
- No account, no ads, no analytics, no SMS upload: Mera Kharcha's policy lists six third-party processors ([Privacy](https://merakharcha.in/pages/privacy)).
- AI is user-controlled and previewed, versus automatic upload of unanonymised records.
- Fewer entry fields, assuming the extra payment-method and date fields are required (not confirmed).

**Where Mera Kharcha is stronger.**
- Voice and Hinglish entry, 29 languages, and automatic capture of bank SMS reduce typing. Cash is still manual.
- Recently deleted, search, calendar view, widget, quick-add notification, splits and family cover needs hisaab• deliberately omits.

## Implications for hisaab•
Handed to `design-product`. None changes `docs/DECISIONS.md`.
- **Position, not copy.** "Tells you what's safe today" is an open gap against this competitor, which says it will not. Worth one line in store copy ([design-content](../../../.claude/agents/design-content.md)).
- **Do not chase SMS or bank capture.** It requires a server, a default-SMS change and consent flows, which conflicts with the no-network rule. Mera Kharcha's own inconsistent privacy messaging shows the cost of claiming "local" while uploading.
- **Voice entry is the one idea worth a later look.** It could fit "a 5-year-old can use it" for low-literacy users, but it needs a speech provider (network or on-device) and would add a path beside Add → digits → Next → tile. Needs usability evidence first; not proposed now.
- **Recently deleted** (30 days) is a recovery pattern; compare with the reset rules in [case study 23](23-backup-reset-delete.md). Open question, not a recommendation.
- **Conflicts with principles:** server sync, ads, analytics and in-app AI conflict with "no network, no analytics". Paywalling the core AI answer conflicts with hisaab•'s zero-config ethos. Extra entry fields conflict with the entry-speed rule. Colours are unknown, so no red/green conflict can be claimed.
- No new principle added to `principles.md`: the evidence is first-party and thin.

## Open questions
- Play rating, review count, installs, last update, Data safety and recent reviews were not read. Run the `curl` method from `sources.md` on `com.mera_kharcha_expense` and read the reviews in a browser.
- Tap count, onboarding, screens, colour, type and category list need the app installed and recorded (or Mobbin in a browser).
- Does a reminder auto-post an entry? Does the free tier show ads on the entry screen?
- Is the 7-day trial followed by a hard paywall on voice and AI, and what do users say about it?
- No independent reviews found, so praise and complaints are unanswered, not "none".
- Confidence: high on features, pricing tiers and data flows as the maker states them; low on everything about usability and reception.
