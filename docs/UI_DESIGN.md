# UI / UX Design Spec: Hisaab

**Name:** Hisaab (हिसाब, "keeping account").
**Direction:** calm monochrome plus one signal colour.
**Mascot:** none; the concept uses no characters. Onboarding's pictures show only a hand (D144).

Every decision below traces to research (§12). Colours, fonts and formatting were checked on 2026-10-26. Exact behaviour and formulas are in [SPEC.md](SPEC.md), mockups are in [design/](design/README.md), and the reasons are in [DECISIONS.md](DECISIONS.md).

> **Name decision (2026-10-26):** the brand is the **"hisaab•" wordmark**: lowercase, with the marigold dot.
>
> - At least 15 Play Store apps already use "Hisaab" or "Hisab" (TechBrij, Mota Moti Labs, Digiclack, Pocket Hisaab, Hisaab Kitaab and others).
> - The dot sets the logo apart visually. It does not help store search or trademark protection.
> - So the Play Store title should carry a descriptor, for example "hisaab• – Daily Spend Tracker" (the title limit is 30 characters).
> - Before launch, run an IP India trademark search in classes 9, 36 and 42.

---

## 1. The concept

> **Your month's money, cut into one share per day until payday. Today's share is a bar that glows. Everything you buy takes a bite out of it.**

(Until D114 each day was drawn as a block; [mockups 22–25](design/mockups/25-today-bar-and-rail.html) show why today became a bar and the days a rail of dots.)

Why this concept:

- **A child can count it.** Children reason better with countable pieces than with ratios, and a chocolate bar cut into pieces needs no explanation.
- **It answers both questions in one picture:**
  - *How much today?* The yellow left in today's bar.
  - *Will it last?* The dots on the rail before payday.
- **Nobody owns it.** No major money app uses a day strip or day blocks. Rings are Apple's, and pace charts belong to Copilot and Monzo.
- **It follows the safer-spending research.** Showing the exact amount left for the whole month raised spending 26–33% (University of Arizona / Think Forward). Hisaab's hero shows **today's share**, and the month total stays secondary.
- **It is honest, as Rams asks.** Every spend is a bite you can see, and the range line says what it does to the days after. Nothing is hidden.

The range line underneath borrows from electric cars. EV drivers trust a range display that says where you will arrive and with how much left. Hisaab writes "Lasts till payday · about ₹9,300 spare", payday being the destination. It is labelled as a forecast and smoothed, so it never jitters.

---

## 2. Principles (ranked; the higher one wins when two conflict)

1. **Less, but better.** One number and one picture on Home (Dieter Rams; Apple's *Qualities of Great Design*: "doesn't try to do more than it needs to").
2. **One colour, one meaning.** Marigold means **today and act** and nothing else. It never appears as decoration, and it never signals "good" or "bad" (Apple HIG colour guidance: "avoid using the same color to mean different things").
3. **Never add a tap.** YNAB added a single dropdown in June 2026 and its ratings collapsed.
4. **Inform, never shame.** There is no red anywhere in the app. Every warning comes with words and a next step (Zerodha Kite: "no big red or green boxes").
5. **Nothing moves unless you move it.** Category positions, the keypad and the nav never reorder. UPI users memorise positions. PhonePe's 2025 redesign was attacked because "everything moves around".
6. **Fly, don't teleport.** Things leave and return along the same path (Apple WWDC18 *Designing Fluid Interfaces*; Family's design values).
7. **Every icon has a word.** State is never carried by colour alone; it uses shape plus words (HIG; WCAG 1.4.1).

---

## 3. Visual identity

### 3.1 The lineage
- In 1987 Dieter Rams' **Braun ET66** calculator had a light body, dark keys, and **one yellow "=" key**.
- Apple's iOS Calculator famously echoed it.
- Hisaab borrows the same idea: a warm off-white "body" and **one marigold key**. In light theme the "display" is a near-white card on the body, the same layer as every other card (D46); in dark theme it is a dark readout. That key is the Add button, the keypad's Next key and today's block.
- Marigold (genda) also reads as Indian and festive, and no money app owns it. Wise uses lime, Robinhood chartreuse, Cash App green, CRED a neon yellow-green, and Mercury indigo.

### 3.2 Tokens

**Light**

| Token | Hex | Use |
|---|---|---|
| `bg` | `#F1EDE8` | App background, the lowest layer (a faint warm grey, never `#FFF`; D145) |
| `surface` | `#FFFEFC` | Cards, sheets, dock: raised, so lighter than `bg` |
| `sunk` | `#E7E0D8` | Keys, chips, icon wells: pressed in, so darker than `bg` and `surface` |
| `hairline` | `#D7CFC5` | 1px dividers, the dock edge, pressed keys, and chip and field fills on a `surface` layer (the tray, sheets, cards; D100) |
| `control` | `#FFFEFC` (alias of `surface`) | Chips, the Back and Settings wells and text fields at rest **on the page**: one layer up, like the cards (1.16:1 on `bg`, D100, D145). Pressed, `sunk` |
| `ink` | `#161615` | Text, selected states, a picked chip's fill, a focused field's edge, the edge around marigold |
| `ink2` | `#5B5650` | Secondary text, labels and hints; 4.71:1 on `hairline`, 7.20:1 on `control` (D90, D100) |
| `signal` | `#FFB020` | **Today + act only.** Always sits on `ink`, or carries `ink` text |
| `scrim` | `#161615` at 32% | Dims the page under the tray, sheets and dialogs |
| `clear` | `#F1EDE8` at 0% | See-through: an unselected fill, a see-through app bar, the far end of a fade. Never a bare transparent, which is black at 0% and fades through grey (D96) |
| `focus` | `#161615` (alias of `ink`) | The keyboard and D-pad focus ring, 2dp, and nothing else (§9, D99) |
| `focusGap` | `#F1EDE8` (alias of `bg`) | The 2dp band between a control and its `focus` ring (D99) |
| `inverse` | `#312E29` | The snackbar's fill, with `bg` text (11.60:1). A charcoal, not `ink`, so it is dark without being a slab (D105) |
| `danger` | `#B42318` | **The *Delete everything* hold key only** (D142): its edge, glyph and label at rest (5.64:1 on `bg`), and its fill with `bg` text (5.64:1). Never a state, an amount or an error |

**Dark** (D92: designed, not inverted. Each layer steps **lighter** by about the contrast its light counterpart steps.)

| Token | Hex | Step |
|---|---|---|
| `bg` | `#131210` | the page |
| `surface` | `#211F1C` | 1.14:1 on `bg` (light: 1.16) |
| `sunk` | `#2F2B27` | 1.17:1 on `surface` (light: 1.30); keys in the tray and wells in cards |
| `hairline` | `#3A3632` | 1.17:1 on `sunk`, so a pressed key shows (light: 1.18); 1.37:1 on `surface` for dividers and controls on a card |
| `control` | `#3A3632` | alias of `hairline`: controls on the page, 1.56:1 on `bg` (D100) |
| `ink` | `#F2F1EC` | |
| `ink2` | `#A7A199` | 4.68:1 on `hairline` and `control`, the chip and field fills |
| `signal` | `#FFB020` (same hue) | |
| `scrim` | `#000000` at 40% | dims the page and keeps the tray the lighter layer (D93) |
| `clear` | `#131210` at 0% | `bg` at 0%, as in light |
| `focus` | `#F2F1EC` | alias of `ink` (D99) |
| `focusGap` | `#131210` | alias of `bg` (D99) |
| `inverse` | `#F2F1EC` | alias of `ink`: the snackbar is a light pill on the dark page (D105) |
| `danger` | `#F97066` | lighter, so it keeps 6.72:1 on `bg`, and `bg` text on its fill 6.72:1 (D142) |

