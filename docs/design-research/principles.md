# Design principles from research

Each principle cites its source and names where it applies in Hisaab. The newest go at the end of their section. When a principle conflicts with a Hisaab decision, `DECISIONS.md` wins until a new row changes it.

## Choosing one option

1. **Show a short list of options as visible rows, not a dropdown or a grid.** People can scan, compare and pick in one step. A grid of labels with different lengths wraps unevenly and loses its alignment. *Sources:* NN/g on dropdowns; Apple HIG, Lists and tables; case study 01. *Applies to:* Ask AI goals, onboarding questions, settings choices.
2. **Mark the pick with a checkmark at the row's end, not a filled block.** A fill is for navigation (the row you came from); a check is for an option. In Hisaab it's an ink check plus a bold label, never marigold, because a pick is a mode (D47). *Sources:* Apple HIG, Lists and tables. *Applies to:* any single-select list.
3. **Two to five short, related nouns go in a segmented control**, with equal-width segments and no introductory text. Hisaab has one segmented style, the Spent | Got switch. *Sources:* Apple HIG, Segmented controls. *Applies to:* periods, kind switches.
4. **Chips only for one- or two-word options in a single row.** Two rows of chips are hard to scan. *Sources:* Material Chips; Setproduct. *Applies to:* quick amounts, filters.
5. **Default single-select for goal questions.** It's about 3:1 across 80 apps. Label multi-select "Select all that apply". *Sources:* Lazyweb. *Applies to:* onboarding and Ask AI.

## Layout and layers

6. **Two layers for a choice: page, then rows.** Every extra box (card, then track, then pill) reads as nesting, not as one list. In Hisaab: grey `bg`, then near-white `surface` cards. Grey `sunk` only for wells and the segmented track (D45). *Sources:* Apple grouped lists; case study 01.
7. **Rows in one card share the Today list's geometry:** a 20dp inset, an icon in a grey well, and hairlines indented to where the text starts. Every option row in the app then lines up with Home. *Sources:* Hisaab Home; Apple inset separators.
8. **Keep the main action in thumb reach while the choices change.** Pin it to the bottom when the window is tall enough. *Sources:* Duolingo's Continue; Monzo onboarding. *Applies to:* Ask AI, onboarding, bill editor.

## AI entry points

9. **Offer 3–4 concrete starters tied to the user's data, never "Ask me anything".** Starters turn recalling a request into recognising one. *Sources:* AI UX Playground; UI Patterns, Suggested prompts. *Applies to:* Ask AI goals.
10. **Keep "type your own" visible next to the starters**, not behind an extra tap. Typing should pick it. *Sources:* Notion AI's "Describe your own"; AI UX Playground. *Applies to:* Ask AI's own question.
11. **Show exactly what will be sent before it leaves the phone.** Preview the first lines, with the full text one tap away. This is already Hisaab's rule (FR-AI-3, NFR-2). *Sources:* case study 01.

## Typography (case study 02)

12. **Size sets the level; weight sets emphasis within a level.** Big jumps (title vs body) come from size. Within one size, one weight step (Regular to Semibold) marks what matters. *Sources:* Apple HIG text styles; IBM Carbon; Fluent 2. *Applies to:* every screen.
13. **Two or three weights in UI text:** Regular, Semibold, and Bold for amounts. Nothing lighter than Regular at small sizes. *Sources:* Apple HIG ("avoid Ultralight, Thin, and Light"); Carbon; Refactoring UI.
14. **List row titles are body-weight; the picked or unread row gets the emphasized weight,** and the check or indicator carries the selection too. *Sources:* Apple HIG (Body vs Headline at 17pt); Material 3 emphasized styles. *Applies to:* goal rows, entry rows, bill rows.
15. **A heading at body size needs Semibold; a big heading can stay Regular** because its size already ranks it. *Sources:* Apple Headline; Carbon `heading-01` (600) vs `heading-03`+ (400).
16. **A card's header must not share its rows' style.** It differs by size or role. *Sources:* Atlassian ("hierarchy with heading styles, not bold or bigger body"); case study 02, finding A3.
17. **De-emphasise with colour, a lighter neutral that still passes 4.5:1, not with a light weight or a tiny size.** *Sources:* Fluent 2; Refactoring UI; Carbon (neutral running text).
18. **Emphasis is a named variant of a style, never a one-off `fontWeight` override.** *Sources:* Apple emphasized weights; Fluent Strong/Stronger; Primer ("don't use arbitrary weight number values").
19. **Sentence case, no all-caps for attention, few typefaces; keep the hierarchy when text scales.** *Sources:* Fluent 2; Apple HIG Dynamic Type.


