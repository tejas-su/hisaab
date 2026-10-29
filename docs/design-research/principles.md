# Design principles from research

Each principle cites its source and names where it applies in Hisaab. The newest go at the end of their section. When a principle conflicts with a Hisaab decision, `DECISIONS.md` wins until a new row changes it.

## Choosing one option

1. **Show a short list of options as visible rows, not a dropdown or a grid.** People can scan, compare and pick in one step. A grid of labels with different lengths wraps unevenly and loses its alignment. *Sources:* NN/g on dropdowns; Apple HIG, Lists and tables; case study 01. *Applies to:* Ask AI goals, onboarding questions, settings choices.
2. **Mark the pick with a checkmark at the row's end, not a filled block.** A fill is for navigation (the row you came from); a check is for an option. In Hisaab it's an ink check plus a bold label, never marigold, because a pick is a mode (D47). *Sources:* Apple HIG, Lists and tables. *Applies to:* any single-select list.
3. **Two to five short, related nouns go in a segmented control**, with equal-width segments and no introductory text. Hisaab has one segmented style, the Spent | Got switch. *Sources:* Apple HIG, Segmented controls. *Applies to:* periods, kind switches.
4. **Chips only for one- or two-word options in a single row.** Two rows of chips are hard to scan. *Sources:* Material Chips; Setproduct. *Applies to:* quick amounts, filters.
5. **Default single-select for goal questions.** It's about 3:1 across 80 apps. Label multi-select "Select all that apply". *Sources:* Lazyweb. *Applies to:* onboarding and Ask AI.

## Layout and layers

6. **Two layers for a choice: page, then rows.** Every extra box (card, then track, then pill) reads as nesting, not as one list. In Hisaab: grey `bg`, then near-white `surface` cards. Grey `sunk` only for wells and the segmented track (D45). *Sources:* Apple grouped lists; case study 01.
7. **Rows in one card share the Today list's geometry:** a 20dp inset, an icon in a grey well, and hairlines indented to where the text starts. Every option row in the app then lines up with Home. *Sources:* Hisaab Home; Apple inset separators.
8. **Keep the main action in thumb reach while the choices change.** Pin it to the bottom when the window is tall enough. *Sources:* Duolingo's Continue; Monzo onboarding. *Applies to:* Ask AI, onboarding, bill editor.

## AI entry points

9. **Offer 3–4 concrete starters tied to the user's data, never "Ask me anything".** Starters turn recalling a request into recognising one. *Sources:* AI UX Playground; UI Patterns, Suggested prompts. *Applies to:* Ask AI goals.
10. **Keep "type your own" visible next to the starters**, not behind an extra tap. Typing should pick it. *Sources:* Notion AI's "Describe your own"; AI UX Playground. *Applies to:* Ask AI's own question.
11. **Show exactly what will be sent before it leaves the phone.** Preview the first lines, with the full text one tap away. This is already Hisaab's rule (FR-AI-3, NFR-2). *Sources:* case study 01.

## Typography (case study 02)

12. **Size sets the level; weight sets emphasis within a level.** Big jumps (title vs body) come from size. Within one size, one weight step (Regular to Semibold) marks what matters. *Sources:* Apple HIG text styles; IBM Carbon; Fluent 2. *Applies to:* every screen.
13. **Two or three weights in UI text:** Regular, Semibold, and Bold for amounts. Nothing lighter than Regular at small sizes. *Sources:* Apple HIG ("avoid Ultralight, Thin, and Light"); Carbon; Refactoring UI.
14. **List row titles are body-weight; the picked or unread row gets the emphasized weight,** and the check or indicator carries the selection too. *Sources:* Apple HIG (Body vs Headline at 17pt); Material 3 emphasized styles. *Applies to:* goal rows, entry rows, bill rows.
15. **A heading at body size needs Semibold; a big heading can stay Regular** because its size already ranks it. *Sources:* Apple Headline; Carbon `heading-01` (600) vs `heading-03`+ (400).
16. **A card's header must not share its rows' style.** It differs by size or role. *Sources:* Atlassian ("hierarchy with heading styles, not bold or bigger body"); case study 02, finding A3.
17. **De-emphasise with colour, a lighter neutral that still passes 4.5:1, not with a light weight or a tiny size.** *Sources:* Fluent 2; Refactoring UI; Carbon (neutral running text).
18. **Emphasis is a named variant of a style, never a one-off `fontWeight` override.** *Sources:* Apple emphasized weights; Fluent Strong/Stronger; Primer ("don't use arbitrary weight number values").
19. **Sentence case, no all-caps for attention, few typefaces; keep the hierarchy when text scales.** *Sources:* Fluent 2; Apple HIG Dynamic Type.


## Motion (case study 05)

20. **Animate a change where it can be seen.** Hold the update until whatever covers it (tray, scrim) has gone, then move one focal point at a time. *Sources:* Material choreography; eBay motion playbook. *Applies to:* the drain after Add, list inserts.
21. **A gauge needs a visible empty part to read as a gauge.** Show it filling once, and make every change visible, even a small one. *Sources:* the blind read in case study 05; Apple's gauge guidance (§3.3). *Applies to:* Day Blocks.
22. **No bounce unless a finger threw it.** Springs start at damping 1. *Sources:* Apple WWDC18 *Designing Fluid Interfaces*, WWDC23 *Animate with springs*.