**The grey scale.** The neutrals are one ordered scale per theme, and every grey role is a step on it. A state moves a set number of steps: **a press moves one step** (a `sunk` key or well presses to `hairline`; a `control` chip or well presses to `sunk`), and a pick goes to the far end of the scale (a chip's rest to an `ink` fill, D100). A role that equals another names the same step in code, so the two can't drift (D97).

**Controls and layers (D100).** A chip, the Back well or a text field sits one step off the layer under it. On the page it is `control` (`surface` in light, `hairline` in dark). On a `surface` layer (the Add tray, the date sheet and the calendar dialog, the over, insights and Ask AI preview cards) a `control` fill would equal the layer in light, so it keeps `hairline`: `HisaabChip(onSurface: true)`, and a `fillColor` override on the tray's note field and the calendar's typed-date field. The tray's back-to-amount well stays `sunk`, like the keys and tiles around it.

| Step | Light | Dark | Job |
|---|---|---|---|
| 1 `bg` | `#F1EDE8` | `#131210` | The page |
| 2 `surface` | `#FFFEFC` (1.16:1 on `bg`) | `#211F1C` (1.14) | Cards, the tray, sheets, the dock; the hero (`display`); in light, `control` |
| 3 `sunk` | `#E7E0D8` (1.30 on `surface`) | `#2F2B27` (1.17) | Keys and icon wells at rest |
| 4 `hairline` | `#D7CFC5` (1.18 on `sunk`) | `#3A3632` (1.17) | Dividers, a pressed key, chip and field fills on a `surface` layer; in dark, `control` |
| 5 `blockIdle` | = `hairline` | `#413D38` (1.11 on `hairline`) | Day blocks that are not today, ≥ 1.5:1 on the hero |
| 6 `ink2` | `#5B5650` | `#A7A199` | Secondary text, labels and hints, Material's `outline` |
| 7 `ink` | `#161615` | `#F2F1EC` | Text, icons, a flashed tile, a picked chip, a focused field's edge; light `displayEdge` |

In light the page sits *below* the card (`surface` is the lightest grey) and `sunk` presses in below both; in dark every step is lighter than the one before.

Inside the hero display card, these extra tokens apply:

| Token | Light | Dark |
|---|---|---|
| `display` | `#FFFEFC` (alias of `surface`) | `#211F1C` (alias of `surface`) |
| `displayInk` | `#161615` (alias of `ink`) | `#F2F1EC` (alias of `ink`) |
| `displayInk2` | `#5B5650` (alias of `ink2`, D145) | `#A7A199` (alias of `ink2`) |
| `blockIdle` | `#D7CFC5` (alias of `hairline`; 1.53:1 on `display`) | `#413D38` (1.53:1 on `display`) |
| `displayEdge` | `#161615` (alias of `ink`): 1.5px edge on today's yellow and today's dot while they show marigold | transparent (none) |

The hero's finish (D106, case study 10) adds three tokens:

| Token | Light | Dark |
|---|---|---|
| `displayEtch` | `#F1EDE8` (alias of `bg`; 1.16:1 on `display`) | `#2F2B27` (alias of `sunk`; 1.17:1) |
| `displayShadow` | `#161615` at 18% | transparent (the hairline edge stays) |
| `displaySheen` | `#FFFEFC` at 70%, a wash | `#F2F1EC` at 10%, a lift |

Aliases stay separate public tokens so the hero can change later without touching every card, but each one points at the same constant as the token it equals (D97).

**Contrast (verified):**

| Pair | Light | Dark |
|---|---|---|
| `ink` on `bg` · `surface` · `sunk` · `hairline` · `control` | 15.54 · 17.97 · 13.84 · 11.75 · 17.97 | 16.55 · 14.54 · 12.41 · 10.59 · 10.59 |
| `ink2` on `bg` · `surface` · `sunk` · `hairline` · `control` | 6.23 · 7.20 · 5.55 · 4.71 · 7.20 | 7.31 · 6.42 · 5.48 · 4.68 · 4.68 |
| `bg` label, check and detail on an `ink` pick (D100) | 15.54 | 16.55 |
| A control off its layer: `control` on `bg` · `hairline` on `surface` (D100; `pressStep`) | 1.16 · 1.53 | 1.56 · 1.37 |
| A pressed control: `sunk` against `control` (D97, D100; `pressStep`) | 1.30 | 1.17 |
| A focused field's `ink` edge on `control` · `hairline` (D100) | 17.97 · 11.75 | 10.59 · 10.59 |
| `onSignal` text on `signal` | 9.90 | 9.90 |
| `displayInk2` on `display` | 7.20 | 6.42 |
| `signal` on `display` | — (never bare: `displayEdge` is 17.97 on `display`, 9.90 on `signal`) | 8.99 |
| `outline` (= `ink2`) on `surface` · `sunk`: the Switch's off thumb and edge (D94) | 7.20 · 5.55 | 6.42 · 5.48 |
| Hero `ink` on `display`, both under the scrim | 8.65 | 5.88 |
| `primaryContainer` (= `sunk`) on `primary` (= `ink`): a pressed Switch thumb (D94) | 13.84 | 12.41 |
| Tooltip: `onInverseSurface` (= `surface`) on `inverseSurface` (= `ink`) (D95) | 17.97 | 14.54 |
| Every other Material `onX` on `X` (D95) | ≥ 13.84 | ≥ 12.41 |
| `focus` ring on `bg` · `surface` · `sunk` · `display` (D99) | 15.30 · 17.97 · 13.84 · 17.97 | 16.55 · 14.54 · 12.41 · 14.54 |
| `focus` ring against a resting chip: `control` · `hairline` (D100) | 17.97 · 11.75 | 10.59 · 10.59 |
| `focus` against `focusGap`: two tones ≥ 9:1 apart (WCAG C40) | 15.30 | 16.55 |
| The hold key: `danger` on `bg` at rest; `bg` text and `focusGap` on its `danger` fill (D142) | 5.55 · 5.55 | 6.72 · 6.72 |
| Against the control's own fill, the band that touches it: `focusGap` on an `ink` pick (D100); on marigold, `focus` in light and `focusGap` in dark | 15.30 · 9.90 | 16.55 · 10.24 |

Every row is an entry in **one list of contrast pairs**, `test/core/design/contrast_pairs_test.dart` (D98). Each entry names its foreground and background, the rule it meets and where it shows. The rule sets the floor: `text` 4.5:1 (WCAG 1.4.3), `nonText` 3:1 (WCAG 1.4.11, boundaries and graphics), `pressStep` 1.15:1 (§3.3), `idleBlock` 1.5:1, `focusTwoTone` 9:1 (the ring against its gap, WCAG C40). The list runs against every theme, and each theme has its own floor per rule, so an increased-contrast theme reuses the same list with higher floors. A new pair is one line in the list, never a one-off assertion.

**Material roles.** `HisaabTheme` sets every `ColorScheme` role, because an unset role falls back to the nearest given colour (D95). `primary`, `secondary`, `tertiary` and `error` are all `ink` with `bg` on them, and their containers are `sunk` with `ink` on them; `error` is `ink` because the app has no red, and errors are said in words. Surface roles are `surface`, except `surfaceContainerHighest` (`sunk`). `outline` is `ink2` and `outlineVariant` is `hairline` (D94). `inverseSurface` is `ink`, with `surface` on it. **No role is marigold**: a widget that means *today / act* reads `signal` itself. A test fails if any role equals `signal`, unless it is on a reasoned allowlist (empty today). `*Fixed` roles follow their parents and `shadow` stays Flutter's black.

**No raw colours.** Outside `lib/core/design/`, no file names `Colors.*` or `Color(0x…)`; `test/core/design/hard_coded_colours_test.dart` reads `lib/` and fails on one. Its only exception is the `DayBlocksColors` constructor's default edge, a `const` alpha-0 value that means "no edge" and never paints. App bars are see-through through `appBarTheme` (`clear`), so Material reads the page's brightness and picks status-bar icons that contrast with it (D96).

- Marigold on the light `bg` is only 1.57:1, so **marigold never sits bare on the light background**. It always appears on ink or has an ink outline or ink label.
- **Cold-proofing:** every neutral except `ink` is tinted toward marigold's hue (about 75° in OKLCH) at the luminance it had as a plain warm grey, so every contrast above held within 0.07 (D108), the motion is playful and the corners are soft (Nothing's hardware team calls this "softer and friendlier").

### 3.3 States with one colour
| State | Today's bar and dot | Words + glyph |
|---|---|---|
| On track | Solid marigold yellow, a bite taken from it with each spend; today's dot marigold | "Lasts till payday · about ₹9,300 spare" with a check glyph |
| Slow down (< 25% of today left, or the forecast falls short of payday) | The yellow drawn as a marigold **outline**; today's dot a marigold ring | "Slow down · at this pace it runs out 22 Nov" with an alert glyph |
| Over today | No yellow; a share tick, and a diagonal hatch in `displayInk2` past it; today's dot hatched | "₹220 over today · each day after ₹1,776" |
| Over for the cycle | As over today, and every later rail dot outlined | "Over by ₹1,200 · payday in 4 days" + "See where it went" |

These rules come from the iOS battery (colour appears only when the state is unusual), Apple's gauge guidance (change the fill at thresholds and label the ends) and Oura (number plus a verdict word).

### 3.4 Typography
All three fonts are by **Ek Type**. Each has ₹ (U+20B9), tabular figures (`tnum`) and Devanagari, which was verified from the font files. All are bundled; runtime fetching is off.

| Role | Font | Size / line height | Weight · width |
|---|---|---|---|
| Hero amount | **Anek Latin** | 76/76 | 600 · `wdth` 85 (semi-condensed, like an instrument readout), `tnum`, tracking −1% |
| Entry amount | Anek Latin | 60/60 | 600 · `wdth` 85 |
| Titles | Anek Latin | 26/30 | 600 · `wdth` 100 |
| Body | **Mukta** | 16/24 | 400 |
| Label | Mukta | 14/20 | 600 |
| Small heading (`titleSmall`) | Mukta | 14/20 | 600 |
| Caption | Mukta | 13/18 | 400, `ink2` |

Hindi later uses **Anek Devanagari** with the same metrics, so no layout changes are needed.

Rules: no all-caps eyebrow labels, and no semibold body text.

**Hierarchy (D68, docs/design-research case study 02):** size sets the level and one weight step sets emphasis within it. List row titles are Regular body text (`bodyLarge`); the picked, unread or today item steps up to `HisaabType.emphasis` (600) through `HisaabType.emphasized`, never an inline `fontWeight`. A card's header uses a title style (`titleLarge`), not its rows' style. Secondary text steps back by `ink2` colour at Regular (`HisaabType.regular`), not by a lighter weight. Mukta uses only 400 and 600, with 700 kept for row amounts; keypad digits are Regular Anek, because their size ranks them. Applied app-wide. Supports text scaling to 1.5×, with the hero stepping down 76 → 56 → 44.

