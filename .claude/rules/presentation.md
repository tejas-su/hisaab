---
paths:
  - "lib/**/presentation/**/*.dart"
  - "lib/core/widgets/**/*.dart"
  - "lib/core/design/**/*.dart"
  - "lib/app/**/*.dart"
---

# Presentation layer conventions

The visual and interaction spec is `docs/UI_DESIGN.md`. Read the relevant section before building or changing a screen; it wins over taste.

## File & widget structure
- Every widget in its own file — no multi-widget files
- If a file exceeds ~150 lines, split it
- Pages → `presentation/pages/`, feature-scoped widgets → `presentation/widgets/`
- Widgets shared by **more than one feature** go in `core/widgets/`. Don't duplicate them per feature
- Separate stateful logic (Bloc) from pure UI widgets
- A page or widget receives its bloc and dependencies from above (constructor or `BlocProvider`); it never creates a data-layer object itself, so a widget test can supply a fake or a seeded bloc

## Widgets
- `const` constructors on every widget that doesn't depend on runtime data
- No `BuildContext`, `Navigator`, or any Flutter UI import inside a Bloc
- No business logic inside `build()` — extract to named methods or Blocs

## Navigation
- Navigate only from pages/widgets — never from inside a Bloc
- Use `BlocListener` to react to state changes that need navigation, the Add tray, or snackbars
- Keep route definitions centralised in `lib/app/routes.dart`
- Android predictive back: pages use `PopScope`; the theme sets `PredictiveBackPageTransitionsBuilder`

## Bloc usage
- `BlocBuilder` — rebuilds UI; use only when the widget tree must change
- `BlocListener` — one-time side effects (navigation, snackbars, haptics); no tree changes
- `BlocConsumer` — only when both are needed; otherwise separate `Builder`/`Listener`
- Never subscribe to a Bloc manually in `initState`/`dispose`. Avoid `BlocProvider.of(context)` in `initState`

## Performance
- `buildWhen` on `BlocBuilder` to skip rebuilds when irrelevant fields change
- `BlocSelector` when a widget needs only a few fields of a large state (e.g. the hero amount vs the Today list)
- `RepaintBoundary` around independently animating subtrees (`DayBlocks`, rolling `AmountText`)
- `CustomPainter`s implement `shouldRepaint` by comparing their inputs
- `ListView.builder` / `SliverList` for dynamic or large lists — never `ListView(children: [...])`
- Extract `const` sub-widgets to maximise widget diffing
- No heavy computation in `build()` — compute once and cache

## Design system (non-negotiable; tokens from `docs/UI_DESIGN.md` §3)
- **Colours:** only through `Theme.of(context).extension<HisaabColors>()` (or its `context` extension). No `Color(0xFF…)` or `Colors.*` in widgets
- **Signal colour (marigold):** means "today / act" only — today's day block, the Add key, the keypad Next key, the Ask AI well, and a screen's one pinned primary key (the editor's Next, *Remind me*, *Add a bill*). Never decoration, never on the bare light background (always on `ink` or carrying `ink` text/outline)
- **No red, no green, no category colours.** State is shown by fill, outline, hatch and words. Only exception: `danger` on the *Delete everything* hold key (D142); never for a state, amount or error
- **Type:** only through the theme's `TextTheme` built in `core/design/hisaab_type.dart` (Anek Latin for amounts and titles, Mukta for body). Every amount style has `FontFeature.tabularFigures()`
- **Icons:** Hugeicons only, through `AppIcon(AppIcons.x)`; never `Icon(Icons.*)`. A glyph Hugeicons lacks goes in `HisaabGlyphs` in Hugeicons' path format (24 grid, 1.5 stroke, round caps and joins, corners copied from a Hugeicons original), never a hand-drawn `CustomPainter`. Every icon has a visible label or a semantics label
- **Motion:** only the spring/duration tokens in `core/design/hisaab_motion.dart`; check `HisaabMotion.reduceMotion(context)` and fall back to a 150ms crossfade
- **Haptics:** only through `Haptics.tick()/success()/reject()/threshold()`; one effect per user event
- **Shape:** radii from the token scale; continuous corners via Flutter's `RoundedSuperellipseBorder`. No glass or blur on any surface that shows an amount
- **Copy:** from `AppLocalizations`; amounts from `MoneyFormatter`. Never the words "transaction", "debit/credit", "budget period", "Oops"
- **Layout:** `EdgeInsetsDirectional` / `AlignmentDirectional`; the floating dock sits above `MediaQuery.paddingOf(context).bottom` (edge-to-edge)
- **Alignment:** content shares one outer edge (`HisaabSpacing.gutter`) and cards one inner inset (`HisaabSpacing.gutter`); header actions sit flush with the cards' edge, and captions line up with what they label. Never put a loose `Flexible` beside an `Expanded`/`Spacer` in one `Row` (its unused share ends up as empty space at the row's end); give label columns fixed widths rather than offsets that assume a text width. New screens get a widget test asserting their shared edges
- **Adaptive:** read `context.layout` (`WidthClass`, `HeightClass`, pane arrangement), never raw `MediaQuery` widths. Use minimum sizes, not fixed heights, so text scaling can't overflow. Widget tests pump at the `TestWindows` sizes via `pumpApp` (UI_DESIGN §13)

## Accessibility
- See `.claude/rules/accessibility.md` for semantics, tap targets, contrast, and text scaling

## Keyboard & focus
- Always dispose `FocusNode`, `TextEditingController`, `ScrollController`, `AnimationController` in `dispose()`
- Amount entry uses the in-app `Keypad`, never the system keyboard. Note fields set a `TextInputAction`
- Dismiss the keyboard on tap outside inputs with `FocusScope.of(context).unfocus()`