## Motion (case study 05)

20. **Animate a change where it can be seen.** Hold the update until whatever covers it (tray, scrim) has gone, then move one focal point at a time. *Sources:* Material choreography; eBay motion playbook. *Applies to:* the drain after Add, list inserts.
21. **A gauge needs a visible empty part to read as a gauge.** Show it filling once, and make every change visible, even a small one. *Sources:* the blind read in case study 05; Apple's gauge guidance (§3.3). *Applies to:* Day Blocks.
22. **No bounce unless a finger threw it.** Springs start at damping 1. *Sources:* Apple WWDC18 *Designing Fluid Interfaces*, WWDC23 *Animate with springs*.

## Tokens and themes (case studies 06, 07)

23. **Every colour token has four values: light, dark, and an increased-contrast value for each.** The contrast values push greys away from the background, never closer. *Sources:* Apple HIG Color and Accessibility; Flutter `highContrastTheme`. *Applies to:* `HisaabColors`, `HisaabTheme`.
24. **Focus has its own token and never doubles as selection.** A ring with a gap, at least 3:1 on every layer, shown only for keyboard or D-pad focus and never hidden under sticky bars. A selected control keeps its look and gains the ring. *Sources:* Carbon `$focus` / `$focus-inset`; Atlassian colour; Vercel Web Interface Guidelines; WCAG 2.4.7, 2.4.13. *Applies to:* keys, tiles, chips, rows, dock, header buttons.
25. **Set every platform role, and a role keeps one meaning in every theme.** An unset Material role inherits the nearest given colour, which here is the signal. *Sources:* Carbon Themes; Flutter `ColorScheme` API. *Applies to:* `HisaabTheme._scheme`.
26. **Contrast pairs are one list, checked in every theme; high contrast raises the floor, not the list.** *Sources:* Primer `colorContrast.config.ts`. *Applies to:* `hisaab_colors_test.dart`, `hisaab_theme_test.dart`.
27. **Roles point to steps of one scale.** State changes move a set number of steps (press one step), and an alias is fine only when it names the same step. *Sources:* Geist Colors; Carbon colour overview; Primer base vs functional; Radix aliasing. *Applies to:* `HisaabColors`, chips, keys, fields.
28. **Deprecate a token before removing it, and record every alias.** *Sources:* Carbon migration FAQ; Primer token-removal check. *Applies to:* `HisaabColors`, `DECISIONS.md`.
29. **Transparent is a token, tinted with its layer.** Fading to a bare transparent fades through black. *Sources:* Razorpay Blade `transparent`; Flutter `Color.lerp`. *Applies to:* fades, unselected fills.

## Colour system (case study 08)

30. **A ramp is steps with jobs, not a gradient to pick from.** Name the role first; if no step has that job, add a step. Never move a token to suit one component. *Sources:* Radix 12-step scale; `better-colors` skill; Refactoring UI. *Applies to:* `HisaabColors`, every colour change.
31. **Measure, never eyeball.** Give OKLCH `L` and the WCAG ratio on the layer it renders on, from a script; compare options in a mockup on real layers in both themes. *Sources:* `better-colors`; case study 08. *Applies to:* every token change.
32. **A neutral scale needs a middle.** Step the light end finely (about 0.04–0.05 `L`) but leave no gap of 0.4 `L` between roles, or medium-weight fills can only be too faint or too heavy. *Sources:* Refactoring UI (8–10 greys); case study 08. *Applies to:* picked chips, selected pills, disabled states.
33. **Dark on light for a transient alert, but a charcoal, not black.** *Sources:* Material inverse surface; Refactoring UI (start greys from a dark grey). *Applies to:* the snackbar (`inverse`, D105).
34. **Colour psychology claims need a study behind them.** Keep only what holds: colour sparingly and never alone, no alarm hues near money, and local meaning (marigold is auspicious in India). *Sources:* Apple HIG Color; case study 08. *Applies to:* D8–D10.

## Colour in fintech (case study 09)

