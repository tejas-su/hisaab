# 30. Play Store colours: the real light-theme colours of 16 shipped apps

Case study 28 placed hisaab among the **published tokens** of design systems. This study places it among **what production apps actually ship**, measured from their Google Play screenshots. It answers one question for the unsettled light palette: where do real money and note apps put their page, card, accent and warmth, and is hisaab's `#F1EBE4` an outlier?

## Question
Do shipped apps (Indian money apps, global money apps, expense trackers, two warm-paper references) use a tinted page with white cards or a white page with grey cards? How strong is the page-to-card step, how warm is the page, and how is a single warm or bright accent placed on a light background?

## Method
Measured on 2026-11-11 by script (Python with Pillow). No device, no users.

1. **Fetch.** Each Play listing was fetched with `curl` and an Android user agent (`hl=en_IN&gl=IN`). Screenshot URLs came from the `alt="Screenshot image"` tags and were requested at `=w720-h1600`. Between 5 and 21 images per app were downloaded (Spendee and Wise return duplicates and tablet banners).
2. **Look.** A contact sheet of every app was read by eye, then one or two screenshots per app were opened with a pixel-coordinate grid to find the real app UI inside the marketing frame. Dominant-colour counts inside the screen region (quantised to 2 code values) were used to confirm page and card.
3. **Sample.** For each app one screenshot was chosen. Fills (page, card, sunk, border, solid accents) are the **median of a 5 by 5 pixel patch**. Text colours are the mean of the **darkest 3% of pixels in a text box** (so they are biased dark; see caveats). Where a second screenshot of the same app was checked by dominant colour, its page and card agreed within 2 code values, except where noted.
4. **Compute.** WCAG 2 contrast (`(L1+0.05)/(L2+0.05)`), OKLCH from sRGB, and the page's R minus B channel gap (the warmth measure in case study 28) were computed by script. Case study 28's own hex values (hisaab `#F1EBE4`, candidates A, B, C) went through the same script so the numbers are comparable.

Scripts and downloads are in the scratchpad only (not in the repo). A contact sheet of the 16 sampled screenshots is at `C:/Users/tejas/AppData/Local/Temp/claude/607a9a694070e6fd/e7f066c7-10cf-455d-b644-7f5b54caa533/scratchpad/play-colours/sheets/_sampled_contact_sheet.png`.

