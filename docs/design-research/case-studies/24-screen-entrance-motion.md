# 24. Screen entrance and micro-motion: making the app feel alive

## Question
The owner wants the app to feel alive. When a screen opens, its contents should arrive with small motion (a list that cascades in, for example), and small interactions should answer the finger. Three questions follow:
1. What does the evidence say about entrance motion and staggered lists: when it helps, how fast it should be, and when it hurts?
2. How does that fit the motion Hisaab already has (D14 springs, D91 drain and fill, D106 sheen, "delight scales inversely with frequency")?
3. Which screens and moments should get entrance motion or micro-motion, and which must stay still?

## Method
**Desk research only** (2026-11-06), plus a read of the current code. No users were tested. Every claim links to its source. Where a page didn't load, this study says so.

Confidence:
- **High:** a peer-reviewed experiment, or a platform guideline that states a rule outright.
- **Medium:** NN/g, or a well-known practitioner's published rules.
- **Low:** third-party summaries and blog posts.

## What the app does now
The app already has a lot of motion, but almost all of it is on the hero. Screens themselves arrive with a hard cut.

| Moment | Now | Source |
|---|---|---|
| App launch | An animated splash, then Home | UI_DESIGN §3.7 |
| Home appears | Today's bar fills in on `calm` (0.55s), and the sheen crosses the hero once (1.4s) | D91, D106 |
| Home ⇄ Spends on a phone (dock) | **A hard cut.** `AppShell` swaps the screen through a `KeyedSubtree` with no transition | `lib/app/app_shell.dart` |
| Settings, Bills, Ask AI, bill editor | Android's predictive-back page transition | `hisaab_theme.dart`, `routes.dart` |
| Spends while loading | **Nothing is drawn** (`SpendsLoading() => []`), then every card appears at once | `spends_page.dart` |
| Home while loading | A raised, etched skeleton of the hero | D106 |
| After a save | The tray closes, the bar's yellow pulls back, the number rolls | D91, D114 |
| A new row in the Today list | **Appears at once.** The `standard` token lists "list insert" as a use, but no `AnimatedList` exists in `lib/` | UI_DESIGN §6 |
| Press | Scale 0.97 with the ink lip collapsing | §6 |
| Bill sheet stamp | Lands with a squash 260ms after the sheet opens | §5 |
| This week bars | Rise from the baseline, today's first, 7% later per day away | D111 |

So the hero feels alive, and the rest of the app feels static. Two things stand out: the dock's hard cut, and Spends popping in from a blank screen.

## Research

