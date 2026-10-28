# Ask AI choice screen: UX/UI case study

**Status:** approved and built as DECISIONS D67, which supersedes D66. The period stays inside the choices card, and the header is fixed at the user's request.

## 1. What the screen must do
The person picks what to ask (one of 4 goals, or their own question) and how far back to look (this month or the last 3). They check the exact text, then hand it off. SPEC FR-AI-1 to FR-AI-4 and BR-15 apply. The bar is "a 5-year-old can use it": one obvious reading order and one obvious next tap.

## 2. What is wrong with the current screen (as built after D66)
Observed on a moto g45, light theme:

| Problem | Why it hurts |
|---|---|
| Four layers deep: grey page, white card, grey track, white pill | Apple and Material use at most two for a choice (page and grouped rows). The extra layers read as nested boxes, not as one list |
| 2×2 grid of labels with different lengths | "Review my month" wraps beside its check while its neighbour stays on one line, so rows don't line up |
| Unpicked options are bare text on grey | No row edge, so the eye can't find the columns or the tap area |
| *Ask my own question* sits alone under the grid | It breaks the grid, and the text field only appears after an extra tap |
| Two selection styles in one card (grid track and segmented track), both with checks | The same job looks different twice |
| The main action scrolls below the fold | The person must scroll to act, after making the choices at the top |

## 3. Research

### 3.1 Apple Human Interface Guidelines
- **Option lists use a checkmark, not a fill.** "A table that lists options often highlights a row only briefly before adding an image — such as a checkmark — indicating that the item is selected." Settings, Health and Wallet all use grouped rows on a grey background ([Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables)).
- **Short row text.** "Keep item text succinct so row content is comfortable to read," which minimises truncation and wrapping.
- **Two to five related nouns belong in a segmented control.** Segments are equal width and use noun labels, and the control "doesn't need introductory text" ([Segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls)).

