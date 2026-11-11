# 28. Light-theme colours: what other systems do with warm neutrals, and three candidate palettes

Case studies 06, 07, 08 and 09 and `docs/design/colour-proposal.md` already cover token architecture, the grey ramp's missing middle, colour mass, category hues and the D108 warm-neutral method. This study does not repeat them. It adds one thing they lacked: the **actual light neutral ramps of a dozen public systems**, so hisaab's values can be placed among them.

## Question
The owner says the light theme's colours are still not settled. Which questions are really open, what do Figma's own writing and the open-source design systems say about light-theme neutrals, and which two or three palettes should be measured and mocked up next?

## Method
Desk and competitive research on 2026-11-11, the cheapest method that can narrow a colour decision before a mockup. No users, no device. Token files were read from GitHub or unpkg where they could be fetched. Contrast ratios marked *(calc)* are my own WCAG 2 calculations from hex values, using the WCAG ratio `(L1 + 0.05) / (L2 + 0.05)` ([WCAG 2.2, SC 1.4.3](https://www.w3.org/TR/WCAG22/#dfn-contrast-ratio); the page's glossary was not fetched, so the luminance coefficients are from memory of the standard). My arithmetic reproduces hisaab's published numbers (D108 `bg` against `surface` 1.17:1, marigold on `bg` 1.55:1), so I trust it to about 0.01, but it must be re-measured. I had no shell, so **no OKLCH value below is computed by me**: OKLCH appears only where a source publishes it.

## What is actually unsettled
Each item is marked **seen** (in the docs or decisions) or **inferred** (my reading).

| # | Open or shaky | Evidence | Status |
|---|---|---|---|
| 1 | **The page `bg` `#F1EBE4` may read as beige.** D108 rejected "a stronger tint (moves contrast and risks reading as beige)", and case study 09 says "don't go to beige". Its chroma (0.011 at L 0.943) was never compared with a peer set, and the proposal's own on-device check (low-end LCD, daylight) is listed as undone | [D108](../../DECISIONS.md), [case study 09](09-colour-in-fintech.md), [colour-proposal §11](../../design/colour-proposal.md) | **Seen** (risk named, check not recorded as done) |
| 2 | **How warm the tint should be.** D108 chose chroma 0.003–0.016 at hue about 75° by eye from mockup 14, holding each grey's luminance | D108, proposal §2 | **Seen** |
| 3 | **Whether neutrals can fix "unpainted" at all.** The proposal itself says the shift per colour is ΔEOK 0.001–0.007, below the 0.02 JND, "polish ... will not on its own fix 'unpainted'" | [colour-proposal §2](../../design/colour-proposal.md) | **Seen**; that the owner is reopening it **infers** D108 did not fully land |
| 4 | **The grey ramp still has no middle** (0.86 to 0.46 L gap). The fix was proposed in case study 08 as a separate task, and `hisaab_colors.dart` has no such steps | [case study 08](08-colour-retrospective.md), `lib/core/design/hisaab_colors.dart` | **Seen** |
| 5 | **`displayInk2` `#65605A` is off the scale** and stays apart from `ink2` since D90, against principle 27 (roles point to steps) | UI_DESIGN §3.2, D90 | **Seen** |
| 6 | **Layer steps** 1.17 (page to card), 1.30 (card to well), 1.53 (hairline) were set in D45, D92 and D100 and are not shown as contested | D45, D100 | **Seen as settled**; whether they are too strong or too weak against peers is new here |
| 7 | **How marigold sits on light.** Settled by rule (never bare, ink edge, 1.55:1), but the hero's marigold-tinted variant A and the ink-hero variant B in the proposal were not adopted as drafted. D106 chose an etched near-white card, and D106 lists a charcoal hero as rejected | D106, proposal §5 | **Seen**; whether the owner wants this reopened is **inferred** |
| 8 | **Doc drift:** UI_DESIGN §3.1 says the ET66 had a "light body"; the V&A record says it is black plastic | [case study 09](09-colour-in-fintech.md) | **Seen**, for `design-ops` |

Not in doubt, so not researched: contrast floors, the dark theme, the one-signal rule.

## Sources and access
| Source | Read? | Notes |
|---|---|---|
| Figma blog: [The Making of the Figma Pattern Library](https://www.figma.com/blog/figma-pattern-library/), [Updating our web system](https://www.figma.com/blog/updating-our-web-system-for-a-new-era/), [UI refresh (2019)](https://www.figma.com/blog/ui-refresh/), [Inside the redesigned Figma (UI3)](https://www.figma.com/blog/behind-our-redesign-ui3/), [Guide to variables](https://help.figma.com/hc/en-us/articles/15339657135383-Guide-to-variables-in-Figma) | Yes | Structure only. None publishes a neutral ramp or hex values. The "Figma on Figma" UI3 post was not found by search. A figma.com resource-library page I tried returned 404 |
| [Figma forum: UI3 Contrast](https://forum.figma.com/suggest-a-feature-11/ui3-contrast-27870) | Yes | One user's report (Oct 2024). No staff reply |
| [Tailwind v4 `theme.css`](https://raw.githubusercontent.com/tailwindlabs/tailwindcss/main/packages/tailwindcss/theme.css), [v4.3 post](https://tailwindcss.com/blog/tailwindcss-v4-3) | Yes | Real OKLCH values for stone, taupe, olive, mist, mauve, neutral. The post gives the reason in one paragraph and no method |
| [Open Props colours](https://raw.githubusercontent.com/argyleink/open-props/main/src/props.colors.css) | Yes | Hex only; no generation comment |
| [Radix `light.ts`](https://raw.githubusercontent.com/radix-ui/colors/main/src/light.ts), [composing a palette](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette) | Yes | Sand and amber hex. Case study 07 covered Radix's step jobs but gave no values |
| [Atlassian `token-default-values.js`](https://unpkg.com/@atlaskit/tokens/dist/esm/artifacts/token-default-values.js) | Yes | The file marks the light set **deprecated**, so it may predate a refresh. Border is an alpha value |
| Polaris [`colors.ts`](https://raw.githubusercontent.com/Shopify/polaris/main/polaris-tokens/src/colors.ts) and [`themes/base/color.ts`](https://raw.githubusercontent.com/Shopify/polaris/main/polaris-tokens/src/themes/base/color.ts) | Yes | Hex only after joining the two files by index (the theme file names `gray[6]`, the colours file lists the `rgba`). Medium confidence. `token-groups/color.ts` returned 404 |
| Fluent 2 [`lightColor.ts`](https://raw.githubusercontent.com/microsoft/fluentui/master/packages/tokens/src/alias/lightColor.ts), [`colors.ts`](https://raw.githubusercontent.com/microsoft/fluentui/master/packages/tokens/src/global/colors.ts) | Yes | Fetch cleanly. The file names steps, not a "page" role |
| [Adobe Spectrum `color-palette.json`](https://unpkg.com/@adobe/spectrum-tokens/src/color-palette.json) | Partly | 330k characters; read characters 0 to 200k. The `raw.githubusercontent.com` path was 404. The alias file that says which gray is the page was **not** read |
| [Ant Design `genColorMapToken.ts`](https://raw.githubusercontent.com/ant-design/ant-design/master/components/theme/themes/shared/genColorMapToken.ts) and `colorAlgorithm.ts` | Partly | Gives the neutral recipe (darken by 4, 6, 15 and text alpha 0.88 and 0.65). The `generateNeutralColorPalettes` source was not shown, so the hex values are my arithmetic |
| [GitLab Pajamas colour](https://design.gitlab.com/product-foundations/color/) | Yes | The page lists `neutral.10` as `#f7f7f5` in its table and as `#fbfafd` in a sentence, so it contradicts itself |
| Twilio Paste (search summary of an unpkg token file) | Search only | The token yml and palette paths returned 404. Values are from a search summary; low-medium confidence |
| [Untitled UI warm gray](https://www.colorsandfonts.com/color-systems/untitledui-color-system/) | Third-party only | The step labels are inferred by position. untitledui.com returned 404 |
| Material: [dart `scheme_tonal_spot.dart`](https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/dart/lib/scheme/scheme_tonal_spot.dart), [Flutter issue #137679](https://github.com/flutter/flutter/issues/137679), [Flex Seed Scheme tones](https://pub.dev/documentation/flex_seed_scheme/latest/flex_seed_scheme/FlexTones-class.html) | Chroma: source read. Tones: search summary | The typescript `material_dynamic_colors.ts` delegates to a 2026 spec file that was not read |
| [Linear: how we redesigned the UI](https://linear.app/now/how-we-redesigned-the-linear-ui) | Yes | Method, no values |
| [Stripe: accessible colour systems](https://stripe.com/blog/accessible-color-systems), [Lyft coloralgorithm](https://github.com/lyft/coloralgorithm) and [ColorBox write-up](https://wptavern.com/lyft-open-sources-colorbox-algorithm-for-building-accessible-color-systems), [Evil Martians on OKLCH](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl), [Harmony README](https://github.com/evilmartians/harmony), [APCA: why APCA](https://git.apcacontrast.com/documentation/WhyAPCA), [W3C WCAG 3 intro](https://www.w3.org/WAI/standards-guidelines/wcag/wcag3-intro/) | Yes (Lyft via search summary) | Methods. Evil Martians' Figma plugin post is about linking paint styles, not colour generation |
| Anthropic [brand-guidelines skill](https://raw.githubusercontent.com/anthropics/skills/main/skills/brand-guidelines/SKILL.md) | Yes | Anthropic's own palette, but written for slides and documents, not the claude.ai app CSS |
| Notion, Monzo, iA Writer, Zerodha Kite (search summaries; [Brandfetch](https://brandfetch.com/zerodha.com)) | Search only | Third-party and unofficial. See the warm-product table |

Not read or not reachable: Salesforce SLDS 2 values (the Styling Hook Index was not fetched), Uber Base, Radix Themes, Wise (`wise.design` is JavaScript-only, case study 09), Revolut, CRED, Jupiter, Fi, Things, Bear: no published light values found.

## Findings

### A. Figma: structure, not values
1. **Figma's own writing is about how tokens are organised, not which neutrals to pick.** The Pattern Library post says the team moved "from color styles to color variables", with primitives "organized by hue from 100 to 1000" that semantic variables alias, plus modes for light and dark and per product (Design, FigJam, Slides, Dev Mode); a GitHub Action opens a pull request when variables are published ([Figma](https://www.figma.com/blog/figma-pattern-library/)). hisaab already does this (`HisaabColors`, D97 aliases), so this adds nothing new. Confidence: high (official).
2. **Figma paints with whole-surface themes, not with tint.** The web system has "a palette of 29 colors, with 25 in use as backgrounds on web", and variable modes "swap between different background color combinations while ensuring color contrast", with named themes White, Dark Green and Dusty Violet ([Figma](https://www.figma.com/blog/updating-our-web-system-for-a-new-era/)). That is a marketing site with many themes, the opposite of hisaab's one palette, so the lesson is only that "painted" comes from the page colour being a deliberate hue, not a faint tint. The post gives no hex, lightness or neutral rule. Confidence: high that it says so; low that it applies.
3. **Figma chose one contrast method and kept it.** In 2019 the colour group picked WCAG 2 "consistently" ([Figma](https://www.figma.com/blog/ui-refresh/)). hisaab does the same (floors in `contrast_pairs_test.dart`).
4. **A faint card step on white was a real complaint.** After UI3, one forum user (a single report, so low confidence) said `--ramp-grey-100` `#f5f5f5` was "not dark enough compared to 255,255,255", that "the border lines are almost invisible", and asked for `#ececec` ([Figma forum](https://forum.figma.com/suggest-a-feature-11/ui3-contrast-27870)). `#F5F5F5` on white is 1.09:1 *(calc)*; `#ECECEC` is 1.18:1 *(calc)*, almost exactly hisaab's 1.17. It is a said-not-did report from a self-selected forum, but it is the only user-side evidence on the page-to-card step I found.
- **Gap:** I found no Figma post that publishes neutral values or explains how UI3's greys were chosen. The owner's "Figma blogs" yield method and structure, not a palette to copy.

### B. Open-source light neutral ramps

Table 1 lists each system's published light values. "Gap" is the red-minus-blue channel difference, my crude proxy for tint strength (0 is pure grey); it is not OKLCH chroma.

| System | Page | Card / surface | Sunken / subtle | Border | Secondary text | Primary text | Tint (gap on page) | Generation | Source quality |
|---|---|---|---|---|---|---|---|---|---|
| **hisaab D108** | `#F1EBE4` | `#FFFEFC` | `#E7E0D8` | `#D7CFC5` | `#5B5650` | `#161615` | 13 (OKLCH C 0.011, h 72) | Held old luminance, tinted to hue 75° | Own |
| Polaris (base light) | `#F1F1F1` | `#FFFFFF` | `#F7F7F7` and `#F3F3F3` | `#E3E3E3` (secondary `#EBEBEB`) | `#616161` | `#303030` | 0 | Hand-tuned neutral grey | Medium (two files joined) |
| Fluent 2 | `#F5F5F5` (bg3; my pairing) | `#FFFFFF` (bg1) | `#F0F0F0` (bg4) | `#E0E0E0` (stroke2), `#D1D1D1` (stroke1) | `#616161` (fg3) | `#242424` | 0 | Numbered by L-like value (grey 98, 96, 94) | High |
| Atlassian (deprecated light set) | `#FFFFFF` | `#FFFFFF` | `#F8F8F8` | `#0B120E24` (alpha) | `#505258` (subtle), `#6B6E76` (subtlest) | `#292A2E` | -2 (slightly cool) | Hand-tuned | Medium (deprecated set) |
| Adobe Spectrum (palette) | n/a | n/a | gray-50 `#F8F8F8`, 75 `#F3F3F3`, 100 `#E9E9E9` | 300 `#DADADA`, 400 `#C6C6C6` | 600 `#717171`, 700 `#505050` | 800 `#292929`, 900 `#131313` | 0 | Not stated | Medium (roles not read) |
| Ant Design 5 (calc) | `#F5F5F5` | `#FFFFFF` | n/a | `#D9D9D9` (secondary `#F0F0F0`) | black at 65% | black at 88% | 0 | Page is white darkened 4%, border 15%, text as alpha of one base | Medium (recipe read, hex mine) |
| GitLab Pajamas neutral | `#F7F7F5` (neutral.10; page says `#fbfafd` elsewhere) | `#FFFFFF` | `#ECEBEA` (50) | `#DCDBD9` (100) | `#646163` (600) | `#28272D` (900) | 2 | Not stated | Medium (page contradicts itself) |
| Twilio Paste | `#F4F4F6` (gray-10, container) | `#FFFFFF` | `#E1E3EA` (20) | n/a | n/a | `#121C2D` (100) | -2 (blue ramp) | Not stated | Low-medium |
| Radix **sand** | `#FDFDFC` (1) | n/a | `#F9F9F8` (2), `#F1F0EF` (3) | `#DAD9D6` (6), `#CFCEC9` (7) | `#63635E` (11) | `#21201C` (12) | 1 on step 1, 2 on step 3 | Hand-tuned, paired to amber, yellow, orange, brown | High (hex), roles from case 07 |
| Open Props stone | `#F8FAFB` (0) | n/a | `#EBEDEF` (2) | `#D1D6D8` (4) | `#666968` (8) | `#121210` (12) | -3 at the light end, warm (+2) at the dark end | Not stated | High (hex only) |
| Untitled UI warm gray (inferred order) | `#FAFAF9` (50) | `#FDFDFC` (25) | `#F5F5F4` (100) | `#E7E5E4` (200), `#D7D3D0` (300) | `#79716B` (500) or `#57534E` (600) | `#1C1917` (900) | 1 on step 50 | Not stated | Low (third-party, labels inferred) |
| Anthropic brand | `#FAF9F5` | n/a | `#E8E6DC` ("subtle backgrounds") | n/a | `#B0AEA5` ("secondary elements") | `#141413` | 5 on page, 12 on the subtle fill | Not stated | Medium (brand palette, not app CSS) |
| Notion (unofficial) | `#FFFFFF` | n/a | `#F7F6F3` (sidebar) | n/a | n/a | `#37352F` | 4 on the sidebar | Not stated | Low (third-party, may be outdated) |

Table 2 gives the OKLCH values Tailwind v4 publishes, which is the only large public warm-neutral set with real chroma numbers ([theme.css](https://raw.githubusercontent.com/tailwindlabs/tailwindcss/main/packages/tailwindcss/theme.css)). Each cell is L / C / h.

| Step | stone | taupe | olive | mist | neutral |
|---|---|---|---|---|---|
| 50 | 98.5 / 0.001 / 106 | 98.6 / 0.002 / 68 | 98.8 / 0.003 / 107 | 98.7 / 0.002 / 197 | 98.5 / 0 |
| 100 | 97.0 / 0.001 / 106 | 96.0 / 0.002 / 17 | 96.6 / 0.005 / 107 | 96.3 / 0.002 / 197 | 97.0 / 0 |
| 200 | 92.3 / 0.003 / 49 | 92.2 / 0.005 / 34 | 93.0 / 0.007 / 107 | 92.5 / 0.005 / 214 | 92.2 / 0 |
| 300 | 86.9 / 0.005 / 56 | 86.8 / 0.007 / 40 | 88.0 / 0.011 / 107 | 87.2 / 0.007 / 220 | 87.0 / 0 |
| 500 | 55.3 / 0.013 / 58 | 54.7 / 0.021 / 43 | 58.0 / 0.031 / 107 | 56.0 / 0.021 / 214 | 55.6 / 0 |
| 600 | 44.4 / 0.011 / 74 | 43.8 / 0.017 / 39 | 46.6 / 0.025 / 107 | 45.0 / 0.017 / 213 | 43.9 / 0 |
| 900 | 21.6 / 0.006 / 56 | 21.4 / 0.009 / 43 | 22.8 / 0.013 / 107 | 21.8 / 0.008 / 224 | 20.5 / 0 |
| 950 | 14.7 / 0.004 / 49 | 14.7 / 0.004 / 49 | 15.3 / 0.006 / 107 | 14.8 / 0.004 / 229 | 14.5 / 0 |

Material 3 builds its neutrals from the seed hue at fixed HCT chroma: `neutralPalette: TonalPalette.of(sourceColorHct.hue, 6.0)` and `neutralVariantPalette ... 8.0` ([material-color-utilities](https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/dart/lib/scheme/scheme_tonal_spot.dart)). Material's docs reportedly raised neutral chroma from 4 to 6 ([search summary of m3.material.io, page not fetched](https://m3.material.io/blog/tone-based-surface-color-m3)), which closes the "unverified" note in case study 09. HCT chroma is not OKLCH chroma, so the two are not comparable by number.

### C. How hisaab sits in the ramp

5. **Page-to-card step: hisaab is at the top of the range.** Card against page *(calc)*: Polaris 1.13, Spectrum gray-75 1.11, Twilio 1.10, Fluent bg3 1.09, Ant 1.09, GitLab 1.07, Atlassian sunken 1.06, Radix sand step 3 against step 1 1.12, Material tone 94 against 98 1.11. hisaab is 1.17. D45 says Carbon, Apple and Polaris sit at "about 1.10–1.13", so hisaab chose a step slightly larger, for a reason D100 states (controls need 1.15, the `pressStep` floor). The one user-side datum (finding 4) lands at 1.18. **Reading: the layer step is not the problem.** Confidence: medium.
6. **Hairline: hisaab's is at the strong end.** Border against white *(calc)*: Polaris 1.28 (secondary 1.19), Fluent stroke2 1.32, Atlassian about 1.36, GitLab 1.37, Spectrum 300 1.40, Ant 1.41, Radix sand 6 1.40, Fluent stroke1 1.53, Radix sand 7 1.56. hisaab's `hairline` is 1.53 on `surface`. It is that high because one token also serves as `blockIdle` (floor 1.5), chip fills and pressed keys, so this is a consequence of a shared role, not a choice about borders. Confidence: medium.
7. **Secondary text: hisaab is a little darker than peers, and that is forced.** Against white *(calc)*: Fluent fg3 6.19, Polaris 6.19, Radix sand 11 6.04, Atlassian subtle 7.8 and subtlest 5.1, Spectrum 700 8.06. hisaab's `ink2` is 7.20 on `surface` and 6.14 on `bg`. D90 darkened it so it holds 4.5:1 on `hairline` fills (4.71 now). It is not a candidate for change unless `hairline` lightens.
8. **Primary text matches the quiet-warm products.** `ink` `#161615` against Anthropic's `Dark` `#141413`, Radix sand 12 `#21201C`, Tailwind stone-950 L 14.7 and Open Props stone-12 `#121210`. Against white *(calc)*: Fluent 15.5, Atlassian 14.3, Polaris 13.2, sand 12 16.3, hisaab 17.97. Nothing to change. Keeping `ink` near-neutral is the common practice (case study 08).
9. **Tint chroma: the page is the outlier, the deeper steps are only strong.** At comparable L, Tailwind's warm neutrals carry far less chroma than hisaab. hisaab `bg` is L 0.943, C 0.011, h 72 ([colour-proposal §2](../../design/colour-proposal.md)). The nearest Tailwind steps are stone-200 (L 92.3, C 0.003), taupe-200 (92.2, 0.005) and olive-200 (93.0, 0.007): hisaab is 1.6 to 3.7 times as tinted (their L is a little lower, which would, if anything, allow slightly more chroma). hisaab `hairline` is L 0.858, C 0.016; stone-300 is 0.005, taupe-300 0.007, olive-300 0.011, so 1.5 to 3 times. hisaab `ink2` (L 0.456, C 0.012, h 73) almost equals stone-600 (44.4 / 0.011 / 74), so the text step is on pattern. The published hex pairs say the same by gap: Radix sand step 3 gap 2, GitLab neutral.10 2, Anthropic page 5, Notion sidebar 4, against hisaab's 13. The one peer with a comparable gap is Anthropic's **subtle-fill** (12), not its page. Confidence: medium-high that hisaab's page is stronger than these peers; unknown whether that causes "beige" (open question 1).
10. **The common shape is graded chroma: nearly neutral at the light end, rising to a peak at the mid-tones.** Stone, taupe, olive and mist all go from C 0.001–0.003 at step 50 to 0.013–0.031 at step 500, then back to 0.004–0.013 at 900 to 950 (Table 2). Radix tells you what the warm grey is for and warns against the opposite of hisaab's page: pair the grey "saturated with the hue closest to your accent hue" (sand with yellow, amber, orange, brown), but "be careful when using saturated grays for your app background" ([Radix](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette)). hisaab already follows the first half (hue 75° beside marigold's 75°); the second half is the open question.

### D. How a single warm accent lives on a light page

11. **No light palette can make marigold safe on its own; its luminance sets the ceiling.** `#FFB020` has relative luminance about 0.524 *(calc)*, so on pure white it reaches at most about 1.83:1, and on every candidate `bg` below about 1.55:1. WCAG's 3:1 for non-text would need a background of luminance above 1.6, which does not exist. So the choice among neutrals does not change the rule "never bare on light": the ink edge or ink text is permanent. (Principle 84.)
12. **Systems with a warm accent on light handle it in three ways.** (a) A darker sibling for text and lines: Radix amber has a bright step 9 `#FFC53D` for fills, a high-contrast text step 12 `#4F3422`, and a text step 11 `#AB6400` (4.6:1 on white *(calc)*) ([Radix `light.ts`](https://raw.githubusercontent.com/radix-ui/colors/main/src/light.ts)). (b) Accept about 3:1: Anthropic's orange `#D97757` on its `#FAF9F5` page is 2.96:1 *(calc)*, and is a brand accent for fills with text on top ([Anthropic](https://raw.githubusercontent.com/anthropics/skills/main/skills/brand-guidelines/SKILL.md)). (c) Dark text on the bright fill. hisaab does (c) plus an ink edge. Option (a) would add a second marigold value, which conflicts with "one signal colour" (see conflicts), so it is noted and not recommended.
13. **The accent's hue and the neutral's hue are tied in Radix and Material, and that is D108's rule.** Radix sand pairs with amber and Material derives neutrals from the seed hue ([Radix](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette), [Material](https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/dart/lib/scheme/scheme_tonal_spot.dart)). Linear took the opposite lesson from its own redesign: by its article's account (paraphrased here), it limited how much blue chrome entered the colour calculations, for a more neutral, timeless look ([Linear](https://linear.app/now/how-we-redesigned-the-linear-ui)). So there is precedent both ways, and no study on which reads better.

### E. Generation methods relevant to a warm neutral and one accent
14. **Fix lightness first, then choose chroma and hue.** Stripe built its palette in CIELAB so that "uniform contrast across all the hues" holds, with the rule that two colours five steps apart pass 4.5:1 and four steps apart pass 3:1 ([Stripe](https://stripe.com/blog/accessible-color-systems)). Lyft's open-sourced algorithm does the same: colours 0 to 50 pass 4.5:1 on black and 60 to 100 pass 4.5:1 on white ([Lyft coloralgorithm summary](https://wptavern.com/lyft-open-sources-colorbox-algorithm-for-building-accessible-color-systems)). Evil Martians' OKLCH article says `L` is "perceived" lightness, unlike HSL, and that you can fix `L` and `C` and vary `H` ([Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)). Material says a tone gap of 40 guarantees 3:1 and 50 guarantees 4.5:1 (case study 07). This is exactly D108's method (hold luminance, move hue and chroma), so **hisaab's generation method is already the standard one.** Only the chroma curve is unsettled.
15. **Linear reduced a whole theme to three inputs: base colour, accent, and contrast**, in LCH, down from 98 variables ([Linear](https://linear.app/now/how-we-redesigned-the-linear-ui)). For hisaab the equivalent is two numbers per theme (neutral hue, and a chroma curve over L), with each token's L fixed by its role and contrast pair. That makes "how warm" one dial, so a palette comparison is cheap and does not drift token by token (case study 08).
16. **WCAG 2 stays the floor; APCA is a second check, not a replacement.** The W3C calls WCAG 3 "an incomplete draft that will change" (page updated 25 September 2026) and says to "meet WCAG 2.2 success criteria now" ([W3C](https://www.w3.org/WAI/standards-guidelines/wcag/wcag3-intro/)). APCA's author says WCAG 2 "far overstates contrast for dark colors" and that "4.5:1 can be functionally unreadable when a color is near black", and that smaller, thinner text needs more lightness difference ([APCA](https://git.apcacontrast.com/documentation/WhyAPCA)). hisaab's dark-on-light text is not near black, so this mostly affects dark theme and the 13sp `ink2` caption. Evil Martians' changelog note says "just OKLCH is not enough" and to use APCA to detect contrast ([Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)); Harmony claims "OKLCH and APCA" together ([Harmony](https://github.com/evilmartians/harmony)). I did not compute any Lc value.

### F. Warm, paper-like light themes in shipped products
Only what a source states is recorded. Everything not in the table is unsourced.

| Product | What is published | Confidence |
|---|---|---|
| Claude / Anthropic | Brand palette: `#FAF9F5` light, `#E8E6DC` "subtle backgrounds", `#B0AEA5` "secondary elements", `#141413` dark, accents `#D97757`, `#6A9BCC`, `#788C5D` ([Anthropic](https://raw.githubusercontent.com/anthropics/skills/main/skills/brand-guidelines/SKILL.md)). Anthropic's "Mid Gray" is only 2.1:1 on its own page *(calc)*, so it is for shapes, not text | Medium: a brand palette for generated documents, not the app's CSS |
| Notion | Sidebar `#F7F6F3` on a `#FFFFFF` window, text `#37352F` ([notioncolors and others, per a search summary](https://www.notionavenue.co/post/notion-color-code-hex-palette)). A source that read Notion's code in September 2024 lists block colours only | Low: unofficial and possibly dated |
| Monzo | Official: a "blue-toned off white" Soft White beside hot coral and deep navy. Hex: about `#F4F6F5` ([oppadu](https://www.oppadu.com/tools/design-systems-site/brand/monzo.html)) or `#F2F8F3` ([oh-my-design](https://oh-my-design.kr/design-systems/monzo)), and the two sources disagree on navy. The 2022 guide says only two pairings pass AA, Hot Coral on Soft White and Deep Navy on Soft White ([search summary](https://www.deck.gallery/monzo-brand-style-guide-deck/)) | Low for hex, medium for intent. Note: Monzo's off-white is **cool**, not warm |
| Jupiter 2.0 | "stark white has been paired with a warm beige", "easier on the eyes" ([Jupiter staff](https://community.jupiter.money/t/jupiter-2-0-redesign-introducing-a-new-experience/51018)); no hex. One user: "looks dull" (case study 09) | High for the words, none for values |
| Zerodha Kite | Default background white; brand `#387ED1` ([Brandfetch](https://brandfetch.com/zerodha.com)). No warm neutral | Low |
| iA Writer | Only a 2011 third-party analysis (`#F5F6F6` page, `#424242` text) ([data-enhanced](https://data-enhanced.com/2011/06/29/ia-writers-typography-and-color-scheme/)) | Low and old |
| Things, Bear, Wise, Revolut, CRED, Fi | **No published values found** | None |

Reading: the shipped "warm paper" products whose values are public (Anthropic, Notion, GitLab, Radix sand) keep the **page** nearly white-warm (gap 2 to 5) and let the tint show in the second step down. Monzo's off-white is cool. Jupiter's warmer beige drew a "dull" comment. Nothing sourced shows a page as strongly tinted as hisaab's.

## Synthesis: patterns
- **Page-to-card step** 1.06 to 1.13 in peers; hisaab 1.17; the only user datum 1.18.
- **Border** 1.3 to 1.4 by default, up to 1.56 for strong; hisaab's 1.53 is shared with `blockIdle`.
- **Secondary text** 5 to 8:1 on white, about 6:1 most often; hisaab 7.20 on card, 6.14 on page.
- **Primary text** 13 to 18:1; hisaab 17.97.
- **Tint** nearly neutral at the page end (C 0.001 to 0.007 in Tailwind; gap 0 to 5 in hex ramps), strongest mid-ramp (C 0.011 to 0.031), then fading toward the text end. hisaab's tint is flat across the light steps (0.011 to 0.016) and sits at the top of the range on the page.
- **Hue** peers vary: stone 49 to 74°, taupe 34 to 49°, olive 107°, Open Props stone cool to warm, Material follows the seed. hisaab's 72 to 75° is inside stone's range.
- **One warm accent on light** is a fill with dark text or a dark sibling for text, never bare at low contrast; no palette choice changes that for marigold.

## Candidate light palettes

All three keep `ink` `#161615`, `signal` `#FFB020`, `onSignal` `#161615`, `inverse` `#312E29`, `surface` `#FFFEFC`, and the D108 aliases (`control` = `surface`, `blockIdle` = `hairline`, `display` = `surface`, `displayEtch` = `bg`, `focusGap` = `bg`, `clear` = `bg` at 0). They differ only in the neutral tint. Each non-A hex is a **hand-built starting point** that holds D108's relative luminance (so the contrast rows barely move) while changing the red-green-blue split. The OKLCH targets are my estimates from the channel gap and must be re-solved and measured by a follow-up with the `better-colors` skill; I computed none by tool.

| Role | **A. D108, small fix** | **B. Graded paper** | **C. Stronger warm paper** |
|---|---|---|---|
| Idea | Keep D108. Fix only what the research flags as a defect | Page nearly neutral, tint growing with depth, hue about 90° like Radix sand, Anthropic and Tailwind olive | A more clearly warm page (cream), same hue 72°, in the Jupiter-warm-beige direction |
| `bg` | `#F1EBE4` | `#EEECE7` | `#F3EBE1` |
| `surface` / `control` / `display` | `#FFFEFC` | `#FFFEFC` | `#FFFEFC` |
| `sunk` | `#E7E0D8` | `#E5E0DA` | `#E9DFD5` |
| `hairline` / `blockIdle` | `#D7CFC5` | `#D6CFC7` | `#D9CEC1` |
| `ink2` | `#5B5650` | `#595753` | `#5D5550` |
| `displayInk2` | `#5B5650` (alias of `ink2`; was `#65605A`) | `#595753` (alias) | `#5D5550` (alias) |
| Channel gap (R minus B) on bg / sunk / hairline | 13 / 15 / 18 | 7 / 11 / 15 | 18 / 24 / 24 |
| Target OKLCH hue | 72 to 74 | about 90 | 70 to 72 |
| Target chroma on bg / sunk / hairline (estimate) | 0.011 / 0.013 / 0.016 | about 0.006 / 0.009 / 0.012 | about 0.015 / 0.021 / 0.021 |
| Page-to-card *(calc)* | 1.17 | 1.17 | 1.17 |
| Card-to-`sunk` *(calc)* | 1.30 | 1.30 | 1.30 |
| `hairline` on `surface` *(calc)*, floor `idleBlock` 1.5 | 1.53 | 1.53 | 1.54 |
| `hairline` against `sunk` *(calc)*, floor `pressStep` 1.15 | 1.18 | 1.18 | 1.18 |
| `ink2` on `hairline` *(calc)*, floor 4.5 | 4.71 | 4.67 | 4.70 |
| `ink2` on `bg` *(calc)* | 6.14 | 6.11 | 6.17 |
| Marigold on `bg` *(calc)*, never bare | 1.55 | 1.55 | 1.55 |

**Measured (2026-11-11, by script: WCAG 2 relative luminance and OKLCH from sRGB).** Every hand calculation above is confirmed to two decimals, and every pair clears its floor in all three candidates.

| Pair (floor) | A | B | C |
|---|---|---|---|
| `surface` on `bg` (layer) | 1.17 | 1.17 | 1.17 |
| `sunk` vs `surface` (1.15) | 1.30 | 1.30 | 1.30 |
| `hairline` on `surface` (idleBlock 1.5) | 1.53 | 1.53 | 1.54 |
| `hairline` vs `sunk` (pressStep 1.15) | 1.18 | 1.18 | 1.18 |
| `ink` on `bg` (4.5) | 15.30 | 15.34 | 15.33 |
| `ink2` on `bg` / `surface` / `sunk` / `hairline` (4.5) | 6.14 / 7.20 / 5.55 / 4.71 | 6.11 / 7.15 / 5.49 / 4.67 | 6.17 / 7.23 / 5.55 / 4.70 |
| `signal` on `bg` (never bare) | 1.55 | 1.55 | 1.55 |
| `ink` on `signal` (4.5) | 9.90 | 9.90 | 9.90 |

| Measured OKLCH | `bg` | `sunk` | `hairline` | `ink2` |
|---|---|---|---|---|
| A | L 0.943 C 0.011 h 72 | L 0.910 C 0.013 h 71 | L 0.858 C 0.016 h 74 | L 0.456 C 0.012 h 73 |
| B | L 0.943 C 0.007 h 89 | L 0.909 C 0.010 h 73 | L 0.858 C 0.013 h 71 | L 0.457 C 0.007 h 85 |
| C | L 0.944 C 0.016 h 74 | L 0.909 C 0.017 h 68 | L 0.857 C 0.022 h 72 | L 0.456 C 0.013 h 54 |

What measuring changed: B's chroma does grade (0.007 → 0.010 → 0.013), but its hue does not stay near 90°. Only `bg` and `ink2` sit there; `sunk` and `hairline` fall back to about 72°, so B mixes two hues, and a final B should pick one. C's `ink2` drifts to hue 54°, toward brown-red, and should be re-solved at about 72° before any trial. Not measured: APCA, and anything on a device.

Hand-calc check: for B the arithmetic gave `bg` luminance 0.839 against 0.837 for D108; for C 0.839. If a follow-up finds any pair below its floor, nudge the lighter step by one channel value rather than change the idea.

**A. Keep D108, small fix.** The only change is `displayInk2` becoming an alias of `ink2` (7.20 on `surface`, from 6.17), which removes the off-scale grey (principle 27, D90's reason no longer holds since `ink2` is now darker than `#65605A`). Touches: D90, D97, `displayInk2` use in the hero. *Why it can win:* findings 5 to 8 show the layer steps, ink and secondary text are in range, and finding 11 says no palette change touches marigold. *Risk:* leaves finding 9 (page tint is the outlier) and the owner's feeling of "unpainted" unaddressed.

**B. Graded paper (a cooler, quieter page).** Page and card nearly the same cool-warm family as Radix sand and Anthropic's `#FAF9F5`, with the tint growing to the well and hairline, as Tailwind's chroma curve does. Same luminance as D108, so every floor holds by hand calculation. *Touches:* **D108's explicit "OKLCH hue about 75°" and the "warm toward marigold" rule**, so it needs a new DECISIONS row superseding D108's values, plus `splash_bg`/`splash_day`, `08-design-system.html`, mockups 01 to 11 and the test literals. *Honest caveat:* the new `bg` `#EEECE7` is nearly the pre-D108 page `#EEECE6` (D45) that the owner called "unpainted", so B is a return to a value already seen, with a graded step beneath it. It only helps if the problem is the page reading beige (finding 9), not the page reading dull.

**C. Stronger warm paper (cream).** Moves the other way: the page is a visibly warm cream. *Touches:* D108's rejected alternative "a stronger tint (moves contrast and risks reading as beige)", case study 09's "don't go to beige", and Radix's warning on saturated app backgrounds. Evidence against: Jupiter's beige drew a "dull" comment and no sourced warm product tints its page this hard (finding 9). Evidence for: the owner's "unpainted" feeling, and Tailwind's own description of taupe and olive as neutrals with "a little more personality". Include it as the contrast case for the mockup, not as a favourite.

**Ranking from this evidence (research view, not a decision):** A first, as the default, because the evidence shows no defect except the page tint's strength; then B, to test whether a quieter page is what the owner wants; C last. Each is cheap to mock up in the mockup-14 harness. None can answer "does it look unpainted?"; only people on a device can.

## Implications for hisaab (to `design-system` and `design-product`)
`docs/DECISIONS.md` wins until a new row changes it.

1. **Do not expect the neutrals to fix "unpainted".** The evidence (proposal §2, finding 9, finding 2) says the only large "painted" levers in the systems read are a hue-bearing surface mass or a dark brand mass (case study 09), and D108's ΔEOK shift was below a just-noticeable difference. If the owner wants more paint, the candidates outside this study are the ink or charcoal hero (case study 09 rec. 4, D106 rejected C) and category tints (held for a test).
2. **Settle the page tint with a side-by-side on a real phone, not on a monitor.** Mock A, B and C on the real layers (page, card, tray) in the mockup-14 harness, then view them on a low-end LCD at full and minimum brightness in daylight, which the proposal's §11 listed and no doc shows as done. Add a five-person preference read ("which looks cleaner, which looks warmer, which looks like paper") with Hindi and English users; this is preference, not usability, so confidence stays low.
3. **If B or C is chosen, it supersedes D108's values and (for B) its hue rule.** It needs a new DECISIONS row, `contrast_pairs_test.dart` and `hisaab_colors_test.dart` first (TDD), then `hisaab_colors.dart`, `splash_colors.xml` (D108's `splash_bg`, `splash_day`), D134's recents colour (follows `bg`), `day_blocks_test.dart`'s literal hex, UI_DESIGN §3.2 and mockup 08.
4. **Whatever is chosen, fix `displayInk2`** by aliasing it to `ink2` (principle 27); this is independent of the palette.
5. **Keep the ramp-middle task (case study 08) separate.** It adds steps; this study changes tints. Do both only with one mockup.
6. **Adopt a two-number description of the neutral tint** (hue, and a chroma curve over L) in `docs/design/` so "how warm" is one dial (finding 15); the measuring agent can generate all three candidates from it.
7. **Add an APCA readout beside WCAG for `ink2` at 13 to 14sp**, as information only; WCAG 2 floors stay the tests (finding 16).

## Conflicts to note
- **D108** (hue about 75°, "a stronger tint ... risks reading as beige"): B changes the hue, C is the stronger tint it rejected. Either needs a new row.
- **D8 and the one-signal rule**: a darker amber sibling for text (finding 12a) would be a second marigold value. Not proposed.
- **D45** (alternating layers, higher layer never darker): all three keep it.
- **UI_DESIGN §3.2** ("every neutral except `ink` is tinted toward marigold's hue (about 75° in OKLCH)"): B touches it.
- **UI_DESIGN §3.1** still says "light body" for the ET66 (case study 09's flag, not mine).

## Open questions
- The three candidates are drawn side by side with the shipped values in [mockup 37](../../design/mockups/37-light-palette-options.html), for the owner's choice.
- Is the owner's real complaint that the page reads **beige**, **dull**, or **unpainted**? B, A and C answer different ones. One question to the owner settles which mockup matters.
- How do A, B and C look on a low-end LCD in daylight? (Owner: `design-validation`, on device.)
- What is APCA Lc for `ink2` on `bg`, `sunk` and `hairline` at 13 to 14sp, in each candidate?
- What are the exact OKLCH values of the three candidates once solved, and do all contrast rows hold? (Owner: the `better-colors` follow-up.)
- Which gray does Spectrum use as its page, and what are Salesforce SLDS 2's light values? Not read.
- Does Material's neutral chroma of 6 (HCT) correspond to roughly OKLCH 0.008 to 0.012? Not computed; would place Material beside Tailwind.
- Do Wise, Revolut, CRED and Fi tint their light page? No public values; record from the apps.

## Gaps in this research
- Figma publishes no neutral values; the owner's "Figma blogs" gave structure and one forum report only.
- Warm product values for Things, Bear, Wise, Revolut, CRED, Jupiter, Fi and Kite are not sourced; Notion, Monzo and iA Writer are third-party.
- Atlassian's file is a deprecated light set; Polaris, Ant and Spectrum roles are partly my pairing or arithmetic; Twilio is from a search summary; GitLab's page contradicts itself on `neutral.10`.
- Material's tones (98, 94, 92, 90) come from a search summary and a third-party package, not Material's current spec file.
- No OKLCH was computed for any hex above, and all candidate hexes and contrast numbers are hand-calculated.
- No user, device or daylight data of any kind.