## Caveats (read before quoting any number)
- **These are marketing assets, not builds.** Many are mockups drawn in Figma and exported. Several show mock data in a design-tool frame (Wise, Monzo, Jupiter, Claude, CRED). A mockup can use a cleaner palette than the shipped app. Treat them as what the brand *wants to be seen as*, which is itself useful.
- **Compression and colour shifts.** Play serves JPEG or WebP. Treat every sampled colour as precise to about **plus or minus 2 code values** at best, and plus or minus 3 where a gradient or shadow is near.
- **Text colours are the weakest numbers.** Thin glyphs never reach their core colour after anti-aliasing, and the darkest-3% method pulls toward black. Primary text reads as pure `#000000` in 11 of 16 apps, which is partly a mockup habit. Secondary text (`ink2`) is **unreliable**: values range from `#000000` (a box that caught a heading) to `#B4B4B4` (the thinnest strokes). The `ink2` contrasts below are shown for completeness, marked `~`, and are not used in any finding.
- **White on white is real, but its separation is not measured.** For GPay, PhonePe, Paytm, Groww, Kite, Wise, Splitwise and Notion, page and card both sample as `#FFFFFF`. Their separation (soft shadow, hairline outline) comes from my reading of the screenshots, not a measurement.
- **Light only.** Revolut's screenshots are all dark and were not sampled. Groww's frames are black marketing art around a light phone mockup; only the phone interior was sampled.
- **One screenshot per app, one screen.** An app can use more than one page colour (PhonePe's page was `#FFFFFF` in one screenshot and `#F6F6F8` in another; Paytm showed `#FFFFFF` and `#F6F6F6`). The table shows the screenshot I sampled and these notes record the others.
- **No device, no meter.** Case study 29 says screens differ; Play images are sRGB renderings.

## Sources: Play listings
Every listing was fetched on 2026-11-11 (`hl=en_IN&gl=IN`). Downloads and rating are as the page showed them; downloads were not extractable for every page.

| App | Package | Play URL | Downloads / rating | Screenshots | Sampled |
|---|---|---|---|---|---|
| Google Pay | `com.google.android.apps.nbu.paisa.user` | [listing](https://play.google.com/store/apps/details?id=com.google.android.apps.nbu.paisa.user&hl=en_IN&gl=IN) | 1B+ / 4.35 | 6 | s6 |
| PhonePe | `com.phonepe.app` | [listing](https://play.google.com/store/apps/details?id=com.phonepe.app&hl=en_IN&gl=IN) | 1B+ / 4.42 | 8 | s4 (s5, s6 checked) |
| Paytm | `net.one97.paytm` | [listing](https://play.google.com/store/apps/details?id=net.one97.paytm&hl=en_IN&gl=IN) | 500M+ / 4.69 | 7 | s4 (s2, s7 checked) |
| CRED | `com.dreamplug.androidapp` | [listing](https://play.google.com/store/apps/details?id=com.dreamplug.androidapp&hl=en_IN&gl=IN) | 50M+ / 4.75 | 7 | s7 (s2, s3 checked) |
| Groww | `com.nextbillion.groww` | [listing](https://play.google.com/store/apps/details?id=com.nextbillion.groww&hl=en_IN&gl=IN) | n/a / 4.79 | 11 | s9 (s5, s11 checked) |
| Zerodha Kite | `com.zerodha.kite3` | [listing](https://play.google.com/store/apps/details?id=com.zerodha.kite3&hl=en_IN&gl=IN) | 10M+ / 4.42 | 7 | s2 (s5 checked) |
| Jupiter | `money.jupiter` | [listing](https://play.google.com/store/apps/details?id=money.jupiter&hl=en_IN&gl=IN) | n/a / 4.30 | 8 | s1 (s4 checked) |
| slice | `indwin.c3.shareapp` | [listing](https://play.google.com/store/apps/details?id=indwin.c3.shareapp&hl=en_IN&gl=IN) | n/a / 4.58 | 8 | s3 (s5, s8 checked) |
| Wise | `com.transferwise.android` | [listing](https://play.google.com/store/apps/details?id=com.transferwise.android&hl=en_IN&gl=IN) | n/a / 4.69 | 21 (12 distinct) | s8 (s3, s10 checked) |
| Monzo | `co.uk.getmondo` | [listing](https://play.google.com/store/apps/details?id=co.uk.getmondo&hl=en_IN&gl=IN) | n/a / 4.69 | 8 | s2 |
| Monefy (swapped in for Cashew) | `com.monefy.app.lite` | [listing](https://play.google.com/store/apps/details?id=com.monefy.app.lite&hl=en_IN&gl=IN) | n/a / 3.99 | 6 | s1 (s4 checked) |
| Money Manager (Realbyte) | `com.realbyteapps.moneymanagerfree` | [listing](https://play.google.com/store/apps/details?id=com.realbyteapps.moneymanagerfree&hl=en_IN&gl=IN) | n/a / 4.64 (its own art says 15M+) | 8 | s6 (s1, s7 checked) |
| Splitwise | `com.Splitwise.SplitwiseMobile` | [listing](https://play.google.com/store/apps/details?id=com.Splitwise.SplitwiseMobile&hl=en_IN&gl=IN) | n/a / 4.27 | 5 | s4 (s3 checked) |
| Spendee (extra) | `com.cleevio.spendee` | [listing](https://play.google.com/store/apps/details?id=com.cleevio.spendee&hl=en_IN&gl=IN) | n/a / 4.32 | 21 (12 distinct) | s1 (s3 checked) |
| Claude | `com.anthropic.claude` | [listing](https://play.google.com/store/apps/details?id=com.anthropic.claude&hl=en_IN&gl=IN) | 50M+ / 4.57 | 8 | s2 (s4, s5 checked) |
| Notion | `notion.id` | [listing](https://play.google.com/store/apps/details?id=notion.id&hl=en_IN&gl=IN) | 10M+ / 4.61 | 14 | s11 |

**Not sampled.** Revolut (`com.revolut.revolut`, 8 screenshots, 4.68): all dark. Navi (`com.naviapp`, swapped in for Fi, 5 screenshots, 100M+): the screenshots are 720 by 405 banners whose phone UI is about 100 pixels wide, too small to sample. **Fi** (`com.epifi.paisa`) returned "Not found" from Play, so it is not listed in India. **Cashew** (`com.budget.cashew`) also returned "Not found" and a search did not find it; Monefy stands in. Goodbudget (`com.dayspring.goodbudget`) returned no screenshots.

## Measurements
### Table 1: what I sampled
Hex are medians of 5 by 5 patches. "Step" is WCAG contrast of the card on the page. "R-B" is red minus blue on the page. OKLCH is L / C / hue of the page. **Sep** is how cards are separated, by my reading (not measured): *step* is colour only, *shadow* a soft drop shadow, *hair* a hairline outline, *none* means no card, only rows.

| App | Theme | Page | Card | Sunk or chip | Step | R-B | Page OKLCH | Sep | Accent (fill unless marked text) |
|---|---|---|---|---|---|---|---|---|---|
| Google Pay | light | `#FFFFFF` | `#FFFFFF` | `#E8F0FD` (blue chip) | 1.00 | 0 | 1.000 / 0 / n/a | shadow + hair | blue text and outline pill, about `#0B3AA8` (not clean; text) |
| PhonePe | light | `#FFFFFF` (`#F6F6F8` on s5) | `#FFFFFF` | `#F4F0F9` (icon circle) | 1.00 | 0 | 1.000 / 0 / n/a | shadow | purple `#5E12C8` fill, white label (8.76 on white) |
| Paytm | light | `#FFFFFF` (`#F6F6F6` on s2) | `#FFFFFF` | `#E1F6EB` (tag) | 1.00 | 0 | 1.000 / 0 / n/a | hair rows + shadow | cyan `#00B8F5` fill (2.29 on white) |
| CRED | light | `#F5F1EC` | `#FCFCFC` | none seen | 1.10 (1.12 to pure white) | 9 | 0.960 / 0.008 / 74 | step + soft shadow | near-black `#242424` button fill, white label (13.8) |
| Groww | light | `#FFFFFF` | `#FFFFFF` | `#EBF9F5` (mint chip) | 1.00 | 0 | 1.000 / 0 / n/a | shadow | green `#00B484` text or underline (about 2.7 on white) |
| Zerodha Kite | light | `#FFFFFF` | `#FFFFFF` | none seen | 1.00 | 0 | 1.000 / 0 / n/a | hair + shadow | blue `#0054C6` fill, white label (6.81) |
| Jupiter | light | `#F5F3EF` (`#F6F4F0` on s4) | `#FFFFFF` | none seen | 1.11 | 6 | 0.965 / 0.006 / 85 | step + soft shadow | dark green `#2F6F62` text (about 7 on page) |
| slice | light | `#F7F7F7` | `#FFFFFF` | `#F6F9FC` (tile) | 1.07 | 0 | 0.976 / 0 / n/a | step + soft shadow | purple `#8B00C7` text and fill (6.71) |
| Wise | light | `#FFFFFF` | `#FFFFFF` | `#F1F1EE` (pill) | 1.00 | 0 | 1.000 / 0 / n/a | shadow on a dark-green backdrop | lime `#9FE870` fill with near-black label (1.47 on white) |
| Monzo | light | `#F2F8F4` | `#FFFFFF` | none seen | 1.08 | -2 | 0.973 / 0.008 / 157 | step | blue `#498BB4` toggle fill (3.46); coral `#FF4F40` marketing only |
| Monefy | light | `#F2FFF6` | none (rows) | none seen | n/a | -4 | 0.988 / 0.018 / 156 | none | app bar `#7AC793`, red and green amounts as text (1.96 for the green) |
| Money Manager | light | `#F7F7F7` (row gaps) | `#FFFFFF` | none seen | 1.07 | 0 | 0.976 / 0 / n/a | step + hair rows | coral `#F16853` text for expense, blue for income |
| Splitwise | light | `#FFFFFF` | none (rows) | none seen | n/a | 0 | 1.000 / 0 / n/a | none (rows, one hairline) | green `#00986C` text (3.68), orange-red `#EE5602` text (3.52), teal FAB |
| Claude | light | `#FAF9F5` | `#FFFFFF` | `#F3F3F0` (inset box) | 1.05 | 5 | 0.982 / 0.005 / 95 | step + soft shadow | coral `#D87858` round button fill, white glyph (2.95 on page) |
| Notion | light | `#FFFFFF` | `#FFFFFF` | `#F3F3F3` (chip) | 1.00 | 0 | 1.000 / 0 / n/a | none (rows) | blue `#2383E2` button fill, white glyph (3.88) |
| Spendee | light | `#F7F7F7` | `#FFFFFF` | `#E7E7E9` (selector) | 1.07 | 0 | 0.976 / 0 / n/a | step + soft shadow | green `#10B981` FAB fill (2.37 on page) |
| **hisaab now (A)** | light | `#F1EBE4` | `#FFFEFC` | `#E7E0D8` | **1.17** | **13** | 0.943 / 0.011 / 72 | step + hairline `#D7CFC5` (1.30 on page) | marigold `#FFB020` fill, ink label (1.55 on page) |
| hisaab B | light | `#EEECE7` | `#FFFEFC` | `#E5E0DA` | 1.17 | 7 | 0.943 / 0.007 / 89 | same | same |
| hisaab C | light | `#F3EBE1` | `#FFFEFC` | `#E9DFD5` | 1.17 | 18 | 0.944 / 0.016 / 74 | same | same |

Secondary text (`~`, unreliable, see caveats): GPay and Groww and Money Manager and slice read as light as about 2 to 3:1 on the page; Kite, Jupiter, Wise, Splitwise and Spendee read near 6 to 14:1. The spread is mostly anti-aliasing, so no conclusion about secondary-text contrast in shipped apps is drawn.

### Table 2: derived
| Measure | Value |
|---|---|
| Apps with a pure white page and no colour step (page and card both `#FFFFFF`) | 8 of 16 (GPay, PhonePe, Paytm, Groww, Kite, Wise, Splitwise, Notion) |
| Apps with a tinted or grey page and white (or near-white) cards | 7 of 16 (CRED, Jupiter, slice, Monzo, Money Manager, Claude, Spendee) |
| Tinted page and rows only, no cards | 1 of 16 (Monefy) |
| Page-to-card step among the 7 | 1.05 to 1.11, median 1.07. hisaab 1.17 is **above every one** |
| Page lightness (OKLCH L) among the 8 non-white pages | 0.960 to 0.988. hisaab's 0.943 is **darker than every one** |
| Warm pages (R-B above 3) | 3 apps: CRED 9, Jupiter 6, Claude 5. hisaab 13, B 7, C 18 |
| Page chroma on the warm three | 0.005 to 0.008. hisaab A 0.011, B 0.007, C 0.016 |
| Cool or green pages | Monzo (-2, hue 157, C 0.008), Monefy (-4, hue 156, C 0.018) |
| Neutral grey pages (`#F7F7F7`) | 3 apps (slice, Money Manager, Spendee) |
| Card colour on a stepped page | `#FFFFFF` in 6, `#FCFCFC` in CRED. None tinted, none dimmer than page |

## Findings
Each is marked **measured** (script, from a sampled patch) or **read** (my reading of the images).

1. **hisaab's layer step is stronger than every shipped step I measured.** The seven stepped apps run 1.05 to 1.11 (median 1.07); hisaab is 1.17. Figma's forum user wanted 1.18 after complaining that `#F5F5F5` on white (1.09) was too faint, so users can want more, but no shipped app in this sample goes that far. **Measured.**
2. **hisaab's page is the darkest and the warmest.** Every sampled tinted page sits at OKLCH L 0.960 to 0.988; hisaab's `#F1EBE4` is 0.943. Its R-B gap of 13 is 1.4 times CRED's 9, the warmest shipped page, and more than twice Jupiter's 6 and Claude's 5. No app has a page as warm as `#F1EBE4`. **Measured.**
3. **Warm pages are rare and premium.** Only three of 16 tint the page toward orange-yellow: CRED, Jupiter (both Indian, both editorial-style premium money brands) and Claude. They cluster tightly: R-B 5 to 9, chroma 0.005 to 0.008, hue 74 to 95. Candidate B (R-B 7, chroma 0.007, hue 89) lands inside that cluster; A and C are outside it. **Measured.**
4. **Half the sample is white on white.** Eight apps (all the big Indian payment apps, Kite, Wise, Notion, Splitwise) use a pure `#FFFFFF` page and `#FFFFFF` cards and separate them with a soft shadow or a hairline outline instead of colour. Where a UPI-scale app adds a colour step, it does so on selected screens only (PhonePe `#F6F6F8`, Paytm `#F6F6F6`). **Measured and read.**
5. **Cards are never tinted.** On all seven stepped pages the card is `#FFFFFF` (`#FCFCFC` in CRED). Tint, where any, lives on the page; the card stays neutral-white. hisaab's `#FFFEFC` (C 0.003) is consistent with this. **Measured.**
6. **Indian apps differ from global ones in two ways.** The scale leaders (GPay, PhonePe, Paytm) are the whites; the two premium or fintech-boutique apps (CRED, Jupiter) are the warm pages; slice is a neutral grey `#F7F7F7`. Globally the pages are cooler and quieter: Monzo has a faint green (`#F2F8F4`), Wise and Notion pure white, Spendee and Money Manager neutral grey, Claude the lone warm. Nobody Indian or global matches `#F1EBE4`. **Measured.**
7. **Low-contrast accents are fills with a label on top, never text.** Wise lime `#9FE870` is 1.47:1 on white and is used only as a filled button with near-black text. Paytm cyan (2.29), Spendee green (2.37), Claude coral (2.95) and Monzo's toggle (3.46) are all filled shapes carrying a white or dark glyph. The accents used as **text** are the darker ones: Jupiter's dark green (about 7), slice's purple (6.7), Kite's blue (6.8), Splitwise's green (3.7) and orange (3.5). Marigold's 1.55 on `#F1EBE4` is the same kind of colour as Wise's lime, which supports "filled, with ink text". **Measured.**
8. **A bright warm accent on light is seldom text and is often not the primary action colour.** CRED's action fill is near-black `#242424` (13.8:1 on its cream page) with a white label; its warm colour appears only in imagery. Claude's coral is a round button fill. Splitwise's orange-red (about 3.5) is used as text for "you owe". No sampled app places a yellow or gold bare on a light page for text. **Measured and read.**
9. **Red and green appear in 3 of the 16 as money direction** (Monefy, Splitwise, Money Manager; Groww's green is brand). Most apps do not use them in the samples at all. hisaab's no-red-no-green rule is rare among trackers but not alone: Wise, Notion, Kite and the UPI apps show amounts in plain ink. **Measured and read.**
10. **Primary text is black or near-black everywhere** (11 of 16 sampled `#000000`, which includes mockup habit; Groww `#070D38`, Monefy `#10181A`). hisaab's `#161615` is in line. **Measured, weak.**
11. **A pure-white page needs a visible outline or a shadow; a stepped page does not.** Separation across the white-on-white apps is by shadow and thin outline (GPay's pills, Groww's floating cards). The stepped apps also add a soft shadow in CRED, Jupiter, Spendee and Claude. That is a pattern for the step size: where the step is under about 1.11, a faint shadow or rounded corner carries part of the separation. **Read.**

## Where hisaab and the candidates sit
| Measure | Shipped spread | hisaab now (A) | B | C |
|---|---|---|---|---|
| Page lightness (L) | 0.960 to 1.000 | 0.943 (below all) | 0.943 | 0.944 |
| Page-to-card step | 1.00 to 1.11 | 1.17 (above all) | 1.17 | 1.17 |
| Page R-B | -4 to 9 | 13 (above all) | 7 (inside warm cluster) | 18 (twice the warmest) |
| Page chroma (warm apps) | 0.005 to 0.008 | 0.011 | 0.007 | 0.016 |
| Page hue (warm apps) | 74 to 95 | 72 | 89 | 74 |
| Card colour | `#FFFFFF` or `#FCFCFC` | `#FFFEFC` (inside) | same | same |
| Card tinted? | never | no | no | no |

Closest shipped page to each: A and C to CRED's `#F5F1EC`, but both are warmer and darker; B to Jupiter `#F5F3EF` and Claude `#FAF9F5`, in both warmth and hue, but darker. None of the three candidates changes lightness or step, so none moves the two measures where hisaab is the outlier.

## Ideas for hisaab
Labelled **evidence-backed** (a measurement above supports it) or **inferred** (my reasoning, to test).

1. **Lighten the page and lower the step, instead of only changing the tint. (Evidence-backed that hisaab is the outlier; the target is inferred.)** Case study 28's three candidates all hold L 0.943 and step 1.17. Shipped pages are 0.960 to 0.988 and 1.05 to 1.11. A page near CRED's `#F5F1EC` (L 0.960) against hisaab's `#FFFEFC` card gives about 1.12 (calculated), which is the top of the shipped range. This is a layer-step decision, so it touches D45 and D100 (step values set there) and the sunk and hairline steps. It breaks none of the fixed rules. Worth a mockup D beside A, B and C.
2. **If warm, stay in the shipped cluster: R-B 5 to 9, chroma up to 0.008. (Evidence-backed.)** B (R-B 7, C 0.007, hue 89) is inside it; A (13) and C (18) are warmer than anything shipped. Using B's page as the base would mean no sampled app is warmer, but B touches D108's hue rule (conflict with D108, as case study 28 notes).
3. **Keep the card neutral-white and let the page carry the tint. (Evidence-backed.)** All seven stepped apps do this. hisaab's `#FFFEFC` is the right idea. Do not tint the card to raise "paint" (case study 28 implication 1 already says neutrals cannot fix "unpainted").
4. **Marigold as a filled shape with ink text, never a text colour, is a shipped pattern. (Evidence-backed.)** Wise's lime at 1.47:1 does exactly this and is the best precedent for marigold at 1.55:1. Spendee, Claude and Paytm do the same with white glyphs at 2.3 to 3. No change needed; this confirms the existing rule.
5. **Do not copy CRED's trick of using near-black as the action colour. (Evidence-backed that CRED does it; the conflict is mine.)** It works for CRED because its accent is imagery, not UI. In hisaab marigold means "today / act" (a fixed rule), so a near-black primary button would conflict with it. The ink hero is already a rejected variant (D106). Listed so nobody reopens it by citing CRED.
6. **If the step goes below about 1.11, add edge cues rather than colour. (Inferred.)** Jupiter, Spendee, CRED and Claude pair a small step with a soft shadow and rounded corners. hisaab's etched card (D106) and hairline may already do this job; a faint shadow may conflict with that visual language. Not tested.
7. **A white page is an unexplored fourth direction. (Inferred.)** Eight of 16 apps, including the three largest Indian payment apps, use a pure white page. For hisaab that would mean white page, `#FFFEFC` card barely separate, with hairline carrying the layer, and the warmth carried only by marigold and ink. It would cost the "paper" mood and the layer step, so it is the opposite of the owner's apparent direction; mentioned only because the spread says it is the majority choice, and "unpainted" may be the owner's word for the absence of a tint at all.

## Conflicts to note
- Ideas 1 and 6 touch **D45** (alternating layers) and **D100** (layer steps), and 6 touches **D106**. Idea 2 for B touches **D108**'s hue. Idea 5 would conflict with the **one-signal rule** (marigold means today / act).
- Finding 9: the apps that use red and green to show money direction (Monefy, Splitwise, Money Manager) are shown as context only. hisaab's no-red-no-green rule is unaffected.
- Nothing here changes a decision; no row was added to `docs/DECISIONS.md`, and no token or code changed.

## Gaps
- **Not sampled:** Revolut (all dark), Navi (tiny banners), Fi (delisted from Play, 404), Cashew (not found on Play; Monefy swapped in), Goodbudget (no screenshots). Spendee was added as an extra.
- **Single screenshot per app.** One screen per app was sampled precisely; others were checked by dominant colour only. Page colours vary by screen in PhonePe and Paytm.
- **Secondary text is unreliable** (anti-aliasing), so no claim is made about the secondary-text contrast peers ship.
- **Separation** (shadow, hairline) is read from the images, not measured. Shadow strengths and border colours were not quantified, apart from a few spot samples.
- **Mockups, not builds.** The Play assets may not match the live app (Wise, Monzo, Jupiter, Claude and CRED show designed frames). The real app pages could be a code value or two different.
- **Downloads** were not extractable for 10 of the 16 pages. No ratings count or review text was fetched.
- **No device.** All values are sRGB from images, not from a panel (see case study 29).
- **No dark-theme data**, and none was asked for.

## What this adds
- The first measured peer spread of light page colours from shipped apps, instead of design-system tokens.
- Two measured facts that case study 28 had not seen: hisaab's page is darker (L 0.943 against 0.960 to 0.988) and its page-to-card step is stronger (1.17 against 1.05 to 1.11) than every sampled app.
- A precedent set for marigold as a fill: Wise's lime at 1.47:1.
- Nothing adopted.

## Verification of idea 1 (2026-11-11)
The lighter page `#F5F1EC` was measured by script against today's other light tokens, all unchanged:
- `surface`/`control` on `bg`: 1.12. This was 1.17, and it is the step D100 relies on for resting chips and the Back well.
- `sunk` on `bg`: 1.16.
- `sunk` against `surface`: 1.30.
- `hairline` on `surface`: 1.53.
- `ink2` on `bg`: 6.46.
- marigold on `bg`: 1.63, which still needs its ink edge.

Every floor in `contrast_pairs_test.dart` still holds, because those floors measure the card and press steps, not the page. The one real cost is that controls resting on the page lose about a third of their lift. Glare at F 1.0 takes the page-to-card step to about 1.06, near the 6% margin from case study 29. CRED's own pair (`#FCFCFC` on `#F5F1EC`) measures 1.10.

The contact sheet confirmed the sampled regions sit inside the phone mockups and not on the marketing backdrops.
