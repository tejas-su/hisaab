# 27. My Spend (myspend.co.in): an account-based Indian tracker with a research-data model

## Question
What is My Spend, who is it for, and what should hisaab• learn from it or avoid? Focus: entry speed, safe-to-spend, privacy, business model.

## Method
Desk and competitive research, the cheapest method that could change a decision. Fetched the marketing site and its legal pages, then searched for the Play Store and App Store listings, press, Reddit and social mentions. Date of research: 2026-11-11.

Limits of this pass: no app was installed, no screens were seen, and the Play listing could not be identified (see Gaps). Everything about in-app flows is therefore unobserved. Only the marketing site and legal pages were read, and they are the company's own words.

## Sources
| Source | Used for | Limit |
|---|---|---|
| [myspend.co.in](https://myspend.co.in/) | Positioning, features, claims | Text only; the fetch tool returned no images. Play button links to `https://play.google.com` with no `id=`, so the listing is not discoverable from the site |
| [Privacy policy](https://myspend.co.in/privacy-policy) | Data collected, servers, retention | First fetch timed out; second worked. Read through a summarising fetch, not verbatim |
| [Terms of use](https://myspend.co.in/terms-of-use) | Business entity, research and analytics clause, Gmail access | Same |
| [Delete data](https://myspend.co.in/delete-data) | How deletion works | Same |
| [Blog](https://myspend.co.in/blog) | Posts | Fetch showed only the heading "Money Tips & Insights"; no posts could be listed |
| Web searches for the Play Store, App Store, Reddit and press | Listing, rating, reviews | Found nothing tied to this product (below) |

## Findings

### Seen directly (company's own site)
- **What it is:** "India's trusted expense tracking app", Android only, India only ([site](https://myspend.co.in/)). Features listed: expense logging with categories and tags, monthly budgets by category with alerts, a subscriptions tracker (OTT, gym, insurance), analytics charts, Google sign-in ([site](https://myspend.co.in/)).
- **Core job:** record spend and stay under category budgets. The only budget illustration is a phone mockup described as "Total Balance", "Income", "Expenses" and a "Budget Alert" at "80% used" ([site](https://myspend.co.in/#download)). No daily or safe-to-spend figure is mentioned anywhere on the site.
- **Entry:** "Add expenses in seconds"; manual entry is the only method described. No SMS or Gmail parsing is claimed ([site](https://myspend.co.in/#download)). The tap count is not published.
- **Onboarding:** none described. Sign-in is with a Google account ([site](https://myspend.co.in/)). Terms say users must be 18+ and resident in India ([terms](https://myspend.co.in/terms-of-use)).
- **AI:** not mentioned on the site or in the terms ([site](https://myspend.co.in/#download), [terms](https://myspend.co.in/terms-of-use)).
- **Offline:** "track without a connection, with automatic syncing", "stored on your device first", optional encrypted cloud backup ([site](https://myspend.co.in/)).
- **Pricing:** "100% Free"; no paid plan is mentioned on the site or in the terms ([site](https://myspend.co.in/), [terms](https://myspend.co.in/terms-of-use)). No ads and "no tracking" are claimed on the site.
- **Privacy claims on the site:** 256-bit encryption "the same security used by banks", one-tap data deletion, "GDPR Ready" badge, "doesn't sell user data" ([site](https://myspend.co.in/)). These are self-reported.
- **Self-reported traction:** "4.8 Rating" and "1 Lakh+" users, with no testimonials and no link to the listing ([site](https://myspend.co.in/#download)).

### Seen directly (legal pages), and they conflict with the marketing
- The privacy policy says: "All data is uploaded to secure servers controlled by My Spend in India via encrypted (HTTPS) channels" ([privacy](https://myspend.co.in/privacy-policy)). The site says data is stored on device first with cloud backup optional ([site](https://myspend.co.in/)). The two are hard to reconcile.
- The policy lists age, gender, contact details, location, device and network information, and contacts (with consent). With Gmail sign-in it may read Gmail messages and attachments "tied to spending" under a scope "such as gmail.readonly" ([privacy](https://myspend.co.in/privacy-policy)). The terms call Gmail access "strictly optional" and say it is used to spot receipts and extract sender, subject and timestamp ([terms](https://myspend.co.in/terms-of-use)).
- Data is retained "for as long as necessary for research purposes" ([privacy](https://myspend.co.in/privacy-policy)). The terms say data is anonymised and used in aggregate "for internal and external research and analytics", and users may join a voluntary "audience measurement panel" ([terms](https://myspend.co.in/terms-of-use)).
- The policy does not mention SMS access or bank linking ([privacy](https://myspend.co.in/privacy-policy)).
- Deletion is by email to myspendapphelp@gmail.com with a subject line, identity check, and a 48 to 72 hour wait ([delete data](https://myspend.co.in/delete-data)). The site's "one tap" deletion claim ([site](https://myspend.co.in/)) is not what the deletion page describes; the page may describe a separate account-closure path, which was not verified.
- Entity: "My Spend LLC", registered office in New Delhi ([terms](https://myspend.co.in/terms-of-use)); the privacy policy says only "My Spend" ([privacy](https://myspend.co.in/privacy-policy)).

### Not found
- **Play Store listing:** not identified. Searches returned other apps named MySpend: [com.myspend.money.spending…](https://play.google.com/store/apps/details?id=com.myspend.money.spending.budget.expense.manager.tracker.planner.app&hl=en_IN) (about 4.2 stars, 139 reviews, 10K+ installs per a search summary, developer mrrErick; the summary says it carries a cloned-app notice and does not mention Gmail login), [io.MySpend.app](https://play.google.com/store/apps/details?id=io.MySpend.app&hl=en_US) (an "AI Expense Tracker" with its own site, myspend.io), [com.myspend](https://play.google.com/store/apps/details?id=com.myspend&hl=en_US) and [TD MySpend](https://play.google.com/store/apps/details?id=com.td.myspend&hl=en_US). None is confirmed as the myspend.co.in app, so no rating, install count, update date or review is attributed to it.
- **App Store:** none (the site says Android only). Search returned only [TD MySpend](https://apps.apple.com/us/app/td-myspend/id1088406064) and an unrelated [MySpend by Vadim Holub](https://apps.apple.com/ca/app/myspend-expense-tracker-app/id6446052184).
- **Press, Reddit, social:** none found. Review praise and complaints cannot be reported.

### Inferred (low confidence)
- The "stored on device first" promise is probably an offline cache that syncs to the company's servers, because the policy says all data is uploaded. This is a reading of two documents, not observed behaviour.
- The research-panel and "external research" language suggests the business model is aggregated spending data, with a free price as the hook. The site never says how the company earns money; this is inference from the terms.
- The site's "Total Balance / Income / Expenses" mockup suggests a ledger-first home (totals and history) rather than a "what can I spend today" home. Based on one text description of a mockup.
- The "4.8" and "1 Lakh+" claims have no verifiable listing behind them and should not be quoted as fact.

## Comparison with hisaab•
| Topic | My Spend (per its site and legal pages) | hisaab• |
|---|---|---|
| Question answered | Track spend, stay under category budgets | "How much can I safely spend today?" |
| Safe-to-spend / daily figure | None stated | The hero figure |
| Account | Google sign-in; Gmail optional | None |
| Network | Data uploaded to servers in India; optional Gmail read | None; only the user-triggered Ask AI export leaves the device |
| Analytics / research use | Aggregated research and a voluntary panel | None, ever |
| Budgets | Monthly, per category, with alerts | Daily share from income; no category budgets |
| Recurring | A subscriptions tracker (OTT, gym, insurance) | Recurring income and bills are first-class |
| AI | None stated | Ask AI exports a prompt the user previews |
| Price | Free, model not stated | See `docs/PLAN.md` |
| Deletion | Email request, 48 to 72 hours | On-device, immediate |

**Overlaps:** Android and India only, INR, categories, recurring or subscription awareness, a promise of speed ("in seconds"), and an offline claim.

**Where hisaab• is stronger (with evidence):** no account, no servers, no research clause, so its privacy claim is simple and checkable, whereas My Spend's marketing and its policy disagree. A daily safe-to-spend figure replaces a "balance minus budgets" mental model. Deletion is instant and local.

**Where My Spend may be stronger (unverified):** it offers per-category budget alerts, charts, a subscription list and multi-device sync through the account. hisaab• has chosen not to offer all of these; see `docs/DECISIONS.md` before treating any as a gap.

**Conflicts with hisaab• principles:** Google sign-in, server upload and Gmail reading all break "no network". Tags and category alerts add fields and steps, which would break Add → digits → Next → tile. Whether it uses red and green is unknown, since no screens were seen.

## Implications for hisaab•
1. **Privacy as a contrast, not a slogan.** The strongest lesson is the gap between "stored on your device first" and "all data is uploaded to secure servers". Handing it to `design-content` and `design-brand`: any hisaab• privacy line should be literally true and checkable (no network permission), and should avoid vague trust badges such as "256-bit, same as banks" or "GDPR Ready".
2. **No change to the product.** Nothing here conflicts with a `docs/DECISIONS.md` row, and nothing suggests adding a feature. The risks flagged (accounts, Gmail, panels) are things hisaab• already rules out.
3. **Subscriptions list:** My Spend names OTT, gym and insurance as a headline feature. hisaab• already covers recurring entries (case studies 17 and 18); no new action, but the wording "subscriptions" is what some Indian users search for. Hand to `design-content` as a possible label check only.
4. **Deletion:** the email-and-wait flow is the opposite of case study 23's in-app reset. It supports keeping deletion on-device.

No new principle was added to `principles.md`: the evidence is one company's own pages with no observed behaviour, so confidence is low.

## Open questions
- What is the real Play package id? Ask the requester for the store URL, or open the Play Store in a browser on an Indian account, then fetch it with `curl` and a browser user agent as `sources.md` describes. This pass had no shell, and WebFetch returns an empty Play page.
- How many taps does an entry take, and what does the home screen show? Needs an install or screen recording.
- Does it use red and green for budget state? Needs screens.
- Is "one tap" deletion real in the app, given the email process on the site?
- What are the real rating, installs, last update and recent reviews? Check the Play listing once the id is known.
- Confidence: medium on what the company says (its own pages, read directly); low on the product's actual behaviour and reception (nothing observed or independent).
