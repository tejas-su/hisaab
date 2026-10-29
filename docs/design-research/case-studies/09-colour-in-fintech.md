# Colour in fintech: colour mass, tinted neutrals, category colours, a dark hero

Case study 08 (the colour retrospective) already covers the grey ramp's missing middle, the `inverse` charcoal (D105) and colour-psychology folklore, including marigold's meaning in India. This study builds on it and does not repeat it.

## Question
The owner feels the app is "failing to paint" a good layout. Today the light theme is about 98% warm grey with one marigold signal (`#FFB020`, *today / act* only, D8), no red or green (D9), no category colours (D10), and a near-white hero card (D46). Marigold is 1.55:1 on the light `bg`, so it never sits there bare (UI_DESIGN §3.2). What we keep: marigold means today/act, and no red/green for good/bad.

This study answers four questions:

- **A.** How do fintech and budgeting apps use colour? How much colour mass is on screen, and are the neutrals tinted?
- **B.** Should hisaab colour its categories? If so, how many hues, and under what constraints?
- **C.** Should the light hero be a dark card again, or a pale brand-tinted one?
- **D.** Are hisaab's tinted neutrals doing enough?

## Method
- **Method:** desk and competitive research only (2026-10-29), with no users. This is the cheapest method that can narrow the options. It cannot settle B or C, because both depend on how people read the screen. The study therefore ends with the smallest tests that would decide them.
- **Citations:** every claim links to its source.
- **Source levels:** I separate three kinds of source:
  - **Official:** the company's own site, help centre, blog or community staff.
  - **Third-party:** reconstructions, reviews and AI-written "design system" files. These are not evidence of the shipped app.
  - **User reports:** forum posts, which tell us what people *said*, not what they *did*.
- **Contrast ratios:** ratios marked *(calc)* are my own WCAG 2 calculations. All other ratios come from UI_DESIGN §3.2 or D105.

