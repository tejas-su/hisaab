# 11. Attention and memorable moments: peaks, ends and the experience curve

## Question
The owner read a blog that drew an experience as a graph: start low, spike in the middle, end smooth and memorable. Three questions follow:
1. What does that curve refer to, and is its shape what the research says?
2. What makes an experience memorable and unique without nagging, loops or extra colour?
3. Where should the low, the peak and the end sit in each Hisaab journey, and how often is each seen (the habituation risk)?

## Method
**Desk research only** (2026-10-29). The question is about what the evidence says, so reading it is the cheapest method that can change a decision. No users were tested, and no usage data exists (Hisaab has no analytics). Every claim below links to its source. Where only an abstract or a secondary summary was readable, it says so.

The confidence scale:
- **High:** a meta-analysis, a randomised trial, or several replications.
- **Medium:** single lab studies, or a well-documented practitioner source (NN/g, Jakob Nielsen).
- **Low:** company blogs that report their own numbers, case-study blogs, and books' anecdotes.

The research in this study cannot settle the recommendations by itself. They need the follow-up under *Open questions*: a diary study across a payday.

## Findings

### 1. The blog's curve is two ideas merged, and "start low" comes from neither
- **The peak-end rule.** People judge a past episode mostly by its most intense moment and its end, not by the sum or the average of every moment ([Laws of UX](https://lawsofux.com/peak-end-rule/); [Kahneman, TED 2010](https://www.ted.com/talks/view/id/779)). The rule says *where* memory is weighted. It draws no curve and says nothing about the start: neither Laws of UX nor [Jakob Nielsen's summary](https://www.uxtigers.com/post/peak-end-rule) mentions the opening.
- **The story arc.** "Low start, climax in the middle, resolution at the end" is Freytag's pyramid (exposition, rising action, climax, falling action, dénouement). Freytag based it on Greek and Shakespearean drama, and modern stories usually move the climax near the end ([Jericho Writers](https://jerichowriters.com/what-is-freytags-pyramid/), [Videomaker](https://www.videomaker.com/article/f04/17174-dramatic-structure-story-arc-freytags-pyramid)). It is a writing convention, not a finding about memory.
- **What the evidence says about the start.** A meta-analysis of 174 effect sizes found the peak-end effect was large (r ≈ 0.58). It was stronger than the effect of the **first episode**, of the trough, of the trend and of the variability ([Alaybek et al. 2022, OBHDP 170](https://ideas.repec.org/a/eee/jobhdp/v170y2022ics0749597822000334.html), abstract read; full text paywalled). So the start carries less weight than the peak and the end. Nothing says it should be *low*.
- **The one finding that comes close.** When outcomes are framed as a sequence, people prefer sequences that improve over time ([Loewenstein & Prelec 1993, *Psychological Review*](https://www.cmu.edu/dietrich/sds/docs/loewenstein/PrefSeqOutcomes.pdf)). That supports "end higher than you start". It does not support lowering the start on purpose.
- **First contact is the exception.** On first contact, the start does matter. People judge a page's visual appeal within about 50ms, and that impression colours later judgments of credibility and usability, the halo effect ([Lindgaard et al. 2006, *Behaviour & IT* 25](https://makinggood.ac.nz/l/lindgaard,-g,-fernandes,-g,-dudek,-c,-brown,-j-(2006)-attention-web-designers-you-have-50-milliseconds-to-make-a-good-first-impression!-behaviour-it,-25,-115–126); abstract and press coverage only). In list memory, the first and last items are recalled best: primacy and recency ([Murdock 1962, DOI 10.1037/h0045106](https://modeldb.science/citations/230974); [NN/g, Primacy effect](https://www.nngroup.com/videos/primacy-effect/)).

**Verdict: a simplification with one wrong part.** "Peaks and ends dominate memory" is well supported (high confidence). "End smooth" is supported if *smooth* means a gentle, better final stretch rather than an abrupt stop (high). "Spike in the middle" is storytelling: the peak counts wherever it falls (medium). "Start low" has no support. On a first contact the start should be clear and good, because first impressions colour everything after them (medium).

```
 The blog's shape                       What the evidence supports
 feel                                   feel
  ▲         ╱╲                           ▲   peak (anywhere) ─┐      good,
  │        ╱  ╲___                       │        ╱╲          │   ┌─ settled end
  │       ╱       ‾‾‾‾‾‾‾ smooth end     │  ‾‾‾‾‾╱  ╲____     │  ╱‾‾‾‾
  │______╱  ← "start low"                │  clear start  ╲___╱  ← fix the pit
  └──────────────────────▶ time          └──────────────────────────▶ time
                                          the start weighs least; the peak and
                                          the end weigh most; length barely counts
```

### 2. Peak-end and duration neglect: the evidence and its limits
- **Cold hand.** People held a hand in 14 °C water for 60 s. Another trial ran the same 60 s, then 30 s more while the water warmed to 15 °C. A significant majority chose to repeat the longer trial, so they picked more total pain with a better end ([Kahneman, Fredrickson, Schreiber & Redelmeier 1993, *Psychological Science* 4(6)](https://www.psychologicalscience.org/journals/psychological-science/j.1467-9280.1993.tb00589.x/)). The often-quoted "69%" was not confirmed from the full text.
- **Film clips.** Duration had only a small effect on how pleasant or aversive clips were remembered ([Fredrickson & Kahneman 1993, *JPSP* 65](https://bear.warrington.ufl.edu/brenner/mar7588/Papers/fredr-kahneman-jpsp1993.pdf)).
- **Colonoscopy (n = 682, randomised).** For half the patients the scope stayed still for a short time at the end. Those patients rated the final moments less painful (1.7 vs 2.5 out of 10). They rated the whole procedure less unpleasant (4.4 vs 4.9). Over a median of 5.3 years, they were slightly more likely to come back for a repeat procedure (OR 1.41, p = 0.038) ([Redelmeier, Katz & Kahneman 2003, *Pain* 104, PMID 12855328](https://pubmed.ncbi.nlm.nih.gov/12855328/)). This is the strongest real-world evidence: a better end changed whether people came back.
- **Limits:**
  - The peak-end score predicted judgments only about as well as the plain average of every moment ([Alaybek et al. 2022](https://ideas.repec.org/a/eee/jobhdp/v170y2022ics0749597822000334.html)). It is a strong weighting, not a law.
  - **Day-long, many-episode experiences did not follow the rule** ([Miron-Shatz 2009, *Emotion* 9](https://worlddatabaseofhappiness.eur.nl/publications/evaluating-multiepisode-events-boundary-conditions-for-the-peak-end-rule-14870); abstract-level summary only). A pay cycle of short daily opens is exactly this kind of experience.
  - For holidays, the "most memorable 24 hours" predicted remembered happiness better than the peak or the end did ([Kemp, Burt & Furneaux 2008, via Wikipedia](https://en.wikipedia.org/wiki/Peak%E2%80%93end_rule); primary not fetched).
  - Unmet expectations override the end ([Carmon & Kahneman, via Wikipedia](https://en.wikipedia.org/wiki/Peak%E2%80%93end_rule); primary not fetched).
- **Nielsen's practitioner reading:**
  - Fix the worst moment first, then build one genuine peak tied to the user's accomplishment, not to a brand animation.
  - Never end a flow on an error.
  - "Overusing celebrations flattens peaks".
  - The rule describes how one episode is remembered. A product that frustrates people every day piles up bad memories that no end can offset ([UX Tigers](https://www.uxtigers.com/post/peak-end-rule)).

**Confidence:** high for single episodes of seconds to minutes. Low for a month of short, repeated uses.

### 3. *The Power of Moments* (Chip and Dan Heath, 2017)
- **Four elements.** Defining moments carry at least one of elevation, insight, pride or connection ([Heath Brothers](https://heathbrothers.com/the-power-of-moments/); the publisher's page gives no definitions).
- **Three kinds of moment to manage** ([Fin24 review](https://www.fin24.com/Opinion/book-review-creating-those-memorable-moments-20171019), [Shortform](https://www.shortform.com/blog/defining-moments-in-life/)):
  - **Transitions** are to be marked. The authors call them the most undervalued moments.
  - **Milestones** are to be commemorated.
  - **Pits** are to be filled. Disney fills its queues with things to look at and tells people how long the wait will be.
- **Elevation from a small surprise.** At the Magic Castle Hotel, a red poolside phone answers "Popsicle Hotline", and staff in white gloves bring an ice lolly on a silver tray, free ([Stanford GSB](https://gsb.stanford.edu/insights/power-free-popsicle)).
- **Confidence:** low to medium. This is a book of well-chosen case stories built on the peak-end research, not new evidence. Its value is as a checklist: mark transitions, fill pits, and find the insight and the pride.

### 4. Attention, habituation and rewards
- **Habituation.** A repeated stimulus draws a smaller response. The more often it comes, the faster the response falls. Withhold it for a while and the response at least partly comes back (spontaneous recovery) ([Rankin et al. 2009, *Neurobiol. Learn. Mem.* 92](https://pmc.ncbi.nlm.nih.gov/articles/PMC2754195/); wording via the PMC text and later citations).
- **Hedonic adaptation.** Good and bad circumstances lose their emotional intensity over time ([Frederick & Loewenstein 1999](https://stafforini.com/works/frederick-1999-hedonic-adaptation/)).
- **What this means for a daily app.** A flourish seen 8 times a day fades fastest. A flourish seen once a day recovers overnight.
- **Delight decays into expectation.** In the Kano model, a "delighter" becomes an expected "performance" feature, then a "basic" one ([arXiv, Kano in app reviews](https://arxiv.org/pdf/2303.03798)).
- **Surface vs deep delight.** NN/g separates *surface* delight (animation, microcopy), which fades fast and can seem gimmicky, from *deep* delight. Deep delight needs a product that is functional, reliable and usable first ([Fessenden, NN/g 2017](https://www.nngroup.com/articles/theory-user-delight/)). "You cannot impose joy" ([NN/g 2022](https://www.nngroup.com/articles/pillars-user-delight/)).
- **Variable rewards are the slot-machine step of the Hook model.** Eyal himself later admitted the technique had a "dark side" ([Fortune 2020](https://fortune.com/2020/01/21/a-tale-of-two-books-how-app-makers-hooked-us-and-how-we-might-resist)). A behavioural-science critique argues that "variable" adds nothing to "reward" ([The Behavioral Scientist](https://www.thebehavioralscientist.com/articles/hooked-how-to-build-habit-forming-products-is-wrong)). Utilities such as Google Maps build habits with no variability at all ([Big Think](https://bigthink.com/?p=54491)).
- **Variable rewards in Indian fintech.**
  - Google Tez (now Google Pay) moved from a fixed referral payout to scratch cards that "most of the time" won nothing ([Manas Saloi 2017](https://manassaloi.com/2017/08/15/tez-50-million-sauce.html)).
  - CRED's coins, jackpots and draws are read by commentators as variable-ratio reinforcement ([Markhub24](https://www.markhub24.com/post/cred-gamified-rewards-exclusivity-architecture-and-credit-behavior-as-a-business-model); a blog, low confidence). CRED has published no design rationale.
- **Indian law.** The CCPA's *Guidelines for Prevention and Regulation of Dark Patterns, 2023* list 13 patterns, including **nagging** and **confirm shaming** ([SCC Online](https://www.scconline.com/blog/post/2023/12/04/ccpa-notifies-guidelines-for-prevention-and-regulation-of-dark-patterns-2023-legal-news/), [Deloitte](https://www2.deloitte.com/content/dam/Deloitte/in/Documents/tax/in-tax-gbt-the-guidelines-for-prevention-and-regulation-of-dark-patterns-noexp.pdf)). The official notification wasn't fetched, so the annexure's exact wording on nagging is unverified.
- **Duolingo's streak is the counter-example.** Duolingo says that as a streak grows, motivation shifts to *loss aversion*. It also reports that its streak animation raised day-7 retention of new learners by 1.7%, and that allowing two streak freezes raised daily actives by 0.38% ([Duolingo blog 2022](https://blog.duolingo.com/how-duolingo-streak-builds-habit/)). These are self-reported numbers with no method given. Hisaab rejects streak shame (UI_DESIGN §12) and nagging (owner's engagement rule), so Duolingo's loss-aversion lever is off the table. What transfers is its *slack*: a freeze forgives a missed day.

### 5. Emotional design and signature moments: the transferable principle, not the style
Norman's three levels are *visceral* (looks, instant), *behavioural* (how it feels in use) and *reflective* (meaning and self-image, memory) ([Wikipedia, *Emotional Design*](https://en.wikipedia.org/wiki/Emotional_Design); NN/g maps delight onto all three, [NN/g 2022](https://www.nngroup.com/articles/pillars-user-delight/)). The book itself wasn't read; secondary sources only.

| Product | What people remember | Transferable principle | Source and confidence |
|---|---|---|---|
| Duolingo | The *Session complete* screen with fireworks. It now shows first and loads data behind it, cutting perceived end latency by 60%+ | **The end of a task is the reward slot, and it must be instant.** A loader at the end replaces the peak with a pit | [Duolingo engineering blog](https://blog.duolingo.com/android-app-performance/); low (self-reported) |
| Monzo | *Year in Monzo* tone: a "kindly relative", not a "mean older sibling". The harsher "savage" mode is opt-in, and lines that were too harsh were cut | **A recap of someone's money is reflective. Default to kind, and make teasing opt-in or leave it out** | [Monzo blog](https://monzo.com/blog/writing-year-in-monzo-2024); medium |
| Spotify Wrapped, Year in Monzo | A once-a-year recap of the user's own data, made to share | **A long, many-episode experience gets its remembered end from an explicit recap, not from the last session** | [Brand Hopper](https://thebrandhopper.com/2025/06/10/a-case-study-on-spotify-wrapped-the-storytelling-phenomenon/) (marketing blog, low); the Monzo post above |
| Apple Pay | A tick, a sound and a haptic on a successful payment | **Confirm completion on several channels at once, in under a second, and then stop** | [Apple HIG, Playing haptics](https://developer-mdn.apple.com/design/human-interface-guidelines/patterns/playing-haptics) ("confirmation of an Apple Pay transaction"); medium |
| Stripe | Success pages: a clear heading, a check or a small animation, then what happens next | **A good end says it's done, shows what happened, and points to what's next** | [Stripe guide](https://stripe.com/resources/more/payment-successful-pages); medium (vendor guidance) |
| Linear | Speed as the feel: "If something takes more than a few hundred milliseconds, we try to make it faster" | **For a frequent action, speed *is* the delight (behavioural level), so add nothing to it** | [linear.app](https://linear.app/now/practices-for-building-linear-is-now-open-for-all) via search snippets (the page wasn't fetched); low |
| Headspace | A breathing exercise as the smallest first step | **A smaller first step lifts early activity, but didn't move week-2 retention or meditation days.** The first peak isn't enough on its own | [raw.studio](https://raw.studio/blog/how-headspace-designs-for-mindfulness/), [Irrational Labs](https://irrationallabs.com/case-studies/headspace-doubled-course-starts/); low to medium |
| Facebook "7 friends in 10 days" | The "Aha moment" metric | **An "Aha" is the point where the product's value becomes visible, found by comparing users who stayed with users who left.** Correlation, not cause | Secondhand accounts of a talk by Chamath Palihapitiya ([Airtribe](https://airtribe.live/blog/product-growth-lessons-from-facebook)); low |
| CRED | Rewards, jackpots, NeoPOP drama | **Not transferable.** Variable rewards conflict with no-nagging, and the look was rejected in case study 10 | See §4; low |
| Revolut | — | Not researched: no primary design source was found in the time spent. Don't cite it without one | — |

**Hisaab's own "Aha" is already designed.** In onboarding, the salary becomes "That's about ₹1,500 a day" and the blocks appear as the user types (UI_DESIGN §5.1). In Heath's terms that is an *insight* moment. The product's single question is answered before onboarding has finished.

### 6. Ending well in an app with no natural end
- **The Zeigarnik effect is weak.** A 2025 meta-analysis found *no* memory advantage for unfinished tasks. It did find a general tendency to *resume* them, the Ovsiankina effect ([Ghibellini & Meier 2025, *Humanities and Social Sciences Communications* 12](https://ideas.repec.org/a/pal/palcom/v12y2025i1d10.1057_s41599-025-05000-w.html); abstract only). "Leave a loop open so they come back" has little evidence behind it, and in Hisaab it would also count as nagging.
- **The goal gradient is real but double-edged.** People speed up as they near a goal. A 12-stamp card with 2 stamps pre-filled was completed faster than a 10-stamp card ([Kivetz, Urminsky & Zheng 2006, *JMR* 43](https://business.columbia.edu/faculty/research/goal-gradient-hypothesis-resurrected-purchase-acceleration-illusionary-goal)). Hisaab's goal is reaching payday with money left. Visible progress toward payday helps, but "illusory progress" would be a misleading dark pattern for money.
- **A daily utility has two natural ends:**
  - **the end of each act:** the save settling;
  - **the end of each cycle:** payday.

  The day is a third, weaker one. Its end can only be seen at the *next* morning's first open, because nobody opens a money app at midnight to watch a day close.

## Implications for Hisaab

### The two curves
**One session** (a typical open: look, log one spend, leave; about 10 s):
```
 feel
  ▲                  ① answer                       ③ END = PEAK
  │                  (number in 2 s)                 drain + trail, number rolls,
  │      ┌──────────╮                             ╭── success haptic, settles calm
  │      │          ╰──╮  ② effort: kept flat  ╭──╯‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
  │──────╯             ╰─────────────────────────╯
  └─ open ── fill-in ── read ── Add · digits · Next · tile ── drain ── close ──▶
     start: CLEAR, not low      no peak here: speed is the delight
```
In a 10 s session the peak and the end should be **the same moment**: the visible consequence of the user's own act (the drain, D91). Nothing should follow it. The last frame is the answer, settled.

**One pay cycle** (30 days):
```
 feel
  ▲ payday: fresh blocks                                   payday: CLOSE old,
  │ ╭──╮      underspend morning (lift)                    then OPEN new
  │ │  ╰──╮      ╭╮            ╭╮                          ╭──── "October: you kept ₹4,300"
  │ │     ╰──────╯╰──╮   ╭─────╯╰──────╮                   │ ╭── new blocks slide in
  │ │                ╰╮ ╭╯             ╰──╮   month-end    │ │
  │ │      overspend ─╰─╯ (pit: fill it)   ╰─ squeeze ─────╯ │
  └─┴──────────────────────────────────────────────────────┴─┴──────────▶ days
   start (high, by nature)    many small daily episodes      the remembered END
```
The cycle starts high on its own: payday is good news. It tends to *end* low, because money is tightest just before payday. The predictable risk is that a user remembers a month of Hisaab as the squeeze. Evidence for peak-end across a month is weak (Miron-Shatz). The cheapest hedge is still to give the cycle an explicit end that lands *after* the squeeze: the payday-morning recap.

### Journey by journey

| Journey | How often it's seen | Habituation risk | Low · peak · end | One recommendation (within marigold-only, no red/green, no loops, no nagging, reduced motion, "5-year-old") |
|---|---|---|---|---|
| **First-run onboarding** | Once | None | Low: none on purpose. The start must be clear (first impressions). Peak: the live "₹1,500 a day" preview (insight). End: the hero assembles, today's block lights, success haptic (UI_DESIGN §5.1) | **Keep it as designed. It is the one place for the boldest motion.** Make sure the Done hero shows the *same* daily figure the step-1 preview promised, so the insight is confirmed, not contradicted. The bills step is the pit (effort): keep **Skip** big. Reduced motion: the hero is simply there |
| **Daily open of Home** (morning tear) | 1–10× a day; the *first* open is once a day | **High** for any flourish on every open; low for once a day | First open: end of yesterday, then today begins (a transition). Later opens: no curve, just the answer | **Run the tear, the sheen and any note only on the first open of the day; later opens show the answer without decoration** (rec. 1). The tear is the day's transition, the one moment that closes yesterday. Its words carry yesterday's result plainly, and marigold moves to today's unit. Reduced motion: crossfade. **Conflicts with D91 and D106**, which run the fill-in and sheen on *every* appearance |
| **Add flow** | Several times a day | Highest | No peak in the middle; the end is the peak | **Add nothing.** Keep the end constant: the same drain, trail, roll and haptic every time, never varied or randomised. Speed is the delight (Linear, NN/g deep delight). Protect NFR-1 (drain begins ≤ 400ms) and the 4-tap path |
| **Underspend morning** | A few times a cycle | Medium | Peak: elevation plus pride ("you saved ₹300 yesterday, so every day got ₹37 more") | Show it **once, on the first open** after the underspend, and only after the blocks have grown (cause, then words, as mockup 15 #5). Praise the user's act ("you saved"), never the app. Don't repeat it on later opens that day |
| **Overspend "It happens"** | Occasional | Low, but it's a *pit* | The pit. The session must **end** on the plan, not on the deficit | **Fill the pit: the last thing seen is a stable next step.** The current copy already ends on the spread ("…spread across the next 3 days"). Add the range line's still-true fact when it holds ("still lasts till payday", the open question in mockup 15) so the episode ends on something steady (rec. 3). No shake, no red, kindly-relative tone (Monzo). Outline and hatch carry the state |
| **Payday / cycle end** | Monthly | Low | The cycle's end and the next one's start, on the same morning | **Close, then open: one kind line about the cycle that ended, before the new blocks slide in** (rec. 2). Neutral when the cycle went over ("October's done. A fresh month starts today."), never a verdict. The share card stays v1.1 (SPEC Q4) |
| **Ask AI export** | Monthly or less | Low | Low: choosing (effort). End: the handoff, which happens *outside* the app | The in-app end is the moment before the tap: the preview and "Nothing leaves your phone until you share it" (FR-AI-3) are the closure, so keep them above the key. When the user comes back from ChatGPT, show nothing new: no "How did it go?" (that would be a loop) |

## Recommendations, ranked
1. **Make the first open of each day the daily moment, and keep every later open quiet.** The tear, the sheen and the underspend note run once, on the day's first open. Every other appearance shows the settled answer, with at most the functional fill-in.
   - Why: habituation is fastest for frequent stimuli and recovers when withheld (Rankin). Overused celebrations flatten peaks (Nielsen). Heath says to mark transitions, and the day boundary is Hisaab's most frequent one.
   - Cost: a stored "last opened day", which case study 05 avoided to keep things simple.
   - Conflict: D91 (fill-in on every appearance) and D106 (sheen whenever the hero appears). `DECISIONS.md` wins until design-product adds a row.
2. **Give the pay cycle an explicit end on payday morning: close the old cycle in one kind line, then open the new one.**
   - Why: a month is many episodes, and peak-end doesn't reliably cover it (Miron-Shatz). Products that want a long stretch remembered end it with a recap (Year in Monzo, Wrapped). Without one, the last thing the user saw of the cycle is the month-end squeeze.
   - Evidence: low confidence. It needs the diary study below.
3. **End the overspend moment on a stable fact, not the deficit.** The over state's last line says what is still true ("still lasts till payday" when BR-7 allows it) or what happens next (the spread), in the kind voice.
   - Why: never end on an error (Nielsen). Fill the pits (Heath). A better end changed whether people came back (Redelmeier 2003).
   - Needs: the open BR-7 range-line wording, which goes to design-content.

## What we don't recommend
- **A deliberately low start** (the blog's curve). There is no evidence for it, and onboarding's first screen sets the halo.
- **Streaks, open loops or "come back" prompts.** The Zeigarnik effect fails to replicate, nagging is a CCPA dark pattern, and both break the owner's no-nagging rule.
- **Random or variable rewards** (scratch cards, surprise animations). Rewards stay predictable and are earned by the user's own act.
- **Asking for a rating at a peak.** Nielsen: it inflates scores and hides problems.

## Risks
- **Desk research only.** The peak-end evidence is mostly about single lab or clinical episodes lasting seconds to an hour. How a whole pay cycle in a phone app is remembered is untested anywhere we found.
- Recommendation 1 trades the teaching value of a fill-in on every appearance (case study 05's re-test) for less habituation. A user who opens the app three times a day sees the "tank" fill only once.
- A once-a-day moment depends on `Clock` and a stored date. A timezone change or a phone left open overnight could show it twice or not at all. That is an edge case for SPEC.

## Open questions
1. **Diary study across a payday (1–2 weeks, 5–8 UPI-first users, mixed literacy, low-end Android).** Questions: which moments people mention unprompted, whether the morning tear still registers in week 2, and whether the cycle is remembered as the squeeze or the recap. Use only in-app counts the participant can see. No telemetry.
2. **5-user think-aloud on the overspend moment,** with and without the "still lasts till payday" line. Measure: can they say what to do next, and their SEQ.
3. Should the first open of the day still fill in the block on later opens (to teach the tank), with only the decoration limited to once a day?
4. What does the payday recap say when the user logged little that cycle? Leave it out below some number of logged days?

## Handoff
- **design-product:** recommendations 1–3. Recommendation 1 conflicts with D91 and D106.
- **design-motion:** once-a-day gating of the tear and sheen.
- **design-content:** the payday close line and the over-state range line.
- **design-validation:** open questions 1–2.
