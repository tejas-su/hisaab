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
| 02 | [Typography: weight, emphasis, hierarchy](case-studies/02-typography-hierarchy.md) | Approved (D68). Applied on Ask AI first: Regular rows with a Semibold pick, a title-style card header, a defined `titleSmall`, named `emphasized`/`regular` weights. Home, Spends and Settings to follow |
| 01 | [Ask AI choice screen](case-studies/01-ask-ai-choice-screen.md) | Built (D67): grouped list rows with a trailing check, an inline own-question field, a segmented period control, a fixed header and pinned actions |

## Adding a study
1. Copy the structure of `case-studies/01-ask-ai-choice-screen.md`: the job of the screen, what's wrong, research by source, patterns compared, recommendation, risks.
2. Use the next free number. Never renumber.
3. Link every claim to its source. Say when a source couldn't be read (a login wall, or only board pages), rather than guessing what it shows.
4. Add any new, reusable principle to `principles.md` and any new site to `sources.md`.
5. When a recommendation is approved, add a `DECISIONS.md` row, update `UI_DESIGN.md`, and set the study's outcome above.
