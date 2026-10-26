---
paths:
  - "lib/**/bloc/**/*.dart"
  - "lib/**/cubit/**/*.dart"
  - "lib/**/*_bloc.dart"
  - "lib/**/*_cubit.dart"
---

# BLoC / Cubit conventions

## State management
- Default to `Cubit`: Hisaab's flows are short and local (enter amount, pick category, load a cycle)
- Use `Bloc` + explicit events only when event modelling earns its keep: debounced/restartable input (search, filters) or events that must be dropped while one is in flight
- No `setState` outside isolated leaf widgets (e.g. a key's pressed animation)
- States (and events) must be immutable: `const` constructors, `final` fields, `copyWith`
- One Cubit per independent concern of a screen, not one per feature: split off a slice of state that has its own inputs (e.g. the Add tray's amount step vs the Home summary); keep together state that the same methods read and write
- Cubits never reference each other: coordinate them through a `BlocListener` in the page, or have both listen to a shared repository stream (e.g. `LedgerRepository.watchCycle()`)
- Keep Cubits thin — delegate all logic to use cases and pure domain functions (`SafeToSpend`, `PeriodCalculator`)
- Receive use cases or repository interfaces through the constructor, never concrete data classes, `GetIt.I`, or singletons, so a test can inject a fake
- States need value equality (`Equatable`); state-sequence tests depend on it
- Test-first: write the expected state sequence for the method/event, watch it fail, then implement (see `.claude/rules/tests.md`)

## Sealed classes & pattern matching
- Use `sealed` classes for states (and events) — enforces exhaustive `switch` at compile time
- Exhaustive `switch` expressions with no `default` fallthrough, so new variants cause compile errors
- Prefer `switch` expressions that return a value over `switch` statements with side effects

## Async
- All async operations belong in Cubits/Blocs or use cases — never `await` inside `build()` or widget callbacks
- No `FutureBuilder` / `StreamBuilder` when a Cubit can own the state
- Consume `TaskEither` results by calling `.run()` in the Cubit, then `.fold(onLeft, onRight)`:
  ```dart
  final result = await saveEntry(params).run();
  result.fold(
    (failure) => emit(AddEntryState.failed(failure)),
    (entry)   => emit(AddEntryState.saved(entry)),
  );
  ```

## Streams
- Streams only for genuinely continuous data (repository change notifications after a write), not as a substitute for one-shot futures
- Every manually opened `StreamSubscription` must be cancelled in `close()`
- Own streams inside Cubits/Blocs or data sources only — never in widgets

## Safety
- Check `isClosed` before calling `emit` after any `await`
- Never `emit` inside a `catch` block without first checking `isClosed`; the Cubit may have been disposed mid-flight
- Guard against double submission (a second tap on Next or a tile while a save is in flight): ignore the call when the state is already `Saving`

## Event deduplication (Bloc only)
- `transformer: droppable()` for events that must not stack
- `transformer: restartable()` for search/filter events where only the latest matters
- Default `concurrent()` only when events are truly independent and safe to run in parallel
- `bloc_concurrency` is not in the dependency tree yet; ask before adding it