### Access notes
- **wise.design:** `foundations/colour` returned only its heading, because it needs JavaScript. The `.md` variant returns 404. Wise's colour values below come from a third-party gallery that cites wise.design ([oppadu](https://www.oppadu.com/tools/design-systems-site/brand/wise.html)), so they are **unverified**.
- **uxplanet.org:** the CRED NeoPOP review returned 403. Its claims below come from the search summary only, and are **unverified**.
- **PMC (pmc.ncbi.nlm.nih.gov):** returned a browser check. **frontiersin.org** redirects to `public-pages-files-2025.frontiersin.org`, which gave only the abstract.
- **lazylanding-labs** (finance theme and brand-colour audits): 503, not read.
- **m3.material.io blog, *Tone-based surfaces*:** returned its title only.
- **life.jupiter.money** (Jupiter's design principles): 403.
- **PDFs:** the MicroSave and Microsoft Research PDFs came back as binary from the fetch tool. The MicroSave note was read from the saved file. The Medhi et al. ToCHI paper was not read.
- **Not covered:** Google Pay India, Groww's app (beyond the MINT tokens in case study 07), Revolut's app, Cleo and Fi have no public screen-level colour material. Nothing here describes their app screens, and nothing should be inferred. Record them on a device first ([sources.md](../sources.md), Indian fintech).

## Findings: A. Colour use across fintech

| App | Brand hue(s) | Colour mass | Neutrals | Good/bad | Dark mode | Confidence |
|---|---|---|---|---|---|---|
| **Wise** | Bright green, about `#9FE870`, and Forest green, `#163300` | Bright green fills buttons and tags. Forest green is the text colour, the top-nav fill and the dark page | Warm off-whites (`#FAFAF7`, `#F0EFEA`), greys tinted toward olive | Separate sentiment set: success green, warning amber, error red | Forest green page, white text | Low: third-party reconstruction ([oppadu](https://www.oppadu.com/tools/design-systems-site/brand/wise.html)) |
| **Monzo** | Hot coral, with deep navy and soft white | "the forefront of our brand, followed closely by deep navy and soft white" | n/a | n/a | n/a | High for the brand ([Monzo blog](https://monzo.com/blog/weve-had-a-little-makeover)); in-app use not documented |
| **Jupiter** (2.0, Apr 2024) | Orange, kept "in accents and highlights" | "Teal, light green, yellow ochre, and darker greys act as pops of colour" | "stark white has been paired with a warm beige", "easier on the eyes" | n/a | Not mentioned | High ([staff post](https://community.jupiter.money/t/jupiter-2-0-redesign-introducing-a-new-experience/51018)) |
| **PhonePe** | Purple | "brand colour the bedrock of the dark mode"; purple is a "subtle touch" on text and icons | Dark text is purple-tinted, not pure white, because pure white "could result in eye fatigue" | n/a | Brand-led; dual-tone icons "to reduce eye strain" | High ([PhonePe design blog](https://www.phonepe.com/blog/design/lighting-up-the-night-presenting-the-dark-theme-of-phonepe/)) |
| **CRED** | Near-black, with neon accents | A dark theme throughout; "most UI elements stick to monochrome" because illustrations carry the colour | n/a | n/a | Dark is the only theme | Low: search summary of a 403 page ([UX Planet](https://uxplanet.org/thoughts-on-creds-ui-revamp-apr-2022-6d2b4dcfcfc6)) |
| **YNAB** | n/a | Coloured "Available" pills on every category row | n/a | Red "immediate action is needed", yellow underfunded, green "It's all good!", grey zero; web icons add shape | n/a | High ([YNAB support](https://support.ynab.com/en_us/colors-and-icons-in-your-plan-HJQv_XHko.md)) |
| **Copilot Money** | n/a | Categories carry a user-chosen colour and emoji | Near-black navy canvas, "never pure black" | Green income, red-orange spending | Dark first | Category colour: high ([help](https://help.copilot.money/en/articles/11157550-quick-start-guide)); hex values: low ([third-party](https://blakecrosley.com/guides/design/copilot-money)) |
| **Fi** | Not stated | "a palette that was cool and fun without being loud and noisy" | n/a | n/a | n/a | High for intent ([Fi guide](https://fi.money/guides/tech-speak-at-Fi/designed-sealed-and-delivered)) |
| **Apple Card / Wallet** | Per-category hues | Purchases "organized by color-coded categories" | n/a | n/a | n/a | High ([Apple Newsroom](https://www.apple.com/newsroom/2019/03/introducing-apple-card-a-new-kind-of-credit-card-created-by-apple)) |
| **Groww** (case study 07) | Green | Green and red for gains and losses | Gray scale, not tinted | `--content-positive` green, `--content-negative` red | Primitives redefined | Medium ([MINT CSS](https://app.unpkg.com/@groww-tech/mint-css@0.4.0/files/dist/fragments/allVariables.css)) |

### Patterns
1. **The usual pair is a bright accent with a dark brand colour, and the dark one carries most of the mass.**
   - Wise pairs bright green with Forest green, and the dark one is the text, the nav and the dark page (third-party, unverified).
   - Monzo leads with coral, "followed closely by deep navy" ([Monzo](https://monzo.com/blog/weve-had-a-little-makeover)).
   - CRED is near-black, with neon accents (unverified).
   - The Braun ET66, hisaab's own lineage, is "made from black plastic", with black number keys, brown function keys and one yellow equals key ([V&A](https://collections.vam.ac.uk/item/O1360553)).
   - hisaab's equivalent of the dark brand colour is the dark end of its scale: `ink` `#161615` and `inverse` `#2F2E2B` (D105). Today they appear only as text, small fills and the snackbar.
2. **The bright accent stays small.**
   - Apple: "Using your brand color too broadly can overwhelm your interface and dilute its impact … use it intentionally for primary actions or status indicators". Apple suggests "moving it into the content layer" rather than onto controls ([HIG Branding](https://developer.apple.com/design/human-interface-guidelines/branding.md), refined Sept 2026).
   - Apple also says that "in apps with primarily monochromatic content or backgrounds, choosing your brand color as the app accent color can be an effective way to tailor your app experience" ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color.md)).
   - Refactoring UI: "almost everything in an interface is grey"; most products need "one, maybe two colors" for primary actions, and accents "used sparingly" ([preview](https://refactoringui.com/previews/building-your-color-palette)).
3. **Too much accent hue draws complaints.**
   - After Jupiter 2.0 spread its orange, user reactions split: "Color scheme looks extremely ugly", "looks dull", "no more orange color", and the dominant pinkish-orange was "a bit too much"; but also "absolutely amazing" from a fan of monochrome ([thread](https://community.jupiter.money/t/jupiter-2-0-redesign-introducing-a-new-experience/51018)).
   - These are user reports (said, not did), from a self-selected forum sample.
4. **Neutrals are tinted, and the tint follows the brand hue.**
   - Wise's neutrals lean olive toward its green (unverified). Jupiter moved white to "warm beige". PhonePe tints even its dark-mode text purple.
   - Radix pairs a grey "saturated with the hue closest to your accent hue" (case study 07). hisaab's warm greys already do this with marigold (OKLCH hue about 90°, chroma about 0.007, case study 08).
   - A search summary says Material raised its neutral palette's chroma from 4 to 6 in 2023 ([Material blog](https://material.io/blog/tone-based-surface-color-m3)). The page didn't render, so this is **unverified**.
5. **Good/bad colour is common, and it is exactly what hisaab rejects.**
   - YNAB (red, yellow, green), Groww (green, red) and Copilot (green, red-orange) all use it.
   - YNAB adds icon shapes in the web app, so its signal doesn't rely on colour alone ([YNAB](https://support.ynab.com/en_us/colors-and-icons-in-your-plan-HJQv_XHko.md)).
   - Nothing found here challenges D9.

### What this means for "failing to paint"
hisaab already uses tinted neutrals and a single small accent, like Wise and Fi. What it lacks is the **dark brand mass** that every benchmark with a bright accent pairs with it:

- Monzo's navy, Wise's Forest green, CRED's black and the ET66's black body all play this role.
- In the light theme, nothing large on Home is darker than text. The page therefore has no focal mass, and marigold, its only colour, can't sit anywhere large.

This is my synthesis from the table, with medium confidence: it rests on official brand statements plus third-party reconstructions, not on screen recordings.

## Findings: B. Category colours (item 3)

### hisaab's categories
- SPEC BR-11 has **10 categories**. Spent has 8 (Food, Travel, Shopping, Bills, Fun, Health, Home, Other), and Got has 2 (Salary, Other income).
- Order and count are fixed (`lib/ledger/domain/entities/category.dart`, D13).
- The Add tray shows the 8 Spent tiles at once.

### Who colours categories, and how
- **Apple Card:** purchases are "organized by color-coded categories such as Food and Drinks, Shopping and Entertainment" ([Apple](https://www.apple.com/newsroom/2019/03/introducing-apple-card-a-new-kind-of-credit-card-created-by-apple)).
  - AppleInsider's 2019 review, read through a search summary, maps health to **red** and travel to **green**. That review is **unverified**, but if accurate, a category hue lands on a good/bad hue.
- **Monzo:** custom categories get "a name, icon and colour" ([help](https://monzo.com/help/budgeting-overdrafts-savings/advanced-budgeting-custom-categories)).
  - Users report **8 colour choices** for up to 50 categories: "8 colour choices is going to give a lot of repetition", "Am already finding it limiting" ([community](https://community.monzo.com/t/monzo-plus-custom-category-icon-suggestions/101474)).
  - One user asks for shades of one colour per group instead.
- **Copilot Money:** category colour, emoji or Genmoji, all user-set ([help](https://help.copilot.money/en/articles/11157550-quick-start-guide)).
- **Jupiter:** a spends donut by category. Users liked the "easy visualization of share of spends across categories" ([thread](https://community.jupiter.money/t/revamped-spends-tracking-on-jupiter/43196)). Staff didn't describe its colours.
- **Pattern:** where colour appears, it shows in three places: icon wells or emoji, list rows, and share-of-spend charts (donut or bar). Global apps let the user pick the colour. None documents a rule against a category hue that reads as state.

### Does colour help people find a category?
- **Colour speeds search when it is redundant with shape and position.**
  - A 2022 study of mobile navigation icons found that icons using colour for layout coding "have the highest visual search efficiency and better user experience" ([Frontiers in Psychology, abstract only](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2022.1040533/text)). I did not see its sample size or effect sizes.
  - Older work found colour beat no coding in search time ([Swan & Perlman](https://garyperlman.com/hfeshci/Abstracts/93_343-347.html), abstract).
  - Confidence: medium. The effect is real in lab search tasks, but none of these studies used finance apps or low-literacy users.
- **Low-literacy users in India rely on colour, and colour also confuses them.**
  - Oral users "rely on colour, relative note size, imagery, the number of zeroes" to recognise rupee notes ([NextBillion, MicroSave authors](https://nextbillion.net/designing-a-mobile-wallet-for-nonliterate-people-a-beginners-guide/)).
  - Yet in MicroSave's fieldwork, "the screens of existing wallets are cluttered with icons and colour choices that can confuse the consumer". People "had considerable trouble identifying [icons] due to literate protocols embedded in colour choices, iconography and navigation cues" ([MicroSave Briefing Note 168, 2017](https://www.microsave.net/wp-content/uploads/2017/05/Mobile_Wallet_Design_for_Oral_Users.pdf)).
  - That note's prototype was deliberately "uncluttered for greater visual clarity". In a test with 20 people in Uttar Pradesh, 6 of the 20 made no error at all (same source).
  - Reading: colour helps when it carries a meaning people already know, as with banknotes. Arbitrary colour codes are one more literate convention to learn.
  - Confidence: medium. The evidence is qualitative fieldwork from one region, not a controlled colour test.

### How many category hues can people tell apart?
- **About six, at most seven.**
  - Innovaccer: categorical colours "become more difficult to comprehend starting at 6 colors, and extremely difficult to understand at 12" ([Innovaccer](https://design.innovaccer.com/data-visualizations/color/usage/)).
  - Datawrapper: "try to avoid using more than seven" ([Datawrapper](https://www.datawrapper.de/academy/what-to-consider-when-choosing-colors-for-data-visualization)).
  - Datadog's classic palette has 6 colours, and they repeat after that ([Datadog](https://docs.datadoghq.com/dashboards/guide/widget_colors/)).
  - Scottish Government recommends "a maximum of 4 colours in a chart" ([gov.scot](https://designsystem.gov.scot/guidance/charts/data-visualisation-colour-palettes)).
- **Colour-blind safety:**
  - Okabe and Ito's Colour Universal Design: "Do not convey information in color only", and label elements directly ([jfly](https://jfly.uni-koeln.de/color/)). Their 8-colour set is the usual safe palette, and it includes orange, yellow, bluish green and vermillion.
- **Equal lightness has a trade-off.**
  - Equal OKLCH lightness keeps one category from looking "more important". Evil Martians' Harmony keeps "equal contrast within lightness groups" ([GitHub](https://github.com/evilmartians/harmony)).
  - But Datawrapper says colour-vision-deficient readers can tell colours apart when you **vary lightness** ([Datawrapper](https://www.datawrapper.de/academy/what-to-consider-when-choosing-colors-for-data-visualization)).
  - So an equal-lightness pastel set is the hardest kind for colour-blind users. It is acceptable only when the icon and the word already carry the identity.

### Arithmetic for hisaab *(my analysis)*
Three hue bands are taken:

- **Marigold, roughly 55–95° in OKLCH:** it means today/act. HIG: "avoid using the same color to mean different things" ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color.md)).
- **Red, roughly 0–40°:** it reads as bad, and Datawrapper calls red a learned "attention/stop/bad" ([Datawrapper](https://www.datawrapper.de/academy/what-to-consider-when-choosing-colors-for-data-visualization)).
- **Green, roughly 125–165°:** it reads as good.

That leaves teal, cyan, blue, indigo, violet and magenta, and the edges of magenta and pink drift toward red. That is **about 4–5 hues** that are clearly different, for **8** Spent tiles. Okabe–Ito's safe set loses orange and yellow to marigold and vermillion to red, which leaves sky blue, blue, reddish purple and bluish green, the last close to green. Eight hues would need repeats or near-neighbours, which is the Monzo complaint. The Got categories would need two more.

### Could a category hue read as good or bad?
Yes:

- If Health gets red, as in Apple's reported map, or Salary gets green, the hue reads as a verdict.
- On a bar chart where "Fun" is pink-red and the largest bar, the hue adds alarm the data doesn't carry.
- Datadog separates categorical palettes, for data with "no natural order", from semantic ones where "red may indicate an error" ([Datadog](https://docs.datadoghq.com/dashboards/guide/widget_colors/)).
- Any hisaab category palette is therefore categorical only, and must exclude the semantic hues.

## Findings: C. A dark hero card in a light theme (item 5)

### What D46 said
The black slab "broke the alternating light layers and looked heavy". The near-white card keeps marigold off a bare light surface with a 1.5px ink edge. D47 adds that a black pill "was the heaviest thing in the tray at ₹0". D105 later chose a charcoal `inverse` (`L` 0.30), not `ink` (`L` 0.20), for the snackbar, to avoid that same slab.

### Evidence
- **Lineage:** the ET66's body is **black** and only the equals key is yellow ([V&A](https://collections.vam.ac.uk/item/O1360553)).
  - UI_DESIGN §3.1 says the ET66 had "a light body, dark keys", which the V&A record contradicts. The lineage argues *for* a dark field around the one yellow element.
  - Apple Cash in Wallet is a black card ([Cult of Mac, 2017](https://www.cultofmac.com/?p=512895); [Apple Magazine, undated](https://applemagazine.com/apple-cash/)). So a dark money card on a light Wallet screen is a known pattern, though at the size of a card, not as a full hero.
- **Platform:** Material's `inverseSurface` is "used for displaying the reverse of what's seen in the surrounding UI … to bring attention to an alert" ([Flutter API](https://api.flutter.dev/flutter/material/ColorScheme/inverseSurface.html)).
  - The role exists to make one thing stand out from its layer. Its example is a transient alert, however, and hisaab already uses `inverse` for the Undo snackbar (D105).
- **Attention:** an element that differs from its surroundings becomes the focal point. Smashing Magazine, an opinion piece, also says people perceive about three levels of dominance ([Smashing](https://www.smashingmagazine.com/2015/02/design-principles-dominance-focal-points-hierarchy/)).
  - Today the hero differs from the other cards only by content. Every card is `surface` at 1.17:1 on `bg`.
- **Readability (against):** dark text on a light background is better "for both visual-acuity tasks and for proofreading tasks" at every age, and "the smaller the font, the better it is for users to see the text in light mode". At night, light mode also did better for glanceable reading ([NN/g, citing Piepenbrock et al. 2013 and Dobres et al. 2017](https://www.nngroup.com/articles/dark-mode/)).
  - The NN/g article says larger text and bright surroundings shrink this gap.
  - The hero's amount is 76sp, so polarity matters little for it. The range line and captions (13–16sp) are where it matters.
- **Contrast** (UI_DESIGN §3.2 or D105 where cited, *(calc)* otherwise):

  | Pair | Light hero today (`surface`) | Ink hero (`#161615`, `L` 0.20) | Charcoal hero (`inverse` `#2F2E2B`, `L` 0.30, D105) |
  |---|---|---|---|
  | Marigold today block | 1.55:1 on light `bg` (never bare; needs the 1.5px ink edge) | **9.90:1**: no edge needed | **7.43:1** *(calc)*: no edge needed |
  | Amount text (`bg` `#EEECE6` on the dark card) | `ink` 17.95:1 | 15.33:1 | 11.49:1 (D105) |
  | Secondary text: dark `ink2` `#A3A29C` | — | about 7.3:1 *(calc)* | 5.31:1 *(calc)* |
  | Idle day blocks | `hairline` 1.53:1 | `#3E3E3B`: 1.69:1 *(calc)* | `#3E3E3B`: 1.27:1 *(calc)*, **fails** 1.5; needs about `#4A4945` (1.51:1 *(calc)*) or lighter |
  | Card against the page | 1.17:1 | about 15:1 | about 11:1 |

- **The pale brand-tinted alternative:**
  - A pale *marigold* tint would spread the signal hue over a large static area. That breaks "one colour, one meaning" (UI_DESIGN §2.2, HIG) and dilutes today's block, the only marigold that should glow.
  - A pale tint of a *second* hue would add a brand hue for decoration.
  - Neither appears in the benchmarks as a hero treatment that I could verify.
  - A pale neutral tint is what hisaab has today, and it is what reads as "not painted".

### Pros and cons
| | Dark hero, `inverse` or `ink` (light theme) | Pale hero (today or tinted) |
|---|---|---|
| Focal mass on Home | Strong: one dark block, as in the ET66 | Weak: the same layer as every card |
| Marigold | 7.43–9.90:1, sits bare, glows; edge removed | Needs an ink edge; 1.55:1 without it |
| Light vs dark parity | The hero looks the same in both themes, which matches the icon and splash (D32: an h on ink) | The hero swaps polarity between themes |
| Small text in the hero | Light-on-dark, slightly worse for acuity (NN/g) | Dark-on-light, best for acuity |
| D45 layering | An exception: the only dark card on Home | Consistent |
| Weight at ₹0 or in an empty state | Heavy (D46, D47 concern); charcoal is lighter than ink, which is why D105 chose it | Light |
| Snackbar | The `inverse` Undo snackbar (D105) is no longer the only dark surface on Home, so it is less distinct | Snackbar stands out |

## Findings: D. Tinted neutrals
- **Where hisaab stands:** its neutrals are already warm (`bg` `#EEECE6`) and paired with the accent's hue, the Radix rule. That is the same move as Wise's off-whites and Jupiter's "warm beige".
- **More chroma has a cost:** Jupiter's beige drew "looks dull" from one user (forum). Apple also warns that colours look "darker and more muted" in bright light ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color.md)), and budget Android LCD panels shift tints further. I didn't test this on a device.
- **Conclusion:** tinting the neutrals is not the missing ingredient. The missing ingredient is value range: a dark mass (A, pattern 1), plus the ramp's missing middle (case study 08).

## Implications for hisaab (for `design-product`)
Research proposes these. `DECISIONS.md` decides them.

### 1. Colour mass and brand surfaces
- **Recommend:** add mass through **value, not a new hue.** Treat the dark end of the scale (`inverse`, `ink`) as hisaab's dark brand colour, the way Monzo uses navy and Wise uses Forest green.
  - Give it one large, meaningful surface on Home: the hero (see 4).
  - Keep marigold small and in the content layer: today's block, the Add key, the Next key (HIG Branding).
- **Don't:** add a second brand hue, put marigold on controls or large fills, or add decorative colour washes.

### 2. Tinted neutrals
- **Recommend:** keep the current warm greys. If anything changes, raise their chroma slightly toward marigold's hue. Treat that as polish, not the fix.
- Check any change on a low-end LCD in daylight before deciding.
- **Don't:** go to beige, or tint `ink` toward a hue. Ink is also the focus ring and the pick fill, so it must stay near-neutral.

### 3. Category colours (item 3): **no-go for v1; run a test before reconsidering**
- **Why not now:**
  - 8 Spent tiles (10 categories in all) exceed the 6–7 distinguishable-hue ceiling once the marigold, red and green bands are removed, which leaves about 4–5 clean hues.
  - Category hues risk reading as good or bad: Apple's red health, a green salary.
  - MicroSave saw colour codes confuse oral users.
  - Identity is already carried by icon, word and fixed position (D10, D13), the redundant cues CUD recommends.
- **If a test shows a benefit,** go only under these constraints:
  1. **At most 6 hues**, from teal, cyan, blue, indigo, violet and magenta only. Never marigold-adjacent (55–95°), red (0–40°) or green (125–165°) bands.
  2. **The tint is a low-chroma well behind an `ink` icon.** It never colours the icon, the label, the amount, a bar that shows state, or a limit. Icon on well ≥ 3:1 (nonText), label ≥ 4.5:1.
  3. **Equal lightness** across the set, so no category ranks above another, accepting that the tint becomes nearly useless for colour-blind users. Identity stays with the icon and the word.
  4. **Fixed hue per category,** never user-picked. A picker is a setting (PLAN §2), and Monzo shows repeats.
  5. **Spent only, and fewer than 8.** The 2 Got categories and "Other" stay neutral grey. That leaves 7 Spent tiles for 6 hues, so two related categories share one hue, for example Bills and Home (both fixed costs).
  6. **Never on Home's hero, and never in the same place as marigold.**
  7. **A share-of-spend chart** (a Spends breakdown) uses position and labels first, as a labelled bar list. Hue is a secondary cue, never a legend the user must decode.
- **Test that decides it:** a 5-user visual-search and first-click test with Hindi/English, UPI-first users on low-end Android phones.
  - Show the Add tray in two versions, monochrome and tinted wells, in counterbalanced order.
  - Task: "Add ₹200 for medicine".
  - Measure time to tap the right tile, wrong taps, SEQ, and a blind read of what each colour means.
  - Kill condition: anyone reads a tint as good or bad, or the tinted version is not faster.

### 4. Dark vs pale hero (item 5): **go for a dark hero in the light theme, starting from the `inverse` charcoal, after a blind read**
- **Why:**
  - It is the one change that adds the dark mass the benchmarks share.
  - It lets marigold sit bare at 7.43:1 on `inverse` (9.90:1 on `ink`), so `displayEdge` and its special case can go.
  - It matches the dark theme, the app icon (D32) and the ET66 lineage, whose black body V&A confirms.
- **Why charcoal, not ink:** case study 08's process rule is that "a new dark fill starts from `inverse`, not `ink`". The owner has twice called `ink` a slab (case study 08; D46, D47). `ink` stays the fallback if charcoal reads too soft beside the ink text on the page.
- **The pale marigold-tinted hero is a no-go,** because it spreads the signal hue. A pale hero in a second hue is a no-go, because it adds a decorative hue.
- **Conditions that answer D46:**
  1. The hero is the only dark card on Home. Every other card stays `surface`.
  2. Text inside it is at least body size (16sp): `bg` text at 11.49:1, secondary text at ≥ 4.5:1 (dark `ink2` gives 5.31:1 *(calc)*). This offsets the polarity cost for small text.
  3. Idle blocks get a step at ≥ 1.5:1 on `inverse`, about `#4A4945` or lighter. Dark `blockIdle` fails at 1.27:1. Case study 08's ramp rebuild should place this step rather than a one-off value.
  4. Check the ₹0 and empty states for weight, because D46's "heavy" complaint was strongest there.
  5. Keep the Undo snackbar (also `inverse`, D105) distinct from the hero. It already sits apart in position, above the dock. Check whether it also needs an edge or a different step when it appears near the hero.
- **Test that decides it:** repeat case study 05's blind read with 5 users, comparing the current hero, a charcoal hero and an ink hero.
  - Ask: "What is this number? What is the yellow block?" and "Which looks easier to trust?"
  - Then a 5-second test: "What did you notice first?"
  - Kill condition: users read the dark card as a warning or an error state, or the range line is misread more often than on the pale card.

## Conflicts to note
- **D46 (light hero is near-white):** recommendation 4 reverses it. A new row is needed.
- **D10 (no category colours):** recommendation 3 keeps it for now. A conditional reversal would need a new row after the test.
- **D105 (`inverse` snackbar):** a charcoal hero would share the snackbar's fill. The snackbar was chosen dark because it must stand off the cards, so check both together.
- **D8 (calm monochrome + one signal):** a dark hero stays within D8. Category tints would add hues, though never as a signal.
- **UI_DESIGN §3.1** says the ET66 had "a light body, dark keys". The V&A record says "made from black plastic" with black number keys ([V&A](https://collections.vam.ac.uk/item/O1360553)). The lineage text should be corrected (`design-ops`).
- **UI_DESIGN §1** says "no major money app uses a day strip", which this study didn't re-check.

## Proposed principles (merged into `principles.md` as 35–40)
See `principles.md`, section *Colour in fintech (case study 09)*.

## Proposed sources (added to `sources.md`)
wise.design (JavaScript-only) and the oppadu gallery; Monzo help and community; the Jupiter community; the PhonePe design blog and design.phonepe.com; YNAB support `.md` pages; the Copilot help centre; MicroSave briefing notes; V&A collections; Datawrapper Academy; Innovaccer data-viz colour; jfly Colour Universal Design; NN/g dark mode; Apple HIG Branding.

## Open questions
- **How do Google Pay India, PhonePe, Groww, Fi, CRED and Revolut colour their category charts and hero balances on the device?** No public screen material exists. Record the screens before citing them (owner: `design-ux-research`, on-device capture).
- **Does a dark hero cost readability for the range line on a low-end LCD in sunlight?** Check on the moto g45 at full and minimum brightness.
- **Do oral and low-literacy users bring colour meanings to categories,** for example green for food or red for health? This is the blind-read part of the category test.
- **What exact chroma does Material use for neutrals?** The m3 blog didn't render.
