# Design systems: Vercel Geist, Apple HIG, IBM Carbon

## Question
What can three mature public design systems teach `HisaabColors` and `HisaabTheme` (UI_DESIGN §3.2, §3.5; D88–D94)? The study covers token layers and naming, how a grey scale is built, dark mode designed rather than inverted, focus, high or increased contrast, reduced transparency, and how token changes are governed. It also looks at our known gaps:
- Our own controls have no focus ring.
- There is no high-contrast token set.
- Unused Material roles fall back to marigold. `ColorScheme` sets `secondary: signal` and leaves `tertiary` and the container roles unset (`lib/core/design/hisaab_theme.dart`).
- `Colors.transparent` is used directly in 7 places (`entries_page.dart`, `dock_item.dart`, `hisaab_app.dart` ×2, `bills_page.dart`, `settings_page.dart`, `bill_editor_page.dart`).
- Some tokens only alias others (`display` = `surface`, `displayInk` = `ink`, and in dark `displayInk2` = `ink2`).

## Method
Desk research only: documentation pages fetched on 2026-10-29. This is the cheapest method that can change a token decision, because tokens are an engineering contract and the systems publish their reasoning. No users were involved, so nothing here is evidence of how people perceive these choices. Confidence describes how reliable the source is, not how well the idea fits hisaab.

