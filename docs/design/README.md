# Design mockups

These are static HTML mockups of the v1 screens. Open any file in a browser; the links between screens work. The live, commentable canvas is at https://claude.ai/artifact/DHgbV79M7Vma977xLZk4ED (private to its owner unless shared).

The mockups illustrate [../UI_DESIGN.md](../UI_DESIGN.md). Every number in them follows the worked example in [../SPEC.md](../SPEC.md), so where a mockup and the spec disagree, the spec wins.

| File | Screen | Shows |
|---|---|---|
| [01-onboarding.html](mockups/01-onboarding.html) | Onboarding, step 1 | Salary turning into day blocks (FR-ON-2) |
| [02-home.html](mockups/02-home.html) | Home, light, on track | Hero ₹1,430, today's block 77% full, range line, due-soon nudge (FR-HO-2/3/4) |
| [03-add-amount.html](mockups/03-add-amount.html) | Add, step 1 | Keypad, quick chips, effect preview "₹1,020 over today's share · tomorrow ₹1,722" (FR-AD-1/3) |
| [04-add-category.html](mockups/04-add-category.html) | Add, step 2 | Monochrome tiles, press flash on Shopping (FR-AD-5) |
| [05-home-dark-over-today.html](mockups/05-home-dark-over-today.html) | Home, dark, over today | Hatched today block, shorter future blocks, ₹1,776 each day after (BR-5 #3, BR-6) |
| [06-spends.html](mockups/06-spends.html) | Spends | Pace chart, largest-remainder percentages, limit tick and hatched overspend (FR-SP-3/4, BR-12/13) |
| [07-ask-ai.html](mockups/07-ask-ai.html) | Ask AI | Goals, period, preview, Leave out my notes, Copy & open ChatGPT (FR-AI-1..4) |
| [08-design-system.html](mockups/08-design-system.html) | Design system | Tokens, the four Day Blocks states, type, keys, motion, haptics |
| [09-splash.html](mockups/09-splash.html) | Launch splash (Android 12+) | Animated, in light and dark side by side: launcher zoom, today and tomorrow arrive, today lights up and becomes the dot, exit into Home. `?t=420` opens paused on a frame (spec: `docs/superpowers/specs/2026-10-26-splash-screen-design.md`) |

[brand/](brand/) holds the app icon masters (UI_DESIGN §3.6): `hisaab-icon.svg` (full icon), `hisaab-icon-foreground.svg` and `hisaab-icon-monochrome.svg` (adaptive layers), `hisaab-play-store-512.png`, and the Play Store feature graphic `hisaab-play-feature-1024x500.png`.

**Worked example behind the numbers.** Income is ₹45,000, paid on the 4th, so the cycle runs Sun 4 Oct to Tue 3 Nov 2026. "Today" is Mon 26 Oct (9 days left). An electricity bill of ₹1,200 is due 29 Oct, and ₹27,150 was spent before today. That gives P = ₹16,650 and A = ₹1,850 a day. ₹420 has been spent today, so the hero shows ₹1,430. The dark mockup is Sat 31 Oct (4 days left) with ₹2,070 spent today.

**Fidelity notes**
- Icons are hand-drawn stand-ins. The app uses Hugeicons stroke-rounded (UI_DESIGN §3.5).
- Fonts load from Google Fonts here. The app bundles them.
- Motion, haptics and squircle corners aren't represented.
- Continuous (squircle) corners are approximated with `border-radius`.

When a screen changes, update the canvas, then re-export these files. The export strips the canvas runtime (`support.js`, `<x-dc>`, `<helmet>`) and rewrites links to these file names.