### 3.5 Shape, depth, icons
- **Corners:**
  - Continuous squircle corners (Flutter `RoundedSuperellipseBorder`).
  - Radius scale: 8 (today's bar, week bars) · 12 (chips) · 16 (keys) · 22 (tiles) · 28 (cards, hero) · 36 (tray).
- **Depth:**
  - Surfaces are layered by colour, not shadow (D45). **One exception: the hero is the only raised card** (D106), with one soft `displayShadow` (`HisaabShapes.raised`: 10dp down, 28dp blur, pulled in 12dp), so it reads as the object on Home. No other card gets a shadow.
  - **The hero is etched** (D106): a guilloché rosette near its top end corner, like the line work on a payment card or a rupee note, over a faint grain, both in `displayEtch` (under 1.2:1, so they never compete with the amount). Like the frame printed round a rupee note (D107), a solid keyline in `displayEtch` runs 6dp inside the edge and a dashed one in `hairline` 10dp inside (4dp dashes, 3dp gaps), each with a concentric radius, 10dp clear of the content. The hero's divider above the range line is `displayEtch` too, the quietest line. The etched card has more room: 24dp above and below its content (sides keep the shared 20dp inset), 8dp from label to amount, 24dp from amount to blocks, 20dp and 16dp around the divider. `DisplayEtch` paints it once behind a `RepaintBoundary`, mirrored in right-to-left. The loading skeleton is raised and etched too, so nothing jumps when the numbers arrive.
  - **Light theme alternates**, like IBM Carbon's light themes and Apple's grouped backgrounds: the page is grey (`bg`), a card on it is near-white (`surface`, 1.17:1), and keys or wells inside it step back to grey (`sunk`, 1.30:1 on `surface`). A higher layer is never darker than the one below it (unlike Material 3's light tonal surfaces).
  - **Dark theme steps lighter** with each layer (`bg` → `surface` → `sunk`), like Carbon's dark themes and Atlassian's elevation.
  - The hero display card is part of this: in light theme it is the near-white `surface` layer, its future days are grey blocks inside it, and today's marigold block carries a 1.5px ink edge, like the Add key. In *slow down* the marigold ring sits inside that edge.
  - Cards have no border; the fill gap carries the edge. Only the floating dock keeps a hairline. Never nest a card inside a card: within a card, rows are split by hairlines.
  - The marigold key has a **2px ink lip** that collapses when pressed, a nod to Braun's physical keys.
  - Trays, sheets and dialogs sit over the `scrim` token: `ink` at 32% in light, black at 40% in dark (D93). A light scrim on the dark page would lift the page above the tray. `HisaabTheme` sets it for every sheet and dialog.
  - **Material roles** (`HisaabTheme._scheme`, D94): `outline` is `ink2`, the 3:1 boundary that Material draws on a Switch's off thumb and track; `outlineVariant` is `hairline`; `primaryContainer` is `sunk`, so a pressed or focused Switch thumb stays visible on its `ink` track; `error` is `ink`.
  - **The snackbar (D105)** is the one inverse layer: an `inverse` pill with `bg` text, `card` radius, on the dock's gutter edges, no shadow. Undo is a Semibold word in `bg`, never marigold. It sits right above the dock or the Add key on Home, right above the pinned actions on Ask AI and the pinned Add key on Bills and Savings (D136), and `xl` above the bottom elsewhere. `HisaabSnackbarHost` (`lib/core/widgets/`).
  - There is no glass and no blur on content. Apple's Liquid Glass guidance puts glass only on navigation.
  - **Top bars on Home and Spends are pinned and solid (D81, D84):** the wordmark row and the Spends title row stay put while the cards scroll under them. The bar is plain `bg` and reaches behind the status bar. Once content is beneath it, a `hairline` bottom edge fades in (200ms, 150ms crossfade with reduced motion), as Material 3's top app bar marks scrolled content. No blur or tint: on `bg` against `surface` cards (about 3% apart) blur reads as a smudge and smears the marigold signal. The bar is a pinned sliver, so focus and TalkBack scrolling stop items below it, never under it. `TopBarScrollView` (`lib/core/widgets/`).
- **Icons:**
  - Hugeicons stroke-rounded only, size 24, `strokeWidth` 1.6, in `ink`.
  - The free set has no ⌫, so the keypad's delete key uses a glyph drawn in Hugeicons' format (`HisaabGlyphs.backspace`): `Keyboard`'s body height and squircle corners, a tip rounded like `Tag01`, and `CancelSquare`'s inner × (D48). A plain × would read as "close the tray" and ← as "back", which the app already uses for navigation.
  - Category icons come from a curated set of 51, keyed by app-owned names (`cigarettes`, `fuel`) in `AppIcons.byKey` (D138). Four the free set lacks are drawn the same way: `HisaabGlyphs.cuttingChai` (`GlassWater`'s taper, `Tea`'s steam), `autoRickshaw` (`Keyboard`'s corners, `Motorbike01`'s wheels), `hookah` and `paan` (a long tip so it never reads as `Heart`).
  - Category icons sit in `sunk` wells and are **monochrome**. Categories are told apart by icon, word and fixed position, not colour.
  - Every icon has a label.
  - **Header icon buttons** (Home's Settings, the tray's Back, and Back on every pushed screen): a 40dp well with 12 corners inside the 48dp tap target (on the page `control`, pressing to `sunk`; the tray's Back stays `sunk`, D100), set flush with the outer edge so the well lines up with the cards or tiles (D57). A full 48dp well outweighed the wordmark. Every pushed screen (Ask AI, Settings, Bills, the bill editor, Every entry) uses the one `HisaabBackButton` (D80).

### 3.6 App icon
The wordmark shrunk to its first letter and its dot: **h•**. The ET66 has one yellow key; the icon has one yellow dot.

- **Mark:** Anek Latin "h" at weight 700, `wdth` 85 (the hero amount's face), in `displayInk` `#F2F1EC` on an `ink` `#161615` field. The marigold dot sits on the baseline, 220 font units after the h.
- **Dot size:** 0.50 × x-height. The wordmark's dot is 0.63 × x-height, but at that size the icon reads as "ho"; 0.50 reads as "h." down to 36px.
- **Grid:** 108dp adaptive canvas; the drawn mark (44dp tall, 50dp wide) is scaled to 0.88 (about 39 × 44dp), in line with other launcher glyphs, and **optically centred**: it sits 4dp right and 2.5dp up from box-centre, because the heavy h and the small trailing dot otherwise read 6.7dp left and 4.5dp low (D55). Its farthest point is 28.3dp from centre, inside the 66dp safe zone, so every launcher mask (circle, squircle, rounded square) keeps it whole. The transform is one `<group>` / `<g>`, so the glyph's path data stays as generated.
- **Themed icon (Android 13+):** the same geometry as a monochrome layer; the dot survives as a dot.
- **Never:** a marigold field, an outline-only h, a gradient, a shadow, or the dot moved off the baseline.
- **Sources:** `docs/design/brand/` holds the master SVGs, the 512px Play Store PNG and the 1024×500 Play feature graphic (the wordmark, "Know what you can spend today." and the Home hero card in dark, etched, with today's bar, the days rail and the SPEC worked-example numbers, on ink), rendered from `hisaab-play-feature.html` so it can be redrawn when the hero changes. The Android resources (`mipmap-anydpi-v26/ic_launcher.xml`, `drawable/ic_launcher_foreground.xml`, `drawable/ic_launcher_monochrome.xml`, legacy `mipmap-*/ic_launcher.png`) are generated from the same geometry.
- **Rejected:** a row of day blocks (reads as a battery or signal meter, a cliché §12 already rejects); the marigold Add key with a "+" (generic); an h whose leg is today's block (reads as a broken glyph).

### 3.7 Launch splash
The native Android splash, shown before Flutter draws (D41). Preview: `docs/design/mockups/09-splash.html` (`?t=<ms>` freezes a frame).

- **Story, "Aaj":** today and tomorrow arrive as day blocks. Today lands with weight and fills marigold from the baseline. Tomorrow steps back. Today rounds into the dot, the full stop of the h•.
- **One colour from tap to Home (D42):** the splash background, the icon background and Home's background are the same, so no circle is drawn.

  | | Light | Dark |
  |---|---|---|
  | Background | `bg` `#F1EDE8` | `bg` `#131210` |
  | h | `ink` `#161615` | `#F2F1EC` |
  | Today's dot | `signal` with a 1-unit `ink` outline (like the wordmark) | `signal`, no outline |
  | Day blocks | `hairline` `#D7CFC5` | `#3D3935` (1.64:1 on `bg`; the hero's `blockIdle` moved to `#3E3E3B` with D92, the splash kept its value, warmed with D108) |

- **Composition (D43):** the mark is drawn at 0.75 inside the system's 192dp mask, so tomorrow fits whole. A second trailing day would be sliced by the invisible mask edge.
- **Optical centre (D56):** the launcher icon's nudge, scaled to 0.75 (3.41 right, 2.13 up in the 108 viewport, about 9dp and 6dp on screen), so the final h• no longer reads 13dp left and 9dp low of the screen centre. Tomorrow still clears the mask by about 1 unit at its closest corner.
- **Timing (ms from the start of the icon animation):**

  | ms | What moves |
  |---|---|
  | 0–100 | Hold while the launcher window grows |
  | 100–220 | Today fades in |
  | 100–380 | Today and tomorrow slide in (translateX 26→0), landing with speed |
  | 100–380 | Today stretches along its travel (scaleX 1.16, scaleY 0.92), easing to 1.06 / 0.97 |
  | 240–340 | Tomorrow fades in to 60%, only once it is wholly inside the mask |
  | 380–440 | Impact squash (scaleX 0.86, scaleY 1.08) |
  | 380–600 | Tomorrow fades out by 470 and slides away (+34) |
  | 380–560 | Today fills marigold from the baseline |
  | 440–660 | Today settles |
  | 520–800 | Today morphs from block to dot |

- **Exit:** the system's default fade into Home. Because the colours match, it reads as the icon dissolving into the app.
- **The splash never delays Home (NFR-9).** It is removed on Flutter's first frame, wherever the animation has got to. On a fast release cold start (moto g45), only the arrival shows before the system freezes the splash for hand-off. The fill and the dot show on slower starts.
- **Below Android 12:** a static h• (the last frame) on the same background.
- **Animations off:** the system shows the last frame and closes the splash with no fade.
- **Sources:**
  - `android/app/src/main/res/drawable-v31/splash_icon.xml` (the animation);
  - `drawable/splash_icon_static.xml`;
  - `values*/splash_colors.xml`;
  - `values-v31/` and `values-night-v31/styles.xml`.

---

## 4. Information architecture
Two tabs and one action. No hamburger menu, and settings are at most one level deep.
```
┌──────────────────────────────────┐
│  Home     [ + Add ]     Spends    │  floating dock, 76dp
└──────────────────────────────────┘
```
- **+ Add** is a marigold key, 136×58, with an ink label and an ink lip. It is the only tinted control (Liquid Glass: "when everything is tinted, nothing stands out").
- **Spends** holds where the money went and has the **Ask AI** card at the top.
- **Settings** is at the top right of Home.
- **Fix my number** adds no tab and no level: one quiet text row at the end of Home's scroll, and one row at the end of Settings › Money (§5.2, §5.6, D169). Its sheet and *Used*'s keypad are in §5.7.

---

## 5. Screens

### 5.1 Onboarding: 3 questions
1. **"How much money comes in each month?"**
   - The keypad is open from the start.
   - The hint names the money, not a job: "Pay, business, pension or family money. If it changes, a low month is a safe guess. Paid weekly? Add up a month." Only about a quarter of Indian workers are salaried, so "salary" would leave most users out (D116; mockup [26](design/mockups/26-income-for-everyone.html)).
   - Between the keypad and Next: a lock and "What you type stays on this phone. The app never uses the internet.", centred, `bodyMedium` in `ink2`. It answers the moment the question feels intrusive.
   - A live preview underneath turns the amount into blocks: "That's about **₹1,500 a day**", and the day blocks appear one by one as you type. Its caption is "Every day gets its own share" (`bodyMedium`, `displayInk2`). This is the rare, bold delight moment.
   - *Restore a backup* (FR-ON-1, D139, mockup [34](design/mockups/34-data-controls.html)): a `hairline` text chip on its own 48dp row at the top end, above the progress dots, so it never overlaps them at 320dp. Never marigold: it is a way out for a new phone, not the question.
2. **"When does it come?"** Big chips: *1st of the month* · *Last day of the month* · *Pick a date* · *Every week* · *It changes*. The hint ends 'No fixed day? Pick "It changes".' so shop owners, freelancers and daily earners know which chip is theirs.
3. **"Any fixed bills?"** Chips for Rent · EMI · Phone · Internet · School fees · Subscriptions in an even grid of two rows of three, sharing the question's and the key's edges; no leading icon, and an added bill shows ink with its amount line, no check (D141). Then a big **Skip**.
   - **Pictures (D144, mockup [36](design/mockups/36-payday-illustration.html), Set A):** steps 2 and 3 show a static picture in the gap between the hint and the controls. A hand holds up a calendar (*When does it come?*), rings one day with a pencil (*Which day of the month?* and *Which day of the week?*), and holds up a receipt (*Any fixed bills?*). The style follows Charco Plus: three rough rocks scribbled in charcoal, taupe and marigold, one ink object with stipple shading on one side, sparkles and burst lines, and no faces. The rock tones live only in the pictures. Each picture is a light and a dark WebP in `assets/illustrations/`, at most 320dp wide, centred, and sized to the gap (`AdaptiveSplit.art`). It is dropped when the gap is under 120dp (a 320dp phone at 2× text) and in the side-by-side and fold layouts, so the controls never scroll. It is hidden from TalkBack and never animates.
4. **Done.** The hero card assembles: today's bar fills marigold, the rail's dots arrive one by one, and `successNotification` fires.

### 5.2 Home
```
 hisaab•                Mon, 26 Oct   [⚙]
 ┌────────────────────────────────────────┐   "display" card
 │ Safe to spend today                    │
 │ ₹1,430                                 │   Anek 76 · wdth 85
 │ ███████████████████████▒▒▒▒▒▒▒▒░ ░     │   yellow = left; bites = today's spends
 │ ₹420 spent          of ₹1,850 for today │
 │ ● · · · · · · · ·              ⚑ 4 Nov │   days rail: today + 8 more
 │ Today                 9 days to payday │
 │ ✓ Lasts till payday · about ₹9,300 spare│
 └────────────────────────────────────────┘
 [⚡] Electricity, ₹1,200, due in 3 days ›
     Thu, 29 Oct
 Today                         ₹420  See all
   [🍴] Food     Chai & samosa          ₹60
   [🚌] Travel   Auto to office        ₹120
   [🛍] Shopping DMart                 ₹240
        Home      [ + Add ]      Spends
```
(The glyphs above stand in for Hugeicons in this sketch.)

- **Hierarchy:**
  1. The hero number.
  2. Today's bar.
  3. The range line.
  4. The Today list. A bill the app posted or the user entered shows the bill's name as its second line when it has no note (*Bill* once the bill is deleted, D127); the header total counts typed spending only (D119, D123). A card bill paid shows the card glyph, the card's name, *Paid, not counted again* and the plain amount; like a saving it has no tap and is never a bite on today's bar (D123). A saving shows the piggy-bank glyph, its name (or *Put in extra*), *Saved* and the amount with no "+"; it has no tap and is never a bite on today's bar (D120).
- **Today's bar (BR-6, D114, mockup 25):**
  - 48dp tall, the card's full inner width, radius 8 (`HisaabRadii.block`).
  - The marigold yellow is what's left of today's share, from the start edge, with the 1.5dp `displayEdge` in light. Each typed *Spent* entry today is a `blockIdle` bite (a bill posted today is not: it sits in the pool, D119), 3dp apart, the first at the end edge and the newest beside the yellow; bites under 4dp merge. Category names sit under bites wide enough for them, in `displayInk2`.
  - Over today the bar spans what was spent: a 2dp `displayInk` share tick cut from the card by a `display` notch, and a `displayInk2` hatch past it.
  - Captions under it: "₹420 spent" and "of ₹1,850 for today".
- **Days rail:** one dot per day left, today's 10dp and marigold, the rest 6dp `blockIdle` (shrinking to fit at 28–31 days on small phones), then ⚑ and the payday date. "Today" and "9 days to payday" sit under it. It is the same in both modes. A month-end cycle (*It changes*, or month start on the 1st) has no payday: the caption reads "6 days left this month", the flag shows the 1st of the next month, and the range line says "Lasts till month end" (D116).
- **One height:** the bar block and the week block (BR-6a) share one cell in a `HeroModeStack`; the card takes the taller, so it never resizes.
- **Tap the hero** to flip between *Today* and *This week*. Monzo users found a daily figure meaningless when they don't spend every day.
- **This week (BR-6a, D111, D114, case study 15):** seven bars, Mon–Sun, take today's bar's place at the card's full width, 64dp tall (D114 drops D111's 48dp growth). Past days are `displayInk2` with a 2dp `displayInk` share tick each, cut from the card by a `display` notch, and hatched above it; a past ₹0 day is a 2dp baseline line. Today is marigold with the 1.5dp `displayEdge` in light, plus its tick. Days to come are 6dp `blockIdle` stubs; days outside the cycle draw nothing. The weekday letters (today Semibold) sit under them, the days rail stays, and the range slot reads "Spent ₹4,950 this week · Tue was ₹460 over its share" with the alert glyph (the check when every day is within its share).
- **Due-soon row (FR-HO-3, D118):** a `sunk` row at least 56dp tall under the hero: the bill's icon in a well, the sentence, the date under it in `ink2`, and a chevron. A tap opens the bill sheet over Home. A changing or card bill's sentence says "about" (D123).
- **Waiting line (FR-HO-3, D123, mockup [29](design/mockups/29-changing-bills.html)):** the same `sunk` row, in the same slot and edges, takes the place of the due-soon row while a bill waits for its amount: the bill's icon in a well, "Electricity went out today. How much?" (one sentence, no date line) and a chevron. A tap raises the **bill amount sheet** (FR-HO-8) in the bill sheet's route: the title "Electricity · 26 Oct" in `titleLarge`, the amount, an `ink2` caption ("Last time ₹1,200", or "You said about ₹1,200" the first time; a card adds its one line), the text chip *Didn't go out this month* (`hairline` on the sheet, never marigold), the keypad with 56dp keys and a marigold Save. Content sits on the 20dp gutter (D122).
- **The nudge slot holds one of four lines (FR-HO-3, D170):** the waiting line and the due-soon row above, then the **install line** and the **missed-log line**, in that order. Only the first that applies shows; when a higher item clears the slot collapses to empty and the next lower line waits for the next cold start or resume. Both lower lines use the due-soon row's shape (a `sunk` squircle of radius 18, at least 56dp, edges as the due-soon row), and neither is ever marigold.
  - **Install line (D169):** a `surface` well with a neutral glyph, "Already spent some this month?" in `bodyMedium` and "Fix my number" under it in `bodySmall`, a chevron; shown once.
  - **Missed-log line (D171, mockup [43](design/mockups/43-missed-log-line.html)):** a neutral question glyph in a `surface` well (one Hugeicons help mark through `AppIcon`, or a `HisaabGlyphs` drawing chosen by `design-system`; never the category's glyph, so it can't read as a logged Food entry), "Spent on Food today?" in `bodyMedium`, "Usually around 1 pm." in `bodySmall` in the date line's place, a 18dp `AppIcons.next` chevron in `ink2`. No amount and no ×. States: pressed `hairline` fill; hovered a 1dp `ink2` outline (`hairline` on `sunk` is 1.18:1 and invisible; `ink2` is 5.5:1); focused the `FocusRing`. At 1.5× text the lines wrap and the category is never cut. In two panes the line sits in Home's pane.
  - **The foot row (FR-HO-9, D169, mockup 41):** a quiet text row at the end of the scroll, "Fix my number" and a chevron in `ink2` on `bg`, 48dp or taller, with no fill, no icon well, no second line and no count. It must not look like the slot's `sunk` row, which would read as a nudge that never leaves (§3 layers).
  - **New Today rows (FR-HO-4, D166, D175):** *Not logged* and *Used* are two-line rows, as *Saved* is: line 1 the name ("Not logged" or the saving's), line 2 the kind word ("Spent" or "Got", or "Used from savings"), the amount at the end, a neutral glyph (the piggy bank for *Used*). No bite, no tint, no tap, not in the header total; direction is a word, never a sign or colour. A fix posted now sits on top. At 176dp wide a one-string title would not fit, which is why they are two lines.
- **When you underspend:** the next morning the number rolls up, and a one-line note appears: "Yesterday was ₹300 under its share, so every day got ₹35 more." (never "saved", D121)
- **Empty Today:** "Nothing spent today. Tap Add when you do."

### 5.3 Add: one tray, two steps
**Step 1 · Amount**
- [Spent | Got] segmented control, defaulting to Spent. In light theme the selected segment is a near-white `surface` pill with bold `ink` text, raised out of the `sunk` track; in dark it is an `ink` pill. It is never marigold: it is a mode, not an action, and Next is the tray's only marigold (D47).
- Amount in Anek 60 with live lakh grouping.
- **The slot (D153, D154):** under the amount, a slot at least 48dp tall for everyone. At ₹0 it can hold the *your usual* pill (FR-AD-10); after any input it holds the preview (FR-AD-3). Spacing: 20dp from Spent/Got to the amount (was 30), 4dp to the slot, 8dp to the chips (was 16). The keypad stays pinned to the bottom of the tray and does not move; the amount sits about 10dp higher and the chips 8dp lower. The pill keeps 12dp clear of the chips. It is the one outlined control in the fill-only system (D88, D100): an offer, not a choice. The short tray keeps its 12dp gap above the amount. The pill is 40dp, fully round, with a 1dp `ink2` edge on `surface`, no fill and never marigold, so *Next* stays the tray's only marigold.
- Quick chips **+₹10 +₹20 +₹50 +₹100 +₹500** that *add* to the amount, like counting notes.
- Phone-layout keypad (1-2-3 on top, as on the UPI PIN pad):
  - Keys 64dp tall, in `sunk`.
  - Bottom row: `00 · 0 · ⌫`. Long-press ⌫ to clear.
  - **No decimal key.** Studies of low-literacy users found decimal and numeric entry caused about half of all errors.
- The **Next** key is the marigold key, like the ET66's "=".

**Step 2 · What was it for?**
- The tray gets shorter.
- The amount flies up into the title.
- A **2×4 grid of monochrome tiles** for the 8 built-in categories (96dp, never reorders). Under them, a "Your own" rule (`labelSmall` `ink2` with a `hairline` line to the end) and row 3: up to 4 of the user's own, oldest first, then a dashed *New* tile (1.5dp dashed `ink2` edge, no fill, plus glyph and "New"), so it reads as a place for a category, not one. At 4 the tile becomes one `ink2` line with an info glyph (D138).
- Chips: *Today ▾* · *Add a note*.
- Chips and text fields are fill-only, with no edges (D88, D100). On the page a chip rests as `control` (white in light, mockups 10 C and 11) and presses to `sunk`; on the tray, a sheet or a card it rests as `hairline` (`HisaabChip.onSurface`) and only shrinks to 0.97 when pressed. A pick fills `ink` with a `background`-coloured label, trailing check and second line, on any layer. A disabled chip has no fill. With keyboard or D-pad focus a chip, picked or not, keeps its fill and gains the `focus` ring (§9, D99). A text field is a `control` well on the page and a `hairline` well on the tray and in the calendar dialog, with a 1.5dp `ink` edge only while focused; its label never floats. A pick is never marigold.
- Every entry: the category filters are one row that scrolls sideways, and the cycle header names the active filter ("October · Food", D89).
- **Tapping a tile saves:**
  1. The tile flashes to ink (120ms).
  2. The tray drops.
  3. Once the tray is gone, today's yellow pulls back, uncovering the new bite, and the number rolls in the same frame (§6, D91, D114).
  4. Haptic: `successNotification`.
- Tap path: Add → digits → Next → tile. *New* is off that path.
- **New category** (FR-AD-9, D138, mockup [33](design/mockups/33-own-categories.html)): the grid gives way to a name step in the same tray, the amount kept in the title. A focused field (a `hairline` well with the 1.5dp `ink` edge) with a count at its end; a 48dp icon line ("Icon from the name: Fuel · Change ›") with the icon in a `sunk` well; 6 name chips in a 3-column grid that narrow as typed; the marigold *Save in {name}*. The icon step is a scrolling list of groups (`labelMedium` `ink2` headings: Food and drink, Treats and habits, Getting around, Home and family, Care and giving, Things and fun), each a 4-column grid of 64dp `sunk` wells with the word under the icon; the pick fills `ink2` with a `bg` glyph and a small check (D89). Habit words are plain: no warnings, no nudges.

### 5.4 Spends
- **Header:** `‹ October ›`.
- **Ask AI card (top):**
  - A near-white card with no border, like every card, and a marigold well with an ink edge, since the AI handoff is an act (D66).
  - Shown only when the cycle has spends (DECISIONS D61).
  - Text: "Ask an AI about October" in `bodyLarge`, with "You'll see exactly what it gets." below in `bodySmall` `ink2`. TalkBack reads both as one button (D70).
- **Pace chart:**
  - A solid `ink` line for your spending and a dotted `ink2` line for steady pace. The steady line steps up on each bill's day, so a bill on the spending line meets a matching step and doesn't read as overspending (D129).
  - The y-axis is fixed, avoiding Apple Card's rescaling problem. Its labels (₹20K / ₹40K) sit just above their gridlines at the plot's left edge, in `labelSmall` `ink2`, painted under the lines; ₹0 is the unlabelled baseline. The plot takes the card's full width (D135).
  - Its height is 0.6 of the card's width, kept between 168 and 216; 160 in a short window (a phone on its side). 12 of room above the plot, `m` under the total (D135).
  - On the current cycle (D133, mockup 31): an `ink2` 1.5dp bracket from today's dot to the steady line; a dashed `ink` 2dp line (6 on 5) for *At this pace*, ending at the cycle's end or in an `ink` ring where it meets the money there is to spend. No amounts are painted on the plot (D135).
  - `xs` under the plot, a `labelSmall` date row: the cycle's first and last days in `ink2`, and *Today* (600, `ink`) under today's dot; a date that would touch *Today* is dropped.
  - `l` under the dates, the key on one row (it wraps, so the longer words never clip), then `s` below it the verdict, "Spending slower" or "Spending faster" (D77), then `xs` below it on the current cycle one `bodySmall` `ink` line with the gap and forecast: "₹7,042 under steady pace. At this pace about ₹9,300 spare." (D135).
- **Where it went:**
  - The title row ends in *See all*, built as Home's Today header: an `ink` `labelLarge` 15 text button, no inset, label ending on the rows' content edge, on the title's baseline, in a 48dp target. TalkBack reads "Every entry in October". It opens every entry of the shown cycle, so the way in stays near the top however many rows and insights follow; there is no chip at the end of the page (D131). A cycle with nothing spent has one card holding its sentence alone, with no link (D151, replacing D148). Under the card, the empty page holds a static picture in the onboarding pictures' Charco Plus style: a blank kirana bill on a spike over the three rocks (one marigold). It is centred in the height left above the dock (`TopBarScrollView.fill`), at most 300dp wide, hidden from TalkBack, and left out when that height is under 120dp, so it never makes the page scroll. Light and dark WebP files at 3× are in `assets/illustrations/spends_empty_*.webp` ([mockup 39](design/mockups/39-spends-empty-illustration.html), D150).
  - Rows sorted by amount: icon well, name, %, ₹, and an `ink` bar on a `sunk` track. Bars, not donuts: people judge length more accurately than angle.
  - If a category has a limit, the bar shows a limit tick. Overspend shows as a hatched segment past the tick, not as red.
  - A row with a limit says what is left: "Food · ₹200 left", "Bills · ₹0 left", or "Shopping · ₹840 over limit" (D110).
  - When a bar is hatched, one key line closes the card: a hatch swatch and "Striped part is over the limit." in `bodySmall` (D110).
- **Insights:** at most 3 plain sentences, each with a next step, for example "Food spending is ₹1,900 more than in September. [See Food entries]". Comparisons name the previous cycle as the switcher does, never "last month" (D78).
- **Spent, saved and not logged (D120, D176, mockup 28, mockup 41 §6):** when the cycle has saves or a fix, one `bodyMedium` `ink2` line, "Spent ₹27,570 · Saved ₹1,000 · Not logged ₹4,200", sits above *Where it went*, aligned with the card titles. Three parts at most, in that order, each only above ₹0; each part is unbreakable and the line wraps between parts with no trailing dots (mockup 42 option B), joined by the `·`. *Spent* excludes *Not logged*, and *Used from savings* is not on the line. Saves and fixes never appear in the bars, pace or insights.

### 5.5 Ask AI
Two layers only: the grey page and near-white cards, the same build as the Today list (D45, D67).
1. **Header:** Back and "Ask AI". It is fixed and doesn't scroll.
2. **"What do you want to know?" card:**
   - The goals as one column of rows, phrased as the user's own questions (D71): *How did I do?* · *Where can I save?* · *What should my limits be?* · *Will my money last till payday?*. Each row has an icon in a 42dp `sunk` well, and hairlines are indented to the text (74dp), as on Home. *Will my money last till payday?* shows only for the current cycle (D72); a month-end cycle reads *Will my money last the month?* (D117).
   - The last row is an always-visible field with a pen icon and the placeholder *Ask something else*. While it has focus and is empty, the placeholder becomes an example: "Like: can I afford a new phone this month?" (D73). Tapping or typing in it picks it.
   - The pick: an `ink` check at the row's end and a bold label. No fill, no marigold (Apple HIG option lists).
   - The period: *October* (default) · *Aug – Oct*, as one segmented control in the Spent | Got style, with no check. The segments are named by their dates, as the cycle switcher names cycles; weekly cycles read "26 Oct – 1 Nov" · "12 Oct – 1 Nov" (D76).
3. **Preview card:** "What the AI will see · 142 entries", then "Nothing leaves your phone until you share it." as a `bodySmall` `ink2` caption, the prompt's first lines with *Show full text*, and below a hairline the **Leave out my notes** switch (D75). No "AI can be wrong" caveat.
4. **Actions, pinned to the bottom:** the marigold **Copy & open ChatGPT** key, then *Other apps* (share sheet) · *Copy only*. While an own question is blank, all three are grey and disabled (D65). Only the cards between the header and the actions scroll.
5. **Paste, said before the tap:** when the prompt is too long to prefill ChatGPT, "ChatGPT will open empty. Long-press the message box and tap Paste." sits as a `bodySmall` `ink2` caption directly above the actions, and no toast follows the tap. The toast "Copied. In the chat, long-press and tap Paste." stays for *Copy only* and for when nothing could open the link (D62, D74).
6. With two panes or a tabletop fold, the header and the choices card sit in one pane, and the preview with the pinned actions in the other.

### 5.6 Settings (one level)
- **Money:**
  - Money coming in (D116, D137, mockup [32](design/mockups/32-income-sheet.html)): the first row of the Money card, a `SettingsRow` with the MoneyReceive glyph and the income as a `bodySmall` `ink2` second line. It opens the bill sheet's slip (below) with two rows, *Amount* and *When it comes*, and no Delete key. The amount question is onboarding's keypad with a `titleMedium` "From payday, 4 Nov." and a `bodyMedium` `ink2` "This month's ₹45,000 stays as it came." above the keys. After a save the footer can show a `HisaabChip` (`onSurface`) *Change this month too*, then "This month's pay is now ₹50,000." with *Undo*. *When it comes* opens onboarding's five choices as full-width `HisaabChip`s (the picked one filled with a check, *Pick a date* and *Every week* showing the picked day as their detail), the shared 1–31 grid or the seven weekday chips as one more step, then a `titleMedium` "This money lasts till 24 Nov." with a `bodyMedium` `ink2` "That's 30 days, about ₹281 a day." and the marigold *Save* (D140).
  - Bills (renamed from *Fixed bills*, D123): one card of rows (name, "Every month on day 29", amount; "about ₹1,200" for a changing or card bill, D127), soonest first, with *Add a bill* as a full-width marigold `SignalKey` pinned at the bottom (padding 8dp above, 16dp below, on the 20dp gutter; the rows scroll above it with no line or fade; the list and key share one column at most 560dp wide; D136). Each row leads with the bill's icon in a `sunk` well. Swipe a row away with Undo. Adding asks one question per screen, like onboarding: the name (a field with 8 bill chips 16dp under it (the onboarding six, then *Credit card* and *Electricity*, D123), in two equal-width columns that share the field's edges and narrow to what is typed; a tap fills the field and marks the pill, and Next moves on; Next alone at the bottom, D83, D85, D86), the amount on the keypad, then a 1–31 day grid where tapping a day saves.
  - **The bill sheet (FR-SE-1, D118, mockup [27](design/mockups/27-bill-sheet.html)):** tapping a row (or Home's due-soon row) raises a sheet that looks like a paper bill. Changing never pushes a page.
    - The slip is `display` paper, flat (D106: only the hero is raised), with 20dp top corners and a torn bottom edge of 14dp × 8dp teeth.
    - Head: the "Bill" eyebrow, the name, and the bill's icon in a `sunk` well. Then a dashed `hairline` perforation with 16dp half-circle notches cut at both edges.
    - The amount line: the amount in Anek with tabular figures, "Every month on day N" under it, and the stamp. The stamp is straight (not rotated), letter-spaced `displayInk2` text written as in the copy (never upper-cased: "Due in 3 days", "Went out 5 Oct", "Paid 5 Oct" for a card, "Waiting" while a changing bill waits, D127) in a 2dp `displayInk2` edge with 6 corners, its right edge on the value column. It lands with a squash (scale 1.25 → 1) 260 ms after the sheet opens, on the spring tokens; with reduced motion it fades in over 150 ms.
    - Five rows, Amount, Kind of bill, Day of the month, Name, Icon (D123), each a label, a dotted leader in `hairline`, the value, and a chevron; 56dp tall. A saved row flashes `sunk` once.
    - The foot: "Next due on {date}" (a waiting bill says when it went out: "Went out on 24 Oct. Home asks how much.", D127), then *Delete bill*, a full-width `sunk` key in the place *Save* takes on a question.
    - A question replaces the rows inside the sheet, under a compact slip (name, amount, icon): the keypad with *Save*, showing "Was ₹1,200" under the typed amount; the 1–31 grid; the name field (no pills), with a line saying whether the icon follows the name; or a 4-column grid of the 16 icons in `sunk` wells, labelled under each. Back sits top left.
    - **Picked state** (the day grid and the icon grid): the bill's current day or icon lifts one layer to `control` (as a chip on the page), its label turns Semibold, and a 6dp `ink` dot sits 6dp in from its top end corner. TalkBack announces it as selected.
    - Bill icons sit in `sunk` icon wells everywhere: the slip, the Bills rows, the grid and Home's due-soon and waiting rows.
    - *Kind of bill* (D123): a row between Amount and Day; its value ("Changes every month") may take two lines, end-aligned. Its question, "What kind of bill is it?", stacks the three answers as full-width `hairline` chips 8dp apart, the current one picked (`ink` fill, check); a tap saves, like the day grid. A saving has no such row.
  - **Remind ask (FR-SE-1 AC-10, D126):** after the first changing or card bill is saved, a sheet rises in the bill sheet's route: "Remind you on the day it's due?" in `titleLarge` on the 20dp gutter, a full-width marigold *Remind me* key, and the text chip *Not now* under it (`hairline`, never marigold). Asked once. The reminders themselves are system notifications in a *Bill reminders* channel with the monochrome launcher glyph, and a locked screen hides their text.
  - Savings (D120, mockup [28](design/mockups/28-savings.html)): a second row under Bills with the piggy-bank glyph. The list, wizard and sheet are the bill ones with a saving's words ("put in", "due"); the sheet drops the Icon row. Under the list, a `ink2` footer "₹5,000 put in since Oct", and the pinned marigold *Add a saving* with a full-width *Put in extra* chip 8dp under it (never marigold; only the keypad's Save is). In a window under 480dp tall the two share one row, the chip stretched to the key's height (D136). *Put in extra* rises in the bill sheet's route: the question, the amount, a `ink2` line saying what it does to the days left, the keypad and a marigold Save.
  - **Yearly costs and *Used* (D174, D175, mockup [42](design/mockups/42-yearly-costs.html)):** the saving's name pills gain *Insurance*, *School fees* and *Festival* after the four; for those three the amount question carries a `bodyMedium` `ink2` caption. A list row gains a **third** `bodySmall` `ink2` line, "₹12,000 set aside", under the schedule line (about 84dp), only above ₹0. The footer gains a second line, "₹5,000 still set aside". The saving's sheet shows the set-aside amount under its amount line and an outlined *Used some of it* key mid-sheet, away from *Delete saving* (a `sunk` key, last); the hint above the key is on the three yearly pills only. The *Used* question is §5.7.
  - My month starts on: *Payday* (default) / *1st*
  - **Fix my number row (D169):** the last row of the *Money* card, after *My month starts on*: a `SettingsRow` with a neutral glyph (mockup 41 uses a sliders stand-in; `design-system` picks the Hugeicons or `HisaabGlyphs` glyph) and the detail "When the number on Home looks wrong." in `bodySmall` `ink2`. It opens the sheet of §5.7 over Settings. Hidden in *No income*.
- **Look** (D130, mockup [30](design/mockups/30-look-setting.html), case study [19](design-research/case-studies/19-theme-choice.md)): a `titleLarge` header 24dp under the Money card, then one `surface` card holding one row (20dp gutter, 12dp vertical): *Light or dark* in `bodyLarge` with the current look's name under it in `bodyMedium` `ink2`, and at the end a compact icon toggle: a `sunk` track (radius `key`, 4dp inset and gaps) of three 48dp buttons (radius `chip`) with 24dp smartphone, sun and moon glyphs in `ink`. The pick fills `ink` with its glyph in `bg`; a press steps to `hairline`. The words may wrap beside the toggle but never break mid-word; when a word can't fit (2× text on a 320dp phone), the toggle moves under the words, on their start edge. The buttons carry their names for TalkBack and the row's words are excluded, so nothing is read twice. Never marigold: a look is a mode, not an act. One tap applies; `MaterialApp.themeAnimationDuration` is zero, so nothing fades.
- **Categories** (FR-SE-2, D138): a group under Look holding one row, *Categories*, which opens a page: *Your own* ("2 of 4") with a dashed-well *Add a category* row, then *Spending* (the 8, with a hint that they keep their places) and *Money in*, each a card of rows with the icon in a `sunk` well. A row opens a sheet in the bill sheet's style: the icon in a 56dp `surface` well beside the name in Anek, with "Your own" or "Built in" above it, a card with *Name* and *Icon* rows, then for the user's own a full-width `surface` key *Hide {name}* with an eye-off glyph and a note on what hiding keeps. Never marigold: hiding is undoable, not an act to push.
- **Your hisaab** (FR-SE-4, BR-16, D139, mockup [34](design/mockups/34-data-controls.html), case study [23](design-research/case-studies/23-backup-reset-delete.md)): a `titleLarge` header 24dp under the Look card, then two `surface` cards 24dp apart. Export CSV comes later (M6).
  - **Card 1:** `SettingsRow`s *Back up* (with the last-backup date as the `ink2` second line), *Restore* ("Bring back from a backup file") and, for 7 days after a restore, *Undo restore* (Undo02 glyph). A busy row swaps its arrow for Loading03 and its second line for "Backing up…" or "Checking the backup…". Under the card, the no-password note in `bodySmall` `ink2`.
  - **Card 2:** *Delete everything* alone, so the group gap sets it apart. It is a plain row with the Delete02 glyph, not a warning colour.
  - **Restore dialog** (the app's one dialog, D4): title, two `bodyMedium` lines (the file's facts, then this phone's), and two stacked full-width keys, since side by side they need about 236dp and the dialog has 232dp: *Replace* filled `inverse` and *Keep what's here* `hairline`. While replacing, "Bringing back your hisaab…" with Loading03 fills the keys' 120dp, so the dialog keeps its size. At 2× text the two lines scroll; the title and keys stay put.
  - **Delete everything page:** a pushed page in reading order:
    1. The lead sentence.
    2. "This goes:" in one `surface` card, a glyph per item, ending in "Once it's deleted, there's no getting it back."
    3. What stays, outside the card with `ink2` ticks.
    4. The last-backup line and a full-width *Back up first* key (`sunk`).
    5. 24dp below it, the hold key, in the page flow (not pinned).
  - **The hold key:** at rest, a 2dp `danger` edge with the Delete02 glyph and label in `danger`. While held, a `danger` fill sweeps from the start edge and the label turns `bg` where the fill has passed. Let go full, it reads *Undo* with the Undo02 glyph and the fill drains back towards the start edge over 5 s while the caption counts down; a tap stops it and nothing is deleted (D149). The caption under it is always shown. Its weight comes from the 2dp edge and the fill, so in a squint test it reads before *Back up first*. Never marigold. It is the app's only red: the owner wanted the one irreversible act to look destructive (D142, amends D9).
  - **Marigold is never on an act that removes or replaces data** (*Replace*, the hold key). Marigold means *today / act*, and these are acts to slow down for, not to invite.
- **About.**

### 5.7 Keypad sheets: Fix my number and Used (FR-KS, FR-FX, D178, mockups [41](design/mockups/41-fix-my-number.html) and [42](design/mockups/42-yearly-costs.html))
Both are questions in the bill sheet's route, built from the Add step 1 anatomy: the amount, one fixed-height two-line slot and the shared keypad.
- **Layout:** the keypad, its full-width action key and the typed amount are pinned; the title and slot scroll between them. Stacked below about 560dp wide; side by side only at 560dp or more and short, and in a tabletop. Keys are 56dp (48dp in a short window), the action key 56dp. The pinned bottom padding is the gutter plus the system bottom inset. The sheet's drag handle (48dp) is not drawn when the window is under 600dp tall; swipe down, the scrim and Back still close it (D180). The sheet sits in one sub-screen of a fold, never across it.
- **Action key:** *Fix it* and *Save* are a full-width marigold `SignalKey` with an `onSignal` label and a 1.5dp edge, as *Next* is in the Add tray (marigold means act). Disabled is a hatch or outline with a TalkBack hint, never colour alone.
- **The slot:** two lines; every state is a child of one `IndexedStack`, so the slot never resizes between states (the guard shortens the whole sheet once). Line 1 anchors ("hisaab thought ₹17,430."); line 2 says the gap and its effect. Digit changes swap text instantly; a change of state class crossfades 150 ms. No red, no green: direction is the words "less" and "more".
- **The guard (FR-FX-4):** the keypad and action key give way to two equal-weight outlined 56dp full-width keys, stacked, *No, some is older* first, neither marigold. The sheet shortens to fit. The question line is a focusable node.
- ***All of it*** (the *Used* question): a 48dp chip beside the amount (below it at large text), resting `hairline`, filling `ink2` while the amount equals the set-aside amount (D89), `selected` in semantics. A second tap clears the amount.
- **The cap (FR-KS-2):** a 10th digit gets the shake and a 2dp ring held on the amount until the next accepted key. No words are drawn.
- **Amounts** on the Fix sheet use full Indian grouping, never the compact form.

---

## 6. Motion: Apple-style springs
Apple's WWDC18 *Designing Fluid Interfaces* says:
- Specify springs by **response and damping**.
- **Start at 100% damping, with no overshoot.** Use about 80% only when a gesture carried momentum.
- Everything must be interruptible and redirectable, with no added latency (no double-tap handlers).

Flutter: `SpringDescription.withDampingRatio(mass: 1, stiffness: (2π/response)², ratio: damping)`.

| Token | Response · damping | Stiffness | Use |
|---|---|---|---|
| `snap` | 0.25s · 1.0 | 632 | Key press release, chips, toggles |
| `standard` | 0.35s · 1.0 | 322 | Tray height change, tabs, the bite, list insert |
| `flick` | 0.40s · 0.8 | 247 | Tray thrown open or closed **by gesture only** |
| `calm` | 0.55s · 1.0 | 130 | The hero assembling after onboarding, today's bar filling in |

- **Press feedback:** scale 0.97 plus the ink lip collapsing (2px → 0).
- **Number roll:** digits roll with tabular figures over 300ms using `Cubic(0.23, 1, 0.32, 1)`.
- **Bite (D91, D114):** teaches that today's bar is today's money, and each spend eats into it. One focal point at a time, no bounce:
  1. **Wait for the tray.** Home holds its numbers while the Add tray covers it, and recomputes once the tray's exit ends. A bite behind the scrim teaches nothing.
  2. **The yellow pulls back** on `standard`, uncovering the new bite beside it, and the number roll starts in the same frame. The uncovered bite replaces D91's 50% trail: its size is the size of the spend.
  3. **Over today:** the bar rescales to what was spent and the hatch appears past the tick. No shake: it would read as an error and contradict "It happens".
- **Fill in:** each time Home's hero appears (at launch, coming back from Spends on a phone, and when the day changes), the yellow grows from empty to its level on `calm`. It shows the bar is a container.
- **Hero sheen (D106):** with the fill in, one diagonal band of `displaySheen` crosses the hero, like a card catching the light: `HisaabMotion.sheen` (1.4s), the first quarter a wait so the light follows the block, then the `sweep` curve (ease-in-out), so it never crawls at the end. The band slides in from wholly off the top start corner and out past the bottom end corner, so it never appears, sticks or vanishes at an edge. It never loops and never runs on a rebuild, only when the hero appears.
- **Hero press (D106):** the whole hero sinks to 0.97 while a finger is down, then flips Today ⇄ This week on release.
- **Today ⇄ This week (D111, D114):** the bar block and the week block crossfade in 150ms in a card that keeps its size; the days rail does not move. The bars rise from the baseline on `standard`, today's first, each column 7% later per day away, each time *This week* appears. With reduced motion only the crossfade plays. (Not built: the rail's today dot sliding off at midnight; today's bar travelling into its weekday's column; case study 15.)
- **Delight scales inversely with frequency:**

  | Frequency | Treatment |
  |---|---|
  | Every key press | Tick haptic and press scale only |
  | Every save | A bite uncovered beside the yellow, plus number roll |
  | Each time Home appears | Today's bar fills in (0.55s), and the hero's sheen crosses once (1.4s) |
  | Daily | The rail loses a dot at midnight |
  | Monthly | Cycle summary: "You kept ₹4,300", with a share card |

- **Hold to delete (D139):** the fill is linear over exactly 1.5 s (D143), with no spring, so the time is honest and predictable. Letting go early drains it on `snap`. Let go full, the fill drains back linearly over exactly 5 s, the Undo window (D149); *Undo* drains the rest on `snap`. With reduced motion the fill and the drain step in quarters on the same clock; the caption carries the timing.
- **Snackbar (D105):** rises 16dp and fades in on `standard`; leaves the same way, or on `snap` after Undo; a swipe down follows the finger. A newer message swaps in place.
- **Fix, Used and the missed-log line (D183, `docs/features/fix-my-number/05-motion.md`):** no new token. One focal point at a time, no bounce, the same path for a drop and a rise.
  - **The hold (D179):** Home holds its numbers under every sheet opened from Home, not only the Add tray, and recomputes when the sheet's exit ends.
  - **Fix:** at t = 0 the hero rolls ₹1,430 → ₹963 on `numberRoll`, today's bar re-spans every boundary in one motion on `standard` (the yellow's end 77% → 70%, the ₹420 bite 23% → 30%; a rise gives 78.6% / 21.4%), and the snackbar rises. The new *Not logged* row grows into the Today list 300 ms later (`numberRoll`'s own length, `resize` and `easeOut`), so a figure is read before the list shifts. No sheen, no fill-in, no hatch (unless the new share really leaves today over), no marigold flash, no emphasis on the row. Undo reverses along the same path and starts at once; a second fix or Undo mid-roll retargets from the displayed value.
  - **Used:** nothing in the hero moves, because nothing in it changes. The set-aside figure on the list row and the footer roll together in one motion; from Home's due-soon door the *Used* row grows in at t = 0.
  - **The sheet:** slot crossfades are 150 ms; the guard's swap is a 150 ms crossfade with the sheet's height changing on `resize` and `easeOut`; digit changes are instant. A sheet has no predictive-back preview: Back commits, then the exit or the crossfade plays.
  - **The missed-log line** arrives with Home's first frame and has no motion of its own. When it leaves, the slot collapses on `resize` and `easeOut` (a spring can't drive an `AnimatedSize`), contents fading over the first 150 ms; after a save the collapse ends no later than the drain.
  - **Reduced motion:** the hero crossfades 150 ms; the bar jumps; the new row takes its height at once with a 150 ms fade; the guard's height change is instant (the crossfade stays, since opacity is allowed); `Shake` is skipped and the cap is carried by the held ring and a spoken line. `TodayBarPainter` must interpolate segment boundaries when the total changes (1,850 → 1,383, 1,850 → 1,961), with a widget test at both.
- **Reduced motion:** all of the above become a 150ms crossfade, and charts never animate. There is no fill in and no sheen.
- **Launch splash (§3.7):** an animated vector drawable cannot use springs, so it uses `pathInterpolator` curves. The settle and the morph use the number-roll curve. Its squash overshoot is a deliberate exception to "no overshoot": a landing block carries momentum (D44).

## 7. Haptics (Flutter 3.47, verified)

| Event | Flutter | Android constant |
|---|---|---|
| Keypad, chip, tile highlight | `selectionClick()` | CLOCK_TICK |
| Save, onboarding done | `successNotification()` | CONFIRM |
| Invalid amount (more than 9 digits) | `errorNotification()` | REJECT |
| Swipe-to-delete threshold | `lightImpact()` | VIRTUAL_KEY |
| Hold-to-delete: finger down / fill full (D139) / Undo (D149) | `Haptics.tick()` / `Haptics.threshold()` / `Haptics.tick()` | CLOCK_TICK / VIRTUAL_KEY / CLOCK_TICK |
| Restore or delete failed and rolled back | `Haptics.reject()` | REJECT |
| A fix saved, or *Used* saved (D183) | `Haptics.success()` with the first visible change: the hero's roll, or the *Used* row or list figures; at the exit start when nothing visible follows (the Settings door) | CONFIRM |
| The 9-digit cap, a digit past a *Used* balance, a refused (stale) or failed Fix or *Used* save | `Haptics.reject()` | REJECT |
| A key on a keypad sheet; Undo of a fix or *Used*; a tap on the missed-log line | `Haptics.tick()` | CLOCK_TICK |
| Entering the Fix guard; Back; the missed-log line's Back | none | — |

One effect per event, never buzzy.

## 8. Voice
- Plain and kind, with "a pinch of humour, not a dollop" (Monzo).
- Never use: transaction, debit/credit, budget period, Oops, "You overspent!".
- **Back up** (verb) / **backup** (noun), never *export* for a backup. Deleting is *delete*, never *erase* or *reset* (Indian users hear "erase" as wiping the phone). A file is *backed up*, never *saved*, because *saved* means money put in. After a failure that touched data, say *Nothing changed*. The data group is *Your hisaab*, not *Your data*, since "data" reads as the mobile internet pack (D139, copy deck [34](design/mockups/34-data-controls-copy-deck.md)).
- **Amounts:**
  - Indian grouping (`₹1,25,000`), and on charts `₹1.25L` / `₹1.25Cr` from `NumberFormat` with `en_IN`.
  - Never show paise, so precision is the same everywhere.
- **Corrections and previews (copy deck [41](design/mockups/41-fix-my-number-copy-deck.md), D182):**
  - No idioms ("spot on", "came in under"); they don't travel to a Hindi-first reader (D121).
  - Direction is a word ("less", "more"), never a sign or colour.
  - The app, not the user, is the one that "thought" wrong: "hisaab thought ₹17,430." "hisaab" is lower case at a sentence start.
  - "about" only on a figure that really is approximate (the per-day floor), never on an exact gap.
  - A zero is stated, not softened: "Safe to spend today: ₹0."
  - A preview slot is two sentences, the anchor first. "Saved" means only money put into a saving. *Not logged*, *Used from savings*, "set aside" and "Fix my number" are the new terms; one word per idea (D132).

## 9. Accessibility
- Touch targets ≥ 48dp; keys and tiles are 64–96dp.
- AA contrast on every text pair, from one list of pairs checked in both themes (§3.2, D98).
- State is shown by fill, outline, hatch **and** words.
- TalkBack reads, for example: "Safe to spend today: 1,430 rupees. 9 days to payday. Lasts till payday with about 9,300 rupees spare."
- Text scales to 1.5× with no clipping. Every colour has an increased-contrast variant (HIG).
- **Keypad sheets (D184 to D186, SPEC FR-KS):**
  - **Live region:** a preview slot is a polite live region. Under TalkBack it updates 1.2 s after the last key, or at once when its state class changes, and its live text is short ("4,200 rupees less."); the full sentence is the slot's focusable text. The visible text is excluded from semantics and a separate `Semantics(liveRegion: true)` carries the live text. The amount is not a live region.
  - **Key-label clamp:** keypad key labels stop growing at 1.5× text, on the shared keypad including the Add tray, so the action key stays on screen at 2×. It is a deliberate exception to WCAG 1.4.4 for key digits only (owner's answer, D185).
  - **Held ring and spoken line:** at the 9-digit cap the amount keeps a 2dp ring until the next accepted key and a polite "That's the most you can type." is announced once. A 150 ms flash isn't used; it is gone before the eye arrives.
  - **Guard focus:** the guard's question is a `Focus` and `Semantics` node, focus requested in the frame the panel is built, then *No*, then *Yes*. Checked on a device before the build is done.
  - **Rows:** every *Not logged* and *Used* row exposes *Delete* as a custom semantics action, so no one needs a swipe or the 4 s Undo to remove it.
- **Snackbar timing (D105, D128, WCAG 2.2.1).** A bar closes after 4 s; a touch or keyboard focus on it restarts the 4 s. With TalkBack on, a bar with Undo stays until Undo, TalkBack's Dismiss action, a newer message or leaving the page. It is a live region, so it is announced without moving focus, and an amount is spoken in rupees.
- **Focus (D99, principle 24).** Every control is reachable by keyboard, D-pad and switch access, and Enter, Space and D-pad centre do what a tap does.
  - A focused control gets a 2dp `focus` ring outside a 2dp `focusGap` band. The ring follows the control's own squircle, with its corner radius grown so it stays concentric.
  - It shows only in Flutter's traditional highlight mode, so a touch never leaves a ring behind. It appears and goes at once, so it needs no motion token.
  - Focus is never selection. A picked chip, segment or dock item keeps its look and gains the ring. Material's own focus fill is turned off on the rows and dock, so it can't read as a pick.
  - The ring is painted over the control and outside its bounds, so it changes neither layout nor the tap target.
  - Where the visible well is smaller than its 48dp target (Back, Settings, back-to-amount), the ring hugs the well. Rows that fill a clipping card (Settings, Bills, entries, Ask AI goals) draw it 4dp inside their bounds, with the card's outer corner, so the card never clips it and the next row never covers it.
  - Every control gets it through `Pressable`. The InkWell rows and the dock items wrap themselves in `FocusRing`.

## 10. Android
- All orientations and window sizes; never locked (§13).
- Edge-to-edge (API 36). The dock sits above `MediaQuery.paddingOf(context).bottom`, on plain `bg`; content never goes behind it. The list's bottom 32dp fades into `bg` on a smoothstep ramp (alpha 0 → .16 → .5 → .84 → 1), so cards dissolve above the dock instead of being cut off, and the fade hints there is more below. The fade lets taps through, is invisible when nothing is under it, and high contrast drops it. The last card rests fully above it (D82).
- Predictive back: `PredictiveBackPageTransitionsBuilder` and `PopScope`. A back swipe previews a **page's** exit. A sheet (a modal bottom sheet in the bill sheet's route) has no back preview, since `ModalBottomSheetRoute` has no back-gesture hook: Back commits, then the sheet plays its exit, or the 150ms crossfade between its steps (D183). This sentence used to say a back swipe scales the tray down; it is corrected for sheets and kept for pages, and device check D10 confirms it for the Add tray.
- Launch splash (§3.7):
  - It is native: the Android 12+ `SplashScreen` API, and a static icon below that.
  - It is one colour from tap to Home in each mode.
  - It follows the phone's dark mode. When the in-app look setting (FR-SE-3) is built, it must also call `UiModeManager.setApplicationNightMode()` (API 31+) so the splash follows the app's choice.
- **Widget, tile and shortcut (D147, SPEC FR-WG, mockup [38](design/mockups/38-widget-and-tile.html)).** These open hisaab sooner without changing the entry path.
  - **The widget is the hero card in miniature, cut from the same paper.** Every size uses `display` with `DisplayEtchPainter`'s rosette (80dp in from the top end corner), the grain, and the solid (6dp in) and dashed (10dp in) keylines. It has 28dp corners and content 10dp clear of the dashed line. There is no `displayShadow` and no sheen, because a launcher clips a widget at its edges and doesn't animate it. On a 360dp phone the 4×2 is as wide as Home's hero (320dp), so the rosette and frame land in the same place.
  - **Sizes** 2×1, 2×2, 4×1 and 4×2 (placed at 4×2):
    - Every size has the marigold Add key at the top end corner: 48dp, with 16 corners. The 2×1 has a 40dp key inside a 48dp target; the 2×2 has a full-width *Add* key at the foot.
    - Today's bar is 20dp on the 4×2 and 4×1, and 14dp on the 2×2. It has no captions or names.
    - The 4×2 keeps the days rail, the `displayEtch` divider and the range line.
  - The widget follows the app's *Look*. Its colours are hisaab's tokens, never the wallpaper's dynamic colours, so marigold still means only *today / act*.
  - **Tile:** "Add a spend", subtitle "hisaab", a monochrome Hugeicons glyph, inactive state, never money. It opens with `startActivityAndCollapse(PendingIntent)` on Android 14+ (the Intent form below that), and `unlockAndRun` when the phone is locked.
  - **App shortcut:** "Add a spend".
  - **Settings › Shortcuts:** *Add a widget* and *Add to quick settings*, each opening the system's own pin dialog (FR-SE-6).
  - **Build note (D156):** the paper, today's bar and the days rail are bitmaps drawn by Kotlin ports of `DisplayEtchPainter`, `TodayBarPainter` and `DaysRailPainter` (`android/.../widget/`), each naming its Dart original. The amount and the wordmark are bitmaps in the Anek Latin from the APK's Flutter assets (`wdth` 85, tabular figures, every API level); words are TextViews in Mukta from `res/font`, except the 4×1's "Safe to spend today", a Mukta bitmap that sizes its column (D158). The moto g45's launcher draws widget TextViews in its own font, not Mukta. Colours come from `res/values/widget_colors.xml`, which a test keeps equal to `HisaabColors`.

## 11. Flutter implementation notes
- `core/design/hisaab_colors.dart`: `ThemeExtension<HisaabColors>` with light and dark instances, including the `display*` aliases, `clear`, `focus` and `focusGap`. `contrast_pairs_test.dart` fails the build if any pair in its list drops below its floor in any theme, and `hard_coded_colours_test.dart` fails on a raw colour outside `core/design/` (§3.2).
- `core/design/hisaab_type.dart`: Anek Latin (with `FontVariation('wdth', 85)` on amounts) and Mukta; `FontFeature.tabularFigures()` on all amounts.
- `core/design/hisaab_motion.dart`: the four spring tokens and `reduceMotion(context)`.
- `core/layout/`: `AppLayout.resolve` and `AppLayoutScope` (§13).
- `core/design/haptics.dart`: `Haptics.tick()`, `.success()`, `.reject()`, `.threshold()`.
- `core/widgets/`:
  - `TodayBar` (`CustomPainter`: the yellow, bites, share tick and hatch) and `DaysRail` (dots, payday flag, captions); `DayBlocks` stays only for onboarding's preview
  - `HeroDisplay`
  - `SignalKey` (marigold with ink lip)
  - `Keypad`
  - `AmountText` (rolling digits)
  - `CategoryTile`
  - `Pressable` (press scale, button semantics, keyboard activation and focus for every app control) and `FocusRing` (§9, D99)
  - `Tray`
  - `RangeLine`
- Packages: `animations`, `fl_chart` (styled to these tokens). Fonts go in `assets/fonts/`.

## 12. Research basis
- **Concept:**
  - No major money app uses a day strip or day blocks (competitor survey of slice, CRED, Jupiter, Groww, Kite, PhonePe, Jar, Robinhood, Copilot, Monzo, YNAB, Apple Card and others).
  - Children understand counting and fullness better than ratios (Frontiers in Psychology, 2022).
  - Exact amount-left displays raise spending 26–33% (University of Arizona / Think Forward via The Fintech Times).
  - EV range-display trust research (CHI 2015).
  - Garmin Body Battery, Oura Readiness and Whoop Recovery, as number-plus-verdict models.
- **One-colour systems:**
  - Braun ET66 (Rams).
  - Robinhood: "a Buy button is never any colour other than chartreuse".
  - Nothing (red only for importance).
  - Teenage Engineering (orange on black).
  - Linear (LCH, reduced blue for neutrality).
  - Vercel Geist (step roles).
  - Zerodha Kite (calm, no red/green boxes).
- **Apple:**
  - HIG on colour, gauges, activity rings ("never use rings for other data"), dark mode and Liquid Glass (WWDC25-219).
  - WWDC18-801 *Qualities of Great Design*.
  - WWDC18-803 *Designing Fluid Interfaces*.
  - WWDC17-802 *Essential Design Principles*.
  - Dieter Rams' 10 principles.
- **Simplicity:**
  - Medhi et al. 2011 (low-literacy UI: no menus, numeric entry errors).
  - NN/g on children's UX and icon labels.
  - CSBC 2022 (UPI users memorise positions).
  - PhonePe redesign backlash (2025).
  - YNAB v26.20 backlash (2026).
- **Data viz:** Cleveland & McGill (1984) and Skau & Kosara (2016) on length versus angle.
- **Rejected:**
  - The clay piggy-bank mascot and "Gullak" name (client).
  - Rings (Apple-owned, and angle reads poorly).
  - The battery or fuel tank (cliché, and it looks alarming late in the cycle).
  - Red for overspending.
  - Category colours.
  - Indigo, emerald and other Tailwind defaults.
  - Glass on content.
  - Streak shame.

---

## 13. Adaptive layout: foldables, tablets, multi-window

Android 16 (API 36, which this app targets) ignores orientation, aspect-ratio and resizability locks on displays at least 600dp wide. Foldables, tablets, split-screen and desktop windowing are normal, so every screen must adapt rather than assume a portrait phone.

**One pure function decides the layout:** `AppLayout.resolve(window size, display features)` in `lib/core/layout/`. It is unit-tested for every posture below. Screens read the result with `context.layout`; they never check `MediaQuery` widths themselves.

| Window | Width class | Arrangement |
|---|---|---|
| Phone, folded foldable, split-screen half (under 600dp) | compact | One pane, full width, dock at the bottom |
| Unfolded foldable in portrait, small tablet (600–839dp) | medium | One pane as a **centred 560dp column**, dock at the bottom |
| Tablet, unfolded foldable in landscape, phone in landscape (840dp and up) | expanded | **Two panes**: Home (40% of the width, clamped to 360–480dp) beside Spends; no dock, since both are visible, and the marigold Add key sits at the bottom of the Home pane |
| A vertical fold or hinge across the window (book posture), window at least 600dp | — | Two panes **split exactly at the fold**; with a physical hinge, nothing is drawn inside the hinge gap |
| A horizontal fold, half-opened (tabletop posture) | — | **Content above the fold, controls below it**: the dock below; onboarding's keypad below; the Add tray and every keypad sheet in the bill sheet's route keep to the lower half with the amount beside the keypad, so the hero stays readable above (Flutter sheets never straddle a fold; the sheet is the whole sheet in the lower half, never the title above and the keys below) |
| Height under 480dp (phone landscape, small multi-window) | compact height | Denser layouts: keypad beside the amount, 48dp keys |

**One widget places question and keypad:** `AdaptiveSplit` (`lib/core/widgets/`) puts a screen's header and controls in the right place for every row above.

**Rules:**
- **Use the window, never the screen.** Sizes come from `MediaQuery.sizeOf`, which is the app window in split-screen or freeform mode.
- **Nothing straddles a fold or hinge.** Display-feature bounds come from `MediaQuery.displayFeaturesOf`. Cutouts never split the layout; they are handled by safe areas.
- **Panes keep clear of system bars only on the window edges they touch,** so the right pane doesn't get left padding for a left-side cutout.
- **Text scale:** layouts are tested at 2× on a 320dp phone. Controls grow (minimum heights, never fixed), and dock labels scale down instead of overflowing. Keypad key labels are the one exception: they stop growing at 1.5× so the action key stays on screen (D185).
- **Readable width:** body content never exceeds 560dp in a single pane.
- **Sheets and keypads (D178, D180, SPEC FR-KS-1):**
  - A sheet in the bill sheet's route and the Add tray sit in **one sub-screen** of a fold, never across it: the left sub-screen in book posture, the lower half in tabletop. The route is posture-agnostic (`anchorPoint: Offset(0, windowHeight)` always, 560dp at most), so a fold during use doesn't strand a sheet.
  - **In a short window the controls are pinned and the header scrolls:** the keypad, action key and typed amount stay on screen; the title and slot scroll between them. Stacked below about 560dp wide; side by side only at 560dp or more and short, and in tabletop. A 320dp window can't hold a 220dp keypad pane beside a readable header. A flat expanded window keeps the 560dp centred stack over both panes.
  - Keys are 56dp, 48dp in a short window. The 48dp drag handle is not drawn under 600dp of height.
  - **Sheet bottoms clear the system bottom inset** (`MediaQuery.paddingOf(context).bottom`), so a gesture pill or a 3-button bar never covers the action key.
  - Each pane in two-pane is its own `FocusTraversalGroup`, Home then Spends.
- **Tests** cover phone, phone landscape, unfolded foldable, tablet, book posture with a fold, a hinge with a gap, tabletop, split-screen, 2× text and dark theme (`test/core/layout/`, `test/app/app_shell_test.dart`). New screens add their own size cases through `test/helpers/pump_app.dart` (`TestWindows`). `TestWindows` gains `splitScreen` (412×400), `splitThird` (412×300), a book (673×841 with a vertical fold, and a variant with a 40dp hinge) and a tabletop (701×841, the fold now out of the Add tray test). A keypad sheet's tests assert no overflow, the sheet inside its sub-screen and clear of the fold, the typed amount and action key inside the window above the bottom inset (checked at padding 24 and 48), and keys of at least 48dp.
