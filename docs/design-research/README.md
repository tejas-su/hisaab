# Design research

UX/UI research for Hisaab: case studies of other apps, the principles we drew from them, and where to look. This folder records why a design was chosen. What was decided lives in `docs/DECISIONS.md`, and the resulting spec in `docs/UI_DESIGN.md`.

| File | What it holds |
|---|---|
| [principles.md](principles.md) | Design principles learned from research, each with its source and the Hisaab screens it applies to |
| [sources.md](sources.md) | Where to look (Apple HIG, Material, Mobbin, Dribbble, Pinterest, NN/g, pattern libraries), what each is good for, and access limits |
| [case-studies/](case-studies/) | One study per design question, numbered `NN-topic.md` |

## Case studies
| # | Topic | Outcome |
|---|---|---|
| 10 | [The hero card: emphasis, material and proportion](case-studies/10-hero-card.md) | Built: B, "etched paper" (D106): the only raised card, a guilloché etch, grain, a sheen as the hero appears, a press. Built too: a note border (D107). Proposed in the same family: brushed metal, embossed amount, etched mark. Not chosen: C, a charcoal hero (reopens D46). Rejected: a 4:5 card, a marigold fill, category colours, sensor tilt |
| 09 | [Colour in fintech: colour mass, category colours, a dark hero](case-studies/09-colour-in-fintech.md) | Proposed: colour mass from value, not hue (the dark end of the scale as the brand surface); a dark `inverse` hero in light, pending a blind read (reverses D46); keep the warm neutrals. Category colours: no-go for v1; at most 6 low-chroma tints, never red, green or marigold, if a 5-user search test shows a gain |
| 08 | [Colour retrospective and the grey ramp](case-studies/08-colour-retrospective.md) | Built: `inverse` token for the snackbar (D105). Approved: role-first, measured colour process. Proposed: fill the 0.86→0.46 `L` gap in the grey ramp (separate task) |
| 07 | [Design systems: Groww, Material 3, Primer, Radix, Atlassian, Blade](case-studies/07-design-systems-groww-material-primer-radix.md) | Proposed: set every Material role, one contrast-pair list for all themes, focus as its own token, tinted transparent token. Rejected: gain/loss colours, seed or dynamic colour, colour-blind themes |
| 06 | [Design systems: Vercel Geist, Apple HIG, IBM Carbon](case-studies/06-design-systems-vercel-apple-ibm.md) | Proposed: increased-contrast token set, ink focus ring with a gap, state as steps of one scale, deprecate before removing. Rejected: blue focus, glass, several themes per mode |
| 05 | [Day Block motion](case-studies/05-day-block-motion.md) | Drain after the tray closes, with a trail; fill in when Home appears; a fill cap of 0.9 once anything is spent (D91) |
| 04 | [Floating dock and pinned top bar](case-studies/04-floating-dock-and-top-bar.md) | Dock: a 32dp eased fade above a solid `bg` seat (D82), built. Top bar: solid with a hairline on scroll, no glass (D84) |
| 03 | [Suggestion pills](case-studies/03-suggestion-pills.md) | Bill name pills as two equal columns so both edges align; list rows if the set grows (D83); picked pill restyled and pills moved under the field (D85) |
| 02 | [Typography: weight, emphasis, hierarchy](case-studies/02-typography-hierarchy.md) | Applied app-wide (D68): Regular row titles with a Semibold pick, title-style card headers, Regular grey captions, a defined `titleSmall`, and every weight set through `HisaabType.emphasized`/`regular` |
| 01 | [Ask AI choice screen](case-studies/01-ask-ai-choice-screen.md) | Built (D67): grouped list rows with a trailing check, an inline own-question field, a segmented period control, a fixed header and pinned actions |

## Adding a study
1. Copy the structure of `case-studies/01-ask-ai-choice-screen.md`: the job of the screen, what's wrong, research by source, patterns compared, recommendation, risks.
2. Use the next free number. Never renumber.
3. Link every claim to its source. Say when a source couldn't be read (a login wall, or only board pages), rather than guessing what it shows.
4. Add any new, reusable principle to `principles.md` and any new site to `sources.md`.
5. When a recommendation is approved, add a `DECISIONS.md` row, update `UI_DESIGN.md`, and set the study's outcome above.
