# UI / UX Design Spec: Hisaab

**Name:** Hisaab (हिसाब, "keeping account").
**Direction:** calm monochrome plus one signal colour.
**Mascot:** none; the concept uses no characters.

Every decision below traces to research (§12). Colours, fonts and formatting were checked on 2026-10-26.

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

The range line underneath borrows from electric cars. EV drivers trust a range display that says where you will arrive and with how much left. Hisaab writes "Lasts till payday · ₹900 spare", payday being the destination. It is labelled as a forecast and smoothed, so it never jitters.

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
- Hisaab borrows the same idea: a warm off-white "body", ink "display" and "keys", and **one marigold key**. That key is the Add button, the keypad's Next key and today's block.
- Marigold (genda) also reads as Indian and festive, and no money app owns it. Wise uses lime, Robinhood chartreuse, Cash App green, CRED a neon yellow-green, and Mercury indigo.

### 3.2 Tokens

**Light**

| Token | Hex | Use |
|---|---|---|
| `bg` | `#F6F5F1` | App background (warm off-white, never `#FFF`) |
| `surface` | `#FCFBF8` | Cards, sheets, dock |
| `sunk` | `#ECEAE4` | Keys, chips, icon wells |
| `hairline` | `#DAD8D1` | 1px dividers, outlines |
| `ink` | `#161615` | Text, the hero "display" card, selected states |
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

Inside the hero display card (both themes), these extra tokens apply:

| Token | Hex |
|---|---|
| `display` | `#161615` (light theme) / `#1C1C1A` (dark theme) |
| `displayInk` | `#F2F1EC` |
| `displayInk2` | `#9C9B95` |
| `blockIdle` | `#3A3A37` |

**Contrast (verified):**

| Pair | Light | Dark |
|---|---|---|
| `ink` on `bg` | 16.6 | 16.6 |
| `ink2` on `bg` | 5.69 | 6.73 |
| `ink2` on `sunk` | 5.16 | 5.44 |
| `ink` text on `signal` | 9.90 | — |
| `signal` on `display` | 10.25 | — |

- Marigold on the light `bg` is only 1.68:1, so **marigold never sits bare on the light background**. It always appears on ink or has an ink outline or ink label.
- **Cold-proofing:** every neutral has a slight warm tint, the motion is playful and the corners are soft (Nothing's hardware team calls this "softer and friendlier").

### 3.3 States with one colour
| State | Today's block | Words + glyph |
|---|---|---|
| On track | Solid marigold, draining from the top as you spend | "Lasts till payday · ₹900 spare" with a check glyph |
| Slow down (< 25% of today left, or the forecast falls short of payday) | Marigold **outline** with a thin marigold sliver | "Slow down · at this pace it runs out 22 Nov" with an alert glyph |
| Over today | Empty block with a diagonal hatch in `displayInk2`; **tomorrow's block is visibly shorter** | "₹220 over today · tomorrow ₹1,610" |
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
| Caption | Mukta | 13/18 | 500, `ink2` |

Hindi later uses **Anek Devanagari** with the same metrics, so no layout changes are needed.

Rules: no all-caps eyebrow labels, and no semibold body text. Supports text scaling to 1.5×, with the hero stepping down 76 → 56 → 44.

### 3.5 Shape, depth, icons
- **Corners:**
  - Continuous squircle corners (`figma_squircle`, smoothing 0.6).
  - Radius scale: 8 (day blocks) · 12 (chips) · 16 (keys) · 22 (tiles) · 28 (cards, hero) · 36 (tray).
- **Depth:**
  - Surfaces are layered by colour, not shadow.
  - The marigold key has a **2px ink lip** that collapses when pressed, a nod to Braun's physical keys.
  - Trays sit over a 32% `ink` scrim.
  - There is no glass and no blur on content. Apple's Liquid Glass guidance puts glass only on navigation.
- **Icons:**
  - Hugeicons stroke-rounded only, size 24, `strokeWidth` 1.6, in `ink`.
  - Category icons sit in `sunk` wells and are **monochrome**. Categories are told apart by icon, word and fixed position, not colour.
  - Every icon has a label.

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
 hisaab•                Sat, 26 Oct   [⚙]
 ┌────────────────────────────────────────┐   ink "display" card
 │ Safe to spend today                    │
 │ ₹1,850                                 │   Anek 76 · wdth 85
 │ ▇ ▆ ▆ ▆ ▆ ▆ ▆ ▆ ▆              ⚑ 4 Nov │   today = marigold, 8 more days
 │ ✓ Lasts till payday · ₹900 spare        │
 └────────────────────────────────────────┘
 ⓘ Rent ₹15,000 goes out in 3 days
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
- **Long-press a block** to see that day's share.
- **When you underspend:** the next morning the blocks grow, the number rolls up, and a one-line note appears: "You saved ₹300 yesterday, so every day got ₹35 more."
- **Empty Today:** "Nothing spent today. Tap Add when you do."

### 5.3 Add: one tray, two steps
**Step 1 · Amount**
- [Spent | Got] segmented control, defaulting to Spent.
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
  - Ink outline card with a marigold well, since the AI handoff is an act.
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
1. Goal cards (2×2): *Review my month* · *Help me save* · *Make me a budget* · *Am I on track?*, plus a full-width *Ask my own question*. The selected card is ink-filled.
2. Period chips: *This month* (default) · *Last 3 months*.
3. Preview card showing "What will be sent · 142 entries", with *Show full text*.
4. Switch: **Hide my notes**.
5. Primary marigold key **Copy & open ChatGPT**. Secondary: *Other AI* (share sheet) · *Copy only*.
6. After copying, a toast: "Copied. Paste it in the chat."

### 5.6 Settings (one level)
- **Money:**
  - Salary and payday
  - Fixed bills
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
- TalkBack reads, for example: "Safe to spend today: 1,850 rupees. 9 days to payday. Lasts till payday with 900 rupees spare."
- Text scales to 1.5× with no clipping. Every colour has an increased-contrast variant (HIG).

## 10. Android
- Edge-to-edge (API 36). The dock sits above `MediaQuery.paddingOf(context).bottom`.
- Predictive back: `PredictiveBackPageTransitionsBuilder` and `PopScope`. A back swipe scales the tray down.
- Later quick-add options:
  - App shortcut.
  - Home-screen widget showing the hero card in miniature (`home_widget`).
  - Quick Settings tile using `startActivityAndCollapse(PendingIntent)`.

## 11. Flutter implementation notes
- `core/design/tokens.dart`: `ThemeExtension<HisaabColors>` with light and dark instances, including the `display*` tokens.
- `core/design/type.dart`: Anek Latin (with `FontVariation('wdth', 85)` on amounts) and Mukta; `FontFeature.tabularFigures()` on all amounts.
- `core/design/motion.dart`: the four spring tokens and `reduceMotion(context)`.
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
