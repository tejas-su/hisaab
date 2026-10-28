# 03. Suggestion pills (bill name step)

## Job of the screen
Bill editor step 1: name a bill. Typing is the main path. Six pills (Rent, EMI, Phone, Internet, School fees, Subscriptions) are shortcuts that name the bill and move on.

## What was wrong
Pills sat in a centered `Wrap`: each row shrank to its content, so rows had different left and right margins and did not line up with the Name field or the Next key. Pixel alignment matters here (see memory: pixel-alignment).

## Research
- **Material 3 chips:** suggestion chips sit inline in a row, overflow breaks to the next line, and a one-row set may scroll horizontally. Filter chips with more than two rows should scroll instead. Keep at least 8dp between chips and a 48dp target. Labels truncate when wider than the window ([M3 Chips](https://m3.material.io/components/chips/guidelines)).
- **Material 2 chips:** an action-chip set can scroll horizontally ([M2 Chips](https://m2.material.io/components/chips)).
- **UXcel suggestion chips:** keep labels under about 20 characters, place chips after the primary content or pinned at the bottom, and use them for secondary actions ([UXcel](https://uxcel.com/lessons/anatomy-694)).
- **Red Hat chip guidelines:** use one chip size in every group ([Red Hat](https://ux.redhat.com/elements/chip/guidelines/)).
- **Carbon (IBM) tags:** selectable tags carry a container border to show they are interactive, sit in the tab order, toggle on Enter or Space, and truncate long titles with an ellipsis ([Carbon tag usage](https://carbondesignsystem.com/components/tag/usage), [accessibility](https://carbondesignsystem.com/components/tag/accessibility/)). No spacing values found.
- **Volvo Cars design system:** chips are for interactive items only; a non-interactive label should be a Pill ([Volvo chips](https://designsystem.volvocars.com/web/components/chips/usage/)).
- **Filter-chip rows in apps** (calimoto, Klook): a horizontal row under the header; the selected state must differ clearly, by fill or a strong border ([ScreensDesign chips gallery](https://screensdesign.com/explore/ui-elements/chips/), [one designer's write-up](https://www.pravinkumar.co/blog/webflow-cms-filter-chips-bar-design-2026)). A single anecdote, not a study.
- **Not found:** Polaris and Atlassian chip layout rules; any Dribbble or Mobbin shot of a bill-name step. Searches returned no pages from either site.
- **Expense apps (Next, Saver, templates):** category shortcuts appear as icon tiles in a grid, one tap to pick ([Next review](https://www.rocketmatter.com/?p=8425), [Saver review](https://www.macstories.net/reviews/review-saver-for-iphone-expense-tracking-made-less-painful-and-more-beautiful/)). Not found: screen-level material for Money Manager, Spendee, CRED or Fi.
- **Our own principle 4:** chips only for one- or two-word options in a single row. Six pills in two rows already breaks it.

## Patterns compared
| Pattern | Alignment | Scan | Fit |
|---|---|---|---|
| A. Centered wrap (before) | Ragged both edges | Poor | Drop |
| B. Left-aligned wrap, content width | Left edge true, ragged right | Fair | Cheap, still ragged |
| C. Two equal columns (built) | Both edges true | Good, 3 rows | Keeps pill look, one tap, no new layer |
| D. Single row, horizontal scroll | Left edge true, clipped right | Hides options | Poor: "show the options" (case 01) |
| E. Rows with trailing chevron in one card | Both edges true | Best | Matches case 01, but 6 rows push Next down and the field is the main path |

## Recommendation
C now. If the list grows past six or labels lengthen, move to E. Do not add icons to pills: Hisaab icons always carry a label, and the label is already there.

## Risks
- Long localized labels truncate in a half-width pill; revisit when l10n adds languages.
- Chip text now centers in the pill.

## Follow-up: picked state and placement (D85)
The owner saw two loud blocks: the ink-filled picked pill and the marigold Next key. Separate UX and UI reviews, then a cross-critique, agreed:
- **Weight:** ink on `bg` is 15.33:1 and marigold is 1.55:1, so the black pill outweighed Next at half its size. Apple HIG keeps one or two prominent buttons per view and uses colour sparingly ([Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Color](https://developer.apple.com/design/human-interface-guidelines/color)). Material's selected filter chip is a quiet tonal fill plus a check ([FilterChip](https://developer.android.com/reference/kotlin/androidx/compose/material3/FilterChip.composable)). Secondary actions take the weakest weight ([UX Movement](https://uxmovement.com/buttons/visual-weight-of-primary-and-secondary-action-buttons/)).
- **Pick:** `surface` fill, 1.5dp `ink` edge (15.33:1, passes [WCAG 1.4.11](https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html)), trailing check. Unpicked hairline is 1.30:1; acceptable because the label identifies each pill.
- **Placement:** pills under the field read as ways to fill it; beside Next they read as more buttons. No caption: the owner found one confusing.
- **Changing a bill:** pills are left out.
- Not verified: Monzo, Revolut, GPay, Wallet chip states (no primary sources); m3.material.io pages render with JavaScript and could not be read.
