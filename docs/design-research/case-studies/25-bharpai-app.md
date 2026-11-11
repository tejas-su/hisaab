# 25. Bharpai: a UPI bill-splitting app

The requester first wrote "bharphai.app", which was a typo. The product is [bharpai.app](https://bharpai.app/). Variant search note: one search for "bharpai app expense tracker" surfaced it ([search result](https://bharpai.app/)); the typo domain does not resolve.

## Question
What is Bharpai, who is it for, and what should hisaab• learn from it or avoid? Date of research: 2026-11-11.

## Method
Desk research, the cheapest method that could change a decision: fetch the site, privacy policy, terms, blog and Play listing; web search for reviews and press. No usage data exists for hisaab to compare. Seen means read on a fetched page. Inferred means my reading.

## Sources and access limits
- Fetched OK: [home](https://bharpai.app/), [privacy](https://bharpai.app/privacy), [terms](https://bharpai.app/terms), [blogs](https://bharpai.app/blogs), [apology post](https://bharpai.app/blogs/an-apology-and-a-rebuild), [what's new post](https://bharpai.app/blogs/whats-new-in-bharpai). WebFetch summarises pages with a small model, so figures below are as it reported them, not read raw.
- Fetched OK on a second pass (2026-11-11, curl with an Android user agent): the [Play listing](https://play.google.com/store/apps/details?id=com.bharpai.app&hl=en_IN), including its full description, stats and all 7 phone screenshots (read as images). No App Store listing exists (the site links Google Play only). No independent reviews, press or Reddit threads were found by [search](https://bharpai.app/). `/pricing` returned 404 (pricing is a section of the home page).
- Visual design is taken from the Play screenshots, which are marketing frames around the app UI, not hands-on use.

## Findings

### What it is and who it is for (seen)
- A bill-splitting app for India: one person pays, everyone else pays their share by scanning a UPI QR code, and friends install nothing ([home](https://bharpai.app/)).
- Audience: friend groups, roommates and travellers splitting dinners, cabs, rent and trips ([home](https://bharpai.app/)). Users must be 18 or older ([terms](https://bharpai.app/terms)).
- Android only, Android 7 and up; no iOS and no payer-side web app ([home](https://bharpai.app/)).
- A solo developer in Bhubaneswar, Sourav Mishra, runs it ([terms](https://bharpai.app/terms)).
- Languages: English and Hindi; Pro reminders also in Hinglish ([home](https://bharpai.app/)).

### Key flow (seen)
1. Payer creates a split and shares a link in the group chat.
2. Each friend taps their name, gets a QR with their exact share, and scans it in GPay, PhonePe, Paytm or any UPI app.
3. Payer watches a settle page ("2/4 settled") and nudges only the pending people.
4. Khata (Pro) keeps a running tab for trips and works out who pays whom.
Source: [home](https://bharpai.app/).
- Receipt scan: camera reads items on the phone, the photo is "never uploaded"; items are tapped onto people with tax and service split ([home](https://bharpai.app/)). The home page never mentions AI.
- Taps to enter an expense: not stated anywhere I could fetch. Unknown.
- Safe-to-spend or daily figure: none described. It is a settle-up tool, not a budget tool (inferred from [home](https://bharpai.app/)).

### The core promise broke, and the founder said so (seen)
- The original pitch was a link that opens the friend's UPI app with the exact amount prefilled. UPI apps now reject person-to-person payments opened from links, so the payment fails ([apology post](https://bharpai.app/blogs/an-apology-and-a-rebuild)).
- The app was rebuilt around QR: one QR if everyone owes the same, a named QR per person if shares differ, one extra tap ([apology post](https://bharpai.app/blogs/an-apology-and-a-rebuild)).
- The post's own lessons: verify platform and regulatory assumptions before making them the pitch; receipts in the real world are messier than test data ([apology post](https://bharpai.app/blogs/an-apology-and-a-rebuild)).
- Some search-result snippets still describe the old link-prefill pitch ([search](https://bharpai.app/)); the current home page says QR.

### Privacy (seen)
- Cloud-backed, not offline-first. Account is email plus a one-time code; it stores email, the splits (titles, amounts, names), display name, UPI IDs, push token and group (khata) data on Vultr servers in Mumbai, with a local copy so it works offline ([privacy](https://bharpai.app/privacy)).
- Does not collect bank credentials, OTPs, PINs or receipt images; no SMS reading or bank linking is mentioned; no ads, no third-party profiling analytics; aggregate usage counts come from its own server ([privacy](https://bharpai.app/privacy)).
- Third parties: Vultr, Google Workspace (email), Firebase Cloud Messaging, Google Play and RevenueCat, Vercel, Google ML Kit, Cloudflare Turnstile ([privacy](https://bharpai.app/privacy)).
- Account deletion is available in-app and at /delete-account, with a named grievance officer ([privacy](https://bharpai.app/privacy)).
- Trust copy: "Money never touches our servers", "No ads. No data sale.", "We never ask for your OTP, PIN, or bank details", and a warning that links on other domains are fake ([home](https://bharpai.app/)).

### Pricing (seen, with a conflict)
- Free: unlimited splits (up to 100 people), settle pages, QR cards, receipt scanning, ledger, manual reminders, partial payments ([home](https://bharpai.app/), [what's new](https://bharpai.app/blogs/whats-new-in-bharpai)).
- Pro: ₹19 a month or ₹149 a year; adds Khata, templates, rosters, recurring splits, widget, auto-remind with quiet hours, firm or funny nudge tones, pay-by dates, CSV export ([terms](https://bharpai.app/terms), [what's new](https://bharpai.app/blogs/whats-new-in-bharpai)).
- Conflict: one search snippet said "one-time ₹49" ([search](https://bharpai.app/)). The site's current terms and blog say ₹19/₹149 a year. Treat ₹49 as an older price; I could not confirm.

### Copy and tone (seen)
- Playful, group-chat voice with Hinglish: "bro, paise?", "Paid. In. Full." ([home](https://bharpai.app/)).
- Reminders: polite by default; firm or funny are Pro; the user previews the exact WhatsApp message before it sends; never sent at night ([what's new](https://bharpai.app/blogs/whats-new-in-bharpai)).
- Visual: receipt-style bill mockups, chat mockups, a scrolling ticker, QR graphics ([home](https://bharpai.app/)). Palette not observed.

### Play listing (seen)
- Category Finance; **10+ downloads**; no rating or reviews shown yet; in-app purchases; updated 10 Nov 2026 ([Play](https://play.google.com/store/apps/details?id=com.bharpai.app&hl=en_IN)). It is a very new app with almost no users, so there is no reception to judge.
- Short description: "Split a bill, share one link. Friends pay by UPI, no app, no signup."
- The description opens on the user, not the feature: "Bharpai is for the one person who paid the bill."
- Split modes: equally, by item, by percentage, by shares, or by exact amounts. Friends can report a partial payment. Foreign bills convert at a locked rate. Works in Hindi, on the app and on the friends' pages.
- The payer marks a payment received "when the money lands in your bank". The settle page says "bank statement is the source of truth", so the app never claims to know a payment happened.
- Trust copy repeats from the site: "no wallet, no escrow, no payment gateway", never asks for "an OTP, a PIN, or bank details", and "anyone who does while claiming to be Bharpai is not us".
- The Data safety section exists, but its contents load on demand and were not read.

### Visual design (seen in the 7 Play screenshots)
- **Strictly monochrome:** black, white and light-grey surfaces. No brand colour, no red or green, no category colours anywhere in the app UI.
- **State without colour:** split status pills are *Settled* = solid black fill, *Partial* = black outline, *Unpaid* = grey fill. Progress is a black bar on a grey track ("2/4 settled"). This is the same fill/outline language hisaab uses for state.
- **Type:** a geometric grotesk with a single-storey "y" and "g" for headings and amounts, a plainer sans for body text. Amounts are large and bold, Indian grouping (₹47,650, ₹16,834).
- **Layout:** one hero summary card per screen, light grey with a big number ("Still to collect ₹25,550", "You get back ₹16,834", "Collected this month / Still pending"), then a list of outlined rounded cards. Avatars are black circles with a white initial.
- **Icons:** thin line icons (mountain for a trip, cutlery for dinner, trophy for turf, house for rent). On the split screen every top-bar icon has a text label (QR, Refresh, Archive, Delete).
- **Wordmark and icon:** "भरpai", Devanagari "भर" plus Latin "pai". The launcher icon is a white "भर" on black.
- **Screens shown:** Ledger (who owes you, per person), Khata trip ("How you get back ₹16,834", you paid minus your share, line by line), Splits home, one split's settle page, receipt scan with items and CGST/SGST split proportionally, the friend's pay sheet (QR, Save QR, Copy UPI ID, Copy amount, "Open a UPI app instead"), and a home-screen *Quick splits* widget (rent, turf, wifi, each with a Split button).
- **Microcopy:** warm and specific: "₹16,400 waiting on Dev, no rush, but you know." and "On this phone: tap the code to save it, then open your UPI app and scan it from gallery."

### Reviews (not found)
- No Play rating or reviews exist yet (10+ downloads). A search found the founder's own posts about launch only ([search](https://bharpai.app/)). Praise and complaints: unknown. Confidence in any quality judgement: low.

## Comparison with hisaab•
| | Bharpai | hisaab• |
|---|---|---|
| Job | Collect money from friends after a shared spend | Answer "how much can I safely spend today?" |
| Data | Account, cloud servers in Mumbai, local copy | Offline, no account, no network |
| Money movement | Generates UPI QR; never holds money | None |
| Daily figure | None | Core |
| AI | Not mentioned (receipt OCR on device) | Ask AI exports a prompt the user previews |
| Tone | Playful, Hinglish | Plain, banned words list |
| Colour | Monochrome; state by fill, outline and grey | One signal colour (marigold); state by fill, outline, hatch and words |
| Hero | One big number per screen in a grey card | Day Blocks and the hero sentence |
| Widget | Quick splits for regular bills | None yet |
| Platform | Android, Hindi/English | Android, INR |
Overlap is small: different job, adjacent audience (UPI-first Indian Android users). They could be used together. Source for Bharpai column: pages cited above.

## Implications for hisaab• (hand to design-product; DECISIONS.md wins)
- No conflict with any D-row found; nothing here changes a decision.
- Do not build splitting or collecting: it needs a network, accounts and UPI integration, against the privacy rule. Mention only if a "who owes me" idea ever comes up.
- Platform-dependency lesson: Bharpai's pitch depended on UPI behaviour it did not control and broke. hisaab reads no SMS and links no UPI, so it avoids this class of risk. Worth stating in the Play listing's privacy copy (hand to design-content).
- Trust copy pattern: short "we never ask for X" lines next to the money claim. hisaab's equivalent is "no network, no account" stated plainly (inferred; hand to design-content).
- Nudge preview: showing the exact message before it is sent is a good pattern for the Ask AI export, which hisaab already previews.
- Colour-free state is shipping elsewhere: Bharpai's Settled / Partial / Unpaid pills (solid, outline, grey) are a live example of the no-red/green rule hisaab already follows. Supports the existing decision; no change.
- Honest certainty: "bank statement is the source of truth" admits what the app can't know. A comparable line could help wherever hisaab's figure depends on what the user entered (inferred; hand to design-content, not a recommendation yet).
- Specific, warm microcopy ("₹16,400 waiting on Dev, no rush, but you know.") names a person and an amount in one sentence, close in spirit to hisaab's hero sentence (inferred).
- A home-screen widget for regulars is a pattern to note if a hisaab widget is ever considered. It is out of scope today.

## Open questions
- Ratings and reviews: none exist yet (10+ downloads); revisit later.
- Data safety contents (load on demand; need a browser).
- Taps to enter a split: needs hands-on use.
- Is ₹49 an older price or an error?