### 3.2 Duolingo, Monzo and other onboarding questions
- Single-select questions are a **single column of full-width answer rows**, often each with a small icon or emoji, and a pinned *Continue* at the bottom ([Duolingo onboarding screens](https://screensdesign.com/explore/apps/duolingo/onboarding/), [Duolingo UX review](https://uxdesign.cc/the-duolingo-diaries-an-honest-ux-review-part-1-onboarding-ed0165d44c58)).
- Monzo opens with "your main financial goal": saving, controlling spending, improving credit and so on, each with a small emoji ([Mobbin: Monzo onboarding flow](https://mobbin.com/explore/flows/7839ee64-6402-4244-8c14-b650d3715ef9), [Craft Innovations teardown](https://craftinnovations.global/banking-onboarding-best-practices-revolut-nubank-monzo/)).
- Single-select is the default for goal questions, by about 3:1 across 80 apps ([Lazyweb](https://www.lazyweb.com/research/single-select-vs-multi-select-quiz-questions)).

### 3.3 Selection controls (Mobbin, Material, NN/g)
- **Radio-style rows** suit a single choice from a short visible list. Mobbin lists "radio buttons with checkmark icon" as a variant, and says a checkmark on a tile "works similarly to a radio button" ([Mobbin: Radio button](https://mobbin.com/glossary/radio-button), [Mobbin: Checkbox](https://mobbin.com/glossary/checkbox)).
- **Chips** suit about 3–6 options of one or two words. "Two or more rows of chips are harder to scan," so long labels belong in rows ([Material: Chips](https://m2.material.io/components/chips), [Setproduct: chips](https://www.setproduct.com/blog/chip-ui-design)).
- **Show the options; don't hide them.** NN/g says buttons that surface all choices at once let users "scan, compare, and select in one step" ([NN/g: dropdowns](https://www.nngroup.com/articles/dropdown-list/), [NN/g: listbox vs dropdown](https://www.nngroup.com/articles/listbox-dropdown/)).

### 3.4 AI "prompt starters" (ChatGPT, Gemini, Claude, Notion AI)
The Ask AI goals are prompt starters: example requests shown so the person recognises a task instead of inventing one.
- Show **3–4 short, concrete task labels**, not "Ask me anything" ([AI UX Playground: Prompt starters](https://aiuxplayground.com/pattern/prompt-starters)).
- **Keep the composer visible** below the starters, so typing your own is never a hidden step. Notion AI shows starter cards plus a "Describe your own" box ([UI Patterns: Suggested prompts](https://ui-patterns.com/patterns/SuggestedPrompts)).
- The pattern is now near-universal. Its weakness is generic starters, and ours are tied to the user's own money data ([uxdesign.cc: The death of the empty state](https://uxdesign.cc/the-death-of-the-empty-state-in-ai-products-2026-e11439fbb688)).
- Cleo, an AI money app, offers quick replies as tappable buttons and keeps chat at the centre ([Cleo on Google Play](https://play.google.com/store/apps/details?id=com.meetcleo.cleo), [izzoul: Cleo case study](https://www.izzoul.com/product-design/cleo-ai)).

### 3.5 Indian fintech (slice, GPay, CRED, Jupiter)
I found no public screen-level material on their choice screens, only brand and illustration work ([slice revamp on Behance](https://behance.net/gallery/167349583/Mobile-App-Visual-Revamp-Slice), [CRED on Dribbble](https://dribbble.com/cred-design), [Jupiter case study](https://medium.com/@guptamuskan495/reimagining-jupiter-a-fintech-case-study-on-product-positioning-ux-and-growth-opportunities-8dbcabdecbd0)). GPay follows Material: radio rows in lists and bottom sheets ([Android: radio button](https://developer.android.com/develop/ui/compose/components/radio-button)). Mobbin pages need a login and Pinterest boards hold mostly 2016–2021 quiz shots, so neither was used as evidence.

## 4. Patterns compared

| Pattern | Fits 4 goals + own | Alignment | Matches Hisaab (D45, Home) | Verdict |
|---|---|---|---|---|
| A. Grouped list rows with trailing check (Apple, GPay) | Yes, one column with no wrapping | Every row shares one leading and one trailing edge | Same as Home's Today list: white card, icon wells, hairlines indented to the text | **Recommended** |
| B. Separate full-width answer cards, picked one outlined (Duolingo) | Yes | Good | Five bordered cards break "cards have no border" | Playful, off-brand |
| C. 2×2 tiles (current) | Labels wrap | Poor | Too many layers | Drop |
| D. Choice chips (Material) | Labels too long; two rows of chips | Poor | Neutral | Only for the period |

## 5. Recommended design

```
 What do you want to know?             ← plain header on the page, lined up with the row text
┌──────────────────────────────────┐
│ [▤] Review my month            ✓ │   white card, 56dp rows, icon in grey well,
│ ─── Help me save                 │   hairline indented to the text (Today list geometry);
│ ─── Make me a budget             │   the pick: ink check and bold label, no fill
│ ─── Am I on track?               │
│ ─── [ Or type your own question ]│   the field is always visible; typing picks it
└──────────────────────────────────┘
┌───────────────┬──────────────────┐
│  This month   │  Last 3 months   │   one segmented control (the Spent | Got style)
└───────────────┴──────────────────┘
┌──────────────────────────────────┐
│ What will be sent · 5 entries    │   preview card (unchanged), with Hide my notes
└──────────────────────────────────┘
══ pinned to the bottom ═════════════
[ Copy & open ChatGPT ]                marigold key, always in thumb reach
[ Other AI ]   [ Copy only ]
```

1. **One column of rows** (Apple, Duolingo, GPay). There are no wraps, and every label starts on the same line. The 4 goals keep their fixed order.
2. **Check, not fill** (Apple HIG). The pick gets an ink check at the row's end and a bold label. No marigold, because a pick is a mode (D47).
3. **Own question as an always-visible field in the last row** (prompt starters, Notion AI). Typing selects it, and tapping a goal row leaves the text in place. This removes one tap and one hidden step. It changes FR-AI-1's "opens a … text field".
4. **Period as a segmented control** (Apple). Two nouns, equal widths, no check, the same style as Spent | Got.
5. **Pinned actions** (Duolingo's Continue, Monzo). The marigold key stays on screen while the person changes the choices, and the preview scrolls above it.
6. **Layers stay at two:** grey page, then white cards. Grey shows only in icon wells and the segmented track (D45).

## 6. Risks and open questions
- **Pinned actions on short windows:** in phone landscape and at 1.5× text, the actions could take a third of the height. Either pin them only when the window is tall enough (the `HeightClass.regular` class), or move them into the second pane on wide windows as now.
- **Own-question field in the list:** the keyboard opening over the list can hide the preview. Scroll the field into view on focus.
- **Icons:** Review gets a chart, Help me save a piggy bank, Make me a budget a target, Am I on track? a flag, and own question a pen. All come from Hugeicons, with labels, in grey wells, and are monochrome.
