# Design systems: Groww MINT, Material 3, Primer, Radix, Atlassian, Razorpay Blade

## Question
What can hisaab's colour tokens (`lib/core/design/hisaab_colors.dart`, `hisaab_theme.dart`, UI_DESIGN §3.2 and §3.5) learn from public design systems? The focus is on five known gaps:

1. Our own controls have no focus ring.
2. There is no high-contrast token set.
3. Material colour roles we don't set fall back to marigold.
4. Some widgets use `Colors.transparent` directly.
5. Some tokens only alias others (`display` = `surface`, `displayInk` = `ink`).

## Method
Desk research only (2026-10-29), with no users involved. This is the cheapest method that can change a token decision, because every question here is about how other systems build their tokens, not about how people behave. Every claim links to the page or file it came from. Where a page didn't load, this study says so. Contrast ratios marked *(calc)* are my own WCAG 2 calculations from published hex values, not figures the source gives.

### Access notes
- **m3.material.io** returned only page titles for *Color roles*, *The science of color & design* and *Advanced color customizations*. **m2.material.io** (the dark theme page) had no body text either. Material facts below come from Android developer docs, the Flutter API, and Material's open-source code.
- **Groww** has no public design-system site, blog post or case study about MINT. The only public artefact is the npm package `@groww-tech/mint-css`, read through unpkg. npmjs.com returned 403. [Figma's customer story](https://www.figma.com/customers/figma-helps-groww-simplify-investing/) confirms the design team and a design-systems lead, but says nothing about tokens.
- **Atlassian**'s colour page didn't list its neutral steps, and no high-contrast theme announcement was found.
- **Primer**'s token-naming page fetched cleanly. The colour page was truncated, but the theme list and contrast rules were confirmed from the `primer/primitives` repo.

## Findings by system

### 1. Groww MINT (Indian fintech)
**Publicly documented.** MINT is published as [`@groww-tech/mint-css`](https://app.unpkg.com/@groww-tech/mint-css@0.3.8/files/README.md), described as "a CSS library that provides classes, tokens, variables, fonts and other essential stylings governed under MINT design system, used by Groww". It ships a token fragment (`allVariables.css`), font faces (GrowwSans), theme utilities and type utilities. The README has no versioning policy, though unpkg lists versions up to 0.4.0.

Everything below comes from reading [`allVariables.css` (v0.4.0)](https://app.unpkg.com/@groww-tech/mint-css@0.4.0/files/dist/fragments/allVariables.css):

- **Architecture:** primitives (`--gray50`…`--gray900`, `--green1`…`--green12`, `--neutral1`…`--neutral12`, and others) sit under semantic tokens grouped by property: `--content-*`, `--background-*` and `--border-*`. Dark mode is `html[data-theme=dark]`.
  - Dark mode redefines the **primitives themselves**. For example, `--gray700` is #7c7e8c in light and #b8b8b8 in dark, so a semantic token points at the same primitive name in both themes.
- **Neutral scale:** `gray` uses 50–900 (11 steps), and `neutral` uses 1–12.
  - `content-primary` is gray900 (#44475b), `content-secondary` is gray700 (#7c7e8c) and `content-tertiary` is gray500 (#a1a3ad).
  - On white, secondary is about 4.0:1 and tertiary about 2.5:1 *(calc)*, so the secondary text tier is below WCAG's 4.5:1.
- **Dark and elevation:** the page is #121212 and `surface-primary` is #1b1b1b, so a higher layer is lighter. There are named elevation tokens `background-surface-z1`, `surface-z2` and `surface-docked`. Borders are tuned per layer: `border-primary-on-surface-z1` and `-z2`.
- **Gains and losses:** `--content-positive` is green9 (#04b488) and `--content-negative` is red9 (#ed5533 in light, #ff5e3b in dark), with matching `background-` and `border-` tokens. Green text on white is about 2.7:1 *(calc)*.
- **Numbers:** the font weights are variable-font values (`--font-weight-regular: 435`, `medium: 535`, `bold: 660`). The file sets no `font-variant-numeric` or tabular figures.
- **Inferred, not documented:**
  - The numbered `green1–12` and `neutral1–12` scales look modelled on Radix's 12 steps. Groww doesn't say so.
  - How the app (not the web CSS) sets numbers is unknown.
  - Focus, high contrast, colour-blind support and governance: nothing public.

### 2. Material Design 3
- **Architecture:** five key colours (primary, secondary, tertiary, error, neutral), each with "a tonal palette of 13 tones" ([Android, Material 3 in Compose](https://developer.android.com/develop/ui/compose/designsystems/material3)). Roles come in `x` / `on-x` pairs, named `--md-sys-color-<token>`, and "all tokens have a corresponding `--md-sys-color-on-<token>`" ([material-web color docs](https://github.com/material-components/material-web/blob/main/docs/theming/color.md)).
- **Perceptual neutral scale (HCT):** HCT is "hue, chroma, tone, based on CAM16 x L*" ([material-color-utilities](https://github.com/material-foundation/material-color-utilities/blob/main/README.md)). Tone is L*, which is linear in perceived lightness.
  - Material's HCT code states: "A difference of 40 in HCT tone guarantees a contrast ratio >= 3.0" and "a difference of 50 guarantees a contrast ratio >= 4.5" (quoted in the [Go port's docs](https://pkg.go.dev/cogentcore.org/core/colors/cam/hct)).
  - Each role is therefore a tone, and contrast follows from the tone gap.
- **Surfaces and elevation:** Flutter's 2024 migration added seven tone-based surfaces: `surfaceBright`, `surfaceDim` and `surfaceContainerLowest` through `surfaceContainerHighest`. It deprecated `background`, `onBackground` and `surfaceVariant`.
  - It also replaced "the old opacity-based model that applied a tinted overlay on top of surfaces based on their elevation". The default `surfaceTintColor` is now `null` ([Flutter breaking change](https://docs.flutter.dev/release/breaking-changes/new-color-scheme-roles)).
  - The Compose page still describes tonal overlays from the primary colour ([Android](https://developer.android.com/develop/ui/compose/designsystems/material3)), so the docs disagree on the current model.
- **Contrast levels:** in Flutter, `ColorScheme.fromSeed(contrastLevel:)` uses 0.0 for standard, and "the medium and high contrast correspond to 0.5 and 1.0" ([Flutter API](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html)).
  - On Android, the MDC `ColorContrast` class applies the user's system contrast level to a custom theme, and "if you are already using dynamic colors, contrast will be applied automatically on Android U+" ([Android reference](https://developer.android.com/reference/com/google/android/material/color/ColorContrast)).
  - Flutter's `MediaQueryData.highContrast` "is currently only updated on iOS devices running iOS 13+ and Android devices running API 34+", and `MaterialApp` uses it to choose `highContrastTheme` or `highContrastDarkTheme` ([highContrast](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html), [highContrastTheme](https://api.flutter.dev/flutter/material/MaterialApp/highContrastTheme.html)).
  - The exact ratios for each level weren't found, because m3.material.io didn't render.
- **Fallbacks for unset roles (the marigold gap):** Flutter's `ColorScheme` constructor requires only nine colours. "If a color is not provided, the closest fallback color from the given colors will be used", and "it is still recommended that applications provide values for them" ([Flutter API](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.html)).
  - In the implementation, `tertiary => _tertiary ?? secondary` ([tertiary](https://api.flutter.dev/flutter/material/ColorScheme/tertiary.html)) and `secondaryContainer => _secondaryContainer ?? secondary` ([secondaryContainer](https://api.flutter.dev/flutter/material/ColorScheme/secondaryContainer.html)).
  - The surface containers fall back to `surface` ([surfaceContainerLow](https://api.flutter.dev/flutter/material/ColorScheme/surfaceContainerLow.html), [surfaceContainerHigh](https://api.flutter.dev/flutter/material/ColorScheme/surfaceContainerHigh.html)).
  - hisaab sets `secondary: signal`, so every Material widget that reads `tertiary` or `secondaryContainer` turns marigold.
- **Transparent:** Flutter's own `Color.lerp` docs warn that `Colors.transparent` "is specifically transparent *black*", and that lerping from a transparent copy of the other colour "is usually preferable" ([Color.lerp](https://api.flutter.dev/flutter/dart-ui/Color/lerp.html)).
- **Focus:** Flutter hides focus highlights in touch mode ("will not show the focus highlight except for controls which bring up the soft keyboard") and shows them in traditional keyboard-and-mouse mode ([FocusHighlightMode](https://api.flutter.dev/flutter/widgets/FocusHighlightMode.html)).

### 3. GitHub Primer
- **Architecture:** there are three layers ([colour usage](https://primer.style/product/getting-started/foundations/color-usage/)):
  - **Base tokens** "should never be used directly in code or design".
  - **Functional tokens** (`bgColor-*`, `fgColor-*`, `borderColor-*`) reference base tokens, follow the colour mode, and are "the most commonly used".
  - **Pattern tokens** are component-specific and used sparingly.
- **Naming:** names follow namespace, pattern, variant, property, scale, for example `control-danger-borderColor-rest` or `base-color-green-5` ([token names](https://primer.style/product/primitives/token-names/)).
- **Neutral scale:** 0–13 including white and black ([colour usage](https://primer.style/product/getting-started/foundations/color-usage/)).
  - Steps 0–5 are backgrounds, steps 7–8 are borders (8 is the minimum for control borders), and steps 9–10 are text (9 is the minimum on steps 0–4, and 10 on steps 5–6). Each step is assigned to a use and to a contrast floor.
- **Dark:** "The light and dark scale directions are inverted", so both themes "share many of the same functional color tokens" ([colour usage](https://primer.style/product/getting-started/foundations/color-usage/)).
- **Themes:** there are nine: light, light-high-contrast, light-colorblind, light-tritanopia, dark, dark-dimmed, dark-high-contrast, dark-colorblind and dark-tritanopia ([primer/primitives](https://github.com/primer/primitives)).
  - The colour-blind themes "swap colors such as red and green for orange and blue" ([2021 changelog](https://github.blog/changelog/2021-09-29-colorblind-themes-beta/)). In 2022 they were split into protanopia/deuteranopia and tritanopia themes ([changelog](https://github.blog/changelog/2022-04-19-protanopia-deuteranopia-colorblind-themes-beta/)).
  - In 2025 GitHub added contrast controls for every theme ([GitHub blog](https://github.blog/open-source/building-githubs-next-chapter-in-accessibility/)).
- **High contrast:** the light high-contrast theme uses steps 2–7 for backgrounds, 10 for borders and 11–13 for text. It aims for "a minimum of 7:1" for most text and interactive elements. Where a softer background is used, borders add contrast ([colour usage](https://primer.style/product/getting-started/foundations/color-usage/)).
- **Contrast is tested, theme by theme:** [`colorContrast.config.ts`](https://raw.githubusercontent.com/primer/primitives/main/scripts/colorContrast.config.ts) lists foreground and background pairs once, then checks them in all 14 theme variants.
  - Text must reach 4.5:1 (7:1 in high contrast), and borders 3:1 (4.5:1 in high contrast).
  - High contrast reuses the same pair list and changes only the ratios.
- **Focus:** there is one functional focus token, `--focus-outlineColor` ([primitives/color](https://primer.style/foundations/primitives/color)). No width or offset guidance was found.
- **Governance:**
  - Releases use Changesets and GitHub Actions, with a release candidate tested in a consumer app ([RELEASING.md](https://raw.githubusercontent.com/primer/primitives/main/RELEASING.md)).
  - A CI script fails if a token disappears without an entry in `removed.json`, which records either `null` or the replacement token ([checkRemovedTokens.ts](https://raw.githubusercontent.com/primer/primitives/main/scripts/checkRemovedTokens.ts)).

### 4. Radix Colors
- **12 steps, each with a job** ([understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)):

  | Step | Use |
  |---|---|
  | 1 | App background |
  | 2 | Subtle background (cards, sidebars) |
  | 3 | UI element background |
  | 4 | Hovered element background |
  | 5 | Pressed or selected element background |
  | 6 | Subtle borders on non-interactive parts |
  | 7 | Borders on interactive parts |
  | 8 | Stronger borders on interactive parts, and focus rings |
  | 9 | Solid background |
  | 10 | Hovered solid background |
  | 11 | Low-contrast text |
  | 12 | High-contrast text |

  - Steps 11 and 12 are "guaranteed to Lc 60 and Lc 90 APCA contrast" on step 2.
  - Amber and yellow step 9 "are designed for dark text", the same as hisaab's `onSignal`.
- **Light and dark:** each scale ships as a light file and a `-dark` file with the same step meanings, such as `gray.css` and `gray-dark.css` ([installation](https://www.radix-ui.com/colors/docs/overview/installation)). Every scale also has alpha variants. Black and white alpha overlays "don't change across light and dark theme" ([scales](https://www.radix-ui.com/colors/docs/palette-composition/scales)).
- **Pairing a gray with an accent:** "choose the gray scale which is saturated with the hue closest to your accent hue". Sand is "based on a yellow hue" and is the natural partner for amber ([composing a palette](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette)). hisaab's warm neutrals with marigold already follow this.
- **Aliases are endorsed:** "you can choose to define multiple aliases which map to the same step", and teams can "defer to the original step number" when no alias fits ([aliasing](https://www.radix-ui.com/colors/docs/overview/aliasing)).
- Radix doesn't cover governance or money.

### 5. Atlassian Design System
- **Naming:** names have a foundation, a property and an optional modifier, such as `color.icon.success` ([design tokens](https://atlassian.design/foundations/tokens/design-tokens)). The themes listed are light, dark and high-contrast, plus non-colour themes (density, reduced motion and type) on the same page.
  - The [colour page](https://atlassian.design/foundations/color) is more cautious. A search summary read it as supporting light and dark only, so I treat high contrast as planned, not shipped.
- **Neutrals:** "a separate color ramp for dark neutrals" ([colour](https://atlassian.design/foundations/color)). The steps weren't listed.
- **Contrast:** text under 24px "must pass 4.5:1", and essential UI and text at 24px or larger needs 3:1 ([colour](https://atlassian.design/foundations/color)).
- **Elevation:** the levels are sunken, default, raised and overlay ([elevation](https://atlassian.design/foundations/elevation)).
  - In dark, "shadows can be harder to see in dark mode, so dark mode elevations also rely on different surface colors". Higher levels are lighter.
  - "Don't mix different shadow and surface elevation tokens."
- **Focus and selection:** "Use `color.border.focused` only for focus indicators". "Don't use link, brand, or focused tokens to communicate selection". "When an element is both selected and focused, preserve the selected treatment and add the focus indicator". "Pair selected colors with another visual cue, such as a checkmark" ([colour](https://atlassian.design/foundations/color)).
- **Moving to tokens:**
  - Jira had hard-coded hex values everywhere. A script converted them and removed "90% of the human work". More than 1,200 images still needed themed versions ([the story of dark theme](https://www.atlassian.com/blog/announcements/the-story-of-dark-theme)).
  - Tokens were introduced together with "a new colour and elevation system" ([community post](https://community.developer.atlassian.com/t/introducing-design-tokens-new-colour-foundations-and-dark-mode/62258)).
- **Governance:** ESLint rules `ensure-design-token-usage` ("rather than hard-coded values") and `no-deprecated-design-token-usage`, both fixable ([ESLint plugin](https://atlassian.design/components/eslint-plugin-design-system/usage)). The `token()` call warns on unknown, deleted or deprecated tokens, and fallbacks "are not recommended anymore" ([use tokens in code](https://atlassian.design/foundations/tokens/use-tokens-in-code)).

### 6. Razorpay Blade (Indian payments, optional)
- **Architecture:** the colour tokens are one object with `onLight` and `onDark` modes. Each mode has the groups `surface`, `feedback` (positive, negative, notice, information, neutral), `interactive`, `overlay`, `popup`, `data` and `transparent` ([bladeTheme.ts](https://raw.githubusercontent.com/razorpay/blade/master/packages/blade/src/tokens/theme/bladeTheme.ts)).
  - Values reference global palettes, and dark uses separate ramps (`blueGrayDark`, not `blueGrayLight`).
  - Deprecated keys carry `// @deprecated` markers in the source ([bladeNeutralTheme.ts](https://raw.githubusercontent.com/razorpay/blade/master/packages/blade/src/tokens/theme/bladeNeutralTheme.ts)).
- **Transparent is a token, tinted for each mode:** `onLight` is `hsla(0, 0%, 100%, 0)` and `onDark` is `hsla(210, 6%, 13%, 0)` ([bladeTheme.ts](https://raw.githubusercontent.com/razorpay/blade/master/packages/blade/src/tokens/theme/bladeTheme.ts)). The file gives no reason. Avoiding fades through black (see Flutter's `Color.lerp` note above) is my inference.
- **Money (the `Amount` component)** ([decisions](https://raw.githubusercontent.com/razorpay/blade/master/packages/blade/src/components/Amount/_decisions/decisions.md), [Amount.tsx](https://raw.githubusercontent.com/razorpay/blade/master/packages/blade/src/components/Amount/Amount.tsx)):
  - INR is the default currency, with Indian comma grouping ("₹1,23,456").
  - A `humanize` suffix uses compact notation.
  - `isAffixSubtle` (on by default) makes the ₹ and the decimals smaller and faded.
  - Size and weight come from one `size` prop "to avoid impossible states".
  - The `intent` prop accepts positive, notice, information and neutral, and the default amount colour is neutral gray (`surface.text.gray.normal`).
  - The component sets no tabular figures.
- **Governance:** RFCs and API decisions are kept in the repo ([README](https://cdn.jsdelivr.net/npm/@razorpay/blade@12.98.1/README.md)).

## Cross-system comparison
| | MINT | M3 | Primer | Radix | Atlassian | Blade | hisaab today |
|---|---|---|---|---|---|---|---|
| Layers | primitive, then semantic | ref palette, then sys role | base, functional, pattern | scale step, then (optional) alias | foundation.property.modifier | global, then mode tokens | one flat layer of roles |
| Neutral steps | 11 (+12) | 13 tones (HCT) | 14 (0–13) | 12 | not listed | numbered ramps | about 7 |
| Perceptual | not stated | yes (L*) | not stated | APCA-checked text | not stated | not stated | no; tested by WCAG ratio |
| Dark | primitives redefined | tone roles | inverted scale | separate `-dark` scale | separate ramp | separate ramp | designed values (D92) |
| Higher layer in dark | lighter | lighter (tone) | n/a | n/a | lighter | n/a | lighter (D92) |
| High contrast | none public | contrast levels | 2 themes, 7:1 | none | planned | none found | none |
| Colour-blind | green/red | n/a | 4 themes | n/a | "not colour alone" | positive/negative | safe by construction (no hues) |
| Focus token | none public | state layer | `focus-outlineColor` | steps 7–8 | `color.border.focused` | none found | none |
| Removal policy | none | n/a | CI + `removed.json` | n/a | lint (deprecated) | `@deprecated` | DECISIONS rows |

## Implications for hisaab (for `design-product`)
Research proposes these. `DECISIONS.md` decides them.

### Adopt
1. **A focus-only ring token, shown only with keyboard or D-pad focus.**
   - Sources: Atlassian keeps `color.border.focused` only for focus and adds it on top of the selected treatment ([colour](https://atlassian.design/foundations/color)). Radix gives focus rings their own step ([scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)). Primer has a single `focus-outlineColor` ([primitives](https://primer.style/foundations/primitives/color)).
   - For hisaab: a 2dp `ink` ring outside a 2dp gap in the layer beneath. That is the two-colour method in [WCAG C40](https://www.w3.org/WAI/WCAG22/Techniques/css/C40) (two colours at least 9:1 apart; `ink` on `bg` is 15.33:1). Each band is 2dp, which also meets [2.4.13](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html) and satisfies [2.4.7 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html).
   - Show it only in `FocusHighlightMode.traditional` ([Flutter](https://api.flutter.dev/flutter/widgets/FocusHighlightMode.html)), so touch users never see it.
   - Never use marigold for the ring: it means today or act, and it is 1.55:1 on the light `bg`.
2. **Set every Material `ColorScheme` role explicitly, and test that only the intended roles resolve to `signal`.**
   - Flutter recommends providing every role ([API](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.html)), and its fallbacks send `tertiary` and `secondaryContainer` to `secondary`, which is marigold here.
   - Map the containers to `surface`, `sunk` and `hairline` and the tertiary roles to `ink` or `ink2`. Also ask whether `secondary` should be `signal` at all.
   - This is the same fix D94 made for `outline`, applied to every role.
3. **A high-contrast pair of token sets, driven by the OS, with the same pair list.**
   - Primer reuses one list of contrast pairs and raises the floors: text from 4.5 to 7:1, boundaries from 3 to 4.5:1 ([config](https://raw.githubusercontent.com/primer/primitives/main/scripts/colorContrast.config.ts)). hisaab's contrast tests can gain a second column the same way.
   - Wire `MaterialApp.highContrastTheme` and `highContrastDarkTheme`. Flutter selects them from Android 14 (API 34) on ([API](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html)). This adds no in-app setting, which fits PLAN §2.
4. **A primitive layer under the roles.** Give the warm neutrals private, numbered steps (Primer base tokens, Radix steps, MINT primitives), and make every role, including the aliases, point to a step.
   - Radix endorses several aliases for one step ([aliasing](https://www.radix-ui.com/colors/docs/overview/aliasing)). An alias then can't drift, and a deliberate split such as `displayInk2` ≠ `ink2` in light (D90) shows up as a different step.
5. **A `transparent` token per theme, tinted with the layer it fades into,** instead of `Colors.transparent`.
   - Blade does this ([bladeTheme.ts](https://raw.githubusercontent.com/razorpay/blade/master/packages/blade/src/tokens/theme/bladeTheme.ts)), and Flutter warns that lerping from transparent black is less suitable ([Color.lerp](https://api.flutter.dev/flutter/dart-ui/Color/lerp.html)).
   - Current uses: `lib/app/widgets/dock_item.dart` (the unselected fill), the `backgroundColor` of four pages, and the system bars in `lib/app/hisaab_app.dart`. The system bars are an OS edge-to-edge setting and can stay.
6. **Enforce tokens with a check, not only a rule, and record removals.**
   - Atlassian lints for hard-coded values and deprecated tokens ([ESLint](https://atlassian.design/components/eslint-plugin-design-system/usage)). Primer's CI rejects an undocumented token removal ([script](https://raw.githubusercontent.com/primer/primitives/main/scripts/checkRemovedTokens.ts)).
   - I found no test in `test/` that scans `lib/` for `Colors.` or `Color(0x` outside `core/design`. A source-scan test would enforce the CLAUDE.md rule.

### Reject
- **Green and red for gains and losses** (MINT `--content-positive` and `--content-negative`; Blade `feedback.positive` and `negative`). This breaks hisaab's no-red, no-green rule. MINT's green text is also about 2.7:1 on white *(calc)*. State stays fill, outline, hatch and words.
- **Colour-blind themes** (Primer). They solve a problem hisaab doesn't have, because meaning never rides on hue. A theme picker would also add a setting.
- **An inverted scale for dark** (Primer). D92 chose designed dark steps that keep each layer's contrast. Atlassian, MINT and current M3 also make a higher layer lighter, as hisaab does.
- **Seed-generated or dynamic colour** (`ColorScheme.fromSeed`, wallpaper colour). It would bring tinted hues into a monochrome palette.
- **A faded ₹ and decimals** (Blade `isAffixSubtle`). hisaab never shows paise, and fading the ₹ lowers the hero's contrast. Worth a design-product look only if the ₹ ever crowds the hero.

## Conflicts to note
- A high-contrast theme probably needs **edges on chips and fields** (Primer: "borders can increase contrast"). That conflicts with D88 and D89 (fill-only, no edges). A new row would be needed to scope the exception to high contrast only.
- Moving `secondary` off `signal` changes which Material widgets can show marigold. Check it against UI_DESIGN §3.5 and the one-signal rule.

## Proposed principles (merged into `principles.md` as 23–29)
23. **Focus has its own token and never doubles as selection.** Keep the selected look and add the ring. Show it only for keyboard or D-pad focus. *Sources:* Atlassian colour; Radix step 8; WCAG C40, 2.4.7, 2.4.13; Flutter `FocusHighlightMode`. *Applies to:* keys, chips, rows, dock, header buttons.
24. **Set every platform role; never rely on fallbacks.** An unset Material role inherits the nearest given colour, which here is the signal. *Sources:* Flutter `ColorScheme` API. *Applies to:* `HisaabTheme._scheme`.
25. **Contrast pairs are one list, checked in every theme; high contrast raises the floor, not the list.** *Sources:* Primer `colorContrast.config.ts`. *Applies to:* `hisaab_colors_test.dart`, `hisaab_theme_test.dart`.
26. **Roles point to steps; aliases are fine when they point to the same step.** *Sources:* Primer base vs functional; Radix aliasing. *Applies to:* `HisaabColors`.
27. **Transparent is a token, tinted with its layer.** *Sources:* Blade `transparent`; Flutter `Color.lerp`. *Applies to:* fades, unselected fills.

## Proposed sources (added to `sources.md`)
| Source | Good for | Limits |
|---|---|---|
| [Radix Colors docs](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale) | A 12-step scale with a use for each step; pairing grays with accents; aliasing | Fetches cleanly; web-first, no governance |
| [Primer primitives repo](https://github.com/primer/primitives) | Theme list, contrast test config, token-removal CI | Raw GitHub files fetch cleanly; primer.style pages truncate |
| [Atlassian elevation](https://atlassian.design/foundations/elevation), [colour](https://atlassian.design/foundations/color) | Elevation levels, dark surfaces, focus vs selection | The colour page sometimes returns empty; retry |
| [Flutter API: ColorScheme](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.html) | Real fallback behaviour of Material roles | The implementation line is often the only place a default is stated |
| [`@groww-tech/mint-css` on unpkg](https://app.unpkg.com/@groww-tech/mint-css@0.4.0/files/dist/fragments/allVariables.css) | Groww's actual token names and hex values | The only public MINT artefact; no docs or rationale; npmjs.com returns 403 |
| [Razorpay Blade repo](https://github.com/razorpay/blade) | INR `Amount` decisions, per-mode tokens | The Storybook site needs JavaScript; read the raw files |
| m3.material.io, m2.material.io | — | Return titles only; use the Android, Flutter and material-web docs instead |

## Open questions
- Does `dock_item.dart`'s `Material` animate between `sunk` and `Colors.transparent`? If it does, the fade passes through grey. This needs a device check, not desk research.
- What exact contrast ratios do Material's medium and high contrast levels target? m3.material.io didn't render.
- How does the Groww app (not the web CSS) set numbers: tabular figures, signs, colour plus arrow? Install the app and record the screens, as `sources.md` advises.
- Would five users on low-end Android phones with *High contrast text* turned on notice the high-contrast set? A usability round is needed once it exists.