35. **Colour mass comes from value before hue.** Fintech brands pair a small bright accent with a dark brand colour that carries the screen: Monzo's coral with navy, Wise's bright green with Forest green, the ET66's yellow key on a black body. In Hisaab, the dark end of the scale (`inverse`, `ink`) is the dark brand colour, and marigold stays small. *Sources:* Monzo brand refresh; V&A ET66 record; Wise (third-party reconstruction); case study 09. *Applies to:* Home hero, brand visuals.
36. **Put the accent in the content layer, not on controls.** Brand colour used too broadly "can overwhelm your interface and dilute its impact". Keep it for the primary action and status. *Sources:* Apple HIG Branding; Refactoring UI palette preview. *Applies to:* marigold placement, chips, dock, keys.
37. **A categorical hue set has six hues at most, and never borrows a hue that already means something.** Remove the signal hue and the good/bad hues (red, green) first, then count what's left. A category hue that lands on red or green reads as a verdict. *Sources:* Innovaccer; Datawrapper Academy; Datadog categorical vs semantic palettes; Apple HIG Color ("avoid using the same color to mean different things"). *Applies to:* category tiles, entry rows, Spends charts.
38. **Colour is a redundant cue, never the identity.** The icon, the word and a fixed position identify a category, and a tint can only speed the search. With equal-lightness tints, colour-blind users get almost nothing from the hue, so the other cues must stand alone. *Sources:* jfly Colour Universal Design; Apple HIG inclusive colour; Datawrapper (vary lightness for CVD). *Applies to:* categories, any chart legend.
39. **Test colour codes with oral and low-literacy users before shipping them.** People who read banknotes by colour can still be confused by arbitrary colour codes in apps, which are one more literate convention to learn. *Sources:* MicroSave Briefing Note 168; NextBillion (MicroSave authors). *Applies to:* category colours, state colours, onboarding.
40. **Keep small text dark-on-light; give a dark card large numerals and few words.** Light mode wins on acuity, especially for small text, and the gap shrinks for large text. *Sources:* NN/g *Dark mode vs light mode* (Piepenbrock et al. 2013; Dobres et al. 2017); Flutter `inverseSurface`. *Applies to:* a dark hero card, the snackbar.

## The hero card (case study 10)

41. **Emphasise the hero by making it a different object, not a bigger one.** A payment card stands out through material and finish (etch, print pattern, metal), not through more hues; with one signal colour, change layer, elevation or texture. *Sources:* Apple Card, OneCard, banknote guilloché; case study 10. *Applies to:* the Home hero.
42. **Let content set a card's height; don't borrow a media ratio.** 4:5 suits a photo in a feed. A readout given a fixed ratio gains only empty space, pushes the next item off the first screen, and breaks at 1.5× text and in wide windows. *Sources:* ISO/IEC 7810; Instagram post sizes; case study 10. *Applies to:* the hero, any card holding text.
43. **Decorative motion runs once, for a reason.** A sheen or shine marks an event (a new day, a reward) and never loops. *Sources:* case study 10; D91. *Applies to:* the hero sheen.

## Attention and memorable moments (case study 11)

44. **Design the peak and the end; the start only has to be clear.** Memory of an episode weights its most intense moment and its end, and the first moment counts for less. Never make a start low on purpose. On a first contact the opening sets a halo over everything after it. *Sources:* Alaybek et al. 2022 meta-analysis; Kahneman et al. 1993; Lindgaard et al. 2006; Loewenstein & Prelec 1993. *Applies to:* onboarding, every flow's last screen.
45. **End every flow on a settled, true state, never on an error, a loader or a deficit.** The last frame says what happened and what is still true. In a short session the end *is* the peak: the visible result of the user's own act. *Sources:* Redelmeier, Katz & Kahneman 2003; Nielsen (UX Tigers); Duolingo session-end; Stripe success pages. *Applies to:* the Add drain, the over state, Ask AI's handoff.
46. **Fill the pits before building peaks.** Fix the worst moment first. A celebration elsewhere doesn't offset a bad middle. *Sources:* Heath & Heath, *The Power of Moments*; Nielsen; NN/g theory of user delight. *Applies to:* overspend, the month-end squeeze, onboarding's bills step.
47. **Delight scales inversely with frequency: put rich moments on transitions that happen once, and keep frequent actions identical.** A response to a repeated stimulus fades faster the more often it comes, and recovers when withheld. A once-a-day moment survives; one on every open fades. *Sources:* Rankin et al. 2009 (habituation); Frederick & Loewenstein 1999; Kano; Nielsen ("overusing celebrations flattens peaks"); UI_DESIGN §6. *Applies to:* the morning tear, the hero sheen, the underspend note, the Add flow.
48. **Rewards are predictable and earned by the user's own act, never random, never withheld to pull them back.** No scratch cards, streak loss, open loops or "come back" prompts. The Zeigarnik memory effect doesn't replicate, and nagging is a listed dark pattern in India. *Sources:* Ghibellini & Meier 2025; CCPA Dark Patterns Guidelines 2023; critiques of *Hooked*; Duolingo streak (counter-example). *Applies to:* every engagement idea.
49. **A month of short uses gets its remembered end from an explicit recap, not from its last session.** Peak-end holds for single episodes, but not reliably for day-long or longer multi-episode ones. Close the cycle in words, kindly, once. *Sources:* Miron-Shatz 2009; Year in Monzo; Spotify Wrapped. Low confidence; test with a diary study. *Applies to:* payday morning, the cycle summary.

