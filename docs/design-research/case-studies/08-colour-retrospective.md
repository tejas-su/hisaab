# Colour retrospective: why picks keep churning, and the grey ramp

## Question
In two days, picked chips and text fields changed colour six times: D85 → D87 → D88 → D89 → D90 → D100. The snackbar redesign (D105) almost repeated the pattern: its first fill was `ink`, a black slab of the kind D46 and D47 had already removed. Why do we keep landing on colours that look too faint or too heavy, and what should change in the system and in how we work?

## Method
- Measured every light and dark neutral in OKLCH lightness (`L`, 0 black to 1 white) with a script, and WCAG contrast against the layers they sit on. No value below is estimated.
- Read how established systems build neutral ramps: Radix Colors, Refactoring UI, Material 3's inverse roles, Apple HIG Color.
- Read the colour-psychology material for fintech and for Indian colour meaning, to see what is evidence and what is folklore.
- Reviewed the `better-colors` agent skill (jakubkrehel/skills) and installed it in `.claude/skills/better-colors/`.

## Findings

### 1. The grey scale has no middle
| Light token | Hex | OKLCH `L` |
|---|---|---|
| `surface` | `#FFFEFB` | 0.997 |
| `bg` | `#EEECE6` | 0.943 |
| `sunk` | `#E4E1DA` | 0.910 |
| `hairline` | `#D3D0C8` | 0.858 |
| *(no step)* | | 0.86 → 0.46 |
| `ink2` | `#585752` | 0.456 |
| `inverse` (D105) | `#2F2E2B` | 0.301 |
| `ink` | `#161615` | 0.200 |

| Dark token | Hex | OKLCH `L` |
|---|---|---|
| `bg` | `#121211` | 0.182 |
| `surface` | `#1F1F1D` | 0.239 |
| `sunk` | `#2C2C29` | 0.292 |
| `hairline` | `#373734` | 0.336 |
| `blockIdle` | `#3E3E3B` | 0.363 |
| *(no step)* | | 0.36 → 0.71 |
| `ink2` | `#A3A29C` | 0.711 |
| `ink` | `#F2F1EC` | 0.958 |

Four light greys share the top 14% of lightness, then the scale jumps 0.40 to `ink2`. Dark has the mirror gap. A component that wants a *medium* weight (a picked chip, a selected pill, a snackbar, a disabled label) can only take a near-invisible step (1.1–1.5:1) or a full-strength ink. That is the churn: each pick was right for one complaint ("too faint") and wrong for the next ("too heavy"), because the step it needed doesn't exist.

### 2. We pick values per component, by eye
Radix gives each of 12 steps a single job: app background, subtle background, component rest, hover, pressed or selected, subtle border, interactive border, strong border, solid fill, hovered solid, low-contrast text, high-contrast text ([Radix](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)). Refactoring UI says to expect 8–10 greys, start from a dark grey rather than black, and define every shade up front instead of deriving them on the fly ([Refactoring UI](https://refactoringui.com:443/previews/building-your-color-palette)). `better-colors` adds: build the ramp with a colour library, step the light end finely (about 0.04–0.05 `L`), never borrow a token because its value happens to look right, and when a role has no token, add the token. We did the opposite: we tuned hex values against one screenshot at a time, and moved existing tokens to suit one component.

### 3. Dark on light is the right snackbar; black is not
Material's snackbar uses the inverse surface, dark in the light theme, so a transient alert stands off every card ([Flutter `inverseSurface`](https://api.flutter.dev/flutter/material/ColorScheme/inverseSurface.html), [Compose](https://kotlinlang.org/api/compose-multiplatform/material3/androidx.compose.material3/-color-scheme/inverse-surface.html)). A light pill vanishes over our near-white cards. But `ink` is `L` 0.20: near black, which the owner has twice called a slab. D105 adds `inverse` at `L` 0.30 (`#2F2E2B`, 11.49:1 with `bg` text).

### 4. Colour psychology: little evidence, two solid rules
Fintech colour-psychology articles repeat statistics with no traceable study (the "62–90% of first impressions" figure, "blue builds trust") ([Progress](https://www.progress.com/blogs/how-choose-right-colors-fintech), [Windmill](https://windmill.digital/insights/psychology-of-color-in-financial-app-design), [We and the Color](https://weandthecolor.com/color-psychology-in-fintech-branding-how-the-right-palette-builds-user-trust/209146)). Treat them as folklore. What holds:
- Use colour sparingly, never as the only signal, and by role rather than raw value ([Apple HIG Color](https://developer.apple.com/design/human-interface-guidelines/color.md)). This is D8–D10.
- Red and warning hues near money raise anxiety; practitioner sources agree even where evidence is thin. This is D9.
- In India, marigold and yellow read as auspicious and festive (turmeric, weddings), and white can carry mourning ([GKToday](https://www.gktoday.in/colour-symbolism-in-indian-culture-and-festivals/)). Marigold for *today* is a good fit; our warm-grey `bg`, never `#FFF`, avoids the white question.

## Recommendation (approved 2026-10-29 as process; the ramp is a separate task)

### Process, now
1. Before a colour change, name the **role** it fills. If no token has that role, add one; never move an existing token to suit one component.
2. Measure in OKLCH `L` and WCAG contrast with a script or the `better-colors` skill. Never estimate.
3. Show options side by side in a mockup on the real layers (page, card, tray) in both themes before choosing.
4. A new dark fill starts from `inverse`, not `ink`.

### Ramp rebuild, proposed
Fill the light gap with steps the roles already ask for, at the same warm hue (OKLCH hue about 90°, chroma about 0.007):

| Proposed step | Hex | `L` | On `bg` | On `surface` | Job it would take |
|---|---|---|---|---|---|
| `border` | `#B9B7B2` | 0.78 | 1.70 | 1.99 | Strong edge on interactive controls; a quiet selected fill |
| `ink3` | `#9A9893` | 0.68 | 2.44 | 2.86 | Disabled labels, placeholder glyphs (non-text, decorative only) |
| `ink2Soft` | `#7C7A76` | 0.58 | 3.63 | 4.25 | Large text and icons only (3:1 rule) |

Dark gets the mirror steps in its 0.36 → 0.71 gap. Then each existing role (picked chip, selected pill, idle block, disabled control) is re-mapped to the step whose job it is, in one DECISIONS row with a mockup, instead of one row per component.

## Risks
- More steps are more choice. Mitigate by publishing each step's job in UI_DESIGN §3.2 and rejecting a token that has no role.
- Re-mapping touches many widgets and the contrast-pair list; do it in one change with the mockup approved first.
- `better-colors` is written for CSS. Its rules transfer; its notation advice (`oklch()`, `color-mix`) does not, since Flutter tokens stay hex.
