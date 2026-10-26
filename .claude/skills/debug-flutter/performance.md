# Jank / Slow UI and Build Thrashing

## 1. Measure first

Don't guess. Ask the user to:
1. Open Flutter DevTools → **Performance** tab
2. Run the janky interaction
3. Report the average frame time in ms, and whether the spike is on the **UI** or the **Raster** thread

- UI thread spike → Dart code is doing too much work on the main isolate
- Raster spike → painting/compositing is expensive (shadows, clips, images)

## 2. Find the rebuild source

Use DevTools **Widget Rebuild Stats**, or temporarily add this to `lib/main.dart`:

```dart
debugPrintRebuildDirtyWidgets = true;
```

Look for widgets rebuilding on every frame, scroll tick, or user interaction.

## 3. Patterns to check first in this app
- **Keypad typing rebuilds the whole tray** — only `AmountText` and the Next key should rebuild per digit; use `BlocSelector`
- **`DayBlocks` repaints every frame** — `shouldRepaint` must compare inputs; wrap it in a `RepaintBoundary`
- **Rolling digits** — `AmountText` animating every glyph with its own controller; one controller per number, tabular figures so layout doesn't shift
- **`BlocBuilder` without `buildWhen`** around the whole Home page — the hero, range line and Today list change at different times
- **Charts** — `fl_chart` rebuilding on unrelated state; feed it a memoised series
- **Missing `const`** on `SizedBox`, `Padding`, and leaf text widgets

## 4. Targeted fixes

| Pattern found | Fix |
|---|---|
| `BlocBuilder` with no `buildWhen` | Add `buildWhen: (prev, next) => prev.relevantField != next.relevantField` |
| `BlocBuilder` selecting a large state | Replace with `BlocSelector<FeatureBloc, State, FieldType>` |
| Missing `const` on leaf widgets | Add `const` |
| `setState()` in a widget that contains a `BlocBuilder` | Extract the `setState` part into its own `StatefulWidget` |
| Large `build()` returning everything | Extract stable subtrees into `const` widgets or separate classes |

## 5. Raster jank fixes
- Wrap heavy animated widgets in `RepaintBoundary`
- On large surfaces, replace `BoxDecoration` with `borderRadius` + `boxShadow` with a cached custom painter or `ClipRRect`
- `precacheImage()` for images loaded on scroll

## 6. Measure after each change

One fix → re-measure → confirm with the user → next fix. Never apply everything at once.