## Countable units (case study 12)

50. **Group a count above four into weeks.** People see about four items at once without counting. Above that, clusters they can see at once make the total fast to count. Seven is the group people already know for days. A denser row of equal units is not easier to count. *Sources:* Sakai & Fujii 2007 (the subitizing limit); Starkey 2014 (groupitizing); calendar blister packs; Wait But Why, *Your Life in Weeks*. *Applies to:* the day units, any row of countable marks.
51. **Count in discrete units; measure in a continuous fill.** Equal segments carry *how many*, but they get too small to show an amount once there are many. The one live unit gets enough size or sub-units to show a small change. *Sources:* Apple HIG Gauges (macOS discrete vs continuous capacity); Nothing Glyph Matrix (per-object brightness); case study 05. *Applies to:* today's unit, any segmented progress.
52. **Borrow a reference's structure, not its surface.** A shipped look (Nothing's dots, Instagram's segments, Flighty's route) brings its owner's brand and its meaning ("loading", "signal") with it. Name the structure being taken, then check that the result doesn't read as the source. *Sources:* Nothing OS 3.0 and 4.0 dot use; Material 3 Expressive wavy progress; UI_DESIGN §12 (the battery cliché). *Applies to:* every reference-driven direction.

## Unfold takeaways (case study 15)