### 1. Frequency decides almost everything (high)
Every source agrees on one rule: the more often people see a motion, the shorter and quieter it must be, down to none.
- **NN/g:** "the more frequent the animation, the more subtle and shorter you'll want it to be." Look for "the shortest time that an animation can take without being jarring". It is "far more common for animations to be too long than too short". At 500ms, animation "start[s] to feel like a real drag" ([NN/g, *Executing UX Animations: Duration and Motion Characteristics*](https://www.nngroup.com/articles/animation-duration/)).
- **Apple HIG:** "In apps, generally avoid adding motion to UI interactions that occur frequently." It also says to add motion "purposefully", to make it optional and never the only channel, and to "let people cancel motion": don't make people wait for it ([HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion.md)).
- **Emil Kowalski:** "How often users will see an animation is a key factor in deciding whether to animate or not." Delight is a valid purpose only when the motion is rarely seen. UI animation should stay under 300ms ([*You don't need animations*](https://emilkowal.ski/ui/you-dont-need-animations)).
- **Rauno Freiberg:** after "seeing the same animation for the hundredth time", motion becomes cognitive load. Removing it from frequent actions made him feel "like I was moving much faster" ([*Invisible details of interaction design*](https://rauno.me/craft/interaction-design)).

Hisaab already follows this (UI_DESIGN §6, "Delight scales inversely with frequency"). The new question is where each *screen* sits on that scale.

### 2. Stagger: what it is for, and its budget (medium)
- **Material (M1) choreography:** "When multiple new surfaces are created at the same time, quickly stagger the appearance of each." "List items have a slightly staggered entrance." Begin each item "no more than 20ms apart", and "do not wait for each item to fully animate before introducing the next". Revealing everything at once "is overwhelming and eliminates a clear focus". Grids fill left to right, top to bottom. "Too much animation during surface creation is distracting" ([M1 choreography](https://m1.material.io/motion/choreography.html)). The M2 and M3 motion pages returned only a title to the fetch tool, so the current Material numbers weren't read.
- **Emil Kowalski's `choreograph` rules:** in product UI, 30–80ms between items with the group done in about 300ms. "Never let item 20 wait 20× the delay": stagger the first handful, and let the rest arrive with the last. Allow 100–150ms steps only for first-run or marketing moments. He sets several limits:
  - "Never stagger on high-frequency or keyboard-triggered UI." Menu rows, tab content and list rows should appear together.
  - "One entrance per container": animate the card or its children, never both.
  - Exits are never staggered.
  - Under reduced motion, keep the opacity, drop the movement and the delays.
  - Content must be tappable as soon as it is visible.

  These come from his published skill files, not a study ([`choreograph`](https://raw.githubusercontent.com/emilkowalski/skills/main/skills/choreograph/SKILL.md), [`find-animation-opportunities`](https://raw.githubusercontent.com/emilkowalski/skills/main/skills/find-animation-opportunities/SKILL.md)). The second file adds: entering content fades and scales from 0.95–0.97, never from 0. Press feedback is 100–160ms. "Data users read or act on should not move for style."
- **Flutter cookbook:** one `AnimationController`, an `Interval` per item, 50ms stagger, 250ms per item, ease-out, started in `initState`. Its button pops in on `elasticOut`, which would break D14 here ([Staggered menu animation](https://docs.flutter.dev/cookbook/effects/staggered-menu-animation)).
- **The sources disagree on the step:** Material says ≤ 20ms, Emil 30–80ms, Flutter's sample 50ms. They agree on the shape: steps much shorter than each item's own motion, so items overlap, and a short total.

### 3. Stagger doesn't help people track things (high)
- **Chevalier, Dragicevic & Franconeri 2014** tested whether staggering moving objects helps people follow them. It had little effect, or a slightly negative one: it hides which objects move together and makes start times less predictable ([*The Not-so-Staggering Effect of Staggered Animated Transitions on Visual Tracking*, IEEE TVCG 20(12)](https://hal.archives-ouvertes.fr/hal-01054408v1), DOI 10.1109/TVCG.2014.2346424; abstract via search summaries, as the HAL page and the PDF host blocked the fetch).
- **Heer & Robertson 2007** found animated transitions between chart states improved graphical perception, and staged ones (axes first, then values) were preferred ([*Animated Transitions in Statistical Data Graphics*](https://idl.uw.edu/papers/animated-transitions); the staging result is from course slides, not the paper's text).

So a stagger is an ordering device. It says "this first, then these" and gives the eye one place to start. It doesn't make content easier to understand. A cascade should be short and should never sit between a person and a number they came to read.

### 4. Loading: under a second, don't show loading (medium)
- **NN/g:** under about 1 second, skip skeletons and spinners. A skeleton suits a full-page load of 2–10 seconds ([*Skeleton Screens 101*](https://www.nngroup.com/articles/skeleton-screens/)).
- **Android developers:** changing content at once "can be jarring, and users can miss new content that appears suddenly". Crossfade from the loading state to the content using `config_shortAnimTime`, which suits "subtle animations or animations that occur frequently" ([Reveal or hide a view](https://developer.android.com/develop/ui/views/animations/reveal-or-hide-view)).

Hisaab reads a local SQLite file, so loads are usually well under a second. Spends' blank frame followed by a pop is the jarring change Android's page describes. It needs a short fade, not a skeleton.

### 5. Accessibility (high)
- **WCAG 2.2, SC 2.3.3 (AAA):** motion triggered by an interaction can be turned off unless it is essential. Opacity, colour and blur changes are not "motion" unless they also change apparent size, shape or position. Content moving into view is essential to scrolling. Effects added *during* scroll, like parallax, are not ([Understanding 2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)).
- **NN/g** names parallax, auto-advancing carousels and scroll-jacking as triggers for dizziness, nausea and migraine in people with vestibular disorders ([NN/g, duration](https://www.nngroup.com/articles/animation-duration/)).

This supports Hisaab's reduced-motion rule (a 150ms crossfade only). It also rules out "reveal on scroll": rows that slide in as they scroll into view.

### 6. Fintech references (low)
- No primary source on Copilot Money's, CRED's or Monzo's entrance motion was found. Copilot is an Apple Design Award finalist known for animated data, but the write-ups found are third-party ([Blake Crosley guide](https://blakecrosley.com/guides/design/copilot-money)). Watching the apps on a device would be the real research. Mobbin needs a login (sources.md).

## Where each screen sits on the frequency scale

| Screen or moment | How often | Motion budget |
|---|---|---|
| Add tray: keypad, Next, tiles | Several times a day, muscle memory | **None beyond press feedback.** Never stagger tiles or keys (entry speed, "nothing moves unless you move it") |
| Home appears | Many times a day | Already spent: the fill in and the sheen are the focal point. **The rest must not compete** |
| Home ⇄ Spends via the dock | Daily | Short, quiet, no movement across the screen |
| Spends content | Daily to weekly | A small cascade of the cards is fine |
| Settings, Bills, Ask AI | Weekly to monthly | The route transition is the entrance; contents don't also cascade |
| A save landing in the Today list | Several times a day | Only after the drain, as part of the save's story |
| Delete with Undo | Rare | Collapse, then come back along the same path |
| Onboarding finish | Once | The richest moment. It already has "assemble" (FR-ON-5) |

## Patterns compared

| Pattern | Feels alive | Cost or risk | Fit |
|---|---|---|---|
| A. Stagger every list on every screen | Yes, at first | Breaks the frequency rule on Home; competes with the fill in and the sheen (two focal points); delays reading the number | **Reject** |
| B. Reveal rows as they scroll into view | Somewhat | Decoration added during scroll (WCAG 2.3.3, NN/g); rows jump while being read | **Reject** |
| C. Hero first, then Home's lower cards fade in as one group | Yes, quietly | One extra fade on a frequent screen; must not delay the number | Build, with a short delay |
| D. Spends cards cascade in (card-level, not row-level) | Yes | Needs a first-frame flag so it never replays on rebuild | Build |
| E. Fade through between Home and Spends | Removes the only hard cut | 150ms on a daily tap | Build |
| F. New row grows into the Today list after the drain | Yes; shows where the money went | Needs an animated list for that one section | Build |
| G. Deleted row collapses; Undo grows it back in place | Yes ("fly, don't teleport") | Same widget as F | Build with F |
| H. Small feedback: Ask AI copy turns into "Copied", chip picks crossfade on `snap` | Yes, small | One-off widgets | Build where missing |
| I. Bouncy pop-ins (`elasticOut`, scale from 0) | Playful | Breaks D14 (no bounce unless thrown) and reads as a toy | **Reject** |

## Recommendation (proposed, not approved)
Make the screens feel alive through **arrival order and continuity**, not more movement. Each screen keeps one focal point. Frequent screens stay nearly still.

### Rules
1. **Animate a screen's first frame only.** A rebuild, a Bloc reload or coming back from a pushed page never replays the entrance. Rows below the first screen arrive already in place.
2. **One entrance per container.** Animate the card, not its rows. Rows never cascade inside a card.
3. **Stagger is short and capped.** About 40ms between items, at most 5 items, the group done in 300ms or less. Item 6 and later arrive with item 5.
4. **Small distance, fade plus rise.** An item rises 8dp and fades from 0 to 1 on `HisaabMotion.easeOut`, or on `standard` if driven by springs. It never scales from 0 and never bounces.
5. **Never block a tap.** Content is tappable from its first frame, and a tap mid-entrance jumps everything to its end.
6. **Never stagger exits.** A leaving screen goes as one piece.
7. **Never animate the tools.** The keypad, the Add tray tiles, the dock and the category order never move in (principle 5 of UI_DESIGN §2).
8. **Reduced motion:** no rise and no delay. Everything fades in together over 150ms, matching the existing rule.

### Motion spec

| Trigger | Element | Property | From → to | Token | Delay | Reduced motion | Haptic |
|---|---|---|---|---|---|---|---|
| Home's first frame | Hero | — (fill in and sheen as today) | — | `calm`, `sheen` | 0 | as today | — |
| Home's first frame | Each card under the hero (Today list, due soon, over card), as one group | opacity, y | 0 → 1, +8dp → 0 | `easeOut`, 250ms | 120ms, so the eye lands on the hero first | 150ms fade, no delay | — |
| Dock: Home ⇄ Spends | The incoming screen | opacity (fade through) | outgoing 1 → 0 in 60ms, incoming 0 → 1 in 150ms | `easeOut` | 0 | the same fade (opacity only) | existing selection tick |
| Spends' first frame | Each card in order (pace, where it went, insights, Ask AI) | opacity, y | 0 → 1, +8dp → 0 | `easeOut`, 250ms each | 40ms × index, max 4 steps | 150ms fade together | — |
| Spends loading → loaded | Whole content | opacity | 0 → 1 | `easeOut`, 150ms | — | the same | — |
| Save, after the drain starts | The new Today row | height, opacity | 0 → row height, 0 → 1 | `standard` | starts when the bar's pull-back starts, so the bite and the row read as one event | appears with a 150ms fade | existing save haptic |
| Delete a Today row | The row | height, opacity | row → 0 | `snap` | 0 | 150ms fade | existing |
| Undo | The row | height, opacity | 0 → row (same path back) | `standard` | 0 | 150ms fade | — |
| Ask AI: Copy | The button's label and icon | crossfade to "Copied" and a check, back after 2s | — | `snap` | 0 | the same (opacity only) | light tick |

Pushed pages (Settings, Bills, Ask AI, bill editor) keep the predictive-back route transition, and their contents don't cascade (rule 2): the page is the container.

### Why Home gets one quiet group fade, not a cascade
Home is the most frequent screen, and its hero already carries two motions each time it appears (fill in, sheen). Principle 20 and Material's choreography both say one focal point at a time. A 120ms hold lets the eye land on the hero, then everything below arrives as one quiet block. Case study 11 suggests the first open of the day could carry more. That needs a stored "last opened" date, which D91 chose not to add, so it stays open.

### Implementation notes (for design-motion and the build)
- One `AnimationController` per screen with an `Interval` per item, as in the Flutter cookbook, but with `HisaabMotion.easeOut` and no `elasticOut`. A shared `EntranceStagger` widget in `lib/core/widgets/` would take the item index and read `reduceMotion(context)`.
- New tokens to hand to design-system: `staggerStep` (40ms), `entranceRise` (8dp), `entrance` (250ms), `entranceHold` (120ms).
- Inject the ticker or use `tester.pump` with durations so widget tests check the end states and the reduced-motion path.
- Animate only opacity and transform, inside `RepaintBoundary`s. Check the frame chart on the moto g45 (UI_DESIGN NFR, D56 device).

## Conflicts and doc changes if approved
- **UI_DESIGN §2 principle 5 ("Nothing moves unless you move it")** is about positions never reordering. An 8dp rise ends in the same place every time, so it doesn't break the rule. Rule 7 above keeps the tools still. The spec should say this outright.
- **UI_DESIGN §6:** add the entrance rules, the spec table and the new tokens, and add rows to the frequency table.
- **SPEC E13:** already says all motion becomes 150ms crossfades. No change.
- **The `standard` token's "list insert" use** becomes real (pattern F).
- A DECISIONS row when approved.

## Risks
- **Habituation:** even a 250ms fade on Home is seen dozens of times a day. If it starts to feel slow, drop Home's group fade first and keep the rest.
- **Perceived slowness on low-end phones:** a dropped frame in a cascade looks worse than no cascade. Measure before shipping.
- **No user evidence:** this is desk research and practitioner rules. The only experiment on stagger (Chevalier et al.) found it doesn't help comprehension, so the claim here is about feel and order, not about understanding.
- **The step value is a judgement call** between Material's ≤ 20ms and Emil's 30–80ms. Tune it on a device.

## Open questions
- Should the first open of the day get a richer entrance than later opens (case study 11)? It needs a stored date.
- An HTML or Flutter prototype of patterns C, D, E and F, recorded on the device, then a blind read: does it feel "alive" or "slow"?
- Watch Copilot, CRED, Monzo and Google Pay on a device to see what their screens do on arrival.

## Principles
See `principles.md` › *Screen entrance motion (case study 24)*.
