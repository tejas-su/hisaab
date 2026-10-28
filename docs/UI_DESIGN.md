# UI / UX Design Spec: Hisaab

**Name:** Hisaab (हिसाब, "keeping account").
**Direction:** calm monochrome plus one signal colour.
**Mascot:** none; the concept uses no characters.

Every decision below traces to research (§12). Colours, fonts and formatting were checked on 2026-10-26. Exact behaviour and formulas are in [SPEC.md](SPEC.md), mockups are in [design/](design/README.md), and the reasons are in [DECISIONS.md](DECISIONS.md).

> **Name decision (2026-10-26):** the brand is the **"hisaab•" wordmark**: lowercase, with the marigold dot.
>
> - At least 15 Play Store apps already use "Hisaab" or "Hisab" (TechBrij, Mota Moti Labs, Digiclack, Pocket Hisaab, Hisaab Kitaab and others).
> - The dot sets the logo apart visually. It does not help store search or trademark protection.
> - So the Play Store title should carry a descriptor, for example "hisaab• – Daily Spend Tracker" (the title limit is 30 characters).
> - Before launch, run an IP India trademark search in classes 9, 36 and 42.

---

## 1. The concept

> **Your month's money, cut into one block per day until payday. Today's block is the one that glows. Spend from it, and it drains.**

Why this concept:

- **A child can count it.** Children reason better with countable pieces than with ratios, and a chocolate bar cut into pieces needs no explanation.
- **It answers both questions in one picture:**
  - *How much today?* The size of today's block.
  - *Will it last?* The number of blocks before payday.
- **Nobody owns it.** No major money app uses a day strip or day blocks. Rings are Apple's, and pace charts belong to Copilot and Monzo.
- **It follows the safer-spending research.** Showing the exact amount left for the whole month raised spending 26–33% (University of Arizona / Think Forward). Hisaab's hero shows **today's share**, and the month total stays secondary.
- **It is honest, as Rams asks.** If you spend less today, tomorrow's block grows; if you overspend, tomorrow's block shrinks. Nothing is hidden.

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
| `bg` | `#EEECE6` | App background, the lowest layer (warm grey, never `#FFF`) |
| `surface` | `#FFFEFB` | Cards, sheets, dock: raised, so lighter than `bg` |
| `sunk` | `#E4E1DA` | Keys, chips, icon wells: pressed in, so darker than `bg` and `surface` |
| `hairline` | `#D3D0C8` | 1px dividers, outlines, pressed keys |
| `ink` | `#161615` | Text, selected states, the edge around marigold |
| `ink2` | `#62615C` | Secondary text |
| `signal` | `#FFB020` | **Today + act only.** Always sits on `ink`, or carries `ink` text |

**Dark**

| Token | Hex |
|---|---|
| `bg` | `#121211` |
| `surface` | `#1C1C1A` |
| `sunk` | `#262624` |
| `hairline` | `#2C2C29` |
| `ink` | `#F2F1EC` |
| `ink2` | `#9C9B95` |
| `signal` | `#FFB020` (same hue) |

Inside the hero display card, these extra tokens apply:

| Token | Light | Dark |
|---|---|---|
| `display` | `#FFFEFB` (= `surface`) | `#1C1C1A` |
| `displayInk` | `#161615` | `#F2F1EC` |
| `displayInk2` | `#62615C` | `#9C9B95` |
| `blockIdle` | `#D3D0C8` (1.53:1 on `display`) | `#3A3A37` |
| `displayEdge` | `#161615`: 1.5px edge on today's block while it shows marigold | transparent (none) |

**Contrast (verified):**

| Pair | Light | Dark |
|---|---|---|
| `ink` on `bg` | 15.3 | 16.6 |
| `ink2` on `bg` | 5.25 | 6.73 |
| `ink2` on `sunk` | 4.75 | 5.44 |
| `ink` text on `signal` | 9.90 | — |
| `displayInk2` on `display` | 6.15 | 6.73 |
| `signal` on `display` | — (never bare: `displayEdge` is 17.95 on `display`, 9.90 on `signal`) | 10.25 |

