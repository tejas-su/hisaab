# Colour-token proposal: a marigold ramp, warmer neutrals, category hues, two hero variants

**Status:** draft proposal, 2026-10-29. Nothing here is adopted. `lib/`, `test/`, `CLAUDE.md`, `UI_DESIGN.md` and `DECISIONS.md` are untouched. §9 lists every rule, doc and decision each item would change. §10 drafts the `DECISIONS.md` rows.

**Problem.** The light theme is about 98% warm grey plus one marigold signal (`#FFB020`, *today / act* only, 1.55:1 on light `bg`). Next to other fintech apps it looks unpainted ([case study 08](../design-research/case-studies/08-colour-in-fintech.md)).

**Kept:**
- Marigold means *today / act*.
- No red or green for good or bad.
- Colour is never the only carrier of meaning.
- Hex notation (`#RRGGBB`) and the `HisaabColors` token style (private constants, semantic public fields, aliases name one constant, D97).
- Every token has a light and a dark value.

## 0. Method

- **Script:** every number below comes from pure-Python scripts, run with `python3 -I`, in `/tmp/claude-1001/-home-tejassu-Desktop-expense-tracker/640c6956-a0a6-4479-bc21-e8dd1f68f0a8/scratchpad/`:

  | File | What it does |
  |---|---|
  | `colourlib.py` | sRGB ↔ OKLab/OKLCH (Ottosson's matrices), gamut clipping by chroma reduction at constant `L` and `h`, WCAG 2 relative luminance and contrast, alpha compositing in sRGB (as Flutter paints), and CVD simulation: Machado et al. 2009 at severity 1.0 (protan, deutan, tritan) and Viénot et al. 1999 (protan, deutan), both in linear RGB |
  | `proposal.py` | Builds every token and prints the neutral, ramp, hero, category, CVD and increased-contrast tables |
  | `hue_search2.py` / `hue_search3.py` | Random search for the category hue set (see §3.2) |
  | `extra.py`, `chart.py`, `misc.py` | Hero A step choice, chart tick and hatch, and the remaining comparisons |

  The scripts are a scratch artefact. If this proposal is adopted, they should move to `scripts/`.
- **Sanity check:** the library reproduces UI_DESIGN §3.2's numbers: `ink` on `bg` 15.33, `ink2` on `hairline` 4.70, `signal` on light `bg` 1.55, `onSignal` on `signal` 9.90.
- **Floors** are the `contrast_pairs_test.dart` rules: `text` 4.5, `nonText` 3, `pressStep` 1.15, `idleBlock` 1.5, `focusTwoTone` 9. A pair marked `info` has no floor and is reported for judgement.
- **Distances:** ΔEOK is Euclidean distance in OKLab. As a yardstick, CSS Color 4's gamut-mapping algorithm treats 0.02 as a just-noticeable difference (JND). That figure comes from the CSS spec, not from my calculation.
- **Marigold's hue:** `#FFB020` = `oklch(0.813 0.165 75)`. Hue 75° is the anchor for the ramp and for the neutral tint.
- **Not verified:** rendering on a device, low-end LCDs in daylight, APCA (the project names WCAG 2 only), and any user test (see §11).

## 1. Marigold tonal ramp

### 1.1 Light ramp (primitives)

The ramp holds hue 75° end to end. The brand value is **pinned** at step 400. The other steps take about 95–100% of the sRGB maximum chroma at their `L`. The light end steps finer (ΔL 0.030–0.048) than the middle (0.08–0.10). Only steps that have a role become Dart constants; the rest are listed for reference only and are not shipped (governance rule 1; "every step has a job").

| Step | Hex | OKLCH | ΔL to previous | Role | Shipped? |
|---|---|---|---|---|---|
| 50 | `#FFF5E8` | oklch(0.974 0.020 75) | — | Fallback hero fill (see §5.1) | no |
| 100 | `#FFE9CC` | oklch(0.944 0.045 75) | 0.030 | **`signalContainer`**: light hero fill (variant A) | yes, if A |
| 200 | `#FFD9A5` | oklch(0.905 0.079 75) | 0.039 | — | no |
| 300 | `#FFC675` | oklch(0.861 0.118 75) | 0.044 | — (the D91 trail renders near here: `signal` at 50% over step 100 = `#FFCC76`; it is painted, not a token) | no |
| 400 | `#FFB020` | oklch(0.813 0.165 75) | 0.048 | **`signal`** (pinned brand) | yes (exists) |
| 500 | `#DE9814` | oklch(0.731 0.150 75) | 0.082 | — (reserved: a fill press for the Add key, if it ever drops the lip collapse) | no |
| 600 | `#B67C0C` | oklch(0.630 0.130 75) | 0.101 | — | no |
| 700 | `#90610C` | oklch(0.530 0.108 75) | 0.100 | — (4.56:1 on step 100: rejected as secondary text, too thin a margin) | no |
| 800 | `#6C4805` | oklch(0.432 0.088 75) | 0.098 | **`onSignalContainerVariant`**: hero secondary text and the over-state hatch (variant A) | yes, if A |
| 900 | `#493004` | oklch(0.331 0.066 76) | 0.101 | **`onSignalContainer`**: the hero number (variant A); increased-contrast `onSignalContainerVariant` | yes, if A |
| 950 | `#2F1F07` | oklch(0.254 0.044 74) | 0.077 | Increased-contrast `onSignalContainer` | yes, if A |

### 1.2 Dark steps (a separate ramp, not the light one reversed)

Chroma is lower than at the light ramp's matching roles: 0.030 against 0.045 for the container, and 0.060 against 0.088 for secondary text. The dark end has wider separation. **`signal` stays `#FFB020` in dark.** It is the pinned brand and the ET66 key, it already measures 8.11–10.25:1 on the dark layers, and `onSignal` on it is 9.90:1. Lowering its chroma would add a second marigold for the same meaning.

| Role | Hex | OKLCH |
|---|---|---|
| `signalContainer` (dark hero fill, variant A) | `#302617` | oklch(0.276 0.030 77) |
| `blockIdle` on the dark container (variant A) | `#4D4539` | oklch(0.395 0.022 78) |
| `onSignalContainerVariant` | `#D5B993` | oklch(0.800 0.060 75) |
| `onSignalContainer` | `#FBECD9` | oklch(0.950 0.030 74) |
| `signal` | `#FFB020` | oklch(0.813 0.165 75) |

### 1.3 Where these roles live in code

**No new public field is needed for the hero.** D97 kept `display`, `displayInk`, `displayInk2`, `blockIdle` and `displayEdge` as separate public tokens "so the hero can change layer without touching every card". Variant A repoints them at the ramp:

| Role name (this doc) | `HisaabColors` field | Light (A) | Dark (A) |
|---|---|---|---|
| `signalContainer` | `display` | `_marigold100` `#FFE9CC` | `_darkMarigoldContainer` `#302617` |
| `onSignalContainer` | `displayInk` | `_marigold900` `#493004` | `#FBECD9` |
| `onSignalContainerVariant` | `displayInk2` | `_marigold800` `#6C4805` | `#D5B993` |
| (idle day) | `blockIdle` | `#CBBDAB` oklch(0.805 0.029 74), own value (no longer an alias of `hairline`) | `#4D4539` |
| (edge round today) | `displayEdge` | `ink` `#161615` (unchanged, so it matches the Add key's ink lip) | transparent (unchanged) |

A public `signalContainer` field is added only when a second use appears, for example the Spends Ask AI well (governance rule 1). Until then, `display` is the seam.

## 2. Neutrals warmed toward marigold

**Method.** Each neutral moves to hue ~75° with chroma 0.003–0.016. Its **relative luminance is held** (`L` is solved for the old Y), so every WCAG ratio stays within ±0.07 of today. `ink` stays as it is in both themes (`#161615`, `#F2F1EC`). Case study 08 keeps `ink` near-neutral because it is also the focus ring and the pick fill. `onSignal` stays `ink`.

The shift per colour is ΔEOK 0.001–0.007, below the 0.02 JND. This is polish, as case study 08 §2 predicted, and it will not on its own fix "unpainted".

| Token | Light old | Light new | New OKLCH | Dark old | Dark new | New OKLCH |
|---|---|---|---|---|---|---|
| `bg` | `#EEECE6` | `#F1EBE4` | oklch(0.943 0.011 72) | `#121211` | `#131210` | oklch(0.183 0.004 85) |
| `surface` (= `display`, light `control`) | `#FFFEFB` | `#FFFEFC` | oklch(0.997 0.003 85) | `#1F1F1D` | `#211F1C` | oklch(0.240 0.006 78) |
| `sunk` | `#E4E1DA` | `#E7E0D8` | oklch(0.910 0.013 71) | `#2C2C29` | `#2F2B27` | oklch(0.292 0.009 67) |
| `hairline` (= light `blockIdle`, dark `control`) | `#D3D0C8` | `#D7CFC5` | oklch(0.858 0.016 74) | `#373734` | `#3A3632` | oklch(0.336 0.009 68) |
| `blockIdle` (dark) | — | — | — | `#3E3E3B` | `#413D38` | oklch(0.362 0.010 74) |
| `ink2` (= dark `displayInk2`) | `#585752` | `#5B5650` | oklch(0.456 0.012 73) | `#A3A29C` | `#A7A199` | oklch(0.712 0.013 75) |
| `displayInk2` (light) | `#62615C` | `#65605A` | oklch(0.492 0.011 73) | — | — | — |
| `inverse` (light; dark = `ink`) | `#2F2E2B` | `#312E29` | oklch(0.303 0.010 81) | — | — | — |
| `ink` | `#161615` | **unchanged** | oklch(0.200 0.002 0) | `#F2F1EC` | **unchanged** | oklch(0.958 0.007 97) |

`scrim` (`ink` at 32% light), `clear` (`bg` at 0%) and `focusGap` (= `bg`) follow their constants.

### 2.1 Every §3.2 contrast row, old and new

The other §3.2 rows are the same colour pairs and so carry the same numbers:
- `outline` = `ink2` on `surface` / `sunk`.
- `primaryContainer` on `primary` = `ink` on `sunk`.
- Tooltip = `ink` on `surface`.
- `focus` against `control` / `hairline` = `ink` on those.
- `focusGap` on an `ink` pick = `bg` on `ink`.

| Pair | Rule (floor) | Light old | Light new | Dark old | Dark new |
|---|---|---|---|---|---|
| `ink` on `bg` | text 4.5 | 15.33 | 15.30 | 16.57 | 16.55 |
| `ink` on `surface` | text 4.5 | 17.95 | 17.97 | 14.60 | 14.54 |
| `ink` on `sunk` | text 4.5 | 13.87 | 13.84 | 12.38 | 12.41 |
| `ink` on `hairline` | text 4.5 | 11.75 | 11.75 | 10.56 | 10.59 |
| `ink` on `control` | text 4.5 | 17.95 | 17.97 | 10.56 | 10.59 |
| `ink2` on `bg` | text 4.5 | 6.13 | 6.14 | 7.32 | 7.31 |
| `ink2` on `surface` | text 4.5 | 7.18 | 7.20 | 6.45 | 6.42 |
| `ink2` on `sunk` | text 4.5 | 5.55 | 5.55 | 5.47 | 5.48 |
| `ink2` on `hairline` | text 4.5 | 4.70 | 4.71 | 4.67 | 4.68 |
| `ink2` on `control` | text 4.5 | 7.18 | 7.20 | 4.67 | 4.68 |
| `bg` on `ink` (a pick) | text 4.5 | 15.33 | 15.30 | 16.57 | 16.55 |
| `control` on `bg` | pressStep 1.15 | 1.17 | 1.17 | 1.57 | 1.56 |
| `hairline` on `surface` | pressStep 1.15 | 1.53 | 1.53 | 1.38 | 1.37 |
| `sunk` against `control` (a press) | pressStep 1.15 | 1.29 | 1.30 | 1.17 | 1.17 |
| `hairline` against `sunk` (a pressed key) | pressStep 1.15 | 1.18 | 1.18 | 1.17 | 1.17 |
| `sunk` on `surface` (keys, wells) | pressStep 1.15 | 1.29 | 1.30 | 1.18 | 1.17 |
| `surface` on `bg` (a card) | info | 1.17 | 1.17 | 1.14 | 1.14 |
| `onSignal` on `signal` | text 4.5 | 9.90 | 9.90 | 9.90 | 9.90 |
| `displayInk` on `display` | text 4.5 | 17.95 | 17.97 | 14.60 | 14.54 |
| `displayInk2` on `display` | text 4.5 | 6.15 | 6.17 | 6.45 | 6.42 |
| `blockIdle` on `display` | idleBlock 1.5 | 1.53 | 1.53 | 1.54 | 1.53 |
| `focus` on `bg` | nonText 3 | 15.33 | 15.30 | 16.57 | 16.55 |
| `focus` on `sunk` | nonText 3 | 13.87 | 13.84 | 12.38 | 12.41 |
| `focus` against `focusGap` | focusTwoTone 9 | 15.33 | 15.30 | 16.57 | 16.55 |
| `bg` on `inverse` (snackbar) | text 4.5 | 11.49 | 11.42 | 16.57 | 16.55 |
| `signal` on `bg` (light: the cap; never bare) | info | 1.55 | 1.55 | 10.25 | 10.24 |
| Hero `ink` on `display`, both under the scrim | info (≥ 4.5 kept) | 8.64 | 8.65 | 5.89 | 5.88 |
| `signal` on `display` under the scrim | info (D93 cites 3.92) | 1.69 | 1.69 | 3.92 | 3.91 |

**No pair falls below its floor.** The slimmest margins are the same as today: `blockIdle` 1.53 (floor 1.5) and dark `pressStep` 1.17 (floor 1.15).

## 3. Category hues

### 3.1 How many

The app has **10 categories**, fixed in count and order (BR-11; seeded in `migration_001_initial.dart`):
- **Spent (8):** food, travel, shopping, bills, fun, health, home, other.
- **Got (2):** salary, other_income.

**Proposal: 7 hues plus neutral.** The 7 Spent categories other than *other* each get a hue. *Other* and both Got categories stay neutral (`sunk` well with `ink2` glyph).

Why:
- *Other* is by definition not a kind.
- Got is never charted beside Spent; the Spent | Got switch separates them.
- A green-adjacent salary hue would read as "good" (case study 08).
- Each added hue lowers the colour-blind separation further (§3.4).

### 3.2 Choosing the hues

**Excluded bands:**
- within 30° of marigold (75°): 45–105° is reserved for *today*;
- within 25° of red (29°): 4–54°;
- within 25° of green (142°): 117–167°.

That leaves 42 candidate hues on a 5° grid. A random search (80,000 draws plus local refinement, `hue_search2.py`) picked the 7-hue set that **maximises the minimum pairwise ΔEOK** under Machado protan and deutan simulation, in light and dark solids. Normal-vision distance is weighted at half, and every pair must be at least 20° apart.

The hand-picked set I started from (110, 180, 215, 250, 285, 320, 355°) scored **0.000** because travel and fun collapsed under dark deutan. The searched set scores **0.014**.

| Hues in the set | Best score found | Set |
|---|---|---|
| 6 | 0.0169 | 105, 170, 205, 265, 305, 345 |
| **7 (proposed)** | **0.0140** | **105, 170, 195, 270, 305, 325, 350** |
| 8 | 0.0093 | 105, 170, 190, 215, 235, 265, 330, 355 |
| 9 | 0.0044 | 105, 175, 195, 225, 265, 285, 310, 330, 355 |

Ten hues, one for every category, would score lower still: the score falls with each added hue, and 10 × 20° nearly fills the 210° left. I did not search at 10.

### 3.3 Tokens

All hued categories share one lightness per role, so no category outranks another:

| Role | Light | Dark |
|---|---|---|
| Solid | `L` 0.50, `C` 0.085 | `L` 0.79, `C` 0.07 |
| Container | `L` 0.935, `C` 0.03 | `L` 0.33, `C` 0.028 |

The **container** is the icon well's fill. The **solid** is the glyph on that well and the chart bar.

| Category | Hue | Light container | Light solid | Dark container | Dark solid | Light solid OKLCH (% of sRGB max C) | ° from marigold / red / green | Flag |
|---|---|---|---|---|---|---|---|---|
| food | 105 | `#ECEBD4` | `#6B6626` | `#373626` | `#C1BE89` | oklch(0.501 0.085 105) (80%) | 30 / 76 / 37 | Olive-mustard, the nearest to marigold. It is 0.33 ΔEOK from `signal` in light and 0.11 in dark, so it won't read as "today". Watch it on a device |
| travel | 270 | `#E1E9FE` | `#506094` | `#303544` | `#A9B9E8` | oklch(0.499 0.086 270) (30%) | 165 / 119 / 128 | — |
| shopping | 350 | `#FAE2EC` | `#874E6A` | `#413037` | `#DEA9C1` | oklch(0.499 0.085 350) (41%) | 85 / 39 / 152 | **Risk: pink drifts toward red.** If it is the biggest bar it may add alarm the data doesn't carry |
| bills | 195 | `#D4F0F0` | `#017272` | `#243A3A` | `#84C9C8` | oklch(0.500 0.085 195) (100%: at the gamut edge) | 120 / 166 / 53 | — |
| fun | 305 | `#EEE5FA` | `#6F568A` | `#393241` | `#C5B0DF` | oklch(0.500 0.085 306) (33%) | 129 / 83 / 164 | — |
| health | 170 | `#D7F0E6` | `#23735C` | `#273A33` | `#8DCAB4` | oklch(0.501 0.085 170) (86%) | 95 / 141 / 28 | **Risk: teal-green, 28° from green.** It may read as "good". Swap with bills (195) if the test flags it |
| home | 325 | `#F4E3F5` | `#7C527E` | `#3D313D` | `#D2ACD4` | oklch(0.501 0.085 325) (36%) | 110 / 64 / 177 | — |
| other, salary, other_income | neutral | `#E7E0D8` (= `sunk`) | `#5B5650` (= `ink2`) | `#2F2B27` (= `sunk`) | `#A7A199` (= `ink2`) | — | — | — |

Container OKLCH values: light containers are all oklch(0.934–0.935, 0.029–0.030, hue ±2°), and dark containers are all oklch(0.329–0.331, 0.026–0.028, hue ±2°). Dark solids are all oklch(0.790–0.791, 0.069–0.071). The minimum hue gap between any two final hexes is 19.6°.

**Code shape:** a new `ThemeExtension`, `HisaabCategoryColors`, with a light and dark `const`. It is keyed by category seed key, and each entry is a `(container, solid)` pair. Neutral entries alias `sunk` and `ink2`. A renamed category keeps its key, so it keeps its hue. Hues are fixed, never user-picked, because a picker would be a setting (PLAN §2).

### 3.4 Contrast for every category pair

Ranges are over all 8 Spent entries, with the lowest category named.

| Pair | Rule (floor) | Light | Dark |
|---|---|---|---|
| Glyph (solid) on its own container | text 4.5 (held above the nonText 3 an icon needs) | 4.76–5.55 (health lowest) | 5.48–6.46 (other lowest) |
| Solid bar on its `sunk` track | nonText 3 | 4.36–5.55 (health) | 5.48–7.51 (other) |
| Solid bar on `surface` | nonText 3 | 5.66–7.20 (health) | 6.42–8.80 (other) |
| `ink` on a container (the conservative option: ink glyph on a tinted well) | text 4.5 | 13.84–15.11 (other) | 10.66–12.41 (bills) |
| Container on `surface` (a well in a card; today `sunk` is 1.30 / 1.17) | info | 1.19–1.30 (bills) | 1.17–1.36 (other) |
| Container on `bg` (no well sits on the page today) | info | 1.01–1.11 (bills) | 1.33–1.55 (other) |
| Solid against `signal` | info | 3.12–3.97 (health) | 1.02–1.40 (health); ΔEOK ≥ 0.112 |

Glyph on container, per category, light / dark:

| Category | Light | Dark |
|---|---|---|
| food | 4.90 | 6.40 |
| travel | 5.02 | 6.28 |
| shopping | 5.15 | 6.20 |
| bills | 4.80 | 6.41 |
| fun | 5.10 | 6.24 |
| health | 4.76 | 6.46 |
| home | 5.10 | 6.21 |
| other | 5.55 | 5.48 |

Bar on track, per category, light / dark:

| Category | Light | Dark |
|---|---|---|
| food | 4.52 | 7.35 |
| travel | 4.66 | 7.22 |
| shopping | 4.82 | 7.05 |
| bills | 4.40 | 7.47 |
| fun | 4.76 | 7.12 |
| health | 4.36 | 7.51 |
| home | 4.77 | 7.08 |
| other | 5.55 | 5.48 |

**No category pair fails.** An earlier draft at solid `L` 0.52 failed: bills 4.44 and health 4.40 against the 4.5 floor. That is why the solid sits at 0.50.

### 3.5 Colour-blind distinguishability

Minimum pairwise ΔEOK, over all 8 Spent entries, with the closest pair named. Reference: 0.02 is a JND.

| Set | Normal | Machado protan | Machado deutan | Machado tritan | Viénot protan | Viénot deutan |
|---|---|---|---|---|---|---|
| Light solid (glyph, bar) | 0.029 fun/home | 0.019 fun/home | 0.017 bills/home | 0.010 bills/health | 0.019 fun/home | 0.016 bills/home |
| Light container | 0.010 fun/home | 0.007 fun/home | 0.005 shopping/health | 0.008 bills/health | 0.007 fun/home | 0.005 shopping/health |
| Dark solid | 0.023 fun/home | 0.016 fun/home | 0.014 bills/home | 0.018 bills/health | 0.016 fun/home | 0.014 travel/fun |
| Dark container | 0.010 fun/home | 0.007 travel/fun | 0.005 bills/home | 0.007 bills/health | 0.006 travel/fun | 0.005 bills/home |

**Reading:**
- **Solids:** with normal vision they clear the JND (0.029 light, 0.023 dark). Under protan and deutan simulation they sit just below it (0.014–0.019).
- **Containers:** pale wells sit below the JND for everyone, even with normal vision (0.010). Their tint is ambience, not identification.
- **Conclusion:** at equal lightness, hue cannot identify a category for colour-blind users. This was expected (case study 08, principle 33). Identity stays with the icon, the word and the fixed position, and the colour is a redundant cue only.
- **Against `signal`:** the solids stay far from marigold under simulation. The light minimum is 0.328 normal, 0.330 deutan and 0.275 protan; the dark minimum is 0.112, 0.099 and 0.090.

## 4. Chart palette (derived from §3)

Only *Where it went* (FR-SP-4) uses category colour. The pace chart stays `ink` solid plus a dotted `ink2` line, and `signal` marks only *today* on it.

| Element | Token | Light | Dark | Rule |
|---|---|---|---|---|
| Category bar | category solid | 4.36–5.55 on `sunk` track | 5.48–7.51 | nonText 3 ✓ |
| Bar track | `sunk` (unchanged) | — | — | — |
| Limit tick where it falls on the track | `ink` | 13.84 on `sunk` | 12.41 | nonText 3 ✓ |
| Limit tick where it crosses a bar | **a 2dp `surface` notch**, not `ink` | 5.66–7.20 against the solids | 6.42–8.80 | nonText 3 ✓ |
| *(rejected)* `ink` tick over a bar | — | 2.49–3.17 (*other* 2.49) | 1.65–2.26 | **fails** nonText 3 |
| Spend past the limit | hatch: category-solid stripes on that category's container | stripes 4.76–5.55 on the container | 5.48–6.46 | nonText 3 ✓ |
| Hatch ground against the track | container against `sunk` | 1.00–1.09 | 1.00–1.16 | info: the stripes carry the edge |
| Neutral *other* bar | `ink2` | 5.55 on `sunk` | 5.48 | nonText 3 ✓ |

**Chart rules:**
- Each colour follows its category, not its rank, so sorting by amount never repaints a bar.
- Every bar keeps its icon, name, % and ₹ (FR-SP-4), so no legend has to be decoded.
- There are no donuts (UI_DESIGN §12, length over angle).
- Bars and slices animate only as today (reduced motion: no chart animation).

## 5. Hero variants

### 5.1 Variant A: a marigold-tinted hero (`signalContainer`)

Light tokens are in §1.3. `display` = `#FFE9CC` (step 100).

| Pair | Rule (floor) | Light A | Dark A |
|---|---|---|---|
| `displayInk` (hero number) on `display` | text 4.5 | 10.41 (`#493004`) | 12.79 (`#FBECD9`) |
| `displayInk2` (range line, labels) on `display` | text 4.5 | 6.93 (`#6C4805`) | 7.91 (`#D5B993`) |
| `displayInk2` over-state hatch on `display` | nonText 3 | 6.93 | 7.91 |
| Hatch against `blockIdle` | info | 4.44 | — |
| `blockIdle` on `display` | idleBlock 1.5 | 1.56 (`#CBBDAB`) | 1.57 (`#4D4539`) |
| `displayEdge` (`ink`) on `display` | nonText 3 | 15.33 | — (no edge in dark) |
| `displayEdge` against `signal` | nonText 3 | 9.90 | — |
| `signal` on `display` (bare in dark) | nonText 3 | never bare | 8.11 |
| `blockIdle` against `signal` (idle against today) | info | 1.01 by luminance; ΔEOK 0.136 (deutan 0.135, protan 0.136) plus today's ink edge | 5.16; ΔEOK 0.442 |
| `display` on `bg` (card off page) | info | **1.00**; ΔEOK 0.034 | 1.26 |
| `display` against `surface` (hero against other cards) | info | 1.17; ΔEOK 0.068 | 1.11 |
| Hero number under the scrim | info (≥ 4.5) | 5.89 (today 8.65) | 5.51 (today 5.88) |
| Hero secondary text under the scrim | info | 4.57 | 3.67 |
| `signal` under the scrim | info | edged | 3.75 (D93 cited 3.92) |
| D91 trail (`signal` at 50%) against `display` | info | 1.26 (`#FFCC76`; today 1.36 on `surface`) | 3.15 (`#986B1C`) |
| `focus` ring on `bg` (the ring sits on the page) | nonText 3 | 15.30 | 16.55 |
| `focusGap` against `display` (the band touching the card) | info | 1.00 (today 1.17) | 1.26 |

**Findings for A:**
- **Every floor passes.**
- **The light card has the same luminance as the page (1.00:1).** It stands off by chroma alone (ΔEOK 0.034). That bends §3.5's "a higher layer is never darker" rule and the D45 alternation.
- **Fallback:** step 50 (`#FFF5E8`) is 1.10:1 on `bg`, with a number at 11.41, step 700 at 4.99 and an idle block `#D4C6B4` at 1.55. But it is only ΔEOK 0.029 from the other cards, so the hero barely reads as painted.
- **The case against A:** a pale marigold hero spreads the signal hue across the largest surface. Case study 08 calls it a no-go: "it spreads the signal hue". Principle 2 says marigold "never appears as decoration". A only holds if the container is defined as *today's* surface; the hero is today's number, but that is a rewording of principle 2.

### 5.2 Variant B: an ink display card in light (Braun lineage)

In the light theme, the hero reuses the dark theme's hero values. No new hex is needed.

| Field | Light B | Source |
|---|---|---|
| `display` | `#161615` | alias of light `ink` |
| `displayInk` | `#F2F1EC` | the dark `ink` constant |
| `displayInk2` | `#A7A199` | the warmed dark `ink2` |
| `blockIdle` | `#413D38` | the warmed dark `blockIdle` |
| `displayEdge` | transparent | as in dark: marigold now sits on ink |
| `signal` | `#FFB020` | unchanged |

Dark B is the same as today's dark hero, with the warmed values.

| Pair | Rule (floor) | Light B |
|---|---|---|
| `displayInk` on `display` | text 4.5 (case study 08 asks ≥ 7) | 16.01 |
| `displayInk2` on `display` | text 4.5 (≥ 7 asked) | 7.07 |
| `displayInk2` hatch on `display` | nonText 3 | 7.07 |
| Hatch against `blockIdle` | info | 4.21 |
| `blockIdle` on `display` | idleBlock 1.5 | 1.68 |
| `signal` on `display` (bare, no edge) | nonText 3 | 9.90 |
| `display` on `bg` | info | 15.30 |
| `focusGap` (`bg`) against `display` | nonText 3 | 15.30 |
| Hero number under the scrim | info (≥ 4.5) | 7.86 |
| Secondary text under the scrim | info | 3.90 |
| `signal` under the scrim | info | 5.12 |
| D91 trail against `display` | info | 3.35 (`#8A631A`) |
| `inverse` snackbar against the ink hero | info | 1.34: keep them apart by position (case study 08, condition 5) |

**Findings for B:**
- **Every floor passes.**
- **`displayEdge` stops being needed in light.** Marigold sits on ink at 9.90:1.
- **The trade:** B adds colour *mass* through value, not hue. The screen gets darker but not more colourful.

### 5.3 Recommendation

**Ship the warmed neutrals and B. Hold A and the category colours until the tests in §11.**
- B meets case study 08's evidence and every floor.
- B keeps marigold to today's block.
- A and category hues both overrule research findings that have not yet been tested with users.

## 6. Increased contrast (principle 23)

Every value in §§1–5 needs a twin in an increased-contrast theme. The theme reuses the `contrast_pairs_test.dart` list with higher floors (D98). The intent is to push each foreground away from its background and never closer. Each theme gets its own values.

| Token | Default | Increased | Ratio, default → increased |
|---|---|---|---|
| Light `onSignalContainerVariant` | `#6C4805` (800) | `#493004` (900) | 6.93 → 10.41 on `#FFE9CC` |
| Light `onSignalContainer` | `#493004` (900) | `#2F1F07` (950) | 10.41 → 13.47 |
| Light `blockIdle` (A) | `#CBBDAB` | `#AB9E8C` | 1.56 → 2.22 |
| Dark `onSignalContainerVariant` | `#D5B993` | `#FDE0B9` | 7.91 → 11.69 on `#302617` |
| Dark `blockIdle` (A) | `#4D4539` | `#776F62` | 1.57 → 2.99 |
| Light category solid (`L` − 0.15) | see §3.3 | food `#413C00`, travel `#293766`, shopping `#5A2541`, bills `#004444`, fun `#452D5E`, health `#004635`, home `#502953` | 9.08–9.66 on own container |
| Dark category solid (`L` + 0.12, `C` × 0.7) | see §3.3 | food `#E6E4BF`, travel `#D6E1FF`, shopping `#FCD5E6`, bills `#BCECEB`, fun `#E9DAFC`, health `#C2ECDC`, home `#F3D7F4` | 9.26–9.46 on own container |

Containers stay put; only foregrounds move. The neutral increased-contrast values are out of scope here, as today.

## 7. Material `ColorScheme` mapping

- **No new token maps to a Material role.** The marigold ramp, `signalContainer`, the hero tokens and the category colours stay in `ThemeExtension`s (`HisaabColors`, `HisaabCategoryColors`).
  - Widgets that mean *today* read them directly, as `signal` is read today.
  - `primaryContainer` stays `sunk`. Pointing it at `signalContainer` would make every Material container marigold (D95).
- **Extend D95's test:** fail when any role is within 15° of hue 75° with OKLCH chroma > 0.03, not only when a role equals `signal`. Otherwise `#FFE9CC` could slip in as a "container" role.
- **Warmed neutrals flow through the existing mapping unchanged:**
  - `surface*` → `surface`, and `surfaceContainerHighest` → `sunk`.
  - `outline` → `ink2`, `outlineVariant` → `hairline`.
  - `inverseSurface` → `ink`.
- **Charts:** `fl_chart` is styled from `HisaabCategoryColors`, never from `ColorScheme`.

## 8. Contrast-list entries to add (`contrast_pairs_test.dart`, D98)

Add one line per pair in §§3.4, 4, 5.1 and 5.2 that has a floor, per theme:
- **Hero:** number, secondary text, hatch, `blockIdle`, `displayEdge` against `display` and `signal`.
- **Categories:** glyph on container ×8, bar on track ×8, notch against solid ×8, hatch stripe on container ×8.

These need new swatches (`categoryContainer(key)`, `categorySolid(key)`) or one parameterised loop.

## 9. What each item would change

| Item | Rules / docs / decisions it changes | Code and assets |
|---|---|---|
| **2. Warmed neutrals** | UI_DESIGN §3.2: both token tables, the grey-scale table and the contrast table (new numbers). D45 and D92 values are superseded, and D105's `inverse` value. D97 is unchanged (aliases hold). `08-design-system.html` and mockups 01–11 (hex values). CLAUDE.md is unchanged | `hisaab_colors.dart` (private constants). `test/core/design/hisaab_colors_test.dart`, `contrast_pairs_test.dart`. `day_blocks_test.dart` line 177 (literal `#D3D0C8`, `#62615C`). `android/app/src/main/res/values{,-night}/splash_colors.xml` (`splash_bg`, `splash_day`), so the splash still matches the first frame; brand SVGs if they use `bg` |
| **1 + 5A. Marigold ramp, tinted hero** | **CLAUDE.md** "One signal colour: marigold `#FFB020` means *today / act* only" → "marigold **and its container**". **UI_DESIGN §2 principle 2** ("never appears as decoration") needs the container defined as *today's* surface. §3.1 (the display description), §3.2 (hero table; light `blockIdle` is no longer an alias of `hairline`), §3.5 (depth: the hero layer; "a higher layer is never darker" at 1.00:1). **D46** superseded. **D97** (light `blockIdle` = `hairline` alias dropped). **D95** (test widened, §7). **Case study 08 rec. 4** ("pale marigold-tinted hero is a no-go") is overruled and needs its blind read first | `hisaab_colors.dart` (ramp constants, hero fields repointed), `day_blocks` painter colours, `home_page.dart` hero, contrast list, `02-home.html`, `05-home-dark-over-today.html`, `08-design-system.html` |
| **5B. Ink hero in light** | UI_DESIGN §3.1 and §3.5 (hero back to ink; also fix the ET66 "light body" error noted in case study 08). **D46** superseded (D47's segmented pill is unaffected). `displayEdge` becomes transparent in light, so §3.2's "always sits on `ink`" note and §3.5's "1.5px ink edge on today's block" change. Principle 35 (case study 08 list): text ≥ 16sp on the ink card | `hisaab_colors.dart` (light hero fields alias the dark constants), DayBlocks edge logic, contrast list, `02-home.html`, `08-design-system.html` |
| **3. Category hues** | **CLAUDE.md** non-negotiable "No red, no green, **no category colours**" → "no category colours except the fixed categorical set; never red or green". **D10** superseded (and D8's "one-colour system" wording). **UI_DESIGN §3.5** "Category icons sit in `sunk` wells and are monochrome" and **§12** "Rejected: category colours". **Case study 08 rec. 3**: this proposal departs on four of its seven conditions. It uses 7 hues against a cap of 6. The glyph takes the hue rather than staying `ink` (`ink` on the container is the computed fallback, 10.66–15.11). Bars take the hue. *Other* and Got stay neutral, as asked. Principle 32 ("six hues at most") is broken by one. **Principle 34** (test colour codes with oral and low-literacy users) is unmet until the test runs. PLAN §2 is untouched (no setting) | New `HisaabCategoryColors` extension in `lib/core/design/`. `category_tile.dart`, `entry_row.dart`, `category_spend_row.dart`, `where_it_went_card.dart`, `today_list.dart`, `insight_tile.dart`. Widget tests for each state. `04-add-category.html`, `06-spends.html`, `08-design-system.html`. Note: the brief asks for wells and charts only, so Add-tray tiles stay `sunk`; whether tiles take the tint is an open question for `design-ui` |
| **4. Chart palette** | UI_DESIGN §5.4 *Where it went* ("an `ink` bar on a `sunk` track"), plus the limit tick as a `surface` notch over a bar | `category_spend_row.dart` bar painter |
| **6. Increased contrast** | UI_DESIGN §9 "Every colour has an increased-contrast variant" becomes concrete for the new tokens. D98's theme list grows when the high-contrast theme ships | Future `HisaabColors.lightHighContrast` / `darkHighContrast` |
| **Docs hygiene found on the way** | `principles.md` has two different "30–34/35" lists for case study 08: the case study's proposed list differs from the merged *Colour system* list. `DECISIONS.md` jumps from D100 to D105 (D101–D104 are unused). Flag both to `design-ops` | — |

**Screens affected (to re-check contrast on a device):**
- Home: the hero, the Today list wells, the Settings well.
- Add tray: the keys, chips and tiles (neutrals only).
- Spends: *Where it went*, insights, the Ask AI card.
- Every entry: the rows and filter chips.
- Fixed bills; Settings; Ask AI goal wells (neutrals only).
- Onboarding: the hero assembly.
- The native splash.
- The snackbar.

## 10. Draft `DECISIONS.md` rows (not appended)

| # | Date | Decision | Why | Alternatives rejected |
|---|---|---|---|---|
| D106 | 2026-10-29 | **Neutrals warm toward marigold's hue (75°)** at OKLCH chroma 0.003–0.016, each holding its old relative luminance: light `bg` `#F1EBE4`, `surface` `#FFFEFC`, `sunk` `#E7E0D8`, `hairline` `#D7CFC5`, `ink2` `#5B5650`, `displayInk2` `#65605A`, `inverse` `#312E29`. Dark `bg` `#131210`, `surface` `#211F1C`, `sunk` `#2F2B27`, `hairline` `#3A3632`, `blockIdle` `#413D38`, `ink2` `#A7A199`. `ink` is unchanged in both themes (supersedes the values from D45, D92 and D105) | Greys sat at hues 87–107°, off the signal's 75°. Every contrast row moves by ≤ 0.07 and every floor holds (`docs/design/colour-proposal.md` §2). `ink` stays neutral because it is the focus ring and pick fill (case study 08) | Tinting `ink`; raising chroma further ("beige", case study 08) |
| D107 | 2026-10-29 | **The light hero is an ink display card** (supersedes D46): `display` = `ink`, and `displayInk`, `displayInk2` and `blockIdle` alias the dark constants (16.01, 7.07, 1.68:1). `displayEdge` is transparent in both themes, so marigold sits bare on ink (9.90:1) | Adds dark colour mass by value, as Monzo, Wise and the ET66 do. Keeps marigold to today's block. Passes after the case study 05-style blind read | A marigold-tinted hero (`#FFE9CC`, 1.00:1 on `bg`, spreads the signal hue: proposal §5.1); keeping the near-white card |
| D108 | 2026-10-29 | **Seven fixed categorical hues** for the Spent categories other than *other*, at equal lightness, used for icon wells (container + glyph) and *Where it went* bars only (supersedes D10). *Other* and the Got categories stay neutral. A limit tick over a bar is a `surface` notch | Search-optimised for colour-blind separation outside the marigold, red and green bands (min ΔEOK 0.014 under Machado protan/deutan). Every glyph ≥ 4.76:1 and every bar ≥ 4.36:1 on its track. Identity still comes from icon, word and fixed position. **Only after the 5-user tile-search test (case study 08 rec. 3) shows a benefit** | Six hues with bills and home sharing one; ten hues (CVD separation collapses); ink glyphs on tinted wells (kept as the fallback) |

## 11. Before any of this is adopted

1. **Blind read, B against today's hero** (case study 08 rec. 4). If the owner still wants A, run A as a third arm.
2. **Tile-search test of the category tints** (case study 08 rec. 3). Kill it if anyone reads a hue as good or bad, or if the tinted version is not faster.
3. **On-device check** of the warmed neutrals and the step-100 hero on a low-end LCD in daylight. A light hero at 1.00:1 off the page may vanish there.
4. If adopted, the change goes test-first: `contrast_pairs_test.dart` and `hisaab_colors_test.dart` entries, then `HisaabColors`. Then UI_DESIGN §3.2, the `08-design-system.html` mockup and the DECISIONS rows, in the same change.