## Sources and access
| Source | Read? | Notes |
|---|---|---|
| [Geist Colors](https://vercel.com/geist/colors) and [colors.md](https://vercel.com/geist/colors.md) | Yes | Steps and roles; no dark mode, contrast or focus content |
| [Geist Materials](https://vercel.com/geist/materials) | Yes | Radius and elevation names only; no fill, stroke or shadow values |
| [Geist Introduction](https://vercel.com/geist/introduction) | Yes | Overview. Any Geist URL serves markdown when `.md` is appended |
| [vercel.com/design.md](https://vercel.com/design.md), [design.dark.md](https://vercel.com/design.dark.md) | Yes | Agent-facing brand rules. They point to a stylesheet rather than listing values |
| [vercel-brand.css](https://vercel.com/geist/vercel-brand.css) | First 100k of about 109k characters | OKLCH values and focus rules for Vercel's brand-report tokens, mapped to Geist steps. The full Geist dark grey scale was **not** found |
| [Vercel Web Interface Guidelines](https://vercel.com/design/guidelines) | Yes | Focus, contrast and interaction rules |
| Apple HIG [Color](https://developer.apple.com/design/human-interface-guidelines/color.md), [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode.md), [Materials](https://developer.apple.com/design/human-interface-guidelines/materials.md), [Typography](https://developer.apple.com/design/human-interface-guidelines/typography.md), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility.md), [Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection.md) | Yes, through the `.md` URLs | Every page has a dated change log |
| Carbon [Color overview](https://carbondesignsystem.com/elements/color/overview/), [tokens](https://carbondesignsystem.com/elements/color/tokens/), [usage](https://carbondesignsystem.com/elements/color/usage/), [Themes](https://carbondesignsystem.com/elements/themes/overview/), [Accessibility color](https://carbondesignsystem.com/guidelines/accessibility/color/), [Accessibility overview](https://carbondesignsystem.com/guidelines/accessibility/overview/) | Yes | Tokens list White-theme values only. Focus width and offset are not on these pages |
| Carbon [Contributing](https://carbondesignsystem.com/contributing/overview/), [Migration (design)](https://carbondesignsystem.com/migrating/guide/design), [Migration FAQ](https://carbondesignsystem.com/migrating/faq/) | Yes | Governance and deprecation |
| Flutter [`MediaQueryData.highContrast`](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html), Android [`UiModeManager`](https://developer.android.com/reference/kotlin/android/app/UiModeManager) | Yes | How Android exposes the contrast settings to us |

Not found: a Carbon page giving the focus ring's width or offset. Third-party pages give conflicting values, so they are not cited. Also not found: a Carbon page on Windows High Contrast or forced colours, and anything public on Geist governance or deprecation.

## Findings

### Vercel Geist
1. **Token architecture.**
   - Geist has scales, not named semantic tiers: backgrounds, gray, gray-alpha, and seven hues ([Colors](https://vercel.com/geist/colors)). A step's number encodes its job.
   - The brand layer adds semantic names on top: `--vbg-surface-primary` maps to background-100 and `--vbg-text-primary` maps to gray-1000. "Tokens must not be invented, aliased, or redeclared" ([design.md](https://vercel.com/design.md); [vercel-brand.css](https://vercel.com/geist/vercel-brand.css)).
   - Confidence: high for the scales, medium for the brand layer, because it is Vercel's brand-report sheet rather than the component library.
2. **Grey scale.**
   - Each scale has 10 steps, 100–1000, and each band of steps has a job ([colors.md](https://vercel.com/geist/colors.md)):
     - 100–300: component backgrounds at default, hover and active.
     - 400–600: borders at default, hover and active.
     - 700–800: high-contrast fills.
     - 900–1000: secondary and primary text.
   - There are two page backgrounds. Background 2 is used "sparingly".
   - Use solid gray by default. Gray-alpha is only for cases where "the background should show through", such as shadows and overlays.
   - Values are written as perceptual, achromatic OKLCH: text-primary is `oklch(0.205 0 0)`, and P3 is used where supported ([vercel-brand.css](https://vercel.com/geist/vercel-brand.css); [Colors](https://vercel.com/geist/colors)). Confidence: high.
3. **Dark mode.**
   - Dark is "implicit", with no visible switcher, and needs "equivalent hierarchy and contrast" ([design.dark.md](https://vercel.com/design.dark.md)).
   - The brand sheet's dark page is pure black, `oklch(0 0 0)`, and the secondary surface lifts only slightly, to `oklch(0.027 0 0)`. Borders become white-alpha ([vercel-brand.css](https://vercel.com/geist/vercel-brand.css)).
   - Ornamental shadows, glows, glass and "fake depth" are rejected ([design.md](https://vercel.com/design.md)).
   - Confidence: medium. The full Geist dark grey scale was not read.
4. **Focus and contrast.**
   - "Every focusable element shows a visible, unobscured focus ring". Sticky headers and overlays "never cover the focused element" ([Guidelines](https://vercel.com/design/guidelines)).
   - The sheet draws the ring as `outline: 2px solid var(--vbg-focus)` at `outline-offset: 3px`, in blue (blue-700 in light, blue-900 in dark) ([vercel-brand.css](https://vercel.com/geist/vercel-brand.css)).
   - ":hover, :active, :focus have more contrast than rest state". The guidelines also say to "Prefer APCA over WCAG 2" ([Guidelines](https://vercel.com/design/guidelines)).
   - No `prefers-contrast` or reduced-transparency rules appeared in the part of the sheet that was read. Confidence: high for the guidelines.
5. **Governance.** Nothing public on change, deprecation or contribution. The only rule found is "don't alias or redeclare" ([design.md](https://vercel.com/design.md)).

### Apple Human Interface Guidelines
1. **Token architecture.**
   - Dynamic system colours are "semantically defined by its purpose, rather than its appearance". Examples: `label`, `secondaryLabel`, `separator`, and the `systemBackground` and `systemGroupedBackground` sets, each with primary, secondary and tertiary levels.
   - "Avoid redefining the semantic meanings": for example, don't use `separator` as text, or `secondaryLabel` as a background ([Color](https://developer.apple.com/design/human-interface-guidelines/color.md)). Confidence: high.
2. **Grey scale.**
   - iOS has six system greys (Gray to Gray 6). **Each grey has four values: light, dark, increased-contrast light and increased-contrast dark** ([Color, Specifications](https://developer.apple.com/design/human-interface-guidelines/color.md)).
   - Increased contrast pushes greys away from the background in both themes:
     - Gray 6: 242→235 in light, 28→36 in dark.
     - Gray: 142→108 in light, 142→174 in dark.
   - Increased contrast also darkens system yellow in light, from 255,204,0 to 161,106,0, because yellow is weak on white.
   - The page doesn't say how the steps were chosen, and gives no OKLCH or CAM16 basis. Confidence: high for the values.
3. **Dark mode.**
   - Dark colours "aren't necessarily inversions of their light counterparts".
   - iOS uses *base* and *elevated* background sets: "base colors are dimmer… elevated colors are brighter", and the system switches a view to elevated when it is in front, as in a sheet or popover.
   - Contrast: "no lower than 4.5:1", and for custom colours "strive for a contrast ratio of 7:1, especially in small text" ([Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode.md)).
   - "Avoid offering an app-specific appearance setting" ([Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode.md)). Confidence: high.
4. **Focus, increased contrast and reduced transparency.**
   - Every custom colour needs light and dark variants "and an increased contrast option for each variant" ([Color](https://developer.apple.com/design/human-interface-guidelines/color.md)).
   - If the default contrast falls short, the app must "at least provide a higher contrast color scheme when … Increase Contrast is turned on" ([Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility.md)).
   - Test dark mode with Increase Contrast and Reduce Transparency, "both separately and together" ([Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode.md)).
   - Liquid Glass belongs in the navigation layer: "Don't use Liquid Glass in the content layer". Its variants change when people reduce transparency or increase contrast ([Materials](https://developer.apple.com/design/human-interface-guidelines/materials.md)).
   - Focus: "Rely on system-provided focus effects". "In general, use a focus ring for a text or search field, but use a highlight in a list or collection". The halo follows the item's shape and must not be clipped ([Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection.md)).
   - Confidence: high.
5. **Governance.**
   - Every HIG page has a dated change log. For example, Color lists "June 9, 2025: Updated system color values" ([Color](https://developer.apple.com/design/human-interface-guidelines/color.md)).
   - Values "may fluctuate from release to release", so apps reference roles, never hard-coded values ([Color](https://developer.apple.com/design/human-interface-guidelines/color.md)).
   - There is no public contribution process.

### IBM Carbon
1. **Token architecture.** Carbon has three layers:
   - **Palette:** Gray 10–100, Blue 60 and so on.
   - **Core semantic tokens,** named `[element]-[role]-[order]-[state]`. Examples: `$layer-01`, `$border-strong-01`, `$background-hover`.
   - **Component tokens,** which "should never be used for anything other than their own component" ([tokens](https://carbondesignsystem.com/elements/color/tokens/); [Migration](https://carbondesignsystem.com/migrating/guide/design)).

   A token is "a role-based identifier", and "Roles cannot be changed between themes"; only the values change ([Themes](https://carbondesignsystem.com/elements/themes/overview/)). Layer numbers pair tokens: a field on `$layer-02` uses `$field-03`, and a border "pair[s] with its same number" ([usage](https://carbondesignsystem.com/elements/color/usage/)). Confidence: high.
2. **Grey scale.**
   - Ten grades per hue plus black and white ([Color overview](https://carbondesignsystem.com/elements/color/overview/)).
   - **Steps are counted in contrast:** a contrast table lists how many grades apart two colours must be for 4.5:1 or 3:1.
   - **Interaction states are counted in grades:** hover is half a step, selected is one step and active is two steps.
   - Carbon also has Cool Gray and Warm Gray families, but the overview page doesn't discuss them. The page gives no OKLCH or CAM16 basis. Confidence: high.
3. **Dark mode.**
   - Four themes: White, Gray 10, Gray 90 and Gray 100.
   - "In the light themes, layers alternate between White and Gray 10. In the dark themes, layers become one step lighter with each added layer" ([Color overview](https://carbondesignsystem.com/elements/color/overview/)). This is the model hisaab already follows (§3.5).
   - Inverse components such as tooltips "should remain high contrast when switching modes" ([usage](https://carbondesignsystem.com/elements/color/usage/)). Confidence: high.
4. **Focus and contrast.**
   - "Focus states are required on all interactive elements and must pass 3:1" ([Color overview](https://carbondesignsystem.com/elements/color/overview/)).
   - Focus is a **pair** of tokens: `$focus` (Blue 60) for the border, plus `$focus-inset` (white), a "Contrast border paired with $focus". `$focus-inverse` covers high-contrast moments ([tokens](https://carbondesignsystem.com/elements/color/tokens/)).
   - `$border-strong-01` is defined as the "3:1 AA non-text contrast" border ([tokens](https://carbondesignsystem.com/elements/color/tokens/)).
   - No high-contrast theme or forced-colours guidance was found; the overview only lists a Chrome plugin ([Accessibility overview](https://carbondesignsystem.com/guidelines/accessibility/overview/)). Components follow the IBM Accessibility Checklist (WCAG AA, Section 508). Confidence: high, except that focus width was not found.
5. **Governance.**
   - "Anyone can contribute". New components go through Carbon Labs, then a lifecycle and a component checklist ([Contributing](https://carbondesignsystem.com/contributing/overview/)).
   - The v11 rename came with migration tables and a stylelint plugin ([Migration](https://carbondesignsystem.com/migrating/guide/design)).
   - "Assets that are deprecated in v10 will remain in v11 and will be removed in v12", with majors at least 12 months apart ([FAQ](https://carbondesignsystem.com/migrating/faq/)). Confidence: high.

### How Android exposes contrast to us
- Flutter's `MediaQueryData.highContrast` maps to Android's "High contrast text or similar accessibility settings". It "is currently only updated on … Android devices running API 34+", and `MaterialApp` uses it to choose `highContrastTheme` or `highContrastDarkTheme` ([Flutter](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html)).
- Android 14 adds `UiModeManager.getContrast()`, a value from −1 to 1, for apps that "do[] its own rendering" ([Android](https://developer.android.com/reference/kotlin/android/app/UiModeManager)). How Material's medium and high contrast map onto that value was not found.

## Cross-cutting pattern
All three systems name tokens by role, and change values per theme and per accessibility mode. None of them inverts light to get dark. Apple and Carbon both want a 3:1 non-text boundary and a visible focus state. Apple and Vercel both treat interaction and accessibility states as "more contrast than rest". Hisaab already matches the layering model (Carbon, D45, D92) and the scrim rule (Apple's base and elevated sets, D93). What we lack is the fourth value per token (increased contrast), a focus token, and a written deprecation rule.

## Implications for hisaab (to design-system and design-product)

### Adopt
| # | Practice | From | Hisaab form | Gap closed |
|---|---|---|---|---|
| A1 | Every colour token has an increased-contrast value in each theme, and contrast settings push greys away from the background | [Apple Color](https://developer.apple.com/design/human-interface-guidelines/color.md), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility.md) | Add `HisaabColors.lightHighContrast` and `darkHighContrast`, used for `MaterialApp.highContrastTheme` and `highContrastDarkTheme` ([Flutter](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html)). Candidates: `ink2` at ≥ 7:1 on every fill (today 4.70 on light `hairline`); `hairline` and `blockIdle` at ≥ 3:1; marigold keeps its ink edge. Same 9 roles, no new ones | No HC set |
| A2 | A focus token that is a two-tone pair, ≥ 3:1, on every interactive element, never covered by sticky chrome | [Carbon tokens](https://carbondesignsystem.com/elements/color/tokens/), [Carbon overview](https://carbondesignsystem.com/elements/color/overview/), [Vercel Guidelines](https://vercel.com/design/guidelines) | Add `focus` = `ink` with `focusInset` = `bg`: a 2dp ink ring with a 2dp `bg` gap (Vercel offsets its ring by 3px). Ink reads on every layer and on marigold (9.90:1). A field keeps its 1.5dp `ink2` edge; per [Apple](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection.md), list rows take a highlight fill rather than a ring | Our controls have no focus ring |
| A3 | Roles never change meaning across themes, and a role is never reused for another job | [Carbon Themes](https://carbondesignsystem.com/elements/themes/overview/), [Apple Color](https://developer.apple.com/design/human-interface-guidelines/color.md) | Give every Material `ColorScheme` role an explicit hisaab value. `secondary` and `tertiary` should be `ink` (or `sunk`), never `signal` by default, because marigold means only today and act. Name the jobs `hairline` carries today (divider, chip fill, field fill, pressed key) before splitting any of them | Roles defaulting to marigold; `hairline` overloaded |
| A4 | Deprecate before removing, and write down every alias | [Carbon FAQ](https://carbondesignsystem.com/migrating/faq/), [Geist design.md](https://vercel.com/design.md) | Aliases (`display`, `displayInk`) become either documented aliases in UI_DESIGN or `@Deprecated` getters that return the target, removed one milestone later with a DECISIONS row. Replace `Colors.transparent` with a named token or `surface.withAlpha(0)`, as case study 04 found for fades | Aliases; `Colors.transparent` |
| A5 | States are counted in steps of one scale | [Carbon overview](https://carbondesignsystem.com/elements/color/overview/), [Geist colors](https://vercel.com/geist/colors.md) | Write the press and pick rule as steps in §3.2: rest → pressed is one grey step (`sunk` → `hairline`), and a pick is the `ink2` step. This records D88–D92's choices as one rule | Undocumented state logic |

### Reject
| Practice | From | Why not |
|---|---|---|
| A blue focus ring, or any hued focus colour | [Vercel sheet](https://vercel.com/geist/vercel-brand.css), [Carbon `$focus`](https://carbondesignsystem.com/elements/color/tokens/) | A second hue breaks "monochrome + one signal". A marigold ring would sit bare on light `bg` at 1.55:1 and would mean "today". Use ink |
| Several themes per mode (White and Gray 10; Gray 90 and Gray 100) | [Carbon](https://carbondesignsystem.com/elements/color/overview/) | Adds settings and test matrix rows. Apple advises no app-specific appearance setting ([Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode.md)), and PLAN §2 prefers defaults over settings. Keep one light, one dark, and one HC of each |
| Glass or translucent materials for depth | [Apple Materials](https://developer.apple.com/design/human-interface-guidelines/materials.md) | Already rejected for content (D84, case study 04). Apple keeps glass for navigation and changes it under Reduce Transparency, so an opaque app needs no reduced-transparency variant |
| Pure black dark page and alpha borders | [Vercel sheet](https://vercel.com/geist/vercel-brand.css) | D92 steps opaque warm greys from `#121211`. Alpha borders change contrast with whatever is underneath, which our solid layering avoids |
| APCA instead of WCAG 2 | [Vercel Guidelines](https://vercel.com/design/guidelines) | Our tests assert WCAG 2 ratios (UI_DESIGN §3.2), and WCAG 2.2 AA is the bar. APCA could be added later as a second check, not a replacement |

## Candidate principles (merged into `principles.md` as 23–29)
23. **Every colour token has four values: light, dark, and increased contrast for each.** The contrast values push greys away from the background, never closer. *Sources:* Apple HIG Color and Accessibility. *Applies to:* `HisaabColors`, `HisaabTheme`.
24. **Focus is a token pair: a ring plus an inset gap,** at ≥ 3:1 on every layer, and never hidden under sticky bars. *Sources:* Carbon tokens and colour overview; Vercel Web Interface Guidelines; Apple Focus and selection. *Applies to:* keys, tiles, chips, dock, header buttons.
25. **A role keeps one meaning in every theme, and no framework role is left to default.** *Sources:* Carbon Themes; Apple Color. *Applies to:* `ColorScheme`, `ThemeExtension`.
26. **State changes are counted in steps of one scale** (press one step, pick a named step), not picked per component. *Sources:* Carbon colour overview; Geist Colors. *Applies to:* chips, keys, fields.
27. **Deprecate a token before removing it, and record every alias.** *Sources:* Carbon migration FAQ; Geist design.md. *Applies to:* `HisaabColors`, DECISIONS.

## Sites (added to `sources.md`)
| Source | Good for | Limits |
|---|---|---|
| [Vercel Geist](https://vercel.com/geist/introduction) | Step-to-role grey scale; append `.md` to any page for clean markdown | No dark values, governance or contrast on the doc pages. `design.md` is agent-facing brand rules |
| [Vercel Web Interface Guidelines](https://vercel.com/design/guidelines) | Focus, interaction-contrast and motion checklists | Web (CSS) terms; map them to Flutter |
| [Carbon migration FAQ and guide](https://carbondesignsystem.com/migrating/faq/) | Token deprecation and rename practice | Mapping tables are on GitHub, not on the site |
| [Flutter `MediaQueryData`](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html) | Which OS settings reach Flutter, and from which API level | API reference only |

## Conflicts with `DECISIONS.md`
- None directly.
- A2 adds a token and a visual state. It needs a new row, and must keep the Add flow's taps unchanged.
- A3 changes `HisaabTheme._scheme`, which D94 last set. It extends D94 rather than reversing it.
- A1 must keep D92's step ratios as the default set; it only adds HC sets.

## Open questions
- Which Android setting turns on `highContrast`? Flutter names "High contrast text". Android 14's contrast slider (`getContrast`) may need its own reading. Check on an API 34+ device before building A1.
- Does a 2dp ink ring with a `bg` gap read as focus, or as "selected", to first-time users? A blind read like case study 05's would answer this, with five users.
- Should HC drop the dock's 32dp fade? D82 already does this for high contrast. Confirm it reads the same flag.
- How many hisaab users use high contrast or a keyboard or switch? There is no telemetry by design. Ask in the next usability round's screener.