- Marigold on the light `bg` is only 1.55:1, so **marigold never sits bare on the light background**. It always appears on ink or has an ink outline or ink label.
- **Cold-proofing:** every neutral has a slight warm tint, the motion is playful and the corners are soft (Nothing's hardware team calls this "softer and friendlier").

### 3.3 States with one colour
| State | Today's block | Words + glyph |
|---|---|---|
| On track | Solid marigold, draining from the top as you spend | "Lasts till payday · about ₹9,300 spare" with a check glyph |
| Slow down (< 25% of today left, or the forecast falls short of payday) | Marigold **outline** with a thin marigold sliver | "Slow down · at this pace it runs out 22 Nov" with an alert glyph |
| Over today | Empty block with a diagonal hatch in `displayInk2`; **tomorrow's block is visibly shorter** | "₹220 over today · each day after ₹1,776" |
| Over for the cycle | All blocks empty and outlined | "Over by ₹1,200 · payday in 4 days" + "See where it went" |

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
  - Continuous squircle corners (`figma_squircle`, smoothing 0.6).
  - Radius scale: 8 (day blocks) · 12 (chips) · 16 (keys) · 22 (tiles) · 28 (cards, hero) · 36 (tray).
- **Depth:**
  - Surfaces are layered by colour, not shadow (D45).
  - **Light theme alternates**, like IBM Carbon's light themes and Apple's grouped backgrounds: the page is grey (`bg`), a card on it is near-white (`surface`, 1.17:1), and keys or wells inside it step back to grey (`sunk`, 1.30:1 on `surface`). A higher layer is never darker than the one below it (unlike Material 3's light tonal surfaces).
  - **Dark theme steps lighter** with each layer (`bg` → `surface` → `sunk`), like Carbon's dark themes and Atlassian's elevation.
  - The hero display card is part of this: in light theme it is the near-white `surface` layer, its future days are grey blocks inside it, and today's marigold block carries a 1.5px ink edge, like the Add key. In *slow down* the marigold ring sits inside that edge.
  - Cards have no border; the fill gap carries the edge. Only the floating dock keeps a hairline. Never nest a card inside a card: within a card, rows are split by hairlines.
  - The marigold key has a **2px ink lip** that collapses when pressed, a nod to Braun's physical keys.
  - Trays sit over a 32% `ink` scrim.
  - There is no glass and no blur on content. Apple's Liquid Glass guidance puts glass only on navigation.
- **Icons:**
  - Hugeicons stroke-rounded only, size 24, `strokeWidth` 1.6, in `ink`.
  - The free set has no ⌫, so the keypad's delete key uses a glyph drawn in Hugeicons' format (`HisaabGlyphs.backspace`): `Keyboard`'s body height and squircle corners, a tip rounded like `Tag01`, and `CancelSquare`'s inner × (D48). A plain × would read as "close the tray" and ← as "back", which the app already uses for navigation.
  - Category icons sit in `sunk` wells and are **monochrome**. Categories are told apart by icon, word and fixed position, not colour.
  - Every icon has a label.
  - **Header icon buttons** (Home's Settings, the tray's Back): a 40dp `sunk` well with 12 corners inside the 48dp tap target, set flush with the outer edge so the well lines up with the cards or tiles (D57). A full 48dp well outweighed the wordmark.

### 3.6 App icon
The wordmark shrunk to its first letter and its dot: **h•**. The ET66 has one yellow key; the icon has one yellow dot.

- **Mark:** Anek Latin "h" at weight 700, `wdth` 85 (the hero amount's face), in `displayInk` `#F2F1EC` on an `ink` `#161615` field. The marigold dot sits on the baseline, 220 font units after the h.
- **Dot size:** 0.50 × x-height. The wordmark's dot is 0.63 × x-height, but at that size the icon reads as "ho"; 0.50 reads as "h." down to 36px.
- **Grid:** 108dp adaptive canvas; the drawn mark (44dp tall, 50dp wide) is scaled to 0.88 (about 39 × 44dp), in line with other launcher glyphs, and **optically centred**: it sits 4dp right and 2.5dp up from box-centre, because the heavy h and the small trailing dot otherwise read 6.7dp left and 4.5dp low (D55). Its farthest point is 28.3dp from centre, inside the 66dp safe zone, so every launcher mask (circle, squircle, rounded square) keeps it whole. The transform is one `<group>` / `<g>`, so the glyph's path data stays as generated.
- **Themed icon (Android 13+):** the same geometry as a monochrome layer; the dot survives as a dot.
- **Never:** a marigold field, an outline-only h, a gradient, a shadow, or the dot moved off the baseline.
- **Sources:** `docs/design/brand/` holds the master SVGs, the 512px Play Store PNG and the 1024×500 Play feature graphic (the wordmark, "Know what you can spend today." and the Home hero card with the SPEC worked-example numbers, on ink). The Android resources (`mipmap-anydpi-v26/ic_launcher.xml`, `drawable/ic_launcher_foreground.xml`, `drawable/ic_launcher_monochrome.xml`, legacy `mipmap-*/ic_launcher.png`) are generated from the same geometry.
- **Rejected:** a row of day blocks (reads as a battery or signal meter, a cliché §12 already rejects); the marigold Add key with a "+" (generic); an h whose leg is today's block (reads as a broken glyph).

### 3.7 Launch splash
The native Android splash, shown before Flutter draws (D41). Preview: `docs/design/mockups/09-splash.html` (`?t=<ms>` freezes a frame).

- **Story, "Aaj":** today and tomorrow arrive as day blocks. Today lands with weight and fills marigold from the baseline. Tomorrow steps back. Today rounds into the dot, the full stop of the h•.
- **One colour from tap to Home (D42):** the splash background, the icon background and Home's background are the same, so no circle is drawn.

  | | Light | Dark |
  |---|---|---|
  | Background | `bg` `#EEECE6` | `bg` `#121211` |
  | h | `ink` `#161615` | `#F2F1EC` |
  | Today's dot | `signal` with a 1-unit `ink` outline (like the wordmark) | `signal`, no outline |
  | Day blocks | `line` `#D3D0C8` | hero `track` `#3A3A37` |

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

---

## 5. Screens

### 5.1 Onboarding: 3 questions
1. **"How much money comes in each month?"**
   - The keypad is open from the start.
   - A live preview underneath turns the amount into blocks: "That's about **₹1,500 a day**", and the day blocks appear one by one as you type. This is the rare, bold delight moment.
2. **"When does it come?"** Big chips: *1st of the month* · *Last day* · *Pick a date* · *Every week* · *It changes*.
3. **"Any fixed bills?"** Chips for Rent · EMI · Phone · Internet · School fees · Subscriptions, plus a big **Skip**.
4. **Done.** The hero card assembles: blocks slide in, today's block lights up marigold, and `successNotification` fires.

### 5.2 Home
```
 hisaab•                Mon, 26 Oct   [⚙]
 ┌────────────────────────────────────────┐   "display" card
 │ Safe to spend today                    │
 │ ₹1,430                                 │   Anek 76 · wdth 85
 │ ▇ ▆ ▆ ▆ ▆ ▆ ▆ ▆ ▆              ⚑ 4 Nov │   today = marigold, 8 more days
 │ ✓ Lasts till payday · about ₹9,300 spare│
 └────────────────────────────────────────┘
 ⓘ Electricity ₹1,200 goes out in 3 days
 Today                         ₹420  See all
   [🍴] Food     Chai & samosa          ₹60
   [🚌] Travel   Auto to office        ₹120
   [🛍] Shopping DMart                 ₹240
        Home      [ + Add ]      Spends
```
(The glyphs above stand in for Hugeicons in this sketch.)

- **Hierarchy:**
  1. The hero number.
  2. Today's glowing block.
  3. The range line.
  4. The Today list.
- **Day blocks:**
  - One block per day from today to payday.
  - Width is shared equally, with a minimum of 6dp. The gap is 6dp for 16 days or fewer, and 3dp above that.
  - Height is 40dp. Today is first, on the left.
  - A flag with the payday date closes the row.
- **Tap the hero** to flip between *Today* and *This week*. Monzo users found a daily figure meaningless when they don't spend every day.
- **When you underspend:** the next morning the blocks grow, the number rolls up, and a one-line note appears: "You saved ₹300 yesterday, so every day got ₹35 more."
- **Empty Today:** "Nothing spent today. Tap Add when you do."

### 5.3 Add: one tray, two steps
**Step 1 · Amount**
- [Spent | Got] segmented control, defaulting to Spent. In light theme the selected segment is a near-white `surface` pill with bold `ink` text, raised out of the `sunk` track; in dark it is an `ink` pill. It is never marigold: it is a mode, not an action, and Next is the tray's only marigold (D47).
- Amount in Anek 60 with live lakh grouping.
- Quick chips **+₹10 +₹20 +₹50 +₹100 +₹500** that *add* to the amount, like counting notes.
- Phone-layout keypad (1-2-3 on top, as on the UPI PIN pad):
  - Keys 64dp tall, in `sunk`.
  - Bottom row: `00 · 0 · ⌫`. Long-press ⌫ to clear.
  - **No decimal key.** Studies of low-literacy users found decimal and numeric entry caused about half of all errors.
- The **Next** key is the marigold key, like the ET66's "=".

**Step 2 · What was it for?**
- The tray gets shorter.
- The amount flies up into the title.
- A **2×4 grid of monochrome tiles** (96dp, never scrolls, never reorders).
- Chips: *Today ▾* · *Add a note*.
- **Tapping a tile saves:**
  1. The tile flashes to ink (120ms).
  2. The tray drops.
  3. On Home, today's block drains to its new level.
  4. The number rolls.
  5. Haptic: `successNotification`.
- Tap path: Add → digits → Next → tile.

### 5.4 Spends
- **Header:** `‹ October ›`.
- **Ask AI card (top):**
  - A near-white card with no border, like every card, and a marigold well with an ink edge, since the AI handoff is an act (D66).
  - Shown only when the cycle has spends (DECISIONS D61).
  - Text: "Ask AI about October — get a second opinion in one tap."
- **Pace chart:**
  - A solid `ink` line for your spending and a dotted `ink2` line for steady pace.
  - The y-axis is fixed and labelled (₹0 / ₹20K / ₹40K), avoiding Apple Card's rescaling problem.
  - A verdict word: "Below pace" or "Above pace".
- **Where it went:**
  - Rows sorted by amount: icon well, name, %, ₹, and an `ink` bar on a `sunk` track. Bars, not donuts: people judge length more accurately than angle.
  - If a category has a limit, the bar shows a limit tick. Overspend shows as a hatched segment past the tick, not as red.
- **Insights:** at most 3 plain sentences, each with a next step, for example "Food is up ₹1,900 from September, mostly weekend orders. [Set a Food limit]".

### 5.5 Ask AI
Two layers only: the grey page and near-white cards, the same build as the Today list (D45, D67).
1. **Header:** Back and "Ask AI". It is fixed and doesn't scroll.
2. **"What do you want to know?" card:**
   - The goals as one column of rows: *Review my month* · *Help me save* · *Make me a budget* · *Am I on track?*. Each row has an icon in a 42dp `sunk` well, and hairlines are indented to the text (74dp), as on Home.
   - The last row is *Ask my own question*: an always-visible field with a pen icon. Tapping or typing in it picks it.
   - The pick: an `ink` check at the row's end and a bold label. No fill, no marigold (Apple HIG option lists).
   - The period: *This month* (default) · *Last 3 months*, as one segmented control in the Spent | Got style, with no check.
3. **Preview card:** "What will be sent · 142 entries" with *Show full text*, and below a hairline the **Hide my notes** switch.
4. **Actions, pinned to the bottom:** the marigold **Copy & open ChatGPT** key, then *Other AI* (share sheet) · *Copy only*. While an own question is blank, all three are grey and disabled (D65). Only the cards between the header and the actions scroll.
5. When the user must paste, a toast: "Copied. Paste it in the chat." That is after *Copy only*, and after *Copy & open ChatGPT* when ChatGPT can't be prefilled (D62).
6. With two panes or a tabletop fold, the header and the choices card sit in one pane, and the preview with the pinned actions in the other.

### 5.6 Settings (one level)
- **Money:**
  - Salary and payday
  - Fixed bills: one card of rows (name, "Every month on day 29", amount), soonest first, with *Add a bill* above it. Tap a row to change it; swipe it away with Undo. Adding or changing asks one question per screen, like onboarding: the name (a field plus the onboarding bill chips), the amount on the keypad, then a 1–31 day grid where tapping a day saves.
  - Keep aside each month
  - My month starts on: *Payday* (default) / *1st*
- **Categories:** rename, change icon.
- **Look:** Light / Dark / Match phone (default).
- **Data:** Backup · Restore · Export CSV.
- **About.**

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
| `standard` | 0.35s · 1.0 | 322 | Tray height change, tabs, block drain, list insert |
| `flick` | 0.40s · 0.8 | 247 | Tray thrown open or closed **by gesture only** |
| `calm` | 0.55s · 1.0 | 130 | Onboarding blocks assembling, the morning "blocks grow" |

- **Press feedback:** scale 0.97 plus the ink lip collapsing (2px → 0).
- **Number roll:** digits roll with tabular figures over 300ms using `Cubic(0.23, 1, 0.32, 1)`.
- **Block drain:** today's fill animates with `standard`. Rubber-band on over-drag, never a hard stop.
- **Delight scales inversely with frequency:**

  | Frequency | Treatment |
  |---|---|
  | Every key press | Tick haptic and press scale only |
  | Every save | Block drain plus number roll |
  | Daily | Blocks re-flow at midnight |
  | Monthly | Cycle summary: "You kept ₹4,300", with a share card |

- **Reduced motion:** all of the above become a 150ms crossfade, and charts never animate.
- **Launch splash (§3.7):** an animated vector drawable cannot use springs, so it uses `pathInterpolator` curves. The settle and the morph use the number-roll curve. Its squash overshoot is a deliberate exception to "no overshoot": a landing block carries momentum (D44).

## 7. Haptics (Flutter 3.47, verified)

| Event | Flutter | Android constant |
|---|---|---|
| Keypad, chip, tile highlight | `selectionClick()` | CLOCK_TICK |
| Save, onboarding done | `successNotification()` | CONFIRM |
| Invalid amount (more than 9 digits) | `errorNotification()` | REJECT |
| Swipe-to-delete threshold | `lightImpact()` | VIRTUAL_KEY |

One effect per event, never buzzy.

## 8. Voice
- Plain and kind, with "a pinch of humour, not a dollop" (Monzo).
- Never use: transaction, debit/credit, budget period, Oops, "You overspent!".
- **Amounts:**
  - Indian grouping (`₹1,25,000`), and on charts `₹1.25L` / `₹1.25Cr` from `NumberFormat` with `en_IN`.
  - Never show paise, so precision is the same everywhere.

## 9. Accessibility
- Touch targets ≥ 48dp; keys and tiles are 64–96dp.
- AA contrast on every text pair (verified above).
- State is shown by fill, outline, hatch **and** words.
- TalkBack reads, for example: "Safe to spend today: 1,430 rupees. 9 days to payday. Lasts till payday with about 9,300 rupees spare."
- Text scales to 1.5× with no clipping. Every colour has an increased-contrast variant (HIG).

## 10. Android
- All orientations and window sizes; never locked (§13).
- Edge-to-edge (API 36). The dock sits above `MediaQuery.paddingOf(context).bottom`.
- Predictive back: `PredictiveBackPageTransitionsBuilder` and `PopScope`. A back swipe scales the tray down.
- Launch splash (§3.7):
  - It is native: the Android 12+ `SplashScreen` API, and a static icon below that.
  - It is one colour from tap to Home in each mode.
  - It follows the phone's dark mode. When the in-app look setting (FR-SE-3) is built, it must also call `UiModeManager.setApplicationNightMode()` (API 31+) so the splash follows the app's choice.
- Later quick-add options:
  - App shortcut.
  - Home-screen widget showing the hero card in miniature (`home_widget`).
  - Quick Settings tile using `startActivityAndCollapse(PendingIntent)`.

## 11. Flutter implementation notes
- `core/design/hisaab_colors.dart`: `ThemeExtension<HisaabColors>` with light and dark instances, including the `display*` tokens. A test fails the build if any token pair drops below WCAG AA.
- `core/design/hisaab_type.dart`: Anek Latin (with `FontVariation('wdth', 85)` on amounts) and Mukta; `FontFeature.tabularFigures()` on all amounts.
- `core/design/hisaab_motion.dart`: the four spring tokens and `reduceMotion(context)`.
- `core/layout/`: `AppLayout.resolve` and `AppLayoutScope` (§13).
- `core/design/haptics.dart`: `Haptics.tick()`, `.success()`, `.reject()`, `.threshold()`.
- `core/widgets/`:
  - `DayBlocks` (`CustomPainter`: N blocks, today fill level, state, payday flag)
  - `HeroDisplay`
  - `SignalKey` (marigold with ink lip)
  - `Keypad`
  - `AmountText` (rolling digits)
  - `CategoryTile`
  - `Tray`
  - `RangeLine`
- Packages: `figma_squircle`, `animations`, `fl_chart` (styled to these tokens). Fonts go in `assets/fonts/`.

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
| A horizontal fold, half-opened (tabletop posture) | — | **Content above the fold, controls below it**: the dock below; onboarding's keypad below; the Add tray keeps to the lower half with the amount beside the keypad, so the hero stays readable above (Flutter sheets never straddle a fold) |
| Height under 480dp (phone landscape, small multi-window) | compact height | Denser layouts: keypad beside the amount, 48dp keys |

**One widget places question and keypad:** `AdaptiveSplit` (`lib/core/widgets/`) puts a screen's header and controls in the right place for every row above.

**Rules:**
- **Use the window, never the screen.** Sizes come from `MediaQuery.sizeOf`, which is the app window in split-screen or freeform mode.
- **Nothing straddles a fold or hinge.** Display-feature bounds come from `MediaQuery.displayFeaturesOf`. Cutouts never split the layout; they are handled by safe areas.
- **Panes keep clear of system bars only on the window edges they touch,** so the right pane doesn't get left padding for a left-side cutout.
- **Text scale:** layouts are tested at 2× on a 320dp phone. Controls grow (minimum heights, never fixed), and dock labels scale down instead of overflowing.
- **Readable width:** body content never exceeds 560dp in a single pane.
- **Tests** cover phone, phone landscape, unfolded foldable, tablet, book posture with a fold, a hinge with a gap, tabletop, split-screen, 2× text and dark theme (`test/core/layout/`, `test/app/app_shell_test.dart`). New screens add their own size cases through `test/helpers/pump_app.dart` (`TestWindows`).
