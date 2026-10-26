---
paths:
  - "lib/**/presentation/**/*.dart"
  - "lib/core/widgets/**/*.dart"
---

# Accessibility

Applies when you **create or modify a widget**. Bring the widgets you touched up to this baseline. Don't audit or rewrite untouched files.

Accessibility serves screen-reader users (TalkBack / VoiceOver) and makes the app addressable to automated tooling. Flutter renders to a single canvas, so without semantics the app is an opaque rectangle to everything outside it.

## The governing rule

**Standard Flutter widgets build the semantics tree automatically.** `Semantics` is for *customisation*, not blanket coverage. Wrapping everything produces a noisy, redundant tree that is worse than the default. Prefer a built-in widget that already carries the right semantics over a `GestureDetector` plus hand-written `Semantics`.

## When to add semantics

- **Icon-only controls** — no visible text, so nothing to announce
- **Custom-painted or `GestureDetector`-based controls** — no default semantics exist
- **Composite widgets** that should announce as one thing, not five
- **Decorative imagery** that should be skipped entirely
- **Gesture-only actions** (swipe to dismiss, drag to reorder) with no button equivalent
- **Custom controls with state** — need `enabled`, `checked`, or `selected`

## Flutter API to use

| Need | Use |
|---|---|
| Announce a composite as one node | `MergeSemantics` |
| Hide a decorative subtree | `ExcludeSemantics` |
| Suppress everything behind a modal | `BlockSemantics` |
| Preserve item order in a list | `IndexedSemantics` |
| Label text / image / icon | `Text.semanticsLabel`, `Image.semanticLabel`, `Icon.semanticLabel` |
| Label an icon button | `IconButton.tooltip` |
| Custom control role + state | `Semantics(label:, button:, enabled:, checked:, selected:)` |

- Label the **parent** of a composite and let children merge — don't make each child separately tappable
- Labels within a list must be **unique**, or a screen reader cannot distinguish rows
- Keep labels short; they are spoken aloud
- Don't put the widget type in the label — `Semantics(button: true)` already announces "button"

## Beyond labels (Flutter accessibility release checklist)

- Every `onTap` / `onPressed` must do something — no silent no-op callbacks
- Tap targets at least **48×48dp** (iOS 44×44pt)
- Contrast at least **4.5:1**, or 3:1 for large text (≥18pt regular / ≥14pt bold)
- Never signal state by colour alone — add text, shape, or an icon
- Don't change the user's context automatically while they are entering information
- Important actions should be undoable; error states should suggest a correction
- Layout must stay legible and usable at the largest system text scale factor

## Project conventions (Hisaab)

The target user includes children, older adults and first-time smartphone users (`docs/UI_DESIGN.md` §2 and §9).

- **Amounts:** `AmountText` exposes a spoken label ("1,850 rupees"), not the glyphs (`₹1,850`). Pass `semanticsLabel` through it rather than wrapping it in `Semantics`
- **Hero card:** one merged node that reads the full sentence, e.g. "Safe to spend today: 1,850 rupees. 9 days to payday. Lasts till payday with 900 rupees spare"
- **`DayBlocks` (custom painter):** one `Semantics` label describing today's share, the days left and the state word; the individual blocks are excluded
- **Keypad:** every key is a real button; ⌫ is labelled "Delete last digit. Long-press to clear"
- **Category tiles:** label "<Category>. Save expense"; their position never changes, so muscle memory works with TalkBack too
- **State is never colour-only.** On track / Slow down / Over always carry a word and a glyph; marigold alone means nothing to a screen reader or a colour-blind user
- **Targets:** keys and tiles are 64–96dp, well above the 48dp floor
- **Text scale:** layouts must hold at 1.5×; the hero amount steps 76 → 56 → 44 before it may wrap
- **Reduced motion:** honour `MediaQuery.disableAnimations` via `reduceMotion(context)`

## Verifying

Automated — add to `test/a11y_test.dart` alongside widget tests:

```dart
testWidgets('follows a11y guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(const MyWidget());

  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));

  handle.dispose();
});
```

Manual:
- `MaterialApp(showSemanticsDebugger: true)` to see the semantics tree over the UI
- Android **Accessibility Scanner** for an on-device audit
- Turn on TalkBack and navigate the screen you changed
