# 10. The hero card: emphasis, material and proportion

## Job of the screen
The Home hero answers the app's one question, *how much can I safely spend today?* It is hierarchy item 1 (UI_DESIGN §5.2) and the first thing the eye should land on. It holds the amount, the Day Blocks with the payday flag, and the range line.

## What's wrong
The owner finds the hero dull: it doesn't read as *the* thing on Home. Measured causes:
- **It is the same object as every other card.** Since D46 the light hero is `surface` `#FFFEFB` on `bg` `#EEECE6`, 1.17:1, the same layer, radius and edge as the due-soon note and the Today list. Only the number's size marks it as the hero.
- **Nothing on it is a material.** It is a flat white rectangle. A payment card, the object people already treat as "my money", always has a finish: metal, a print pattern, an etch.
- **Its colour point is small.** The marigold today block is about 30 × 40dp, and on light it needs an ink edge (marigold on `surface` is 1.81:1).

The owner also asked whether a 4:5 portrait card, like a portrait photo, would suit it better.

## Research

### Payment cards: emphasis without many colours
- **Apple Card** is the closest model for Hisaab: an off-white matte titanium card with only a laser-etched name and logo, no numbers, a chip simplified to six rounded shapes ([iDrop News](https://www.idropnews.com/news/mineralogist-finds-apple-cards-atomic-makeup-isnt-100-titanium/116221), [Azure](https://www.azuremagazine.com/?p=96769), [AppleInsider](https://appleinsider.com/articles/19/09/03/unsurprisingly-the-apple-card-isnt-100-titanium)). It reads as premium through **material and restraint**, not colour. Its digital card in Wallet shifts colour by spending category and returns to white as the balance is paid ([creditcards.com](https://creditcards.com/card-advice/apple-card-colors), [Built for Mars](https://builtformars.com/company/apple-card), [D&AD](https://www.dandad.org/work/d-ad-awards-archive/apple-card)). No official mapping is published.
- **OneCard** (India) sells a 16 g metal card in a "double black" finish, laser-engraved details, and a minimal layout; weight and finish carry the status ([OneCard](https://www.getonecard.app/blog/onecard-metal-credit-card/)).
- **Monzo's hot coral** card was a quick pick that became the brand because it was instantly recognisable in a wallet of dark cards; its CDO lists it among things Monzo will always keep ([uxdesign.cc](https://uxdesign.cc/is-hot-coral-a-feature-or-a-liability-a-closer-look-at-the-colour-of-your-bank-card-fbd2f987d359), [It's Nice That](https://www.itsnicethat.com/features/in-house-monzo-vuokko-aro-coral-garvey-creative-industry-020926)). The lesson is **one owned colour, used big, once**. Hisaab owns marigold, but D8–D10 reserve it for *today / act*, so it can't become the card's fill.
- **CRED NeoPOP** gets drama from hard shadows, isometric depth, linear motion and rigid corners ([Analytics India](https://analyticsindiamag.com/cred-open-sources-its-ui-design-system-neopop/), [UX Planet](https://uxplanet.org/thoughts-on-creds-ui-revamp-apr-2022-6d2b4dcfcfc6)). It suits a rewards app aimed at affluent users; it clashes with Hisaab's calm, fill-only, squircle language.
- **Security printing.** Card and banknote backgrounds use guilloché, fine interlaced line rosettes. Indian rupee notes carry them too, so the pattern reads as "money" here without any colour.

### Proportion
- A payment card is ID-1, 85.60 × 53.98 mm, **1.586:1 landscape**, near but not equal to the golden ratio ([ISO/IEC 7810](https://en.wikipedia.org/wiki/ISO/IEC_7810)).
- **Vertical cards** exist for a physical reason: people hold a card upright to tap or dip it, and phones are upright. Mastercard: "a portrait orientation [is] easier to tap"; Venmo tied its vertical card to TikTok and Instagram's portrait layout ([BNN Bloomberg](https://www.bnnbloomberg.ca/credit-cards-are-turning-vertical-with-tap-to-pay-taking-off-1.1562427), [American Banker](https://americanbanker.com/payments/news/banks-design-vertical-credit-cards-for-customers-with-disabilities), [CBC](https://amp.cbc.ca/news/business/credit-cards-future-1.6261182)).
- **4:5** is Instagram's tallest feed post. It wins because a *photo* takes more of a scrolling feed; claims that it raises engagement come from marketing blogs with no data ([socialsizes.io](https://socialsizes.io/instagram-post-size/)). The hero is not a photo in a feed: it is a readout at the top of a screen whose content below (the Today list) is the second thing users need.

### Texture and motion
- A faint noise layer breaks gradient banding and is what makes dark "premium" cards look tactile; keep it at about 0.2 opacity or below, finer behind text ([instantgradient](https://instantgradient.com/blog/grainy-gradients), [cssmatic](https://cssmatic.com/gen-noise-texture.html)). No source measures the "premium" effect; it is convention.
- A holographic or metal sheen is a diagonal light band whose position follows tilt, from the game rotation vector sensor ([ProAndroidDev](https://proandroiddev.com/how-a-holographic-foil-effect-works-in-jetpack-compose-9535d621c055)). Flutter packages do it ([holographic_card_flutter](https://pub.dev/documentation/holographic_card_flutter/latest/), [spatial_card](https://pub.dev/packages/spatial_card)), but sensor tilt needs a new dependency (`sensors_plus`), runs the sensor while Home is open, and is a continuous effect.

## Measured: the current hero
From a throwaway widget test of `HomePage` with the bundled fonts and the fake services' data, 1× text, light theme:

| Window | Hero (w × h dp) | Ratio | Today list starts at | At 4:5 the hero would be | Today list would start at |
|---|---|---|---|---|---|
| 412 × 915 (`TestWindows.phone`) | 372 × 261 | 1.43:1 | 435 | 372 × 465 (+204) | 639 |
| 360 × 780 | 320 × 261 | 1.23:1 | 435 | 320 × 400 (+139) | 574 |
| 320 × 568 (`TestWindows.smallPhone`) | 280 × 281 | 1.00:1 | 475 | 280 × 350 (+69) | 544, under the 76dp dock |

On the reference phone the hero is already a landscape card, 1.43:1, close to a payment card's 1.586:1.

## Patterns compared
Mockup: [13-hero-card-options.html](../../design/mockups/13-hero-card-options.html), light and dark, with a motion replay.

| Option | What changes | Keeps D8–D10 and D46? | Gain | Cost |
|---|---|---|---|---|
| A · Today | Nothing | Yes | — | Dull: same object as every card |
| **B · Etched paper** | The only raised card on Home (a soft shadow), a guilloché etch in `hairline` behind the top-right, faint grain, one light sheen when today's block fills | Yes | Reads as a card and as "money" with no new colour; marigold stays the only hue | Subtle: a shadow is new to the app (cards have no edge or elevation today), so it needs a token and an elevation rule |
| C · Charcoal card | Hero fill becomes `inverse` `#2F2E2B` (11.49:1 on the page), with etch and grain | **No**, reopens D46 | The strongest figure-ground on Home; marigold sits bare at 7.42:1, so today's block glows like a card's chip | D46 removed a dark hero as a "black slab". Charcoal at `L` 0.30 is lighter than the `ink` slab D46 rejected, and D105 already uses it for the snackbar. New tokens: captions `#B0AFA9` (6.18:1), idle blocks `#4F4E4A` (1.63:1) |
| Marigold-filled card (Monzo-style) | Hero fill is marigold | No (D8: marigold = today / act) | Very loud, ownable | Every day reads as "act now"; the today block has nothing left to stand out against. Rejected |
| Category colours (Apple Card digital) | Card hue follows spending | No (D9, D10) | — | Rejected by the no-category-colour rule |
| Tilt sheen (sensor) | Sheen follows the phone's tilt | Yes | Delight | New dependency, battery, a continuous effect on a calm screen. Not now |
| 4:5 portrait card | Fixed aspect ratio | Yes | Taller | See below. Rejected |

### Why not 4:5
1. **The extra height is empty.** The content (title, amount, blocks, captions, range line) has a natural height. A 4:5 box adds space and nothing to read, as the mockup shows.
2. **It pushes hierarchy item 4 down.** On the reference phone the Today list starts 204dp lower, at 639 of 915, about half its room above the dock gone. On `TestWindows.smallPhone` it starts at 544 of 568, under the dock: off the first screen.
3. **A fixed ratio fights adaptive layout.** At 1.5× text the content grows (the amount steps 76 → 56 → 44) and could overflow a fixed box; in landscape, on a foldable or a tablet, a 4:5 card in a wide pane is either huge or must be capped anyway. CLAUDE.md: never assume a portrait phone.
4. **The card reference doesn't point to 4:5.** A payment card is 1.586:1; it turned vertical only for tapping. The portrait trend is for media in feeds.

If "card-ness" is the aim, the proportion that carries it is the payment card's own, and the hero is already near it on the reference phone (1.43:1). A minimum height is not needed.

## Recommendation (B built 2026-10-29, D106)
1. **Build B now.** It stays inside every current rule and fixes the actual cause, that the hero is the same object as every other card:
   - **Elevation:** the hero is the only card with a shadow. Add an `elevationHero` token (a 1dp key line plus a soft 28dp blur at about 20% `ink`, light only; dark keeps its hairline). UI_DESIGN §3.5 says cards have no border; this adds "the hero alone is raised".
   - **Etch:** a guilloché rosette in `hairline`, clipped by the card, behind the top-right corner, never behind the amount's glyphs at full strength. Drawn once as a path in `HisaabGlyphs`-style code, cached (`RepaintBoundary`). It is decoration: excluded from semantics.
   - **Grain:** a tiled noise image at about 6–7% opacity. Optional; drop it if it shows on a low-end screen.
2. **Micro-motion, all one-shot and gated by `reduceMotion`:**
   - A single diagonal sheen across the card (about 1.1 s, `calm`) when today's block fills in on a new day (D91), the "card catching the light". Never on every rebuild, never looping.
   - Keep the number roll and the drain with its trail (D91).
   - When yesterday was underspent, the sheen runs with the blocks' growth (UI_DESIGN §5.2) as the one reward moment. No confetti (no nagging, no celebration of spending).
   - A press: the card scales to 0.98 on `snap` while the finger is down, then flips Today ⇄ This week, so the tap target feels like a physical card.
3. **Put C to the owner as a decision**, with the mockup, not as a build. It is the bigger change and the stronger hero, but it reverses D46. If chosen, add a `DECISIONS.md` row superseding D46 for the light hero only, and new `display*` values; the `display` aliases (D97) already let the hero change without touching other cards.
4. **Keep the hero's height content-driven.** No 4:5 and no fixed ratio.

## Risks
- **Etch legibility.** A pattern behind a 76sp amount can reduce reading for low-vision users. Keep it out of the amount's area or under 1.2:1 against `display`; check with the a11y tests and at 1.5× text.
- **Shadow vs fill-only language.** One raised card is a new rule; it must stay the only one, or elevation turns into noise.
- **Sheen fatigue.** Once a day is the limit. If users see it on every Home visit it becomes a loading effect.
- **Low-end GPUs.** A full-card blur shadow and a noise layer repaint with the drain animation; wrap the static layers in a `RepaintBoundary` and profile on a low-end device.
- **C contradicts the owner's earlier call.** Present it with D46's reasons beside it.

## As built (D106)
- `DisplayCard(raised: true, etched: true)` with `DisplayEtch` (`lib/core/widgets/`), `HeroSheen` and `HeroPress` (`lib/home/presentation/widgets/`); tokens `displayEtch`, `displayShadow`, `displaySheen`, `HisaabMotion.sheen`, `HisaabShapes.raised`.
- Two changes from the proposal: the press uses the app's `pressedScale` (0.97), not 0.98, so every press sinks the same; and the sheen plays whenever the hero appears, with the fill in (D91), which on a phone includes coming back from Spends. Limiting it to once a day needs state outside the widget; revisit if it starts to feel like a loading effect.

## More in B's family (proposed, in mockup 13)
Same rule as B (material and finish, no new colour, marigold the only hue); each can replace or join the guilloché:
- **D · Brushed metal:** fine horizontal hairlines, like Apple Card titanium or a steel tiffin. The quietest; the sheen reads best over it.
- **E · Embossed amount:** the amount pressed into the card, a 1px light lip under the digits and a faint vertical tone, like raised card numbers. Check it at 1.5× text and against the contrast floor.
- **F · Etched mark:** the h• wordmark etched large in the top end corner, as a card carries its issuer's mark. Brand, not pattern.
- **G · Note border:** an inner keyline in from the edge, like the frame printed round a rupee note. **Built (D107):** a solid line 6dp in and a dashed line 10dp in, as in the mockup, with a quieter divider and more vertical room.
