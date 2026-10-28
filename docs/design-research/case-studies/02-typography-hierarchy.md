# Typography: weight, emphasis and hierarchy

**Status:** research plus an audit of Hisaab's type scale. Nothing has changed in the code. If any recommendation is approved, it gets a `DECISIONS.md` row and a UI_DESIGN §3.4 update.

## 1. Question
How do the major design systems show hierarchy and emphasis with type: size, weight or colour? And does Hisaab's scale (`lib/core/design/hisaab_type.dart`, UI_DESIGN §3.4) follow them?

## 2. What each system says

### 2.1 Apple Human Interface Guidelines
- **Hierarchy comes from three dials:** "Adjust font weight, size, and color as needed to emphasize important information and help people visualize hierarchy," and keep that hierarchy when the text size changes ([Typography](https://developer.apple.com/design/human-interface-guidelines/typography)).
- **No light weights:** "Prefer Regular, Medium, Semibold, or Bold font weights, and avoid Ultralight, Thin, and Light font weights, which can be difficult to see, especially when text is small."
- **Few typefaces:** "Minimize the number of typefaces you use… Mixing too many… can obscure your information hierarchy."
- **Emphasis is a named variant of the same style.** Each text style has an "Emphasized weight", applied with the bold trait, "letting you create another level of hierarchy."
- **The iOS text styles at the default size** carry hierarchy mostly by size, at Regular weight:

  | Style | Weight | Size/leading (pt) | Emphasized |
  |---|---|---|---|
  | Large Title | Regular | 34/41 | Bold |
  | Title 1 / 2 / 3 | Regular | 28/34 · 22/28 · 20/25 | Bold · Bold · Semibold |
  | Headline | **Semibold** | 17/22 | Semibold |
  | Body | Regular | 17/22 | Semibold |
  | Callout · Subhead | Regular | 16/21 · 15/20 | Semibold |
  | Footnote · Caption 1 · Caption 2 | Regular | 13/18 · 12/16 · 11/13 | Semibold |

  Headline and Body are the **same size**: weight alone separates a row's title from its text. The minimum size on iOS is 11 pt and the default is 17 pt.
- WWDC20 *The details of UI typography* covers how size, tracking and leading work together across optical sizes ([session](https://developer.apple.com/videos/play/wwdc2020/10175/), [notes](https://wwdcnotes.com/notes/wwdc20/10175)).

### 2.2 Google Material 3
- **Five roles, each in three sizes:** Display, Headline, Title, Body and Label, in Large, Medium and Small. Weights are only 400 and 500 ([M3 type scale, via an M3 reference](https://github.com/hamen/material-3-skill/blob/master/skills/material-3/references/typography-and-shape.md), [Compose Material 3](https://developer.android.com/develop/ui/compose/designsystems/material3)).
  - **Regular (400):** Display, Headline, Title Large and Body.
  - **Medium (500):** Title Medium and Small, and every Label size. For example, Title Medium is 16/24 at 500 and Label Large is 14/20 at 500.
- **Usage:** Title is for "medium-emphasis, relatively short text"; Label is for text inside components, such as buttons.
- **Emphasized styles** mirror the baseline scale at a higher weight. They're for selected or active states, primary buttons and unread items. Published weight values conflict between sources, so check the official tokens before using a number ([search summary](https://medium.com/@vosarat1995/material-3-you-typography-cheatsheet-ffc58c540181)).

### 2.3 Microsoft Fluent 2
- **Every size has emphasis variants:** Body 1 is 14/20 Regular, *Strong* is Semibold and *Stronger* is Bold. Subtitles and titles are Semibold (Subtitle 1 at 20/26, Title 3 at 24/32, up to Display at 68/92) ([Fluent 2 typography](https://fluent2.microsoft.design/typography)).
- **Colour:** "Using a lighter neutral than standard text will subdue the text and place it lower in a visual hierarchy." Body text needs ≥ 4.5:1 contrast, and large text ≥ 3:1.
- Use sentence case; "Don't use all caps to get a user's attention."

### 2.4 IBM Carbon
- **Weight and size are balanced together:** "A bold weight will always have more emphasis than a lighter weight font of the same size," but a much larger lighter weight "can rank hierarchically higher than a bold font" ([Carbon typography](https://carbondesignsystem.com/elements/typography/overview/)).
- **Product type set** ([type sets](https://carbondesignsystem.com/elements/typography/type-sets/)):
  - Body and labels are 400.
  - Small component headings (`heading-01`, 14/20) are **600**, to stand out from body text of the same size.
  - Mid headings (20–32px) drop back to **400**, because size does the work.
  - The largest headings (42px and up) are 300.
  - SemiBold "should not be used for long text."
- Keep running text a neutral colour. Colour is for links, actions and alerts.

### 2.5 Atlassian
- **Headings are all Bold**, from 12 to 32px. Body is Regular at 12, 14 or 16px. Medium is "for alignment with iconography" in components. Bold is for "unique cases where text needs to be differentiated" ([Atlassian typography](https://atlassian.design/foundations/typography)).
- **Make hierarchy with heading styles, not with bold or bigger body text.** This matters for screen readers too.

### 2.6 GitHub Primer and others
- **Primer:** "Refrain from utilizing color as a primary method of emphasis." Use weight tokens, and "don't use arbitrary weight number values." Keep lines to about 80 characters or less ([Primer typography](https://primer.style/foundations/typography)).
- **Salesforce:** each text tier comes in Regular, Semibold and Bold ([Agentforce SDK typography](https://developer.salesforce.com/docs/ai/agentforce-mobile-sdk/references/agentforce-mobile-sdk/typography-and-fonts-ios.html)).
- **Refactoring UI** (book, through secondary summaries): use 400–500 for most text and 600–700 for emphasis, nothing under 400 in UI. **De-emphasise with colour (grey) rather than a smaller size or a lighter weight** ([Refactoring UI tips](https://medium.com/refactoring-ui/7-practical-tips-for-cheating-at-design-40c736799886)).
- **Not used:** Polaris didn't load (connection closed). Uber Base and SLDS figures came only from third-party sites.

## 3. Where the systems agree
1. **Size sets the level; weight sets emphasis within a level.** The big jumps (title vs body) come from size. Within a size, one step up in weight (Regular to Semibold) marks the important line.
2. **Only two or three weights in UI text:** Regular, Medium or Semibold, and Bold. Nothing lighter than Regular at small sizes.
3. **A heading at body size needs weight.** Apple's Headline, Carbon's heading-01 and Fluent's Strong are all Semibold at body size. Big headings can be Regular, because their size already ranks them.
4. **De-emphasise with colour**, a lighter neutral that still passes 4.5:1, and never with a light weight.
5. **Emphasis is a named variant** (Emphasized, Strong, `-01` heading tokens), not a one-off `fontWeight` override.
6. **Row titles in lists are body-weight.** The picked or unread row gets the emphasized weight, and selection is marked by a check or indicator, not weight alone.
7. Sentence case, no all-caps, few typefaces, and keep hierarchy when text scales.

## 4. Audit: Hisaab today
The scale is in `hisaab_type.dart`. Counts are from `lib/`.

| # | Finding | Evidence | Against |
|---|---|---|---|
| A1 | **Four Mukta weights in use: 400, 500, 600, 700**, plus Anek at 600 | `bodySmall` 500, `title`/`label` 600, `rowAmount` and overrides 700 | Agreement 2 (two or three weights) |
| A2 | **List row titles are Semibold (`titleMedium` 16/20 w600)**, so the picked Ask AI goal moves only from 600 to 700 | `goal_row.dart`, `entry_row.dart` | Agreement 6: rows Regular, pick emphasized |
| A3 | **The card header and its rows share one style.** "What do you want to know?" and every goal row are `titleMedium` | `ask_ai_controls.dart`, `goal_row.dart` | Agreement 1: the header must differ by size or role |
| A4 | **`titleSmall` is used but never defined**, so it falls back to Material's default (14/20 at 500) in Mukta, outside the spec | `period_switch.dart`, `prompt_preview.dart` | §3.4 role table |
| A5 | **Seven inline `fontWeight` overrides** (four at w700, two at w500, one at w600) | `grep FontWeight.w lib` | Agreement 5 (named variants) |
| A6 | Caption is Medium (500) *and* `ink2` grey: it uses both weight and colour to de-emphasise | `bodySmall` | Agreement 4 (colour alone is enough) |
| A7 | The good: no light weights, two typefaces, sentence case, no all-caps eyebrows, tabular amounts, and a hero that steps down at 1.5× | §3.4 rules | All systems |

## 5. Recommendations (for approval)
1. **Three Mukta weights:** 400 (body, row titles, captions), 600 (emphasis: labels, the picked row, small headers) and 700 (amounts only, `rowAmount`). Drop 500.
2. **Row titles become Regular 16/24.** The emphasized variant (600) is reserved for the picked row, unread or today items. This affects Ask AI goal rows, entry rows and bill rows.
3. **Card headers get their own role**, distinct from rows: for example `titleLarge` (Anek 22/28 at 600) for card titles such as "Today" and "What do you want to know?", like Apple's Title 3 over Body rows.
4. **Define every role that's used.** Add `titleSmall` (Mukta 14/20 at 600) to the scale, or move its callers to `labelLarge`.
5. **Replace inline weight overrides with named emphasized styles,** for example `HisaabType.emphasized(style)` or emphasized tokens per role, so emphasis is one decision in one file.
6. **Caption becomes Regular 13/18 in `ink2`.** It's de-emphasised by colour, and `ink2` on `surface` already passes 4.5:1 (UI_DESIGN §3.2).

## 6. Risks
- Making row titles Regular on Home changes how the Today list looks. Check it on the device in light and dark before committing.
- Mukta at 400 is lighter than SF Regular. Check the 16px rows on the moto g45 at 1× and 1.5×.
- Changing weights doesn't change line heights, but switching `titleMedium` from 16/20 to 16/24 grows each row by 4dp. The Today-list edge tests may need their expected values re-measured. Ask before changing any existing test.
