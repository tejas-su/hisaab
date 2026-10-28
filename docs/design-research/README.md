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