53. **Measure each day against its own line.** When a reference changes from day to day (each day's share), give every bar its own tick rather than one line at today's value, and say in words what the line is. *Sources:* Apple HIG Charts ("write descriptions that help people understand what a chart does"); Vicki Boykis on Screen Time's unlabelled average (2019); BR-3/BR-4. *Applies to:* week bars, any per-period chart.
54. **Swap a picture in place.** A second view of the same card takes the first view's row and height, so nothing below it moves, and the live unit travels to its new place. *Sources:* principles 5 and 6 (UI_DESIGN §2); Apple HIG Charts ("help people notice important changes"). *Applies to:* the hero's Today and This week, any toggle inside a card.
55. **Protect privacy without a control first.** Remove the exposure (the recents preview) before adding a button to hide things; add the button only if people still ask, and then remember its state. *Sources:* Android `setRecentsScreenshotEnabled` (API 33); OWASP MASTG on `FLAG_SECURE`; Trading 212 users on privacy mode that forgot its state. *Applies to:* recents, hide amounts, any privacy feature.

## Changing a fixed bill (case study 16)

56. **Create in steps, change in place.** A wizard that helps someone create a thing should not be the only way to change it. To change one answer, show the whole item with a Change control per answer, open only that question, and save it alone. Never make the user re-confirm answers they didn't touch. *Sources:* DWP "Add another thing"; GovStack check answers; Infowise forms (wizard on create only); PatternFly wizard vs progressive form. *Applies to:* fixed bills, and any future editor for a thing first made in steps (categories, onboarding answers).

## Savings (case study 17)

57. **Saving is reserved before its day and recorded on it, never counted as spending.** Take it out of "safe to spend" ahead of time, show it as its own kind of row on the day, and keep it out of spending charts, pace and over-states. *Sources:* Simple Safe-to-Spend Goals; Simplifi's plan formula; Copilot goals; Monefy and Monzo user complaints; case study 17. *Applies to:* BR-3, Home's Today list, Spends.
58. **Label and separate a saving, but never make breaking it feel like failure.** Naming and partitioning raise saving; guilt and streaks bring the what-the-hell effect. Skipping is a quiet undo, with no behind-state and no count. *Sources:* Soman & Cheema 2011; Thaler 1999; Cochran & Tesser 1996 (as cited); Copilot's "behind" (counter-example); principle 48. *Applies to:* savings rows, skip, any goal idea.
59. **One source of truth for every total.** Any saved or spent total is computed from the same entries as the hero, never kept as a second balance. *Sources:* Monzo "left to spend" threads; Monarch goals vs Cash Flow reports; Goodbudget's manual mirroring. *Applies to:* Spends' summary line, the Savings list total.

## Bills and reminders (case study 18)

60. **A known date with an unknown amount waits for the amount; it is never posted as a guess.** Reserve an estimate until the real amount is entered or skipped. *Sources:* Actual Budget schedules (approve manually); YNAB scheduled transactions; Chronicle *Amount Due Varies*. *Applies to:* changing bills, BR-3 `B`.
61. **Count money once, at the moment of choice.** A card purchase is spending; paying the card is not. *Sources:* YNAB credit card handling; Monarch transfers; Realbyte transfers; Soman 2001. *Applies to:* credit card bills, any future "account" idea.
62. **A reminder is a bonus; the in-app line is the guarantee.** Design so nothing breaks if the notification never arrives. *Sources:* dontkillmyapp; Android alarms (inexact, Doze, reboot). *Applies to:* bill reminders, any scheduled nudge.
63. **One notification per thing, opened by its tap, with no action that repeats the tap; ask permission at the moment it helps.** *Sources:* Material notifications pattern; Apple HIG Notifications; Android notification permission. *Applies to:* bill reminders.

## Choosing light or dark (case study 19)

64. **Follow the phone by default; an in-app look is a quiet override, not a feature.** Most people set light or dark once on the phone and never look for it in an app, so the in-app choice should be one tap with every option visible, and should never stay hidden behind a second step. *Sources:* NN/g, *Dark Mode: How Users Think about It*; Material 3 / Compose `SingleChoiceSegmentedButtonRow`; iOS Display & Brightness. *Applies to:* Settings › Look.
65. **A short word in a secondary grey can fail contrast that its colour pair passes.** At 15dp, anti-aliasing on a 4-letter word pulled `ink2` on `sunk` (5.7:1 as flat colours) to 3.2:1 under Flutter's text-contrast check. Keep short labels on tinted tracks in the primary ink and mark the pick by fill and weight. *Sources:* `textContrastGuideline` on the Look control (D130). *Applies to:* segmented controls, chips.

## Charts on a narrow phone (case study 21)

66. **A cramped chart is usually small data, not a short frame. Measure the marks' footprint before changing the height.** On a fixed axis, early-period data can fill a quarter of the plot, and a taller card enlarges mostly empty space. *Sources:* case study 21 (measured screenshot); Apple HIG Charts (fixed vs dynamic range). *Applies to:* the pace chart, any cumulative chart against a period total.
67. **Choose the aspect ratio for the slope people must read, not by a fixed rule.** Banking to 45° is a starting point. Flatter is fine for comparing slopes, and taller exaggerates. When one chart holds a long trend and a short one, the short one that matters chooses the ratio. *Sources:* Heer & Agrawala 2006; Talbot, Gerth & Hanrahan 2012; EU Data Visualisation Guide, *Line chart aspect ratios*; Aisch 2012. *Applies to:* pace chart height (D69), week bars.
68. **Keep an axis fixed when its bounds mean something. If it must change, make the change noticed, both animated and stated.** *Sources:* Apple HIG Charts › Axes and Best practices. *Applies to:* the pace chart's y-axis, any rescaling idea.
69. **On a narrow screen, numbers leave the plot.** Put the main message in a line above the chart or in a key below it, and leave at most one short mark at the point that matters. Two free-floating labels in one plot will collide at some width and on some day. *Sources:* Datawrapper responsive annotations (2020) and mobile-first (2016); EU guide, *Responsive text annotations*; Apple HIG (summarise the main message); Copilot's *Free to Spend* above its graph. *Applies to:* pace chart gap and forecast labels, any annotated chart.
70. **Give the plot the full width: short axis labels inside the plot or on the trailing side, units in the title.** *Sources:* Apple HIG Charts ("maximize the width of the plot area"); Datawrapper, *Why many charts don't include axis labels*. *Applies to:* pace chart y-labels.
71. **On mobile, use 3–6 labelled gridlines at a familiar round step, about 3 date labels, and a key rather than line-end labels.** *Sources:* ONS service manual, *Axes and gridlines*; Apple HIG (familiar sequences); Gestalt (≤3 horizontal labels ≤576px, unverified); Datawrapper (2016). *Applies to:* pace chart axis, date row and legend.

## Backup, restore and erase (case study 23)

72. **Know what the phone already backs up before building a backup, and keep privacy copy true to it.** Android Auto Backup uploads an app's database and preferences to the user's Google Drive by default. A "stays on this phone" sentence must match the manifest. *Sources:* Android Auto Backup; Android 12 backup changes; sqflite `getDatabasesPath`. *Applies to:* the manifest, onboarding's privacy line, About.
73. **Check the file before touching the data, and show what's in it before replacing.** Validate the whole file, then say its date and size in days and entries, then ask. A file from a newer app version is "update the app", not "corrupt". *Sources:* Bluecoins (schema check first); Cashew's import warnings; Actual Budget's version error; BR-16, E14. *Applies to:* restore, any import.
74. **A replace keeps the old data for undo; an erase meant for privacy keeps nothing.** Restoring can keep a local snapshot and offer *Undo*. Erasing must truly erase, so it needs a stronger guard instead. *Sources:* Actual Budget's "Revert to original version"; NN/g, *Confirmation dialogs* ("provide undo"); Pixel factory reset. *Applies to:* restore, reset, delete everything.
75. **Offer the safe act at the moment of risk.** Put "Back up first" before erasing, and put restore where a new-phone user starts, the first screen. *Sources:* Pixel help; Goodbudget; PocketSmith; Signal and WhatsApp restore at setup; Cashew's "Backup Found". *Applies to:* the erase sheet, onboarding step 1.
76. **Put the scope in the words, not just the verb.** Name what goes and what stays on the button and in the sentence, and never use Yes/No. *Sources:* NN/g, *Confirmation dialogs*; Primer; Lunch Money's reset complaint (2026); Goodbudget's "DELETE ALL MY DATA". *Applies to:* erase, restore, delete bill, any destructive act.
77. **A backup that needs a secret the user can lose isn't a backup for most people.** Without an account, the file's safety is the place the user chose. Skip passphrases unless the threat demands one. *Sources:* Signal (30-digit passphrase); WhatsApp (64-digit key, unrecoverable); Gupta et al. 2022 (passwords in diaries, helpers set up phones). *Applies to:* backup.
78. **Guard an irreversible act with a deliberate step that doesn't test English spelling.** A typed English word is a literacy test on a Hindi-first phone. Prefer a localised word, a hold with visible words, or the phone's own lock, and test which one stops a stray tap on a shared phone. *Sources:* NN/g guideline 7 (nonstandard action); GitHub's typed name; Bluecoins' typed phrase; Pixel's PIN; Gupta et al. 2022 (spelling, shared phones). Low confidence until tested. *Applies to:* reset or erase.

## Screen entrance motion (case study 24)

79. **A screen's motion budget is set by how often it is seen.** Tools used many times a day (keypad, Add tiles, dock) get press feedback only; frequent screens get one quiet arrival; rare screens and first-run moments can carry more. *Sources:* NN/g, *Animation duration*; Apple HIG Motion; Emil Kowalski, *You don't need animations*; Rauno Freiberg, *Invisible details of interaction design*. *Applies to:* every screen entrance, the Add tray.
80. **A stagger orders attention; it doesn't aid understanding. Keep it short, capped and first-frame only.** Steps of tens of ms, a handful of items, the group done in about 300ms, never replayed on a rebuild, never on rows as they scroll in, never on exits. *Sources:* M1 choreography (≤ 20ms apart); Kowalski's `choreograph` rules (30–80ms, ~300ms total); Chevalier, Dragicevic & Franconeri 2014 (no tracking benefit); WCAG 2.3.3. *Applies to:* Spends cards, Home's lower cards.
81. **One entrance per container.** Animate the card or its rows, never both; a pushed page's route transition is its entrance. *Sources:* Kowalski's `choreograph` rules; M1 choreography ("too much animation during surface creation is distracting"). *Applies to:* Settings, Bills, Ask AI, list cards.
82. **Under a second, don't show loading: fade the content in.** A blank frame and then a pop is jarring; a skeleton suits 2–10 second waits. *Sources:* NN/g, *Skeleton screens 101*; Android developers, *Reveal or hide a view*. *Applies to:* Spends while loading, any local-DB screen.
